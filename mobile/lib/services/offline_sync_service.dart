import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart';
import 'storage_service.dart';
import 'api_service.dart';

/// Service for offline data management and synchronization
/// Allows farmers to enter lot data offline and sync when connection is available
class OfflineSyncService {
  final StorageService _storageService;
  final ApiService _apiService;
  final Connectivity _connectivity;

  static const String _pendingLotsKey = 'pending_lots';
  static const String _pendingUpdatesKey = 'pending_updates';
  static const String _lastSyncKey = 'last_sync_timestamp';

  bool _isSyncing = false;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  final _syncStatusController = StreamController<SyncStatus>.broadcast();

  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  OfflineSyncService({
    required StorageService storageService,
    required ApiService apiService,
  })  : _storageService = storageService,
        _apiService = apiService,
        _connectivity = Connectivity();

  /// Initialize offline sync service
  Future<void> initialize() async {
    // Monitor connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) {
        if (result != ConnectivityResult.none && !_isSyncing) {
          syncPendingData();
        }
      },
    );

    // Attempt initial sync if online
    final isOnline = await checkConnectivity();
    if (isOnline) {
      await syncPendingData();
    }
  }

  /// Check if device is online
  Future<bool> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  /// Save lot data for offline creation
  Future<void> savePendingLot(Map<String, dynamic> lotData) async {
    try {
      final pendingLots = await _getPendingLots();

      // Add timestamp and unique ID
      lotData['offlineId'] = DateTime.now().millisecondsSinceEpoch.toString();
      lotData['createdOffline'] = true;
      lotData['offlineTimestamp'] = DateTime.now().toIso8601String();

      pendingLots.add(lotData);
      await _savePendingLots(pendingLots);

      _syncStatusController.add(SyncStatus(
        type: SyncType.lotAdded,
        pendingCount: pendingLots.length,
        message: 'Lot saved offline. Will sync when online.',
      ));
    } catch (e) {
      throw Exception('Failed to save lot offline: $e');
    }
  }

  /// Save pending update for existing lot
  Future<void> savePendingUpdate({
    required String lotId,
    required Map<String, dynamic> updateData,
  }) async {
    try {
      final pendingUpdates = await _getPendingUpdates();

      pendingUpdates.add({
        'lotId': lotId,
        'updateData': updateData,
        'timestamp': DateTime.now().toIso8601String(),
      });

      await _savePendingUpdates(pendingUpdates);

      _syncStatusController.add(SyncStatus(
        type: SyncType.updateAdded,
        pendingCount: pendingUpdates.length,
        message: 'Update saved offline. Will sync when online.',
      ));
    } catch (e) {
      throw Exception('Failed to save update offline: $e');
    }
  }

  /// Get count of pending items to sync
  Future<int> getPendingCount() async {
    final lots = await _getPendingLots();
    final updates = await _getPendingUpdates();
    return lots.length + updates.length;
  }

  /// Sync all pending data with server
  Future<SyncResult> syncPendingData() async {
    if (_isSyncing) {
      return SyncResult(
        success: false,
        message: 'Sync already in progress',
      );
    }

    _isSyncing = true;
    _syncStatusController.add(SyncStatus(
      type: SyncType.syncing,
      message: 'Syncing data...',
    ));

    int successCount = 0;
    int failureCount = 0;
    final errors = <String>[];

    try {
      // Check connectivity
      final isOnline = await checkConnectivity();
      if (!isOnline) {
        throw Exception('No internet connection');
      }

      // Sync pending lots
      final pendingLots = await _getPendingLots();
      for (var i = 0; i < pendingLots.length; i++) {
        try {
          final lot = pendingLots[i];
          await _apiService.post('/lots', lot);
          successCount++;

          // Remove from pending
          pendingLots.removeAt(i);
          i--;
        } catch (e) {
          failureCount++;
          errors.add('Failed to sync lot: $e');
        }
      }
      await _savePendingLots(pendingLots);

      // Sync pending updates
      final pendingUpdates = await _getPendingUpdates();
      for (var i = 0; i < pendingUpdates.length; i++) {
        try {
          final update = pendingUpdates[i];
          await _apiService.patch(
            '/lots/${update['lotId']}',
            update['updateData'],
          );
          successCount++;

          // Remove from pending
          pendingUpdates.removeAt(i);
          i--;
        } catch (e) {
          failureCount++;
          errors.add('Failed to sync update: $e');
        }
      }
      await _savePendingUpdates(pendingUpdates);

      // Update last sync timestamp
      await _storageService.saveString(
        _lastSyncKey,
        DateTime.now().toIso8601String(),
      );

      _syncStatusController.add(SyncStatus(
        type: SyncType.completed,
        pendingCount: 0,
        message: 'Sync completed successfully',
      ));

      return SyncResult(
        success: failureCount == 0,
        syncedCount: successCount,
        failedCount: failureCount,
        errors: errors,
        message: failureCount == 0
            ? 'All data synced successfully'
            : 'Some items failed to sync',
      );
    } catch (e) {
      _syncStatusController.add(SyncStatus(
        type: SyncType.failed,
        message: 'Sync failed: $e',
      ));

      return SyncResult(
        success: false,
        message: 'Sync failed: $e',
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    final timestamp = await _storageService.getString(_lastSyncKey);
    if (timestamp == null) return null;

    try {
      return DateTime.parse(timestamp);
    } catch (e) {
      return null;
    }
  }

  /// Clear all pending data (use with caution)
  Future<void> clearPendingData() async {
    await _storageService.remove(_pendingLotsKey);
    await _storageService.remove(_pendingUpdatesKey);

    _syncStatusController.add(SyncStatus(
      type: SyncType.cleared,
      pendingCount: 0,
      message: 'Pending data cleared',
    ));
  }

  // Private helper methods

  Future<List<Map<String, dynamic>>> _getPendingLots() async {
    try {
      final jsonString = await _storageService.getString(_pendingLotsKey);
      if (jsonString == null) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString) as List;
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future<void> _savePendingLots(List<Map<String, dynamic>> lots) async {
    await _storageService.saveString(_pendingLotsKey, jsonEncode(lots));
  }

  Future<List<Map<String, dynamic>>> _getPendingUpdates() async {
    try {
      final jsonString = await _storageService.getString(_pendingUpdatesKey);
      if (jsonString == null) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString) as List;
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future<void> _savePendingUpdates(List<Map<String, dynamic>> updates) async {
    await _storageService.saveString(_pendingUpdatesKey, jsonEncode(updates));
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _syncStatusController.close();
  }
}

/// Sync status for real-time updates
class SyncStatus {
  final SyncType type;
  final int pendingCount;
  final String message;

  SyncStatus({
    required this.type,
    this.pendingCount = 0,
    required this.message,
  });
}

/// Types of sync operations
enum SyncType {
  lotAdded,
  updateAdded,
  syncing,
  completed,
  failed,
  cleared,
}

/// Result of sync operation
class SyncResult {
  final bool success;
  final int syncedCount;
  final int failedCount;
  final List<String> errors;
  final String message;

  SyncResult({
    required this.success,
    this.syncedCount = 0,
    this.failedCount = 0,
    this.errors = const [],
    required this.message,
  });
}
