import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session_model.dart';
import '../services/session_service.dart';
import '../../../../core/network/api_client.dart';

final sessionServiceProvider = Provider<SessionService>((ref) {
  return SessionService(ApiClient());
});

final sessionsProvider = FutureProvider.family<List<SessionModel>, String>((ref, seasonId) async {
  final service = ref.read(sessionServiceProvider);
  return await service.getSessionsBySeasonId(seasonId);
});

final sessionProvider = FutureProvider.family<SessionModel, String>((ref, sessionId) async {
  final service = ref.read(sessionServiceProvider);
  return await service.getSessionById(sessionId);
});

final sessionControllerProvider = StateNotifierProvider.family<SessionController, AsyncValue<List<SessionModel>>, String>((ref, seasonId) {
  return SessionController(ref.read(sessionServiceProvider), seasonId, ref);
});

class SessionController extends StateNotifier<AsyncValue<List<SessionModel>>> {
  final SessionService _sessionService;
  final String _seasonId;
  final Ref _ref;

  SessionController(this._sessionService, this._seasonId, this._ref) : super(const AsyncValue.loading()) {
    fetchSessions();
  }

  Future<void> fetchSessions() async {
    state = const AsyncValue.loading();
    try {
      final sessions = await _sessionService.getSessionsBySeasonId(_seasonId);
      state = AsyncValue.data(sessions);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<SessionModel> createSession({
    required String sessionName,
    required DateTime date,
    required double yieldKg,
    required double areaHarvested,
    String? notes,
  }) async {
    try {
      final session = await _sessionService.createSession(
        seasonId: _seasonId,
        sessionName: sessionName,
        date: date,
        yieldKg: yieldKg,
        areaHarvested: areaHarvested,
        notes: notes,
      );
      
      // Refresh the list
      if (state.hasValue) {
        final currentSessions = state.value ?? [];
        state = AsyncValue.data([...currentSessions, session]);
      } else {
        await fetchSessions();
      }
      
      return session;
    } catch (e) {
      rethrow;
    }
  }

  Future<SessionModel> updateSession({
    required String sessionId,
    String? sessionName,
    DateTime? date,
    double? yieldKg,
    double? areaHarvested,
    String? notes,
  }) async {
    try {
      final updatedSession = await _sessionService.updateSession(
        sessionId: sessionId,
        sessionName: sessionName,
        date: date,
        yieldKg: yieldKg,
        areaHarvested: areaHarvested,
        notes: notes,
      );
      
      // Refresh the list
      if (state.hasValue) {
        final currentSessions = state.value ?? [];
        final index = currentSessions.indexWhere((s) => s.id == sessionId);
        if (index != -1) {
          currentSessions[index] = updatedSession;
          state = AsyncValue.data([...currentSessions]);
        }
      }

      // Invalidate the specific session provider to ensure EditSessionPage gets fresh data
      _ref.invalidate(sessionProvider(sessionId));
      
      return updatedSession;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      await _sessionService.deleteSession(sessionId);
      
      // Refresh the list
      if (state.hasValue) {
        final currentSessions = state.value ?? [];
        state = AsyncValue.data(currentSessions.where((s) => s.id != sessionId).toList());
      }

      // Invalidate the specific session provider
      _ref.invalidate(sessionProvider(sessionId));
    } catch (e) {
      rethrow;
    }
  }
}

