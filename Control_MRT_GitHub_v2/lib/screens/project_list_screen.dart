import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/project.dart';
import '../models/survey_point.dart';
import '../models/design_params.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'project_detail_screen.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({Key? key}) : super(key: key);

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  final _uuid = const Uuid();
  final _dateFormat = DateFormat('dd/MM/yyyy');
  List<Project> _projects = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    final list = await DatabaseService.getAllProjects();
    setState(() {
      _projects = list;
      _isLoading = false;
    });
  }

  Future<void> _createNewProject() async {
    final nameCtrl = TextEditingController(text: "MRT-0${_projects.length + 1}");
    final estCtrl = TextEditingController();
    SurveyMode selectedMode = SurveyMode.optical;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Nuevo Proyecto de MRT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: "Nombre del Proyecto / MRT"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: estCtrl,
                      decoration: const InputDecoration(labelText: "Establecimiento / Lote"),
                    ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Método de Relevamiento:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text("Nivel Óptico"),
                            selected: selectedMode == SurveyMode.optical,
                            selectedColor: const Color(0xFFF59E0B),
                            onSelected: (val) {
                              if (val) setDialogState(() => selectedMode = SurveyMode.optical);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text("GNSS SurvX"),
                            selected: selectedMode == SurveyMode.gnss,
                            selectedColor: const Color(0xFFF59E0B),
                            onSelected: (val) {
                              if (val) setDialogState(() => selectedMode = SurveyMode.gnss);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("CANCELAR"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A)),
                  child: const Text("CREAR"),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      final newProj = Project(
        id: _uuid.v4(),
        name: nameCtrl.text.trim().isEmpty ? "Nuevo MRT" : nameCtrl.text.trim(),
        establishment: estCtrl.text.trim(),
        date: DateTime.now(),
        surveyMode: selectedMode,
        designParams: MrtDesignParams(),
      );

      await DatabaseService.saveProject(newProj);
      await _loadProjects();

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProjectDetailScreen(initialProject: newProj)),
        ).then((_) => _loadProjects());
      }
    }
  }

  Future<void> _duplicateProject(String id) async {
    try {
      await DatabaseService.duplicateProject(id);
      await _loadProjects();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Proyecto duplicado con éxito."), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al duplicar: $e")),
      );
    }
  }

  Future<void> _deleteProject(Project project) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("¿Eliminar Proyecto?", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text("¿Confirma que desea eliminar '${project.name}'? Esta acción no se puede deshacer."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCELAR")),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("ELIMINAR"),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await DatabaseService.deleteProject(project.id);
      await _loadProjects();
    }
  }

  Future<void> _importProject() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) return;

      String jsonContent;
      if (result.files.first.bytes != null) {
        jsonContent = String.fromCharCodes(result.files.first.bytes!);
      } else if (result.files.first.path != null) {
        jsonContent = await File(result.files.first.path!).readAsString();
      } else {
        throw Exception("No se pudo leer el archivo seleccionado.");
      }

      final imported = await DatabaseService.importProjectFromJson(jsonContent);
      await _loadProjects();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Proyecto '${imported.name}' importado con éxito."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al importar archivo: $e"), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _projects.where((p) {
      final q = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(q) || p.establishment.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Control de Obra MRT"),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: "Importar Proyecto (.mrt / .json)",
            onPressed: _importProject,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Actualizar",
            onPressed: _loadProjects,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewProject,
        backgroundColor: AppTheme.precisionCyan,
        foregroundColor: AppTheme.autoridadNavy,
        icon: const Icon(Icons.add, size: 22),
        label: const Text(
          "NUEVO MRT",
          style: TextStyle(
            fontFamily: AppTheme.fontHeading,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Buscar proyectos o establecimientos...",
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),

          // Lista de Proyectos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.landscape_outlined, size: 64, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 12),
                            const Text(
                              "No se encontraron proyectos",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Toque 'NUEVO MRT' para iniciar un relevamiento.",
                              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final p = filtered[index];
                          return Card(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProjectDetailScreen(initialProject: p),
                                  ),
                                ).then((_) => _loadProjects());
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Icono según modo de relevamiento (Paleta Oficial)
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: p.surveyMode == SurveyMode.gnss
                                            ? const Color(0xFFE8F4FA) // Agua & Precisión suave
                                            : AppTheme.sueloWarm,     // Suelo & Base
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppTheme.sueloBorder),
                                      ),
                                      child: Icon(
                                        p.surveyMode == SurveyMode.gnss
                                            ? Icons.satellite_alt
                                            : Icons.straighten,
                                        color: p.surveyMode == SurveyMode.gnss
                                            ? AppTheme.autoridadNavy
                                            : AppTheme.colorBaseTerreno,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Datos del proyecto
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.name,
                                            style: const TextStyle(
                                              fontFamily: AppTheme.fontHeading,
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.autoridadNavy,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            p.establishment.isNotEmpty
                                                ? p.establishment
                                                : "Sin establecimiento especificado",
                                            style: const TextStyle(
                                              fontFamily: AppTheme.fontBody,
                                              fontSize: 12,
                                              color: AppTheme.datosCharcoal,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.sueloWarm,
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: AppTheme.sueloBorder),
                                                ),
                                                child: Text(
                                                  "${p.points.length} puntos",
                                                  style: const TextStyle(
                                                    fontFamily: AppTheme.fontHeading,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.datosCharcoal,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                _dateFormat.format(p.date),
                                                style: const TextStyle(
                                                  fontFamily: AppTheme.fontHeading,
                                                  fontSize: 11,
                                                  color: Color(0xFF8A9197),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Menú de opciones
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
                                      onSelected: (val) {
                                        if (val == 'dup') _duplicateProject(p.id);
                                        if (val == 'del') _deleteProject(p);
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'dup',
                                          child: Row(
                                            children: [
                                              Icon(Icons.copy, size: 18),
                                              SizedBox(width: 8),
                                              Text("Duplicar"),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'del',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text("Eliminar", style: TextStyle(color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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
}
