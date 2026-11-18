import 'dart:math';
import '../models/survey_point.dart';

class GeometryService {
  /// Ajusta el eje longitudinal principal mediante Análisis de Componentes Principales (PCA 2D)
  /// y proyecta cada punto sobre dicho eje para obtener su Progresiva (0.00 m a Longitud Total).
  static List<SurveyPoint> projectPointsOnLongitudinalAxis(
    List<SurveyPoint> points, {
    bool reverseDirection = false,
  }) {
    final validPoints = points.where((p) => p.x != null && p.y != null).toList();
    if (validPoints.length < 2) return points;

    // 1. Centroide (promedio de coordenadas planas)
    double sumX = 0;
    double sumY = 0;
    for (final p in validPoints) {
      sumX += p.x!;
      sumY += p.y!;
    }
    final double meanX = sumX / validPoints.length;
    final double meanY = sumY / validPoints.length;

    // 2. Matriz de covarianza
    double sXX = 0;
    double sYY = 0;
    double sXY = 0;
    for (final p in validPoints) {
      final dx = p.x! - meanX;
      final dy = p.y! - meanY;
      sXX += dx * dx;
      sYY += dy * dy;
      sXY += dx * dy;
    }

    // 3. Dirección del eje principal (vector propio dominante)
    final double theta = 0.5 * atan2(2 * sXY, sXX - sYY);
    double vx = cos(theta);
    double vy = sin(theta);

    // Normalizar orientación estándar: preferir proyección hacia el cuadrante positivo (oeste a este, o sur a norte)
    if (vx < 0 || (vx.abs() < 1e-6 && vy < 0)) {
      vx = -vx;
      vy = -vy;
    }

    if (reverseDirection) {
      vx = -vx;
      vy = -vy;
    }

    // 4. Proyección ortogonal de cada punto sobre el eje
    final List<double> projections = [];
    for (final p in points) {
      if (p.x != null && p.y != null) {
        final double t = (p.x! - meanX) * vx + (p.y! - meanY) * vy;
        projections.add(t);
      } else {
        projections.add(0.0);
      }
    }

    // 5. Ajuste para que la progresiva inicie en 0.00 m
    final double minT = projections.reduce(min);
    final List<SurveyPoint> projected = [];

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final double prog = double.parse((projections[i] - minT).toStringAsFixed(2));
      projected.add(p.copyWith(progressive: prog));
    }

    // Ordenar de menor a mayor progresiva
    projected.sort((a, b) => a.progressive.compareTo(b.progressive));
    return projected;
  }

  /// Algoritmo de separación automática por ventanas móviles / vecinos cercanos:
  /// En cada tramo longitudinal del MRT, los puntos de mayor cota 'h' corresponden al
  /// Coronamiento y los de menor cota 'h' a la Base (terreno natural).
  static List<SurveyPoint> autoClassifyBaseAndCrest(
    List<SurveyPoint> points, {
    double windowMeters = 6.0,
    double minHeightDiffThreshold = 0.40,
  }) {
    if (points.isEmpty) return [];

    // Ordenar por progresiva
    final sorted = List<SurveyPoint>.from(points)
      ..sort((a, b) => a.progressive.compareTo(b.progressive));

    final List<PointClassification> classifications =
        List.filled(sorted.length, PointClassification.coronamiento);

    // Paso 1: Analizar ventanas locales de progresiva
    for (int i = 0; i < sorted.length; i++) {
      if (sorted[i].classification == PointClassification.ignored) {
        classifications[i] = PointClassification.ignored;
        continue;
      }

      final currentProg = sorted[i].progressive;
      final currentElev = sorted[i].elevation;

      // Buscar vecinos dentro de la ventana de progresiva
      final neighbors = <int>[];
      for (int j = 0; j < sorted.length; j++) {
        if (sorted[j].classification == PointClassification.ignored) continue;
        if ((sorted[j].progressive - currentProg).abs() <= windowMeters) {
          neighbors.add(j);
        }
      }

      if (neighbors.length >= 2) {
        double minH = double.infinity;
        double maxH = -double.infinity;
        for (final idx in neighbors) {
          final h = sorted[idx].elevation;
          if (h < minH) minH = h;
          if (h > maxH) maxH = h;
        }

        final deltaH = maxH - minH;
        if (deltaH >= minHeightDiffThreshold) {
          final midH = (minH + maxH) / 2.0;
          if (currentElev >= midH) {
            classifications[i] = PointClassification.coronamiento;
          } else {
            classifications[i] = PointClassification.base;
          }
        }
      }
    }

    // Paso 2: Para puntos aislados o sin vecinos con suficiente desnivel,
    // comparar contra las envolventes globales de base y coronamiento
    final knownBases = <SurveyPoint>[];
    final knownCrests = <SurveyPoint>[];
    for (int i = 0; i < sorted.length; i++) {
      if (classifications[i] == PointClassification.base) {
        knownBases.add(sorted[i]);
      } else if (classifications[i] == PointClassification.coronamiento) {
        knownCrests.add(sorted[i]);
      }
    }

    // Si aún faltan clasificaciones o no hubo pares, usar umbral relativo
    if (knownBases.isEmpty && sorted.length >= 4) {
      // Si el algoritmo no detectó bases por espaciado irregular, dividir por el percentil 40
      final allElevations = sorted.map((p) => p.elevation).toList()..sort();
      final medianElev = allElevations[allElevations.length ~/ 2];
      for (int i = 0; i < sorted.length; i++) {
        if (sorted[i].elevation < medianElev - 0.25) {
          classifications[i] = PointClassification.base;
        }
      }
    }

    final List<SurveyPoint> classified = [];
    for (int i = 0; i < sorted.length; i++) {
      classified.add(sorted[i].copyWith(
        classification: classifications[i],
      ));
    }

    return classified;
  }

  /// Invierte el sentido del eje de progresivas (0 a L pasa a ser L a 0).
  static List<SurveyPoint> invertProgressives(List<SurveyPoint> points) {
    if (points.isEmpty) return [];
    double maxProg = 0;
    for (final p in points) {
      if (p.progressive > maxProg) maxProg = p.progressive;
    }

    final List<SurveyPoint> inverted = [];
    for (final p in points) {
      final newProg = double.parse((maxProg - p.progressive).toStringAsFixed(2));
      inverted.add(p.copyWith(progressive: newProg));
    }
    inverted.sort((a, b) => a.progressive.compareTo(b.progressive));
    return inverted;
  }
}
