class EmergencyTemplate {
  final String id;
  final String issueName;
  final String symptoms;
  final String treatmentTask;
  final String priority;
  final String instructions;
  final DateTime createdAt;

  EmergencyTemplate({
    required this.id,
    required this.issueName,
    required this.symptoms,
    required this.treatmentTask,
    required this.priority,
    required this.instructions,
    required this.createdAt,
  });

  factory EmergencyTemplate.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'] ?? json['_id'] ?? json['Id'];
    if (idValue == null) {
      throw FormatException('EmergencyTemplate ID is required but was null');
    }

    return EmergencyTemplate(
      id: idValue.toString(),
      issueName: (json['issue_name'] ?? json['issueName'] ?? json['IssueName'] ?? '').toString(),
      symptoms: (json['symptoms'] ?? json['Symptoms'] ?? '').toString(),
      treatmentTask: (json['treatment_task'] ?? json['treatmentTask'] ?? json['TreatmentTask'] ?? '').toString(),
      priority: (json['priority'] ?? json['Priority'] ?? 'High').toString(),
      instructions: (json['instructions'] ?? json['Instructions'] ?? '').toString(),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt'] ?? json['CreatedAt']),
    );
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
}

