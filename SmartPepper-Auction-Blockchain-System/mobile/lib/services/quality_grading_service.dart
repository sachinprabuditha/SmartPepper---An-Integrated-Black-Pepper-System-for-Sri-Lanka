import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/env.dart';

/// Model for Quality Grading data from ML system
class QualityGradingRecord {
  final String id;
  final double density;
  final double weightGrams;
  final Map<String, double> visualPercentages;
  final String finalGrade;
  final DateTime timestamp;

  QualityGradingRecord({
    required this.id,
    required this.density,
    required this.weightGrams,
    required this.visualPercentages,
    required this.finalGrade,
    required this.timestamp,
  });

  factory QualityGradingRecord.fromJson(Map<String, dynamic> json) {
    return QualityGradingRecord(
      id: json['id'] ?? '',
      density: (json['density'] ?? 0).toDouble(),
      weightGrams: (json['weightGrams'] ?? 0).toDouble(),
      visualPercentages: {
        'pure': (json['visualPercentages']?['pure'] ?? 0).toDouble(),
        'molded': (json['visualPercentages']?['molded'] ?? 0).toDouble(),
        'discolored':
            (json['visualPercentages']?['discolored'] ?? 0).toDouble(),
      },
      finalGrade: json['finalGrade'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  /// Map ML Grade (A-D) to mobile app grade (AAA-B)
  /// Grade A (Premium High Density) -> AAA
  /// Grade B (Standard High Quality) -> AA
  /// Grade C (Lightweight / Industrial) -> A
  /// Grade D (Low Density / Waste) -> B
  String getMappedGrade() {
    if (finalGrade.startsWith('Grade A')) return 'AAA';
    if (finalGrade.startsWith('Grade B')) return 'AA';
    if (finalGrade.startsWith('Grade C')) return 'A';
    if (finalGrade.startsWith('Grade D')) return 'B';
    return 'B'; // Default to lowest grade
  }

  /// Get a short display text for the grade
  String getGradeDisplay() {
    final mapped = getMappedGrade();
    return '$mapped (${finalGrade.split('(').first.trim()})';
  }
}

/// Service for Quality Grading ML system integration
class QualityGradingService {
  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  QualityGradingService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: Environment.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Add auth token interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          print('❌ Quality Grading API Error: ${error.message}');
          if (error.response != null) {
            print('   Status: ${error.response?.statusCode}');
            print('   Data: ${error.response?.data}');
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Get quality grading history for the logged-in farmer
  Future<List<QualityGradingRecord>> getQualityGradingHistory() async {
    try {
      print('Fetching quality grading history...');
      final response = await _dio.get('/quality-grading/history');

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => QualityGradingRecord.fromJson(json)).toList();
      } else {
        throw Exception(response.data['error'] ??
            'Failed to fetch quality grading history');
      }
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
      print('Error fetching quality grading history: $e');
      rethrow;
    }
  }

  /// Get the latest quality grading record for the farmer
  Future<QualityGradingRecord?> getLatestQualityGrading() async {
    try {
      final history = await getQualityGradingHistory();
      if (history.isEmpty) return null;

      // History is already sorted by timestamp descending from backend
      return history.first;
    } catch (e) {
      print('Error fetching latest quality grading: $e');
      rethrow;
    }
  }

  /// Save a new quality grading entry (if needed for manual entry)
  Future<QualityGradingRecord> saveQualityGrading({
    required double weightGrams,
    required double density,
    required Map<String, double> visualPercentages,
  }) async {
    try {
      print('Saving quality grading...');
      final response = await _dio.post(
        '/quality-grading',
        data: {
          'weightGrams': weightGrams,
          'density': density,
          'visualPercentages': visualPercentages,
        },
      );

      if (response.data['success'] == true) {
        return QualityGradingRecord.fromJson(response.data['data']);
      } else {
        throw Exception(
            response.data['error'] ?? 'Failed to save quality grading');
      }
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
      print('Error saving quality grading: $e');
      rethrow;
    }
  }
}
