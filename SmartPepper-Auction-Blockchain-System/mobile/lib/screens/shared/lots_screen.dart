import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lot_provider.dart';
import '../../config/theme.dart';
import '../farmer/create_lot_screen.dart';
import '../farmer/lot_details_screen.dart';

class LotsScreen extends StatefulWidget {
  const LotsScreen({super.key});

  @override
  State<LotsScreen> createState() => _LotsScreenState();
}

class _LotsScreenState extends State<LotsScreen> {
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    // Fetch lots when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLots();
    });
  }

  Future<void> _loadLots() async {
    final authProvider = context.read<AuthProvider>();
    final lotProvider = context.read<LotProvider>();

    await lotProvider.fetchLots(
      farmerAddress: authProvider.user?.role.toLowerCase() == 'farmer'
          ? authProvider.user?.walletAddress
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isFarmer = authProvider.user?.role.toLowerCase() == 'farmer';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppTheme.forestGreen,
        elevation: 0,
        title: const Text(
          'Pepper Lots',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scan QR Code')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Created', 'created'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Approved', 'approved'),
                  const SizedBox(width: 8),
                  _buildFilterChip('In Auction', 'auction'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Sold', 'sold'),
                ],
              ),
            ),
          ),

          // Lots List
          Expanded(
            child: _buildLotsList(),
          ),
        ],
      ),
      floatingActionButton: isFarmer
          ? FloatingActionButton.extended(
              heroTag: 'lots_fab',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CreateLotScreen()),
                );
              },
              backgroundColor: AppTheme.forestGreen,
              icon: const Icon(Icons.add),
              label: const Text('Create Lot'),
            )
          : null,
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: AppTheme.forestGreen,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.grey[200],
    );
  }

  Widget _buildLotsList() {
    final lotProvider = context.watch<LotProvider>();

    // Filter lots by selected status
    var filteredLots = lotProvider.lots;
    if (_selectedFilter != 'all') {
      filteredLots = filteredLots
          .where((lot) =>
              lot.status.toLowerCase() == _selectedFilter.toLowerCase())
          .toList();
    }

    if (lotProvider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (lotProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading lots',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _loadLots(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (filteredLots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == 'all'
                  ? 'No lots available'
                  : 'No $_selectedFilter lots',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadLots();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredLots.length,
        itemBuilder: (context, index) {
          final lot = filteredLots[index];
          return _buildLotCard(lot);
        },
      ),
    );
  }

  Widget _buildLotCard(Lot lot) {
    final status = lot.status.toLowerCase();
    final Color statusColor = _getStatusColor(status);
    final IconData statusIcon = _getStatusIcon(status);

    // Format harvest date
    final harvestDate =
        '${lot.harvestDate.year}-${lot.harvestDate.month.toString().padLeft(2, '0')}-${lot.harvestDate.day.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LotDetailsScreen(lot: lot),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(statusIcon, color: statusColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lot.lotId,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Quality Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.pepperGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.pepperGold),
                    ),
                    child: Text(
                      lot.quality ?? 'N/A',
                      style: const TextStyle(
                        color: AppTheme.pepperGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Variety
              Text(
                lot.variety,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.forestGreen,
                ),
              ),

              const SizedBox(height: 12),

              // Details Grid
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      icon: Icons.scale,
                      label: 'Quantity',
                      value: '${lot.quantity.toStringAsFixed(0)} kg',
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      icon: Icons.calendar_today,
                      label: 'Harvest',
                      value: harvestDate,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('View traceability')),
                        );
                      },
                      icon: const Icon(Icons.track_changes, size: 16),
                      label: const Text('Track'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.forestGreen,
                        side: const BorderSide(color: AppTheme.forestGreen),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('View NFT Passport')),
                        );
                      },
                      icon: const Icon(Icons.verified, size: 16),
                      label: const Text('NFT'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.pepperGold,
                        side: const BorderSide(color: AppTheme.pepperGold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'created':
        return Colors.blue;
      case 'approved':
        return Colors.green;
      case 'auction':
        return Colors.orange;
      case 'sold':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'created':
        return Icons.add_circle;
      case 'approved':
        return Icons.check_circle;
      case 'auction':
        return Icons.gavel;
      case 'sold':
        return Icons.monetization_on;
      default:
        return Icons.circle;
    }
  }
}
