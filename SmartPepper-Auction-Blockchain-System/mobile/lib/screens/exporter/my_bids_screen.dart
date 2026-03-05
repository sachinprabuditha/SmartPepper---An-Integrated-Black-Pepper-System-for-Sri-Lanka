import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';
import '../../localization/app_localizations.dart';

class MyBidsScreen extends StatefulWidget {
  const MyBidsScreen({super.key});

  @override
  State<MyBidsScreen> createState() => _MyBidsScreenState();
}

class _MyBidsScreenState extends State<MyBidsScreen> {
  bool _isLoading = true;
  List<dynamic> _auctions = [];
  String _filter = 'all'; // all, active, won, lost, settled
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBids();
  }

  Future<void> _loadBids() async {
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

      setState(() {
        _auctions = response['auctions'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredAuctions {
    switch (_filter) {
      case 'active':
        return _auctions
            .where((a) => a['status'] == 'active' && a['is_leading'] == true)
            .toList();
      case 'won':
        return _auctions
            .where((a) =>
                (a['status'] == 'ended' || a['status'] == 'settled') &&
                a['is_leading'] == true)
            .toList();
      case 'lost':
        return _auctions
            .where((a) => a['status'] == 'ended' && a['is_leading'] == false)
            .toList();
      case 'settled':
        return _auctions.where((a) => a['status'] == 'settled').toList();
      default:
        return _auctions;
    }
  }

  String _getStatusBadgeText(Map<String, dynamic> auction) {
    if (auction['status'] == 'settled') {
      return 'Settled';
    } else if (auction['status'] == 'ended' && auction['is_leading'] == true) {
      return 'Won';
    } else if (auction['status'] == 'ended' && auction['is_leading'] == false) {
      return 'Lost';
    } else if (auction['status'] == 'active' && auction['is_leading'] == true) {
      return 'Leading';
    } else if (auction['status'] == 'active') {
      return 'Outbid';
    }
    return 'Unknown';
  }

  Color _getStatusBadgeColor(Map<String, dynamic> auction) {
    if (auction['status'] == 'settled') {
      return Colors.purple;
    } else if (auction['status'] == 'ended' && auction['is_leading'] == true) {
      return Colors.green;
    } else if (auction['status'] == 'ended' && auction['is_leading'] == false) {
      return Colors.grey;
    } else if (auction['status'] == 'active' && auction['is_leading'] == true) {
      return Colors.blue;
    } else if (auction['status'] == 'active') {
      return Colors.orange;
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('auction_bid_history')),
        backgroundColor: AppTheme.forestGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBids,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                      'all', context.tr('common_all'), _auctions.length),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                      'active',
                      context.tr('status_active'),
                      _auctions
                          .where((a) =>
                              a['status'] == 'active' &&
                              a['is_leading'] == true)
                          .length),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                      'won',
                      context.tr('auction_won'),
                      _auctions
                          .where((a) =>
                              (a['status'] == 'ended' ||
                                  a['status'] == 'settled') &&
                              a['is_leading'] == true)
                          .length),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                      'lost',
                      context.tr('auction_lost'),
                      _auctions
                          .where((a) =>
                              a['status'] == 'ended' &&
                              a['is_leading'] == false)
                          .length),
                  const SizedBox(width: 8),
                  _buildFilterChip('settled', context.tr('auction_settled'),
                      _auctions.where((a) => a['status'] == 'settled').length),
                ],
              ),
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
                                onPressed: _loadBids,
                                child: Text(context.tr('common_retry')),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _filteredAuctions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.gavel,
                                    size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  context.tr('empty_no_bids'),
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  context.tr('empty_browse_auctions'),
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () =>
                                      context.push('/exporter/browse'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.forestGreen,
                                  ),
                                  child: Text(context.tr('lot_all_lots')),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadBids,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredAuctions.length,
                              itemBuilder: (context, index) {
                                final auction = _filteredAuctions[index];
                                return _buildAuctionCard(auction);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, int count) {
    final isSelected = _filter == value;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filter = value;
        });
      },
      selectedColor: AppTheme.forestGreen.withOpacity(0.2),
      checkmarkColor: AppTheme.forestGreen,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.forestGreen : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildAuctionCard(Map<String, dynamic> auction) {
    final myBids = auction['my_bids'] as List? ?? [];
    final myHighestBid = auction['my_highest_bid'];
    final myHighestBidLkr = auction['my_highest_bid_lkr'];
    final isLeading = auction['is_leading'] ?? false;

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
                        Text(
                          auction['variety'] ?? 'Unknown Variety',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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
                      color: _getStatusBadgeColor(auction).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusBadgeColor(auction),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getStatusBadgeText(auction),
                      style: TextStyle(
                        color: _getStatusBadgeColor(auction),
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
                      Icons.supervisor_account,
                      'Bids',
                      '${auction['bid_count'] ?? 0}',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // My Bid Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isLeading
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isLeading ? Colors.green : Colors.orange,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLeading
                          ? '🏆 Your Highest Bid (Leading)'
                          : '💰 Your Highest Bid',
                      style: TextStyle(
                        color:
                            isLeading ? Colors.green[700] : Colors.orange[700],
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
                    const SizedBox(height: 8),
                    Text(
                      'You placed ${myBids.length} bid${myBids.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Current Status
              if (auction['status'] == 'active')
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Ends: ${_formatDateTime(auction['end_time'])}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

              // Settlement Status
              if (auction['status'] == 'settled')
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.purple, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'Payment Completed',
                        style: TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

              // Action Button
              if (auction['status'] == 'ended' && isLeading)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to payment/escrow screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Payment feature coming soon'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.pepperGold,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(context.tr('auction_complete_payment')),
                    ),
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
      return DateFormat('MMM d, y HH:mm').format(dateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }
}
