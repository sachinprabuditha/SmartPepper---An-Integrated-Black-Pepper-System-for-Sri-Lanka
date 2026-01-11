const express = require('express');
const router = express.Router();
const { ethers } = require('ethers');
const db = require('../db/database');
const logger = require('../utils/logger');

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

    // Record escrow in database
    const result = await db.query(
      `INSERT INTO escrow_deposits (
        auction_id,
        exporter_address,
        amount,
        tx_hash,
        user_id,
        status,
        deposited_at
      ) VALUES ($1, $2, $3, $4, $5, $6, NOW())
      RETURNING *`,
      [auctionId, exporterAddress, amount, txHash, userId, 'deposited']
    );

    // Update auction status
    await db.query(
      `UPDATE auctions 
       SET escrow_deposited = true, escrow_amount = $1, escrow_tx_hash = $2
       WHERE auction_id = $3`,
      [amount, txHash, auctionId]
    );

    logger.info('Escrow deposit recorded successfully', {
      escrowId: result.rows[0].id,
      auctionId
    });

    res.json({
      success: true,
      escrow: result.rows[0]
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
    const auctionResult = await db.query(
      `SELECT 
        auction_id,
        status,
        escrow_deposited,
        escrow_amount,
        escrow_tx_hash,
        current_bid,
        highest_bidder,
        end_time
       FROM auctions
       WHERE auction_id = $1`,
      [auctionId]
    );

    if (auctionResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Auction not found'
      });
    }

    const auction = auctionResult.rows[0];

    // Get escrow deposit record if exists
    const escrowResult = await db.query(
      `SELECT * FROM escrow_deposits
       WHERE auction_id = $1
       ORDER BY deposited_at DESC
       LIMIT 1`,
      [auctionId]
    );

    // Calculate time remaining to deposit
    const endTime = new Date(auction.end_time);
    const depositDeadline = new Date(endTime.getTime() + 24 * 60 * 60 * 1000); // 24 hours after end
    const now = new Date();
    const timeRemaining = depositDeadline - now;
    const hoursRemaining = Math.max(0, Math.floor(timeRemaining / (1000 * 60 * 60)));

    res.json({
      success: true,
      escrowStatus: {
        auctionId: auction.auction_id,
        auctionStatus: auction.status,
        escrowDeposited: auction.escrow_deposited || false,
        escrowAmount: auction.escrow_amount,
        escrowTxHash: auction.escrow_tx_hash,
        requiredAmount: auction.current_bid,
        winner: auction.highest_bidder,
        depositDeadline: depositDeadline.toISOString(),
        hoursRemaining,
        isExpired: timeRemaining <= 0,
        escrowRecord: escrowResult.rows[0] || null
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
    await db.query(
      `UPDATE escrow_deposits 
       SET verified = true, verified_at = NOW()
       WHERE auction_id = $1 AND tx_hash = $2`,
      [auctionId, txHash]
    );

    logger.info('Escrow transaction verified', { auctionId, txHash });

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

    const result = await db.query(
      `SELECT 
        e.*,
        a.auction_id,
        a.lot_id,
        a.status as auction_status,
        p.variety,
        p.quantity,
        p.quality
       FROM escrow_deposits e
       JOIN auctions a ON e.auction_id = a.auction_id
       LEFT JOIN pepper_lots p ON a.lot_id = p.lot_id
       WHERE e.user_id = $1
       ORDER BY e.deposited_at DESC`,
      [userId]
    );

    res.json({
      success: true,
      count: result.rows.length,
      deposits: result.rows
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
