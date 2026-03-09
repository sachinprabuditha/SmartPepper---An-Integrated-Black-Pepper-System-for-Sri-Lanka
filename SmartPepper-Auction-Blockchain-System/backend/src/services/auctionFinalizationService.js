const admin = require('firebase-admin');
const logger = require('../utils/logger');
const BlockchainService = require('./blockchainService');
const notificationService = require('./notificationService');
const currencyConverter = require('../utils/currencyConverter');

/**
 * Auction Finalization Service
 * Handles automatic auction completion, blockchain settlement, and winner notifications
 */
class AuctionFinalizationService {
  constructor() {
    this.blockchainService = new BlockchainService();
    this.processingQueue = new Set(); // Prevent duplicate processing
  }

  async initialize() {
    try {
      await this.blockchainService.initialize();
      logger.info('✅ Auction Finalization Service initialized');
    } catch (error) {
      logger.warn('⚠️ Blockchain service initialization failed - auctions will end without blockchain finalization:', error.message);
    }
  }

  /**
   * Process newly ended auctions
   * Called when auction status changes from 'active' to 'ended'
   */
  async finalizeEndedAuctions(endedAuctionIds) {
    if (!endedAuctionIds || endedAuctionIds.length === 0) {
      return { success: 0, failed: 0 };
    }

    const firestore = admin.firestore();
    let successCount = 0;
    let failedCount = 0;

    for (const auctionId of endedAuctionIds) {
      // Skip if already processing
      if (this.processingQueue.has(auctionId)) {
        logger.info(`⏭️ Skipping auction ${auctionId} - already processing`);
        continue;
      }

      this.processingQueue.add(auctionId);

      try {
        // Get auction details
        const auctionDoc = await firestore.collection('auctions').doc(auctionId).get();
        
        if (!auctionDoc.exists) {
          logger.error(`❌ Auction ${auctionId} not found`);
          failedCount++;
          continue;
        }

        const auction = auctionDoc.data();
        
        // Only process if status is 'ended' and not already finalized
        if (auction.status !== 'ended' || auction.finalized) {
          logger.info(`⏭️ Skipping auction ${auctionId} - status: ${auction.status}, finalized: ${auction.finalized}`);
          continue;
        }

        logger.info(`🔄 Finalizing auction ${auctionId}...`);

        // Check if there's a winning bid
        const hasWinner = auction.current_bid && 
                         auction.current_bidder && 
                         parseFloat(auction.current_bid) >= parseFloat(auction.reserve_price || auction.start_price);

        if (hasWinner) {
          await this.processSuccessfulAuction(auctionDoc, auction);
          successCount++;
        } else {
          await this.processFailedAuction(auctionDoc, auction);
          successCount++;
        }

      } catch (error) {
        logger.error(`❌ Failed to finalize auction ${auctionId}:`, error);
        failedCount++;
      } finally {
        this.processingQueue.delete(auctionId);
      }
    }

    return { success: successCount, failed: failedCount };
  }

  /**
   * Process auction with winning bid
   */
  async processSuccessfulAuction(auctionDoc, auction) {
    const firestore = admin.firestore();
    const auctionId = auctionDoc.id;
    const updates = {
      finalized: true,
      finalized_at: admin.firestore.FieldValue.serverTimestamp(),
      winner_address: auction.current_bidder,
      final_price: auction.current_bid,
      final_price_lkr: auction.current_bid_lkr || currencyConverter.ethToLkr(parseFloat(auction.current_bid)).toString(),
      settlement_status: 'pending_escrow'
    };

    // Try to finalize on blockchain
    if (auction.blockchain_auction_id) {
      try {
        logger.info(`📝 Calling blockchain endAuction for auction ${auctionId}...`);
        const txHash = await this.blockchainService.endAuction(auction.blockchain_auction_id);
        
        updates.blockchain_finalization_tx = txHash;
        updates.blockchain_finalized = true;
        
        logger.info(`✅ Blockchain auction ended successfully`, {
          auctionId,
          blockchainId: auction.blockchain_auction_id,
          txHash
        });
      } catch (blockchainError) {
        logger.error(`⚠️ Blockchain finalization failed for auction ${auctionId}:`, blockchainError.message);
        updates.blockchain_finalized = false;
        updates.blockchain_error = blockchainError.message;
      }
    }

    // Update auction
    await auctionDoc.ref.update(updates);

    // Broadcast auction ended via WebSocket
    this.broadcastAuctionEnded(auctionId, auction.current_bidder, auction.current_bid);

    // Create notification for winner
    await this.createWinnerNotification(auction, auctionDoc.id);

    // Create notification for farmer
    await this.createFarmerNotification(auction, auctionDoc.id, 'won');

    // Update lot status
    if (auction.lot_id) {
      await this.updateLotStatus(auction.lot_id, 'sold', auction.current_bidder);
    }

    logger.info(`🎉 Auction ${auctionId} finalized successfully - Winner: ${auction.current_bidder}, Price: ${auction.current_bid} ETH`);
  }

