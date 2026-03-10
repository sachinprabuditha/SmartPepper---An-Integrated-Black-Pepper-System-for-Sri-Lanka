class AppNotification {
  final String id;
  final String userId;
  final String
      type; // auction_start, auction_end, auction_won, auction_sold, auction_no_sale,
  // auction_settled, bid_update, compliance, payment, payment_received, system
  final String title;
  final String message;
  final Map<String, dynamic>? data; // Additional data (lotId, auctionId, etc.)
  final bool read;
  final String priority; // low, medium, high, urgent
  final DateTime createdAt;
  final DateTime? readAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    this.read = false,
    this.priority = 'medium',
    required this.createdAt,
    this.readAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      // Support both camelCase and snake_case field names from backend
      id: (json['notification_id'] ?? json['id']) as String,
      userId: (json['user_id'] ?? json['userId']) as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>?,
      read: (json['is_read'] ?? json['read']) as bool? ?? false,
      priority: json['priority'] as String? ?? 'medium',
      createdAt:
          DateTime.parse((json['created_at'] ?? json['createdAt']) as String),
      readAt: (json['updated_at'] ?? json['readAt']) != null
          ? DateTime.parse((json['updated_at'] ?? json['readAt']) as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'data': data,
      'read': read,
      'priority': priority,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }

  bool get isUnread => !read;
  bool get isUrgent => priority == 'urgent';
  bool get isHigh => priority == 'high';

  // Type checks
  bool get isAuctionStart => type == 'auction_start';
  bool get isAuctionEnd => type == 'auction_end';
  bool get isAuctionWon => type == 'auction_won';
  bool get isAuctionSold => type == 'auction_sold';
  bool get isAuctionNoSale => type == 'auction_no_sale';
  bool get isAuctionSettled => type == 'auction_settled';
  bool get isBidUpdate => type == 'bid_update';
  bool get isBidPlaced => type == 'bid_placed';
  bool get isCompliance => type == 'compliance';
  bool get isPayment => type == 'payment' || type == 'payment_received';
  bool get isPaymentReceived => type == 'payment_received';
  bool get isSystem => type == 'system';
}
