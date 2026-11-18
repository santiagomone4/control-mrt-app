import 'package:flutter/material.dart';
import '../../models/project.dart';
import '../../models/survey_point.dart';
import '../../services/geometry_service.dart';

class TabGnssReview extends StatefulWidget {
  final Project project;
  final Function(Project) onProjectUpdated;

  const TabGnssReview({
    Key? key,
    required this.project,
    required this.onProjectUpdated,
  }) : super(key: key);

  @override
  State<TabGnssReview> createState() => _TabGnssReviewState();
}

class _TabGnssReviewState extends State<TabGnssReview> {
  String _filter = 'TODOS'; // 'TODOS', 'CORONAMIENTO', 'BASE', 'IGNORADO'

  void _updateClassification(int index, PointClassification newClass) {
    final updatedList = List<SurveyPoint>.from(widget.project.points);
    updatedList[index] = updatedList[index].copyWith(classification: newClass);

    final updatedProj = widget.project.copyWith(points: updatedList);
    widget.onProjectUpdated(updatedProj);
    setState(() {});
  }

  void _reRunAutoClassification() {
    final auto = GeometryService.autoClassifyBaseAndCrest(widget.project.points);
    final updatedProj = widget.project.copyWith(points: auto);
    widget.onProjectUpdated(updatedProj);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Clasificación automática recalculada.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allPoints = widget.project.points;
    final crestCount = allPoints.where((p) => p.classification == PointClassification.coronamiento).length;
    final baseCount = allPoints.where((p) => p.classification == PointClassification.base).length;
    final ignoredCount = allPoints.where((p) => p.classification == PointClassification.ignored).length;

    List<SurveyPoint> filteredPoints = allPoints;
    if (_filter == 'CORONAMIENTO') {
      filteredPoints = allPoints.where((p) => p.classification == PointClassification.coronamiento).toList();
    } else if (_filter == 'BASE') {
      filteredPoints = allPoints.where((p) => p.classification == PointClassification.base).toList();
    } else if (_filter == 'IGNORADO') {
      filteredPoints = allPoints.where((p) => p.classification == PointClassification.ignored).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Revisión Rápida de Puntos GNSS"),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: "Re-ejecutar Clasificación Automática",
            onPressed: _reRunAutoClassification,
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner explicativo y contador
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: const Color(0xFFE2E8F0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    "Toque cualquier chip para cambiar la clasificación de un punto:",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                ),
                Text(
                  "Total: ${allPoints.length}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          ),

          // Filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                _filterChip('TODOS', 'Todos (${allPoints.length})'),
                const SizedBox(width: 6),
                _filterChip('CORONAMIENTO', 'Coronamiento ($crestCount)'),
                const SizedBox(width: 6),
                _filterChip('BASE', 'Base ($baseCount)'),
                const SizedBox(width: 6),
                _filterChip('IGNORADO', 'Descartados ($ignoredCount)'),
              ],
            ),
          ),

          // Lista de puntos
          Expanded(
            child: filteredPoints.isEmpty
                ? const Center(child: Text("No hay puntos en este filtro."))
                : ListView.builder(
                    itemCount: filteredPoints.length,
                    itemBuilder: (context, i) {
                      final p = filteredPoints[i];
                      final origIndex = allPoints.indexWhere((item) => item.id == p.id);

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Pto ${p.nr}  |  Prog: ${p.progressive.toStringAsFixed(2)} m",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                  ),
                                  Text(
                                    "Cota h: ${p.elevation.toStringAsFixed(3)} m",
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1E3A8A)),
                                  ),
                                ],
                              ),
                              if (p.x != null && p.y != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  "x: ${p.x!.toStringAsFixed(2)}  y: ${p.y!.toStringAsFixed(2)}",
                                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _classChoice(
                                    label: "Coronamiento",
                                    isSelected: p.classification == PointClassification.coronamiento,
                                    activeColor: const Color(0xFF1D4ED8),
                                    onTap: () => _updateClassification(origIndex, PointClassification.coronamiento),
                                  ),
                                  const SizedBox(width: 8),
                                  _classChoice(
                                    label: "Base",
                                    isSelected: p.classification == PointClassification.base,
                                    activeColor: const Color(0xFF78350F),
                                    onTap: () => _updateClassification(origIndex, PointClassification.base),
                                  ),
                                  const SizedBox(width: 8),
                                  _classChoice(
                                    label: "Ignorar",
                                    isSelected: p.classification == PointClassification.ignored,
                                    activeColor: const Color(0xFF64748B),
                                    onTap: () => _updateClassification(origIndex, PointClassification.ignored),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String filterKey, String label) {
    final isSelected = _filter == filterKey;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selectedColor: const Color(0xFFF59E0B),
      onSelected: (_) {
        setState(() {
          _filter = filterKey;
        });
      },
    );
  }

  Widget _classChoice({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? activeColor : const Color(0xFFCBD5E1),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }
}
