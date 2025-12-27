import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../models/lot.dart';

class LotDetailsScreen extends StatefulWidget {
  final String lotId;

  const LotDetailsScreen({super.key, required this.lotId});

  @override
  State<LotDetailsScreen> createState() => _LotDetailsScreenState();
}

class _LotDetailsScreenState extends State<LotDetailsScreen> {
  Lot? _lot;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLotDetails();
  }

  Future<void> _loadLotDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = context.read<ApiService>();
      final response = await apiService.get('/lots/${widget.lotId}');

      if (response['success'] == true && response['lot'] != null) {
        setState(() {
          _lot = Lot.fromJson(response['lot']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Lot not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2F23),
      appBar: AppBar(
        title: const Text('Lot Details'),
        backgroundColor: AppTheme.forestGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLotDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading lot details',
                        style:
                            TextStyle(fontSize: 18, color: Colors.red.shade300),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadLotDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _lot == null
                  ? const Center(child: Text('No lot data available'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Card
                          _buildHeaderCard(),
                          const SizedBox(height: 16),

                          // Details Card
                          _buildDetailsCard(),
                          const SizedBox(height: 16),

                          // Blockchain Card
                          if (_lot!.txHash != null) ...[
                            _buildBlockchainCard(),
                            const SizedBox(height: 16),
                          ],

                          // IPFS Card
                          if (_lot!.metadataURI != null ||
                              _lot!.certificateHash != null) ...[
                            _buildIPFSCard(),
                            const SizedBox(height: 16),
                          ],

                          // Status Card
                          _buildStatusCard(),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      color: AppTheme.forestGreen,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.spa, color: AppTheme.pepperGold, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _lot!.variety,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Lot ID: ${_lot!.lotId}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    Icons.scale,
                    '${_lot!.quantity} kg',
                    'Quantity',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoChip(
                    Icons.star,
                    _lot!.quality,
                    'Quality',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.deepEmerald,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.pepperGold, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      color: AppTheme.forestGreen,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lot Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Divider(color: Colors.white24, height: 24),
            _buildDetailRow(
                'Harvest Date', dateFormat.format(_lot!.harvestDate)),
            _buildDetailRow('Origin', _lot!.origin),
            _buildDetailRow('Farm Location', _lot!.farmLocation),
            _buildDetailRow('Farmer', _lot!.farmerName),
            if (_lot!.farmerAddress != null)
              _buildDetailRow(
                'Wallet Address',
                '${_lot!.farmerAddress!.substring(0, 10)}...${_lot!.farmerAddress!.substring(_lot!.farmerAddress!.length - 8)}',
              ),
            _buildDetailRow(
              'Organic Certified',
              _lot!.organicCertified ? 'Yes' : 'No',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockchainCard() {
    return Card(
      color: AppTheme.forestGreen,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.link, color: AppTheme.pepperGold),
                const SizedBox(width: 8),
                const Text(
                  'Blockchain Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 24),
            _buildDetailRow('Transaction Hash', _lot!.txHash ?? 'N/A',
                mono: true),
            if (_lot!.certificateHash != null)
              _buildDetailRow('Certificate Hash', _lot!.certificateHash!,
                  mono: true),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.sriLankanLeaf.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.sriLankanLeaf),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified, color: AppTheme.sriLankanLeaf, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'This lot is verified on the blockchain',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
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

  Widget _buildIPFSCard() {
    return Card(
      color: AppTheme.forestGreen,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storage, color: AppTheme.pepperGold),
                const SizedBox(width: 8),
                const Text(
                  'IPFS Storage',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 24),
            if (_lot!.metadataURI != null)
              _buildDetailRow('Metadata URI', _lot!.metadataURI!, mono: true),
            if (_lot!.certificateIpfsUrl != null)
              _buildDetailRow('Certificate URL', _lot!.certificateIpfsUrl!,
                  mono: true),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (_lot!.status.toLowerCase()) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Pending Approval';
        break;
      case 'approved':
        statusColor = AppTheme.sriLankanLeaf;
        statusIcon = Icons.check_circle;
        statusText = 'Approved';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Rejected';
        break;
      case 'listed':
        statusColor = Colors.blue;
        statusIcon = Icons.storefront;
        statusText = 'Listed for Auction';
        break;
      case 'sold':
        statusColor = AppTheme.pepperGold;
        statusIcon = Icons.sell;
        statusText = 'Sold';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
        statusText = _lot!.status;
    }

    return Card(
      color: statusColor.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 14,
                      color: statusColor.withOpacity(0.8),
                    ),
                  ),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  if (_lot!.rejectionReason != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Reason: ${_lot!.rejectionReason}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
