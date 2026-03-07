import 'package:dio/dio.dart';
import '../models/session_model.dart';
import '../../agronomy/models/api_response_model.dart';
import '../../services/plantation_api_client.dart';

class SessionService {
  final PlantationApiClient _client;

  SessionService(this._client);

  Future<List<SessionModel>> getSessionsBySeasonId(String seasonId) async {
    try {
      final response = await _client.dio.get(
        '/sessions/season/$seasonId',
      );

      final apiResponse = ApiResponseModel<List<SessionModel>>.fromJson(
        response.data,
        (json) {
          if (json is! List) return <SessionModel>[];
          return json.map((item) {
            if (item is Map<String, dynamic>) return SessionModel.fromJson(item);
            if (item is Map) return SessionModel.fromJson(Map<String, dynamic>.from(item));
            throw FormatException('Invalid item type in sessions list: ${item.runtimeType}');
          }).toList();
        },
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
      final response = await _client.dio.post(
        '/sessions',
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
      final response = await _client.dio.get(
        '/sessions/$sessionId',
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

      final response = await _client.dio.put(
        '/sessions/$sessionId',
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
      final response = await _client.dio.delete(
        '/sessions/$sessionId',
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

