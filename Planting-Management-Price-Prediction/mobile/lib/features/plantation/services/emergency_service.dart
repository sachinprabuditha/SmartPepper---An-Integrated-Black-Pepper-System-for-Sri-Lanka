import '../../../../core/network/api_client.dart';
import '../../../../core/utils/constants.dart';
import '../models/emergency_template_model.dart';
import '../../auth/models/api_response_model.dart';
import 'package:dio/dio.dart';

class EmergencyService {
  final ApiClient _apiClient;

  EmergencyService(this._apiClient);

  /// Get all emergency templates
  Future<List<EmergencyTemplate>> getEmergencyTemplates({String? search}) async {
    try {
      final response = await _apiClient.dio.get(
        '${AppConstants.agronomyBase}/emergency-templates',
        queryParameters: search != null && search.isNotEmpty ? {'search': search} : null,
      );

      final apiResponse = ApiResponseModel<List<EmergencyTemplate>>.fromJson(
        response.data,
        (json) => (json as List)
            .map((item) => EmergencyTemplate.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw Exception(apiResponse.message);
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final apiResponse = ApiResponseModel<dynamic>.fromJson(
          e.response!.data,
          (json) => json,
        );
        throw Exception(apiResponse.message);
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Get a single emergency template by ID
  Future<EmergencyTemplate> getEmergencyTemplateById(String id) async {
    try {
      final response = await _apiClient.dio.get(
        '${AppConstants.agronomyBase}/emergency-templates/$id',
      );

      final apiResponse = ApiResponseModel<EmergencyTemplate>.fromJson(
        response.data,
        (json) => EmergencyTemplate.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw Exception(apiResponse.message);
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final apiResponse = ApiResponseModel<dynamic>.fromJson(
          e.response!.data,
          (json) => json,
        );
        throw Exception(apiResponse.message);
      }
      throw Exception('Network error: ${e.message}');
    }
  }
}

