import 'dart:convert';
import 'survey_point.dart';
import 'design_params.dart';

enum SurveyMode {
  optical,
  gnss,
}

class Project {
  final String id;
  String name;
  String establishment;
  DateTime date;
  String operatorName;
  String observations;
  SurveyMode surveyMode;
  List<SurveyPoint> points;
  MrtDesignParams designParams;
  bool isReversedProgressive;
  DateTime createdAt;
  DateTime updatedAt;

  Project({
    required this.id,
    required this.name,
    this.establishment = '',
    required this.date,
    this.operatorName = '',
    this.observations = '',
    this.surveyMode = SurveyMode.optical,
    List<SurveyPoint>? points,
    MrtDesignParams? designParams,
    this.isReversedProgressive = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : points = points ?? [],
        designParams = designParams ?? MrtDesignParams(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'establishment': establishment,
      'date': date.toIso8601String(),
      'operatorName': operatorName,
      'observations': observations,
      'surveyMode': surveyMode.name,
      'points': points.map((p) => p.toMap()).toList(),
      'designParams': designParams.toMap(),
      'isReversedProgressive': isReversedProgressive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Proyecto MRT',
      establishment: map['establishment'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      operatorName: map['operatorName'] ?? '',
      observations: map['observations'] ?? '',
      surveyMode: SurveyMode.values.firstWhere(
        (e) => e.name == map['surveyMode'],
        orElse: () => SurveyMode.optical,
      ),
      points: (map['points'] as List<dynamic>?)
              ?.map((p) => SurveyPoint.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      designParams: map['designParams'] != null
          ? MrtDesignParams.fromMap(map['designParams'])
          : MrtDesignParams(),
      isReversedProgressive: map['isReversedProgressive'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory Project.fromJson(String source) => Project.fromMap(json.decode(source));

  Project copyWith({
    String? id,
    String? name,
    String? establishment,
    DateTime? date,
    String? operatorName,
    String? observations,
    SurveyMode? surveyMode,
    List<SurveyPoint>? points,
    MrtDesignParams? designParams,
    bool? isReversedProgressive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      establishment: establishment ?? this.establishment,
      date: date ?? this.date,
      operatorName: operatorName ?? this.operatorName,
      observations: observations ?? this.observations,
      surveyMode: surveyMode ?? this.surveyMode,
      points: points ?? this.points.map((p) => p.copyWith()).toList(),
      designParams: designParams ?? this.designParams.copyWith(),
      isReversedProgressive: isReversedProgressive ?? this.isReversedProgressive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
