import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auction_provider.dart';
import '../../config/theme.dart';
import '../../localization/app_localizations.dart';
import 'auction_details_screen.dart';
import '../farmer/create_auction_screen.dart';
import '../farmer/auction_monitor_screen.dart';

class AuctionsScreen extends StatefulWidget {
  const AuctionsScreen({super.key});

  @override
  State<AuctionsScreen> createState() => _AuctionsScreenState();
}

class _AuctionsScreenState extends State<AuctionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Fetch auctions when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final isFarmer = authProvider.user?.role.toLowerCase() == 'farmer';
      final farmerAddress = isFarmer ? authProvider.user?.walletAddress : null;
      context
          .read<AuctionProvider>()
          .fetchAuctions(farmerAddress: farmerAddress);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isFarmer = authProvider.user?.role.toLowerCase() == 'farmer';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppTheme.forestGreen,
        elevation: 0,
        title: Text(
          isFarmer
              ? context.tr('label_my_auctions')
              : context.tr('label_auctions'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {
              _showFilterDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(context.tr('message_search_functionality'))),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.pepperGold,
          labelColor: AppTheme.pepperGold,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: context.tr('tab_active')),
            Tab(text: context.tr('tab_upcoming')),
            Tab(text: context.tr('tab_completed')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAuctionList('active'),
          _buildAuctionList('upcoming'),
          _buildAuctionList('completed'),
        ],
      ),
      floatingActionButton: isFarmer
          ? FloatingActionButton.extended(
              heroTag: 'auctions_fab',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateAuctionScreen(),
                  ),
                );
              },
              backgroundColor: AppTheme.forestGreen,
              icon: const Icon(Icons.add),
              label: Text(context.tr('button_create_auction')),
            )
          : null,
    );
  }

  Widget _buildAuctionList(String status) {
    final authProvider = context.watch<AuthProvider>();
    final auctionProvider = context.watch<AuctionProvider>();
    final isFarmer = authProvider.user?.role.toLowerCase() == 'farmer';
    final farmerAddress = isFarmer ? authProvider.user?.walletAddress : null;

    // Map display status to backend statuses
    List<String> statusFilters = [];
    if (status == 'active') {
      statusFilters = ['active'];
    } else if (status == 'upcoming') {
      statusFilters = ['created'];
    } else if (status == 'completed') {
      statusFilters = ['ended', 'settled', 'failed_compliance'];
    }

    // Filter auctions by status
    final filteredAuctions = auctionProvider.auctions
        .where(
            (auction) => statusFilters.contains(auction.status.toLowerCase()))
        .toList();

    if (auctionProvider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (auctionProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              context.tr('error_loading_auctions'),
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  auctionProvider.fetchAuctions(farmerAddress: farmerAddress),
              child: Text(context.tr('button_retry')),
            ),
          ],
        ),
      );
    }

    if (filteredAuctions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.gavel_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isFarmer
                  ? '${context.tr('common_no')} $status ${context.tr('label_auctions')}\n${context.tr('message_create_first_auction')}'
                  : '${context.tr('common_no')} $status ${context.tr('label_auctions')}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await auctionProvider.fetchAuctions(farmerAddress: farmerAddress);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredAuctions.length,
        itemBuilder: (context, index) {
          final auction = filteredAuctions[index];
          return _buildAuctionCard(auction);
        },
      ),
    );
  }

  Widget _buildAuctionCard(dynamic auction) {
    final status = auction.status.toLowerCase();
    final Color statusColor = status == 'active'
        ? Colors.green
        : status == 'upcoming'
            ? Colors.orange
            : Colors.grey;

    // Calculate time remaining
    final now = DateTime.now();
    String timeRemaining;
    if (status == 'active') {
      final duration = auction.endTime.difference(now);
      if (duration.isNegative) {
        timeRemaining = context.tr('label_ending_soon');
      } else if (duration.inDays > 0) {
        timeRemaining = '${duration.inDays}d ${duration.inHours % 24}h';
      } else if (duration.inHours > 0) {
        timeRemaining = '${duration.inHours}h ${duration.inMinutes % 60}m';
      } else {
        timeRemaining = '${duration.inMinutes}m';
      }
    } else if (status == 'upcoming') {
      final duration = auction.startTime.difference(now);
      if (duration.inDays > 0) {
        timeRemaining = '${context.tr('label_starts_in')} ${duration.inDays}d';
      } else {
        timeRemaining = '${context.tr('label_starts_in')} ${duration.inHours}h';
      }
    } else {
      timeRemaining = context.tr('label_ended');
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          final authProvider = context.read<AuthProvider>();
          final isFarmer = authProvider.user?.role.toLowerCase() == 'farmer';

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => isFarmer
                  ? FarmerAuctionMonitorScreen(auctionId: auction.auctionId)
                  : AuctionDetailsScreen(auction: auction),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  Text(
                    auction.auctionId,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Variety and Quantity
              Text(
                auction.variety ?? context.tr('label_black_pepper'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.forestGreen,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.scale, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${auction.quantity?.toStringAsFixed(0) ?? context.tr('label_na')} kg',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Current Bid and Time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auction.currentBid > 0
                            ? context.tr('label_current_bid')
                            : context.tr('label_starting_price'),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${(auction.currentBid > 0 ? auction.currentBid : auction.startingPrice).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.forestGreen,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeRemaining,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${context.tr('label_lot_prefix')} ${auction.lotId}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              if (status == 'active') ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final authProvider = context.read<AuthProvider>();
                      final isFarmer =
                          authProvider.user?.role.toLowerCase() == 'farmer';

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => isFarmer
                              ? FarmerAuctionMonitorScreen(
                                  auctionId: auction.auctionId)
                              : AuctionDetailsScreen(auction: auction),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.forestGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      context.tr('button_place_bid'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('dialog_filter_auctions')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(context.tr('label_all_varieties')),
              leading: Radio(value: 0, groupValue: 0, onChanged: (_) {}),
            ),
            ListTile(
              title: Text(context.tr('label_black_pepper')),
              leading: Radio(value: 1, groupValue: 0, onChanged: (_) {}),
            ),
            ListTile(
              title: Text(context.tr('label_white_pepper')),
              leading: Radio(value: 2, groupValue: 0, onChanged: (_) {}),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('button_cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.tr('message_filter_applied'))),
              );
            },
            child: Text(context.tr('button_apply')),
          ),
        ],
      ),
    );
  }
}
