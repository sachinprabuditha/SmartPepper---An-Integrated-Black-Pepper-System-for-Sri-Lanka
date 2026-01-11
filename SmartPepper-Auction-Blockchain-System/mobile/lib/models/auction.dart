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
    return Auction(
      id: json['id'] as String,
      lotId: json['lotId'] as String,
      farmerId: json['farmerId'] as String,
      startingPrice: (json['startingPrice'] as num).toDouble(),
      currentBid: json['currentBid'] != null
          ? (json['currentBid'] as num).toDouble()
          : null,
      reservePrice: json['reservePrice'] != null
          ? (json['reservePrice'] as num).toDouble()
          : null,
      currentBidder: json['currentBidder'] as String?,
      currentBidderName: json['currentBidderName'] as String?,
      bidderCount: json['bidderCount'] as int? ?? 0,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      status: json['status'] as String? ?? 'pending',
      winnerAddress: json['winnerAddress'] as String?,
      winnerName: json['winnerName'] as String?,
      finalPrice: json['finalPrice'] != null
          ? (json['finalPrice'] as num).toDouble()
          : null,
      escrowLocked: json['escrowLocked'] as bool? ?? false,
      paymentReleased: json['paymentReleased'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      lotVariety: json['lotVariety'] as String?,
      lotQuantity: json['lotQuantity'] != null
          ? (json['lotQuantity'] as num).toDouble()
          : null,
      lotQuality: json['lotQuality'] as String?,
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
