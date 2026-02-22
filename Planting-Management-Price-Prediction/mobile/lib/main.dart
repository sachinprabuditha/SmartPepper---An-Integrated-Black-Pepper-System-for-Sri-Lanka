import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/pages/login_page.dart';
import 'features/auth/pages/home_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/utils/constants.dart';
import 'dart:developer' as developer;
import 'dart:async';

void main() {
  // Add error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    developer.log('Flutter Error: ${details.exception}', error: details.exception, stackTrace: details.stack);
  };

  runApp(
    const ProviderScope(
      child: HarvestTrackerApp(),
    ),
  );
}

class HarvestTrackerApp extends StatelessWidget {
  const HarvestTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set up global error widget builder
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Widget Error',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    details.exception.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    };
    
    return MaterialApp(
      title: 'Harvest Tracker',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _storage = const FlutterSecureStorage();
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _hasInitialized = false;
  Timer? _authCheckTimer;

  @override
  void initState() {
    super.initState();
    if (!_hasInitialized) {
      _hasInitialized = true;
      _checkAuthStatus();
    }
    // Periodically check auth status to catch token expiration
    _authCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkAuthStatus();
    });
  }

  @override
  void dispose() {
    _authCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Add timeout to prevent hanging
      await _performAuthCheck().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          developer.log('Auth check timed out, defaulting to logged out');
          if (mounted) {
            setState(() {
              _isLoggedIn = false;
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      developer.log('Error checking auth status: $e');
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _performAuthCheck() async {
    final token = await _storage.read(key: AppConstants.jwtTokenKey);
    final userId = await _storage.read(key: AppConstants.userIdKey);
    developer.log('Auth check: token exists = ${token != null && token.isNotEmpty}, userId = $userId');
    
    // For now, if token exists but userId is missing, clear everything
    if (token != null && token.isNotEmpty && (userId == null || userId.isEmpty)) {
      developer.log('Token exists but userId is missing, clearing auth');
      await _storage.delete(key: AppConstants.jwtTokenKey);
      await _storage.delete(key: AppConstants.userIdKey);
      await _storage.delete(key: AppConstants.userEmailKey);
      await _storage.delete(key: AppConstants.userFullNameKey);
    }
    
    if (mounted) {
      final newIsLoggedIn = token != null && token.isNotEmpty && userId != null && userId.isNotEmpty;
      // Only call setState if the state actually changed
      if (_isLoggedIn != newIsLoggedIn || _isLoading) {
        setState(() {
          _isLoggedIn = newIsLoggedIn;
          _isLoading = false;
          _hasInitialized = true;
        });
      } else {
        // Even if state didn't change, mark as initialized
        _hasInitialized = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Prevent unnecessary rebuilds by checking if state actually changed
    if (_isLoading) {
      developer.log('AuthWrapper: Showing loading screen');
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    // Only log once per state change to reduce noise
    if (!_hasInitialized) {
      developer.log('Building AuthWrapper: isLoading=$_isLoading, isLoggedIn=$_isLoggedIn');
    }
    
    // Return the appropriate page - using const to prevent rebuilds
    if (_isLoggedIn) {
      if (!_hasInitialized) {
        developer.log('AuthWrapper: Building HomePage');
      }
      return const HomePage(key: ValueKey('home_page'));
    } else {
      if (!_hasInitialized) {
        developer.log('AuthWrapper: Building LoginPage');
      }
      return const LoginPage(key: ValueKey('login_page'));
    }
  }
}

