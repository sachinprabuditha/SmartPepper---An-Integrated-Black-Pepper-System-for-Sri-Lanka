import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/blockchain_service.dart';

class User {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? walletAddress;
  final bool verified;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.walletAddress,
    this.verified = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      walletAddress: json['walletAddress'],
      verified: json['verified'] ?? false,
    );
  }
}

class AuthProvider with ChangeNotifier {
  final ApiService apiService;
  final StorageService storageService;
  final BlockchainService blockchainService;

  User? _user;
  bool _isAuthenticated = false;
  bool _loading = false;
  String? _error;

  AuthProvider({
    required this.apiService,
    required this.storageService,
    required this.blockchainService,
  });

  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> checkAuthStatus() async {
    _loading = true;
    notifyListeners();

    try {
      final token = await storageService.getToken();
      if (token != null) {
        final userData = await apiService.getCurrentUser();
        _user = User.fromJson(userData);
        _isAuthenticated = true;
      }
    } catch (e) {
      print('Auth check failed: $e');
      await logout();
    }

    _loading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final response = await apiService.login({
        'email': email,
        'password': password,
      });

      await storageService.saveToken(response['token']);
      _user = User.fromJson(response['user']);
      _isAuthenticated = true;

      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
  }) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final response = await apiService.register({
        'email': email,
        'password': password,
        'name': name,
        'role': role,
        if (phone != null) 'phone': phone,
      });

      await storageService.saveToken(response['token']);
      _user = User.fromJson(response['user']);
      _isAuthenticated = true;

      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await storageService.clearAll();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
