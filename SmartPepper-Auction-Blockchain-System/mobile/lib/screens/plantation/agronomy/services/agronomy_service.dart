import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/agronomy_guide_response_model.dart';
import '../models/district_model.dart';
import '../models/soil_type_model.dart';
import '../models/variety_model.dart';
import '../models/api_response_model.dart';

/// A dedicated Dio client for the Plantation Management microservice backend.
/// This runs separately from the main SmartPepper backend.
/// Update [plantationBaseUrl] to match your server's IP/port.
import '../../services/plantation_api_client.dart';

class AgronomyService {
  final PlantationApiClient _client;

  AgronomyService() : _client = PlantationApiClient();

  Future<List<District>> fetchAllDistricts() async {
    try {
      final response = await _client.dio.get('/agronomy/districts');
      final apiResponse = ApiResponseModel<List<District>>.fromJson(
        response.data,
        (json) {
          if (json is List) {
            return json
                .map((e) => District.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          return <District>[];
        },
      );
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      }
      throw Exception(apiResponse.message);
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

  Future<List<SoilType>> fetchSoilsByDistrict(String districtId) async {
    try {
      final response = await _client.dio
          .get('/agronomy/districts/$districtId/soils');
      final apiResponse = ApiResponseModel<List<SoilType>>.fromJson(
        response.data,
        (json) {
          if (json is List) {
            return json
                .map((e) => SoilType.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          return <SoilType>[];
        },
      );
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      }
      throw Exception(apiResponse.message);
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

  Future<List<AgronomyGuideResponse>> searchGuides(
      String districtId, String? soilTypeId) async {
    try {
      final Map<String, dynamic> queryParams = {'districtId': districtId};
      if (soilTypeId != null) queryParams['soilTypeId'] = soilTypeId;

      final response = await _client.dio.get(
        '/agronomy/search',
        queryParameters: queryParams,
      );

      final apiResponse =
          ApiResponseModel<List<AgronomyGuideResponse>>.fromJson(
        response.data,
        (json) {
          if (json is List) {
            return json
                .map((e) =>
                    AgronomyGuideResponse.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          return <AgronomyGuideResponse>[];
        },
      );

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      }
      throw Exception(apiResponse.message);
    } on DioException catch (e) {
      if (e.response != null) {
        if (e.response!.data == null ||
            e.response!.data.toString().isEmpty) {
          if (e.response!.statusCode == 404) {
            throw Exception('No guides found for the selected criteria.');
          }
          throw Exception('Server returned an empty response');
        }
        try {
          final apiResponse = ApiResponseModel<dynamic>.fromJson(
            e.response!.data,
            (json) => json,
          );
          throw Exception(apiResponse.message);
        } catch (_) {
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
      final response = await _client.dio.get(
        '/agronomy/districts/$districtId/soils/$soilTypeId/varieties',
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
      final response = await _client.dio.get(
        '/agronomy/varieties',
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
