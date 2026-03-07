import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../services/notification_service.dart';
import '../../services/api_service.dart';

class ExporterDashboard extends StatefulWidget {
  const ExporterDashboard({super.key});

  @override
  State<ExporterDashboard> createState() => _ExporterDashboardState();
}

class _ExporterDashboardState extends State<ExporterDashboard> {
  int _unreadNotifications = 0;
  int _activeBids = 0;
  int _wonAuctions = 0;
  int _participatedAuctions = 0;
  double _totalSpent = 0.0;
  List<Map<String, dynamic>> _recentActivities = [];
  bool _isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationCount();
    _loadStatistics();
    _loadRecentActivities();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoadingStats = true);
    try {
      final apiService = context.read<ApiService>();
      final authProvider = context.read<AuthProvider>();

      // Get current user's ID to filter their bids only
      final exporterId = authProvider.user?.id;

      if (exporterId != null) {
        final response = await apiService.getUserBids(exporterId);
        final auctions = response['auctions'] as List? ?? [];

        if (mounted) {
          setState(() {
            // Active bids - bids in active auctions
            _activeBids = auctions
                .where((auction) => auction['status'] == 'active')
                .length;

            // Won auctions - ended or settled + leading
            _wonAuctions = auctions.where((auction) {
              final status = auction['status'];
              final isLeading = auction['is_leading'] ?? false;
              return (status == 'ended' || status == 'settled') && isLeading;
            }).length;

            // Total auctions participated
            _participatedAuctions = auctions.length;

            // Total spent - sum of won auction bids
            _totalSpent = auctions.fold(0.0, (sum, auction) {
              final status = auction['status'];
              final isLeading = auction['is_leading'] ?? false;
              if ((status == 'ended' || status == 'settled') && isLeading) {
                final bid = auction['my_highest_bid'];
                if (bid != null) {
                  return sum + double.parse(bid.toString());
                }
              }
              return sum;
            });
          });
        }
      }
    } catch (e) {
      // Ignore errors - will show 0 values
    } finally {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  Future<void> _loadNotificationCount() async {
    try {
      final notificationService = context.read<NotificationService>();
      final count = await notificationService.getUnreadCount();
      if (mounted) {
        setState(() => _unreadNotifications = count);
      }
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> _loadRecentActivities() async {
    try {
      final apiService = context.read<ApiService>();
      final authProvider = context.read<AuthProvider>();
      final exporterId = authProvider.user?.id;

      if (exporterId != null) {
        final response = await apiService.getUserBids(exporterId);
        final auctions = response['auctions'] as List? ?? [];

        // Get last 3 activities
        final activities = <Map<String, dynamic>>[];
        for (var auction in auctions.take(3)) {
          activities.add({
            'icon': _getActivityIcon(auction),
            'title': _getActivityTitle(auction),
            'subtitle': '${auction['variety']} - ${auction['quantity']}kg',
            'time': _getRelativeTime(auction['updated_at']),
            'color': _getActivityColor(auction),
          });
        }

        if (mounted) {
          setState(() => _recentActivities = activities);
        }
      }
    } catch (e) {
      // Ignore errors
    }
  }

  IconData _getActivityIcon(Map<String, dynamic> auction) {
    final status = auction['status'];
    final isLeading = auction['is_leading'] ?? false;

    if ((status == 'ended' || status == 'settled') && isLeading) {
      return Icons.emoji_events;
    } else if (status == 'active' && isLeading) {
      return Icons.trending_up;
    } else {
      return Icons.gavel;
    }
  }

  String _getActivityTitle(Map<String, dynamic> auction) {
    final status = auction['status'];
    final isLeading = auction['is_leading'] ?? false;

    if (status == 'settled' && isLeading) {
      return 'Auction completed';
    } else if (status == 'ended' && isLeading) {
      return 'Auction won!';
    } else if (status == 'active' && isLeading) {
      return 'Leading bid';
    } else if (status == 'active') {
      return 'Bid placed';
    } else {
      return 'Outbid';
    }
  }

  Color _getActivityColor(Map<String, dynamic> auction) {
    final status = auction['status'];
    final isLeading = auction['is_leading'] ?? false;

    if ((status == 'ended' || status == 'settled') && isLeading) {
      return AppTheme.sriLankanLeaf;
    } else if (status == 'active' && isLeading) {
      return AppTheme.pepperGold;
    } else {
      return Colors.orange;
    }
  }

  String _getRelativeTime(String? timestamp) {
    if (timestamp == null) return 'Recently';
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.forestGreen,
      appBar: AppBar(
        backgroundColor: AppTheme.forestGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            // Handle menu/drawer
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icons/logo_copy.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            const Text(
              'SmartPepper',
              style: TextStyle(
                color: AppTheme.pepperGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: AppTheme.pepperGold),
                onPressed: () async {
                  await context.push('/exporter/notifications');
                  _loadNotificationCount();
                },
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadNotifications > 9 ? '9+' : '$_unreadNotifications',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Text(
                'Welcome back,',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                authProvider.user?.name ?? 'Exporter',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 24),

              // Quick Actions
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.shopping_basket,
                      label: 'Browse Lots',
                      color: AppTheme.pepperGold,
                      onTap: () => context.push('/exporter/browse'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.gavel,
                      label: 'My Bids',
                      color: AppTheme.sriLankanLeaf,
                      onTap: () => context.push('/exporter/bids'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.emoji_events,
                      label: 'Won Auctions',
                      color: Colors.blue,
                      onTap: () => context.push('/exporter/won'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.person,
                      label: 'My Profile',
                      color: Colors.purple,
                      onTap: () => context.push('/exporter/profile'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.gavel,
                      label: 'Live Auctions',
                      color: Colors.orange,
                      onTap: () => context.push('/exporter/live-auctions'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.qr_code_scanner,
                      label: 'Scan QR Code',
                      color: Colors.teal,
                      onTap: () => context.push('/qr-scanner'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Stats Overview
              const Text(
                'Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.deepEmerald,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _isLoadingStats
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                            color: AppTheme.pepperGold,
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.trending_up,
                                  label: 'Active Bids',
                                  value: '$_activeBids',
                                  color: AppTheme.sriLankanLeaf,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.emoji_events,
                                  label: 'Won',
                                  value: '$_wonAuctions',
                                  color: AppTheme.pepperGold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.gavel,
                                  label: 'Participated',
                                  value: '$_participatedAuctions',
                                  color: AppTheme.sriLankanLeaf,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.attach_money,
                                  label: 'Total Spent',
                                  value:
                                      '${_totalSpent.toStringAsFixed(2)} ETH',
                                  color: AppTheme.pepperGold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 24),

              // Recent Activity
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/exporter/bids'),
                    child: const Text(
                      'View All',
                      style: TextStyle(color: AppTheme.pepperGold),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Activity List
              if (_recentActivities.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.deepEmerald,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.shopping_basket_outlined,
                          size: 48,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No bids yet',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start browsing lots to place your first bid',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._recentActivities.map((activity) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildActivityItem(
                        icon: activity['icon'],
                        title: activity['title'],
                        subtitle: activity['subtitle'],
                        time: activity['time'],
                        color: activity['color'],
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.deepEmerald,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.forestGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.deepEmerald,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
