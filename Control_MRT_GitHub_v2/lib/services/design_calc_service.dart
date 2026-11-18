import 'dart:math';
import '../models/survey_point.dart';
import '../models/design_params.dart';
import '../models/control_point.dart';

class MrtCalculationSummary {
  final double cotaBaseMin;
  final double cotaCoronamientoIdeal;
  final double cotaVertederosIdeal;
  final double totalLength;
  final List<ControlPoint> controlPoints;
  final List<SurveyPoint> basePoints;
  final List<SurveyPoint> crestPoints;
  final int countRellenar;
  final int countCortar;
  final int countOk;
  final double maxRellenarCm;
  final double maxCortarCm;

  MrtCalculationSummary({
    required this.cotaBaseMin,
    required this.cotaCoronamientoIdeal,
    required this.cotaVertederosIdeal,
    required this.totalLength,
    required this.controlPoints,
    required this.basePoints,
    required this.crestPoints,
    required this.countRellenar,
    required this.countCortar,
    required this.countOk,
    required this.maxRellenarCm,
    required this.maxCortarCm,
  });
}

class DesignCalcService {
  /// Calcula el perfil ideal de diseño y la planilla de control de obra (Corte/Relleno/OK)
  static MrtCalculationSummary calculateMrtProfile({
    required List<SurveyPoint> points,
    required MrtDesignParams params,
  }) {
    final activePoints = points.where((p) => p.classification != PointClassification.ignored).toList();
    final basePoints = activePoints.where((p) => p.classification == PointClassification.base).toList();
    final crestPoints = activePoints.where((p) => p.classification == PointClassification.coronamiento).toList();

    // Longitud total del MRT
    double totalLength = 0.0;
    for (final p in activePoints) {
      if (p.progressive > totalLength) totalLength = p.progressive;
    }

    // 1. Cota Base Mínima (punto más bajo en el terreno natural / fondo de cauce)
    double cotaBaseMin = 100.0;
    if (basePoints.isNotEmpty) {
      cotaBaseMin = basePoints.map((p) => p.elevation).reduce(min);
    } else if (crestPoints.isNotEmpty) {
      // Si no se relevaron bases aún, estimar base = crest - designHeight
      cotaBaseMin = crestPoints.map((p) => p.elevation).reduce(min) - params.designHeight;
    }

    // 2. Cotas Ideales
    final double cotaCoronamientoIdeal = double.parse(
      (cotaBaseMin + params.designHeight).toStringAsFixed(3),
    );
    final double cotaVertederosIdeal = double.parse(
      (cotaCoronamientoIdeal - params.spillwayDrop).toStringAsFixed(3),
    );

    // 3. Evaluar cada punto de coronamiento relevado
    final List<ControlPoint> controlPoints = [];
    int countRellenar = 0;
    int countCortar = 0;
    int countOk = 0;
    double maxRellenar = 0.0;
    double maxCortar = 0.0;

    // Ordenar puntos de coronamiento por progresiva
    crestPoints.sort((a, b) => a.progressive.compareTo(b.progressive));

    for (final crest in crestPoints) {
      final prog = crest.progressive;
      final cotaActual = crest.elevation;

      // Determinar la cota ideal en esta progresiva
      // Vertedero izquierdo: [0, leftSpillwayLength]
      // Vertedero derecho: [totalLength - rightSpillwayLength, totalLength]
      // Coronamiento central: resto
      final bool inLeftSpillway = prog <= params.leftSpillwayLength;
      final bool inRightSpillway = prog >= (totalLength - params.rightSpillwayLength);

      final double cotaIdeal = (inLeftSpillway || inRightSpillway)
          ? cotaVertederosIdeal
          : cotaCoronamientoIdeal;

      // Diferencia = Cota Ideal - Cota Relevada
      final double diffMeters = double.parse((cotaIdeal - cotaActual).toStringAsFixed(3));
      final double diffCm = double.parse((diffMeters * 100).toStringAsFixed(1));

      // Acción según tolerancia
      ActionType action;
      if (diffMeters > params.tolerance) {
        action = ActionType.rellenar;
        countRellenar++;
        if (diffCm > maxRellenar) maxRellenar = diffCm;
      } else if (diffMeters < -params.tolerance) {
        action = ActionType.cortar;
        countCortar++;
        if (diffCm.abs() > maxCortar) maxCortar = diffCm.abs();
      } else {
        action = ActionType.ok;
        countOk++;
      }

      // Buscar cota de base cercana para mostrar en la planilla
      double? nearbyBaseElev;
      double minDist = double.infinity;
      for (final bp in basePoints) {
        final d = (bp.progressive - prog).abs();
        if (d < minDist && d <= 10.0) {
          minDist = d;
          nearbyBaseElev = bp.elevation;
        }
      }

      controlPoints.add(ControlPoint(
        sourcePointId: crest.id,
        pointNr: crest.nr,
        progressive: prog,
        baseElevation: nearbyBaseElev,
        actualCrestElevation: cotaActual,
        idealElevation: cotaIdeal,
        diffMeters: diffMeters,
        diffCm: diffCm,
        action: action,
      ));
    }

    return MrtCalculationSummary(
      cotaBaseMin: cotaBaseMin,
      cotaCoronamientoIdeal: cotaCoronamientoIdeal,
      cotaVertederosIdeal: cotaVertederosIdeal,
      totalLength: totalLength,
      controlPoints: controlPoints,
      basePoints: basePoints,
      crestPoints: crestPoints,
      countRellenar: countRellenar,
      countCortar: countCortar,
      countOk: countOk,
      maxRellenarCm: maxRellenar,
      maxCortarCm: maxCortar,
    );
  }

  /// Devuelve la cota ideal en una progresiva continua cualquiera
  static double getIdealElevationAt({
    required double progressive,
    required double totalLength,
    required MrtDesignParams params,
    required double cotaCoronamientoIdeal,
    required double cotaVertederosIdeal,
  }) {
    if (progressive <= params.leftSpillwayLength ||
        progressive >= (totalLength - params.rightSpillwayLength)) {
      return cotaVertederosIdeal;
    }
    return cotaCoronamientoIdeal;
  }
}
