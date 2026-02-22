import 'guide_step_model.dart';

class AgronomyGuideResponse {
  final String id;
  final String districtId;
  final String districtName;
  final String soilTypeId;
  final String soilTypeName;
  final String varietyId;
  final String varietyName;
  final String varietySpecialities;
  final String varietySuitabilityReason;
  final String varietySoilTypeRecommendation;
  final String varietySpacingMeters;
  final int? varietyVinesPerHectare;
  final String varietyPitDimensionsCm;
  final List<GuideStep> steps;

  AgronomyGuideResponse({
    required this.id,
    required this.districtId,
    required this.districtName,
    required this.soilTypeId,
    required this.soilTypeName,
    required this.varietyId,
    required this.varietyName,
    this.varietySpecialities = '',
    this.varietySuitabilityReason = '',
    this.varietySoilTypeRecommendation = '',
    this.varietySpacingMeters = '',
    this.varietyVinesPerHectare,
    this.varietyPitDimensionsCm = '',
    required this.steps,
  });

  factory AgronomyGuideResponse.fromJson(Map<String, dynamic> json) {
    return AgronomyGuideResponse(
      id: json['id']?.toString() ?? '',
      districtId: json['districtId']?.toString() ?? '',
      districtName: json['districtName'] as String,
      soilTypeId: json['soilTypeId']?.toString() ?? '',
      soilTypeName: json['soilTypeName'] as String,
      varietyId: json['varietyId'] as String,
      varietyName: json['varietyName'] as String,
      varietySpecialities: json['varietySpecialities'] as String? ?? '',
      varietySuitabilityReason: json['varietySuitabilityReason'] as String? ?? '',
      varietySoilTypeRecommendation: json['varietySoilTypeRecommendation'] as String? ?? '',
      varietySpacingMeters: json['varietySpacingMeters'] as String? ?? '',
      varietyVinesPerHectare: json['varietyVinesPerHectare'] as int?,
      varietyPitDimensionsCm: json['varietyPitDimensionsCm'] as String? ?? '',
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) => GuideStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'districtId': districtId,
      'districtName': districtName,
      'soilTypeId': soilTypeId,
      'soilTypeName': soilTypeName,
      'varietyId': varietyId,
      'varietyName': varietyName,
      'varietySpecialities': varietySpecialities,
      'varietySuitabilityReason': varietySuitabilityReason,
      'varietySoilTypeRecommendation': varietySoilTypeRecommendation,
      'varietySpacingMeters': varietySpacingMeters,
      'varietyVinesPerHectare': varietyVinesPerHectare,
      'varietyPitDimensionsCm': varietyPitDimensionsCm,
      'steps': steps.map((e) => e.toJson()).toList(),
    };
  }
}

