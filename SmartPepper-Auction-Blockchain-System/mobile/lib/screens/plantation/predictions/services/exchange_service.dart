import 'package:dio/dio.dart';
import '../../services/plantation_api_client.dart';

class ExchangeRateData {
  final String base;
  final String currency;
  final double rate;
  final double buyRate;
  final double sellRate;
  final String source;
  final String date;

  ExchangeRateData({
    required this.base,
    required this.currency,
    required this.rate,
    required this.buyRate,
    required this.sellRate,
    required this.source,
    required this.date,
  });

  factory ExchangeRateData.fromJson(Map<String, dynamic> json) {
    return ExchangeRateData(
      base: json['base'] ?? 'USD',
      currency: json['currency'] ?? 'LKR',
      rate: (json['rate'] ?? 0.0).toDouble(),
      buyRate: (json['buyRate'] ?? json['rate'] ?? 0.0).toDouble(),
      sellRate: (json['sellRate'] ?? json['rate'] ?? 0.0).toDouble(),
      source: json['source'] ?? 'unknown',
      date: json['date'] ?? '',
    );
  }
}

class ExchangeService {
  final PlantationApiClient _client;

  ExchangeService([PlantationApiClient? client])
      : _client = client ?? PlantationApiClient();

  /**
   * Fetches the USD to LKR exchange rate from the backend
   * The backend handles primary/fallback APIs and caching
   */
  Future<ExchangeRateData> getUSDToLKR() async {
    try {
      final Response response = await _client.dio.get('/exchange/usd-lkr');

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return ExchangeRateData.fromJson(response.data as Map<String, dynamic>);
      }

      throw Exception('Failed to load exchange rate');
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          'Exchange API failed: ${e.response?.data?['message'] ?? e.message}',
        );
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching exchange rate: $e');
    }
  }
}
