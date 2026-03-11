import 'package:flutter/material.dart';

import '../models/farm_record_model.dart';
import '../models/farm_task_model.dart';
import '../services/plantation_service.dart';

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

class PlantationController extends ChangeNotifier {
  final PlantationService _plantationService;

  PlantationController(this._plantationService);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  FarmRecord? _currentFarm;
  FarmRecord? get currentFarm => _currentFarm;

  Future<FarmRecord> startPlantation({
    required String farmName,
    required String districtId,
    required String soilTypeId,
    required String chosenVarietyId,
    required DateTime farmStartDate,
    required double areaHectares,
    required int totalVines,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
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
      _currentFarm = farmRecord;
      return farmRecord;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<FarmRecord>> fetchFarms() async {
    return await _plantationService.getFarms();
  }

  Future<FarmRecord> fetchFarmById(String farmId) async {
    return await _plantationService.getFarmById(farmId);
  }

  // Alias for backward compatibility
  Future<FarmRecord> getFarmById(String farmId) async {
    return await fetchFarmById(farmId);
  }

  Future<List<FarmTask>> fetchTasksByFarmId(String farmId) async {
    return await _plantationService.getTasksByFarmId(farmId);
  }

  // Alias for backward compatibility
  Future<List<FarmTask>> getFarmTasks(String farmId) async {
    return await fetchTasksByFarmId(farmId);
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
