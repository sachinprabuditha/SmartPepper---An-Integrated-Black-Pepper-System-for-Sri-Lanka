import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/notification.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// Service for managing in-app and push notifications
class NotificationService {
  final ApiService _apiService;
  final StorageService _storageService;
  final FlutterLocalNotificationsPlugin _localNotifications;

  static const String _notificationsKey = 'cached_notifications';
  static const String _unreadCountKey = 'unread_notification_count';

  NotificationService({
    required ApiService apiService,
    required StorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService,
        _localNotifications = FlutterLocalNotificationsPlugin();

  /// Initialize notification service
  Future<void> initialize() async {
    // Request notification permissions
    await _requestPermissions();

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Request notification permissions
  Future<bool> _requestPermissions() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // TODO: Navigate to appropriate screen based on notification data
    print('Notification tapped: ${response.payload}');
  }

  /// Fetch notifications from server
  Future<List<AppNotification>> fetchNotifications() async {
    try {
      final response = await _apiService.get('/notifications');
      final List<dynamic> data = response['notifications'] as List;
      final notifications = data.map((json) => AppNotification.fromJson(json)).toList();

      // Cache notifications locally
      await _cacheNotifications(notifications);

      return notifications;
    } catch (e) {
      // Return cached notifications if network fails
      return await _getCachedNotifications();
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final notifications = await fetchNotifications();
      final count = notifications.where((n) => n.isUnread).length;
      await _storageService.saveInt(_unreadCountKey, count);
      return count;
    } catch (e) {
      // Return cached count if network fails
      return await _storageService.getInt(_unreadCountKey) ?? 0;
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _apiService.patch('/notifications/$notificationId/read', {});
      
      // Update cached notifications
      final cached = await _getCachedNotifications();
      final updated = cached.map((n) {
        if (n.id == notificationId) {
          return AppNotification.fromJson({
            ...n.toJson(),
            'read': true,
            'readAt': DateTime.now().toIso8601String(),
          });
        }
        return n;
      }).toList();
      await _cacheNotifications(updated);

      return true;
    } catch (e) {
      print('Failed to mark notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      await _apiService.patch('/notifications/read-all', {});
      
      // Update cached notifications
      final cached = await _getCachedNotifications();
      final updated = cached.map((n) {
        return AppNotification.fromJson({
          ...n.toJson(),
          'read': true,
          'readAt': DateTime.now().toIso8601String(),
        });
      }).toList();
      await _cacheNotifications(updated);

      return true;
    } catch (e) {
      print('Failed to mark all notifications as read: $e');
      return false;
    }
  }

  /// Show local notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    NotificationPriority priority = NotificationPriority.defaultPriority,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'smartpepper_channel',
      'SmartPepper Notifications',
      channelDescription: 'Notifications for SmartPepper app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Show auction start notification
  Future<void> notifyAuctionStart({
    required String lotId,
    required String variety,
    required double startingPrice,
    required DateTime endTime,
  }) async {
    await showLocalNotification(
      title: '🎯 Auction Started!',
      body: 'Your $variety lot is now live. Starting at LKR $startingPrice',
      payload: jsonEncode({'type': 'auction_start', 'lotId': lotId}),
      priority: NotificationPriority.high,
    );
  }

  /// Show bid update notification
  Future<void> notifyBidUpdate({
    required String lotId,
    required double newBid,
    required int bidderCount,
  }) async {
    await showLocalNotification(
      title: '💰 New Bid Received!',
      body: 'Current bid: LKR $newBid from $bidderCount bidders',
      payload: jsonEncode({'type': 'bid_update', 'lotId': lotId}),
      priority: NotificationPriority.high,
    );
  }

  /// Show auction end notification
  Future<void> notifyAuctionEnd({
    required String lotId,
    required double finalPrice,
    required String? winnerName,
  }) async {
    await showLocalNotification(
      title: '🏆 Auction Ended!',
      body: winnerName != null
          ? 'Sold to $winnerName for LKR $finalPrice'
          : 'Auction ended. No winning bid.',
      payload: jsonEncode({'type': 'auction_end', 'lotId': lotId}),
      priority: NotificationPriority.max,
    );
  }

  /// Show compliance notification
  Future<void> notifyCompliance({
    required String lotId,
    required bool approved,
    String? message,
  }) async {
    await showLocalNotification(
      title: approved ? '✅ Lot Approved' : '❌ Lot Rejected',
      body: message ?? (approved 
          ? 'Your lot has been approved for auction'
          : 'Your lot did not meet compliance requirements'),
      payload: jsonEncode({'type': 'compliance', 'lotId': lotId}),
      priority: NotificationPriority.high,
    );
  }

  /// Show payment notification
  Future<void> notifyPayment({
    required String lotId,
    required double amount,
  }) async {
    await showLocalNotification(
      title: '💵 Payment Released!',
      body: 'You received LKR $amount for your pepper lot',
      payload: jsonEncode({'type': 'payment', 'lotId': lotId}),
      priority: NotificationPriority.max,
    );
  }

  /// Cache notifications locally
  Future<void> _cacheNotifications(List<AppNotification> notifications) async {
    final jsonList = notifications.map((n) => n.toJson()).toList();
    await _storageService.saveString(_notificationsKey, jsonEncode(jsonList));
  }

  /// Get cached notifications
  Future<List<AppNotification>> _getCachedNotifications() async {
    try {
      final jsonString = await _storageService.getString(_notificationsKey);
      if (jsonString == null) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => AppNotification.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Clear all notifications
  Future<void> clearNotifications() async {
    await _localNotifications.cancelAll();
    await _storageService.remove(_notificationsKey);
    await _storageService.remove(_unreadCountKey);
  }
}

enum NotificationPriority {
  min,
  low,
  defaultPriority,
  high,
  max,
}
