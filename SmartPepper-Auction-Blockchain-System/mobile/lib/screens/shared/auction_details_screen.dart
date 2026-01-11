import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../../providers/auth_provider.dart';
import '../../providers/auction_provider.dart';
import '../../config/theme.dart';

class AuctionDetailsScreen extends StatefulWidget {
  final Auction auction;

  const AuctionDetailsScreen({
    super.key,
    required this.auction,
  });

  @override
  State<AuctionDetailsScreen> createState() => _AuctionDetailsScreenState();
}

class _AuctionDetailsScreenState extends State<AuctionDetailsScreen> {
  final TextEditingController _bidController = TextEditingController();
  Timer? _countdownTimer;
  Duration? _timeRemaining;
  bool _isPlacingBid = false;
  List<Map<String, dynamic>> _bidHistory = [];

  @override
  void initState() {
    super.initState();
    _initializeAuction();
    _startCountdown();
    _loadBidHistory();
  }

  void _initializeAuction() {
    final auctionProvider = context.read<AuctionProvider>();
    auctionProvider.joinAuction(widget.auction.id);
  }

  void _startCountdown() {
    _updateTimeRemaining();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _updateTimeRemaining();
      }
    });
  }

  void _updateTimeRemaining() {
    final now = DateTime.now();
    if (widget.auction.status.toLowerCase() == 'active') {
      final remaining = widget.auction.endTime.difference(now);
      setState(() {
        _timeRemaining = remaining.isNegative ? Duration.zero : remaining;
      });
    } else if (widget.auction.status.toLowerCase() == 'upcoming') {
      final remaining = widget.auction.startTime.difference(now);
      setState(() {
        _timeRemaining = remaining.isNegative ? Duration.zero : remaining;
      });
    }
  }

  void _loadBidHistory() {
    // TODO: Load bid history from API
    // For now, show empty state as no real bids exist yet
    setState(() {
      _bidHistory = [];
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _bidController.dispose();
    context.read<AuctionProvider>().leaveAuction();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h ${duration.inMinutes % 60}m';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m ${duration.inSeconds % 60}s';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  Future<void> _placeBid() async {
    final bidAmount = double.tryParse(_bidController.text);
    if (bidAmount == null || bidAmount <= widget.auction.currentBid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bid must be higher than current bid (\$${widget.auction.currentBid.toStringAsFixed(2)})',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isPlacingBid = true);

    final auctionProvider = context.read<AuctionProvider>();
    final success =
        await auctionProvider.placeBid(widget.auction.id, bidAmount);

    setState(() => _isPlacingBid = false);

    if (success && mounted) {
      _bidController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bid placed successfully! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
      _loadBidHistory(); // Refresh bid history
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auctionProvider.error ?? 'Failed to place bid. Please try again.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final auctionProvider = context.watch<AuctionProvider>();
    final currentAuction = auctionProvider.currentAuction ?? widget.auction;
    final isFarmer = authProvider.user?.role.toLowerCase() == 'farmer';
    final isActive = currentAuction.status.toLowerCase() == 'active';
    final isUpcoming = currentAuction.status.toLowerCase() ==
        'created'; // Backend uses 'created' for upcoming

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppTheme.forestGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          currentAuction.auctionId,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share auction')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bookmark added')),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await auctionProvider.fetchAuctions();
          _loadBidHistory();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Banner
              _buildStatusBanner(currentAuction, isActive, isUpcoming),

              // Countdown Timer
              if (_timeRemaining != null && (isActive || isUpcoming))
                _buildCountdownTimer(isActive),

              // Current Bid Section
              _buildCurrentBidSection(currentAuction),

              // Auction Details
              _buildAuctionDetails(currentAuction),

              // Lot Information
              _buildLotInformation(currentAuction),

              // Farmer Information
              _buildFarmerInformation(currentAuction),

              // Bid History
              _buildBidHistory(),

              // Blockchain Verification
              _buildBlockchainVerification(currentAuction),

              const SizedBox(height: 100), // Space for bottom sheet
            ],
          ),
        ),
      ),
      bottomSheet: isActive && !isFarmer
          ? _buildBiddingBottomSheet(currentAuction)
          : null,
    );
  }

  Widget _buildStatusBanner(Auction auction, bool isActive, bool isUpcoming) {
    Color bgColor;
    Color textColor;
    String statusText;
    IconData icon;

    if (isActive) {
      bgColor = Colors.green;
      textColor = Colors.white;
      statusText = 'LIVE AUCTION';
      icon = Icons.circle;
    } else if (isUpcoming) {
      bgColor = Colors.orange;
      textColor = Colors.white;
      statusText = 'UPCOMING';
      icon = Icons.schedule;
    } else {
      bgColor = Colors.grey;
      textColor = Colors.white;
      statusText = 'ENDED';
      icon = Icons.check_circle;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: bgColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isActive)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1000),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Icon(icon, color: textColor, size: 16),
                );
              },
              onEnd: () {
                if (mounted) {
                  setState(() {});
                }
              },
            )
          else
            Icon(icon, color: textColor, size: 16),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownTimer(bool isActive) {
    if (_timeRemaining == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [AppTheme.forestGreen, Colors.green[700]!]
              : [Colors.orange, Colors.deepOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isActive ? AppTheme.forestGreen : Colors.orange)
                .withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            isActive ? 'Ends In' : 'Starts In',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatDuration(_timeRemaining!),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentBidSection(Auction auction) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Bid',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (auction.highestBidder != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.pepperGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        size: 12,
                        color: AppTheme.pepperGold,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Highest Bidder',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '\$${(auction.currentBid > 0 ? auction.currentBid : auction.startingPrice).toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: AppTheme.forestGreen,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            auction.currentBid > 0
                ? 'Current Highest Bid'
                : 'Starting Price - No bids yet',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Starting Bid: ',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              Text(
                '\$${auction.startingPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+${((auction.currentBid - auction.startingPrice) / auction.startingPrice * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuctionDetails(Auction auction) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Auction Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.forestGreen,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.business_center,
            'Variety',
            auction.variety ?? 'Black Pepper Premium',
          ),
          _buildDetailRow(
            Icons.scale,
            'Quantity',
            '${auction.quantity?.toStringAsFixed(0) ?? 'N/A'} kg',
          ),
          _buildDetailRow(
            Icons.access_time,
            'Start Time',
            _formatDateTime(auction.startTime),
          ),
          _buildDetailRow(
            Icons.event,
            'End Time',
            _formatDateTime(auction.endTime),
          ),
          _buildDetailRow(
            Icons.tag,
            'Auction ID',
            auction.auctionId,
            copyable: true,
          ),
        ],
      ),
    );
  }

  Widget _buildLotInformation(Auction auction) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lot Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.forestGreen,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.inventory_2,
            'Lot ID',
            auction.lotId,
          ),
          _buildDetailRow(
            Icons.token,
            'Token ID',
            auction.tokenId,
            copyable: true,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Navigate to lot details screen based on user role
                final authProvider = context.read<AuthProvider>();
                final isFarmer =
                    authProvider.user?.role.toLowerCase() == 'farmer';

                if (isFarmer) {
                  // Navigate to farmer lot details screen
                  Navigator.pushNamed(
                    context,
                    '/farmer/lot-details',
                    arguments: {'lotId': auction.lotId},
                  );
                } else {
                  // For buyers, show lot details in a dialog or separate screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lot details view for buyers coming soon'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.visibility),
              label: const Text('View Full Lot Details'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.forestGreen,
                side: const BorderSide(color: AppTheme.forestGreen),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmerInformation(Auction auction) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.forestGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.agriculture,
                  color: AppTheme.forestGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Farmer Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.forestGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.account_balance_wallet,
            'Wallet Address',
            _formatAddress(auction.farmerAddress),
            copyable: true,
            fullValue: auction.farmerAddress,
          ),
          _buildDetailRow(
            Icons.verified,
            'Verified Farmer',
            'Yes',
            trailing: const Icon(
              Icons.verified,
              color: Colors.green,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBidHistory() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bid History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.forestGreen,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.forestGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_bidHistory.length} bids',
                  style: const TextStyle(
                    color: AppTheme.forestGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_bidHistory.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No bids yet. Be the first!',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ..._bidHistory.asMap().entries.map((entry) {
              final index = entry.key;
              final bid = entry.value;
              final isLatest = index == 0;

              return Container(
                margin: EdgeInsets.only(
                    bottom: index < _bidHistory.length - 1 ? 12 : 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isLatest
                      ? AppTheme.pepperGold.withOpacity(0.1)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isLatest ? AppTheme.pepperGold : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            isLatest ? AppTheme.pepperGold : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isLatest ? Icons.emoji_events : Icons.person,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bid['bidder'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTimeAgo(bid['time']),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${bid['amount'].toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            isLatest ? AppTheme.forestGreen : Colors.grey[700],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildBlockchainVerification(Auction auction) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.verified_user,
                  color: Colors.purple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Blockchain Verification',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.lock, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                'Immutable Record',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Real-time Updates',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.shield, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                'Smart Contract Enforced',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: auction.blockchainTxHash != null &&
                      auction.blockchainTxHash!.isNotEmpty
                  ? () async {
                      // Hardhat local blockchain explorer URL
                      // You can change this to your blockchain explorer URL
                      final url = Uri.parse(
                          'http://localhost:8545/tx/${auction.blockchainTxHash}');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url,
                            mode: LaunchMode.externalApplication);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Transaction Hash: ${auction.blockchainTxHash}'),
                              duration: const Duration(seconds: 5),
                              action: SnackBarAction(
                                label: 'Copy',
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(
                                      text: auction.blockchainTxHash!));
                                },
                              ),
                            ),
                          );
                        }
                      }
                    }
                  : null,
              icon: const Icon(Icons.open_in_new),
              label: const Text('View on Blockchain'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.purple,
                side: const BorderSide(color: Colors.purple),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiddingBottomSheet(Auction auction) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _bidController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Enter your bid',
                      hintText:
                          'Min: \$${(auction.currentBid + 10).toStringAsFixed(2)}',
                      prefixIcon: const Icon(Icons.attach_money),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.forestGreen,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isPlacingBid ? null : _placeBid,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.forestGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isPlacingBid
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Place Bid',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickBidButton(auction.currentBid + 50),
                _buildQuickBidButton(auction.currentBid + 100),
                _buildQuickBidButton(auction.currentBid + 200),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickBidButton(double amount) {
    return OutlinedButton(
      onPressed: () {
        _bidController.text = amount.toStringAsFixed(2);
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.forestGreen,
        side: const BorderSide(color: AppTheme.forestGreen),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        '\$${amount.toStringAsFixed(0)}',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    bool copyable = false,
    String? fullValue,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (copyable)
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              color: AppTheme.forestGreen,
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(text: fullValue ?? value),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied to clipboard'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatAddress(String address) {
    if (address.isEmpty || address.length < 10) {
      return address; // Return as-is if too short
    }
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
