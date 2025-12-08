import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../models/farm_record_model.dart';
import '../models/farm_task_model.dart';
import '../services/plantation_service.dart';
import '../../../../core/network/api_client.dart';

final plantationServiceProvider = Provider<PlantationService>((ref) {
  return PlantationService(ApiClient());
});

final farmsProvider = FutureProvider<List<FarmRecord>>((ref) async {
  try {
    developer.log('farmsProvider: Fetching farms...');
    final service = ref.read(plantationServiceProvider);
    final farms = await service.getFarms();
    developer.log('farmsProvider: Successfully fetched ${farms.length} farms');
    return farms;
  } catch (e, stackTrace) {
    developer.log('farmsProvider: Error fetching farms - $e', error: e, stackTrace: stackTrace);
    rethrow;
  }
});

final farmProvider = FutureProvider.family<FarmRecord, String>((ref, farmId) async {
  final service = ref.read(plantationServiceProvider);
  return await service.getFarmById(farmId);
});

final farmTasksProvider = FutureProvider.family<List<FarmTask>, String>((ref, farmId) async {
  final service = ref.read(plantationServiceProvider);
  return await service.getTasksByFarmId(farmId);
});

final plantationControllerProvider = StateNotifierProvider<PlantationController, AsyncValue<FarmRecord?>>((ref) {
  return PlantationController(ref.read(plantationServiceProvider));
});

class PlantationController extends StateNotifier<AsyncValue<FarmRecord?>> {
  final PlantationService _plantationService;

  PlantationController(this._plantationService) : super(const AsyncValue.data(null));

  Future<FarmRecord> startPlantation({
    required String farmName,
    required int districtId,
    required int soilTypeId,
    required String chosenVarietyId,
    required DateTime farmStartDate,
    required double areaHectares,
    required int totalVines,
  }) async {
    state = const AsyncValue.loading();
    try {
      final farmRecord = await _plantationService.startPlantation(
        farmName: farmName,
        districtId: districtId,
        soilTypeId: soilTypeId,
        chosenVarietyId: chosenVarietyId,
        farmStartDate: farmStartDate,
        areaHectares: areaHectares,
        totalVines: totalVines,
      );
      state = AsyncValue.data(farmRecord);
      return farmRecord;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<List<FarmRecord>> fetchFarms() async {
    try {
      return await _plantationService.getFarms();
    } catch (e) {
      rethrow;
    }
  }

  Future<FarmRecord> fetchFarmById(String farmId) async {
    try {
      return await _plantationService.getFarmById(farmId);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<FarmTask>> fetchTasksByFarmId(String farmId) async {
    try {
      return await _plantationService.getTasksByFarmId(farmId);
    } catch (e) {
      rethrow;
    }
  }

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
      final updated = await _plantationService.updateFarm(
        farmId: farmId,
        farmName: farmName,
        districtId: districtId,
        soilTypeId: soilTypeId,
        chosenVarietyId: chosenVarietyId,
        farmStartDate: farmStartDate,
        areaHectares: areaHectares,
        totalVines: totalVines,
      );
      return updated;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteFarm(String farmId) async {
    try {
      await _plantationService.deleteFarm(farmId);
    } catch (e) {
      rethrow;
    }
  }

  Future<FarmTask> completeTask({
    required String taskId,
    required List<InputItem> items,
    required double laborHours,
    String? notes,
  }) async {
    try {
      return await _plantationService.completeTask(
        taskId: taskId,
        items: items,
        laborHours: laborHours,
        notes: notes,
      );
    } catch (e) {
      rethrow;
    }
  }

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
      return await _plantationService.createManualTask(
        farmId: farmId,
        taskName: taskName,
        phase: phase,
        dueDate: dueDate,
        priority: priority,
        detailedSteps: detailedSteps,
        reasonWhy: reasonWhy,
      );
    } catch (e) {
      rethrow;
    }
  }

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
      return await _plantationService.updateTaskDetails(
        taskId: taskId,
        taskName: taskName,
        phase: phase,
        dueDate: dueDate,
        priority: priority,
        detailedSteps: detailedSteps,
        reasonWhy: reasonWhy,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<FarmTask> updateCompletionDetails({
    required String taskId,
    required List<InputItem> items,
    required double laborHours,
    String? notes,
  }) async {
    try {
      return await _plantationService.updateCompletionDetails(
        taskId: taskId,
        items: items,
        laborHours: laborHours,
        notes: notes,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _plantationService.deleteTask(taskId);
    } catch (e) {
      rethrow;
    }
  }
}

