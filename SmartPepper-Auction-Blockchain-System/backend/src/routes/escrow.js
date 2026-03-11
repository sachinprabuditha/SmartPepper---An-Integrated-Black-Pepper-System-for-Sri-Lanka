const express = require('express');
const router = express.Router();
const { ethers } = require('ethers');
const admin = require('firebase-admin');
const logger = require('../utils/logger');

const db = admin.firestore();

/**
 * POST /api/escrow/deposit
 * Record escrow deposit transaction
 */
router.post('/deposit', async (req, res) => {
  try {
    const {
      auctionId,
      exporterAddress,
      amount,
      txHash,
      userId
    } = req.body;

    logger.info('Recording escrow deposit', {
      auctionId,
      exporterAddress,
      amount,
      txHash
    });

    // Validate inputs
    if (!auctionId || !exporterAddress || !amount || !txHash) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields'
      });
    }

    // Convert auctionId to string for Firestore document path
    const auctionIdStr = String(auctionId);

    // Record escrow in database
    const escrowData = {
      auction_id: auctionIdStr,
      exporter_address: exporterAddress,
      amount,
      tx_hash: txHash,
      user_id: userId || null,
      status: 'deposited',
      deposited_at: admin.firestore.FieldValue.serverTimestamp(),
      created_at: admin.firestore.FieldValue.serverTimestamp()
    };

    const docRef = await db.collection('escrow_deposits').add(escrowData);

    // Update auction status
    const auctionRef = db.collection('auctions').doc(auctionIdStr);
    await auctionRef.update({
      escrow_deposited: true,
      escrow_amount: amount,
      escrow_tx_hash: txHash,
      settlement_status: 'escrow_received',
      admin_settlement_approved: false,
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    });

    logger.info('Escrow deposit recorded successfully', {
      escrowId: docRef.id,
      auctionId
    });

    const doc = await docRef.get();
    res.json({
      success: true,
      escrow: { id: doc.id, ...doc.data() }
    });
  } catch (error) {
    logger.error('Error recording escrow deposit:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to record escrow deposit'
    });
  }
});

/**
 * GET /api/escrow/status/:auctionId
 * Get escrow status for an auction
 */
router.get('/status/:auctionId', async (req, res) => {
  try {
    const { auctionId } = req.params;

    logger.info(`Fetching escrow status for auction ${auctionId}`);

    // Get auction with escrow info
    const auctionDoc = await db.collection('auctions').doc(auctionId).get();

    if (!auctionDoc.exists) {
      return res.status(404).json({
        success: false,
        error: 'Auction not found'
      });
    }

    const auction = { id: auctionDoc.id, ...auctionDoc.data() };

    // Get escrow deposit record if exists
    const escrowSnapshot = await db.collection('escrow_deposits')
      .where('auction_id', '==', auctionId)
      .orderBy('deposited_at', 'desc')
      .limit(1)
      .get();

    let escrowRecord = null;
    if (!escrowSnapshot.empty) {
      const doc = escrowSnapshot.docs[0];
      escrowRecord = { id: doc.id, ...doc.data() };
    }

    // Calculate time remaining to deposit
    const endTime = auction.end_time.toDate();
    const depositDeadline = new Date(endTime.getTime() + 24 * 60 * 60 * 1000); // 24 hours after end
    const now = new Date();
    const timeRemaining = depositDeadline - now;
    const hoursRemaining = Math.max(0, Math.floor(timeRemaining / (1000 * 60 * 60)));

    res.json({
      success: true,
      escrowStatus: {
        auctionId: auction.id,
        auctionStatus: auction.status,
        escrowDeposited: auction.escrow_deposited || false,
        escrowAmount: auction.escrow_amount,
        escrowTxHash: auction.escrow_tx_hash,
        requiredAmount: auction.current_bid,
        winner: auction.winner_address || auction.current_bidder,
        depositDeadline: depositDeadline.toISOString(),
        hoursRemaining,
        isExpired: timeRemaining <= 0,
        escrowRecord
      }
    });
  } catch (error) {
    logger.error('Error fetching escrow status:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch escrow status'
    });
  }
});

/**
 * POST /api/escrow/verify
 * Verify escrow transaction on blockchain
 */
router.post('/verify', async (req, res) => {
  try {
    const { auctionId, txHash } = req.body;

    logger.info('Verifying escrow transaction', { auctionId, txHash });

    // Convert auctionId to string for Firestore queries
    const auctionIdStr = String(auctionId);

    // Get blockchain provider
    const provider = new ethers.JsonRpcProvider(process.env.BLOCKCHAIN_RPC_URL || 'http://localhost:8545');
    
    // Get transaction receipt
    const receipt = await provider.getTransactionReceipt(txHash);

    if (!receipt) {
      return res.status(404).json({
        success: false,
        error: 'Transaction not found'
      });
    }

    // Verify transaction was successful
    if (receipt.status !== 1) {
      return res.status(400).json({
        success: false,
        error: 'Transaction failed on blockchain'
      });
    }

    // Update verification status
    const snapshot = await db.collection('escrow_deposits')
      .where('auction_id', '==', auctionIdStr)
      .where('tx_hash', '==', txHash)
      .get();

    const batch = db.batch();
    snapshot.forEach(doc => {
      batch.update(doc.ref, {
        verified: true,
        verified_at: admin.firestore.FieldValue.serverTimestamp()
      });
    });
    await batch.commit();

    logger.info('Escrow transaction verified', { auctionId: auctionIdStr, txHash });

    res.json({
      success: true,
      verified: true,
      blockNumber: receipt.blockNumber,
      confirmations: await provider.getBlockNumber() - receipt.blockNumber
    });
  } catch (error) {
    logger.error('Error verifying escrow transaction:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to verify escrow transaction'
    });
  }
});

/**
 * GET /api/escrow/user/:userId
 * Get all escrow deposits for a user
 */
router.get('/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    logger.info(`Fetching escrow deposits for user ${userId}`);

    // Get escrow deposits for user
    const escrowSnapshot = await db.collection('escrow_deposits')
      .where('user_id', '==', userId)
      .orderBy('deposited_at', 'desc')
      .get();

    const deposits = [];

    // For each escrow, fetch related auction and lot info
    for (const escrowDoc of escrowSnapshot.docs) {
      const escrow = { id: escrowDoc.id, ...escrowDoc.data() };
      
      // Get auction info
      const auctionDoc = await db.collection('auctions').doc(escrow.auction_id).get();
      if (auctionDoc.exists) {
        const auction = auctionDoc.data();
        escrow.auction_status = auction.status;
        escrow.lot_id = auction.lot_id;

        // Get lot info
        if (auction.lot_id) {
          const lotDoc = await db.collection('pepper_lots').doc(auction.lot_id).get();
          if (lotDoc.exists) {
            const lot = lotDoc.data();
            escrow.variety = lot.variety;
            escrow.quantity = lot.quantity;
            escrow.quality = lot.quality;
          }
        }
      }

      deposits.push(escrow);
    }

    res.json({
      success: true,
      count: deposits.length,
      deposits
    });
  } catch (error) {
    logger.error('Error fetching user escrow deposits:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch escrow deposits'
    });
  }
});

module.exports = router;
