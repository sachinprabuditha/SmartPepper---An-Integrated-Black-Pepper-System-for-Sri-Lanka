import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auction_provider.dart';
import '../../providers/lot_provider.dart';
import '../../config/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final auctionProvider = context.read<AuctionProvider>();
    final lotProvider = context.read<LotProvider>();

    await Future.wait([
      auctionProvider.fetchAuctions(),
      lotProvider.fetchLots(
        farmerAddress: authProvider.user?.role.toLowerCase() == 'farmer'
            ? authProvider.user?.walletAddress
            : null,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final auctionProvider = context.watch<AuctionProvider>();
    final lotProvider = context.watch<LotProvider>();
    final user = authProvider.user;

    // Calculate stats from real data
    final activeAuctions = auctionProvider.auctions
        .where((a) => a.status.toLowerCase() == 'active')
        .length;
    final totalLots = lotProvider.lots.length;

    return Scaffold(
      backgroundColor: AppTheme.forestGreen,
      appBar: AppBar(
        backgroundColor: AppTheme.forestGreen,
        elevation: 0,
        title: const Text(
          'smartPepper',
          style: TextStyle(
            color: AppTheme.pepperGold,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppTheme.pepperGold,
            ),
            onPressed: () {
              // Navigate to notifications
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                decoration: const BoxDecoration(
                  color: AppTheme.forestGreen,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.name ?? 'User',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.pepperGold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.pepperGold,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getRoleIcon(user?.role ?? 'user'),
                            size: 16,
                            color: AppTheme.pepperGold,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            user?.role.toUpperCase() ?? 'USER',
                            style: const TextStyle(
                              color: AppTheme.pepperGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Stats
                      _buildQuickStats(activeAuctions, totalLots),

                      const SizedBox(height: 24),

                      // Quick Actions
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.forestGreen,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildQuickActions(context, user?.role ?? 'user'),

                      const SizedBox(height: 24),

                      // Recent Activity
                      const Text(
                        'Recent Activity',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.forestGreen,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildRecentActivity(auctionProvider.auctions),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'farmer':
        return Icons.agriculture;
      case 'exporter':
        return Icons.local_shipping;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }

  Widget _buildQuickStats(int activeAuctions, int totalLots) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.gavel,
            label: 'Active Auctions',
            value: activeAuctions.toString(),
            color: AppTheme.forestGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.inventory_2,
            label: 'Total Lots',
            value: totalLots.toString(),
            color: AppTheme.pepperGold,
          ),
        ),
      ],
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, String role) {
    final actions = _getQuickActionsForRole(role);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildActionCard(
          icon: action['icon'] as IconData,
          label: action['label'] as String,
          color: action['color'] as Color,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${action['label']} tapped')),
            );
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> _getQuickActionsForRole(String role) {
    if (role.toLowerCase() == 'farmer') {
      return [
        {
          'icon': Icons.add_circle_outline,
          'label': 'Create Lot',
          'color': AppTheme.forestGreen,
        },
        {
          'icon': Icons.qr_code_scanner,
          'label': 'Scan QR',
          'color': AppTheme.pepperGold,
        },
        {
          'icon': Icons.track_changes,
          'label': 'Track',
          'color': AppTheme.forestGreen,
        },
        {
          'icon': Icons.gavel,
          'label': 'Auctions',
          'color': Colors.blue,
        },
        {
          'icon': Icons.analytics,
          'label': 'Analytics',
          'color': Colors.purple,
        },
        {
          'icon': Icons.document_scanner,
          'label': 'Documents',
          'color': Colors.orange,
        },
      ];
    } else if (role.toLowerCase() == 'exporter') {
      return [
        {
          'icon': Icons.gavel,
          'label': 'Browse',
          'color': AppTheme.forestGreen,
        },
        {
          'icon': Icons.monetization_on,
          'label': 'My Bids',
          'color': AppTheme.pepperGold,
        },
        {
          'icon': Icons.qr_code_scanner,
          'label': 'Scan',
          'color': AppTheme.forestGreen,
        },
        {
          'icon': Icons.history,
          'label': 'History',
          'color': Colors.blue,
        },
        {
          'icon': Icons.analytics,
          'label': 'Analytics',
          'color': Colors.purple,
        },
        {
          'icon': Icons.local_shipping,
          'label': 'Shipments',
          'color': Colors.orange,
        },
      ];
    } else {
      return [
        {
          'icon': Icons.gavel,
          'label': 'Auctions',
          'color': AppTheme.forestGreen,
        },
        {
          'icon': Icons.inventory_2,
          'label': 'Inventory',
          'color': AppTheme.pepperGold,
        },
        {
          'icon': Icons.qr_code_scanner,
          'label': 'Scan',
          'color': AppTheme.forestGreen,
        },
      ];
    }
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(List auctions) {
    if (auctions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'No recent activity',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    // Show last 3 auctions
    final recentAuctions = auctions.take(3).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentAuctions.length,
      itemBuilder: (context, index) {
        final auction = recentAuctions[index];
        final timeAgo = _getTimeAgo(auction.startTime);

        return _buildActivityItem(
          title: 'Auction ${auction.auctionId}',
          subtitle: 'Current bid: \$${auction.currentBid.toStringAsFixed(2)}',
          time: timeAgo,
          icon: Icons.gavel,
          color: auction.status.toLowerCase() == 'active'
              ? AppTheme.forestGreen
              : Colors.grey,
        );
      },
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildActivityItem({
    required String title,
    required String subtitle,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
