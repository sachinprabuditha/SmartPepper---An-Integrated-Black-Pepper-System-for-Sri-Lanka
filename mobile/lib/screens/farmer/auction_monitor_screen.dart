import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/auction_provider.dart';
import '../../providers/auth_provider.dart';
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

      // Fetch all auctions and find the one we need
      final auctionsResponse = await apiService.getAuctions();
      final auction = auctionsResponse.firstWhere(
        (a) => Auction.fromJson(a).auctionId == widget.auctionId,
        orElse: () => throw Exception('Auction not found'),
      );
      final auctionObj = Auction.fromJson(auction);

      // Fetch lot details
      final lotsResponse = await apiService.getLots();
      final lotData = lotsResponse.firstWhere(
        (l) => Lot.fromJson(l).lotId == auctionObj.lotId,
        orElse: () => throw Exception('Lot not found'),
      );
      final lot = Lot.fromJson(lotData);

      if (mounted) {
        setState(() {
          _auction = auctionObj;
          _lot = lot;
          // Calculate time remaining
          _timeRemaining = auctionObj.endTime.difference(DateTime.now());
          if (_timeRemaining.isNegative) {
            _timeRemaining = Duration.zero;
          }
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

    // Listen for bid updates (backend emits 'new_bid')
    socketService.on('new_bid', (data) {
      print('📡 Received new_bid event: $data');
      if (!mounted) return; // Check if widget is still mounted

      if (data['auctionId'] == widget.auctionId ||
          data['auctionId'].toString() == _auction?.auctionId) {
        setState(() {
          if (_auction != null) {
            // Backend sends 'amount' (ETH) and 'amountLkr' fields
            final bidAmount = data['amount'] ?? data['bidAmount'];
            final bidAmountLkr = data['amountLkr'];
            _auction = Auction(
              id: _auction!.id,
              auctionId: _auction!.auctionId,
              tokenId: _auction!.tokenId,
              lotId: _auction!.lotId,
              farmerAddress: _auction!.farmerAddress,
              startingPrice: _auction!.startingPrice,
              currentBid: double.tryParse(bidAmount?.toString() ?? '0') ??
                  _auction!.currentBid,
              currentBidLkr: double.tryParse(bidAmountLkr?.toString() ?? '0') ??
                  _auction!.currentBidLkr,
              highestBidder: data['bidder']?.toString() ??
                  data['bidderId']?.toString() ??
                  _auction!.highestBidder,
              startTime: _auction!.startTime,
              endTime: _auction!.endTime,
              status: _auction!.status,
              variety: _auction!.variety,
              quantity: _auction!.quantity,
              blockchainTxHash: _auction!.blockchainTxHash,
              compliancePassed: _auction!.compliancePassed,
            );
          }
        });
      }
    });

    // Listen for auction end
    socketService.on('auction_ended', (data) {
      print('🏁 Received auction_ended event: $data');
      if (!mounted) return; // Check if widget is still mounted

      if (data['auctionId'] == widget.auctionId ||
          data['auctionId'].toString() == _auction?.auctionId) {
        setState(() {
          if (_auction != null) {
            _auction = Auction(
              id: _auction!.id,
              auctionId: _auction!.auctionId,
              tokenId: _auction!.tokenId,
              lotId: _auction!.lotId,
              farmerAddress: _auction!.farmerAddress,
              startingPrice: _auction!.startingPrice,
              currentBid:
                  double.tryParse(data['finalPrice']?.toString() ?? '0') ??
                      _auction!.currentBid,
              highestBidder:
                  data['winnerAddress']?.toString() ?? _auction!.highestBidder,
              startTime: _auction!.startTime,
              endTime: _auction!.endTime,
              status: 'ended',
              variety: _auction!.variety,
              quantity: _auction!.quantity,
              blockchainTxHash: _auction!.blockchainTxHash,
              compliancePassed: _auction!.compliancePassed,
            );
          }
        });

        _showAuctionEndDialog(
            data['winnerName']?.toString(), data['finalPrice']);
      }
    });

    // Listen for auction joined confirmation
    socketService.on('auction_joined', (data) {
      print('✅ Successfully joined auction room: ${data['auctionId']}');
    });

    // Join auction room for real-time updates
    print('📡 Joining auction room: ${widget.auctionId}');
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
          // Calculate time remaining from endTime
          _timeRemaining = _auction!.endTime.difference(DateTime.now());
          if (_timeRemaining.isNegative) {
            _timeRemaining = Duration.zero;
            timer.cancel();
          }
        });
      }
    });
  }

  void _showAuctionEndDialog(String? winnerName, dynamic finalPrice) {
    final finalPriceDouble =
        double.tryParse(finalPrice?.toString() ?? '0') ?? 0.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🏆 Auction Ended'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (winnerName != null)
              Text(
                'Congratulations! Your lot sold to $winnerName',
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 16),
            Text(
              'Final Price: \$${finalPriceDouble.toStringAsFixed(2)}',
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
              Navigator.pop(context); // Go back to auctions list
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestEmergencyCancellation() async {
    // Show reason selection dialog
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _EmergencyCancellationDialog(),
    );

    if (reason == null || reason.isEmpty) return;

    try {
      final apiService = context.read<ApiService>();
      final authProvider = context.read<AuthProvider>();

      await apiService.post('/auctions/request-cancellation', {
        'auctionId': widget.auctionId,
        'reason': reason,
        'farmerAddress': authProvider.user?.walletAddress ?? '',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cancellation request submitted. Admin will review.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        actions: [
          // Emergency cancellation button
          if (_auction!.status == 'created' || _auction!.status == 'active')
            IconButton(
              icon: const Icon(Icons.cancel_outlined, color: Colors.white),
              tooltip: 'Request Cancellation',
              onPressed: _requestEmergencyCancellation,
            ),
        ],
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

    if (_auction!.status == 'active') {
      backgroundColor = Colors.green;
      icon = Icons.circle;
      text = 'LIVE AUCTION';
    } else if (_auction!.status == 'ended') {
      backgroundColor = Colors.orange;
      icon = Icons.timer_off;
      text = 'AUCTION ENDED';
    } else if (_auction!.status == 'pending_approval') {
      backgroundColor = Colors.orange;
      icon = Icons.hourglass_empty;
      text = 'PENDING ADMIN APPROVAL';
    } else if (_auction!.status == 'created') {
      // Calculate time until start
      final timeUntilStart = _auction!.startTime.difference(DateTime.now());
      if (timeUntilStart.inMinutes <= 5 && timeUntilStart.inSeconds > 0) {
        backgroundColor = Colors.green.shade600;
        icon = Icons.schedule;
        text =
            'STARTING SOON (${timeUntilStart.inMinutes}m ${timeUntilStart.inSeconds % 60}s)';
      } else {
        backgroundColor = Colors.blue;
        icon = Icons.schedule;
        text = 'SCHEDULED - STARTS ${_formatDateTime(_auction!.startTime)}';
      }
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
            'LKR ${(_auction!.currentBidLkr ?? (_auction!.currentBid ?? _auction!.startingPrice) * 322580.65).toStringAsFixed(2)}',
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
                _auction!.currentBid != null ? '1+' : '0',
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
            _auction!.status == 'active',
          ),
          if (_auction!.status == 'ended')
            _buildTimelineItem(
              'Settled',
              _auction!.status == 'settled' ? 'Complete' : 'Pending',
              _auction!.status == 'settled',
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
                        _auction!.highestBidder ?? 'Anonymous',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'LKR ${(_auction!.currentBidLkr ?? _auction!.currentBid! * 322580.65).toStringAsFixed(2)}',
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

/// Dialog for requesting emergency cancellation with predefined reasons
class _EmergencyCancellationDialog extends StatefulWidget {
  @override
  State<_EmergencyCancellationDialog> createState() =>
      __EmergencyCancellationDialogState();
}

class __EmergencyCancellationDialogState
    extends State<_EmergencyCancellationDialog> {
  final _reasonController = TextEditingController();
  String _selectedReason = '';

  final List<String> _predefinedReasons = [
    'Quality issue discovered',
    'Lot damaged or compromised',
    'Error in lot details',
    'Force majeure (natural disaster, etc.)',
    'Other',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Request Emergency Cancellation'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚠️ Emergency cancellations require admin approval',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
              items: _predefinedReasons
                  .map((reason) => DropdownMenuItem(
                        value: reason,
                        child: Text(reason),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedReason = value!);
              },
            ),
            if (_selectedReason == 'Other') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Please specify',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedReason.isEmpty
              ? null
              : () {
                  final reason = _selectedReason == 'Other'
                      ? _reasonController.text
                      : _selectedReason;
                  if (reason.isEmpty) return;
                  Navigator.pop(context, reason);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            disabledBackgroundColor: Colors.grey,
          ),
          child: const Text('Submit Request'),
        ),
      ],
    );
  }
}
