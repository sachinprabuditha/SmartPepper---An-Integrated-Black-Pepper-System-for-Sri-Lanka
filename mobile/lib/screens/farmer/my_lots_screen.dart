import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lot_provider.dart' show Lot;
import 'lot_details_screen.dart';

class MyLotsScreen extends StatefulWidget {
  const MyLotsScreen({super.key});

  @override
  State<MyLotsScreen> createState() => _MyLotsScreenState();
}

class _MyLotsScreenState extends State<MyLotsScreen> {
  List<Lot> _lots = [];
  bool _isLoading = true;
  String? _error;
  String _filterStatus =
      'all'; // all, pending, approved, rejected, listed, sold

  @override
  void initState() {
    super.initState();
    _loadLots();
  }

  Future<void> _loadLots() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = context.read<ApiService>();
      final authProvider = context.read<AuthProvider>();

      // Get current user's wallet address to filter their lots
      final walletAddress = authProvider.user?.walletAddress;

      if (walletAddress == null) {
        throw Exception('Wallet address not found');
      }

      // Pass wallet address to get only this farmer's lots
      final lotsData = await apiService.getLots(farmerAddress: walletAddress);

      if (mounted) {
        setState(() {
          _lots = lotsData.map<Lot>((data) => Lot.fromJson(data)).toList();
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

  List<Lot> get _filteredLots {
    if (_filterStatus == 'all') return _lots;

    switch (_filterStatus) {
      case 'pending':
        return _lots.where((lot) => lot.isPending).toList();
      case 'approved':
        return _lots.where((lot) => lot.isApproved).toList();
      case 'rejected':
        return _lots.where((lot) => lot.isRejected).toList();
      case 'listed':
        return _lots.where((lot) => lot.isListed).toList();
      case 'sold':
        return _lots.where((lot) => lot.isSold).toList();
      default:
        return _lots;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.forestGreen,
      appBar: AppBar(
        title: const Text('My Lots'),
        backgroundColor: AppTheme.forestGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLots,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: AppTheme.forestGreen,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pending', 'pending'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Approved', 'approved'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Rejected', 'rejected'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Listed', 'listed'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Sold', 'sold'),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
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
                              'Error loading lots',
                              style: TextStyle(
                                  fontSize: 18, color: Colors.red.shade300),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadLots,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredLots.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory_outlined,
                                    size: 64, color: Colors.white30),
                                const SizedBox(height: 16),
                                Text(
                                  _filterStatus == 'all'
                                      ? 'No lots created yet'
                                      : 'No $_filterStatus lots',
                                  style: const TextStyle(
                                      fontSize: 18, color: Colors.white70),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Create your first lot to get started',
                                  style: TextStyle(color: Colors.white60),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      context.push('/farmer/create-lot'),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create Lot'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.pepperGold,
                                    foregroundColor: AppTheme.forestGreen,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadLots,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredLots.length,
                              itemBuilder: (context, index) {
                                final lot = _filteredLots[index];
                                return _buildLotCard(lot);
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/farmer/create-lot');
        },
        backgroundColor: AppTheme.pepperGold,
        foregroundColor: AppTheme.forestGreen,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _filterStatus = value);
        }
      },
      selectedColor: AppTheme.pepperGold,
      backgroundColor: AppTheme.deepEmerald,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.forestGreen : Colors.white,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildLotCard(Lot lot) {
    Color statusColor;
    IconData statusIcon;

    if (lot.isPending) {
      statusColor = Colors.orange;
      statusIcon = Icons.pending;
    } else if (lot.isApproved) {
      statusColor = AppTheme.sriLankanLeaf;
      statusIcon = Icons.check_circle;
    } else if (lot.isRejected) {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    } else if (lot.isListed) {
      statusColor = Colors.blue;
      statusIcon = Icons.storefront;
    } else if (lot.isSold) {
      statusColor = AppTheme.pepperGold;
      statusIcon = Icons.sell;
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.info;
    }

    return Card(
      color: AppTheme.forestGreen,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LotDetailsScreen(lot: lot),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      lot.variety,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: statusColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          lot.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on,
                      size: 16, color: Colors.white.withOpacity(0.7)),
                  const SizedBox(width: 4),
                  Text(
                    lot.origin ?? 'Unknown',
                    style: TextStyle(color: Colors.white.withOpacity(0.7)),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.scale,
                      size: 16, color: Colors.white.withOpacity(0.7)),
                  const SizedBox(width: 4),
                  Text(
                    '${lot.quantity}kg',
                    style: TextStyle(color: Colors.white.withOpacity(0.7)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.star, size: 16, color: AppTheme.pepperGold),
                  const SizedBox(width: 4),
                  Text(
                    'Grade: ${lot.quality}',
                    style: const TextStyle(color: AppTheme.pepperGold),
                  ),
                  if (lot.currentBid != null) ...[
                    const Spacer(),
                    Text(
                      'Current Bid: \$${lot.currentBid!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppTheme.pepperGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
              if (lot.hasAuction) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.gavel, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        'In Auction',
                        style: TextStyle(color: Colors.blue),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () =>
                            context.push('/farmer/auction/${lot.auctionId}'),
                        child: const Text('View Live'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
