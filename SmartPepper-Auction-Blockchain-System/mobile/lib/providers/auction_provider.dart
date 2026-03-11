import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/blockchain_service.dart';
import '../services/notification_service.dart';

class Auction {
  final String id;
  final String auctionId;
  final String tokenId;
  final String lotId;
  final String farmerAddress;
  final double startingPrice;
  final double? startingPriceLkr; // LKR equivalent of starting price
  final double currentBid;
  final double? currentBidLkr; // LKR equivalent of current bid
  final String? highestBidder;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final String? variety;
  final double? quantity;
  final String? quality;
  final int bidderCount;
  final String? blockchainTxHash;
  final bool compliancePassed;

  Auction({
    required this.id,
    required this.auctionId,
    required this.tokenId,
    required this.lotId,
    required this.farmerAddress,
    required this.startingPrice,
    this.startingPriceLkr,
    required this.currentBid,
    this.currentBidLkr,
    this.highestBidder,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.variety,
    this.quantity,
    this.quality,
    this.bidderCount = 0,
    this.blockchainTxHash,
    this.compliancePassed = false,
  });

  factory Auction.fromJson(Map<String, dynamic> json) {
    // Extract ID with fallback to auction_id (backend uses auction_id)
    final extractedId =
        json['id']?.toString() ?? json['auction_id']?.toString() ?? '';

    return Auction(
      id: extractedId,
      auctionId:
          json['auction_id']?.toString() ?? json['auctionId']?.toString() ?? '',
      tokenId:
          json['token_id']?.toString() ?? json['tokenId']?.toString() ?? '',
      lotId: json['lot_id']?.toString() ?? json['lotId']?.toString() ?? '',
      farmerAddress: json['farmer_address']?.toString() ??
          json['farmerAddress']?.toString() ??
          '',
      startingPrice: double.tryParse(json['starting_price']?.toString() ??
              json['startingPrice']?.toString() ??
              json['start_price']?.toString() ??
              json['reserve_price']?.toString() ??
              '0') ??
          0.0,
      startingPriceLkr: double.tryParse(json['price_lkr']?.toString() ??
          json['starting_price_lkr']?.toString() ??
          json['startingPriceLkr']?.toString() ??
          '0'),
      currentBid: double.tryParse(json['current_bid']?.toString() ??
              json['currentBid']?.toString() ??
              '0') ??
          0.0,
      currentBidLkr: double.tryParse(json['current_bid_lkr']?.toString() ??
          json['currentBidLkr']?.toString() ??
          '0'),
      highestBidder: json['current_bidder']?.toString() ??
          json['highest_bidder']?.toString() ??
          json['highestBidder']?.toString() ??
          json['winner_address']?.toString(),
      startTime: DateTime.tryParse(json['start_time']?.toString() ??
              json['startTime']?.toString() ??
              '') ??
          DateTime.now(),
      endTime: DateTime.tryParse(json['end_time']?.toString() ??
              json['endTime']?.toString() ??
              '') ??
          DateTime.now(),
      status: json['status']?.toString() ?? 'created',
      variety: json['variety']?.toString(),
      quantity: double.tryParse(json['quantity']?.toString() ?? '0'),
      quality: json['quality']?.toString(),
      bidderCount: int.tryParse(json['bid_count']?.toString() ??
              json['bidderCount']?.toString() ??
              '0') ??
          0,
      blockchainTxHash: json['blockchain_tx_hash']?.toString(),
      compliancePassed:
          json['compliance_passed'] == true || json['compliancePassed'] == true,
    );
  }
}

class AuctionProvider with ChangeNotifier {
  final ApiService apiService;
  final SocketService socketService;
  final BlockchainService blockchainService;
  final NotificationService? notificationService;

  List<Auction> _auctions = [];
  Auction? _currentAuction;
  bool _loading = false;
  String? _error;
  String? _farmerAddress;

  AuctionProvider({
    required this.apiService,
    required this.socketService,
    required this.blockchainService,
    this.notificationService,
  }) {
    _initializeSocket();
  }

  List<Auction> get auctions => _auctions;
  Auction? get currentAuction => _currentAuction;
  bool get loading => _loading;
  String? get error => _error;

  void _initializeSocket() {
    // Socket is already connected at app startup
    // Just set up event listeners
    print('🎧 Setting up auction event listeners...');

    socketService.onNewBid((data) {
      print('📥 New bid received: $data');
      _updateCurrentAuction(data);

      // Notify farmer if this bid is for their auction
      _notifyFarmerOfNewBid(data);
    });

    socketService.onAuctionEnd((data) {
      print('📥 Auction ended: $data');
      _handleAuctionEnd(data);
    });
  }

