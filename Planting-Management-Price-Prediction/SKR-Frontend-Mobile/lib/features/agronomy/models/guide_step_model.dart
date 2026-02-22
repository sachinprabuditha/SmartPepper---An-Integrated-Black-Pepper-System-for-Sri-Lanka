class GuideStep {
  final String id;
  final int stepNumber;
  final String title;
  final String details;

  GuideStep({
    required this.id,
    required this.stepNumber,
    required this.title,
    required this.details,
  });

  factory GuideStep.fromJson(Map<String, dynamic> json) {
    return GuideStep(
      id: json['id'].toString(),
      stepNumber: json['stepNumber'] as int,
      title: json['title'] as String,
      details: json['details'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stepNumber': stepNumber,
      'title': title,
      'details': details,
    };
  }
}

