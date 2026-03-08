import 'package:dio/dio.dart';
import '../models/session_model.dart';
import '../../auth/models/api_response_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/constants.dart';

class SessionService {
  final ApiClient _apiClient;

  SessionService(this._apiClient);

  Future<List<SessionModel>> getSessionsBySeasonId(String seasonId) async {
    try {
      final response = await _apiClient.dio.get(
        '${AppConstants.sessionsBase}/season/$seasonId',
      );

      final apiResponse = ApiResponseModel<List<SessionModel>>.fromJson(
        response.data,
        (json) => (json as List)
            .map((item) => SessionModel.fromJson(item as Map<String, dynamic>))
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

  Future<SessionModel> createSession({
    required String seasonId,
    required String sessionName,
    required DateTime date,
    required double yieldKg,
    required double areaHarvested,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        AppConstants.sessionsBase,
        data: {
          'seasonId': seasonId,
          'sessionName': sessionName,
          'date': date.toIso8601String(),
          'yieldKg': yieldKg,
          'areaHarvested': areaHarvested,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );

      final apiResponse = ApiResponseModel<SessionModel>.fromJson(
        response.data,
        (json) => SessionModel.fromJson(json as Map<String, dynamic>),
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

  Future<SessionModel> getSessionById(String sessionId) async {
    try {
      final response = await _apiClient.dio.get(
        '${AppConstants.sessionsBase}/$sessionId',
      );

      final apiResponse = ApiResponseModel<SessionModel>.fromJson(
        response.data,
        (json) => SessionModel.fromJson(json as Map<String, dynamic>),
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

  Future<SessionModel> updateSession({
    required String sessionId,
    String? sessionName,
    DateTime? date,
    double? yieldKg,
    double? areaHarvested,
    String? notes,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (sessionName != null && sessionName.isNotEmpty) data['sessionName'] = sessionName;
      if (date != null) data['date'] = date.toIso8601String();
      if (yieldKg != null) data['yieldKg'] = yieldKg;
      if (areaHarvested != null) data['areaHarvested'] = areaHarvested;
      if (notes != null) data['notes'] = notes;

      final response = await _apiClient.dio.put(
        '${AppConstants.sessionsBase}/$sessionId',
        data: data,
      );

      final apiResponse = ApiResponseModel<SessionModel>.fromJson(
        response.data,
        (json) => SessionModel.fromJson(json as Map<String, dynamic>),
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

  Future<void> deleteSession(String sessionId) async {
    try {
      final response = await _apiClient.dio.delete(
        '${AppConstants.sessionsBase}/$sessionId',
      );

      final apiResponse = ApiResponseModel<dynamic>.fromJson(
        response.data,
        (json) => json,
      );

      if (!apiResponse.success) {
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

