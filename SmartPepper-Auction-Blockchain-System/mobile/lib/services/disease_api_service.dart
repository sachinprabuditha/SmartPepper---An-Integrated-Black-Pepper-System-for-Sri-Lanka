import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import '../models/disease_location.dart';

class DiseaseApiService {
  late Dio _dio;

  // Disease detection backend runs on port 5000
  // Update this IP address to match your computer's IP
  static const String diseaseApiBaseUrl = 'http://192.168.1.68:5005';

  // API Endpoints
  static const String predictEndpoint = '/predict';
  static const String diseaseLocationsEndpoint = '/api/disease-locations';

  // Full URLs
  static String get predictUrl => '$diseaseApiBaseUrl$predictEndpoint';
  static String get diseaseLocationsUrl =>
      '$diseaseApiBaseUrl$diseaseLocationsEndpoint';

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
          print(' Disease API REQUEST: ${options.method} ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(' Disease API RESPONSE: ${response.statusCode}');
          return handler.next(response);
        },
        onError: (error, handler) {
          print(' Disease API Error: ${error.message}');
          if (error.response != null) {
            print('   Status: ${error.response?.statusCode}');
            print('   Data: ${error.response?.data}');
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Predict disease from images using multipart form data
  /// Returns analysis results including severity, disease counts, and forecasts
  Future<Map<String, dynamic>> predictDisease(List<File> imageFiles) async {
    if (imageFiles.isEmpty) {
      throw Exception('No images provided for analysis');
    }

    if (imageFiles.length > 4) {
      throw Exception('Maximum 4 images allowed');
    }

    try {
      print(' Uploading ${imageFiles.length} image(s) for analysis...');

      // Create HTTP client with extended timeout for large image processing
      final client = http.Client();

      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(predictUrl));

      // Add all image files
      for (var file in imageFiles) {
        request.files.add(
          await http.MultipartFile.fromPath('images', file.path),
        );
      }

      // Add headers to accept compressed response
      request.headers['Accept-Encoding'] = 'gzip, deflate';

      print('Sending request to server...');
      var streamedResponse = await client.send(request).timeout(
        const Duration(seconds: 300),
        onTimeout: () {
          throw Exception('Request timeout - Server took too long to respond');
        },
      );

      print(
          'Reading response (${streamedResponse.contentLength ?? "unknown"} bytes)...');
      var response = await http.Response.fromStream(streamedResponse).timeout(
        const Duration(seconds: 600), // 10 minutes for reading large response
        onTimeout: () {
          throw Exception('Response timeout - Failed to receive complete data');
        },
      );

      client.close();

      if (response.statusCode == 200) {
        final jsonResponse = Map<String, dynamic>.from(
          _parseJson(response.body),
        );

        print(' Response received successfully');
        print(' Total leaves: ${jsonResponse['total_detected']}');
        print('🌡 Severity: ${jsonResponse['severity']}%');

        return jsonResponse;
      } else {
        // Parse error response
        String errorMsg = 'Server error: ${response.statusCode}';
        try {
          var errorJson = _parseJson(response.body);
          errorMsg = errorJson['message'] ?? errorJson['error'] ?? errorMsg;
        } catch (_) {
          errorMsg = response.body.isNotEmpty ? response.body : errorMsg;
        }
        throw Exception(errorMsg);
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on Exception catch (e) {
      rethrow;
    } catch (e) {
      throw Exception('Error analyzing images: $e');
    }
  }

  dynamic _parseJson(String body) {
    try {
      return const JsonCodec().decode(body);
    } catch (e) {
      throw Exception('Invalid JSON response from server');
    }
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
