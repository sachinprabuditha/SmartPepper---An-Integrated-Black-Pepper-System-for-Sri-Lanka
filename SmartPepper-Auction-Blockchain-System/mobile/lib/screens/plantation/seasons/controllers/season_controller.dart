import 'package:flutter/foundation.dart';
import '../models/season_model.dart';
import '../services/season_service.dart';

class SeasonController extends ChangeNotifier {
  final SeasonService _seasonService;

  List<SeasonModel> _seasons = [];
  bool _isLoading = false;
  String? _error;

  SeasonController(this._seasonService);

  List<SeasonModel> get seasons => _seasons;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchSeasons(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _seasons = await _seasonService.getSeasonsByUserId(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
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

      _seasons.add(season);
      notifyListeners();

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

      final index = _seasons.indexWhere((s) => s.id == seasonId);
      if (index != -1) {
        _seasons[index] = updatedSeason;
        notifyListeners();
      }

      return updatedSeason;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteSeason(String seasonId) async {
    try {
      await _seasonService.deleteSeason(seasonId);

      _seasons.removeWhere((s) => s.id == seasonId);
      notifyListeners();
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
      final index = _seasons.indexWhere((s) => s.id == seasonId);
      if (index != -1) {
        // Just notify listeners to trigger a rebuild
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }
}
