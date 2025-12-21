import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/blockchain_service.dart';

class Auction {
  final String id;
  final String tokenId;
  final String lotId;
  final String farmerAddress;
  final double startingPrice;
  final double currentBid;
  final String? highestBidder;
  final DateTime startTime;
  final DateTime endTime;
  final String status;

  Auction({
    required this.id,
    required this.tokenId,
    required this.lotId,
    required this.farmerAddress,
    required this.startingPrice,
    required this.currentBid,
    this.highestBidder,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory Auction.fromJson(Map<String, dynamic> json) {
    return Auction(
      id: json['id'] ?? '',
      tokenId: json['tokenId'] ?? '',
      lotId: json['lotId'] ?? '',
      farmerAddress: json['farmerAddress'] ?? '',
      startingPrice: (json['startingPrice'] ?? 0).toDouble(),
      currentBid: (json['currentBid'] ?? 0).toDouble(),
      highestBidder: json['highestBidder'],
      startTime: DateTime.tryParse(json['startTime'] ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(json['endTime'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'created',
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

  Future<void> fetchAuctions() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.getAuctions();
      _auctions = response.map((json) => Auction.fromJson(json)).toList();
    } catch (e) {
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

  void _updateCurrentAuction(dynamic data) {
    if (_currentAuction != null && data['auctionId'] == _currentAuction!.id) {
      // Update current auction with new bid data
      _currentAuction = Auction(
        id: _currentAuction!.id,
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
