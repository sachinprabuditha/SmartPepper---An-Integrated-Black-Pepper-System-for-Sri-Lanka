import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:skr_frontend_mobile/core/network/api_client.dart';
import '../../../../core/utils/constants.dart';
import '../models/prediction_input_model.dart';
import '../models/prediction_output_model.dart';

final predictionServiceProvider = Provider<PredictionService>((ref) {
  return PredictionService();
});

class PredictionService {
  // Use centralized base URL from ApiClient
  static const String _baseUrl = ApiClient.baseUrl;
  final _storage = const FlutterSecureStorage();

  Future<PredictionOutput> predictPrice(PredictionInput input) async {
    final url = Uri.parse('$_baseUrl/Prediction/predict');
    
    // Get token if needed (schema shows Auth is used generally, but this endpoint might be public or protected)
    // Adding auth header just in case, won't hurt if not required
    final token = await _storage.read(key: AppConstants.jwtTokenKey);
    
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(input.toJson()),
      );

      if (response.statusCode == 200) {
        return PredictionOutput.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get prediction (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      throw Exception('Error connecting to prediction service: $e');
    }
  }
}
