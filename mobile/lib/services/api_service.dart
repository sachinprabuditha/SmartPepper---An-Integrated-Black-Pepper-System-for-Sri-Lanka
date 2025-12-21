import 'package:dio/dio.dart';
import '../config/env.dart';

class ApiService {
  late Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: Environment.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token if available
          // final token = await _getToken();
          // if (token != null) {
          //   options.headers['Authorization'] = 'Bearer $token';
          // }
          return handler.next(options);
        },
        onError: (error, handler) {
          print('API Error: ${error.message}');
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
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/auth/login', data: data);
      return response.data;
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
    } catch (e) {
      rethrow;
    }
  }

  // Auction endpoints
  Future<List<dynamic>> getAuctions() async {
    try {
      final response = await _dio.get('/auctions');
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
}
