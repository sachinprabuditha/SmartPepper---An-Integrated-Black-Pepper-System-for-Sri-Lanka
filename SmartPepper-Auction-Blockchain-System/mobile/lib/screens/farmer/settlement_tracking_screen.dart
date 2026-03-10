import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'receipt_screen.dart';
import 'create_lot_screen.dart';

class SettlementTrackingScreen extends StatefulWidget {
  final String auctionId;

  const SettlementTrackingScreen({
    super.key,
    required this.auctionId,
  });

  @override
  State<SettlementTrackingScreen> createState() =>
      _SettlementTrackingScreenState();
}

class _SettlementTrackingScreenState extends State<SettlementTrackingScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _settlementData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSettlementStatus();
  }

  Future<void> _loadSettlementStatus() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = context.read<ApiService>();
      final response = await apiService.get(
        '/auctions/${widget.auctionId}/settlement-status',
      );

      if (mounted) {
        setState(() {
          _settlementData = response['settlement'];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.forestGreen,
        elevation: 0,
        title: const Text(
          'Settlement Tracking',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadSettlementStatus,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildSettlementContent(),
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
              'Error Loading Settlement Data',
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
              onPressed: _loadSettlementStatus,
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

  Widget _buildSettlementContent() {
    if (_settlementData == null) {
      return const Center(child: Text('No settlement data available'));
    }

    final settlementStatus = _settlementData!['settlementStatus'] as String?;
    final finalized = _settlementData!['finalized'] as bool? ?? false;
    final blockchainFinalized =
        _settlementData!['blockchainFinalized'] as bool? ?? false;

    return RefreshIndicator(
      onRefresh: _loadSettlementStatus,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Overview Card
            _buildStatusOverviewCard(settlementStatus, finalized),
            const SizedBox(height: 16),

            // Settlement Timeline
            _buildSettlementTimeline(settlementStatus, blockchainFinalized),
            const SizedBox(height: 16),

            // Price Details Card
            _buildPriceDetailsCard(),
            const SizedBox(height: 16),

            // Winner Information
            if (_settlementData!['winner'] != null) _buildWinnerInfoCard(),
            const SizedBox(height: 16),

            // Blockchain Transactions
            _buildBlockchainTransactionsCard(),
            const SizedBox(height: 16),

            // Actions
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOverviewCard(String? settlementStatus, bool finalized) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    String statusDescription;

    switch (settlementStatus) {
      case 'pending_escrow':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Awaiting Escrow';
        statusDescription = 'Waiting for winner to deposit escrow payment';
        break;
      case 'escrow_received':
        statusColor = Colors.blue;
        statusIcon = Icons.account_balance_wallet;
        statusText = 'Escrow Received';
        statusDescription = 'Escrow deposited, awaiting admin approval';
        break;
      case 'approved_for_settlement':
        statusColor = Colors.teal;
        statusIcon = Icons.verified_user;
        statusText = 'Approved for Settlement';
        statusDescription =
            'Admin approved. Processing final payment distribution';
        break;
      case 'settled':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Settled';
        statusDescription = 'Payment has been distributed to your wallet';
        break;
      case 'no_winner':
        statusColor = Colors.grey;
        statusIcon = Icons.cancel;
        statusText = 'No Sale';
        statusDescription = 'Auction ended without meeting reserve price';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
        statusText = 'Unknown Status';
        statusDescription = 'Settlement status is not available';
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              statusColor.withOpacity(0.1),
              AppTheme.forestGreen,
            ],
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, size: 48, color: statusColor),
            ),
            const SizedBox(height: 16),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              statusDescription,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            if (finalized) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 16, color: Colors.green[700]),
                    const SizedBox(width: 6),
                    Text(
                      'Finalized',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettlementTimeline(
      String? settlementStatus, bool blockchainFinalized) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settlement Timeline',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 20),
            _buildTimelineStep(
              'Auction Ended',
              _parseDateFromSettlement(_settlementData!['finalizedAt']),
              true,
              Icons.gavel,
              Colors.green,
            ),
            _buildTimelineStep(
              'Blockchain Finalized',
              null,
              blockchainFinalized,
              Icons.link,
              blockchainFinalized ? Colors.green : Colors.grey,
            ),
            _buildTimelineStep(
              'Escrow Deposit',
              null,
              settlementStatus == 'escrow_received' ||
                  settlementStatus == 'approved_for_settlement' ||
                  settlementStatus == 'settled',
              Icons.account_balance_wallet,
              settlementStatus == 'escrow_received' ||
                      settlementStatus == 'approved_for_settlement' ||
                      settlementStatus == 'settled'
                  ? Colors.green
                  : Colors.grey,
            ),
            _buildTimelineStep(
              'Funds Distributed',
              _parseDateFromSettlement(_settlementData!['settledAt']),
              settlementStatus == 'settled',
              Icons.payments,
              settlementStatus == 'settled' ? Colors.green : Colors.grey,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep(
    String title,
    DateTime? timestamp,
    bool completed,
    IconData icon,
    Color color, {
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: completed ? color : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                completed ? Icons.check : icon,
                size: 20,
                color: Colors.white,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: completed ? color : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: completed
                      ? Theme.of(context).textTheme.bodyLarge?.color
                      : Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.6),
                ),
              ),
              if (timestamp != null) ...[
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
              if (!isLast) const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceDetailsCard() {
    final finalPrice = _settlementData!['finalPrice'] as Map<String, dynamic>?;
    if (finalPrice == null) return const SizedBox.shrink();

    final ethPrice =
        double.tryParse(finalPrice['eth']?.toString() ?? '0') ?? 0.0;
    final lkrPrice =
        double.tryParse(finalPrice['lkr']?.toString() ?? '0') ?? 0.0;
    final platformFee = ethPrice * 0.02;
    final farmerAmount = ethPrice * 0.98;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Price Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            _buildPriceRow('Final Bid', ethPrice, lkrPrice, isHighlight: true),
            const Divider(height: 24),
            _buildPriceRow('Platform Fee (2%)', platformFee, lkrPrice * 0.02),
            const SizedBox(height: 12),
            _buildPriceRow('Your Earnings (98%)', farmerAmount, lkrPrice * 0.98,
                isEarnings: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double eth, double lkr,
      {bool isHighlight = false, bool isEarnings = false}) {
    return Container(
      padding: isEarnings ? const EdgeInsets.all(12) : EdgeInsets.zero,
      decoration: isEarnings
          ? BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.4)),
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isHighlight || isEarnings ? 16 : 14,
              fontWeight: isHighlight || isEarnings
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: isEarnings
                  ? Colors.green
                  : Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${eth.toStringAsFixed(4)} ETH',
                style: TextStyle(
                  fontSize: isHighlight || isEarnings ? 18 : 14,
                  fontWeight: isHighlight || isEarnings
                      ? FontWeight.bold
                      : FontWeight.w600,
                  color: isEarnings
                      ? Colors.green
                      : isHighlight
                          ? AppTheme.pepperGold
                          : Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              Text(
                'LKR ${lkr.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWinnerInfoCard() {
    final winner = _settlementData!['winner'] as String?;
    if (winner == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Winner Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.pepperGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: AppTheme.pepperGold,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Winning Bidder',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              winner,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'monospace',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: winner));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Address copied!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockchainTransactionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Blockchain Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            if (_settlementData!['blockchainFinalizationTx'] != null)
              _buildTransactionRow(
                'Finalization',
                _settlementData!['blockchainFinalizationTx'] as String,
                Icons.gavel,
              ),
            if (_settlementData!['escrowTxHash'] != null)
              _buildTransactionRow(
                'Escrow Deposit',
                _settlementData!['escrowTxHash'] as String,
                Icons.account_balance_wallet,
              ),
            if (_settlementData!['settlementTxHash'] != null)
              _buildTransactionRow(
                'Settlement',
                _settlementData!['settlementTxHash'] as String,
                Icons.payments,
              ),
            if (_settlementData!['blockchainFinalizationTx'] == null &&
                _settlementData!['escrowTxHash'] == null &&
                _settlementData!['settlementTxHash'] == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No blockchain transactions yet',
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionRow(String label, String txHash, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.forestGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppTheme.forestGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${txHash.substring(0, 10)}...${txHash.substring(txHash.length - 8)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new, size: 20),
            onPressed: () => _openBlockchainExplorer(txHash),
            tooltip: 'View on Explorer',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final settlementStatus = _settlementData!['settlementStatus'] as String?;

    return Column(
      children: [
        if (settlementStatus == 'settled')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReceiptScreen(
                      settlementData: _settlementData!,
                      auctionId: widget.auctionId,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.receipt_long),
              label: const Text('View Receipt'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.forestGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        if (settlementStatus == 'no_winner') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showRelistDialog(context),
              icon: const Icon(Icons.refresh),
              label: const Text('Re-list Auction'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showRelistDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.refresh, color: AppTheme.pepperGold),
            const SizedBox(width: 12),
            const Text('Re-list Auction'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This auction ended without a sale. Would you like to:',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '• Create a new auction with the same lot',
              style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
            Text(
              '• Adjust reserve price if needed',
              style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
            Text(
              '• Set new auction timing',
              style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _navigateToCreateLot(context);
            },
            icon: const Icon(Icons.add),
            label: const Text('Create New Lot'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.pepperGold,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCreateLot(BuildContext context) {
    // Get lot details from settlement data if available
    final lotDetails = _settlementData?['lotDetails'] as Map<String, dynamic>?;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateLotScreen(
          prefillData: lotDetails != null
              ? {
                  'variety': lotDetails['variety'],
                  'quantity': lotDetails['quantity'],
                  'quality': lotDetails['quality'],
                }
              : null,
        ),
      ),
    ).then((created) {
      if (created == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New lot created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate back to lots screen
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  Future<void> _openBlockchainExplorer(String txHash) async {
    // TODO: Get the correct explorer URL from config
    final explorerUrl = 'https://sepolia.etherscan.io/tx/$txHash';
    final uri = Uri.parse(explorerUrl);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open blockchain explorer')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  DateTime? _parseDateFromSettlement(dynamic dateValue) {
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
