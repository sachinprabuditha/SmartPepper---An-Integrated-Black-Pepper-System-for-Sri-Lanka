// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'season_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SeasonModel _$SeasonModelFromJson(Map<String, dynamic> json) => SeasonModel(
      id: json['_id'] as String,
      seasonName: json['seasonName'] as String,
      district: json['district'] as String,
      startMonth: (json['startMonth'] as num).toInt(),
      startYear: (json['startYear'] as num).toInt(),
      endMonth: (json['endMonth'] as num).toInt(),
      endYear: (json['endYear'] as num).toInt(),
      farmId: json['farm_id'] as String? ?? json['farmId'] as String? ?? '',
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$SeasonModelToJson(SeasonModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'seasonName': instance.seasonName,
      'district': instance.district,
      'startMonth': instance.startMonth,
      'startYear': instance.startYear,
      'endMonth': instance.endMonth,
      'endYear': instance.endYear,
      'farm_id': instance.farmId,
      'createdBy': instance.createdBy,
      'createdAt': instance.createdAt.toIso8601String(),
    };
