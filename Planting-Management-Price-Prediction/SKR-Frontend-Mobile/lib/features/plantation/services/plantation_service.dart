import 'package:dio/dio.dart';
import '../models/farm_record_model.dart';
import '../models/farm_task_model.dart';
import '../../auth/models/api_response_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/constants.dart';

class PlantationService {
  final ApiClient _apiClient;

  PlantationService(this._apiClient);

  /// Start a new plantation (Part 02 - Planting Start)
  Future<FarmRecord> startPlantation({
    required String farmName,
    required int districtId,
    required int soilTypeId,
    required String chosenVarietyId,
    required DateTime farmStartDate,
    required double areaHectares,
    required int totalVines,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '${AppConstants.plantationBase}/start',
        data: {
          'farmName': farmName,
          'districtId': districtId,
          'soilTypeId': soilTypeId,
          'chosenVarietyId': chosenVarietyId,
          // Send date as date-only string (YYYY-MM-DD) to avoid timezone conversion issues
          // This ensures the selected date is preserved regardless of timezone
          'farmStartDate': '${farmStartDate.year.toString().padLeft(4, '0')}-${farmStartDate.month.toString().padLeft(2, '0')}-${farmStartDate.day.toString().padLeft(2, '0')}T00:00:00Z',
          'areaHectares': areaHectares,
          'totalVines': totalVines,
        },
      );

      final apiResponse = ApiResponseModel<FarmRecord>.fromJson(
        response.data,
        (json) => FarmRecord.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.success && apiResponse.data != null) {
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

  /// Get all farms for the authenticated user
  Future<List<FarmRecord>> getFarms() async {
    try {
      final response = await _apiClient.dio.get(
        '${AppConstants.plantationBase}/farms',
      );

      final apiResponse = ApiResponseModel<List<FarmRecord>>.fromJson(
        response.data,
        (json) => (json as List)
            .map((item) => FarmRecord.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

      if (apiResponse.success && apiResponse.data != null) {
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

  /// Get a farm by ID
  Future<FarmRecord> getFarmById(String farmId) async {
    try {
      final response = await _apiClient.dio.get(
        '${AppConstants.plantationBase}/farm/$farmId',
      );

      final apiResponse = ApiResponseModel<FarmRecord>.fromJson(
        response.data,
        (json) => FarmRecord.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.success && apiResponse.data != null) {
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

  /// Update a farm record
  Future<FarmRecord> updateFarm({
    required String farmId,
    String? farmName,
    int? districtId,
    int? soilTypeId,
    String? chosenVarietyId,
    DateTime? farmStartDate,
    double? areaHectares,
    int? totalVines,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (farmName != null) data['farmName'] = farmName;
      if (districtId != null) data['districtId'] = districtId;
      if (soilTypeId != null) data['soilTypeId'] = soilTypeId;
      if (chosenVarietyId != null) data['chosenVarietyId'] = chosenVarietyId;
      if (farmStartDate != null)
      {
        // Send date as date-only string (YYYY-MM-DD) to avoid timezone conversion issues
        data['farmStartDate'] = '${farmStartDate.year.toString().padLeft(4, '0')}-${farmStartDate.month.toString().padLeft(2, '0')}-${farmStartDate.day.toString().padLeft(2, '0')}T00:00:00Z';
      }
      if (areaHectares != null) data['areaHectares'] = areaHectares;
      if (totalVines != null) data['totalVines'] = totalVines;

      final response = await _apiClient.dio.put(
        '${AppConstants.plantationBase}/farm/$farmId',
        data: data,
      );

      final apiResponse = ApiResponseModel<FarmRecord>.fromJson(
        response.data,
        (json) => FarmRecord.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.success && apiResponse.data != null) {
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

  /// Delete a farm record
  Future<void> deleteFarm(String farmId) async {
    try {
      final response = await _apiClient.dio.delete(
        '${AppConstants.plantationBase}/farm/$farmId',
      );

      final apiResponse = ApiResponseModel<dynamic>.fromJson(
        response.data,
        (json) => json,
      );

      if (!apiResponse.success) {
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

  /// Get all tasks for a specific farm (Part 03 - Display Timeline)
  Future<List<FarmTask>> getTasksByFarmId(String farmId) async {
    try {
      final response = await _apiClient.dio.get(
        '${AppConstants.plantationBase}/tasks/$farmId',
      );

      final apiResponse = ApiResponseModel<List<FarmTask>>.fromJson(
        response.data,
        (json) => (json as List)
            .map((item) => FarmTask.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

      if (apiResponse.success && apiResponse.data != null) {
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

  /// Complete a task with input details (Part 04.2/04.3 - Record Keeping)
  Future<FarmTask> completeTask({
    required String taskId,
    required List<InputItem> items,
    required double laborHours,
    String? notes,
  }) async {
    try {
      final data = <String, dynamic>{
        'items': items.map((item) => {
          'itemName': item.itemName,
          'quantity': item.quantity,
          'unitCostLKR': item.unitCostLKR,
          'unit': item.unit,
        }).toList(),
        'laborHours': laborHours,
      };
      if (notes != null) data['notes'] = notes;

      final response = await _apiClient.dio.put(
        '${AppConstants.plantationBase}/task/complete/$taskId',
        data: data,
      );

      final apiResponse = ApiResponseModel<FarmTask>.fromJson(
        response.data,
        (json) => FarmTask.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.success && apiResponse.data != null) {
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

  /// Update task details (manual tasks only, before completion)
  Future<FarmTask> updateTaskDetails({
    required String taskId,
    required String taskName,
    String? phase,
    required DateTime dueDate,
    String priority = 'Medium',
    List<String>? detailedSteps,
    String? reasonWhy,
  }) async {
    try {
      final data = <String, dynamic>{
        'taskName': taskName,
        'dueDate': dueDate.toIso8601String(),
        'priority': priority,
      };
      if (phase != null) data['phase'] = phase;
      if (detailedSteps != null) data['detailedSteps'] = detailedSteps;
      if (reasonWhy != null) data['reasonWhy'] = reasonWhy;

      final response = await _apiClient.dio.put(
        '${AppConstants.plantationBase}/tasks/$taskId',
        data: data,
      );

      final apiResponse = ApiResponseModel<FarmTask>.fromJson(
        response.data,
        (json) => FarmTask.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.success && apiResponse.data != null) {
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

  /// Update completion details (both manual and auto tasks, after completion)
  Future<FarmTask> updateCompletionDetails({
    required String taskId,
    required List<InputItem> items, // Can be empty list to clear items
    required double laborHours,
    String? notes,
  }) async {
    try {
      final data = <String, dynamic>{
        'items': items.map((item) => {
          'itemName': item.itemName,
          'quantity': item.quantity,
          'unitCostLKR': item.unitCostLKR,
          'unit': item.unit,
        }).toList(), // Always send items array (even if empty)
        'laborHours': laborHours,
      };
      if (notes != null && notes.isNotEmpty) {
        data['notes'] = notes;
      } else {
        data['notes'] = null; // Explicitly set to null if empty
      }

      final response = await _apiClient.dio.put(
        '${AppConstants.plantationBase}/tasks/$taskId/completion',
        data: data,
      );

      final apiResponse = ApiResponseModel<FarmTask>.fromJson(
        response.data,
        (json) => FarmTask.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.success && apiResponse.data != null) {
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

  /// Delete a task (manual tasks only, before completion)
  Future<void> deleteTask(String taskId) async {
    try {
      await _apiClient.dio.delete(
        '${AppConstants.plantationBase}/tasks/$taskId',
      );
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

  /// Create a manual task (emergency or custom)
  Future<FarmTask> createManualTask({
    required String farmId,
    required String taskName,
    String? phase,
    required DateTime dueDate,
    String priority = 'Medium',
    List<String>? detailedSteps,
    String? reasonWhy,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '${AppConstants.plantationBase}/tasks/manual',
        data: {
          'farmId': farmId,
          'taskName': taskName,
          'phase': phase ?? 'Maintenance',
          'taskType': 'Manual',
          'dueDate': dueDate.toIso8601String(),
          'priority': priority,
          'detailedSteps': detailedSteps ?? [],
          'reasonWhy': reasonWhy ?? '',
        },
      );

      final apiResponse = ApiResponseModel<FarmTask>.fromJson(
        response.data,
        (json) => FarmTask.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.success && apiResponse.data != null) {
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
}

