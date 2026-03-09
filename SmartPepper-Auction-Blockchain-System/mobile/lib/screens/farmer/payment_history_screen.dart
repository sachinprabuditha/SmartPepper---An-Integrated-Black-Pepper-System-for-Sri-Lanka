import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';
import 'settlement_tracking_screen.dart';
import 'package:intl/intl.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _completedAuctions = [];
  String? _error;
  String _filterStatus = 'all'; // all, settled, ended

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  Future<void> _loadPaymentHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = context.read<ApiService>();

      // Fetch all auctions for the farmer
      final response = await apiService.getAuctions();

      // Filter for completed auctions (ended or settled)
      final completed = response.where((auction) {
        final status = auction['status']?.toString().toLowerCase();
        return status == 'ended' || status == 'settled';
      }).toList();

      if (mounted) {
        setState(() {
          _completedAuctions = completed.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredAuctions() {
    if (_filterStatus == 'all') {
      return _completedAuctions;
    }
    return _completedAuctions
        .where((auction) =>
            auction['status']?.toString().toLowerCase() == _filterStatus)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.forestGreen,
        elevation: 0,
        title: const Text(
          'Payment History',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadPaymentHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : Column(
                  children: [
                    _buildSummaryCard(),
                    _buildFilterChips(),
                    Expanded(child: _buildAuctionsList()),
                  ],
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error.withOpacity(0.7)),
            const SizedBox(height: 16),
            Text(
              'Error Loading Payment History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPaymentHistory,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.forestGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalAuctions = _completedAuctions.length;
    final settledAuctions = _completedAuctions
        .where((a) => a['status']?.toString().toLowerCase() == 'settled')
        .length;

    // Calculate total earnings (ETH)
    double totalEarnings = 0.0;
    double totalEarningsLkr = 0.0;

    for (var auction in _completedAuctions) {
      if (auction['status']?.toString().toLowerCase() == 'settled') {
        final finalPrice =
            double.tryParse(auction['final_price']?.toString() ?? '0') ?? 0.0;
        final finalPriceLkr =
            double.tryParse(auction['final_price_lkr']?.toString() ?? '0') ??
                0.0;
        totalEarnings += finalPrice * 0.98; // 98% after 2% platform fee
        totalEarningsLkr += finalPriceLkr * 0.98;
      }
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.forestGreen,
            AppTheme.forestGreen.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.forestGreen.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                'Total Auctions',
                totalAuctions.toString(),
                Icons.gavel,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildSummaryItem(
                'Settled',
                settledAuctions.toString(),
                Icons.check_circle,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          Column(
            children: [
              const Text(
                'Total Earnings',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${totalEarnings.toStringAsFixed(4)} ETH',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'LKR ${NumberFormat('#,##0.00').format(totalEarningsLkr)}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
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
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('All', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('Settled', 'settled'),
          const SizedBox(width: 8),
          _buildFilterChip('Pending', 'ended'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: AppTheme.pepperGold.withOpacity(0.2),
      checkmarkColor: AppTheme.pepperGold,
      labelStyle: TextStyle(
        color: isSelected
            ? AppTheme.pepperGold
            : Theme.of(context).textTheme.bodyMedium?.color,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color:
            isSelected ? AppTheme.pepperGold : Theme.of(context).dividerColor,
      ),
    );
  }

  Widget _buildAuctionsList() {
    final filteredAuctions = _getFilteredAuctions();

    if (filteredAuctions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox,
                size: 64,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'No auctions found',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPaymentHistory,
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

  Widget _buildAuctionCard(Map<String, dynamic> auction) {
    final auctionId = auction['auction_id']?.toString() ?? 'N/A';
    final status = auction['status']?.toString().toLowerCase() ?? 'ended';
    final variety = auction['variety']?.toString() ?? 'Unknown';
    final quantity =
        double.tryParse(auction['quantity']?.toString() ?? '0') ?? 0.0;
    final finalPrice = double.tryParse(auction['final_price']?.toString() ??
            auction['current_bid']?.toString() ??
            '0') ??
        0.0;
    final finalPriceLkr = double.tryParse(
            auction['final_price_lkr']?.toString() ??
                auction['current_bid_lkr']?.toString() ??
                '0') ??
        0.0;
    final endTime =
        _parseDateFromAuction(auction['end_time']) ?? DateTime.now();
    final isSettled = status == 'settled';
    final hasWinner = auction['winner_address'] != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SettlementTrackingScreen(
                auctionId: auctionId,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      variety,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSettled
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSettled ? Colors.green : Colors.orange,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSettled
                              ? Icons.check_circle
                              : Icons.hourglass_empty,
                          size: 14,
                          color: isSettled ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isSettled ? 'SETTLED' : 'PENDING',
                          style: TextStyle(
                            color: isSettled ? Colors.green : Colors.orange,
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

              // Auction details
              Row(
                children: [
                  Icon(Icons.inventory_2,
                      size: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color),
                  const SizedBox(width: 6),
                  Text(
                    '${quantity.toStringAsFixed(0)} kg',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today,
                      size: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('MMM dd, yyyy').format(endTime),
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),

              // Price information
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasWinner ? 'Final Price' : 'No Sale',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      if (hasWinner) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${finalPrice.toStringAsFixed(4)} ETH',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.pepperGold,
                          ),
                        ),
                        Text(
                          'LKR ${NumberFormat('#,##0.00').format(finalPriceLkr)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (hasWinner)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Your Earnings (98%)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(finalPrice * 0.98).toStringAsFixed(4)} ETH',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                        Text(
                          'LKR ${NumberFormat('#,##0.00').format(finalPriceLkr * 0.98)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Action button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettlementTrackingScreen(
                          auctionId: auctionId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('View Details'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.pepperGold,
                    side: BorderSide(color: AppTheme.pepperGold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DateTime? _parseDateFromAuction(dynamic dateValue) {
    if (dateValue == null) return null;

    try {
      // If it's already a string, parse it directly
      if (dateValue is String) {
        return DateTime.parse(dateValue);
      }

      // If it's a Map (object), try to get the string value from common keys
      if (dateValue is Map) {
        // Try common date field names
        final dateStr = dateValue['\$date'] ??
            dateValue['date'] ??
            dateValue['value'] ??
            dateValue.toString();

        if (dateStr is String) {
          return DateTime.parse(dateStr);
        }

        // Handle MongoDB date format with milliseconds
        if (dateStr is Map && dateStr['\$numberLong'] != null) {
          final millis = int.tryParse(dateStr['\$numberLong'].toString());
          if (millis != null) {
            return DateTime.fromMillisecondsSinceEpoch(millis);
          }
        }
      }

      return null;
    } catch (e) {
      print('Error parsing date: $e');
      return null;
    }
  }
}
