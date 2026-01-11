import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';

class PendingApprovalsScreen extends StatefulWidget {
  const PendingApprovalsScreen({super.key});

  @override
  State<PendingApprovalsScreen> createState() => _PendingApprovalsScreenState();
}

class _PendingApprovalsScreenState extends State<PendingApprovalsScreen> {
  final _apiService = ApiService();
  List<Map<String, dynamic>> _pendingAuctions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingAuctions();
  }

  Future<void> _fetchPendingAuctions() async {
    setState(() => _loading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final farmerAddress = authProvider.user?.walletAddress ?? '';

      final response = await _apiService.get(
        '/auctions?status=pending_approval&farmer=$farmerAddress',
      );

      setState(() {
        _pendingAuctions =
            List<Map<String, dynamic>>.from(response['auctions'] ?? []);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load pending auctions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Pending Approvals'),
        backgroundColor: AppTheme.forestGreen,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pendingAuctions.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchPendingAuctions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pendingAuctions.length,
                    itemBuilder: (context, index) {
                      final auction = _pendingAuctions[index];
                      return _buildAuctionCard(auction);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Pending Approvals',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'All your auctions have been approved or you have no pending submissions',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuctionCard(Map<String, dynamic> auction) {
    final lotId = auction['lot_id'] ?? 'Unknown';
    final variety = auction['variety'] ?? 'N/A';
    final quantity = auction['quantity']?.toString() ?? 'N/A';
    final reservePrice = auction['reserve_price']?.toString() ?? 'N/A';
    final createdAt = auction['created_at'] != null
        ? DateTime.parse(auction['created_at'])
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange[300]!, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.orange[900]),
                  const SizedBox(width: 6),
                  Text(
                    'PENDING ADMIN APPROVAL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[900],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Lot Details
            Row(
              children: [
                const Icon(Icons.inventory_2,
                    color: AppTheme.forestGreen, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lot: $lotId',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Auction Info
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(
                    Icons.grass,
                    'Variety',
                    variety,
                  ),
                ),
                Expanded(
                  child: _buildInfoRow(
                    Icons.scale,
                    'Quantity',
                    '$quantity kg',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(
                    Icons.attach_money,
                    'Reserve',
                    'LKR $reservePrice',
                  ),
                ),
                Expanded(
                  child: _buildInfoRow(
                    Icons.access_time,
                    'Submitted',
                    createdAt != null
                        ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
                        : 'N/A',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Info Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Admin is reviewing your auction. You will be notified once approved.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[900],
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
