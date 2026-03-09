import 'package:dio/dio.dart';
import '../models/disease_location.dart';

class DiseaseApiService {
  late Dio _dio;

  // Disease detection backend runs on port 5000
  // Update this IP address to match your computer's IP
  static const String diseaseApiBaseUrl = 'http://192.168.8.197:5000';

  DiseaseApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: diseaseApiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Add logging interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('🔹 Disease API REQUEST: ${options.method} ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('✅ Disease API RESPONSE: ${response.statusCode}');
          return handler.next(response);
        },
        onError: (error, handler) {
          print('❌ Disease API Error: ${error.message}');
          if (error.response != null) {
            print('   Status: ${error.response?.statusCode}');
            print('   Data: ${error.response?.data}');
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Get all disease locations from Firebase
  Future<List<DiseaseLocation>> getDiseaseLocations() async {
    try {
      final response = await _dio.get('/api/disease-locations');

      if (response.data['status'] == 'success') {
        final List<dynamic> locationsData = response.data['data'];
        return locationsData
            .map((json) => DiseaseLocation.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load disease locations');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Connection timeout. Please check your network.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
            'Cannot connect to server. Make sure the disease detection server is running on port 5000.');
      } else if (e.response != null) {
        throw Exception(
            e.response?.data['message'] ?? 'Failed to load disease locations');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error loading disease locations: $e');
    }
  }

  /// Save a disease location to Firebase
  Future<void> saveDiseaseLocation(DiseaseLocation location) async {
    try {
      final response = await _dio.post(
        '/api/disease-locations',
        data: location.toJson(),
      );

      if (response.data['status'] != 'success') {
        throw Exception('Failed to save disease location');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Connection timeout. Please check your network.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
            'Cannot connect to server. Make sure the disease detection server is running on port 5000.');
      } else if (e.response != null) {
        throw Exception(
            e.response?.data['message'] ?? 'Failed to save disease location');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error saving disease location: $e');
    }
  }
}
