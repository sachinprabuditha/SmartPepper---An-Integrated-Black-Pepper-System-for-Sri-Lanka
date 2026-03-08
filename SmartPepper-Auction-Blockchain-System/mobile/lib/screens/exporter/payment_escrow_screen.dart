import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:web3dart/web3dart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/blockchain_service.dart';
import '../../services/storage_service.dart';
import '../../config/theme.dart';
import '../../localization/app_localizations.dart';

class PaymentEscrowScreen extends StatefulWidget {
  final String auctionId;
  final Map<String, dynamic> auctionData;

  const PaymentEscrowScreen({
    super.key,
    required this.auctionId,
    required this.auctionData,
  });

  @override
  State<PaymentEscrowScreen> createState() => _PaymentEscrowScreenState();
}

class _PaymentEscrowScreenState extends State<PaymentEscrowScreen> {
  bool _isLoading = false;
  bool _isDepositing = false;
  String? _errorMessage;
  String? _currentStep = 'wallet'; // wallet, deposit, confirm, success
  String? _walletAddress;
  String? _walletBalance;
  String? _transactionHash;

  @override
  void initState() {
    super.initState();
    _loadWalletInfo();
  }

  Future<void> _loadWalletInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();

      _walletAddress = authProvider.user?.walletAddress;

      if (_walletAddress != null && _walletAddress!.isNotEmpty) {
        final blockchainService = context.read<BlockchainService>();
        await blockchainService.initialize();

        final balance = await blockchainService.getBalance(_walletAddress!);
        _walletBalance =
            balance.getValueInUnit(EtherUnit.ether).toStringAsFixed(4);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _depositEscrow() async {
    if (_walletAddress == null || _walletAddress!.isEmpty) {
      setState(() {
        _errorMessage = 'Please connect your wallet first';
      });
      return;
    }

    setState(() {
      _isDepositing = true;
      _errorMessage = null;
      _currentStep = 'deposit';
    });

    try {
      final storage = const FlutterSecureStorage();
      final storageService = StorageService(storage);
      final privateKey = await storageService.getPrivateKey();

      if (privateKey == null) {
        throw Exception('Private key not found. Please reconnect your wallet.');
      }

      final blockchainService = context.read<BlockchainService>();
      await blockchainService.initialize();

      // Get the winning bid amount
      final bidAmount = widget.auctionData['my_highest_bid'];
      if (bidAmount == null) {
        throw Exception('Bid amount not found');
      }

      // Convert bid amount to Wei
      final bidInEther = double.parse(bidAmount.toString());
      final bidInWei = BigInt.from(bidInEther * 1e18);

      setState(() {
        _currentStep = 'confirm';
      });

      // Call depositEscrow on the smart contract
      final txHash = await blockchainService.depositEscrow(
        privateKey: privateKey,
        auctionId: int.parse(widget.auctionId),
        amount: bidInWei,
      );

      setState(() {
        _transactionHash = txHash;
        _currentStep = 'success';
      });

      // Update backend
      final apiService = context.read<ApiService>();
      await apiService.lockEscrow(
        auctionId: widget.auctionId,
        exporterAddress: _walletAddress!,
        transactionHash: txHash,
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('payment_success')),
            backgroundColor: Colors.green,
          ),
        );
      }

      setState(() {
        _isDepositing = false;
      });

      // Navigate back after a delay
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isDepositing = false;
        _currentStep = 'wallet';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bidAmount = widget.auctionData['my_highest_bid'];
    final bidAmountLkr = widget.auctionData['my_highest_bid_lkr'];
    final variety = widget.auctionData['variety'] ?? 'Unknown';
    final quantity = widget.auctionData['quantity'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        backgroundColor: AppTheme.forestGreen,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Auction Details Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📦 Auction Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow('Variety:', variety),
                          _buildDetailRow('Quantity:', '$quantity kg'),
                          _buildDetailRow(
                              'Lot ID:', widget.auctionData['lot_id'] ?? ''),
                          const Divider(height: 24),
                          _buildDetailRow(
                            'Winning Bid:',
                            '${double.parse(bidAmount ?? '0').toStringAsFixed(4)} ETH',
                            isHighlighted: true,
                          ),
                          if (bidAmountLkr != null)
                            _buildDetailRow(
                              '',
                              '≈ LKR ${double.parse(bidAmountLkr).toStringAsFixed(2)}',
                              isSubtext: true,
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // How Escrow Works
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                '📋 How Escrow Works',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildStep('1', 'Connect your MetaMask wallet'),
                          _buildStep('2',
                              'Deposit the required escrow amount (your winning bid)'),
                          _buildStep('3',
                              'Funds are locked in the smart contract (not sent to anyone yet)'),
                          _buildStep('4',
                              'Once compliance is approved and shipment is confirmed, funds will be released to the farmer'),
                          _buildStep('5',
                              'If there are issues, escrow can be refunded to you'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Wallet Information
                  if (_walletAddress != null && _walletAddress!.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '👛 Wallet Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                                'Address:', _shortenAddress(_walletAddress!)),
                            if (_walletBalance != null)
                              _buildDetailRow(
                                  'Balance:', '$_walletBalance ETH'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Error Message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Progress Indicator
                  if (_isDepositing) ...[
                    _buildProgressStep(),
                    const SizedBox(height: 20),
                  ],

                  // Success Message
                  if (_currentStep == 'success' &&
                      _transactionHash != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green, width: 2),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 64),
                          const SizedBox(height: 12),
                          const Text(
                            '✅ Payment Successful!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Your escrow has been deposited successfully.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'TX: ${_shortenHash(_transactionHash!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Action Buttons
                  if (!_isDepositing && _currentStep != 'success') ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            _walletAddress == null || _walletAddress!.isEmpty
                                ? null
                                : _depositEscrow,
                        icon: const Icon(Icons.lock),
                        label: const Text('Deposit Escrow & Complete Payment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.pepperGold,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => context.pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isHighlighted = false, bool isSubtext = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: isSubtext ? 12 : 14,
                ),
              ),
            ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                fontSize: isHighlighted ? 18 : (isSubtext ? 12 : 14),
                color: isHighlighted
                    ? AppTheme.forestGreen
                    : (isSubtext ? Colors.grey[600] : Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStep() {
    String stepText = '';
    switch (_currentStep) {
      case 'deposit':
        stepText = 'Preparing transaction...';
        break;
      case 'confirm':
        stepText = 'Depositing escrow to smart contract...';
        break;
      default:
        stepText = 'Processing...';
    }

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              stepText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please wait while we process your payment...',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _shortenAddress(String address) {
    if (address.length <= 13) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  String _shortenHash(String hash) {
    if (hash.length <= 13) return hash;
    return '${hash.substring(0, 10)}...${hash.substring(hash.length - 8)}';
  }
}
