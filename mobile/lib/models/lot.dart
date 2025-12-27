class Lot {
  final String id;
  final String lotId; // Unique lot identifier (e.g., LOT-xxxxx)
  final String farmerId;
  final String farmerName;
  final String? farmerAddress; // Blockchain wallet address
  final String variety;
  final double quantity; // in kg
  final String quality; // AAA, AA, A, B
  final DateTime harvestDate;
  final String origin;
  final String farmLocation;
  final bool organicCertified;
  final String? metadataURI; // IPFS URI for metadata
  final String? certificateHash; // Blockchain certificate hash
  final String? certificateIpfsUrl; // IPFS URL for certificates
  final String? txHash; // Blockchain transaction hash
  final String? qrCode; // QR code data for lot
  final String? nfcTag; // NFC tag identifier
  final List<String> certificateImages;
  final String status; // pending, approved, rejected, listed, sold
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Auction related fields
  final String? auctionId;
  final double? currentBid;
  final int? bidderCount;
  final DateTime? auctionEndTime;

  Lot({
    required this.id,
    required this.lotId,
    required this.farmerId,
    required this.farmerName,
    this.farmerAddress,
    required this.variety,
    required this.quantity,
    required this.quality,
    required this.harvestDate,
    required this.origin,
    required this.farmLocation,
    this.organicCertified = false,
    this.metadataURI,
    this.certificateHash,
    this.certificateIpfsUrl,
    this.txHash,
    this.qrCode,
    this.nfcTag,
    this.certificateImages = const [],
    this.status = 'pending',
    this.rejectionReason,
    required this.createdAt,
    this.updatedAt,
    this.auctionId,
    this.currentBid,
    this.bidderCount,
    this.auctionEndTime,
  });

  factory Lot.fromJson(Map<String, dynamic> json) {
    return Lot(
      id: json['id']?.toString() ?? '',
      lotId: (json['lotId'] ?? json['lot_id'])?.toString() ?? '',
      farmerId: (json['farmerId'] ?? json['farmer_id'])?.toString() ?? '',
      farmerName: (json['farmerName'] ?? json['farmer_name'])?.toString() ??
          'Unknown Farmer',
      farmerAddress:
          (json['farmerAddress'] ?? json['farmer_address'])?.toString(),
      variety: json['variety']?.toString() ?? '',
      quantity: json['quantity'] != null
          ? (json['quantity'] is String
              ? double.tryParse(json['quantity']) ?? 0.0
              : (json['quantity'] as num).toDouble())
          : 0.0,
      quality: json['quality']?.toString() ?? '',
      harvestDate: (json['harvestDate'] ?? json['harvest_date']) != null
          ? DateTime.parse(
              (json['harvestDate'] ?? json['harvest_date']).toString())
          : DateTime.now(),
      origin: json['origin']?.toString() ?? '',
      farmLocation:
          (json['farmLocation'] ?? json['farm_location'])?.toString() ?? '',
      organicCertified:
          (json['organicCertified'] ?? json['organic_certified']) as bool? ??
              false,
      metadataURI: (json['metadataURI'] ?? json['metadata_uri'])?.toString(),
      certificateHash:
          (json['certificateHash'] ?? json['certificate_hash'])?.toString(),
      certificateIpfsUrl:
          (json['certificateIpfsUrl'] ?? json['certificate_ipfs_url'])
              ?.toString(),
      txHash: (json['txHash'] ?? json['blockchain_tx_hash'])?.toString(),
      qrCode: (json['qrCode'] ?? json['qr_code'])?.toString(),
      nfcTag: (json['nfcTag'] ?? json['nfc_tag'])?.toString(),
      certificateImages:
          (json['certificateImages'] ?? json['certificate_images']) != null
              ? List<String>.from(((json['certificateImages'] ??
                      json['certificate_images']) as List)
                  .map((e) => e?.toString() ?? ''))
              : [],
      status: json['status']?.toString() ?? 'pending',
      rejectionReason:
          (json['rejectionReason'] ?? json['rejection_reason'])?.toString(),
      createdAt: (json['createdAt'] ?? json['created_at']) != null
          ? DateTime.parse((json['createdAt'] ?? json['created_at']).toString())
          : DateTime.now(),
      updatedAt: (json['updatedAt'] ?? json['updated_at']) != null
          ? DateTime.parse((json['updatedAt'] ?? json['updated_at']).toString())
          : null,
      auctionId: (json['auctionId'] ?? json['auction_id'])?.toString(),
      currentBid: (json['currentBid'] ?? json['current_bid']) != null
          ? ((json['currentBid'] ?? json['current_bid']) is String
              ? double.tryParse((json['currentBid'] ?? json['current_bid'])) ??
                  0.0
              : ((json['currentBid'] ?? json['current_bid']) as num).toDouble())
          : null,
      bidderCount: (json['bidderCount'] ?? json['bidder_count']) != null
          ? ((json['bidderCount'] ?? json['bidder_count']) is String
              ? int.tryParse((json['bidderCount'] ?? json['bidder_count'])) ?? 0
              : ((json['bidderCount'] ?? json['bidder_count']) as num).toInt())
          : null,
      auctionEndTime: (json['auctionEndTime'] ?? json['auction_end_time']) !=
              null
          ? DateTime.parse(
              (json['auctionEndTime'] ?? json['auction_end_time']).toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lotId': lotId,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'farmerAddress': farmerAddress,
      'variety': variety,
      'quantity': quantity,
      'quality': quality,
      'harvestDate': harvestDate.toIso8601String(),
      'origin': origin,
      'farmLocation': farmLocation,
      'organicCertified': organicCertified,
      'metadataURI': metadataURI,
      'certificateHash': certificateHash,
      'certificateIpfsUrl': certificateIpfsUrl,
      'txHash': txHash,
      'qrCode': qrCode,
      'nfcTag': nfcTag,
      'certificateImages': certificateImages,
      'status': status,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'auctionId': auctionId,
      'currentBid': currentBid,
      'bidderCount': bidderCount,
      'auctionEndTime': auctionEndTime?.toIso8601String(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isListed => status == 'listed';
  bool get isSold => status == 'sold';
  bool get hasAuction => auctionId != null;
  bool get isInAuction =>
      hasAuction &&
      auctionEndTime != null &&
      DateTime.now().isBefore(auctionEndTime!);
}
