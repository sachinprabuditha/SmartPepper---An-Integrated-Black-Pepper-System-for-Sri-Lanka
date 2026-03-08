import 'localized_string.dart';

class BlackPepperVariety {
  final String id;
  final LocalizedString name;
  final LocalizedString specialities;
  final LocalizedString suitabilityReason;
  final LocalizedString soilTypeRecommendation;
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
      name: LocalizedString.fromJson(json['name'] ?? json['Name']),
      specialities: LocalizedString.fromJson(json['specialities'] ?? json['Specialities']),
      suitabilityReason: LocalizedString.fromJson(json['suitability_reason'] ?? 
                          json['SuitabilityReason'] ?? 
                          json['suitabilityReason']),
      soilTypeRecommendation: LocalizedString.fromJson(json['soil_type_recommendation'] ?? 
                               json['SoilTypeRecommendation'] ?? 
                               json['soilTypeRecommendation']),
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
    'name': name.toJson(),
    'specialities': specialities.toJson(),
    'suitability_reason': suitabilityReason.toJson(),
    'soil_type_recommendation': soilTypeRecommendation.toJson(),
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

