import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class ApiClient {
  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  // IMPORTANT: Update this URL based on your environment
  // - Android Emulator: http://10.0.2.2:PORT/api (replace PORT with your backend port)
  // - iOS Simulator: http://localhost:PORT/api
  // - Physical Device: http://YOUR_COMPUTER_IP:PORT/api
  // 
  // Check your backend console output for the actual port when you run "dotnet run"
  // Common ports: 5000, 7001 (HTTP), 7000 (HTTPS)
  // For Android emulator, use 10.0.2.2 instead of localhost
  // UPDATED: Using LAN IP for Physical Device Support
  static const String baseUrl = 'http://192.168.8.110:5000/api';

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      // Increased timeouts to 60 seconds to handle slow connections
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(AuthInterceptor(_storage));
    // Enable logging for debugging
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
      logPrint: (object) => print('[API] $object'),
    ));
  }

  Dio get dio => _dio;
}

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;

  AuthInterceptor(this._storage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: AppConstants.jwtTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Handle unauthorized - clear all auth data
      // This will trigger AuthWrapper to redirect to login on next build
      await _storage.delete(key: AppConstants.jwtTokenKey);
      await _storage.delete(key: AppConstants.userIdKey);
      await _storage.delete(key: AppConstants.userEmailKey);
      await _storage.delete(key: AppConstants.userFullNameKey);
      print('[API] Token expired - cleared all auth data. Please log in again.');
    }
    handler.next(err);
  }
}

