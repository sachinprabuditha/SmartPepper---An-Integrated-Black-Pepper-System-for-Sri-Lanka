import 'package:flutter/material.dart';

/// Helper class to handle navigation from notifications
class NotificationNavigationHelper {
  /// Handle navigation based on notification payload
  static void handleNotificationTap(
      BuildContext context, Map<String, dynamic> payload) {
    final type = payload['type'] as String?;
    final navigate = payload['navigate'] as String?;
    final auctionId = payload['auctionId'] as String?;
    final lotId = payload['lotId'] as String?;

    print('📱 Handling notification tap - Type: $type, Navigate: $navigate');

    switch (navigate) {
      case 'settlement_tracking':
        if (auctionId != null) {
          _navigateToSettlementTracking(context, auctionId);
        }
        break;

      case 'payment_history':
        _navigateToPaymentHistory(context);
        break;

      case 'monitor_auction':
        if (auctionId != null) {
          _navigateToAuctionMonitor(context, auctionId);
        }
        break;

      case 'lot_details':
        if (lotId != null) {
          _navigateToLotDetails(context, lotId);
        }
        break;

      case 'auctions':
        _navigateToAuctions(context);
        break;

      default:
        // Handle based on type if navigate not specified
        _handleByType(context, type, auctionId, lotId);
    }
  }

  static void _handleByType(
      BuildContext context, String? type, String? auctionId, String? lotId) {
    switch (type) {
      case 'auction_settled':
      case 'payment_received':
      case 'auction_no_sale':
        if (auctionId != null) {
          _navigateToSettlementTracking(context, auctionId);
        }
        break;

      case 'auction_sold':
      case 'auction_end':
      case 'bid_update':
        if (auctionId != null) {
          _navigateToAuctionMonitor(context, auctionId);
        }
        break;

      case 'auction_start':
        _navigateToAuctions(context);
        break;

      case 'compliance':
        if (lotId != null) {
          _navigateToLotDetails(context, lotId);
        }
        break;

      default:
        // Navigate to notifications screen as fallback
        _navigateToNotifications(context);
    }
  }

  static void _navigateToSettlementTracking(
      BuildContext context, String auctionId) {
    try {
      // Using Navigator.push since we might not have a named route
      Navigator.of(context).pushNamed(
        '/farmer/settlement-tracking',
        arguments: {'auctionId': auctionId},
      ).catchError((e) {
        print('Navigation error: $e');
        // Fallback to payment history if route doesn't exist
        _navigateToPaymentHistory(context);
        return null;
      });
    } catch (e) {
      print('Error navigating to settlement tracking: $e');
    }
  }

  static void _navigateToPaymentHistory(BuildContext context) {
    try {
      Navigator.of(context)
          .pushNamed('/farmer/payment-history')
          .catchError((e) {
        print('Navigation error: $e');
        return null;
      });
    } catch (e) {
      print('Error navigating to payment history: $e');
    }
  }

  static void _navigateToAuctionMonitor(
      BuildContext context, String auctionId) {
    try {
      Navigator.of(context).pushNamed(
        '/farmer/auction-monitor',
        arguments: {'auctionId': auctionId},
      ).catchError((e) {
        print('Navigation error: $e');
        return null;
      });
    } catch (e) {
      print('Error navigating to auction monitor: $e');
    }
  }

  static void _navigateToAuctions(BuildContext context) {
    try {
      Navigator.of(context).pushNamed('/farmer/auctions').catchError((e) {
        print('Navigation error: $e');
        return null;
      });
    } catch (e) {
      print('Error navigating to auctions: $e');
    }
  }

  static void _navigateToLotDetails(BuildContext context, String lotId) {
    try {
      Navigator.of(context).pushNamed(
        '/farmer/lot-details',
        arguments: {'lotId': lotId},
      ).catchError((e) {
        print('Navigation error: $e');
        return null;
      });
    } catch (e) {
      print('Error navigating to lot details: $e');
    }
  }

  static void _navigateToNotifications(BuildContext context) {
    try {
      Navigator.of(context).pushNamed('/farmer/notifications').catchError((e) {
        print('Navigation error: $e');
        return null;
      });
    } catch (e) {
      print('Error navigating to notifications: $e');
    }
  }
}
