import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../models/project.dart';
import '../../models/survey_point.dart';
import '../../services/optical_calc_service.dart';
import '../../services/survx_parser_service.dart';
import '../../services/geometry_service.dart';
import 'tab_gnss_review.dart';

class TabDataEntry extends StatefulWidget {
  final Project project;
  final Function(Project) onProjectUpdated;

  const TabDataEntry({
    Key? key,
    required this.project,
    required this.onProjectUpdated,
  }) : super(key: key);

  @override
  State<TabDataEntry> createState() => _TabDataEntryState();
}

class _TabDataEntryState extends State<TabDataEntry> {
  final _uuid = const Uuid();

  // Controladores de metadatos
  late TextEditingController _nameController;
  late TextEditingController _estController;
  late TextEditingController _operatorController;
  late TextEditingController _obsController;

  // Controladores para carga manual Nivel Óptico
  PointClassification _selectedPointType = PointClassification.coronamiento;
  OpticalSide _selectedSide = OpticalSide.izquierda;
  final TextEditingController _distController = TextEditingController();
  final TextEditingController _rodController = TextEditingController();
  final TextEditingController _visualPlaneController = TextEditingController();

  bool _isProcessingFile = false;
  String? _fileStatusMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
    _estController = TextEditingController(text: widget.project.establishment);
    _operatorController = TextEditingController(text: widget.project.operatorName);
    _obsController = TextEditingController(text: widget.project.observations);
    _visualPlaneController = TextEditingController(
      text: widget.project.designParams.opticalVisualPlane.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _estController.dispose();
    _operatorController.dispose();
    _obsController.dispose();
    _distController.dispose();
    _rodController.dispose();
    _visualPlaneController.dispose();
    super.dispose();
  }

  void _saveMetadata() {
    final updated = widget.project.copyWith(
      name: _nameController.text.trim(),
      establishment: _estController.text.trim(),
      operatorName: _operatorController.text.trim(),
      observations: _obsController.text.trim(),
      designParams: widget.project.designParams.copyWith(
        opticalVisualPlane: double.tryParse(_visualPlaneController.text.replaceAll(',', '.')) ?? 100.0,
      ),
    );
    widget.onProjectUpdated(updated);
  }

