import '../agronomy/models/district_model.dart';
import 'plantation_api_client.dart';

class PriceAnalyticsService {
  final PlantationApiClient _apiClient;

  PriceAnalyticsService(this._apiClient);

  Future<List<District>> fetchDistricts() async {
    try {
      final response = await _apiClient.dio.get('/agronomy/districts');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((d) => District.fromJson(d)).toList();
      }
      return [];
    } catch (e) {
      print('[PriceAnalyticsService] Error fetching districts: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchPriceAnalytics(
      String district) async {
    try {
      final response =
          await _apiClient.dio.get('/prediction/analytics/$district');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      print('[PriceAnalyticsService] Error fetching price analytics: $e');
      return [];
    }
  }
}
