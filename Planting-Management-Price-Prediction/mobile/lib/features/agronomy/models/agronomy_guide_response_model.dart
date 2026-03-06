import 'guide_step_model.dart';
import 'localized_string.dart';

class AgronomyGuideResponse {
  final String id;
  final String districtId;
  final LocalizedString districtName;
  final String soilTypeId;
  final LocalizedString soilTypeName;
  final String varietyId;
  final LocalizedString varietyName;
  final LocalizedString varietySpecialities;
  final LocalizedString varietySuitabilityReason;
  final LocalizedString varietySoilTypeRecommendation;
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
    required this.varietySpecialities,
    required this.varietySuitabilityReason,
    required this.varietySoilTypeRecommendation,
    this.varietySpacingMeters = '',
    this.varietyVinesPerHectare,
    this.varietyPitDimensionsCm = '',
    required this.steps,
  });

  factory AgronomyGuideResponse.fromJson(Map<String, dynamic> json) {
    return AgronomyGuideResponse(
      id: json['id']?.toString() ?? '',
      districtId: json['districtId']?.toString() ?? '',
      districtName: LocalizedString.fromJson(json['districtName']),
      soilTypeId: json['soilTypeId']?.toString() ?? '',
      soilTypeName: LocalizedString.fromJson(json['soilTypeName']),
      varietyId: json['varietyId'] as String,
      varietyName: LocalizedString.fromJson(json['varietyName']),
      varietySpecialities: LocalizedString.fromJson(json['varietySpecialities']),
      varietySuitabilityReason: LocalizedString.fromJson(json['varietySuitabilityReason']),
      varietySoilTypeRecommendation: LocalizedString.fromJson(json['varietySoilTypeRecommendation']),
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
      'districtName': districtName.toJson(),
      'soilTypeId': soilTypeId,
      'soilTypeName': soilTypeName.toJson(),
      'varietyId': varietyId,
      'varietyName': varietyName.toJson(),
      'varietySpecialities': varietySpecialities.toJson(),
      'varietySuitabilityReason': varietySuitabilityReason.toJson(),
      'varietySoilTypeRecommendation': varietySoilTypeRecommendation.toJson(),
      'varietySpacingMeters': varietySpacingMeters,
      'varietyVinesPerHectare': varietyVinesPerHectare,
      'varietyPitDimensionsCm': varietyPitDimensionsCm,
      'steps': steps.map((e) => e.toJson()).toList(),
    };
  }
}

