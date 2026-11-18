enum ActionType {
  rellenar,
  cortar,
  ok,
}

class ControlPoint {
  final String sourcePointId;
  final String pointNr;
  final double progressive;
  final double? baseElevation;
  final double actualCrestElevation;
  final double idealElevation;
  final double diffMeters; // ideal - actual
  final double diffCm; // (ideal - actual) * 100
  final ActionType action;

  ControlPoint({
    required this.sourcePointId,
    required this.pointNr,
    required this.progressive,
    this.baseElevation,
    required this.actualCrestElevation,
    required this.idealElevation,
    required this.diffMeters,
    required this.diffCm,
    required this.action,
  });

  Map<String, dynamic> toMap() {
    return {
      'sourcePointId': sourcePointId,
      'pointNr': pointNr,
      'progressive': progressive,
      'baseElevation': baseElevation,
      'actualCrestElevation': actualCrestElevation,
      'idealElevation': idealElevation,
      'diffMeters': diffMeters,
      'diffCm': diffCm,
      'action': action.name,
    };
  }

  factory ControlPoint.fromMap(Map<String, dynamic> map) {
    return ControlPoint(
      sourcePointId: map['sourcePointId'] ?? '',
      pointNr: map['pointNr'] ?? '',
      progressive: (map['progressive'] as num).toDouble(),
      baseElevation: (map['baseElevation'] as num?)?.toDouble(),
      actualCrestElevation: (map['actualCrestElevation'] as num).toDouble(),
      idealElevation: (map['idealElevation'] as num).toDouble(),
      diffMeters: (map['diffMeters'] as num).toDouble(),
      diffCm: (map['diffCm'] as num).toDouble(),
      action: ActionType.values.firstWhere(
        (e) => e.name == map['action'],
        orElse: () => ActionType.ok,
      ),
    );
  }
}
