import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_response_model.dart';
import '../services/auth_service.dart';
import '../../../../core/network/api_client.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ApiClient());
});

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<AuthResponseModel?>>((ref) {
  return AuthController(ref.read(authServiceProvider));
});

class AuthController extends StateNotifier<AsyncValue<AuthResponseModel?>> {
  final AuthService _authService;

  AuthController(this._authService) : super(const AsyncValue.data(null));

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await _authService.signIn(email, password);
      state = AsyncValue.data(response);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
      );
      state = AsyncValue.data(response);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = const AsyncValue.data(null);
  }

  Future<bool> checkAuthStatus() async {
    return await _authService.isLoggedIn();
  }
}

