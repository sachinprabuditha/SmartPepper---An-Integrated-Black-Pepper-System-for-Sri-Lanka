class FarmRecord {
  final String id;
  final String userId;
  final String farmName;
  final String district;
  final String chosenVariety;
  final DateTime farmStartDate;
  final double areaHectares;
  final int totalVines;
  final DateTime createdAt;

  FarmRecord({
    required this.id,
    required this.userId,
    required this.farmName,
    required this.district,
    required this.chosenVariety,
    required this.farmStartDate,
    required this.areaHectares,
    required this.totalVines,
    required this.createdAt,
  });

  factory FarmRecord.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'] ?? json['_id'] ?? json['Id'];
    if (idValue == null) {
      throw FormatException('FarmRecord ID is required but was null');
    }

    return FarmRecord(
      id: idValue.toString(),
      userId: (json['user_id'] ?? json['userId'] ?? json['UserId'] ?? '').toString(),
      farmName: (json['farm_name'] ?? json['farmName'] ?? json['FarmName'] ?? '').toString(),
      district: (json['district'] ?? json['District'] ?? '').toString(),
      chosenVariety: (json['chosen_variety'] ?? json['chosenVariety'] ?? json['ChosenVariety'] ?? '').toString(),
      farmStartDate: _parseDateTime(
        _getDateValue(json, 'farm_start_date') ??
        _getDateValue(json, 'farmStartDate') ??
        _getDateValue(json, 'FarmStartDate') ??
        _getDateValue(json, 'planting_date') ??
        _getDateValue(json, 'plantingDate') ??
        _getDateValue(json, 'PlantingDate')
      ),
      areaHectares: _parseDouble(json['area_hectares'] ?? json['areaHectares'] ?? json['AreaHectares']),
      totalVines: _parseInt(json['total_vines'] ?? json['totalVines'] ?? json['TotalVines']),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt'] ?? json['CreatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'farm_name': farmName,
      'district': district,
      'chosen_variety': chosenVariety,
      'farm_start_date': farmStartDate.toIso8601String(),
      'area_hectares': areaHectares,
      'total_vines': totalVines,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static dynamic _getDateValue(Map<String, dynamic> json, String key) {
    final value = json[key];
    // Return null if value is null or empty string, so ?? operator can fall through
    if (value == null || (value is String && value.isEmpty)) {
      return null;
    }
    return value;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }
    if (value is DateTime) {
      // If already a DateTime, convert to local time for display
      return value.isUtc ? value.toLocal() : value;
    }
    if (value is String) {
      if (value.isEmpty) {
        return DateTime.now();
      }
      try {
        final parsed = DateTime.parse(value);
        // Convert UTC dates to local time for display
        // This ensures dates like 2025-12-24 00:00:00Z display as Dec 24 in local timezone
        return parsed.isUtc ? parsed.toLocal() : parsed;
      } catch (e) {
        return DateTime.now();
      }
    }
    // For any other type, return current date
    return DateTime.now();
  }
}

