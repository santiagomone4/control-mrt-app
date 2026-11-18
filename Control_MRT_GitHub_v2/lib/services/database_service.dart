import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/project.dart';
import '../models/survey_point.dart';
import '../models/design_params.dart';

class DatabaseService {
  static const String _projectsKey = 'mrt_projects_store_v1';
  static final _uuid = Uuid();

  /// Obtiene todos los proyectos almacenados localmente
  static Future<List<Project>> getAllProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_projectsKey);

    if (jsonList == null || jsonList.isEmpty) {
      // Si está vacía, sembrar con un proyecto de ejemplo realista
      final defaultProject = _createSampleProject();
      await saveProject(defaultProject);
      return [defaultProject];
    }

    final List<Project> projects = [];
    for (final jsonStr in jsonList) {
      try {
        projects.add(Project.fromJson(jsonStr));
      } catch (e) {
        // Ignorar registros corruptos
      }
    }

    projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return projects;
  }

  /// Obtiene un proyecto por su ID
  static Future<Project?> getProject(String id) async {
    final list = await getAllProjects();
    try {
      return list.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Guarda o actualiza un proyecto
  static Future<void> saveProject(Project project) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getAllProjects();

    final existingIndex = list.indexWhere((p) => p.id == project.id);
    final updatedProject = project.copyWith(updatedAt: DateTime.now());

    if (existingIndex >= 0) {
      list[existingIndex] = updatedProject;
    } else {
      list.insert(0, updatedProject);
    }

    final rawList = list.map((p) => p.toJson()).toList();
    await prefs.setStringList(_projectsKey, rawList);
  }

  /// Elimina un proyecto por ID
  static Future<void> deleteProject(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getAllProjects();
    list.removeWhere((p) => p.id == id);
    final rawList = list.map((p) => p.toJson()).toList();
    await prefs.setStringList(_projectsKey, rawList);
  }

  /// Duplica un proyecto existente
  static Future<Project> duplicateProject(String sourceId) async {
    final source = await getProject(sourceId);
    if (source == null) throw Exception('Proyecto no encontrado');

    final clonedPoints = source.points.map((p) => p.copyWith(id: _uuid.v4())).toList();
    final duplicated = Project(
      id: _uuid.v4(),
      name: '${source.name} (Copia)',
      establishment: source.establishment,
      date: DateTime.now(),
      operatorName: source.operatorName,
      observations: source.observations,
      surveyMode: source.surveyMode,
      points: clonedPoints,
      designParams: source.designParams.copyWith(),
      isReversedProgressive: source.isReversedProgressive,
    );

    await saveProject(duplicated);
    return duplicated;
  }

  /// Importa un proyecto desde texto JSON (.json o .mrt)
  static Future<Project> importProjectFromJson(String jsonContent) async {
    final data = json.decode(jsonContent);
    final project = Project.fromMap(data);
    // Asignar nuevo ID para evitar colisiones
    final imported = project.copyWith(
      id: _uuid.v4(),
      name: '${project.name} (Importado)',
      updatedAt: DateTime.now(),
    );
    await saveProject(imported);
    return imported;
  }

  /// Genera un proyecto demostrativo completo para pruebas de campo inmediatas
  static Project _createSampleProject() {
    final id = _uuid.v4();
    final List<SurveyPoint> pts = [
      // Estribo Izquierdo y Vertedero Izquierdo (0.00m a 15.00m)
      SurveyPoint(id: _uuid.v4(), nr: "1", elevation: 98.40, progressive: 0.00, classification: PointClassification.base, isManualOptical: false),
      SurveyPoint(id: _uuid.v4(), nr: "2", elevation: 99.85, progressive: 0.00, classification: PointClassification.coronamiento, isManualOptical: false),
      SurveyPoint(id: _uuid.v4(), nr: "3", elevation: 98.20, progressive: 10.00, classification: PointClassification.base, isManualOptical: false),
      SurveyPoint(id: _uuid.v4(), nr: "4", elevation: 99.70, progressive: 10.00, classification: PointClassification.coronamiento, isManualOptical: false),
      
      // Terraplén Central - Bajada al cauce (15.00m a 60.00m)
      SurveyPoint(id: _uuid.v4(), nr: "5", elevation: 97.50, progressive: 20.00, classification: PointClassification.base, isManualOptical: false),
      SurveyPoint(id: _uuid.v4(), nr: "6", elevation: 100.10, progressive: 20.00, classification: PointClassification.coronamiento, isManualOptical: false),
      SurveyPoint(id: _uuid.v4(), nr: "7", elevation: 96.80, progressive: 35.00, classification: PointClassification.base, isManualOptical: false),
      SurveyPoint(id: _uuid.v4(), nr: "8", elevation: 99.95, progressive: 35.00, classification: PointClassification.coronamiento, isManualOptical: false),
      
      // Fondo de Cauce / Punto más bajo de la Base (Cota Mínima 96.20 m)
      SurveyPoint(id: _uuid.v4(), nr: "9", elevation: 96.20, progressive: 50.00, classification: PointClassification.base, isManualOptical: false),
      SurveyPoint(id: _uuid.v4(), nr: "10", elevation: 99.80, progressive: 50.00, classification: PointClassification.coronamiento, isManualOptical: false),
      
      // Subida hacia estribo derecho (60.00m a 90.00m)
      SurveyPoint(id: _uuid.v4(), nr: "11", elevation: 97.10, progressive: 65.00, classification: PointClassification.base, isManualOptical: false),
      SurveyPoint(id: _uuid.v4(), nr: "12", elevation: 100.25, progressive: 65.00, classification: PointClassification.coronamiento, isManualOptical: false),
      SurveyPoint(id: _uuid.v4(), nr: "13", elevation: 98.10, progressive: 80.00, classification: PointClassification.base, isManualOptical: false),
      SurveyPoint(id: _uuid.v4(), nr: "14", elevation: 100.05, progressive: 80.00, classification: PointClassification.coronamiento, isManualOptical: false),
      
      // Vertedero y Estribo Derecho (85.00m a 100.00m)
      SurveyPoint(id: _uuid.v4(), nr: "15", elevation: 98.60, progressive: 90.00, classification: PointClassification.base, isManualOptical: false),
      SurveyPoint(id: _uuid.v4(), nr: "16", elevation: 99.65, progressive: 90.00, classification: PointClassification.coronamiento, isManualOptical: false),
      SurveyPoint(id: _uuid.v4(), nr: "17", elevation: 98.90, progressive: 100.00, classification: PointClassification.base, isManualOptical: false),
      SurveyPoint(id: _uuid.v4(), nr: "18", elevation: 99.70, progressive: 100.00, classification: PointClassification.coronamiento, isManualOptical: false),
    ];

    return Project(
      id: id,
      name: "MRT-01 Arroyo El Trébol",
      establishment: "Estancia La Esperanza - Lote 14",
      date: DateTime.now(),
      operatorName: "Ing. Juan M. Pérez",
      observations: "Relevamiento de control de rasante y vertederos previo a compactación final.",
      surveyMode: SurveyMode.gnss,
      points: pts,
      designParams: MrtDesignParams(
        designHeight: 3.80, // Coronamiento ideal = 96.20 + 3.80 = 100.00 m
        spillwayDrop: 0.30, // Vertederos = 100.00 - 0.30 = 99.70 m
        leftSpillwayLength: 15.0,
        rightSpillwayLength: 15.0,
        tolerance: 0.05, // 5 cm
      ),
    );
  }
}
