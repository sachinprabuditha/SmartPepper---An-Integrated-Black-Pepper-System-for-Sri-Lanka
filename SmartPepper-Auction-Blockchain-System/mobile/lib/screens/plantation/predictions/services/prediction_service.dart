import 'package:dio/dio.dart';

import '../../services/plantation_api_client.dart';
import '../models/prediction_input_model.dart';
import '../models/prediction_output_model.dart';
import '../../agronomy/models/api_response_model.dart';

class PredictionService {
  final PlantationApiClient _client;

  PredictionService([PlantationApiClient? client])
      : _client = client ?? PlantationApiClient();

  Future<PredictionOutput> predictPrice(PredictionInput input) async {
    try {
      final Response response = await _client.dio.post(
        '/prediction/predict',
        data: input.toJson(),
        options: Options(
          // ONNX model warm-up on first request can be slow.
          receiveTimeout: const Duration(minutes: 3),
        ),
      );

      // Backend returns plain JSON, not wrapped ApiResponse
      // Normalize into PredictionOutput.
      if (response.data is Map<String, dynamic>) {
        return PredictionOutput.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      // If someone later wraps it with { success, data }, handle that too.
      if (response.data is Map && (response.data as Map).containsKey('data')) {
        final apiResponse = ApiResponseModel<Map<String, dynamic>>.fromJson(
          Map<String, dynamic>.from(response.data as Map),
          (json) => Map<String, dynamic>.from(json as Map),
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(apiResponse.message);
        }

        return PredictionOutput.fromJson(apiResponse.data!);
      }

      throw Exception('Unexpected prediction response format');
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          'Prediction failed: ${e.response?.data?['message'] ?? e.message}',
        );
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> getLatestWeather(String district) async {
    try {
      final Response response = await _client.dio.get(
        '/prediction/weather/$district',
      );

      if (response.data is Map<String, dynamic> &&
          response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }

      throw Exception('Failed to fetch weather data');
    } on DioException catch (e) {
      if (e.response != null && e.response?.statusCode == 404) {
        // Handle 404 silently or return null to let the UI know no data exists
        return {};
      }
      throw Exception('Network error while fetching weather: ${e.message}');
    }
  }
}
