import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:uuid/uuid.dart';
import '../models/survey_point.dart';

class SurvXParserResult {
  final List<SurveyPoint> points;
  final String? sheetName;
  final int totalRowsParsed;
  final String? errorMessage;

  SurvXParserResult({
    required this.points,
    this.sheetName,
    this.totalRowsParsed = 0,
    this.errorMessage,
  });
}

class SurvXParserService {
  static final _uuid = Uuid();

  /// Parsea un archivo Excel (.xlsx / .xls) exportado desde SurvX
  /// ("GNSS MEASUREMENT REPORT").
  ///
  /// Reglas estrictas:
  /// 1. Ignora la sección inicial y la tabla "GNSS base station".
  /// 2. Detecta la fila de encabezados bajo "GNSS measurements".
  /// 3. Mapea las columnas obligatorias: Nr, x, y, h (cota ortométrica).
  ///    Descarta explícitamente 'H' (cota elipsoidal).
  static SurvXParserResult parseSurvXExcel(Uint8List fileBytes) {
    try {
      final excel = Excel.decodeBytes(fileBytes);

      for (final table in excel.tables.keys) {
        final sheet = excel.tables[table];
        if (sheet == null || sheet.rows.isEmpty) continue;

        int headerRowIndex = -1;
        int idxNr = -1;
        int idxX = -1;
        int idxY = -1;
        int idxH = -1;
        bool inGnssMeasurementsSection = false;

        // Escaneamos las filas para encontrar la sección "GNSS measurements"
        for (int r = 0; r < sheet.rows.length; r++) {
          final row = sheet.rows[r];
          final rowTexts = row.map((c) => c?.value?.toString().trim() ?? '').toList();

          // Detección de la sección exclusiva de mediciones (descartando el título general del reporte)
          final rowJoined = rowTexts.join(' ').toLowerCase();
          if ((rowJoined.contains('gnss measurement') || rowJoined.contains('mediciones gnss')) &&
              !rowJoined.contains('report') && !rowJoined.contains('informe')) {
            inGnssMeasurementsSection = true;
          }

          // Detección de la fila de encabezados bajo la sección de mediciones
          // Columnas estándar SurvX: Nr, Date, Time, GMT, Mode, B, L, H, X, Y, Z, x, y, h, E, Sat, PDOP, mp, mh, H.ant
          int tempNr = -1;
          int tempX = -1;
          int tempY = -1;
          int tempH = -1;
          bool hasSurveyColumn = false;

          for (int c = 0; c < row.length; c++) {
            final rawVal = row[c]?.value?.toString().trim() ?? '';
            final val = rawVal.toLowerCase();
            if (rawVal.isEmpty) continue;

            if (val == 'nr' || val == 'nr.' || val == 'punto' || val == 'id') {
              tempNr = c;
            } else if (rawVal == 'x' || val == 'este' || val == 'x(m)') {
              tempX = c;
            } else if (rawVal == 'y' || val == 'norte' || val == 'y(m)') {
              tempY = c;
            } else if (rawVal == 'h' || val == 'cota' || val == 'h(m)' || val == 'cota ortom.') {
              // Exact lowercase 'h' is orthometric elevation
              tempH = c;
            }

            if (val == 'mode' || val == 'sat' || val == 'pdop' || val == 'gmt') {
              hasSurveyColumn = true;
            }
          }

          // La tabla de mediciones GNSS contiene las columnas clave x, y, h Y columnas exclusivas (Sat/PDOP/Mode)
          // o se ubica inmediatamente tras el marcador de sección
          if (tempNr != -1 && tempX != -1 && tempY != -1 && tempH != -1) {
            if (hasSurveyColumn || inGnssMeasurementsSection) {
              headerRowIndex = r;
              idxNr = tempNr;
              idxX = tempX;
              idxY = tempY;
              idxH = tempH;
              break;
            }
          }
        }

        // Si no se encontró el header exacto 'h', buscamos fallback de columnas
        if (headerRowIndex == -1) {
          for (int r = 0; r < sheet.rows.length; r++) {
            final row = sheet.rows[r];
            for (int c = 0; c < row.length; c++) {
              final val = row[c]?.value?.toString().trim() ?? '';
              if (val.toLowerCase() == 'nr' || val.toLowerCase() == 'punto') idxNr = c;
              if (val == 'x') idxX = c;
              if (val == 'y') idxY = c;
              if (val == 'h') idxH = c;
            }
            if (idxNr != -1 && idxX != -1 && idxY != -1 && idxH != -1) {
              headerRowIndex = r;
              break;
            }
          }
        }

        if (headerRowIndex == -1 || idxNr == -1 || idxX == -1 || idxY == -1 || idxH == -1) {
          continue; // Probar siguiente hoja
        }

        final List<SurveyPoint> points = [];

        // Extraer mediciones desde la fila siguiente al encabezado
        for (int r = headerRowIndex + 1; r < sheet.rows.length; r++) {
          final row = sheet.rows[r];
          if (row.isEmpty) continue;

          final nrVal = row.length > idxNr ? row[idxNr]?.value?.toString().trim() : null;
          if (nrVal == null || nrVal.isEmpty) continue;

          // Si encontramos otro título o fin de tabla, detener
          if (nrVal.toLowerCase().contains('total') || nrVal.toLowerCase().contains('report')) {
            break;
          }

          final xVal = row.length > idxX ? _parseNumber(row[idxX]?.value) : null;
          final yVal = row.length > idxY ? _parseNumber(row[idxY]?.value) : null;
          final hVal = row.length > idxH ? _parseNumber(row[idxH]?.value) : null;

          if (xVal != null && yVal != null && hVal != null) {
            points.add(SurveyPoint(
              id: _uuid.v4(),
              nr: nrVal,
              x: xVal,
              y: yVal,
              elevation: hVal,
              isManualOptical: false,
              classification: PointClassification.coronamiento, // Asignación inicial que el motor refina
            ));
          }
        }

        if (points.isNotEmpty) {
          return SurvXParserResult(
            points: points,
            sheetName: table,
            totalRowsParsed: points.length,
          );
        }
      }

      return SurvXParserResult(
        points: [],
        errorMessage: 'No se encontraron columnas válidas (Nr, x, y, h) en el reporte de SurvX.',
      );
    } catch (e) {
      return SurvXParserResult(
        points: [],
        errorMessage: 'Error al procesar el archivo Excel: $e',
      );
    }
  }

  static double? _parseNumber(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final str = value.toString().trim().replaceAll(',', '.');
    return double.tryParse(str);
  }
}