  void _addOpticalPoint() {
    final dist = double.tryParse(_distController.text.replaceAll(',', '.'));
    final rod = double.tryParse(_rodController.text.replaceAll(',', '.'));
    final visualPlane = double.tryParse(_visualPlaneController.text.replaceAll(',', '.')) ?? 100.0;

    if (dist == null || rod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            dist == null
                ? "Ingrese la distancia desde el nivel óptico."
                : "Ingrese la lectura de mira para ${_selectedPointType == PointClassification.coronamiento ? 'Coronamiento' : 'Base'}.",
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final List<SurveyPoint> currentPoints = List.from(widget.project.points);
    final countType = currentPoints.where((p) => p.classification == _selectedPointType).length + 1;
    final prefix = _selectedPointType == PointClassification.coronamiento ? "C" : "B";
    final pointNr = "$prefix-$countType";

    // Crear punto individual según el tipo seleccionado explícitamente
    final newPoint = SurveyPoint(
      id: _uuid.v4(),
      nr: pointNr,
      side: _selectedSide,
      distanceFromLevel: dist,
      rodCoronamiento: _selectedPointType == PointClassification.coronamiento ? rod : null,
      rodBase: _selectedPointType == PointClassification.base ? rod : null,
      elevation: double.parse((visualPlane - rod).toStringAsFixed(3)),
      classification: _selectedPointType,
      isManualOptical: true,
    );
    currentPoints.add(newPoint);

    // Recalcular progresivas continuas y cotas
    final updatedPoints = OpticalCalcService.recalculateOpticalSurvey(
      inputPoints: currentPoints,
      visualPlane: visualPlane,
    );

    _rodController.clear();

    final updated = widget.project.copyWith(points: updatedPoints);
    widget.onProjectUpdated(updated);

    final typeLabel = _selectedPointType == PointClassification.coronamiento ? "Coronamiento" : "Base";
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Punto de $typeLabel ($pointNr) agregado. Total: ${updatedPoints.length} puntos."),
        backgroundColor: _selectedPointType == PointClassification.coronamiento
            ? const Color(0xFF1D4ED8)
            : const Color(0xFF78350F),
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }
    widget.onProjectUpdated(updated);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Punto agregado correctamente. Total: ${updatedPoints.length} puntos."),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _pickAndParseSurvXFile() async {
    try {
      setState(() {
        _isProcessingFile = true;
        _fileStatusMessage = "Seleccionando archivo SurvX...";
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _isProcessingFile = false;
          _fileStatusMessage = null;
        });
        return;
      }

      final fileBytes = result.files.first.bytes ??
          (result.files.first.path != null ? await File(result.files.first.path!).readAsBytes() : null);

      if (fileBytes == null) {
        throw Exception("No se pudieron leer los bytes del archivo.");
      }

      setState(() {
        _fileStatusMessage = "Analizando reporte GNSS de SurvX...";
      });

      final parserResult = SurvXParserService.parseSurvXExcel(fileBytes);

      if (parserResult.errorMessage != null) {
        throw Exception(parserResult.errorMessage);
      }

      setState(() {
        _fileStatusMessage = "Ajustando eje longitudinal (PCA) y proyectando progresivas...";
      });

      // 1. Proyectar sobre el eje longitudinal principal
      final projected = GeometryService.projectPointsOnLongitudinalAxis(
        parserResult.points,
        reverseDirection: widget.project.isReversedProgressive,
      );

      // 2. Clasificación automática (Base vs Coronamiento)
      final classified = GeometryService.autoClassifyBaseAndCrest(projected);

      final updated = widget.project.copyWith(
        points: classified,
        surveyMode: SurveyMode.gnss,
      );
      widget.onProjectUpdated(updated);

      setState(() {
        _isProcessingFile = false;
        _fileStatusMessage = "¡${classified.length} puntos importados y procesados con éxito!";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Éxito: Se importaron ${classified.length} puntos desde SurvX."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isProcessingFile = false;
        _fileStatusMessage = "Error: $e";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al importar: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _invertProgressives() {
    final inverted = GeometryService.invertProgressives(widget.project.points);
    final updated = widget.project.copyWith(
      points: inverted,
      isReversedProgressive: !widget.project.isReversedProgressive,
    );
    widget.onProjectUpdated(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Sentido de progresivas invertido (0 a L <-> L a 0).")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Metadatos
        _buildMetadataCard(),
        const SizedBox(height: 12),

        // Selector de Modo de Relevamiento
        _buildModeSelector(),
        const SizedBox(height: 12),

        // Formulario según modo seleccionado
        if (widget.project.surveyMode == SurveyMode.optical) ...[
          _buildOpticalEntryCard(),
        ] else ...[
          _buildGnssImportCard(),
        ],
        const SizedBox(height: 12),

        // Listado resumen de puntos relevados
        _buildPointsSummaryCard(),
      ],
    );
  }

  Widget _buildMetadataCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF0F172A), size: 20),
              SizedBox(width: 8),
              Text(
                "Metadatos del Proyecto",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: "Nombre del Proyecto / MRT"),
            onChanged: (_) => _saveMetadata(),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _estController,
            decoration: const InputDecoration(labelText: "Establecimiento / Lote / Campo"),
            onChanged: (_) => _saveMetadata(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _operatorController,
                  decoration: const InputDecoration(labelText: "Operario / Topógrafo"),
                  onChanged: (_) => _saveMetadata(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _visualPlaneController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: "Plano Visual (m)", helperText: "Ej. 100.00"),
                  onChanged: (_) => _saveMetadata(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _obsController,
            decoration: const InputDecoration(labelText: "Observaciones de Campo"),
            maxLines: 2,
            onChanged: (_) => _saveMetadata(),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Método de Relevamiento Topográfico",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text("Nivel Óptico (Manual)", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    selected: widget.project.surveyMode == SurveyMode.optical,
                    selectedColor: const Color(0xFFF59E0B),
                    onSelected: (val) {
                      if (val) {
                        final u = widget.project.copyWith(surveyMode: SurveyMode.optical);
                        widget.onProjectUpdated(u);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text("GNSS SurvX (.xlsx)", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    selected: widget.project.surveyMode == SurveyMode.gnss,
                    selectedColor: const Color(0xFFF59E0B),
                    onSelected: (val) {
                      if (val) {
                        final u = widget.project.copyWith(surveyMode: SurveyMode.gnss);
                        widget.onProjectUpdated(u);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpticalEntryCard() {
    final isCrest = _selectedPointType == PointClassification.coronamiento;
    final primaryColor = isCrest ? const Color(0xFF1D4ED8) : const Color(0xFF78350F);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        children: [
          Row(
            children: [
              Icon(Icons.straighten, color: primaryColor),
              const SizedBox(width: 8),
              const Text(
                "Carga con Nivel Óptico",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            "Nivel estacionado sobre el MRT (0 m). Mirando aguas abajo:",
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 12),

          // 1. Selector EXPLICITO: Tipo de Punto (Base o Coronamiento)
          const Text(
            "Elemento / Tipo de Punto a Relevar:",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 6),
          SegmentedButton<PointClassification>(
            segments: const [
              ButtonSegment(
                value: PointClassification.coronamiento,
                label: Text("CORONAMIENTO", style: TextStyle(fontWeight: FontWeight.bold)),
                icon: Icon(Icons.terrain),
              ),
              ButtonSegment(
                value: PointClassification.base,
                label: Text("BASE (TERRENO)", style: TextStyle(fontWeight: FontWeight.bold)),
                icon: Icon(Icons.vertical_align_bottom),
              ),
            ],
            selected: {_selectedPointType},
            onSelectionChanged: (newVal) {
              setState(() {
                _selectedPointType = newVal.first;
              });
            },
          ),
          const SizedBox(height: 12),

          // 2. Selector: Lado Izquierda / Derecha
          const Text(
            "Lado respecto al Nivel (Mirando aguas abajo):",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 6),
          SegmentedButton<OpticalSide>(
            segments: const [
              ButtonSegment(
                value: OpticalSide.izquierda,
                label: Text("IZQUIERDA", style: TextStyle(fontWeight: FontWeight.bold)),
                icon: Icon(Icons.arrow_back),
              ),
              ButtonSegment(
                value: OpticalSide.derecha,
                label: Text("DERECHA", style: TextStyle(fontWeight: FontWeight.bold)),
                icon: Icon(Icons.arrow_forward),
              ),
            ],
            selected: {_selectedSide},
            onSelectionChanged: (newVal) {
              setState(() {
                _selectedSide = newVal.first;
              });
            },
          ),
          const SizedBox(height: 12),

          // 3. Distancia desde el Nivel
          TextField(
            controller: _distController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: "Distancia desde el Nivel (m)",
              hintText: "Siempre valor positivo (ej. 15.00)",
              prefixIcon: Icon(Icons.linear_scale),
            ),
          ),
          const SizedBox(height: 10),

          // 4. Lectura de Mira individual para el tipo seleccionado
          TextField(
            controller: _rodController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: isCrest
                  ? "Lectura de Mira en CORONAMIENTO (m)"
                  : "Lectura de Mira en BASE (m)",
              hintText: isCrest ? "Ej. 1.450" : "Ej. 2.820",
              prefixIcon: Icon(isCrest ? Icons.terrain : Icons.vertical_align_bottom, color: primaryColor),
              helperText: isCrest
                  ? "Cota calculada = Plano Visual - Lectura Coronamiento"
                  : "Cota calculada = Plano Visual - Lectura Base",
            ),
          ),
          const SizedBox(height: 14),

          // Botón con texto y color según el tipo seleccionado
          ElevatedButton.icon(
            onPressed: _addOpticalPoint,
            icon: Icon(isCrest ? Icons.terrain : Icons.vertical_align_bottom, color: Colors.white),
            label: Text(
              isCrest ? "AGREGAR PUNTO DE CORONAMIENTO" : "AGREGAR PUNTO DE BASE",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGnssImportCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        children: [
          const Row(
            children: [
              Icon(Icons.satellite_alt, color: Color(0xFF1E3A8A)),
              SizedBox(width: 8),
              Text(
                "Importador SurvX GNSS (.xlsx / .xls)",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "Lee automáticamente el 'GNSS MEASUREMENT REPORT', descarta estaciones base, extrae coordenadas planas (x, y) y cota ortométrica (h), ajusta el eje y clasifica Base/Coronamiento.",
            style: TextStyle(fontSize: 11, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 14),

          ElevatedButton.icon(
            onPressed: _isProcessingFile ? null : _pickAndParseSurvXFile,
            icon: _isProcessingFile
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file),
            label: Text(_isProcessingFile ? "PROCESANDO..." : "SELECCIONAR REPORTE SURVX (.XLSX)"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),

          if (_fileStatusMessage != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Text(
                _fileStatusMessage!,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ),
          ],

          if (widget.project.points.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TabGnssReview(
                            project: widget.project,
                            onProjectUpdated: widget.onProjectUpdated,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.fact_check, size: 18),
                    label: const Text("REVISAR PUNTOS (BASE / CORON.)"),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: "Invertir Progresivas (0 <-> L)",
                  onPressed: _invertProgressives,
                  icon: const Icon(Icons.swap_horiz, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPointsSummaryCard() {
    final points = widget.project.points;
    final baseCount = points.where((p) => p.classification == PointClassification.base).length;
    final crestCount = points.where((p) => p.classification == PointClassification.coronamiento).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Puntos Relevados (${points.length})",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(4)),
                    child: Text("Coronamiento: $crestCount", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(4)),
                    child: Text("Base: $baseCount", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (points.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  "Aún no hay puntos cargados.\nAgregue lecturas de nivel o importe un archivo SurvX.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: points.length > 8 ? 8 : points.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final p = points[index];
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: p.classification == PointClassification.coronamiento
                        ? const Color(0xFF1D4ED8)
                        : const Color(0xFF78350F),
                    child: Text(
                      p.classification == PointClassification.coronamiento ? "C" : "B",
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text("Pto ${p.nr} - Prog: ${p.progressive.toStringAsFixed(2)} m", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text("Cota: ${p.elevation.toStringAsFixed(3)} m"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    onPressed: () {
                      final updatedList = List<SurveyPoint>.from(points)..removeAt(index);
                      final updated = widget.project.copyWith(points: updatedList);
                      widget.onProjectUpdated(updated);
                    },
                  ),
                );
              },
            ),

          if (points.length > 8)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  "+ ${points.length - 8} puntos más...",
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
