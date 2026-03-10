const db = require('../db/database');
const logger = require('../utils/logger');

/**
 * Notification Service
 * Handles creation and management of user notifications in Firestore
 */
class NotificationService {
  constructor() {
    this.firestore = db.getDb();
    this.notificationsCollection = 'notifications';
  }

  /**
   * Create a new notification for a user
   * @param {string} userId - The recipient user ID
   * @param {string} type - Notification type (bid_placed, auction_ended, etc.)
   * @param {string} title - Notification title
   * @param {string} message - Notification message
   * @param {object} data - Additional data (auction_id, amount, etc.)
   */
  async createNotification(userId, type, title, message, data = {}) {
    try {
      const notification = {
        user_id: userId,
        type,
        title,
        message,
        data,
        is_read: false,
        created_at: new Date(),
        updated_at: new Date()
      };

      const notificationRef = await this.firestore
        .collection(this.notificationsCollection)
        .add(notification);

      logger.info('Notification created', {
        notification_id: notificationRef.id,
        user_id: userId,
        type
      });

      return {
        notification_id: notificationRef.id,
        ...notification
      };
    } catch (error) {
      logger.error('Error creating notification:', error);
      throw error;
    }
  }

  /**
   * Create notification for farmer when bid is placed on their auction
   * @param {string} farmerId - Farmer user ID
   * @param {string} auctionId - Auction ID
   * @param {string} bidderName - Name of the bidder
   * @param {string} amountLkr - Bid amount in LKR
   * @param {number} bidCount - Total number of bids
   */
  async notifyBidPlaced(farmerId, auctionId, bidderName, amountLkr, bidCount) {
    try {
      return await this.createNotification(
        farmerId,
        'bid_placed',
        'New Bid Received',
        `${bidderName} placed a bid of LKR ${amountLkr} on your auction (${bidCount} total bids)`,
        {
          auction_id: auctionId,
          bidder_name: bidderName,
          amount_lkr: amountLkr,
          bid_count: bidCount,
          navigate: 'auction_monitor'
        }
      );
    } catch (error) {
      logger.error('Error notifying bid placed:', error);
      throw error;
    }
  }

  /**
   * Create notification when auction ends with winner
   * @param {string} farmerId - Farmer user ID
   * @param {string} auctionId - Auction ID
   * @param {string} winnerName - Name of the winning bidder
   * @param {string} finalAmount - Final bid amount
   */
  async notifyAuctionSold(farmerId, auctionId, winnerName, finalAmount) {
    try {
      return await this.createNotification(
        farmerId,
        'auction_sold',
        'Auction Sold!',
        `Your auction was won by ${winnerName} for LKR ${finalAmount}`,
        {
          auction_id: auctionId,
          winner_name: winnerName,
          final_amount: finalAmount,
          navigate: 'auction_monitor'
        }
      );
    } catch (error) {
      logger.error('Error notifying auction sold:', error);
      throw error;
    }
  }

  /**
   * Create notification when auction ends without bids
   * @param {string} farmerId - Farmer user ID
   * @param {string} auctionId - Auction ID
   */
  async notifyAuctionNoSale(farmerId, auctionId) {
    try {
      return await this.createNotification(
        farmerId,
        'auction_no_sale',
        'Auction Ended',
        'Your auction ended with no bids',
        {
          auction_id: auctionId,
          navigate: 'auction_monitor'
        }
      );
    } catch (error) {
      logger.error('Error notifying auction no sale:', error);
      throw error;
    }
  }

  /**
   * Create notification when auction is settled
   * @param {string} farmerId - Farmer user ID
   * @param {string} auctionId - Auction ID
   * @param {string} finalAmount - Final amount in LKR
   * @param {string} farmerEarnings - Farmer's earnings after deductions
   */
  async notifyAuctionSettled(farmerId, auctionId, finalAmount, farmerEarnings) {
    try {
      return await this.createNotification(
        farmerId,
        'auction_settled',
        'Auction Settled',
        `Your auction has been settled. You earned LKR ${farmerEarnings} (from LKR ${finalAmount})`,
        {
          auction_id: auctionId,
          final_amount: finalAmount,
          farmer_earnings: farmerEarnings,
          navigate: 'auction_monitor'
        }
      );
    } catch (error) {
      logger.error('Error notifying auction settled:', error);
      throw error;
    }
  }

