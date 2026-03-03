import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';
import '../../models/lot.dart';
import '../../localization/app_localizations.dart';

class BrowseLotsScreen extends StatefulWidget {
  const BrowseLotsScreen({super.key});

  @override
  State<BrowseLotsScreen> createState() => _BrowseLotsScreenState();
}

class _BrowseLotsScreenState extends State<BrowseLotsScreen> {
  List<Lot> _lots = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all'; // all, inAuction, upcoming

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
      // Only fetch approved lots for exporters to browse
      final lotsData = await apiService.getLots(status: 'approved');

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
    if (_selectedFilter == 'all') {
      return _lots;
    } else if (_selectedFilter == 'inAuction') {
      return _lots.where((lot) => lot.isInAuction).toList();
    } else if (_selectedFilter == 'upcoming') {
      return _lots.where((lot) => !lot.isInAuction && !lot.isSold).toList();
    }
    return _lots;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppTheme.forestGreen,
        elevation: 0,
        title: Text(
          context.tr('lot_all_lots'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            tooltip: context.tr('lot_scan_qr'),
            onPressed: () => context.push('/qrScanner'),
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
                  _buildFilterChip(context.tr('lot_all_lots'), 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                      context.tr('auction_in_auction'), 'inAuction'),
                  const SizedBox(width: 8),
                  _buildFilterChip(context.tr('auction_upcoming'), 'upcoming'),
                ],
              ),
            ),
          ),

          // Lots List
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
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

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              context.tr('error_loading_lots'),
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadLots,
              child: Text(context.tr('common_retry')),
            ),
          ],
        ),
      );
    }

    if (_filteredLots.isEmpty) {
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
                  ? 'No approved lots available'
                  : _selectedFilter == 'inAuction'
                      ? 'No lots currently in auction'
                      : 'No upcoming lots',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadLots,
              icon: const Icon(Icons.refresh),
              label: Text(context.tr('common_refresh')),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLots,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredLots.length,
        itemBuilder: (context, index) {
          final lot = _filteredLots[index];
          return _buildLotCard(lot);
        },
      ),
    );
  }

  Widget _buildLotCard(Lot lot) {
    final isInAuction = lot.isInAuction;
    final isSold = lot.isSold;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => context.push('/lot/${lot.lotId}'),
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
                  // Lot ID and Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lot.lotId,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildStatusBadge(lot),
                      ],
                    ),
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
                      lot.quality.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.pepperGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),

              // Lot Details
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.scale,
                      'Weight',
                      '${lot.quantity} kg',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.local_offer,
                      'Variety',
                      lot.variety,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.location_on,
                      'Origin',
                      lot.origin,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.calendar_today,
                      'Harvest',
                      _formatDate(lot.harvestDate),
                    ),
                  ),
                ],
              ),

              // Current Bid
              if (isInAuction && lot.currentBid != null) ...[
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr('auction_current_bid'),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      'LKR ${lot.currentBid!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.forestGreen,
                      ),
                    ),
                  ],
                ),
              ] else if (!isSold && lot.organicCertified) ...[
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Organically Certified',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],

              // Action Button
              if (isInAuction && !isSold) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/auction/${lot.auctionId}'),
                    icon: const Icon(Icons.gavel),
                    label: Text(context.tr('auction_place_bid')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.forestGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Lot lot) {
    final Color statusColor;
    final String statusText;
    final IconData statusIcon;

    if (lot.isSold) {
      statusColor = Colors.grey;
      statusText = 'SOLD';
      statusIcon = Icons.check_circle;
    } else if (lot.isInAuction) {
      statusColor = Colors.orange;
      statusText = 'IN AUCTION';
      statusIcon = Icons.gavel;
    } else {
      statusColor = Colors.green;
      statusText = 'AVAILABLE';
      statusIcon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 14, color: statusColor),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
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
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
