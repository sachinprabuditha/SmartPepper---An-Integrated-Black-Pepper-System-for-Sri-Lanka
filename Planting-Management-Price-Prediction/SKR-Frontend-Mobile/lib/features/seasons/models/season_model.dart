import 'package:json_annotation/json_annotation.dart';

part 'season_model.g.dart';

@JsonSerializable()
class SeasonModel {
  @JsonKey(name: '_id')
  final String id;
  final String seasonName;
  final String? district; // Optional - can be obtained from farm
  final int startMonth;
  final int startYear;
  final int endMonth;
  final int endYear;
  final String farmId;
  final String createdBy;
  final DateTime createdAt;
  final double totalHarvestedYield;
  final String status;

  SeasonModel({
    required this.id,
    required this.seasonName,
    this.district,
    required this.startMonth,
    required this.startYear,
    required this.endMonth,
    required this.endYear,
    required this.farmId,
    required this.createdBy,
    required this.createdAt,
    this.totalHarvestedYield = 0.0,
    this.status = 'season-start',
  });

  factory SeasonModel.fromJson(Map<String, dynamic> json) {
    // Handle both 'id' and '_id' fields from backend
    // Also handle MongoDB ObjectId format: {"$oid": "..."}
    dynamic idValue = json['id'] ?? json['_id'] ?? json['Id'];
    if (idValue == null) {
      throw FormatException('Season ID is required but was null');
    }

    // Handle MongoDB ObjectId format
    String idString;
    if (idValue is Map && idValue.containsKey('\$oid')) {
      idString = idValue['\$oid'].toString();
    } else if (idValue is Map && idValue.containsKey('oid')) {
      idString = idValue['oid'].toString();
    } else {
      idString = idValue.toString();
    }

    // Handle farmId which might also be an ObjectId
    dynamic farmIdValue = json['farm_id'] ?? json['farmId'] ?? json['FarmId'];
    String farmIdString;
    if (farmIdValue == null) {
      farmIdString = '';
    } else if (farmIdValue is Map && farmIdValue.containsKey('\$oid')) {
      farmIdString = farmIdValue['\$oid'].toString();
    } else if (farmIdValue is Map && farmIdValue.containsKey('oid')) {
      farmIdString = farmIdValue['oid'].toString();
    } else {
      farmIdString = farmIdValue.toString();
    }

    // Handle null values and different casing
    return SeasonModel(
      id: idString,
      seasonName: (json['seasonName'] ?? json['SeasonName'] ?? '').toString(),
      district: _parseStringNullable(json['district'] ?? json['District']),
      startMonth: _parseInt(json['startMonth'] ?? json['StartMonth']),
      startYear: _parseInt(json['startYear'] ?? json['StartYear']),
      endMonth: _parseInt(json['endMonth'] ?? json['EndMonth']),
      endYear: _parseInt(json['endYear'] ?? json['EndYear']),
      farmId: farmIdString,
      createdBy: (json['createdBy'] ?? json['CreatedBy'] ?? '').toString(),
      createdAt: _parseDateTime(json['createdAt'] ?? json['CreatedAt']),
      totalHarvestedYield: _parseDouble(json['totalHarvestedYield'] ?? json['TotalHarvestedYield']),
      status: (json['status'] ?? json['Status'] ?? 'season-start').toString(),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static String? _parseStringNullable(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
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

  Map<String, dynamic> toJson() => _$SeasonModelToJson(this);

  String get period {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[startMonth - 1]} $startYear - ${months[endMonth - 1]} $endYear';
  }
}

