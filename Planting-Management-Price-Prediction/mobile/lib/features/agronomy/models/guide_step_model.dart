import 'localized_string.dart';

class GuideStep {
  final String id;
  final int stepNumber;
  final LocalizedString title;
  final LocalizedString details;

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
      title: LocalizedString.fromJson(json['title']),
      details: LocalizedString.fromJson(json['details']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stepNumber': stepNumber,
      'title': title.toJson(),
      'details': details.toJson(),
    };
  }
}

