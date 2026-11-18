import 'dart:math';
import 'package:flutter/material.dart';
import '../models/survey_point.dart';
import '../models/project.dart';
import '../services/design_calc_service.dart';
import '../theme/app_theme.dart';

class ProfileChartPainter extends CustomPainter {
  final Project project;
  final MrtCalculationSummary summary;
  final double scaleX;
  final double scaleY;
  final Offset panOffset;
  final Offset? touchPosition;
  final Function(SurveyPoint? selectedPoint, double? touchProg, double? touchElev)? onPointSelected;

  ProfileChartPainter({
    required this.project,
    required this.summary,
    this.scaleX = 1.0,
    this.scaleY = 1.0,
    this.panOffset = Offset.zero,
    this.touchPosition,
    this.onPointSelected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final double marginL = 55.0;
    final double marginR = 20.0;
    final double marginT = 25.0;
    final double marginB = 40.0;

    final chartWidth = size.width - marginL - marginR;
    final chartHeight = size.height - marginT - marginB;

    // 1. Rango de Progresivas
    final double maxProg = summary.totalLength > 0 ? summary.totalLength : 100.0;
    final double minProg = 0.0;

    // 2. Rango de Cotas
    double minCota = summary.cotaBaseMin;
    double maxCota = summary.cotaCoronamientoIdeal;
    for (final p in project.points) {
      if (p.classification == PointClassification.ignored) continue;
      if (p.elevation < minCota) minCota = p.elevation;
      if (p.elevation > maxCota) maxCota = p.elevation;
    }
    minCota -= 0.6;
    maxCota += 0.6;
    final double deltaCota = (maxCota - minCota) > 0 ? (maxCota - minCota) : 1.0;

    // Funciones de mapeo con pan y zoom
    double toScreenX(double prog) {
      final norm = (prog - minProg) / (maxProg - minProg);
      return marginL + (norm * chartWidth * scaleX) + panOffset.dx;
    }

    double toScreenY(double cota) {
      final norm = (cota - minCota) / deltaCota;
      // Invertir eje Y: cota más alta arriba
      return (marginT + chartHeight) - (norm * chartHeight * scaleY) + panOffset.dy;
    }

    double toDataProg(double screenX) {
      final adjustedX = screenX - marginL - panOffset.dx;
      return minProg + (adjustedX / (chartWidth * scaleX)) * (maxProg - minProg);
    }

    // Clip al área interna del gráfico para no desbordar en zoom
    final clipRect = Rect.fromLTWH(marginL, marginT, chartWidth, chartHeight);
    canvas.save();
    canvas.clipRect(clipRect);

    // Fondo del gráfico
    final bgPaint = Paint()..color = const Color(0xFFFAFBFD);
    canvas.drawRect(clipRect, bgPaint);

    // ==========================================
    // Grilla de Cotas (Líneas Horizontales)
    // ==========================================
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0;

    final cotaStep = deltaCota > 8 ? 2.0 : (deltaCota > 3 ? 1.0 : 0.5);
    final firstCotaGrid = (minCota / cotaStep).ceil() * cotaStep;
    for (double c = firstCotaGrid; c <= maxCota; c += cotaStep) {
      final y = toScreenY(c);
      canvas.drawLine(Offset(marginL, y), Offset(marginL + chartWidth, y), gridPaint);
    }

    // Grilla de Progresivas (Líneas Verticales)
    final progStep = maxProg > 150 ? 50.0 : (maxProg > 50 ? 20.0 : 10.0);
    for (double p = 0; p <= maxProg; p += progStep) {
      final x = toScreenX(p);
      canvas.drawLine(Offset(x, marginT), Offset(x, marginT + chartHeight), gridPaint);
    }

    // ==========================================
    // Sombreado de Relleno y Corte entre Relevado e Ideal
    // ==========================================
    final crestPoints = summary.crestPoints;
    if (crestPoints.length >= 2) {
      final fillPaint = Paint()
        ..color = const Color(0x603FA34D) // Naturaleza & Crecimiento #3FA34D (RELLENAR)
        ..style = PaintingStyle.fill;

      final cutPaint = Paint()
        ..color = const Color(0x60C53030) // Rojo rasante #C53030 (CORTAR)
        ..style = PaintingStyle.fill;

      for (int i = 0; i < crestPoints.length - 1; i++) {
        final p1 = crestPoints[i];
        final p2 = crestPoints[i + 1];

        final x1 = toScreenX(p1.progressive);
        final y1Actual = toScreenY(p1.elevation);
        final y1Ideal = toScreenY(DesignCalcService.getIdealElevationAt(
          progressive: p1.progressive,
          totalLength: maxProg,
          params: project.designParams,
          cotaCoronamientoIdeal: summary.cotaCoronamientoIdeal,
          cotaVertederosIdeal: summary.cotaVertederosIdeal,
        ));

        final x2 = toScreenX(p2.progressive);
        final y2Actual = toScreenY(p2.elevation);
        final y2Ideal = toScreenY(DesignCalcService.getIdealElevationAt(
          progressive: p2.progressive,
          totalLength: maxProg,
          params: project.designParams,
          cotaCoronamientoIdeal: summary.cotaCoronamientoIdeal,
          cotaVertederosIdeal: summary.cotaVertederosIdeal,
        ));

        final path = Path()
          ..moveTo(x1, y1Actual)
          ..lineTo(x2, y2Actual)
          ..lineTo(x2, y2Ideal)
          ..lineTo(x1, y1Ideal)
          ..close();

        // Si ideal > actual (en pantalla Y ideal es menor que Y actual) -> Rellenar
        final avgDiff = ((y1Actual - y1Ideal) + (y2Actual - y2Ideal)) / 2.0;
        if (avgDiff > 0) {
          canvas.drawPath(path, fillPaint);
        } else {
          canvas.drawPath(path, cutPaint);
        }
      }
    }

    // ==========================================
    // 1. Línea de Base (Terreno Natural / Suelo)
    // ==========================================
    final basePoints = summary.basePoints;
    if (basePoints.isNotEmpty) {
      final baseLinePaint = Paint()
        ..color = AppTheme.colorBaseTerreno // Suelo & Base #6D4C41
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;

      final basePath = Path();
      basePath.moveTo(toScreenX(basePoints.first.progressive), toScreenY(basePoints.first.elevation));
      for (int i = 1; i < basePoints.length; i++) {
        basePath.lineTo(toScreenX(basePoints[i].progressive), toScreenY(basePoints[i].elevation));
      }
      canvas.drawPath(basePath, baseLinePaint);

      // Puntos de base
      final baseDotPaint = Paint()
        ..color = const Color(0xFF8D6E63)
        ..style = PaintingStyle.fill;
      for (final bp in basePoints) {
        canvas.drawCircle(Offset(toScreenX(bp.progressive), toScreenY(bp.elevation)), 4.0, baseDotPaint);
      }
    }

    // ==========================================
    // 2. Línea de Coronamiento Relevado (Autoridad & Precisión)
    // ==========================================
    if (crestPoints.isNotEmpty) {
      final crestLinePaint = Paint()
        ..color = AppTheme.autoridadNavy // Autoridad & Confianza #112B4F
        ..strokeWidth = 2.8
        ..style = PaintingStyle.stroke;

      final crestPath = Path();
      crestPath.moveTo(toScreenX(crestPoints.first.progressive), toScreenY(crestPoints.first.elevation));
      for (int i = 1; i < crestPoints.length; i++) {
        crestPath.lineTo(toScreenX(crestPoints[i].progressive), toScreenY(crestPoints[i].elevation));
      }
      canvas.drawPath(crestPath, crestLinePaint);

      // Puntos de coronamiento con halo Agua & Precisión #4FA3D1
      final crestDotPaint = Paint()
        ..color = AppTheme.autoridadNavy
        ..style = PaintingStyle.fill;
      final crestStrokePaint = Paint()
        ..color = AppTheme.precisionCyan
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke;

      for (final cp in crestPoints) {
        final pt = Offset(toScreenX(cp.progressive), toScreenY(cp.elevation));
        canvas.drawCircle(pt, 5.0, crestDotPaint);
        canvas.drawCircle(pt, 5.0, crestStrokePaint);
      }
    }

    // ==========================================
    // 3. Línea de Perfil Ideal (Escalonado de Vertederos)
    // ==========================================
    final idealLinePaint = Paint()
      ..color = AppTheme.colorCortar // Rojo rasante #C53030
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final leftL = project.designParams.leftSpillwayLength;
    final rightL = max(leftL, maxProg - project.designParams.rightSpillwayLength);

    final yVert = toScreenY(summary.cotaVertederosIdeal);
    final yCrest = toScreenY(summary.cotaCoronamientoIdeal);

    final idealPath = Path()
      ..moveTo(toScreenX(0), yVert)
      ..lineTo(toScreenX(leftL), yVert) // Tramo vertedero izquierdo
      ..lineTo(toScreenX(leftL), yCrest) // Escalón subida al coronamiento
      ..lineTo(toScreenX(rightL), yCrest) // Tramo coronamiento central
      ..lineTo(toScreenX(rightL), yVert) // Escalón bajada a vertedero derecho
      ..lineTo(toScreenX(maxProg), yVert); // Tramo vertedero derecho

    canvas.drawPath(idealPath, idealLinePaint);

    // ==========================================
    // Interacción Touch (Cursor y Tooltip)
    // ==========================================
    if (touchPosition != null && clipRect.contains(touchPosition!)) {
      final progTouch = toDataProg(touchPosition!.dx);

      // Buscar punto de coronamiento más cercano
      SurveyPoint? nearestPoint;
      double minDistance = double.infinity;
      for (final cp in crestPoints) {
        final d = (cp.progressive - progTouch).abs();
        if (d < minDistance) {
          minDistance = d;
          nearestPoint = cp;
        }
      }

      if (nearestPoint != null && minDistance <= 15.0) {
        final px = toScreenX(nearestPoint.progressive);
        final pyActual = toScreenY(nearestPoint.elevation);
        final pyIdeal = toScreenY(DesignCalcService.getIdealElevationAt(
          progressive: nearestPoint.progressive,
          totalLength: maxProg,
          params: project.designParams,
          cotaCoronamientoIdeal: summary.cotaCoronamientoIdeal,
          cotaVertederosIdeal: summary.cotaVertederosIdeal,
        ));

        // Línea vertical crosshair
        final crosshairPaint = Paint()
          ..color = const Color(0xFF64748B)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(px, marginT), Offset(px, marginT + chartHeight), crosshairPaint);

        // Círculo resaltado en coronamiento
        final highlightPaint = Paint()
          ..color = const Color(0xFFF59E0B)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(px, pyActual), 7.0, highlightPaint);
      }
    }