  /**
   * Process auction without winning bid
   */
  async processFailedAuction(auctionDoc, auction) {
    const auctionId = auctionDoc.id;
    const updates = {
      finalized: true,
      finalized_at: admin.firestore.FieldValue.serverTimestamp(),
      settlement_status: 'no_winner',
      status: 'failed' // Change status to failed
    };

    // Try to finalize on blockchain (refund any escrow)
    if (auction.blockchain_auction_id) {
      try {
        logger.info(`📝 Calling blockchain endAuction for failed auction ${auctionId}...`);
        const txHash = await this.blockchainService.endAuction(auction.blockchain_auction_id);
        
        updates.blockchain_finalization_tx = txHash;
        updates.blockchain_finalized = true;
        
        logger.info(`✅ Blockchain auction ended (no winner)`, {
          auctionId,
          blockchainId: auction.blockchain_auction_id,
          txHash
        });
      } catch (blockchainError) {
        logger.error(`⚠️ Blockchain finalization failed:`, blockchainError.message);
        updates.blockchain_finalized = false;
        updates.blockchain_error = blockchainError.message;
      }
    }

    await auctionDoc.ref.update(updates);

    // Create notification for farmer
    await this.createFarmerNotification(auction, auctionDoc.id, 'failed');

    // Update lot status back to available
    if (auction.lot_id) {
      await this.updateLotStatus(auction.lot_id, 'available', null);
    }

    logger.info(`❌ Auction ${auctionId} ended without winner - No bids met reserve price`);
  }

  /**
   * Create notification for auction winner
   */
  async createWinnerNotification(auction, auctionId) {
    try {
      const firestore = admin.firestore();
      
      // Get winner user ID from wallet address
      const winnerSnapshot = await firestore.collection('users')
        .where('wallet_address_lower', '==', auction.current_bidder.toLowerCase())
        .limit(1)
        .get();
      
      if (winnerSnapshot.empty) {
        logger.warn('Winner user not found for wallet address', { wallet: auction.current_bidder });
        return;
      }
      
      const winnerId = winnerSnapshot.docs[0].id;
      const bidAmountLkr = auction.current_bid_lkr || (await currencyConverter.convertToLkr(parseFloat(auction.current_bid))).toFixed(2);
      
      await notificationService.createNotification(
        winnerId,
        'auction_won',
        'Congratulations! You Won the Auction',
        `You won auction for ${auction.lot_id || 'lot'}. Price: LKR ${bidAmountLkr} (${auction.current_bid} ETH). Please proceed with payment.`,
        {
          auction_id: auctionId,
          lot_id: auction.lot_id,
          final_price: auction.current_bid,
          final_price_lkr: bidAmountLkr,
          action_required: 'payment',
          navigate: 'auction_monitor'
        }
      );

      logger.info(`📧 Winner notification created for ${auction.current_bidder}`);
    } catch (error) {
      logger.error('Failed to create winner notification:', error);
    }
  }

  /**
   * Create notification for farmer
   */
  async createFarmerNotification(auction, auctionId, outcome) {
    try {
      // Get farmer user ID from wallet address
      const farmerId = await notificationService.getFarmerIdFromWallet(auction.farmer_address);
      
      if (!farmerId) {
        logger.warn('Farmer user not found for wallet address', { wallet: auction.farmer_address });
        return;
      }
      
      if (outcome === 'won') {
        // Auction sold with winner
        const finalAmountLkr = auction.current_bid_lkr || (await currencyConverter.convertToLkr(parseFloat(auction.current_bid))).toFixed(2);
        const winnerName = auction.current_bidder_name || auction.current_bidder;
        
        await notificationService.notifyAuctionSold(
          farmerId,
          auctionId,
          winnerName,
          finalAmountLkr
        );
      } else {
        // Auction ended without sale
        await notificationService.notifyAuctionNoSale(
          farmerId,
          auctionId
        );
      }

      logger.info(`📧 Farmer notification created for ${auction.farmer_address}`, { outcome });
    } catch (error) {
      logger.error('Failed to create farmer notification:', error);
    }
  }

  /**
   * Update lot status after auction
   */
  async updateLotStatus(lotId, status, newOwner = null) {
    try {
      const firestore = admin.firestore();
      
      const lotSnapshot = await firestore.collection('pepper_lots')
        .where('lot_id', '==', lotId)
        .limit(1)
        .get();

      if (!lotSnapshot.empty) {
        const updates = {
          status,
          updated_at: admin.firestore.FieldValue.serverTimestamp()
        };

        if (newOwner) {
          updates.current_owner = newOwner.toLowerCase();
        }

        await lotSnapshot.docs[0].ref.update(updates);
        logger.info(`📦 Lot ${lotId} status updated to: ${status}`);
      }
    } catch (error) {
      logger.error(`Failed to update lot status for ${lotId}:`, error);
    }
  }

