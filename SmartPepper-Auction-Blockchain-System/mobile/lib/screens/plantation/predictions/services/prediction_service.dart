import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/plantation_api_client.dart';
import '../models/prediction_input_model.dart';
import '../models/prediction_output_model.dart';
import '../../agronomy/models/api_response_model.dart';

final predictionServiceProvider = Provider<PredictionService>((ref) {
  return PredictionService(PlantationApiClient());
});

class PredictionService {
  final PlantationApiClient _client;

  PredictionService(this._client);

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
      if (response.data is Map &&
          (response.data as Map).containsKey('data')) {
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
}

