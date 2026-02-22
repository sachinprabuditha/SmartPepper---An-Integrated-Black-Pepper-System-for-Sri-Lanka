class BlackPepperVariety {
  final String id;
  final String name;
  final String specialities;
  final String suitabilityReason;
  final String soilTypeRecommendation;
  final PlantingSpecifications plantingSpecifications;

  BlackPepperVariety({
    required this.id,
    required this.name,
    required this.specialities,
    required this.suitabilityReason,
    required this.soilTypeRecommendation,
    required this.plantingSpecifications,
  });

  factory BlackPepperVariety.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'] ?? json['_id'] ?? json['Id'];
    
    return BlackPepperVariety(
      id: idValue?.toString() ?? '',
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      specialities: (json['specialities'] ?? json['Specialities'] ?? '').toString(),
      suitabilityReason: (json['suitability_reason'] ?? 
                          json['SuitabilityReason'] ?? 
                          json['suitabilityReason'] ?? '').toString(),
      soilTypeRecommendation: (json['soil_type_recommendation'] ?? 
                               json['SoilTypeRecommendation'] ?? 
                               json['soilTypeRecommendation'] ?? '').toString(),
      plantingSpecifications: _parsePlantingSpecifications(
        json['planting_specifications'] ?? 
        json['PlantingSpecifications'] ?? 
        json['plantingSpecifications']
      ),
    );
  }

  static PlantingSpecifications _parsePlantingSpecifications(dynamic value) {
    if (value == null || value is! Map) {
      return PlantingSpecifications(
        spacingMeters: '',
        vinesPerHectare: 0,
        pitDimensionsCm: '',
      );
    }
    return PlantingSpecifications.fromJson(value as Map<String, dynamic>);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'specialities': specialities,
    'suitability_reason': suitabilityReason,
    'soil_type_recommendation': soilTypeRecommendation,
    'planting_specifications': plantingSpecifications.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlackPepperVariety &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}

class PlantingSpecifications {
  final String spacingMeters;
  final int vinesPerHectare;
  final String pitDimensionsCm;

  PlantingSpecifications({
    required this.spacingMeters,
    required this.vinesPerHectare,
    required this.pitDimensionsCm,
  });

  factory PlantingSpecifications.fromJson(Map<String, dynamic> json) {
    return PlantingSpecifications(
      spacingMeters: (json['spacing_meters'] ?? 
                      json['SpacingMeters'] ?? 
                      json['spacingMeters'] ?? '').toString(),
      vinesPerHectare: _parseInt(json['vines_per_hectare'] ?? 
                                  json['VinesPerHectare'] ?? 
                                  json['vinesPerHectare']),
      pitDimensionsCm: (json['pit_dimensions_cm'] ?? 
                        json['PitDimensionsCm'] ?? 
                        json['pitDimensionsCm'] ?? '').toString(),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  Map<String, dynamic> toJson() => {
    'spacing_meters': spacingMeters,
    'vines_per_hectare': vinesPerHectare,
    'pit_dimensions_cm': pitDimensionsCm,
  };
}

