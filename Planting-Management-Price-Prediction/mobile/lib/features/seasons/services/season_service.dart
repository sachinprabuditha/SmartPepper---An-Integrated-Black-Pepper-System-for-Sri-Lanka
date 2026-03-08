import 'package:dio/dio.dart';
import '../models/season_model.dart';
import '../../auth/models/api_response_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/constants.dart';

class SeasonService {
  final ApiClient _apiClient;

  SeasonService(this._apiClient);

  Future<List<SeasonModel>> getSeasonsByUserId(String userId) async {
    try {
      final response = await _apiClient.dio.get(
        '${AppConstants.seasonsBase}/user/$userId',
      );

      // Ensure response.data is a Map
      if (response.data is! Map<String, dynamic>) {
        throw Exception('Invalid response format from server');
      }

      final apiResponse = ApiResponseModel<List<SeasonModel>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) {
          if (json is List) {
            return json
                .map((item) {
                  if (item is Map<String, dynamic>) {
                    return SeasonModel.fromJson(item);
                  } else if (item is Map) {
                    // Convert Map<dynamic, dynamic> to Map<String, dynamic>
                    return SeasonModel.fromJson(Map<String, dynamic>.from(item));
                  } else {
                    throw FormatException('Invalid item type in seasons list: ${item.runtimeType}');
                  }
                })
                .toList();
          } else {
            throw FormatException('Expected List but got ${json.runtimeType}');
          }
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
          e.response!.data is Map<String, dynamic>
              ? e.response!.data as Map<String, dynamic>
              : {'success': false, 'message': 'Invalid response format', 'data': null},
          (json) => json,
        );
        throw Exception(apiResponse.message);
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<List<SeasonModel>> getSeasonsByFarmId(String farmId) async {
    try {
      final response = await _apiClient.dio.get(
        '${AppConstants.seasonsBase}/farm/$farmId',
      );

      // Ensure response.data is a Map
      if (response.data is! Map<String, dynamic>) {
        throw Exception('Invalid response format from server');
      }

      final apiResponse = ApiResponseModel<List<SeasonModel>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) {
          if (json is List) {
            return json
                .map((item) {
                  if (item is Map<String, dynamic>) {
                    return SeasonModel.fromJson(item);
                  } else if (item is Map) {
                    // Convert Map<dynamic, dynamic> to Map<String, dynamic>
                    return SeasonModel.fromJson(Map<String, dynamic>.from(item));
                  } else {
                    throw FormatException('Invalid item type in seasons list: ${item.runtimeType}');
                  }
                })
                .toList();
          } else {
            throw FormatException('Expected List but got ${json.runtimeType}');
          }
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
          e.response!.data is Map<String, dynamic>
              ? e.response!.data as Map<String, dynamic>
              : {'success': false, 'message': 'Invalid response format', 'data': null},
          (json) => json,
        );
        throw Exception(apiResponse.message);
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<SeasonModel> createSeason({
    required String seasonName,
    required int startMonth,
    required int startYear,
    required int endMonth,
    required int endYear,
    required String farmId,
    required String createdBy,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        AppConstants.seasonsBase,
        data: {
          'seasonName': seasonName,
          'startMonth': startMonth,
          'startYear': startYear,
          'endMonth': endMonth,
          'endYear': endYear,
          'farmId': farmId,
          'createdBy': createdBy,
        },
      );

      final apiResponse = ApiResponseModel<SeasonModel>.fromJson(
        response.data,
        (json) => SeasonModel.fromJson(json as Map<String, dynamic>),
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

  Future<SeasonModel> getSeasonById(String seasonId) async {
    try {
      final response = await _apiClient.dio.get(
        '${AppConstants.seasonsBase}/$seasonId',
      );

      final apiResponse = ApiResponseModel<SeasonModel>.fromJson(
        response.data,
        (json) => SeasonModel.fromJson(json as Map<String, dynamic>),
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

  Future<SeasonModel> updateSeason({
    required String seasonId,
    String? seasonName,
    int? startMonth,
    int? startYear,
    int? endMonth,
    int? endYear,
    String? farmId,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (seasonName != null) data['seasonName'] = seasonName;
      if (startMonth != null) data['startMonth'] = startMonth;
      if (startYear != null) data['startYear'] = startYear;
      if (endMonth != null) data['endMonth'] = endMonth;
      if (endYear != null) data['endYear'] = endYear;
      if (farmId != null) data['farmId'] = farmId;

      final response = await _apiClient.dio.put(
        '${AppConstants.seasonsBase}/$seasonId',
        data: data,
      );

      final apiResponse = ApiResponseModel<SeasonModel>.fromJson(
        response.data,
        (json) => SeasonModel.fromJson(json as Map<String, dynamic>),
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

  Future<void> endSeason(String seasonId) async {
    try {
      final response = await _apiClient.dio.post(
        '${AppConstants.seasonsBase}/$seasonId/end',
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

  Future<void> deleteSeason(String seasonId) async {
    try {
      final response = await _apiClient.dio.delete(
        '${AppConstants.seasonsBase}/$seasonId',
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

