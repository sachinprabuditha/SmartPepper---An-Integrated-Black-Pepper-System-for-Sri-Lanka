import '../models/farm_record_model.dart';
import '../models/farm_task_model.dart';
import '../services/plantation_service.dart';
import '../../agronomy/services/agronomy_service.dart';
import '../../agronomy/models/district_model.dart';
import '../../agronomy/models/soil_type_model.dart';
import '../../agronomy/models/variety_model.dart';
import '../../services/plantation_api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final plantationApiClientProvider = Provider<PlantationApiClient>((ref) {
  return PlantationApiClient();
});

final plantationServiceProvider = Provider<PlantationService>((ref) {
  return PlantationService(ref.read(plantationApiClientProvider));
});

final agronomyServiceProvider = Provider<AgronomyService>((ref) {
  return AgronomyService();
});

final allDistrictsProvider = FutureProvider<List<District>>((ref) async {
  final service = ref.read(agronomyServiceProvider);
  return await service.fetchAllDistricts();
});

final soilsByDistrictProvider = FutureProvider.family<List<SoilType>, String>((ref, districtId) async {
  final service = ref.read(agronomyServiceProvider);
  return await service.fetchSoilsByDistrict(districtId);
});

final varietiesByDistrictAndSoilProvider = FutureProvider.family<List<BlackPepperVariety>, DistrictSoilKey>((ref, key) async {
  final service = ref.read(agronomyServiceProvider);
  return await service.fetchVarietiesByDistrictAndSoil(key.districtId, key.soilTypeId);
});

class DistrictSoilKey {
  final String districtId;
  final String soilTypeId;

  const DistrictSoilKey(this.districtId, this.soilTypeId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DistrictSoilKey &&
          runtimeType == other.runtimeType &&
          districtId == other.districtId &&
          soilTypeId == other.soilTypeId;

  @override
  int get hashCode => districtId.hashCode ^ soilTypeId.hashCode;
}

final farmsProvider = FutureProvider<List<FarmRecord>>((ref) async {
  final service = ref.read(plantationServiceProvider);
  return await service.getFarms();
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
    required String districtId,
    required String soilTypeId,
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
    return await _plantationService.getFarms();
  }

  Future<FarmRecord> fetchFarmById(String farmId) async {
    return await _plantationService.getFarmById(farmId);
  }

  Future<List<FarmTask>> fetchTasksByFarmId(String farmId) async {
    return await _plantationService.getTasksByFarmId(farmId);
  }

  Future<FarmRecord> updateFarm({
    required String farmId,
    String? farmName,
    String? districtId,
    String? soilTypeId,
    String? chosenVarietyId,
    DateTime? farmStartDate,
    double? areaHectares,
    int? totalVines,
  }) async {
    return await _plantationService.updateFarm(
      farmId: farmId,
      farmName: farmName,
      districtId: districtId,
      soilTypeId: soilTypeId,
      chosenVarietyId: chosenVarietyId,
      farmStartDate: farmStartDate,
      areaHectares: areaHectares,
      totalVines: totalVines,
    );
  }

  Future<void> deleteFarm(String farmId) async {
    await _plantationService.deleteFarm(farmId);
  }

  Future<FarmTask> completeTask({
    required String taskId,
    required List<InputItem> items,
    required double laborHours,
    String? notes,
  }) async {
    return await _plantationService.completeTask(
      taskId: taskId,
      items: items,
      laborHours: laborHours,
      notes: notes,
    );
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
    return await _plantationService.createManualTask(
      farmId: farmId,
      taskName: taskName,
      phase: phase,
      dueDate: dueDate,
      priority: priority,
      detailedSteps: detailedSteps,
      reasonWhy: reasonWhy,
    );
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
    return await _plantationService.updateTaskDetails(
      taskId: taskId,
      taskName: taskName,
      phase: phase,
      dueDate: dueDate,
      priority: priority,
      detailedSteps: detailedSteps,
      reasonWhy: reasonWhy,
    );
  }

  Future<FarmTask> updateCompletionDetails({
    required String taskId,
    required List<InputItem> items,
    required double laborHours,
    String? notes,
  }) async {
    return await _plantationService.updateCompletionDetails(
      taskId: taskId,
      items: items,
      laborHours: laborHours,
      notes: notes,
    );
  }

  Future<void> deleteTask(String taskId) async {
    await _plantationService.deleteTask(taskId);
  }
}
