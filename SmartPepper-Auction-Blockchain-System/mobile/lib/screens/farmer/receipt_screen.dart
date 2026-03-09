import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/theme.dart';

class ReceiptScreen extends StatelessWidget {
  final Map<String, dynamic> settlementData;
  final String auctionId;

  const ReceiptScreen({
    super.key,
    required this.settlementData,
    required this.auctionId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.forestGreen,
        elevation: 0,
        title: const Text(
          'Settlement Receipt',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () => _shareReceipt(context),
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () => _downloadReceipt(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildReceiptCard(context),
            const SizedBox(height: 20),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptCard(BuildContext context) {
    final finalPrice = settlementData['finalPrice'] as Map<String, dynamic>?;
    final ethPrice =
        double.tryParse(finalPrice?['eth']?.toString() ?? '0') ?? 0.0;
    final lkrPrice =
        double.tryParse(finalPrice?['lkr']?.toString() ?? '0') ?? 0.0;
    final platformFee = ethPrice * 0.02;
    final farmerEarnings = ethPrice * 0.98;
    final platformFeeLkr = lkrPrice * 0.02;
    final farmerEarningsLkr = lkrPrice * 0.98;

    final settledAt = _parseDateFromSettlement(settlementData['settledAt']);
    final winner = settlementData['winner'] as String?;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 64,
                    color: AppTheme.pepperGold,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'SETTLEMENT RECEIPT',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.forestGreen,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, size: 16, color: Colors.green),
                        const SizedBox(width: 6),
                        Text(
                          'PAID',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(thickness: 2),
            const SizedBox(height: 16),

            // Transaction Details
            _buildReceiptRow(
                'Receipt #', auctionId.substring(0, 8).toUpperCase(),
                isBold: true),
            const SizedBox(height: 12),
            _buildReceiptRow(
              'Settlement Date',
              settledAt != null ? _formatDate(settledAt) : 'N/A',
            ),

            if (winner != null) ...[
              const SizedBox(height: 12),
              _buildReceiptRow('Buyer Address', winner,
                  isMonospace: true, isSmall: true),
            ],

            const SizedBox(height: 20),
            const Divider(thickness: 2),
            const SizedBox(height: 16),

            // Price Breakdown
            Text(
              'PRICE BREAKDOWN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.forestGreen,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 16),

            _buildPriceRow('Final Bid Price', ethPrice, lkrPrice),
            const SizedBox(height: 12),
            _buildPriceRow('Platform Fee (2%)', platformFee, platformFeeLkr,
                isNegative: true),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            _buildPriceRow(
                'Your Earnings (98%)', farmerEarnings, farmerEarningsLkr,
                isTotal: true),

            const SizedBox(height: 20),
            const Divider(thickness: 2),
            const SizedBox(height: 16),

            // Blockchain Verification
            if (settlementData['settlementTxHash'] != null) ...[
              Text(
                'BLOCKCHAIN VERIFICATION',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.forestGreen,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              _buildTransactionInfo(
                'Settlement TX',
                settlementData['settlementTxHash'] as String,
                context,
              ),
            ],

            const SizedBox(height: 20),
            const Divider(thickness: 2),
            const SizedBox(height: 16),

            // Footer
            Center(
              child: Column(
                children: [
                  Text(
                    'SmartPepper Auction Platform',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Blockchain-Verified Pepper Trading',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Generated on ${_formatDate(DateTime.now())}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value,
      {bool isBold = false, bool isMonospace = false, bool isSmall = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: isSmall ? 12 : 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontSize: isSmall ? 11 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontFamily: isMonospace ? 'monospace' : null,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, double eth, double lkr,
      {bool isNegative = false, bool isTotal = false}) {
    return Container(
      padding: isTotal ? const EdgeInsets.all(12) : EdgeInsets.zero,
      decoration: isTotal
          ? BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? Colors.green[900] : Colors.black87,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isNegative ? '-' : ''}${eth.toStringAsFixed(4)} ETH',
                style: TextStyle(
                  fontSize: isTotal ? 18 : 14,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                  color: isTotal
                      ? Colors.green[700]
                      : isNegative
                          ? Colors.red[700]
                          : Colors.black87,
                ),
              ),
              Text(
                '${isNegative ? '-' : ''}LKR ${NumberFormat('#,##0.00').format(lkr)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionInfo(
      String label, String txHash, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.link, size: 16, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${txHash.substring(0, 10)}...${txHash.substring(txHash.length - 8)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.copy, size: 18, color: Colors.blue[700]),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: txHash));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transaction hash copied!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _copyReceiptText(context),
            icon: const Icon(Icons.content_copy),
            label: const Text('Copy Receipt Details'),
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
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _shareReceipt(context),
            icon: const Icon(Icons.share),
            label: const Text('Share Receipt'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.pepperGold,
              side: BorderSide(color: AppTheme.pepperGold),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _copyReceiptText(BuildContext context) {
    final finalPrice = settlementData['finalPrice'] as Map<String, dynamic>?;
    final ethPrice =
        double.tryParse(finalPrice?['eth']?.toString() ?? '0') ?? 0.0;
    final lkrPrice =
        double.tryParse(finalPrice?['lkr']?.toString() ?? '0') ?? 0.0;
    final farmerEarnings = ethPrice * 0.98;
    final farmerEarningsLkr = lkrPrice * 0.98;
    final settledAt = _parseDateFromSettlement(settlementData['settledAt']);

    final receiptText = '''
═══════════════════════════
  SMARTPEPPER RECEIPT
═══════════════════════════

Receipt #: ${auctionId.substring(0, 8).toUpperCase()}
Date: ${settledAt != null ? _formatDate(settledAt) : 'N/A'}
Status: PAID ✓

─────────────────────────────
PRICE BREAKDOWN
─────────────────────────────

Final Bid: ${ethPrice.toStringAsFixed(4)} ETH
          (LKR ${NumberFormat('#,##0.00').format(lkrPrice)})

Platform Fee (2%): -${(ethPrice * 0.02).toStringAsFixed(4)} ETH
                   (-LKR ${NumberFormat('#,##0.00').format(lkrPrice * 0.02)})

─────────────────────────────
YOUR EARNINGS: ${farmerEarnings.toStringAsFixed(4)} ETH
              LKR ${NumberFormat('#,##0.00').format(farmerEarningsLkr)}
─────────────────────────────

${settlementData['settlementTxHash'] != null ? '''
Blockchain TX:
${settlementData['settlementTxHash']}
''' : ''}
SmartPepper Auction Platform
Blockchain-Verified Trading
Generated: ${_formatDate(DateTime.now())}
═══════════════════════════
''';

    Clipboard.setData(ClipboardData(text: receiptText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt details copied to clipboard!'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _shareReceipt(BuildContext context) {
    final finalPrice = settlementData['finalPrice'] as Map<String, dynamic>?;
    final ethPrice =
        double.tryParse(finalPrice?['eth']?.toString() ?? '0') ?? 0.0;
    final lkrPrice =
        double.tryParse(finalPrice?['lkr']?.toString() ?? '0') ?? 0.0;
    final farmerEarnings = ethPrice * 0.98;
    final farmerEarningsLkr = lkrPrice * 0.98;

    final shareText = '''
SmartPepper Receipt #${auctionId.substring(0, 8).toUpperCase()}

✅ Payment Settled
💰 Your Earnings: ${farmerEarnings.toStringAsFixed(4)} ETH (LKR ${NumberFormat('#,##0.00').format(farmerEarningsLkr)})

Blockchain-verified pepper auction transaction.
''';

    Share.share(shareText, subject: 'SmartPepper Settlement Receipt');
  }

  void _downloadReceipt(BuildContext context) {
    // For now, just show a message. Full PDF generation can be added with pdf package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt saved to gallery! (Feature coming soon)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  DateTime? _parseDateFromSettlement(dynamic dateValue) {
    if (dateValue == null) return null;

    try {
      if (dateValue is String) {
        return DateTime.parse(dateValue);
      }

      if (dateValue is Map) {
        final dateStr = dateValue['\$date'] ??
            dateValue['date'] ??
            dateValue['value'] ??
            dateValue.toString();

        if (dateStr is String) {
          return DateTime.parse(dateStr);
        }

        if (dateStr is Map && dateStr['\$numberLong'] != null) {
          final millis = int.tryParse(dateStr['\$numberLong'].toString());
          if (millis != null) {
            return DateTime.fromMillisecondsSinceEpoch(millis);
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy • HH:mm').format(date);
  }
}
