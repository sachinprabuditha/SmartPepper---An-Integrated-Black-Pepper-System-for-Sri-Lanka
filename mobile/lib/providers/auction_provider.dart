import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/blockchain_service.dart';

class Auction {
  final String id;
  final String auctionId;
  final String tokenId;
  final String lotId;
  final String farmerAddress;
  final double startingPrice;
  final double currentBid;
  final double? currentBidLkr; // LKR equivalent of current bid
  final String? highestBidder;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final String? variety;
  final double? quantity;
  final String? blockchainTxHash;
  final bool compliancePassed;

  Auction({
    required this.id,
    required this.auctionId,
    required this.tokenId,
    required this.lotId,
    required this.farmerAddress,
    required this.startingPrice,
    required this.currentBid,
    this.currentBidLkr,
    this.highestBidder,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.variety,
    this.quantity,
    this.blockchainTxHash,
    this.compliancePassed = false,
  });

  factory Auction.fromJson(Map<String, dynamic> json) {
    return Auction(
      id: json['id']?.toString() ?? '',
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
      currentBid: double.tryParse(json['current_bid']?.toString() ??
              json['currentBid']?.toString() ??
              '0') ??
          0.0,
      currentBidLkr: double.tryParse(json['current_bid_lkr']?.toString() ??
          json['currentBidLkr']?.toString() ??
          '0'),
      highestBidder: json['highest_bidder']?.toString() ??
          json['highestBidder']?.toString(),
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

  List<Auction> _auctions = [];
  Auction? _currentAuction;
  bool _loading = false;
  String? _error;

  AuctionProvider({
    required this.apiService,
    required this.socketService,
    required this.blockchainService,
  }) {
    _initializeSocket();
  }

  List<Auction> get auctions => _auctions;
  Auction? get currentAuction => _currentAuction;
  bool get loading => _loading;
  String? get error => _error;

  void _initializeSocket() {
    socketService.connect();

    socketService.onNewBid((data) {
      print('New bid received: $data');
      _updateCurrentAuction(data);
    });

    socketService.onAuctionEnd((data) {
      print('Auction ended: $data');
      _handleAuctionEnd(data);
    });
  }

  Future<void> fetchAuctions({String? farmerAddress}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔍 Fetching auctions for farmer: $farmerAddress');
      final response =
          await apiService.getAuctions(farmerAddress: farmerAddress);
      print('✅ Received ${response.length} auctions from API');
      _auctions = response.map((json) => Auction.fromJson(json)).toList();
      print('✅ Parsed ${_auctions.length} auction objects');
    } catch (e) {
      print('❌ Error fetching auctions: $e');
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> joinAuction(String auctionId) async {
    try {
      final auctionData = await apiService.getAuctionById(auctionId);
      _currentAuction = Auction.fromJson(auctionData);
      socketService.joinAuction(auctionId);
      notifyListeners();
    } catch (e) {
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

  Future<bool> placeBid(String auctionId, double amount) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await apiService.placeBid(auctionId, {'amount': amount});
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
