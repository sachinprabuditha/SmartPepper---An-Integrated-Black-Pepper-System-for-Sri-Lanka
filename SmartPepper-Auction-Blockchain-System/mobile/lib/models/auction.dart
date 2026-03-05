class Auction {
  final String id;
  final String lotId;
  final String farmerId;
  final double startingPrice;
  final double? currentBid;
  final double? reservePrice;
  final String? currentBidder;
  final String? currentBidderName;
  final int bidderCount;
  final DateTime startTime;
  final DateTime endTime;
  final String status; // pending, active, ended, settled
  final String? winnerAddress;
  final String? winnerName;
  final double? finalPrice;
  final bool escrowLocked;
  final bool paymentReleased;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Lot details (denormalized for convenience)
  final String? lotVariety;
  final double? lotQuantity;
  final String? lotQuality;

  Auction({
    required this.id,
    required this.lotId,
    required this.farmerId,
    required this.startingPrice,
    this.currentBid,
    this.reservePrice,
    this.currentBidder,
    this.currentBidderName,
    this.bidderCount = 0,
    required this.startTime,
    required this.endTime,
    this.status = 'pending',
    this.winnerAddress,
    this.winnerName,
    this.finalPrice,
    this.escrowLocked = false,
    this.paymentReleased = false,
    required this.createdAt,
    this.updatedAt,
    this.lotVariety,
    this.lotQuantity,
    this.lotQuality,
  });

  factory Auction.fromJson(Map<String, dynamic> json) {
    // Debug logging to trace ID extraction
    final extractedId = (json['id'] ?? json['auction_id'] ?? '') as String;
    if (extractedId.isEmpty) {
      print(
          '⚠️ WARNING: Auction ID is empty! Raw JSON keys: ${json.keys.toList()}');
      print('   json["id"]: ${json['id']}');
      print('   json["auction_id"]: ${json['auction_id']}');
    } else {
      print('✅ Extracted auction ID: $extractedId from json');
    }

    return Auction(
      id: extractedId,
      lotId: (json['lotId'] ?? json['lot_id'] ?? '') as String,
      farmerId: (json['farmerId'] ?? json['farmer_id'] ?? '') as String,
      startingPrice: ((json['startingPrice'] ??
              json['starting_price'] ??
              json['start_price'] ??
              0) as num)
          .toDouble(),
      currentBid: json['currentBid'] != null || json['current_bid'] != null
          ? ((json['currentBid'] ?? json['current_bid']) as num).toDouble()
          : null,
      reservePrice: json['reservePrice'] != null ||
              json['reserve_price'] != null
          ? ((json['reservePrice'] ?? json['reserve_price']) as num).toDouble()
          : null,
      currentBidder:
          (json['currentBidder'] ?? json['current_bidder']) as String?,
      currentBidderName:
          (json['currentBidderName'] ?? json['current_bidder_name']) as String?,
      bidderCount: (json['bidderCount'] ?? json['bidder_count'] ?? 0) as int,
      startTime:
          DateTime.parse((json['startTime'] ?? json['start_time']) as String),
      endTime: DateTime.parse((json['endTime'] ?? json['end_time']) as String),
      status: (json['status'] ?? 'pending') as String,
      winnerAddress:
          (json['winnerAddress'] ?? json['winner_address']) as String?,
      winnerName: (json['winnerName'] ?? json['winner_name']) as String?,
      finalPrice: json['finalPrice'] != null || json['final_price'] != null
          ? ((json['finalPrice'] ?? json['final_price']) as num).toDouble()
          : null,
      escrowLocked:
          (json['escrowLocked'] ?? json['escrow_locked'] ?? false) as bool,
      paymentReleased: (json['paymentReleased'] ??
          json['payment_released'] ??
          false) as bool,
      createdAt:
          DateTime.parse((json['createdAt'] ?? json['created_at']) as String),
      updatedAt: json['updatedAt'] != null || json['updated_at'] != null
          ? DateTime.parse((json['updatedAt'] ?? json['updated_at']) as String)
          : null,
      lotVariety: (json['lotVariety'] ?? json['variety']) as String?,
      lotQuantity: json['lotQuantity'] != null || json['quantity'] != null
          ? ((json['lotQuantity'] ?? json['quantity']) as num).toDouble()
          : null,
      lotQuality: (json['lotQuality'] ?? json['quality']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lotId': lotId,
      'farmerId': farmerId,
      'startingPrice': startingPrice,
      'currentBid': currentBid,
      'reservePrice': reservePrice,
      'currentBidder': currentBidder,
      'currentBidderName': currentBidderName,
      'bidderCount': bidderCount,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'status': status,
      'winnerAddress': winnerAddress,
      'winnerName': winnerName,
      'finalPrice': finalPrice,
      'escrowLocked': escrowLocked,
      'paymentReleased': paymentReleased,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lotVariety': lotVariety,
      'lotQuantity': lotQuantity,
      'lotQuality': lotQuality,
    };
  }

  bool get isPending => status == 'pending';
  bool get isActive => status == 'active';
  bool get isEnded => status == 'ended';
  bool get isSettled => status == 'settled';

  bool get isLive => isActive && DateTime.now().isBefore(endTime);

  Duration get timeRemaining {
    if (DateTime.now().isAfter(endTime)) {
      return Duration.zero;
    }
    return endTime.difference(DateTime.now());
  }

  String get timeRemainingFormatted {
    final remaining = timeRemaining;
    if (remaining.inDays > 0) {
      return '${remaining.inDays}d ${remaining.inHours % 24}h';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes % 60}m';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes}m ${remaining.inSeconds % 60}s';
    } else {
      return '${remaining.inSeconds}s';
    }
  }
}
