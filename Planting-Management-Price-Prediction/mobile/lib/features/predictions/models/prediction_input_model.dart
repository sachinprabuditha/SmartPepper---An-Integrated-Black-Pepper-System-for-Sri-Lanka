class PredictionInput {
  final double usdBuyRate;
  final double usdSellRate;
  final double temperature;
  final double precipitation;
  final DateTime date;
  final String location;
  final String grade;

  PredictionInput({
    required this.usdBuyRate,
    required this.usdSellRate,
    required this.temperature,
    required this.precipitation,
    required this.date,
    required this.location,
    required this.grade,
  });

  Map<String, dynamic> toJson() {
    return {
      'usdBuyRate': usdBuyRate,
      'usdSellRate': usdSellRate,
      'temperature': temperature,
      'precipitation': precipitation,
      'date': date.toIso8601String(),
      'location': location,
      'grade': grade,
    };
  }
}
