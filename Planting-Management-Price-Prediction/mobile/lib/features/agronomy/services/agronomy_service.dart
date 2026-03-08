import 'package:dio/dio.dart';
import '../models/planting_guide_model.dart';
import '../models/variety_model.dart';
import '../models/district_model.dart';
import '../models/soil_type_model.dart';
import '../models/agronomy_guide_response_model.dart';
import '../../auth/models/api_response_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/constants.dart';

class AgronomyService {
  final ApiClient _apiClient;

  AgronomyService(this._apiClient);

  /// Fetches all districts
  Future<List<District>> fetchAllDistricts() async {
    try {
      final response = await _apiClient.dio.get(
        '${AppConstants.agronomyBase}/districts',
      );

      final apiResponse = ApiResponseModel<List<District>>.fromJson(
        response.data,
        (json) {
          if (json is List) {
            return json.map((e) => District.fromJson(e as Map<String, dynamic>)).toList();
          }
          return <District>[];
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

  /// Fetches soil types for a specific district
  Future<List<SoilType>> fetchSoilsByDistrict(String districtId) async {
    try {
      final response = await _apiClient.dio.get(
        '${AppConstants.agronomyBase}/districts/$districtId/soils',
      );

      final apiResponse = ApiResponseModel<List<SoilType>>.fromJson(
        response.data,
        (json) {
          if (json is List) {
            return json.map((e) => SoilType.fromJson(e as Map<String, dynamic>)).toList();
          }
          return <SoilType>[];
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

  /// Fetches agronomy guide for district, soil type, and variety combination
  Future<AgronomyGuideResponse> fetchGuide({
    required String districtId,
    required String soilTypeId,
    required String varietyId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '${AppConstants.agronomyBase}/guide',
        queryParameters: {
          'districtId': districtId,
          'soilTypeId': soilTypeId,
          'varietyId': varietyId,
        },
      );

      final apiResponse = ApiResponseModel<AgronomyGuideResponse>.fromJson(
        response.data,
        (json) => AgronomyGuideResponse.fromJson(json as Map<String, dynamic>),
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

  /// Fetches planting guide data for a specific district (Deprecated - kept for backward compatibility if needed, but updated for String)
  @Deprecated('Use fetchGuide with districtId, soilTypeId, and varietyId instead')
  Future<PlantingGuide> fetchGuideData(String districtName) async {
    try {
      final response = await _apiClient.dio.get(
        '${AppConstants.agronomyBase}/guide/$districtName',
      );

      final apiResponse = ApiResponseModel<PlantingGuide>.fromJson(
        response.data,
        (json) => PlantingGuide.fromJson(json as Map<String, dynamic>),
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

  /// Fetches all guides (with variety details and steps) for a specific district and soil type combination
  Future<List<AgronomyGuideResponse>> fetchAllGuidesByDistrictAndSoil(String districtId, String soilTypeId) async {
    return searchGuides(districtId, soilTypeId);
  }

  /// Searches for agronomy guides by district and optional soil type
  Future<List<AgronomyGuideResponse>> searchGuides(String districtId, String? soilTypeId) async {
    try {
      final Map<String, dynamic> queryParams = {'districtId': districtId};
      if (soilTypeId != null) {
        queryParams['soilTypeId'] = soilTypeId;
      }

      final response = await _apiClient.dio.get(
        '${AppConstants.agronomyBase}/search',
        queryParameters: queryParams,
      );

      final apiResponse = ApiResponseModel<List<AgronomyGuideResponse>>.fromJson(
        response.data,
        (json) {
          if (json is List) {
            return json.map((e) => AgronomyGuideResponse.fromJson(e as Map<String, dynamic>)).toList();
          }
          return <AgronomyGuideResponse>[];
        },
      );

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw Exception(apiResponse.message);
      }
    } on DioException catch (e) {
      if (e.response != null) {
        // Handle empty response body (e.g., 404 with no content)
        if (e.response!.data == null || 
            e.response!.data.toString().isEmpty || 
            (e.response!.data is String && (e.response!.data as String).isEmpty)) {
          if (e.response!.statusCode == 404) {
            throw Exception('No guides found for the selected criteria.');
          }
          throw Exception('Server returned an empty response');
        }
        
        // Try to parse error response
        try {
          final apiResponse = ApiResponseModel<dynamic>.fromJson(
            e.response!.data,
            (json) => json,
          );
          throw Exception(apiResponse.message);
        } catch (parseError) {
          // If parsing fails, use status code message
          if (e.response!.statusCode == 404) {
            throw Exception('No guides found for the selected criteria.');
          }
          throw Exception('Error: ${e.response!.statusCode}');
        }
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Fetches varieties available for a specific district and soil type combination
  Future<List<BlackPepperVariety>> fetchVarietiesByDistrictAndSoil(String districtId, String soilTypeId) async {
    try {
      final response = await _apiClient.dio.get(
        '${AppConstants.agronomyBase}/districts/$districtId/soils/$soilTypeId/varieties',
      );

      final apiResponse = ApiResponseModel<List<BlackPepperVariety>>.fromJson(
        response.data,
        (json) {
          if (json is List) {
            return json.map((e) => BlackPepperVariety.fromJson(e as Map<String, dynamic>)).toList();
          }
          return <BlackPepperVariety>[];
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

  /// Fetches all varieties
  Future<List<BlackPepperVariety>> fetchAllVarieties() async {
    try {
      final response = await _apiClient.dio.get(
        '${AppConstants.agronomyBase}/varieties',
      );

      final apiResponse = ApiResponseModel<List<BlackPepperVariety>>.fromJson(
        response.data,
        (json) {
          if (json is List) {
            return json.map((e) => BlackPepperVariety.fromJson(e as Map<String, dynamic>)).toList();
          }
          return <BlackPepperVariety>[];
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
}
