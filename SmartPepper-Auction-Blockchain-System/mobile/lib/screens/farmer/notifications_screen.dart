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
            .where((n) =>
                n.type.contains('auction') ||
                n.type == 'bid_update' ||
                n.type == 'bid_placed')
            .toList();
      case 'compliance':
        return _notifications.where((n) => n.type == 'compliance').toList();
      case 'payment':
        return _notifications
            .where((n) => n.type == 'payment' || n.type == 'payment_received')
            .toList();
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
      // Support both camelCase and snake_case field names
      final lotId = (notification.data!['lot_id'] ??
          notification.data!['lotId']) as String?;
      final auctionId = (notification.data!['auction_id'] ??
          notification.data!['auctionId']) as String?;
      final navigate = notification.data!['navigate'] as String?;

      if (navigate == 'auction_monitor' && auctionId != null) {
        context.push('/shared/auction-details/$auctionId');
      } else if (lotId != null) {
        context.push('/farmer/lot-details/$lotId');
      } else if (auctionId != null) {
        context.push('/shared/auction-details/$auctionId');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => n.isUnread).length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.forestGreen,
                AppTheme.forestGreen.withOpacity(0.8),
              ],
            ),
          ),
        ),
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.pepperGold,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.pepperGold.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _markAllAsRead,
                icon: const Icon(
                  Icons.done_all,
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text(
                  'Mark all read',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
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
    final count = _getFilterCount(value);

    IconData icon;
    switch (value) {
      case 'all':
        icon = Icons.grid_view;
        break;
      case 'unread':
        icon = Icons.mark_chat_unread;
        break;
      case 'auction':
        icon = Icons.gavel;
        break;
      case 'compliance':
        icon = Icons.verified_user;
        break;
      case 'payment':
        icon = Icons.payments;
        break;
      default:
        icon = Icons.notifications;
    }

    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppTheme.forestGreen,
                    AppTheme.forestGreen.withOpacity(0.8),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.grey[100],
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppTheme.forestGreen : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.forestGreen.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[800],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white
                      : AppTheme.pepperGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color:
                        isSelected ? AppTheme.forestGreen : AppTheme.pepperGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  int _getFilterCount(String filter) {
    switch (filter) {
      case 'unread':
        return _notifications.where((n) => n.isUnread).length;
      case 'auction':
        return _notifications
            .where((n) =>
                n.type.contains('auction') ||
                n.type == 'bid_update' ||
                n.type == 'bid_placed')
            .length;
      case 'compliance':
        return _notifications.where((n) => n.type == 'compliance').length;
      case 'payment':
        return _notifications
            .where((n) => n.type == 'payment' || n.type == 'payment_received')
            .length;
      default:
        return _notifications.length;
    }
  }

  Widget _buildNotificationCard(AppNotification notification) {
    final iconData = _getNotificationIconData(notification);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: notification.isUnread
                ? iconData.color.withOpacity(0.15)
                : Colors.black.withOpacity(0.05),
            blurRadius: notification.isUnread ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: notification.isUnread
              ? iconData.color.withOpacity(0.3)
              : Colors.grey.shade100,
          width: notification.isUnread ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _onNotificationTap(notification),
          child: Container(
            decoration: BoxDecoration(
              gradient: notification.isUnread
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        iconData.color.withOpacity(0.03),
                        Colors.white,
                      ],
                    )
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon with gradient background
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          iconData.color,
                          iconData.color.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: iconData.color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      iconData.icon,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Type badge and time
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: iconData.color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    iconData.categoryIcon,
                                    size: 12,
                                    color: iconData.color,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    iconData.category,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: iconData.color,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              timeago.format(notification.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Title
                        Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isUnread
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontSize: 16,
                            color: Colors.grey[900],
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Message
                        Text(
                          notification.message,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Amount or additional info
                        if (_extractAmount(notification) != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.pepperGold.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.pepperGold.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.attach_money,
                                  size: 16,
                                  color: AppTheme.pepperGold,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'LKR ${_extractAmount(notification)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.pepperGold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Unread indicator
                  if (notification.isUnread)
                    Container(
                      margin: const EdgeInsets.only(left: 8, top: 4),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            iconData.color,
                            iconData.color.withOpacity(0.7),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: iconData.color.withOpacity(0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _extractAmount(AppNotification notification) {
    final message = notification.message;
    final regex = RegExp(r'LKR\s+([\d,]+\.?\d*)');
    final match = regex.firstMatch(message);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }
    return null;
  }

  _NotificationIconData _getNotificationIconData(AppNotification notification) {
    switch (notification.type) {
      case 'bid_placed':
        return _NotificationIconData(
          icon: Icons.local_offer,
          color: const Color.fromARGB(255, 35, 112, 41), // Cyan
          category: 'NEW BID',
          categoryIcon: Icons.trending_up,
        );
      case 'auction_start':
        return _NotificationIconData(
          icon: Icons.gavel,
          color: const Color(0xFF3B82F6), // Blue
          category: 'STARTED',
          categoryIcon: Icons.play_arrow,
        );
      case 'auction_end':
      case 'auction_sold':
        return _NotificationIconData(
          icon: Icons.emoji_events,
          color: const Color(0xFF10B981), // Green
          category: 'SOLD',
          categoryIcon: Icons.check_circle,
        );
      case 'auction_won':
        return _NotificationIconData(
          icon: Icons.celebration,
          color: const Color(0xFFF59E0B), // Amber
          category: 'WON',
          categoryIcon: Icons.emoji_events,
        );
      case 'auction_no_sale':
        return _NotificationIconData(
          icon: Icons.cancel_outlined,
          color: const Color(0xFFEF4444), // Red
          category: 'NO SALE',
          categoryIcon: Icons.close,
        );
      case 'auction_settled':
        return _NotificationIconData(
          icon: Icons.verified,
          color: const Color(0xFF8B5CF6), // Purple
          category: 'SETTLED',
          categoryIcon: Icons.done_all,
        );
      case 'bid_update':
        return _NotificationIconData(
          icon: Icons.trending_up,
          color: const Color(0xFF14B8A6), // Teal
          category: 'BID UPDATE',
          categoryIcon: Icons.show_chart,
        );
      case 'compliance':
        final approved = notification.message.contains('approved');
        return _NotificationIconData(
          icon: approved ? Icons.verified_user : Icons.warning,
          color: approved ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          category: approved ? 'APPROVED' : 'REJECTED',
          categoryIcon: approved ? Icons.check_circle : Icons.error,
        );
      case 'payment':
      case 'payment_received':
        return _NotificationIconData(
          icon: Icons.account_balance_wallet,
          color: const Color(0xFF059669), // Emerald
          category: 'PAYMENT',
          categoryIcon: Icons.payment,
        );
      default:
        return _NotificationIconData(
          icon: Icons.notifications_active,
          color: AppTheme.forestGreen,
          category: 'UPDATE',
          categoryIcon: Icons.info,
        );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.forestGreen.withOpacity(0.1),
                  AppTheme.pepperGold.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _filter == 'unread'
                  ? Icons.check_circle_outline
                  : Icons.notifications_none_outlined,
              size: 60,
              color:
                  _filter == 'unread' ? AppTheme.forestGreen : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _filter == 'unread' ? 'All Caught Up! 🎉' : 'No Notifications Yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              _filter == 'unread'
                  ? 'You\'ve read all your notifications.\nGreat job staying updated!'
                  : 'We\'ll notify you when there\'s\nsomething new to show.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ),
          if (_filter != 'all' && _filter != 'unread') ...[
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => setState(() => _filter = 'all'),
              icon: const Icon(Icons.view_list),
              label: const Text('View All Notifications'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.forestGreen,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Helper class for notification icon data
class _NotificationIconData {
  final IconData icon;
  final Color color;
  final String category;
  final IconData categoryIcon;

  _NotificationIconData({
    required this.icon,
    required this.color,
    required this.category,
    required this.categoryIcon,
  });
}
