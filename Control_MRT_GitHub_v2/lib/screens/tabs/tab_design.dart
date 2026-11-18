import 'package:flutter/material.dart';
import '../../models/project.dart';
import '../../models/design_params.dart';
import '../../services/design_calc_service.dart';
import '../../widgets/kpi_card.dart';

class TabDesign extends StatefulWidget {
  final Project project;
  final Function(Project) onProjectUpdated;

  const TabDesign({
    Key? key,
    required this.project,
    required this.onProjectUpdated,
  }) : super(key: key);

  @override
  State<TabDesign> createState() => _TabDesignState();
}

class _TabDesignState extends State<TabDesign> {
  late TextEditingController _heightController;
  late TextEditingController _spillwayDropController;
  late TextEditingController _leftSpillwayController;
  late TextEditingController _rightSpillwayController;
  late TextEditingController _toleranceController;

  @override
  void initState() {
    super.initState();
    final p = widget.project.designParams;
    _heightController = TextEditingController(text: p.designHeight.toStringAsFixed(2));
    _spillwayDropController = TextEditingController(text: p.spillwayDrop.toStringAsFixed(2));
    _leftSpillwayController = TextEditingController(text: p.leftSpillwayLength.toStringAsFixed(1));
    _rightSpillwayController = TextEditingController(text: p.rightSpillwayLength.toStringAsFixed(1));
    _toleranceController = TextEditingController(text: (p.tolerance * 100).toStringAsFixed(0));
  }

  @override
  void dispose() {
    _heightController.dispose();
    _spillwayDropController.dispose();
    _leftSpillwayController.dispose();
    _rightSpillwayController.dispose();
    _toleranceController.dispose();
    super.dispose();
  }

  void _onParamChanged() {
    final h = double.tryParse(_heightController.text.replaceAll(',', '.')) ?? 2.50;
    final drop = double.tryParse(_spillwayDropController.text.replaceAll(',', '.')) ?? 0.30;
    final leftL = double.tryParse(_leftSpillwayController.text.replaceAll(',', '.')) ?? 15.0;
    final rightL = double.tryParse(_rightSpillwayController.text.replaceAll(',', '.')) ?? 15.0;
    final tolCm = double.tryParse(_toleranceController.text.replaceAll(',', '.')) ?? 5.0;

    final newParams = widget.project.designParams.copyWith(
      designHeight: h,
      spillwayDrop: drop,
      leftSpillwayLength: leftL,
      rightSpillwayLength: rightL,
      tolerance: tolCm / 100.0,
    );

    final updated = widget.project.copyWith(designParams: newParams);
    widget.onProjectUpdated(updated);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final summary = DesignCalcService.calculateMrtProfile(
      points: widget.project.points,
      params: widget.project.designParams,
    );

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Resultados en tiempo real
        const Text(
          "Cotas Ideales Resultantes (Hidráulica)",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: KpiCard(
                title: "Cota Base Mínima",
                value: "${summary.cotaBaseMin.toStringAsFixed(2)} m",
                subtitle: "Terreno Natural (fondo)",
                icon: Icons.vertical_align_bottom,
                color: const Color(0xFF78350F),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: KpiCard(
                title: "Coronamiento Ideal",
                value: "${summary.cotaCoronamientoIdeal.toStringAsFixed(2)} m",
                subtitle: "Base + Altura de Diseño",
                icon: Icons.shield,
                color: const Color(0xFF1E3A8A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: KpiCard(
                title: "Cota Vertederos",
                value: "${summary.cotaVertederosIdeal.toStringAsFixed(2)} m",
                subtitle: "Desnivel -${widget.project.designParams.spillwayDrop}m",
                icon: Icons.water,
                color: const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: KpiCard(
                title: "Longitud Total",
                value: "${summary.totalLength.toStringAsFixed(1)} m",
                subtitle: "Eje Longitudinal MRT",
                icon: Icons.linear_scale,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Tarjeta de Parámetros de Diseño
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            children: [
              const Row(
                children: [
                  Icon(Icons.tune, color: Color(0xFF0F172A)),
                  SizedBox(width: 8),
                  Text(
                    "Configuración del Perfil Ideal MRT",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Altura de diseño
              TextField(
                controller: _heightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "Altura de Diseño del Coronamiento (m)",
                  helperText: "Metros por encima de la Base Mínima registrada",
                  prefixIcon: Icon(Icons.height),
                ),
                onChanged: (_) => _onParamChanged(),
              ),
              const SizedBox(height: 12),

              // Desnivel de vertederos
              TextField(
                controller: _spillwayDropController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "Desnivel de Vertederos (m)",
                  helperText: "Drop respecto al coronamiento (defecto 0.30 m)",
                  prefixIcon: Icon(Icons.water_drop),
                ),
                onChanged: (_) => _onParamChanged(),
              ),
              const SizedBox(height: 12),

              // Longitudes de vertederos izquierdo y derecho
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _leftSpillwayController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: "Vertedero Izquierdo (m)",
                        helperText: "Desde Progresiva 0.00",
                      ),
                      onChanged: (_) => _onParamChanged(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _rightSpillwayController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: "Vertedero Derecho (m)",
                        helperText: "Desde el extremo final",
                      ),
                      onChanged: (_) => _onParamChanged(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Tolerancia de obra
              TextField(
                controller: _toleranceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "Tolerancia de Obra (cm)",
                  helperText: "Diferencia aceptable para marcar 'OK' (ej. ±5 cm)",
                  prefixIcon: Icon(Icons.check_box_outlined),
                ),
                onChanged: (_) => _onParamChanged(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Esquema visual de la geometría del terraplén
        _buildGeometryDiagram(summary),
      ],
    );
  }

  Widget _buildGeometryDiagram(MrtCalculationSummary summary) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Esquema Geométrico de Vertederos y Coronamiento",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 8),
            Container(
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                children: [
                  // Vertedero Izquierdo
                  Expanded(
                    flex: widget.project.designParams.leftSpillwayLength.toInt().clamp(5, 40),
                    child: Container(
                      margin: const EdgeInsets.only(top: 24, bottom: 4, left: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        border: Border.all(color: const Color(0xFFDC2626), width: 1.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Vert. Izq\n${widget.project.designParams.leftSpillwayLength}m",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                      ),
                    ),
                  ),
                  // Coronamiento Central
                  Expanded(
                    flex: 60,
                    child: Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 4, left: 2, right: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        border: Border.all(color: const Color(0xFF1D4ED8), width: 1.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Coronamiento Central (${summary.cotaCoronamientoIdeal.toStringAsFixed(2)} m)\nAltura: ${widget.project.designParams.designHeight}m s/base",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                      ),
                    ),
                  ),
                  // Vertedero Derecho
                  Expanded(
                    flex: widget.project.designParams.rightSpillwayLength.toInt().clamp(5, 40),
                    child: Container(
                      margin: const EdgeInsets.only(top: 24, bottom: 4, right: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        border: Border.all(color: const Color(0xFFDC2626), width: 1.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Vert. Der\n${widget.project.designParams.rightSpillwayLength}m",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
