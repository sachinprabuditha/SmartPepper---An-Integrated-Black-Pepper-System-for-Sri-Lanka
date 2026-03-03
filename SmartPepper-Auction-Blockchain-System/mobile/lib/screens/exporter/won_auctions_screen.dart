import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';

class WonAuctionsScreen extends StatefulWidget {
  const WonAuctionsScreen({super.key});

  @override
  State<WonAuctionsScreen> createState() => _WonAuctionsScreenState();
}

class _WonAuctionsScreenState extends State<WonAuctionsScreen> {
  bool _isLoading = true;
  List<dynamic> _wonAuctions = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWonAuctions();
  }

  Future<void> _loadWonAuctions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final apiService = context.read<ApiService>();

      if (authProvider.user?.id == null) {
        setState(() {
          _errorMessage = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      final response = await apiService.getUserBids(authProvider.user!.id);

      // Filter for won auctions only (ended or settled + leading)
      final allAuctions = response['auctions'] as List? ?? [];
      final wonAuctions = allAuctions.where((auction) {
        final status = auction['status'];
        final isLeading = auction['is_leading'] ?? false;
        return (status == 'ended' || status == 'settled') && isLeading;
      }).toList();

      setState(() {
        _wonAuctions = wonAuctions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  int get _pendingPaymentCount {
    return _wonAuctions.where((a) => a['status'] == 'ended').length;
  }

  int get _completedCount {
    return _wonAuctions.where((a) => a['status'] == 'settled').length;
  }

  double get _totalSpent {
    return _wonAuctions.fold(0.0, (sum, auction) {
      final bid = auction['my_highest_bid'];
      if (bid == null) return sum;
      return sum + double.parse(bid.toString());
    });
  }

  double get _totalSpentLkr {
    return _wonAuctions.fold(0.0, (sum, auction) {
      final bidLkr = auction['my_highest_bid_lkr'];
      if (bidLkr == null) return sum;
      return sum + double.parse(bidLkr.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Won Auctions'),
        backgroundColor: AppTheme.forestGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWonAuctions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Summary
          if (!_isLoading && _errorMessage == null)
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.forestGreen.withOpacity(0.1),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          '🏆',
                          'Total Won',
                          '${_wonAuctions.length}',
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          '⏳',
                          'Pending Payment',
                          '$_pendingPaymentCount',
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          '✅',
                          'Completed',
                          '$_completedCount',
                          Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          '💰',
                          'Total Spent',
                          '${_totalSpent.toStringAsFixed(4)} ETH',
                          Colors.blue,
                          subtitle:
                              '≈ LKR ${_totalSpentLkr.toStringAsFixed(2)}',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 64, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadWonAuctions,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _wonAuctions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.emoji_events,
                                    size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No won auctions yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Win your first auction to see it here',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () =>
                                      context.push('/exporter/browse'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.forestGreen,
                                  ),
                                  child: const Text('Browse Auctions'),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadWonAuctions,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _wonAuctions.length,
                              itemBuilder: (context, index) {
                                final auction = _wonAuctions[index];
                                return _buildWonAuctionCard(auction);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String emoji,
    String label,
    String value,
    Color color, {
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWonAuctionCard(Map<String, dynamic> auction) {
    final myHighestBid = auction['my_highest_bid'];
    final myHighestBidLkr = auction['my_highest_bid_lkr'];
    final isSettled = auction['status'] == 'settled';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () {
          context.push('/exporter/auction/${auction['auction_id']}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              '🏆 ',
                              style: TextStyle(fontSize: 20),
                            ),
                            Expanded(
                              child: Text(
                                auction['variety'] ?? 'Unknown Variety',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Lot #${auction['lot_id']}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
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
                      color: isSettled
                          ? Colors.purple.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSettled ? Colors.purple : Colors.orange,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      isSettled ? 'Settled' : 'Payment Pending',
                      style: TextStyle(
                        color: isSettled ? Colors.purple : Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),

              // Auction Info
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.scale,
                      'Quantity',
                      '${auction['quantity']} kg',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.access_time,
                      'Ended',
                      _formatDateTime(auction['end_time']),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Winning Bid
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🎉 Winning Bid',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${double.parse(myHighestBid ?? '0').toStringAsFixed(4)} ETH',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (myHighestBidLkr != null)
                      Text(
                        '≈ LKR ${double.parse(myHighestBidLkr).toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),

              // Settlement Status
              if (isSettled)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.purple, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment Completed',
                              style: TextStyle(
                                color: Colors.purple,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Awaiting delivery confirmation',
                              style: TextStyle(
                                color: Colors.purple,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Action Buttons
              if (!isSettled)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to payment/escrow screen
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Payment feature coming soon'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.payment),
                          label: const Text('Complete Payment'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.pepperGold,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          context.push(
                              '/exporter/auction/${auction['auction_id']}');
                        },
                        icon: const Icon(Icons.arrow_forward),
                        tooltip: 'View Details',
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'Unknown';
    try {
      final DateTime dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('MMM d, HH:mm').format(dateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }
}
