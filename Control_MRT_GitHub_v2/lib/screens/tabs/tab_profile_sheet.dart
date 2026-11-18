import 'package:flutter/material.dart';
import '../../models/project.dart';
import '../../models/control_point.dart';
import '../../models/survey_point.dart';
import '../../services/design_calc_service.dart';
import '../../widgets/profile_chart_painter.dart';
import '../../widgets/action_badge.dart';

class TabProfileSheet extends StatefulWidget {
  final Project project;

  const TabProfileSheet({
    Key? key,
    required this.project,
  }) : super(key: key);

  @override
  State<TabProfileSheet> createState() => _TabProfileSheetState();
}

class _TabProfileSheetState extends State<TabProfileSheet> {
  double _scaleX = 1.0;
  double _scaleY = 1.0;
  Offset _panOffset = Offset.zero;
  Offset? _touchPosition;
  SurveyPoint? _selectedPoint;

  String _filterAction = 'TODAS'; // 'TODAS', 'RELLENAR', 'CORTAR', 'OK'
  String _searchQuery = '';

  void _zoomIn() {
    setState(() {
      _scaleX = (_scaleX * 1.25).clamp(0.5, 8.0);
      _scaleY = (_scaleY * 1.25).clamp(0.5, 8.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _scaleX = (_scaleX / 1.25).clamp(0.5, 8.0);
      _scaleY = (_scaleY / 1.25).clamp(0.5, 8.0);
    });
  }

  void _resetZoom() {
    setState(() {
      _scaleX = 1.0;
      _scaleY = 1.0;
      _panOffset = Offset.zero;
      _touchPosition = null;
      _selectedPoint = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final summary = DesignCalcService.calculateMrtProfile(
      points: widget.project.points,
      params: widget.project.designParams,
    );

    // Filtrado de la planilla
    List<ControlPoint> filteredList = summary.controlPoints;
    if (_filterAction == 'RELLENAR') {
      filteredList = filteredList.where((p) => p.action == ActionType.rellenar).toList();
    } else if (_filterAction == 'CORTAR') {
      filteredList = filteredList.where((p) => p.action == ActionType.cortar).toList();
    } else if (_filterAction == 'OK') {
      filteredList = filteredList.where((p) => p.action == ActionType.ok).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filteredList = filteredList.where((p) {
        return p.pointNr.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.progressive.toString().contains(_searchQuery);
      }).toList();
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // ==========================================
        // 1. Gráfico del Perfil Longitudinal
        // ==========================================
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.show_chart, color: Color(0xFF0F172A)),
                        SizedBox(width: 6),
                        Text(
                          "Perfil Longitudinal MRT",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.zoom_in, size: 22),
                          onPressed: _zoomIn,
                          tooltip: "Acercar",
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.zoom_out, size: 22),
                          onPressed: _zoomOut,
                          tooltip: "Alejar",
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.restart_alt, size: 22),
                          onPressed: _resetZoom,
                          tooltip: "Restablecer vista",
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Leyenda de colores del perfil
                _buildLegend(),
                const SizedBox(height: 8),

                // Canvas interactivo con soporte de Pan y Zoom táctil
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: GestureDetector(
                      onScaleUpdate: (details) {
                        setState(() {
                          _panOffset += details.focalPointDelta;
                        });
                      },
                      onTapDown: (details) {
                        setState(() {
                          _touchPosition = details.localPosition;
                        });
                      },
                      child: CustomPaint(
                        painter: ProfileChartPainter(
                          project: widget.project,
                          summary: summary,
                          scaleX: _scaleX,
                          scaleY: _scaleY,
                          panOffset: _panOffset,
                          touchPosition: _touchPosition,
                        ),
                        child: Container(),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 6),
                const Text(
                  "Arraste con el dedo para desplazar el perfil o use los botones de zoom.",
                  style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ==========================================
        // 2. Resumen Rápido de Estado de Obra
        // ==========================================
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Expanded(
                child: _statusKpiBox(
                  label: "OK",
                  count: summary.countOk,
                  sub: "En tolerancia",
                  col: const Color(0xFF15803D),
                  bg: const Color(0xFFDCFCE7),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statusKpiBox(
                  label: "RELLENAR",
                  count: summary.countRellenar,
                  sub: "Máx: +${summary.maxRellenarCm.toStringAsFixed(0)} cm",
                  col: const Color(0xFF1D4ED8),
                  bg: const Color(0xFFDBEAFE),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statusKpiBox(
                  label: "CORTAR",
                  count: summary.countCortar,
                  sub: "Máx: -${summary.maxCortarCm.toStringAsFixed(0)} cm",
                  col: const Color(0xFFB91C1C),
                  bg: const Color(0xFFFEE2E2),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ==========================================
        // 3. Planilla de Control de Obra
        // ==========================================
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Planilla de Control de Rasante",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      "${filteredList.length} puntos",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Filtros de Acción y Búsqueda
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: "Buscar por prog. o pto...",
                            prefixIcon: Icon(Icons.search, size: 18),
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(fontSize: 12),
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val.trim();
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _filterAction,
                      underline: const SizedBox(),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                      items: const [
                        DropdownMenuItem(value: 'TODAS', child: Text("Todas")),
                        DropdownMenuItem(value: 'RELLENAR', child: Text("Rellenar")),
                        DropdownMenuItem(value: 'CORTAR', child: Text("Cortar")),
                        DropdownMenuItem(value: 'OK', child: Text("OK")),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _filterAction = val);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Tabla de Control de Obra
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 14,
                    headingRowHeight: 34,
                    dataRowMinHeight: 38,
                    dataRowMaxHeight: 44,
                    headingRowColor: MaterialStateProperty.all(const Color(0xFFF1F5F9)),
                    columns: const [
                      DataColumn(label: Text("Pto", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      DataColumn(label: Text("Prog (m)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      DataColumn(label: Text("Cota Base", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      DataColumn(label: Text("Cota Actual", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      DataColumn(label: Text("Cota Ideal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      DataColumn(label: Text("Dif. (cm)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      DataColumn(label: Text("Acción", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    ],
                    rows: filteredList.map((cp) {
                      return DataRow(
                        cells: [
                          DataCell(Text(cp.pointNr, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                          DataCell(Text("${cp.progressive.toStringAsFixed(2)} m", style: const TextStyle(fontSize: 11))),
                          DataCell(Text(cp.baseElevation != null ? "${cp.baseElevation!.toStringAsFixed(2)} m" : "-", style: const TextStyle(fontSize: 11))),
                          DataCell(Text("${cp.actualCrestElevation.toStringAsFixed(2)} m", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          DataCell(Text("${cp.idealElevation.toStringAsFixed(2)} m", style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626)))),
                          DataCell(Text(
                            "${cp.diffCm > 0 ? '+' : ''}${cp.diffCm.toStringAsFixed(1)} cm",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: cp.action == ActionType.rellenar
                                  ? const Color(0xFF1D4ED8)
                                  : (cp.action == ActionType.cortar ? const Color(0xFFB91C1C) : const Color(0xFF15803D)),
                            ),
                          )),
                          DataCell(ActionBadge(action: cp.action, diffCm: cp.diffCm, compact: true)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        _legendItem(const Color(0xFF78350F), "Base (Terreno Natural)"),
        _legendItem(const Color(0xFF1D4ED8), "Coronamiento Relevado"),
        _legendItem(const Color(0xFFDC2626), "Perfil Ideal Diseñado"),
        _legendItem(const Color(0xFF10B981), "Sombreado Rellenar"),
        _legendItem(const Color(0xFFEF4444), "Sombreado Cortar"),
      ],
    );
  }

  Widget _legendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 10, color: Color(0xFF334155), fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _statusKpiBox({
    required String label,
    required int count,
    required String sub,
    required Color col,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: col, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: col)),
              Text("$count", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: col)),
            ],
          ),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(fontSize: 9, color: col.withOpacity(0.85), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
