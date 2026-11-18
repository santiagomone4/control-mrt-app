class MrtDesignParams {
  double designHeight; // Altura de diseño sobre la base mínima (m)
  double spillwayDrop; // Desnivel de vertederos respecto al coronamiento (m, ej 0.30)
  double leftSpillwayLength; // Longitud vertedero izquierdo desde prog 0 (m)
  double rightSpillwayLength; // Longitud vertedero derecho desde el final (m)
  double tolerance; // Tolerancia en metros (ej. 0.05 = 5 cm)
  double opticalVisualPlane; // Cota del plano visual para nivel óptico (ej. 100.00)

  MrtDesignParams({
    this.designHeight = 2.50,
    this.spillwayDrop = 0.30,
    this.leftSpillwayLength = 15.0,
    this.rightSpillwayLength = 15.0,
    this.tolerance = 0.05,
    this.opticalVisualPlane = 100.00,
  });

  Map<String, dynamic> toMap() {
    return {
      'designHeight': designHeight,
      'spillwayDrop': spillwayDrop,
      'leftSpillwayLength': leftSpillwayLength,
      'rightSpillwayLength': rightSpillwayLength,
      'tolerance': tolerance,
      'opticalVisualPlane': opticalVisualPlane,
    };
  }

  factory MrtDesignParams.fromMap(Map<String, dynamic> map) {
    return MrtDesignParams(
      designHeight: (map['designHeight'] as num?)?.toDouble() ?? 2.50,
      spillwayDrop: (map['spillwayDrop'] as num?)?.toDouble() ?? 0.30,
      leftSpillwayLength: (map['leftSpillwayLength'] as num?)?.toDouble() ?? 15.0,
      rightSpillwayLength: (map['rightSpillwayLength'] as num?)?.toDouble() ?? 15.0,
      tolerance: (map['tolerance'] as num?)?.toDouble() ?? 0.05,
      opticalVisualPlane: (map['opticalVisualPlane'] as num?)?.toDouble() ?? 100.00,
    );
  }

  MrtDesignParams copyWith({
    double? designHeight,
    double? spillwayDrop,
    double? leftSpillwayLength,
    double? rightSpillwayLength,
    double? tolerance,
    double? opticalVisualPlane,
  }) {
    return MrtDesignParams(
      designHeight: designHeight ?? this.designHeight,
      spillwayDrop: spillwayDrop ?? this.spillwayDrop,
      leftSpillwayLength: leftSpillwayLength ?? this.leftSpillwayLength,
      rightSpillwayLength: rightSpillwayLength ?? this.rightSpillwayLength,
      tolerance: tolerance ?? this.tolerance,
      opticalVisualPlane: opticalVisualPlane ?? this.opticalVisualPlane,
    );
  }
}
