import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A shared Dio client for the Plantation Management microservice backend.
/// This runs separately from the main SmartPepper backend.
class PlantationApiClient {
  static const String plantationBaseUrl = 'http://192.168.1.153:5000/api';
  // For Android Emulator (Pixel): 'http://10.0.2.2:5000/api'

  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  PlantationApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: plantationBaseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      error: true,
      logPrint: (object) => print('[PlantationAPI] $object'),
    ));

    // Add auth token interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token if available (using same key as main app)
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  Dio get dio => _dio;
}
