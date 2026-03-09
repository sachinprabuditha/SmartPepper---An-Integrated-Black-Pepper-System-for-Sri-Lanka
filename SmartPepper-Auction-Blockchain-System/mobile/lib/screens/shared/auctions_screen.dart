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
        : status == 'created'
            ? Colors.orange
            : Colors.grey;

    // Calculate time remaining and progress
    final now = DateTime.now();
    String timeRemaining;
    double? timeProgress;
    bool isUrgent = false;

    if (status == 'active') {
      final duration = auction.endTime.difference(now);
      final totalDuration = auction.endTime.difference(auction.startTime);
      timeProgress = (1 - (duration.inSeconds / totalDuration.inSeconds))
          .clamp(0.0, 1.0)
          .toDouble();

      if (duration.isNegative) {
        timeRemaining = context.tr('label_ending_soon');
        isUrgent = true;
      } else if (duration.inDays > 0) {
        timeRemaining = '${duration.inDays}d ${duration.inHours % 24}h';
      } else if (duration.inHours > 0) {
        timeRemaining = '${duration.inHours}h ${duration.inMinutes % 60}m';
        if (duration.inHours < 2) isUrgent = true;
      } else {
        timeRemaining = '${duration.inMinutes}m';
        isUrgent = true;
      }
    } else if (status == 'created') {
      final duration = auction.startTime.difference(now);
      if (duration.inDays > 0) {
        timeRemaining = '${context.tr('label_starts_in')} ${duration.inDays}d';
      } else if (duration.inHours > 0) {
        timeRemaining = '${context.tr('label_starts_in')} ${duration.inHours}h';
      } else {
        timeRemaining =
            '${context.tr('label_starts_in')} ${duration.inMinutes}m';
      }
    } else {
      timeRemaining = context.tr('label_ended');
    }

    // Get auction details
    final variety = auction.variety ?? context.tr('label_black_pepper');
    final quantity = auction.quantity ?? 0.0;
    final quality = auction.quality;
    final bidderCount = auction.bidderCount ?? 0;
    final currentBid = auction.currentBid ?? 0.0;
    final currentBidLkr = auction.currentBidLkr ?? 0.0;
    final startingPrice = auction.startingPrice ?? 0.0;
    final startingPriceLkr = auction.startingPriceLkr ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: AppTheme.forestGreen.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () {
          final authProvider = context.read<AuthProvider>();
          final isFarmer = authProvider.user?.role.toLowerCase() == 'farmer';

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => isFarmer
                  ? FarmerAuctionMonitorScreen(auctionId: auction.id)
                  : AuctionDetailsScreen(auction: auction),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                status == 'active'
                    ? Colors.green.withOpacity(0.02)
                    : Colors.grey.withOpacity(0.02),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row - Status and ID
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            statusColor,
                            statusColor.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            status == 'active'
                                ? Icons.gavel
                                : status == 'created'
                                    ? Icons.schedule
                                    : Icons.check_circle,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#${auction.id.toString().substring(0, auction.id.length > 8 ? 8 : auction.id.length)}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Variety and Quality Badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        variety,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.forestGreen,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    if (quality != null && quality.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.pepperGold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.pepperGold,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: AppTheme.pepperGold,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              quality.toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.pepperGold,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Quantity and Lot Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.forestGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.inventory_2,
                          size: 20,
                          color: AppTheme.forestGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quantity',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${quantity.toStringAsFixed(0)} kg',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.forestGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.category,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${context.tr('label_lot_prefix')} ${auction.lotId}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Price and Bidding Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.forestGreen.withOpacity(0.05),
                        AppTheme.forestGreen.withOpacity(0.02),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.forestGreen.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  currentBid > 0
                                      ? Icons.trending_up
                                      : Icons.price_check,
                                  size: 14,
                                  color: Colors.yellow,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  currentBid > 0
                                      ? context.tr('label_current_bid')
                                      : context.tr('label_starting_price'),
                                  style: const TextStyle(
                                    color: Colors.yellow,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // ETH Price
                            Row(
                              children: [
                                const Icon(
                                  Icons.currency_bitcoin,
                                  size: 16,
                                  color: AppTheme.forestGreen,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${(currentBid > 0 ? currentBid : startingPrice).toStringAsFixed(4)} ETH',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.forestGreen,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // LKR Price
                            Row(
                              children: [
                                const Icon(
                                  Icons.attach_money,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'LKR ${((currentBid > 0 ? currentBidLkr : startingPriceLkr) ?? 0.0).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            if (currentBid > 0 && startingPrice > 0) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.green[300]!,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '+${(currentBid - startingPrice).toStringAsFixed(4)} ETH from start',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (status == 'active') ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isUrgent
                                    ? Colors.red.withOpacity(0.1)
                                    : Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isUrgent ? Colors.red : Colors.blue,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    isUrgent
                                        ? Icons.timer_off
                                        : Icons.access_time,
                                    size: 18,
                                    color: isUrgent ? Colors.red : Colors.blue,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    timeRemaining,
                                    style: TextStyle(
                                      color:
                                          isUrgent ? Colors.red : Colors.blue,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'remaining',
                                    style: TextStyle(
                                      color: isUrgent
                                          ? Colors.red[700]
                                          : Colors.blue[700],
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ] else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                timeRemaining,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (bidderCount > 0) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.pepperGold.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.people,
                                    size: 14,
                                    color: AppTheme.pepperGold,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$bidderCount ${bidderCount == 1 ? 'bidder' : 'bidders'}',
                                    style: const TextStyle(
                                      color: AppTheme.pepperGold,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Progress bar for active auctions
                if (status == 'active' && timeProgress != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: timeProgress,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isUrgent ? Colors.red : AppTheme.forestGreen,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],

                // Action Button
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
                                    auctionId: auction.id)
                                : AuctionDetailsScreen(auction: auction),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.forestGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.gavel, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            context.tr('button_place_bid'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else if (status == 'created') ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Starts $timeRemaining',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
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
