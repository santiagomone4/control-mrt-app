import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/project.dart';
import '../models/control_point.dart';
import 'design_calc_service.dart';

class ExportPdfService {
  /// Genera un documento PDF profesional de control de obra y perfil hidráulico
  static Future<Uint8List> generatePdfReport({
    required Project project,
    required MrtCalculationSummary summary,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return [
            // Encabezado
            _buildHeader(project, dateFormat),
            pw.SizedBox(height: 12),

            // Tarjetas de Parámetros y KPIs
            _buildParametersAndKpis(project, summary),
            pw.SizedBox(height: 14),

            // Gráfico Vectorial del Perfil Longitudinal
            _buildProfileChart(project, summary),
            pw.SizedBox(height: 14),

            // Planilla de Control de Obra
            pw.Text(
              "PLANILLA DE CONTROL DE OBRA (RASANTE Y VERTEDEROS)",
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey900,
              ),
            ),
            pw.SizedBox(height: 6),
            _buildControlTable(summary.controlPoints),
            pw.SizedBox(height: 20),

            // Firmas de Responsabilidad
            _buildSignatures(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(Project project, DateFormat dateFormat) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFF112B4F), // Autoridad & Confianza #112B4F
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "INFORME TÉCNICO DE CONTROL DE OBRA",
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                "Micro-embalse de Retención Temporaria (MRT)",
                style: const pw.TextStyle(
                  color: PdfColor.fromInt(0xFFC0D8EA),
                  fontSize: 9,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                "Proyecto: ${project.name}",
                style: const pw.TextStyle(
                  color: PdfColor.fromInt(0xFF4FA3D1), // Agua & Precisión #4FA3D1
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                "Lote/Establecimiento: ${project.establishment.isEmpty ? 'N/D' : project.establishment}",
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 8),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                "Fecha: ${dateFormat.format(project.date)}",
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 8),
              ),
              pw.Text(
                "Operario: ${project.operatorName.isEmpty ? 'N/D' : project.operatorName}",
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 8),
              ),
              pw.Text(
                "Método: ${project.surveyMode == SurveyMode.gnss ? 'GNSS (SurvX)' : 'Nivel Óptico'}",
                style: const pw.TextStyle(color: PdfColor.fromInt(0xFF4FA3D1), fontSize: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildParametersAndKpis(Project project, MrtCalculationSummary summary) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF3F1EC), // Suelo & Base #F3F1EC
        border: pw.Border.fromBorderSides(pw.BorderSide(color: PdfColor.fromInt(0xFFD4CFC2), width: 0.8)),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _paramItem("Cota Base Mínima", "${summary.cotaBaseMin.toStringAsFixed(2)} m"),
              _paramItem("Altura Diseño", "${project.designParams.designHeight.toStringAsFixed(2)} m"),
              _paramItem("Cota Coronamiento Ideal", "${summary.cotaCoronamientoIdeal.toStringAsFixed(2)} m"),
              _paramItem("Cota Vertederos", "${summary.cotaVertederosIdeal.toStringAsFixed(2)} m"),
              _paramItem("Vertederos (I/D)", "${project.designParams.leftSpillwayLength}m / ${project.designParams.rightSpillwayLength}m"),
              _paramItem("Tolerancia", "±${(project.designParams.tolerance * 100).toStringAsFixed(0)} cm"),
            ],
          ),
          pw.Divider(color: const PdfColor.fromInt(0xFFD4CFC2), thickness: 0.5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _kpiBox("Puntos OK", "${summary.countOk}", const PdfColor.fromInt(0xFF3FA34D)), // Naturaleza
              _kpiBox("Rellenar", "${summary.countRellenar} pts (máx: +${summary.maxRellenarCm.toStringAsFixed(1)} cm)", const PdfColor.fromInt(0xFF2376A4)), // Agua
              _kpiBox("Cortar", "${summary.countCortar} pts (máx: -${summary.maxCortarCm.toStringAsFixed(1)} cm)", const PdfColor.fromInt(0xFFC53030)), // Cortar
              _kpiBox("Longitud MRT", "${summary.totalLength.toStringAsFixed(1)} m", const PdfColor.fromInt(0xFF112B4F)), // Autoridad
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _paramItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
        pw.Text(value, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _kpiBox(String title, String val, PdfColor col) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
        color: col.luminance > 0.5 ? col : PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
        border: pw.Border.all(color: col, width: 0.8),
      ),
      child: pw.Column(
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: col)),
          pw.Text(val, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        ],
      ),
    );
  }

  static pw.Widget _buildProfileChart(Project project, MrtCalculationSummary summary) {
    return pw.Container(
      height: 140,
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey500, width: 0.8),
        color: PdfColors.grey50,
      ),
      child: pw.CustomPaint(
        painter: (PdfGraphics canvas, PdfPoint size) {
          final width = size.x;
          final height = size.y;
          final margin = 25.0;

          // Rango de progresivas
          final maxProg = summary.totalLength > 0 ? summary.totalLength : 100.0;

          // Rango de cotas
          double minCota = summary.cotaBaseMin;
          double maxCota = summary.cotaCoronamientoIdeal;
          for (final p in project.points) {
            if (p.elevation < minCota) minCota = p.elevation;
            if (p.elevation > maxCota) maxCota = p.elevation;
          }
          minCota -= 0.5;
          maxCota += 0.5;
          final deltaCota = (maxCota - minCota) > 0 ? (maxCota - minCota) : 1.0;

          double mapX(double prog) => margin + (prog / maxProg) * (width - 2 * margin);
          double mapY(double cota) => margin + ((cota - minCota) / deltaCota) * (height - 2 * margin);

          // Ejes y grilla
          canvas.setStrokeColor(PdfColors.grey400);
          canvas.setLineWidth(0.4);
          canvas.drawLine(margin, margin, width - margin, margin);
          canvas.drawLine(margin, margin, margin, height - margin);

          // 1. Línea de Base (Terreno natural / Suelo)
          if (summary.basePoints.isNotEmpty) {
            canvas.setStrokeColor(const PdfColor.fromInt(0xFF6D4C41)); // Suelo & Base #6D4C41
            canvas.setLineWidth(1.3);
            for (int i = 0; i < summary.basePoints.length - 1; i++) {
              final p1 = summary.basePoints[i];
              final p2 = summary.basePoints[i + 1];
              canvas.drawLine(mapX(p1.progressive), mapY(p1.elevation), mapX(p2.progressive), mapY(p2.elevation));
            }
          }

          // 2. Línea de Coronamiento Relevado (Autoridad & Confianza)
          if (summary.crestPoints.isNotEmpty) {
            canvas.setStrokeColor(const PdfColor.fromInt(0xFF112B4F)); // Autoridad #112B4F
            canvas.setLineWidth(1.6);
            for (int i = 0; i < summary.crestPoints.length - 1; i++) {
              final p1 = summary.crestPoints[i];
              final p2 = summary.crestPoints[i + 1];
              canvas.drawLine(mapX(p1.progressive), mapY(p1.elevation), mapX(p2.progressive), mapY(p2.elevation));
            }
          }

          // 3. Perfil Ideal de Diseño (Escalonado con Vertederos)
          canvas.setStrokeColor(const PdfColor.fromInt(0xFFC53030)); // Rojo rasante
          canvas.setLineWidth(1.8);

          final leftL = project.designParams.leftSpillwayLength;
          final rightL = maxProg - project.designParams.rightSpillwayLength;
          final yVert = mapY(summary.cotaVertederosIdeal);
          final yCrest = mapY(summary.cotaCoronamientoIdeal);

          // Vertedero izquierdo
          canvas.drawLine(mapX(0), yVert, mapX(leftL), yVert);
          // Escalón subida
          canvas.drawLine(mapX(leftL), yVert, mapX(leftL), yCrest);
          // Coronamiento central
          canvas.drawLine(mapX(leftL), yCrest, mapX(rightL), yCrest);
          // Escalón bajada
          canvas.drawLine(mapX(rightL), yCrest, mapX(rightL), yVert);
          // Vertedero derecho
          canvas.drawLine(mapX(rightL), yVert, mapX(maxProg), yVert);
        },
      ),
    );
  }

  static pw.Widget _buildControlTable(List<ControlPoint> points) {
    return pw.Table(
      border: const pw.TableBorder(
        bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFD4CFC2), width: 0.5),
        horizontalInside: pw.BorderSide(color: PdfColor.fromInt(0xFFE9E6DC), width: 0.5),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.2), // Pto / ID
        1: pw.FlexColumnWidth(1.8), // Prog (m)
        2: pw.FlexColumnWidth(2.0), // Cota Base
        3: pw.FlexColumnWidth(2.0), // Cota Actual
        4: pw.FlexColumnWidth(2.0), // Cota Ideal
        5: pw.FlexColumnWidth(2.2), // Dif (cm)
        6: pw.FlexColumnWidth(2.4), // Acción
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF112B4F)), // Autoridad #112B4F
          children: [
            _thWhite("Pto"),
            _thWhite("Prog. (m)"),
            _thWhite("Cota Base"),
            _thWhite("Cota Actual"),
            _thWhite("Cota Ideal"),
            _thWhite("Dif. (cm)"),
            _thWhite("Acción"),
          ],
        ),
        ...points.map((cp) {
          PdfColor actionColor = const PdfColor.fromInt(0xFF3FA34D); // Naturaleza #3FA34D
          String actionText = "OK";
          if (cp.action == ActionType.rellenar) {
            actionColor = const PdfColor.fromInt(0xFF2376A4); // Agua & Precisión #2376A4
            actionText = "RELLENAR";
          } else if (cp.action == ActionType.cortar) {
            actionColor = const PdfColor.fromInt(0xFFC53030); // Cortar
            actionText = "CORTAR";
          }

          return pw.TableRow(
            children: [
              _td(cp.pointNr),
              _td("${cp.progressive.toStringAsFixed(2)} m"),
              _td(cp.baseElevation != null ? "${cp.baseElevation!.toStringAsFixed(2)} m" : "-"),
              _td("${cp.actualCrestElevation.toStringAsFixed(2)} m"),
              _td("${cp.idealElevation.toStringAsFixed(2)} m"),
              _td("${cp.diffCm > 0 ? '+' : ''}${cp.diffCm.toStringAsFixed(1)} cm"),
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Text(
                  actionText,
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                    color: actionColor,
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _thWhite(String text) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(vertical: 3.5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 7.5,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _th(String text) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _td(String text) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 7)),
    );
  }

  static pw.Widget _buildSignatures() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        pw.Column(
          children: [
            pw.Container(width: 140, height: 1, color: PdfColors.grey700),
            pw.SizedBox(height: 3),
            pw.Text("Operario / Topógrafo", style: const pw.TextStyle(fontSize: 8)),
          ],
        ),
        pw.Column(
          children: [
            pw.Container(width: 140, height: 1, color: PdfColors.grey700),
            pw.SizedBox(height: 3),
            pw.Text("Director de Obra / Ing. Civil", style: const pw.TextStyle(fontSize: 8)),
          ],
        ),
      ],
    );
  }
}