    canvas.restore();

    // ==========================================
    // Ejes y Etiquetas Exteriores (IBM Plex Sans)
    // ==========================================
    final axisPaint = Paint()
      ..color = AppTheme.datosCharcoal
      ..strokeWidth = 1.5;

    // Eje Y (Izquierdo)
    canvas.drawLine(Offset(marginL, marginT), Offset(marginL, marginT + chartHeight), axisPaint);
    // Eje X (Inferior)
    canvas.drawLine(Offset(marginL, marginT + chartHeight), Offset(marginL + chartWidth, marginT + chartHeight), axisPaint);

    // Textos de Cotas (Eje Y)
    const textStyle = TextStyle(
      fontFamily: AppTheme.fontHeading,
      color: Color(0xFF62686E),
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );

    for (double c = firstCotaGrid; c <= maxCota; c += cotaStep) {
      final y = toScreenY(c);
      if (y >= marginT - 5 && y <= marginT + chartHeight + 5) {
        final span = TextSpan(text: c.toStringAsFixed(1), style: textStyle);
        final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(canvas, Offset(marginL - tp.width - 6, y - tp.height / 2));
      }
    }

    // Textos de Progresivas (Eje X)
    for (double p = 0; p <= maxProg; p += progStep) {
      final x = toScreenX(p);
      if (x >= marginL - 5 && x <= marginL + chartWidth + 5) {
        final span = TextSpan(text: '${p.toInt()}m', style: textStyle);
        final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(canvas, Offset(x - tp.width / 2, marginT + chartHeight + 6));
      }
    }

    // Título de Ejes
    const labelProgSpan = TextSpan(
      text: "Progresiva (m)",
      style: TextStyle(
        fontFamily: AppTheme.fontHeading,
        color: AppTheme.autoridadNavy,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
    final tpProg = TextPainter(text: labelProgSpan, textDirection: TextDirection.ltr);
    tpProg.layout();
    tpProg.paint(canvas, Offset(marginL + (chartWidth - tpProg.width) / 2, size.height - 18));
  }

  @override
  bool shouldRepaint(covariant ProfileChartPainter oldDelegate) {
    return true;
  }
}
