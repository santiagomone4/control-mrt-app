enum PointClassification {
  coronamiento,
  base,
  ignored,
}

enum OpticalSide {
  izquierda,
  derecha,
  centro,
}

class SurveyPoint {
  final String id;
  String nr;
  OpticalSide? side;
  double? distanceFromLevel;
  double? rodCoronamiento;
  double? rodBase;
  double? x;
  double? y;
  double elevation; // Cota h (calculada o medida)
  double progressive; // Progresiva en metros desde 0.00
  PointClassification classification;
  bool isManualOptical;
  String? notes;

  SurveyPoint({
    required this.id,
    required this.nr,
    this.side,
    this.distanceFromLevel,
    this.rodCoronamiento,
    this.rodBase,
    this.x,
    this.y,
    required this.elevation,
    this.progressive = 0.0,
    this.classification = PointClassification.coronamiento,
    this.isManualOptical = false,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nr': nr,
      'side': side?.name,
      'distanceFromLevel': distanceFromLevel,
      'rodCoronamiento': rodCoronamiento,
      'rodBase': rodBase,
      'x': x,
      'y': y,
      'elevation': elevation,
      'progressive': progressive,
      'classification': classification.name,
      'isManualOptical': isManualOptical,
      'notes': notes,
    };
  }

  factory SurveyPoint.fromMap(Map<String, dynamic> map) {
    return SurveyPoint(
      id: map['id'] ?? '',
      nr: map['nr'] ?? '0',
      side: map['side'] != null
          ? OpticalSide.values.firstWhere(
              (e) => e.name == map['side'],
              orElse: () => OpticalSide.centro,
            )
          : null,
      distanceFromLevel: (map['distanceFromLevel'] as num?)?.toDouble(),
      rodCoronamiento: (map['rodCoronamiento'] as num?)?.toDouble(),
      rodBase: (map['rodBase'] as num?)?.toDouble(),
      x: (map['x'] as num?)?.toDouble(),
      y: (map['y'] as num?)?.toDouble(),
      elevation: (map['elevation'] as num?)?.toDouble() ?? 0.0,
      progressive: (map['progressive'] as num?)?.toDouble() ?? 0.0,
      classification: PointClassification.values.firstWhere(
        (e) => e.name == map['classification'],
        orElse: () => PointClassification.coronamiento,
      ),
      isManualOptical: map['isManualOptical'] ?? false,
      notes: map['notes'],
    );
  }

  SurveyPoint copyWith({
    String? id,
    String? nr,
    OpticalSide? side,
    double? distanceFromLevel,
    double? rodCoronamiento,
    double? rodBase,
    double? x,
    double? y,
    double? elevation,
    double? progressive,
    PointClassification? classification,
    bool? isManualOptical,
    String? notes,
  }) {
    return SurveyPoint(
      id: id ?? this.id,
      nr: nr ?? this.nr,
      side: side ?? this.side,
      distanceFromLevel: distanceFromLevel ?? this.distanceFromLevel,
      rodCoronamiento: rodCoronamiento ?? this.rodCoronamiento,
      rodBase: rodBase ?? this.rodBase,
      x: x ?? this.x,
      y: y ?? this.y,
      elevation: elevation ?? this.elevation,
      progressive: progressive ?? this.progressive,
      classification: classification ?? this.classification,
      isManualOptical: isManualOptical ?? this.isManualOptical,
      notes: notes ?? this.notes,
    );
  }
}
