import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../config/env.dart';

class ApiService {
  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: Environment.apiBaseUrl,
        connectTimeout:
            const Duration(seconds: 60), // Increased for physical devices
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Add comprehensive HTTP logging
    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: true,
        error: true,
        compact: false,
        maxWidth: 120,
        enabled: true, // Set to false in production
        filter: (options, args) {
          // Log all requests
          return true;
        },
      ),
    );

    // Add auth token interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token if available
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          print('🔹 REQUEST: ${options.method} ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
              '✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
          return handler.next(response);
        },
        onError: (error, handler) {
          print('❌ API Error: ${error.message}');
          if (error.response != null) {
            print('   Status: ${error.response?.statusCode}');
            print('   Data: ${error.response?.data}');
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Auth endpoints
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/auth/register', data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        // Extract error message from response
        final errorData = e.response!.data;
        if (errorData is Map && errorData.containsKey('error')) {
          throw Exception(errorData['error']);
        } else if (errorData is Map && errorData.containsKey('message')) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Network error. Please check your connection.');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/auth/login', data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        // Extract error message from response
        final errorData = e.response!.data;
        if (errorData is Map && errorData.containsKey('error')) {
          throw Exception(errorData['error']);
        } else if (errorData is Map && errorData.containsKey('message')) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Network error. Please check your connection.');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Lot endpoints
  Future<List<dynamic>> getLots({String? farmerAddress}) async {
    try {
      final response = await _dio.get(
        '/lots',
        queryParameters: {if (farmerAddress != null) 'farmer': farmerAddress},
      );
      return response.data['lots'] ?? [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getLotById(String lotId) async {
    try {
      final response = await _dio.get('/lots/$lotId');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createLot(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/lots', data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        // Extract error message from response
        final errorData = e.response!.data;
        if (errorData is Map && errorData.containsKey('error')) {
          throw Exception(errorData['error']);
        } else if (errorData is Map && errorData.containsKey('message')) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Network error. Please check your connection.');
    } catch (e) {
      rethrow;
    }
  }

  // Auction endpoints
  Future<List<dynamic>> getAuctions({String? farmerAddress}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (farmerAddress != null && farmerAddress.isNotEmpty) {
        queryParams['farmer'] = farmerAddress;
      }
      final response = await _dio.get(
        '/auctions',
        queryParameters: queryParams,
      );
      return response.data['auctions'] ?? [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAuctionById(String auctionId) async {
    try {
      final response = await _dio.get('/auctions/$auctionId');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createAuction(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/auctions', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> placeBid(
    String auctionId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post('/auctions/$auctionId/bid', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Compliance endpoints
  Future<Map<String, dynamic>> checkCompliance(String lotId) async {
    try {
      final response = await _dio.get('/compliance/$lotId');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // NFT Passport endpoints
  Future<Map<String, dynamic>> mintPassport(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/nft-passport/mint', data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData.containsKey('error')) {
          throw Exception('Failed to mint passport: ${errorData['error']}');
        } else if (errorData is Map && errorData.containsKey('message')) {
          throw Exception('Failed to mint passport: ${errorData['message']}');
        }
      }
      throw Exception(
          'Failed to mint passport: Network error. Please check your connection.');
    } catch (e) {
      throw Exception('Failed to mint passport: ${e.toString()}');
    }
  }

  // File upload
  Future<String> uploadFile(String filePath) async {
    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await _dio.post('/upload', data: formData);
      return response.data['url'];
    } catch (e) {
      rethrow;
    }
  }

  // Generic HTTP methods
  Future<dynamic> get(String endpoint,
      {Map<String, dynamic>? queryParameters}) async {
    try {
      final response =
          await _dio.get(endpoint, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData.containsKey('error')) {
          throw Exception(errorData['error']);
        } else if (errorData is Map && errorData.containsKey('message')) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Network error. Please check your connection.');
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic>? data) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData.containsKey('error')) {
          throw Exception(errorData['error']);
        } else if (errorData is Map && errorData.containsKey('message')) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Network error. Please check your connection.');
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic>? data) async {
    try {
      final response = await _dio.patch(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData.containsKey('error')) {
          throw Exception(errorData['error']);
        } else if (errorData is Map && errorData.containsKey('message')) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Network error. Please check your connection.');
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await _dio.delete(endpoint);
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData.containsKey('error')) {
          throw Exception(errorData['error']);
        } else if (errorData is Map && errorData.containsKey('message')) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Network error. Please check your connection.');
    } catch (e) {
      rethrow;
    }
  }

  // Processing Stages endpoint
  Future<Map<String, dynamic>> addProcessingStage({
    required String lotId,
    required String stageType,
    required String stageName,
    required String location,
    required String timestamp,
    required String operatorName,
    required Map<String, dynamic> qualityMetrics,
    required String notes,
  }) async {
    try {
      final response = await _dio.post('/processing/stages', data: {
        'lotId': lotId,
        'stageType': stageType,
        'stageName': stageName,
        'location': location,
        'timestamp': timestamp,
        'operatorName': operatorName,
        'qualityMetrics': qualityMetrics,
        'notes': notes,
      });
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData.containsKey('error')) {
          throw Exception(errorData['error']);
        } else if (errorData is Map && errorData.containsKey('message')) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Failed to add processing stage');
    } catch (e) {
      rethrow;
    }
  }
}
