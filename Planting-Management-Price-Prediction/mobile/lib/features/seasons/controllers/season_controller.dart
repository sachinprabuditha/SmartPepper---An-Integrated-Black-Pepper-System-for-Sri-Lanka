import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/season_model.dart';
import '../services/season_service.dart';
import '../../../../core/network/api_client.dart';

final seasonServiceProvider = Provider<SeasonService>((ref) {
  return SeasonService(ApiClient());
});

final seasonsProvider = FutureProvider.family<List<SeasonModel>, String>((ref, userId) async {
  final service = ref.read(seasonServiceProvider);
  return await service.getSeasonsByUserId(userId);
});

final seasonsByFarmProvider = FutureProvider.family<List<SeasonModel>, String>((ref, farmId) async {
  final service = ref.read(seasonServiceProvider);
  return await service.getSeasonsByFarmId(farmId);
});

final seasonProvider = FutureProvider.family<SeasonModel, String>((ref, seasonId) async {
  final service = ref.read(seasonServiceProvider);
  return await service.getSeasonById(seasonId);
});

final seasonControllerProvider = StateNotifierProvider<SeasonController, AsyncValue<List<SeasonModel>>>((ref) {
  return SeasonController(ref.read(seasonServiceProvider));
});

class SeasonController extends StateNotifier<AsyncValue<List<SeasonModel>>> {
  final SeasonService _seasonService;

  SeasonController(this._seasonService) : super(const AsyncValue.data([]));

  Future<void> fetchSeasons(String userId) async {
    state = const AsyncValue.loading();
    try {
      final seasons = await _seasonService.getSeasonsByUserId(userId);
      state = AsyncValue.data(seasons);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<SeasonModel> createSeason({
    required String seasonName,
    required int startMonth,
    required int startYear,
    required int endMonth,
    required int endYear,
    required String farmId,
    required String createdBy,
  }) async {
    try {
      final season = await _seasonService.createSeason(
        seasonName: seasonName,
        startMonth: startMonth,
        startYear: startYear,
        endMonth: endMonth,
        endYear: endYear,
        farmId: farmId,
        createdBy: createdBy,
      );
      
      // Refresh the list
      if (state.hasValue) {
        final currentSeasons = state.value ?? [];
        state = AsyncValue.data([...currentSeasons, season]);
      }
      
      return season;
    } catch (e) {
      rethrow;
    }
  }

  Future<SeasonModel> updateSeason({
    required String seasonId,
    String? seasonName,
    int? startMonth,
    int? startYear,
    int? endMonth,
    int? endYear,
    String? farmId,
  }) async {
    try {
      final updatedSeason = await _seasonService.updateSeason(
        seasonId: seasonId,
        seasonName: seasonName,
        startMonth: startMonth,
        startYear: startYear,
        endMonth: endMonth,
        endYear: endYear,
        farmId: farmId,
      );
      
      // Refresh the list
      if (state.hasValue) {
        final currentSeasons = state.value ?? [];
        final index = currentSeasons.indexWhere((s) => s.id == seasonId);
        if (index != -1) {
          currentSeasons[index] = updatedSeason;
          state = AsyncValue.data([...currentSeasons]);
        }
      }
      
      return updatedSeason;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteSeason(String seasonId, String userId) async {
    try {
      await _seasonService.deleteSeason(seasonId);
      
      // Refresh the list
      if (state.hasValue) {
        final currentSeasons = state.value ?? [];
        state = AsyncValue.data(currentSeasons.where((s) => s.id != seasonId).toList());
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> endSeason(String seasonId) async {
    try {
      await _seasonService.endSeason(seasonId);
      
      // We don't necessarily need to refresh the list here if we are on the details page, 
      // but it's good practice to ensure list consistency if we go back.
      // The details page should invalidate itself.
      if (state.hasValue) {
        final currentSeasons = state.value ?? [];
        final index = currentSeasons.indexWhere((s) => s.id == seasonId);
        if (index != -1) {
          // We might not have the full updated object, but we know the status changed.
          // Ideally we fetch the updated season or manually update the status in the local object.
          // For simplicity, we can trust the details page reload or just let the list refresh next time.
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}

