// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionModel _$SessionModelFromJson(Map<String, dynamic> json) => SessionModel(
      id: json['_id'] as String,
      seasonId: json['seasonId'] as String,
      sessionName: json['sessionName'] as String? ?? json['SessionName'] as String? ?? '',
      date: DateTime.parse(json['date'] as String),
      yieldKg: (json['yieldKg'] as num).toDouble(),
      areaHarvested: (json['areaHarvested'] as num).toDouble(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$SessionModelToJson(SessionModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'seasonId': instance.seasonId,
      'sessionName': instance.sessionName,
      'date': instance.date.toIso8601String(),
      'yieldKg': instance.yieldKg,
      'areaHarvested': instance.areaHarvested,
      'notes': instance.notes,
      'createdAt': instance.createdAt.toIso8601String(),
    };
