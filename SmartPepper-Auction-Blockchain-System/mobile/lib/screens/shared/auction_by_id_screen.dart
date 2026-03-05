import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auction_provider.dart';
import '../../config/theme.dart';
import 'auction_details_screen.dart';

/// Wrapper screen that loads auction by ID and displays AuctionDetailsScreen
class AuctionByIdScreen extends StatefulWidget {
  final String auctionId;

  const AuctionByIdScreen({super.key, required this.auctionId});

  @override
  State<AuctionByIdScreen> createState() => _AuctionByIdScreenState();
}

class _AuctionByIdScreenState extends State<AuctionByIdScreen> {
  bool _isLoading = true;
  String? _error;
  Auction? _auction;

  @override
  void initState() {
    super.initState();
    _loadAuction();
  }

  Future<void> _loadAuction() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auctionProvider = context.read<AuctionProvider>();

      // Use joinAuction which fetches the auction data from API
      await auctionProvider.joinAuction(widget.auctionId);

      final auction = auctionProvider.currentAuction;
      if (auction == null) {
        throw Exception('Auction not found');
      }

      if (mounted) {
        setState(() {
          _auction = auction;
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.forestGreen,
        appBar: AppBar(
          title: const Text('Loading Auction...'),
          backgroundColor: AppTheme.forestGreen,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.pepperGold),
        ),
      );
    }

    if (_error != null || _auction == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Auction'),
          backgroundColor: AppTheme.forestGreen,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Auction not found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'The auction may have been removed',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.forestGreen,
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    // Display the auction details screen
    return AuctionDetailsScreen(auction: _auction!);
  }
}
