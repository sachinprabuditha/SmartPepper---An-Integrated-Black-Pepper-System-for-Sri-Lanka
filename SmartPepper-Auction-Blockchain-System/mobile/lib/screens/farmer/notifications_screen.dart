import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/notification.dart';
import '../../services/notification_service.dart';
import '../../config/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, unread, auction, compliance, payment

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      final notificationService = context.read<NotificationService>();
      final notifications = await notificationService.fetchNotifications();

      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<AppNotification> get _filteredNotifications {
    switch (_filter) {
      case 'unread':
        return _notifications.where((n) => n.isUnread).toList();
      case 'auction':
        return _notifications
            .where((n) => n.type.contains('auction') || n.type == 'bid_update')
            .toList();
      case 'compliance':
        return _notifications.where((n) => n.type == 'compliance').toList();
      case 'payment':
        return _notifications.where((n) => n.type == 'payment').toList();
      default:
        return _notifications;
    }
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.read) return;

    final notificationService = context.read<NotificationService>();
    await notificationService.markAsRead(notification.id);
    await _loadNotifications();
  }

  Future<void> _markAllAsRead() async {
    final notificationService = context.read<NotificationService>();
    final success = await notificationService.markAllAsRead();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadNotifications();
    }
  }

  void _onNotificationTap(AppNotification notification) {
    _markAsRead(notification);

    // Navigate based on notification type
    if (notification.data != null) {
      final lotId = notification.data!['lotId'] as String?;
      final auctionId = notification.data!['auctionId'] as String?;

      if (lotId != null) {
        context.push('/farmer/lot-details/$lotId');
      } else if (auctionId != null) {
        context.push('/shared/auction-details/$auctionId');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppTheme.forestGreen,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_notifications.any((n) => n.isUnread))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(color: AppTheme.pepperGold),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Unread', 'unread'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Auction', 'auction'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Compliance', 'compliance'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Payment', 'payment'),
                ],
              ),
            ),
          ),

          // Notifications list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredNotifications.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadNotifications,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredNotifications.length,
                          itemBuilder: (context, index) {
                            final notification = _filteredNotifications[index];
                            return _buildNotificationCard(notification);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.forestGreen : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isUnread ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isUnread
              ? Colors.blue.shade200
              : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _buildNotificationIcon(notification),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight:
                notification.isUnread ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification.message),
            const SizedBox(height: 8),
            Text(
              timeago.format(notification.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: notification.isUnread
            ? Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () => _onNotificationTap(notification),
      ),
    );
  }

  Widget _buildNotificationIcon(AppNotification notification) {
    IconData icon;
    Color color;

    switch (notification.type) {
      case 'auction_start':
        icon = Icons.gavel;
        color = Colors.blue;
        break;
      case 'auction_end':
        icon = Icons.emoji_events;
        color = Colors.amber;
        break;
      case 'bid_update':
        icon = Icons.trending_up;
        color = Colors.green;
        break;
      case 'compliance':
        icon = notification.message.contains('approved')
            ? Icons.check_circle
            : Icons.cancel;
        color = notification.message.contains('approved')
            ? Colors.green
            : Colors.red;
        break;
      case 'payment':
        icon = Icons.payments;
        color = Colors.green;
        break;
      default:
        icon = Icons.notifications;
        color = AppTheme.forestGreen;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _filter == 'unread'
                ? 'You\'re all caught up!'
                : 'Check back later for updates',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
