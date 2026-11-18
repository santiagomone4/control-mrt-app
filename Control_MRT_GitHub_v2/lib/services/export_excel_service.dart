import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../models/project.dart';
import '../models/control_point.dart';
import 'design_calc_service.dart';

class ExportExcelService {
  /// Genera un archivo Excel (.xlsx) completo con 3 pestañas especializadas
  static List<int>? generateExcelReport({
    required Project project,
    required MrtCalculationSummary summary,
  }) {
    final excel = Excel.createExcel();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    // Renombrar la hoja por defecto o crear las 3 requeridas
    final String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheet, 'Resumen y Diseño');

    final sheetResumen = excel['Resumen y Diseño'];
    final sheetControl = excel['Perfil Procesado (Control)'];
    final sheetCrudos = excel['Datos Crudos'];

    // ==========================================
    // 1. PESTAÑA: Resumen y Diseño
    // ==========================================
    sheetResumen.appendRow([TextCellValue('REPORTE DE CONTROL DE OBRA - MRT')]);
    sheetResumen.appendRow([TextCellValue('Metadatos del Proyecto')]);
    sheetResumen.appendRow([TextCellValue('Nombre:'), TextCellValue(project.name)]);
    sheetResumen.appendRow([TextCellValue('Establecimiento/Lote:'), TextCellValue(project.establishment)]);
    sheetResumen.appendRow([TextCellValue('Fecha:'), TextCellValue(dateFormat.format(project.date))]);
    sheetResumen.appendRow([TextCellValue('Operario:'), TextCellValue(project.operatorName)]);
    sheetResumen.appendRow([TextCellValue('Método de Relevamiento:'), TextCellValue(project.surveyMode == SurveyMode.gnss ? 'GNSS (SurvX)' : 'Nivel Óptico')]);
    sheetResumen.appendRow([TextCellValue('Observaciones:'), TextCellValue(project.observations)]);
    sheetResumen.appendRow([TextCellValue('')]);

    sheetResumen.appendRow([TextCellValue('Parámetros Hidráulicos y de Diseño')]);
    sheetResumen.appendRow([TextCellValue('Cota Mínima Base (Terreno Natural):'), FloatCellValue(summary.cotaBaseMin), TextCellValue('m')]);
    sheetResumen.appendRow([TextCellValue('Altura de Diseño del Coronamiento:'), FloatCellValue(project.designParams.designHeight), TextCellValue('m')]);
    sheetResumen.appendRow([TextCellValue('Cota Coronamiento Ideal:'), FloatCellValue(summary.cotaCoronamientoIdeal), TextCellValue('m')]);
    sheetResumen.appendRow([TextCellValue('Desnivel de Vertederos:'), FloatCellValue(project.designParams.spillwayDrop), TextCellValue('m')]);
    sheetResumen.appendRow([TextCellValue('Cota Vertederos Ideal:'), FloatCellValue(summary.cotaVertederosIdeal), TextCellValue('m')]);
    sheetResumen.appendRow([TextCellValue('Longitud Vertedero Izquierdo:'), FloatCellValue(project.designParams.leftSpillwayLength), TextCellValue('m')]);
    sheetResumen.appendRow([TextCellValue('Longitud Vertedero Derecho:'), FloatCellValue(project.designParams.rightSpillwayLength), TextCellValue('m')]);
    sheetResumen.appendRow([TextCellValue('Tolerancia de Obra:'), FloatCellValue(project.designParams.tolerance * 100), TextCellValue('cm')]);
    sheetResumen.appendRow([TextCellValue('')]);

    sheetResumen.appendRow([TextCellValue('Resumen de Movimiento de Suelos / Control')]);
    sheetResumen.appendRow([TextCellValue('Longitud Total Relevada:'), FloatCellValue(summary.totalLength), TextCellValue('m')]);
    sheetResumen.appendRow([TextCellValue('Puntos dentro de Tolerancia (OK):'), IntCellValue(summary.countOk)]);
    sheetResumen.appendRow([TextCellValue('Puntos a RELLENAR:'), IntCellValue(summary.countRellenar)]);
    sheetResumen.appendRow([TextCellValue('Puntos a CORTAR:'), IntCellValue(summary.countCortar)]);
    sheetResumen.appendRow([TextCellValue('Espesor Máximo de Relleno:'), FloatCellValue(summary.maxRellenarCm), TextCellValue('cm')]);
    sheetResumen.appendRow([TextCellValue('Espesor Máximo de Corte:'), FloatCellValue(summary.maxCortarCm), TextCellValue('cm')]);

    // ==========================================
    // 2. PESTAÑA: Perfil Procesado (Control de Obra)
    // ==========================================
    sheetControl.appendRow([
      TextCellValue('Punto'),
      TextCellValue('Progresiva (m)'),
      TextCellValue('Cota Base (m)'),
      TextCellValue('Cota Coronamiento Actual (m)'),
      TextCellValue('Cota Ideal (m)'),
      TextCellValue('Diferencia (m)'),
      TextCellValue('Diferencia (cm)'),
      TextCellValue('Acción Recomendada'),
    ]);

    for (final cp in summary.controlPoints) {
      String accion = 'OK';
      if (cp.action == ActionType.rellenar) accion = 'RELLENAR';
      if (cp.action == ActionType.cortar) accion = 'CORTAR';

      sheetControl.appendRow([
        TextCellValue(cp.pointNr),
        FloatCellValue(cp.progressive),
        cp.baseElevation != null ? FloatCellValue(cp.baseElevation!) : TextCellValue('-'),
        FloatCellValue(cp.actualCrestElevation),
        FloatCellValue(cp.idealElevation),
        FloatCellValue(cp.diffMeters),
        FloatCellValue(cp.diffCm),
        TextCellValue(accion),
      ]);
    }

    // ==========================================
    // 3. PESTAÑA: Datos Crudos Relevamiento
    // ==========================================
    sheetCrudos.appendRow([
      TextCellValue('ID / Nr'),
      TextCellValue('Lado / Modo'),
      TextCellValue('Distancia Nivel (m)'),
      TextCellValue('Lectura Coronamiento (m)'),
      TextCellValue('Lectura Base (m)'),
      TextCellValue('Coord. Este / x'),
      TextCellValue('Coord. Norte / y'),
      TextCellValue('Cota h (m)'),
      TextCellValue('Progresiva Calculada (m)'),
      TextCellValue('Clasificación Asignada'),
    ]);

    for (final p in project.points) {
      sheetCrudos.appendRow([
        TextCellValue(p.nr),
        TextCellValue(p.side?.name ?? (p.isManualOptical ? 'Óptico' : 'GNSS')),
        p.distanceFromLevel != null ? FloatCellValue(p.distanceFromLevel!) : TextCellValue('-'),
        p.rodCoronamiento != null ? FloatCellValue(p.rodCoronamiento!) : TextCellValue('-'),
        p.rodBase != null ? FloatCellValue(p.rodBase!) : TextCellValue('-'),
        p.x != null ? FloatCellValue(p.x!) : TextCellValue('-'),
        p.y != null ? FloatCellValue(p.y!) : TextCellValue('-'),
        FloatCellValue(p.elevation),
        FloatCellValue(p.progressive),
        TextCellValue(p.classification.name.toUpperCase()),
      ]);
    }

    return excel.save();
  }
}
