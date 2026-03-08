class PlantingGuide {
  final String id;
  final String district;
  final List<String> suitableVarietyIds;
  final List<InstructionalStep> instructionalSteps;

  PlantingGuide({
    required this.id,
    required this.district,
    required this.suitableVarietyIds,
    required this.instructionalSteps,
  });

  factory PlantingGuide.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'] ?? json['_id'] ?? json['Id'];
    
    return PlantingGuide(
      id: idValue?.toString() ?? '',
      district: (json['district'] ?? json['District'] ?? '').toString(),
      suitableVarietyIds: _parseStringList(json['suitable_variety_ids'] ?? 
                                            json['SuitableVarietyIds'] ?? 
                                            json['suitableVarietyIds']),
      instructionalSteps: _parseInstructionalSteps(json['instructional_steps'] ?? 
                                                    json['InstructionalSteps'] ?? 
                                                    json['instructionalSteps']),
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  static List<InstructionalStep> _parseInstructionalSteps(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((item) {
        if (item is Map<String, dynamic>) {
          return InstructionalStep.fromJson(item);
        }
        return InstructionalStep(step: 0, title: '', details: '');
      }).toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'district': district,
    'suitable_variety_ids': suitableVarietyIds,
    'instructional_steps': instructionalSteps.map((e) => e.toJson()).toList(),
  };
}

class InstructionalStep {
  final int step;
  final String title;
  final String details;

  InstructionalStep({
    required this.step,
    required this.title,
    required this.details,
  });

  factory InstructionalStep.fromJson(Map<String, dynamic> json) {
    return InstructionalStep(
      step: _parseInt(json['step'] ?? json['Step']),
      title: (json['title'] ?? json['Title'] ?? '').toString(),
      details: (json['details'] ?? json['Details'] ?? '').toString(),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  Map<String, dynamic> toJson() => {
    'step': step,
    'title': title,
    'details': details,
  };
}
