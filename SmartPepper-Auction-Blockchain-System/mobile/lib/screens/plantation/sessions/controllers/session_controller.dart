import 'package:flutter/foundation.dart';
import '../models/session_model.dart';
import '../services/session_service.dart';

class SessionController extends ChangeNotifier {
  final SessionService _sessionService;

  List<SessionModel> _sessions = [];
  bool _isLoading = false;
  String? _error;

  SessionController(this._sessionService);

  List<SessionModel> get sessions => _sessions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchSessions(String seasonId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sessions = await _sessionService.getSessionsBySeasonId(seasonId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SessionModel> createSession({
    required String seasonId,
    required String sessionName,
    required DateTime date,
    required double yieldKg,
    required double areaHarvested,
    String? notes,
  }) async {
    try {
      final session = await _sessionService.createSession(
        seasonId: seasonId,
        sessionName: sessionName,
        date: date,
        yieldKg: yieldKg,
        areaHarvested: areaHarvested,
        notes: notes,
      );

      _sessions.add(session);
      notifyListeners();

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

      final index = _sessions.indexWhere((s) => s.id == sessionId);
      if (index != -1) {
        _sessions[index] = updatedSession;
        notifyListeners();
      }

      return updatedSession;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      await _sessionService.deleteSession(sessionId);

      _sessions.removeWhere((s) => s.id == sessionId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
