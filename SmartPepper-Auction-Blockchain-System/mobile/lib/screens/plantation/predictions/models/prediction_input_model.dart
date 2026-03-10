class PredictionInput {
  final double usdRate;
  final double temperature;
  final double precipitation;
  final DateTime date;
  final String location;
  final String grade;

  PredictionInput({
    required this.usdRate,
    required this.temperature,
    required this.precipitation,
    required this.date,
    required this.location,
    required this.grade,
  });

  Map<String, dynamic> toJson() {
    return {
      'usdRate': usdRate,
      'temperature': temperature,
      'precipitation': precipitation,
      'date': date.toIso8601String(),
      'location': location,
      'grade': grade,
    };
  }
}