  /**
   * Process escrow deposit (called when winner pays)
   */
  async processEscrowDeposit(auctionId, winnerAddress, txHash) {
    try {
      const firestore = admin.firestore();
      const auctionDoc = await firestore.collection('auctions').doc(auctionId).get();

      if (!auctionDoc.exists) {
        throw new Error('Auction not found');
      }

      const auction = auctionDoc.data();

      await auctionDoc.ref.update({
        settlement_status: 'escrow_received',
        escrow_tx_hash: txHash,
        escrow_received_at: admin.firestore.FieldValue.serverTimestamp()
      });

      // Trigger automatic settlement
      await this.settleAuction(auctionId);

      logger.info(`💰 Escrow deposit processed for auction ${auctionId}`);
    } catch (error) {
      logger.error(`Failed to process escrow deposit:`, error);
      throw error;
    }
  }

  /**
   * Settle auction and distribute funds
   */
  async settleAuction(auctionId) {
    try {
      const firestore = admin.firestore();
      const auctionDoc = await firestore.collection('auctions').doc(auctionId).get();

      if (!auctionDoc.exists) {
        throw new Error('Auction not found');
      }

      const auction = auctionDoc.data();

      // Call blockchain settlement
      if (auction.blockchain_auction_id) {
        logger.info(`💸 Calling blockchain settleAuction for ${auctionId}...`);
        const txHash = await this.blockchainService.settleAuction(auction.blockchain_auction_id);

        await auctionDoc.ref.update({
          settlement_status: 'settled',
          settlement_tx_hash: txHash,
          settled_at: admin.firestore.FieldValue.serverTimestamp()
        });

        // Create settlement notifications
        await this.createSettlementNotifications(auction, auctionId);

        logger.info(`✅ Auction ${auctionId} settled successfully - Funds distributed`);
      }
    } catch (error) {
      logger.error(`Failed to settle auction ${auctionId}:`, error);
      throw error;
    }
  }

  /**
   * Create notifications after settlement
   */
  async createSettlementNotifications(auction, auctionId) {
    try {
      const firestore = admin.firestore();
      const platformFee = parseFloat(auction.current_bid) * 0.02;
      const farmerAmount = parseFloat(auction.current_bid) - platformFee;

      // Notify buyer
      await firestore.collection('notifications').add({
        user_address: auction.current_bidder.toLowerCase(),
        type: 'auction_settled',
        title: 'Auction Settlement Complete',
        message: `Payment processed. Ownership of ${auction.lot_id || 'lot'} has been transferred to you.`,
        data: {
          auction_id: auctionId,
          lot_id: auction.lot_id
        },
        read: false,
        created_at: admin.firestore.FieldValue.serverTimestamp()
      });

      // Notify farmer
      await firestore.collection('notifications').add({
        user_address: auction.farmer_address.toLowerCase(),
        type: 'payment_received',
        title: 'Payment Received',
        message: `Payment of ${farmerAmount.toFixed(4)} ETH received for ${auction.lot_id || 'lot'} (after ${(platformFee * 100 / parseFloat(auction.current_bid)).toFixed(1)}% platform fee).`,
        data: {
          auction_id: auctionId,
          lot_id: auction.lot_id,
          amount: farmerAmount.toFixed(4),
          platform_fee: platformFee.toFixed(4)
        },
        read: false,
        created_at: admin.firestore.FieldValue.serverTimestamp()
      });

      logger.info(`📧 Settlement notifications created`);
    } catch (error) {
      logger.error('Failed to create settlement notifications:', error);
    }
  }

  /**
   * Broadcast auction ended event via WebSocket
   */
  broadcastAuctionEnded(auctionId, winnerAddress, finalPrice) {
    try {
      // Try to get io instance from global (set by server.js)
      if (global.io) {
        const auctionNamespace = global.io.of('/auction');
        auctionNamespace.to(`auction_${auctionId}`).emit('auction_ended', {
          auctionId,
          winnerAddress,
          winnerName: `${winnerAddress.substring(0, 6)}...${winnerAddress.substring(38)}`,
          finalPrice,
          timestamp: new Date().toISOString()
        });
        
        logger.info(`📡 WebSocket broadcast: auction_ended for ${auctionId}`);
      }
    } catch (error) {
      logger.error('Failed to broadcast auction ended:', error);
    }
  }
}

// Export singleton
const finalizationService = new AuctionFinalizationService();
module.exports = finalizationService;
