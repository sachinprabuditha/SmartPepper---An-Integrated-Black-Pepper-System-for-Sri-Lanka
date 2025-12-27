import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../services/notification_service.dart';
import '../../services/offline_sync_service.dart';
import '../../services/api_service.dart';
import '../../models/lot.dart';

class FarmerDashboard extends StatefulWidget {
  const FarmerDashboard({super.key});

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard> {
  int _unreadNotifications = 0;
  bool _isSyncing = false;
  int _pendingSyncCount = 0;
  int _activeLots = 0;
  int _inAuction = 0;
  int _soldLots = 0;
  double _totalRevenue = 0.0;

  @override
  void initState() {
    super.initState();
    _loadNotificationCount();
    _loadSyncStatus();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final apiService = context.read<ApiService>();
      final authProvider = context.read<AuthProvider>();

      // Get current user's ID to filter their lots only
      final farmerId = authProvider.user?.id;

      if (farmerId != null) {
        final lotsData = await apiService.getLots(farmerAddress: farmerId);
        final lots = lotsData.map<Lot>((data) => Lot.fromJson(data)).toList();

        if (mounted) {
          setState(() {
            _activeLots = lots.where((lot) => lot.status == 'approved').length;
            _inAuction = lots.where((lot) => lot.isInAuction).length;
            _soldLots = lots.where((lot) => lot.isSold).length;
            _totalRevenue = lots
                .where((lot) => lot.isSold && lot.currentBid != null)
                .fold(0.0, (sum, lot) => sum + lot.currentBid!);
          });
        }
      }
    } catch (e) {
      // Ignore errors - will show 0 values
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

  Future<void> _loadSyncStatus() async {
    try {
      final syncService = context.read<OfflineSyncService>();
      final count = await syncService.getPendingCount();
      if (mounted) {
        setState(() => _pendingSyncCount = count);
      }
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> _triggerSync() async {
    setState(() => _isSyncing = true);
    try {
      final syncService = context.read<OfflineSyncService>();
      final result = await syncService.syncPendingData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : Colors.orange,
          ),
        );
        await _loadSyncStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
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
        title: const Text(
          'smartPepper',
          style: TextStyle(
            color: AppTheme.pepperGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: AppTheme.pepperGold),
                onPressed: () async {
                  await context.push('/farmer/notifications');
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
                authProvider.user?.name ?? 'Farmer',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 24),

              // Offline Sync Status
              if (_pendingSyncCount > 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.sync, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_pendingSyncCount items pending sync',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900,
                              ),
                            ),
                            Text(
                              'Connect to internet to sync',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _isSyncing ? null : _triggerSync,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          foregroundColor: Colors.white,
                        ),
                        child: _isSyncing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Sync'),
                      ),
                    ],
                  ),
                ),

              // Quick Actions
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.add_circle_outline,
                      label: 'Create Lot',
                      color: AppTheme.pepperGold,
                      onTap: () => context.push('/farmer/create-lot'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.inventory_outlined,
                      label: 'My Lots',
                      color: AppTheme.sriLankanLeaf,
                      onTap: () => context.push('/farmer/my-lots'),
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
                      color: Colors.blue,
                      onTap: () => context.push('/shared/auctions'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.qr_code,
                      label: 'Scan QR',
                      color: Colors.purple,
                      onTap: () => context.push('/shared/qr-scanner'),
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
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.eco,
                            label: 'Active Lots',
                            value: '$_activeLots',
                            color: AppTheme.sriLankanLeaf,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.trending_up,
                            label: 'In Auction',
                            value: '$_inAuction',
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
                            icon: Icons.check_circle,
                            label: 'Sold',
                            value: '$_soldLots',
                            color: AppTheme.sriLankanLeaf,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.attach_money,
                            label: 'Revenue',
                            value:
                                '\$${(_totalRevenue / 1000).toStringAsFixed(1)}K',
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
                    onPressed: () => context.push('/farmer/activity'),
                    child: const Text(
                      'View All',
                      style: TextStyle(color: AppTheme.pepperGold),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Activity List
              _buildActivityItem(
                icon: Icons.gavel,
                title: 'Lot #1234 sold',
                subtitle: 'Black Pepper - 100kg',
                time: '2 hours ago',
                color: AppTheme.sriLankanLeaf,
              ),
              const SizedBox(height: 12),
              _buildActivityItem(
                icon: Icons.trending_up,
                title: 'New bid on Lot #1235',
                subtitle: 'White Pepper - 50kg',
                time: '5 hours ago',
                color: AppTheme.pepperGold,
              ),
              const SizedBox(height: 12),
              _buildActivityItem(
                icon: Icons.verified,
                title: 'Certificate approved',
                subtitle: 'Lot #1236 - Quality Check',
                time: '1 day ago',
                color: AppTheme.sriLankanLeaf,
              ),
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
              ),
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
              fontSize: 24,
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
