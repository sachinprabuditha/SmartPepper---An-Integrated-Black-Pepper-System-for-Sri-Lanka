const express = require('express');
const router = express.Router();
const db = require('../db/database');
const BlockchainService = require('../services/blockchainService');
const ComplianceService = require('../services/complianceService');
const logger = require('../utils/logger');
const { v4: uuidv4 } = require('uuid');

const blockchainService = new BlockchainService();
const complianceService = new ComplianceService();

// Initialize services
blockchainService.initialize().catch(err => logger.error('Blockchain init failed:', err));
complianceService.initialize().catch(err => logger.error('Compliance init failed:', err));

/**
 * GET /api/auctions
 * Get all auctions with optional filters
 */
router.get('/', async (req, res) => {
  try {
    const { status, farmer, limit = 50, offset = 0 } = req.query;
    
    let query = 'SELECT * FROM auctions WHERE 1=1';
    const params = [];
    let paramIndex = 1;

    if (status) {
      query += ` AND status = $${paramIndex++}`;
      params.push(status);
    }

    if (farmer) {
      query += ` AND farmer_address = $${paramIndex++}`;
      params.push(farmer);
    }

    query += ` ORDER BY created_at DESC LIMIT $${paramIndex++} OFFSET $${paramIndex++}`;
    params.push(limit, offset);

    const result = await db.query(query, params);

    res.json({
      success: true,
      count: result.rows.length,
      auctions: result.rows
    });
  } catch (error) {
    logger.error('Error fetching auctions:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch auctions'
    });
  }
});

/**
 * GET /api/auctions/:id
 * Get auction details by ID
 */
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await db.query(
      'SELECT * FROM auctions WHERE auction_id = $1',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Auction not found'
      });
    }

    // Get bids
    const bidsResult = await db.query(
      'SELECT * FROM bids WHERE auction_id = $1 ORDER BY timestamp DESC',
      [id]
    );

    res.json({
      success: true,
      auction: result.rows[0],
      bids: bidsResult.rows
    });
  } catch (error) {
    logger.error('Error fetching auction:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch auction'
    });
  }
});

/**
 * POST /api/auctions
 * Create a new auction
 */
router.post('/', async (req, res) => {
  try {
    const {
      lotId,
      farmerAddress,
      startPrice,
      reservePrice,
      duration
    } = req.body;

    // Validate inputs
    if (!lotId || !farmerAddress || !startPrice || !reservePrice || !duration) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields'
      });
    }

    // Check if lot exists
    const lotResult = await db.query(
      'SELECT * FROM pepper_lots WHERE lot_id = $1',
      [lotId]
    );

    if (lotResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Lot not found'
      });
    }

    const lot = lotResult.rows[0];

    // Get farmer ID
    const farmerResult = await db.query(
      'SELECT id FROM users WHERE wallet_address = $1',
      [farmerAddress]
    );

    const farmerId = farmerResult.rows.length > 0 ? farmerResult.rows[0].id : null;

    // Create auction on blockchain
    const blockchainResult = await blockchainService.createAuction({
      lotId,
      startPrice,
      reservePrice,
      duration: parseInt(duration)
    });

    const startTime = new Date();
    const endTime = new Date(startTime.getTime() + parseInt(duration) * 1000);

    // Store in database
    const insertResult = await db.query(
      `INSERT INTO auctions (
        auction_id, lot_id, farmer_id, farmer_address,
        start_price, reserve_price, start_time, end_time,
        status, blockchain_tx_hash
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
      RETURNING *`,
      [
        parseInt(blockchainResult.auctionId),
        lotId,
        farmerId,
        farmerAddress,
        startPrice,
        reservePrice,
        startTime,
        endTime,
        'created',
        blockchainResult.txHash
      ]
    );

    // Run compliance check
    const complianceResult = await complianceService.checkCompliance({
      lotId: lot.lot_id,
      certificateHash: lot.certificate_hash,
      certificateIpfsUrl: lot.certificate_ipfs_url
    });

    // Store compliance results
    for (const result of complianceResult.results) {
      await db.query(
        `INSERT INTO compliance_checks (
          lot_id, auction_id, rule_name, rule_type, passed, details
        ) VALUES ($1, $2, $3, $4, $5, $6)`,
        [
          lotId,
          parseInt(blockchainResult.auctionId),
          result.ruleName,
          result.ruleType,
          result.passed,
          JSON.stringify(result.details)
        ]
      );
    }

    // Set compliance status on blockchain
    await blockchainService.setComplianceStatus(
      parseInt(blockchainResult.auctionId),
      complianceResult.passed
    );

    // Update auction status in database
    await db.query(
      'UPDATE auctions SET compliance_passed = $1, status = $2 WHERE auction_id = $3',
      [complianceResult.passed, complianceResult.passed ? 'active' : 'failed_compliance', parseInt(blockchainResult.auctionId)]
    );

    res.status(201).json({
      success: true,
      auction: insertResult.rows[0],
      compliance: complianceResult
    });
  } catch (error) {
    logger.error('Error creating auction:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to create auction',
      details: error.message
    });
  }
});