  /**
   * Create notification when payment is received
   * @param {string} farmerId - Farmer user ID
   * @param {string} auctionId - Auction ID
   * @param {string} amount - Payment amount
   * @param {string} currency - Currency (ETH/LKR)
   */
  async notifyPaymentReceived(farmerId, auctionId, amount, currency) {
    try {
      return await this.createNotification(
        farmerId,
        'payment_received',
        'Payment Received',
        `Payment of ${amount} ${currency} has been received for your auction`,
        {
          auction_id: auctionId,
          amount,
          currency,
          navigate: 'auction_monitor'
        }
      );
    } catch (error) {
      logger.error('Error notifying payment received:', error);
      throw error;
    }
  }

  /**
   * Get notifications for a user
   * @param {string} userId - User ID
   * @param {number} limit - Maximum number of notifications to fetch
   * @param {boolean} unreadOnly - Fetch only unread notifications
   */
  async getNotifications(userId, limit = 50, unreadOnly = false) {
    try {
      let query = this.firestore
        .collection(this.notificationsCollection)
        .where('user_id', '==', userId)
        .orderBy('created_at', 'desc')
        .limit(limit);

      if (unreadOnly) {
        query = query.where('is_read', '==', false);
      }

      const snapshot = await query.get();
      
      const notifications = snapshot.docs.map(doc => ({
        notification_id: doc.id,
        ...doc.data(),
        created_at: doc.data().created_at?.toDate?.() || doc.data().created_at,
        updated_at: doc.data().updated_at?.toDate?.() || doc.data().updated_at
      }));

      return notifications;
    } catch (error) {
      logger.error('Error fetching notifications:', error);
      throw error;
    }
  }

  /**
   * Get unread notification count for a user
   * @param {string} userId - User ID
   */
  async getUnreadCount(userId) {
    try {
      const snapshot = await this.firestore
        .collection(this.notificationsCollection)
        .where('user_id', '==', userId)
        .where('is_read', '==', false)
        .count()
        .get();

      return snapshot.data().count;
    } catch (error) {
      logger.error('Error getting unread count:', error);
      throw error;
    }
  }

  /**
   * Mark notifications as read
   * @param {string[]} notificationIds - Array of notification IDs to mark as read
   */
  async markAsRead(notificationIds) {
    try {
      const batch = this.firestore.batch();

      for (const notificationId of notificationIds) {
        const notificationRef = this.firestore
          .collection(this.notificationsCollection)
          .doc(notificationId);
        
        batch.update(notificationRef, {
          is_read: true,
          updated_at: new Date()
        });
      }

      await batch.commit();

      logger.info('Notifications marked as read', {
        count: notificationIds.length,
        notification_ids: notificationIds
      });

      return true;
    } catch (error) {
      logger.error('Error marking notifications as read:', error);
      throw error;
    }
  }

  /**
   * Delete old read notifications (cleanup)
   * @param {number} daysOld - Delete notifications older than this many days
   */
  async deleteOldNotifications(daysOld = 30) {
    try {
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - daysOld);

      const snapshot = await this.firestore
        .collection(this.notificationsCollection)
        .where('is_read', '==', true)
        .where('created_at', '<', cutoffDate)
        .get();

      const batch = this.firestore.batch();
      snapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
      });

      await batch.commit();

      logger.info('Old notifications deleted', {
        count: snapshot.docs.length,
        days_old: daysOld
      });

      return snapshot.docs.length;
    } catch (error) {
      logger.error('Error deleting old notifications:', error);
      throw error;
    }
  }

  /**
   * Get farmer user ID from wallet address
   * @param {string} walletAddress - Farmer's wallet address
   * @returns {string|null} - Farmer user ID or null if not found
   */
  async getFarmerIdFromWallet(walletAddress) {
    try {
      const snapshot = await this.firestore
        .collection('users')
        .where('wallet_address_lower', '==', walletAddress.toLowerCase())
        .where('role', '==', 'farmer')
        .limit(1)
        .get();

      if (snapshot.empty) {
        logger.warn('Farmer not found for wallet address', { walletAddress });
        return null;
      }

      return snapshot.docs[0].id;
    } catch (error) {
      logger.error('Error getting farmer ID from wallet:', error);
      return null;
    }
  }
}

module.exports = new NotificationService();
