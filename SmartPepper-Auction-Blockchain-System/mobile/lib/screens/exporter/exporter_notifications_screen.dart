import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';
import '../../config/theme.dart';

class ExporterNotificationsScreen extends StatefulWidget {
  const ExporterNotificationsScreen({super.key});

  @override
  State<ExporterNotificationsScreen> createState() =>
      _ExporterNotificationsScreenState();
}

class _ExporterNotificationsScreenState
    extends State<ExporterNotificationsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];
  String? _errorMessage;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final notificationService = context.read<NotificationService>();
      final notifications = await notificationService.fetchNotifications();

      setState(() {
        _notifications = notifications
            .map((n) => {
                  'id': n.id,
                  'type': n.type,
                  'title': n.title,
                  'body': n.message,
                  'read': n.read,
                  'created_at': n.createdAt.toIso8601String(),
                  'auction_id': n.data?['auctionId'],
                })
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredNotifications {
    if (_selectedFilter == 'all') {
      return _notifications;
    } else if (_selectedFilter == 'unread') {
      return _notifications.where((n) => n['read'] == false).toList();
    } else if (_selectedFilter == 'read') {
      return _notifications.where((n) => n['read'] == true).toList();
    }
    return _notifications.where((n) => n['type'] == _selectedFilter).toList();
  }

  int get _unreadCount {
    return _notifications.where((n) => n['read'] == false).length;
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      final notificationService = context.read<NotificationService>();
      await notificationService.markAsRead(notificationId);

      setState(() {
        final index =
            _notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          _notifications[index]['read'] = true;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark as read: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final notificationService = context.read<NotificationService>();
      await notificationService.markAllAsRead();

      setState(() {
        for (var notification in _notifications) {
          notification['read'] = true;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark all as read: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      // Note: deleteNotification method not yet implemented in NotificationService
      // For now, just remove from local list
      setState(() {
        _notifications.removeWhere((n) => n['id'] == notificationId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification removed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove notification: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'bid_placed':
        return Icons.gavel;
      case 'bid_outbid':
        return Icons.trending_down;
      case 'auction_won':
        return Icons.emoji_events;
      case 'auction_ending':
        return Icons.timer;
      case 'auction_ended':
        return Icons.event_available;
      case 'payment_reminder':
        return Icons.payment;
      case 'payment_confirmed':
        return Icons.check_circle;
      case 'delivery_update':
        return Icons.local_shipping;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'bid_placed':
        return Colors.blue;
      case 'bid_outbid':
        return Colors.orange;
      case 'auction_won':
        return Colors.green;
      case 'auction_ending':
        return Colors.purple;
      case 'auction_ended':
        return Colors.grey;
      case 'payment_reminder':
        return Colors.red;
      case 'payment_confirmed':
        return Colors.teal;
      case 'delivery_update':
        return Colors.indigo;
      case 'system':
        return Colors.blueGrey;
      default:
        return AppTheme.forestGreen;
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    // Mark as read
    if (!notification['read']) {
      _markAsRead(notification['id']);
    }

    // Navigate based on notification type
    final auctionId = notification['auction_id'];

    if (auctionId != null) {
      context.push('/exporter/auction/$auctionId');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppTheme.forestGreen,
        actions: [
          if (_unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Mark all as read',
              onPressed: _markAllAsRead,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All', _notifications.length),
                  _buildFilterChip('unread', 'Unread', _unreadCount),
                  _buildFilterChip(
                      'bid_outbid',
                      'Outbid',
                      _notifications
                          .where((n) => n['type'] == 'bid_outbid')
                          .length),
                  _buildFilterChip(
                      'auction_won',
                      'Won',
                      _notifications
                          .where((n) => n['type'] == 'auction_won')
                          .length),
                  _buildFilterChip(
                      'payment_reminder',
                      'Payment',
                      _notifications
                          .where((n) => n['type'] == 'payment_reminder')
                          .length),
                  _buildFilterChip(
                      'system',
                      'System',
                      _notifications
                          .where((n) => n['type'] == 'system')
                          .length),
                ],
              ),
            ),
          ),

          // Notifications List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 64, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadNotifications,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _filteredNotifications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.notifications_none,
                                    size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  _selectedFilter == 'all'
                                      ? 'No notifications yet'
                                      : 'No $_selectedFilter notifications',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'You\'ll receive updates here',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadNotifications,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredNotifications.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final notification =
                                    _filteredNotifications[index];
                                return _buildNotificationCard(notification);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, int count) {
    final isSelected = _selectedFilter == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text('$label ($count)'),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
          });
        },
        backgroundColor: Colors.white,
        selectedColor: AppTheme.forestGreen.withOpacity(0.2),
        checkmarkColor: AppTheme.forestGreen,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.forestGreen : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['read'] == true;
    final type = notification['type'] ?? 'system';
    final icon = _getNotificationIcon(type);
    final color = _getNotificationColor(type);
    final timestamp = notification['created_at'];

    return Dismissible(
      key: Key(notification['id'] ?? ''),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _deleteNotification(notification['id']);
      },
      child: Card(
        elevation: isRead ? 0 : 2,
        color: isRead ? Colors.grey[100] : Colors.white,
        child: InkWell(
          onTap: () => _handleNotificationTap(notification),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),

                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              notification['title'] ?? 'Notification',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification['body'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTimestamp(timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),

                // More Menu
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'read') {
                      _markAsRead(notification['id']);
                    } else if (value == 'delete') {
                      _deleteNotification(notification['id']);
                    }
                  },
                  itemBuilder: (context) => [
                    if (!isRead)
                      const PopupMenuItem(
                        value: 'read',
                        child: Row(
                          children: [
                            Icon(Icons.done, size: 20),
                            SizedBox(width: 8),
                            Text('Mark as read'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return DateFormat('MMM d, yyyy').format(dateTime);
      }
    } catch (e) {
      return 'Invalid date';
    }
  }
}
