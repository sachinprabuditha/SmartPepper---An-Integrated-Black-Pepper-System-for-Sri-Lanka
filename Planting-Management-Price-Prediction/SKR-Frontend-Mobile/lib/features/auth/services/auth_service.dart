import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_response_model.dart';
import '../models/api_response_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/constants.dart';

class AuthService {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthService(this._apiClient);

  Future<AuthResponseModel> signIn(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        AppConstants.authSignIn,
        data: {
          'email': email,
          'password': password,
        },
      );

      final apiResponse = ApiResponseModel<AuthResponseModel>.fromJson(
        response.data,
        (json) => AuthResponseModel.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.success && apiResponse.data != null) {
        // Store token and user info
        await _storage.write(key: AppConstants.jwtTokenKey, value: apiResponse.data!.token);
        await _storage.write(key: AppConstants.userIdKey, value: apiResponse.data!.userId);
        await _storage.write(key: AppConstants.userEmailKey, value: apiResponse.data!.email);
        await _storage.write(key: AppConstants.userFullNameKey, value: apiResponse.data!.fullName);

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

  Future<AuthResponseModel> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        AppConstants.authSignUp,
        data: {
          'email': email,
          'password': password,
          'fullName': fullName,
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
        },
      );

      final apiResponse = ApiResponseModel<AuthResponseModel>.fromJson(
        response.data,
        (json) => AuthResponseModel.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.success && apiResponse.data != null) {
        // Store token and user info
        await _storage.write(key: AppConstants.jwtTokenKey, value: apiResponse.data!.token);
        await _storage.write(key: AppConstants.userIdKey, value: apiResponse.data!.userId);
        await _storage.write(key: AppConstants.userEmailKey, value: apiResponse.data!.email);
        await _storage.write(key: AppConstants.userFullNameKey, value: apiResponse.data!.fullName);

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

  Future<void> signOut() async {
    await _storage.delete(key: AppConstants.jwtTokenKey);
    await _storage.delete(key: AppConstants.userIdKey);
    await _storage.delete(key: AppConstants.userEmailKey);
    await _storage.delete(key: AppConstants.userFullNameKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: AppConstants.jwtTokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: AppConstants.userIdKey);
  }
}

