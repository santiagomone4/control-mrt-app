import '../models/survey_point.dart';

class OpticalCalcService {
  /// Recalcula progresivas y cotas para una lista de puntos relevados con Nivel Óptico.
  /// 
  /// Criterio topográfico e hidráulico:
  /// - El nivel está estacionado sobre el MRT (0 m relativo).
  /// - Lado "Izquierda" o "Derecha" (mirando aguas abajo).
  /// - Plano visual de colimación (ej. 100.00 m).
  /// - Cota = Plano Visual - Lectura de Mira.
  /// - Progresiva 0.00 m en el punto más extremo a la izquierda.
  static List<SurveyPoint> recalculateOpticalSurvey({
    required List<SurveyPoint> inputPoints,
    required double visualPlane,
  }) {
    if (inputPoints.isEmpty) return [];

    // Separamos puntos según su posición relativa respecto al nivel
    // x_relativo: Nivel = 0, Izquierda = -distancia, Derecha = +distancia
    double minRelX = 0.0;
    for (final p in inputPoints) {
      final dist = (p.distanceFromLevel ?? 0.0).abs();
      double relX = 0.0;
      if (p.side == OpticalSide.izquierda) {
        relX = -dist;
      } else if (p.side == OpticalSide.derecha) {
        relX = dist;
      } else {
        relX = 0.0;
      }
      if (relX < minRelX) {
        minRelX = relX;
      }
    }

    final double offsetToZero = minRelX.abs();

    final List<SurveyPoint> updated = [];
    for (final p in inputPoints) {
      final dist = (p.distanceFromLevel ?? 0.0).abs();
      double relX = 0.0;
      if (p.side == OpticalSide.izquierda) {
        relX = -dist;
      } else if (p.side == OpticalSide.derecha) {
        relX = dist;
      } else {
        relX = 0.0;
      }

      // Progresiva continua ordenada de izquierda a derecha
      final progressive = double.parse((relX + offsetToZero).toStringAsFixed(2));

      // Cota = Plano Visual - Lectura de mira
      double calculatedElevation = p.elevation;
      final rod = (p.classification == PointClassification.coronamiento)
          ? (p.rodCoronamiento ?? p.rodBase)
          : (p.rodBase ?? p.rodCoronamiento);

      if (rod != null) {
        calculatedElevation = double.parse((visualPlane - rod).toStringAsFixed(3));
      }

      updated.add(p.copyWith(
        progressive: progressive,
        elevation: calculatedElevation,
      ));
    }

    // Ordenar por progresiva ascendente
    updated.sort((a, b) => a.progressive.compareTo(b.progressive));
    return updated;
  }
}
