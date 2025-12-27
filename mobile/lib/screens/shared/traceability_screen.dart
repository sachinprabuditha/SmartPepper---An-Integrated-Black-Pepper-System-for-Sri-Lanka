import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class TraceabilityScreen extends StatefulWidget {
  final String lotId;

  const TraceabilityScreen({super.key, required this.lotId});

  @override
  State<TraceabilityScreen> createState() => _TraceabilityScreenState();
}

class _TraceabilityScreenState extends State<TraceabilityScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _traceabilityData;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _fetchTraceability();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchTraceability() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final apiService = ApiService();
      final response = await apiService.get('/traceability/${widget.lotId}');

      if (response['success'] == true) {
        setState(() {
          _traceabilityData = response;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['error'] ?? 'Failed to load traceability';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        backgroundColor: AppTheme.forestGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blockchain Traceability'),
        elevation: 0,
        bottom: _isLoading
            ? null
            : TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Timeline'),
                  Tab(text: 'Processing'),
                  Tab(text: 'Certificates'),
                  Tab(text: 'Compliance'),
                  Tab(text: 'Blockchain'),
                ],
              ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading traceability records...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchTraceability,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildTimelineTab(),
        _buildProcessingTab(),
        _buildCertificatesTab(),
        _buildComplianceTab(),
        _buildBlockchainTab(),
      ],
    );
  }

  Widget _buildTimelineTab() {
    final timeline = _traceabilityData?['timeline'] as List? ?? [];
    final stats = _traceabilityData?['statistics'] ?? {};

    return Column(
      children: [
        // Statistics Card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.forestGreen, AppTheme.pepperGold],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Text(
                'Traceability Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                      'Events', stats['total_events']?.toString() ?? '0'),
                  _buildStatItem('Blockchain TX',
                      stats['blockchain_transactions']?.toString() ?? '0'),
                  _buildStatItem(
                      'Days', stats['days_in_system']?.toString() ?? '0'),
                ],
              ),
            ],
          ),
        ),

        // Timeline List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: timeline.length,
            itemBuilder: (context, index) {
              final event =
                  timeline[timeline.length - 1 - index]; // Reverse order
              return _buildTimelineItem(event, index == timeline.length - 1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
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
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> event, bool isFirst) {
    final type = event['type'] as String? ?? '';
    final description = event['description'] as String? ?? '';
    final timestamp = event['timestamp'] as String? ?? '';
    final actorName = event['actor_name'] as String? ?? '';
    final blockchainTx = event['blockchain_tx'] as String?;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getEventColor(type),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getEventIcon(type),
                color: Colors.white,
                size: 20,
              ),
            ),
            if (!isFirst)
              Container(
                width: 2,
                height: 60,
                color: Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        description,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (blockchainTx != null && blockchainTx.isNotEmpty)
                      const Icon(Icons.verified,
                          color: AppTheme.forestGreen, size: 16),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'By: $actorName',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  _formatTimestamp(timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                if (blockchainTx != null && blockchainTx.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () =>
                        _copyToClipboard(blockchainTx, 'Transaction hash'),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.link, size: 14, color: Colors.blue),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${blockchainTx.substring(0, 10)}...${blockchainTx.substring(blockchainTx.length - 8)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          const Icon(Icons.copy, size: 14, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingTab() {
    final stages = _traceabilityData?['processing_stages'] as List? ?? [];

    if (stages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No processing stages recorded'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: stages.length,
      itemBuilder: (context, index) {
        final stage = stages[index];
        return _buildProcessingCard(stage);
      },
    );
  }

  Widget _buildProcessingCard(Map<String, dynamic> stage) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getStageIcon(stage['stage_type']),
                    color: AppTheme.forestGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stage['stage_name'] ?? 'Unknown Stage',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Location', stage['location'] ?? 'N/A'),
            _buildInfoRow('Operator', stage['operator_name'] ?? 'N/A'),
            _buildInfoRow('Time', _formatTimestamp(stage['timestamp'])),
            if (stage['notes'] != null && stage['notes'].toString().isNotEmpty)
              _buildInfoRow('Notes', stage['notes']),
            if (stage['blockchain_tx_hash'] != null &&
                stage['blockchain_tx_hash'].toString().isNotEmpty)
              InkWell(
                onTap: () => _copyToClipboard(
                    stage['blockchain_tx_hash'], 'Transaction hash'),
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified,
                          size: 16, color: AppTheme.forestGreen),
                      const SizedBox(width: 4),
                      const Text('Blockchain verified',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.forestGreen)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificatesTab() {
    final certs = _traceabilityData?['certifications'] as List? ?? [];

    if (certs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.workspace_premium_outlined,
                size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No certifications recorded'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: certs.length,
      itemBuilder: (context, index) {
        final cert = certs[index];
        return _buildCertificateCard(cert);
      },
    );
  }

  Widget _buildCertificateCard(Map<String, dynamic> cert) {
    final isVerified = cert['verified'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.workspace_premium,
                    color: isVerified ? AppTheme.pepperGold : Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cert['cert_type'] ?? 'Unknown Certificate',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (isVerified)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified,
                            size: 14, color: AppTheme.forestGreen),
                        SizedBox(width: 4),
                        Text('Verified',
                            style: TextStyle(
                                fontSize: 11, color: AppTheme.forestGreen)),
                      ],
                    ),
                  ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Certificate Number', cert['cert_number'] ?? 'N/A'),
            _buildInfoRow('Issued By', cert['issued_by'] ?? 'N/A'),
            _buildInfoRow('Issue Date', _formatDate(cert['issue_date'])),
            _buildInfoRow('Expiry Date', _formatDate(cert['expiry_date'])),
            if (isVerified) ...[
              _buildInfoRow('Verified By', cert['verified_by'] ?? 'N/A'),
              _buildInfoRow(
                  'Verified At', _formatTimestamp(cert['verified_at'])),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildComplianceTab() {
    final checks = _traceabilityData?['compliance_checks'] as List? ?? [];

    if (checks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fact_check_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No compliance checks recorded'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: checks.length,
      itemBuilder: (context, index) {
        final check = checks[index];
        return _buildComplianceCard(check);
      },
    );
  }

  Widget _buildComplianceCard(Map<String, dynamic> check) {
    final isPassed = check['passed'] == true;
    final ruleName = check['rule_name'] as String? ?? 'Unknown Rule';
    final ruleType = check['rule_type'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPassed ? Icons.check_circle : Icons.cancel,
                  color: isPassed ? AppTheme.forestGreen : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ruleName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (ruleType.isNotEmpty)
                        Text(
                          ruleType.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPassed ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isPassed ? 'PASSED' : 'FAILED',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isPassed ? AppTheme.forestGreen : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Checked At', _formatTimestamp(check['checked_at'])),
            if (check['details'] != null) ...[
              const SizedBox(height: 12),
              Text(
                'Details:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  check['details'].toString(),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildComplianceStat(String label, dynamic value, [Color? color]) {
    return Column(
      children: [
        Text(
          value?.toString() ?? '0',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildBlockchainTab() {
    final blockchainInfo = _traceabilityData?['blockchain_info'] ?? {};
    final lotInfo = _traceabilityData?['lot_info'] ?? {};
    final currentStatus = _traceabilityData?['current_status'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NFT Passport Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.badge, color: AppTheme.forestGreen),
                      SizedBox(width: 8),
                      Text('NFT Passport',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildBlockchainRow(
                    'Lot ID',
                    lotInfo['lot_id'] ?? 'N/A',
                    canCopy: true,
                  ),
                  _buildBlockchainRow(
                    'Primary TX Hash',
                    blockchainInfo['primary_tx_hash'] ?? 'Not yet recorded',
                    canCopy: blockchainInfo['primary_tx_hash'] != null,
                  ),
                  _buildBlockchainRow(
                    'Certificate Hash',
                    blockchainInfo['certificate_hash'] ?? 'N/A',
                    canCopy: true,
                  ),
                  _buildBlockchainRow(
                    'Metadata URI',
                    blockchainInfo['metadata_uri'] ?? 'N/A',
                    canCopy: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Current Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Current Status',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildInfoRow('Stage', currentStatus['description'] ?? 'N/A'),
                  _buildInfoRow('Current Owner',
                      currentStatus['current_owner_name'] ?? 'N/A'),
                  _buildInfoRow('Compliance',
                      currentStatus['compliance_status'] ?? 'N/A'),
                  _buildInfoRow(
                    'In Auction',
                    currentStatus['is_in_auction'] == true ? 'Yes' : 'No',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Blockchain Statistics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.analytics, color: AppTheme.pepperGold),
                      SizedBox(width: 8),
                      Text('Blockchain Statistics',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    'Total Blockchain Transactions',
                    blockchainInfo['total_transactions']?.toString() ?? '0',
                  ),
                  _buildInfoRow(
                    'Network',
                    'Hardhat Local (Chain ID: 1337)',
                  ),
                  _buildInfoRow(
                    'RPC URL',
                    'http://192.168.8.116:8545',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockchainRow(String label, String value,
      {bool canCopy = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: canCopy && value != 'N/A' && value != 'Not yet recorded'
                ? () => _copyToClipboard(value, label)
                : null,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value.length > 40
                          ? '${value.substring(0, 20)}...${value.substring(value.length - 20)}'
                          : value,
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  if (canCopy && value != 'N/A' && value != 'Not yet recorded')
                    const Icon(Icons.copy, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getEventColor(String type) {
    switch (type) {
      case 'lot_created':
        return Colors.green;
      case 'processing_stage':
        return AppTheme.forestGreen;
      case 'certification_added':
        return AppTheme.pepperGold;
      case 'compliance_check':
        return Colors.blue;
      case 'auction_created':
      case 'auction_ended':
      case 'auction_settled':
        return Colors.purple;
      case 'bid_placed':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'lot_created':
        return Icons.add_circle;
      case 'processing_stage':
        return Icons.settings;
      case 'certification_added':
        return Icons.workspace_premium;
      case 'compliance_check':
        return Icons.fact_check;
      case 'auction_created':
        return Icons.gavel;
      case 'auction_ended':
        return Icons.timer_off;
      case 'auction_settled':
        return Icons.handshake;
      case 'bid_placed':
        return Icons.local_offer;
      default:
        return Icons.circle;
    }
  }

  IconData _getStageIcon(String? stageType) {
    switch (stageType?.toLowerCase()) {
      case 'harvest':
        return Icons.agriculture;
      case 'drying':
        return Icons.wb_sunny;
      case 'grading':
        return Icons.star_rate;
      case 'packaging':
        return Icons.inventory_2;
      case 'shipment':
        return Icons.local_shipping;
      default:
        return Icons.settings;
    }
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return timestamp;
    }
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return 'N/A';
    try {
      final dateTime = DateTime.parse(date);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return date;
    }
  }
}
