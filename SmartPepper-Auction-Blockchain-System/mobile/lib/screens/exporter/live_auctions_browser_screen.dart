import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auction_provider.dart';
import '../../config/theme.dart';
import '../shared/auction_details_screen.dart';

/// Screen for exporters to browse and join live auctions
class LiveAuctionsBrowserScreen extends StatefulWidget {
  const LiveAuctionsBrowserScreen({super.key});

  @override
  State<LiveAuctionsBrowserScreen> createState() =>
      _LiveAuctionsBrowserScreenState();
}

class _LiveAuctionsBrowserScreenState extends State<LiveAuctionsBrowserScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAuctions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAuctions() async {
    final auctionProvider = context.read<AuctionProvider>();
    await auctionProvider.fetchAuctions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppTheme.forestGreen,
        elevation: 0,
        title: const Text(
          'Live Auctions',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.pepperGold,
          labelColor: AppTheme.pepperGold,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.play_circle_outline),
              text: 'Active Now',
            ),
            Tab(
              icon: Icon(Icons.schedule),
              text: 'Upcoming',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'Ended',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAuctionList('active'),
          _buildAuctionList('upcoming'),
          _buildAuctionList('ended'),
        ],
      ),
    );
  }

  Widget _buildAuctionList(String filter) {
    return Consumer<AuctionProvider>(
      builder: (context, auctionProvider, _) {
        if (auctionProvider.loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.forestGreen),
          );
        }

        if (auctionProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading auctions',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  auctionProvider.error!,
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadAuctions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.forestGreen,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Filter auctions based on tab
        final filteredAuctions = auctionProvider.auctions.where((auction) {
          final status = auction.status.toLowerCase();
          if (filter == 'active') {
            return status == 'active';
          } else if (filter == 'upcoming') {
            return status == 'created' ||
                status == 'upcoming' ||
                status == 'pending';
          } else {
            return status == 'ended' ||
                status == 'completed' ||
                status == 'settled';
          }
        }).toList();

        if (filteredAuctions.isEmpty) {
          String emptyTitle, emptyMessage;
          IconData emptyIcon;

          if (filter == 'active') {
            emptyIcon = Icons.gavel;
            emptyTitle = 'No active auctions';
            emptyMessage = 'Check back later for live auctions';
          } else if (filter == 'upcoming') {
            emptyIcon = Icons.schedule;
            emptyTitle = 'No upcoming auctions';
            emptyMessage = 'New auctions will appear here';
          } else {
            emptyIcon = Icons.history;
            emptyTitle = 'No ended auctions';
            emptyMessage = 'Completed auctions will appear here';
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  emptyIcon,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  emptyTitle,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  emptyMessage,
                  style: TextStyle(color: Colors.grey[500]),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadAuctions,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.forestGreen,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadAuctions,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredAuctions.length,
            itemBuilder: (context, index) {
              final auction = filteredAuctions[index];
              return _buildAuctionCard(auction);
            },
          ),
        );
      },
    );
  }

  Widget _buildAuctionCard(Auction auction) {
    final status = auction.status.toLowerCase();
    final isActive = status == 'active';
    final isUpcoming =
        status == 'created' || status == 'upcoming' || status == 'pending';
    final isEnded =
        status == 'ended' || status == 'completed' || status == 'settled';

    Color statusColor;
    String statusLabel;
    if (isActive) {
      statusColor = Colors.green;
      statusLabel = 'LIVE';
    } else if (isUpcoming) {
      statusColor = Colors.orange;
      statusLabel = 'UPCOMING';
    } else {
      statusColor = Colors.grey;
      statusLabel = 'ENDED';
    }

    // Calculate time info
    final now = DateTime.now();
    String timeInfo;
    IconData timeIcon;

    if (isActive) {
      final duration = auction.endTime.difference(now);
      timeIcon = Icons.timer;
      if (duration.isNegative) {
        timeInfo = 'Ending soon';
      } else if (duration.inDays > 0) {
        timeInfo = 'Ends in ${duration.inDays}d ${duration.inHours % 24}h';
      } else if (duration.inHours > 0) {
        timeInfo = 'Ends in ${duration.inHours}h ${duration.inMinutes % 60}m';
      } else {
        timeInfo = 'Ends in ${duration.inMinutes}m';
      }
    } else if (isUpcoming) {
      final duration = auction.startTime.difference(now);
      timeIcon = Icons.schedule;
      if (duration.isNegative) {
        timeInfo = 'Starting soon';
      } else if (duration.inDays > 0) {
        timeInfo = 'Starts in ${duration.inDays}d';
      } else if (duration.inHours > 0) {
        timeInfo = 'Starts in ${duration.inHours}h';
      } else {
        timeInfo = 'Starting soon';
      }
    } else {
      final duration = now.difference(auction.endTime);
      timeIcon = Icons.history;
      if (duration.inDays > 0) {
        timeInfo = 'Ended ${duration.inDays}d ago';
      } else if (duration.inHours > 0) {
        timeInfo = 'Ended ${duration.inHours}h ago';
      } else {
        timeInfo = 'Recently ended';
      }
    }

    // Determine price to display
    final double displayPrice;
    final String priceLabel;
    final double? displayPriceLkr;

    if (isActive && auction.currentBid > 0) {
      displayPrice = auction.currentBid;
      priceLabel = 'Current Bid';
      displayPriceLkr = auction.currentBidLkr;
    } else if (isEnded && auction.currentBid > 0) {
      displayPrice = auction.currentBid;
      priceLabel = 'Final Price';
      displayPriceLkr = auction.currentBidLkr;
    } else {
      displayPrice = auction.startingPrice;
      priceLabel = 'Starting Price';
      displayPriceLkr = null;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AuctionDetailsScreen(auction: auction),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row - Status and Time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isActive)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        if (isActive) const SizedBox(width: 6),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Time Info
                  Row(
                    children: [
                      Icon(
                        timeIcon,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeInfo,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Auction ID
              Row(
                children: [
                  const Icon(Icons.gavel,
                      size: 18, color: AppTheme.forestGreen),
                  const SizedBox(width: 6),
                  Text(
                    'Auction #${auction.auctionId}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Variety and Quantity
              if (auction.variety != null || auction.quantity != null) ...[
                Row(
                  children: [
                    if (auction.variety != null) ...[
                      Icon(Icons.eco, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          auction.variety!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    if (auction.variety != null && auction.quantity != null)
                      const SizedBox(width: 12),
                    if (auction.quantity != null) ...[
                      Icon(Icons.scale, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        '${auction.quantity!.toStringAsFixed(0)} kg',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Farmer Address
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    'Farmer: ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: auction.farmerAddress));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Farmer address copied!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Text(
                        '${auction.farmerAddress.substring(0, 6)}...${auction.farmerAddress.substring(auction.farmerAddress.length - 4)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.forestGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Icon(Icons.copy, size: 14, color: Colors.grey[500]),
                ],
              ),

              const SizedBox(height: 8),

              // Blockchain Transaction Hash
              if (auction.blockchainTxHash != null) ...[
                Row(
                  children: [
                    Icon(Icons.link, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      'Tx: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: auction.blockchainTxHash!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Transaction hash copied!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Text(
                          '${auction.blockchainTxHash!.substring(0, 6)}...${auction.blockchainTxHash!.substring(auction.blockchainTxHash!.length - 4)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    Icon(Icons.copy, size: 14, color: Colors.grey[500]),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              const Divider(),

              const SizedBox(height: 8),

              // Price and Action Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Price Display
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          priceLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '\$${displayPrice.toStringAsFixed(4)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.forestGreen,
                          ),
                        ),
                        if (displayPriceLkr != null)
                          Text(
                            'LKR ${displayPriceLkr.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Action Button
                  if (isActive)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AuctionDetailsScreen(auction: auction),
                          ),
                        );
                      },
                      icon: const Icon(Icons.gavel, size: 18),
                      label: const Text('Place Bid'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.forestGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AuctionDetailsScreen(auction: auction),
                          ),
                        );
                      },
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('View Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.forestGreen,
                        side: const BorderSide(color: AppTheme.forestGreen),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
