class FarmTask {
  final String id;
  final String farmId;
  final String taskName;
  final String phase;
  final String taskType;
  final String varietyKey;
  final DateTime dueDate;
  final String status;
  final DateTime? dateCompleted;
  final InputDetails? inputDetails;
  final List<String> detailedSteps;
  final String? reasonWhy;
  final bool isManual;
  final String priority;
  final DateTime createdAt;

  FarmTask({
    required this.id,
    required this.farmId,
    required this.taskName,
    required this.phase,
    required this.taskType,
    required this.varietyKey,
    required this.dueDate,
    required this.status,
    this.dateCompleted,
    this.inputDetails,
    required this.detailedSteps,
    this.reasonWhy,
    this.isManual = false,
    this.priority = 'Medium',
    required this.createdAt,
  });

  factory FarmTask.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'] ?? json['_id'] ?? json['Id'];
    if (idValue == null) {
      throw FormatException('FarmTask ID is required but was null');
    }

    return FarmTask(
      id: idValue.toString(),
      farmId: (json['farm_id'] ?? json['farmId'] ?? json['FarmId'] ?? '').toString(),
      taskName: (json['task_name'] ?? json['taskName'] ?? json['TaskName'] ?? '').toString(),
      phase: (json['phase'] ?? json['Phase'] ?? '').toString(),
      taskType: (json['task_type'] ?? json['taskType'] ?? json['TaskType'] ?? '').toString(),
      varietyKey: (json['variety_key'] ?? json['varietyKey'] ?? json['VarietyKey'] ?? '').toString(),
      dueDate: _parseDateTime(json['due_date'] ?? json['dueDate'] ?? json['DueDate']),
      status: (json['status'] ?? json['Status'] ?? 'Scheduled').toString(),
      dateCompleted: json['date_completed'] != null || json['dateCompleted'] != null || json['DateCompleted'] != null
          ? _parseDateTime(json['date_completed'] ?? json['dateCompleted'] ?? json['DateCompleted'])
          : null,
      inputDetails: json['input_details'] != null || json['inputDetails'] != null || json['InputDetails'] != null
          ? InputDetails.fromJson((json['input_details'] ?? json['inputDetails'] ?? json['InputDetails']) as Map<String, dynamic>)
          : null,
      detailedSteps: _parseStringList(json['detailed_steps'] ?? json['detailedSteps'] ?? json['DetailedSteps']),
      reasonWhy: (json['reason_why'] ?? json['reasonWhy'] ?? json['ReasonWhy'])?.toString(),
      isManual: json['is_manual'] ?? json['isManual'] ?? json['IsManual'] ?? false,
      priority: (json['priority'] ?? json['Priority'] ?? 'Medium').toString(),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt'] ?? json['CreatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farm_id': farmId,
      'task_name': taskName,
      'phase': phase,
      'task_type': taskType,
      'variety_key': varietyKey,
      'due_date': dueDate.toIso8601String(),
      'status': status,
      'date_completed': dateCompleted?.toIso8601String(),
      'input_details': inputDetails?.toJson(),
      'detailed_steps': detailedSteps,
      'reason_why': reasonWhy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now().toUtc();
    if (value is DateTime) return value.toUtc();
    if (value is String) {
      try {
        return DateTime.parse(value).toUtc();
      } catch (e) {
        return DateTime.now().toUtc();
      }
    }
    return DateTime.now().toUtc();
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }
}

class InputDetails {
  final List<InputItem> items;
  final double laborHours;
  final String? notes;
  
  // Legacy fields for backward compatibility
  final String? itemUsed;
  final double? quantity;
  final double? unitCostLKR;

  InputDetails({
    required this.items,
    required this.laborHours,
    this.notes,
    this.itemUsed,
    this.quantity,
    this.unitCostLKR,
  });

  factory InputDetails.fromJson(Map<String, dynamic> json) {
    // Handle new format with items list
    List<InputItem> itemsList = [];
    if (json['items'] != null && json['items'] is List) {
      itemsList = (json['items'] as List)
          .map((item) => InputItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    
    // Handle legacy format - convert to items list
    if (itemsList.isEmpty && json['item_used'] != null) {
      itemsList.add(InputItem(
        itemName: (json['item_used'] ?? json['itemUsed'] ?? json['ItemUsed'] ?? '').toString(),
        quantity: _parseDouble(json['quantity'] ?? json['Quantity']),
        unitCostLKR: _parseDouble(json['unit_cost_lkr'] ?? json['unitCostLKR'] ?? json['UnitCostLKR']),
        unit: 'kg',
      ));
    }

    return InputDetails(
      items: itemsList,
      laborHours: _parseDouble(json['labor_hours'] ?? json['laborHours'] ?? json['LaborHours']),
      notes: json['notes'] != null ? json['notes'].toString() : null,
      // Legacy fields
      itemUsed: json['item_used'] != null ? json['item_used'].toString() : null,
      quantity: json['quantity'] != null ? _parseDouble(json['quantity']) : null,
      unitCostLKR: json['unit_cost_lkr'] != null ? _parseDouble(json['unit_cost_lkr']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'labor_hours': laborHours,
      if (notes != null) 'notes': notes,
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class InputItem {
  final String itemName;
  final double quantity;
  final double? unitCostLKR; // Nullable - unit cost is optional
  final String unit;

  InputItem({
    required this.itemName,
    required this.quantity,
    this.unitCostLKR, // Optional - can be null
    this.unit = 'kg',
  });

  factory InputItem.fromJson(Map<String, dynamic> json) {
    final unitCostValue = json['unit_cost_lkr'] ?? json['unitCostLKR'] ?? json['UnitCostLKR'];
    return InputItem(
      itemName: (json['item_name'] ?? json['itemName'] ?? json['ItemName'] ?? '').toString(),
      quantity: _parseDouble(json['quantity'] ?? json['Quantity']),
      unitCostLKR: unitCostValue != null ? _parseDouble(unitCostValue) : null,
      unit: (json['unit'] ?? json['Unit'] ?? 'kg').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_name': itemName,
      'quantity': quantity,
      'unit_cost_lkr': unitCostLKR, // Can be null
      'unit': unit,
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

