import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../models/auction.dart';
import '../../models/lot.dart';
import '../../services/socket_service.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';
import 'package:go_router/go_router.dart';

/// Auction monitoring screen for farmers to track their lots in auctions
/// Farmers can see live bid updates, bidder count, and time remaining
class FarmerAuctionMonitorScreen extends StatefulWidget {
  final String auctionId;

  const FarmerAuctionMonitorScreen({
    super.key,
    required this.auctionId,
  });

  @override
  State<FarmerAuctionMonitorScreen> createState() =>
      _FarmerAuctionMonitorScreenState();
}

class _FarmerAuctionMonitorScreenState
    extends State<FarmerAuctionMonitorScreen> {
  Auction? _auction;
  Lot? _lot;
  bool _isLoading = true;
  Timer? _countdownTimer;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadAuctionData();
    _setupRealtimeUpdates();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _disconnectRealtimeUpdates();
    super.dispose();
  }

  Future<void> _loadAuctionData() async {
    setState(() => _isLoading = true);

    try {
      final apiService = context.read<ApiService>();

      // Fetch auction details
      final auctionResponse =
          await apiService.get('/auctions/${widget.auctionId}');
      final auction = Auction.fromJson(auctionResponse);

      // Fetch lot details
      final lotResponse = await apiService.get('/lots/${auction.lotId}');
      final lot = Lot.fromJson(lotResponse);

      if (mounted) {
        setState(() {
          _auction = auction;
          _lot = lot;
          _timeRemaining = auction.timeRemaining;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load auction: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _setupRealtimeUpdates() {
    final socketService = context.read<SocketService>();

    // Listen for bid updates
    socketService.on('bid_placed', (data) {
      if (data['auctionId'] == widget.auctionId) {
        setState(() {
          _auction = Auction.fromJson({
            ..._auction!.toJson(),
            'currentBid': data['bidAmount'],
            'currentBidder': data['bidderId'],
            'currentBidderName': data['bidderName'],
            'bidderCount': data['bidderCount'],
          });
        });
      }
    });

    // Listen for auction end
    socketService.on('auction_ended', (data) {
      if (data['auctionId'] == widget.auctionId) {
        setState(() {
          _auction = Auction.fromJson({
            ..._auction!.toJson(),
            'status': 'ended',
            'winnerAddress': data['winnerAddress'],
            'winnerName': data['winnerName'],
            'finalPrice': data['finalPrice'],
          });
        });

        _showAuctionEndDialog();
      }
    });

    // Join auction room for real-time updates
    socketService.emit('join_auction', {'auctionId': widget.auctionId});
  }

  void _disconnectRealtimeUpdates() {
    final socketService = context.read<SocketService>();
    socketService.emit('leave_auction', {'auctionId': widget.auctionId});
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_auction != null && mounted) {
        setState(() {
          _timeRemaining = _auction!.timeRemaining;
          if (_timeRemaining == Duration.zero) {
            timer.cancel();
          }
        });
      }
    });
  }

  void _showAuctionEndDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🏆 Auction Ended'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_auction?.winnerName != null)
              Text(
                'Congratulations! Your lot sold to ${_auction!.winnerName}',
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 16),
            Text(
              'Final Price: LKR ${_auction?.finalPrice?.toStringAsFixed(2) ?? "0.00"}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.forestGreen,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/farmer/home');
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: AppTheme.forestGreen,
          title: const Text('Loading Auction...'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_auction == null || _lot == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: AppTheme.forestGreen,
          title: const Text('Auction Not Found'),
        ),
        body: const Center(
          child: Text('Failed to load auction details'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppTheme.forestGreen,
        elevation: 0,
        title: const Text(
          'Live Auction',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAuctionData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status banner
              _buildStatusBanner(),
              const SizedBox(height: 20),

              // Lot details card
              _buildLotDetailsCard(),
              const SizedBox(height: 20),

              // Live bid information
              _buildLiveBidCard(),
              const SizedBox(height: 20),

              // Auction timeline
              _buildTimelineCard(),
              const SizedBox(height: 20),

              // Bidding activity
              _buildBiddingActivityCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    Color backgroundColor;
    IconData icon;
    String text;

    if (_auction!.isLive) {
      backgroundColor = Colors.green;
      icon = Icons.circle;
      text = 'LIVE AUCTION';
    } else if (_auction!.isEnded) {
      backgroundColor = Colors.orange;
      icon = Icons.timer_off;
      text = 'AUCTION ENDED';
    } else {
      backgroundColor = Colors.blue;
      icon = Icons.schedule;
      text = 'PENDING START';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLotDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Pepper Lot',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _lot!.lotId,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.forestGreen,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoColumn('Variety', _lot!.variety),
              ),
              Expanded(
                child: _buildInfoColumn('Quality', _lot!.quality),
              ),
              Expanded(
                child: _buildInfoColumn('Quantity', '${_lot!.quantity} kg'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveBidCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.forestGreen, Color(0xFF2D5016)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.forestGreen.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _auction!.currentBid != null ? 'Current Bid' : 'Starting Price',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'LKR ${(_auction!.currentBid ?? _auction!.startingPrice).toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppTheme.pepperGold,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBidStatColumn(
                Icons.people,
                '${_auction!.bidderCount}',
                'Bidders',
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildBidStatColumn(
                Icons.timer,
                _formatTimeRemaining(_timeRemaining),
                'Time Left',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Auction Timeline',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTimelineItem(
            'Started',
            _formatDateTime(_auction!.startTime),
            true,
          ),
          _buildTimelineItem(
            'Ends',
            _formatDateTime(_auction!.endTime),
            _auction!.isLive,
          ),
          if (_auction!.isEnded)
            _buildTimelineItem(
              'Settled',
              _auction!.isSettled ? 'Complete' : 'Pending',
              _auction!.isSettled,
            ),
        ],
      ),
    );
  }

  Widget _buildBiddingActivityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bidding Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_auction!.currentBid != null) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.trending_up, color: Colors.green.shade700),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Leading Bidder',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        _auction!.currentBidderName ?? 'Anonymous',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'LKR ${_auction!.currentBid!.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.forestGreen,
                  ),
                ),
              ],
            ),
          ] else ...[
            Center(
              child: Column(
                children: [
                  Icon(Icons.hourglass_empty,
                      size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Waiting for first bid...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBidStatColumn(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(String title, String time, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isActive ? AppTheme.forestGreen : Colors.grey[300],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeRemaining(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else if (duration.inSeconds > 0) {
      return '${duration.inSeconds}s';
    } else {
      return 'Ended';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