  Future<void> fetchAuctions({String? farmerAddress}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔍 Fetching auctions for farmer: $farmerAddress');
      // Store farmer address for notification filtering
      _farmerAddress = farmerAddress;

      final response =
          await apiService.getAuctions(farmerAddress: farmerAddress);
      print('✅ Received ${response.length} auctions from API');
      _auctions = response.map((json) => Auction.fromJson(json)).toList();
      print('✅ Parsed ${_auctions.length} auction objects');

      // Auto-join all active auction rooms for real-time bid notifications
      for (var auction in _auctions) {
        if (auction.status == 'active' || auction.status == 'live') {
          print('🔔 Joining auction room: ${auction.auctionId}');
          socketService.joinAuction(auction.auctionId);
        }
      }

      // Debug: Log parsed auction IDs
      for (var auction in _auctions) {
        print('   📦 Auction: id=${auction.id}, status=${auction.status}');
      }
    } catch (e) {
      print('❌ Error fetching auctions: $e');
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> joinAuction(String auctionId) async {
    try {
      final response = await apiService.getAuctionById(auctionId);
      // Backend returns { "success": true, "auction": {...}, "bids": [] }
      // Extract the auction object from the response
      final auctionData = response['auction'] ?? response;
      print('🔍 Parsing auction data: status = ${auctionData['status']}');
      _currentAuction = Auction.fromJson(auctionData);
      print('✅ Current auction status set to: ${_currentAuction?.status}');
      socketService.joinAuction(auctionId);
      notifyListeners();
    } catch (e) {
      print('❌ Error in joinAuction: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> leaveAuction() async {
    if (_currentAuction != null) {
      socketService.leaveAuction(_currentAuction!.id);
      _currentAuction = null;
      notifyListeners();
    }
  }

  Future<bool> placeBid(
      String auctionId, double amount, String bidderAddress) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await apiService.placeBid(auctionId, {
        'amount': amount,
        'bidderAddress': bidderAddress,
      });
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createAuction(Map<String, dynamic> auctionData) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await apiService.createAuction(auctionData);
      await fetchAuctions(); // Refresh auction list
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  void _updateCurrentAuction(dynamic data) {
    if (_currentAuction != null && data['auctionId'] == _currentAuction!.id) {
      // Update current auction with new bid data
      _currentAuction = Auction(
        id: _currentAuction!.id,
        auctionId: _currentAuction!.auctionId,
        tokenId: _currentAuction!.tokenId,
        lotId: _currentAuction!.lotId,
        farmerAddress: _currentAuction!.farmerAddress,
        startingPrice: _currentAuction!.startingPrice,
        currentBid: (data['amount'] ?? _currentAuction!.currentBid).toDouble(),
        highestBidder: data['bidder'],
        startTime: _currentAuction!.startTime,
        endTime: _currentAuction!.endTime,
        status: _currentAuction!.status,
      );
      notifyListeners();
    }
  }

  void _handleAuctionEnd(dynamic data) {
    if (_currentAuction != null && data['auctionId'] == _currentAuction!.id) {
      _currentAuction = Auction(
        id: _currentAuction!.id,
        auctionId: _currentAuction!.auctionId,
        tokenId: _currentAuction!.tokenId,
        lotId: _currentAuction!.lotId,
        farmerAddress: _currentAuction!.farmerAddress,
        startingPrice: _currentAuction!.startingPrice,
        currentBid: _currentAuction!.currentBid,
        highestBidder: _currentAuction!.highestBidder,
        startTime: _currentAuction!.startTime,
        endTime: _currentAuction!.endTime,
        status: 'ended',
      );
      notifyListeners();
    }
  }

  void _notifyFarmerOfNewBid(dynamic data) {
    // Only send notification if NotificationService is available
    if (notificationService == null) return;

    try {
      final bidAuctionId = data['auctionId']?.toString();
      if (bidAuctionId == null) {
        print('⚠️ No auctionId in bid data');
        return;
      }

      print(
          '🔍 Checking if bid is for farmer\'s auction. Bid auctionId: $bidAuctionId, Farmer: $_farmerAddress');

      // Check if this bid is for one of the farmer's auctions
      final farmerAuction = _auctions.firstWhere(
        (auction) =>
            (auction.id == bidAuctionId || auction.auctionId == bidAuctionId) &&
            auction.farmerAddress == _farmerAddress,
        orElse: () => _auctions.first, // Will cause check below to fail
      );

      // If we found a matching auction owned by this farmer
      if (farmerAuction.farmerAddress == _farmerAddress &&
          (farmerAuction.id == bidAuctionId ||
              farmerAuction.auctionId == bidAuctionId)) {
        // Parse bid amounts
        final bidAmountEth =
            double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0;
        final bidAmountLkr =
            double.tryParse(data['amountLkr']?.toString() ?? '0') ??
                (bidAmountEth * 322580.65); // Fallback conversion
        final bidderCount =
            int.tryParse(data['bidCount']?.toString() ?? '1') ?? 1;

        print(
            '🔔 Sending notification to farmer for bid on auction ${bidAuctionId}');
        print(
            '   💰 Amount: ${bidAmountLkr.toStringAsFixed(2)} LKR (${bidAmountEth.toStringAsFixed(4)} ETH)');
        print('   👥 Bidders: $bidderCount');

        // Trigger notification
        notificationService!.notifyBidUpdate(
          lotId: farmerAuction.lotId,
          newBid: bidAmountLkr,
          bidderCount: bidderCount,
        );
      } else {
        print('ℹ️ Bid not for current farmer\'s auction');
      }
    } catch (e) {
      print('⚠️ Error notifying farmer of new bid: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    socketService.disconnect();
    super.dispose();
  }
}