/**
 * POST /api/auctions/:id/bid
 * Place a bid on an auction
 */
router.post('/:id/bid', async (req, res) => {
  try {
    const { id } = req.params;
    const { bidderAddress, amount, txHash } = req.body;

    if (!bidderAddress || !amount || !txHash) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields'
      });
    }

    // Get bidder ID
    const bidderResult = await db.query(
      'SELECT id FROM users WHERE wallet_address = $1',
      [bidderAddress]
    );

    const bidderId = bidderResult.rows.length > 0 ? bidderResult.rows[0].id : null;

    // Store bid in database
    const result = await db.query(
      `INSERT INTO bids (
        auction_id, bidder_id, bidder_address, amount, blockchain_tx_hash
      ) VALUES ($1, $2, $3, $4, $5)
      RETURNING *`,
      [parseInt(id), bidderId, bidderAddress, amount, txHash]
    );

    // Update auction
    await db.query(
      `UPDATE auctions 
       SET current_bid = $1, current_bidder_address = $2, bid_count = bid_count + 1
       WHERE auction_id = $3`,
      [amount, bidderAddress, parseInt(id)]
    );

    // Broadcast via WebSocket (will be handled by websocket service)
    
    res.status(201).json({
      success: true,
      bid: result.rows[0]
    });
  } catch (error) {
    logger.error('Error placing bid:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to place bid',
      details: error.message
    });
  }
});

/**
 * POST /api/auctions/:id/end
 * End an auction
 */
router.post('/:id/end', async (req, res) => {
  try {
    const { id } = req.params;

    const result = await db.query(
      'SELECT * FROM auctions WHERE auction_id = $1',
      [parseInt(id)]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Auction not found'
      });
    }

    const auction = result.rows[0];

    // Update status
    await db.query(
      'UPDATE auctions SET status = $1 WHERE auction_id = $2',
      ['ended', parseInt(id)]
    );

    res.json({
      success: true,
      message: 'Auction ended successfully',
      auction: { ...auction, status: 'ended' }
    });
  } catch (error) {
    logger.error('Error ending auction:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to end auction'
    });
  }
});

/**
 * POST /api/auctions/:id/settle
 * Settle an auction
 */
router.post('/:id/settle', async (req, res) => {
  try {
    const { id } = req.params;

    const result = await db.query(
      'SELECT * FROM auctions WHERE auction_id = $1',
      [parseInt(id)]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Auction not found'
      });
    }

    const auction = result.rows[0];

    if (auction.status !== 'ended') {
      return res.status(400).json({
        success: false,
        error: 'Auction must be ended before settling'
      });
    }

    // Update status
    await db.query(
      'UPDATE auctions SET status = $1 WHERE auction_id = $2',
      ['settled', parseInt(id)]
    );

    // Update lot status
    await db.query(
      'UPDATE pepper_lots SET status = $1 WHERE lot_id = $2',
      ['sold', auction.lot_id]
    );

    res.json({
      success: true,
      message: 'Auction settled successfully'
    });
  } catch (error) {
    logger.error('Error settling auction:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to settle auction'
    });
  }
});

module.exports = router;
