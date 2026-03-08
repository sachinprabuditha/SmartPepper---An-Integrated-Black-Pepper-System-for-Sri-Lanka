class PredictionOutput {
  final double highestPrice;
  final double averagePrice;
  final String currency;

  PredictionOutput({
    required this.highestPrice,
    required this.averagePrice,
    required this.currency,
  });

  factory PredictionOutput.fromJson(Map<String, dynamic> json) {
    return PredictionOutput(
      highestPrice: (json['highestPrice'] as num).toDouble(),
      averagePrice: (json['averagePrice'] as num).toDouble(),
      currency: json['currency'] ?? 'LKR',
    );
  }
}
