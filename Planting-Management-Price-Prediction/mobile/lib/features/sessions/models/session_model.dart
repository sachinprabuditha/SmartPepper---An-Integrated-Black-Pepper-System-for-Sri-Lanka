import 'package:json_annotation/json_annotation.dart';

part 'session_model.g.dart';

@JsonSerializable()
class SessionModel {
  @JsonKey(name: '_id')
  final String id;
  final String seasonId;
  final String sessionName;
  final DateTime date;
  final double yieldKg;
  final double areaHarvested;
  final String? notes;
  final DateTime createdAt;

  SessionModel({
    required this.id,
    required this.seasonId,
    required this.sessionName,
    required this.date,
    required this.yieldKg,
    required this.areaHarvested,
    this.notes,
    required this.createdAt,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    // Handle both 'id' and '_id' fields from backend
    final idValue = json['id'] ?? json['_id'] ?? json['Id'];
    if (idValue == null) {
      throw FormatException('Session ID is required but was null');
    }

    // Handle null values and different casing
    return SessionModel(
      id: idValue.toString(),
      seasonId: (json['seasonId'] ?? json['SeasonId'] ?? '').toString(),
      sessionName: (json['sessionName'] ?? json['SessionName'] ?? '').toString(),
      date: _parseDateTime(json['date'] ?? json['Date']),
      yieldKg: _parseDouble(json['yieldKg'] ?? json['YieldKg']),
      areaHarvested: _parseDouble(json['areaHarvested'] ?? json['AreaHarvested']),
      notes: _parseStringNullable(json['notes'] ?? json['Notes']),
      createdAt: _parseDateTime(json['createdAt'] ?? json['CreatedAt']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static String? _parseStringNullable(dynamic value) {
    if (value == null) return null;
    final str = value.toString();
    return str.isEmpty ? null : str;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() => _$SessionModelToJson(this);

  double get yieldPerHectare {
    if (areaHarvested == 0) return 0;
    return yieldKg / areaHarvested;
  }
}

