const express = require('express');
const router = express.Router();
const db = require('../db/database');
const BlockchainService = require('../services/blockchainService');
const ComplianceService = require('../services/complianceService');
const currencyConverter = require('../utils/currencyConverter');
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
    
    let query = `
      SELECT 
        a.*,
        p.variety,
        p.quantity,
        p.quality,
        p.origin
      FROM auctions a
      LEFT JOIN pepper_lots p ON a.lot_id = p.lot_id
      WHERE 1=1
    `;
    let countQuery = 'SELECT COUNT(*) FROM auctions WHERE 1=1';
    const params = [];
    const countParams = [];
    let paramIndex = 1;
    let countParamIndex = 1;

    if (status) {
      query += ` AND a.status = $${paramIndex++}`;
      countQuery += ` AND status = $${countParamIndex++}`;
      params.push(status);
      countParams.push(status);
    }

    if (farmer) {
      query += ` AND LOWER(a.farmer_address) = LOWER($${paramIndex++})`;
      countQuery += ` AND LOWER(farmer_address) = LOWER($${countParamIndex++})`;
      params.push(farmer);
      countParams.push(farmer);
    }

    query += ` ORDER BY a.created_at DESC LIMIT $${paramIndex++} OFFSET $${paramIndex++}`;
    params.push(limit, offset);

    const [result, countResult] = await Promise.all([
      db.query(query, params),
      db.query(countQuery, countParams)
    ]);

    res.json({
      success: true,
      count: parseInt(countResult.rows[0].count),
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
      'SELECT * FROM bids WHERE auction_id = $1 ORDER BY placed_at DESC',
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
 * GET /api/auctions/check-eligibility/:lotId
 * Check if a lot is eligible for auction creation
 * Validates all preconditions before allowing auction creation
 */
router.get('/check-eligibility/:lotId', async (req, res) => {
  try {
    const { lotId } = req.params;
    const reasons = [];
    let eligible = true;

    // 1. Check if lot exists
    const lotResult = await db.query(
      'SELECT * FROM pepper_lots WHERE lot_id = $1',
      [lotId]
    );

    if (lotResult.rows.length === 0) {
      eligible = false;
      reasons.push('Pepper lot does not exist in the system');
      return res.json({ eligible, reasons });
    }

    const lot = lotResult.rows[0];

    // 2. Check if lot is approved/available
    if (lot.status !== 'approved' && lot.status !== 'available') {
      eligible = false;
      reasons.push(`Lot status is "${lot.status}". Only approved or available lots can be auctioned.`);
    }

    // 3. Check if lot already has an active auction
    const activeAuctionResult = await db.query(
      `SELECT * FROM auctions 
       WHERE lot_id = $1 
       AND status IN ('created', 'active', 'pending')
       LIMIT 1`,
      [lotId]
    );

    if (activeAuctionResult.rows.length > 0) {
      eligible = false;
      reasons.push('This lot already has an active auction');
    }

    // 4. Check if required certificates are uploaded
    const certsResult = await db.query(
      `SELECT COUNT(*) as cert_count 
       FROM certifications 
       WHERE lot_id = $1`,
      [lotId]
    );

    const certCount = parseInt(certsResult.rows[0].cert_count);
    if (certCount < 3) {
      eligible = false;
      reasons.push(`Insufficient certificates uploaded. Found ${certCount}, minimum 3 required.`);
    }

    // 5. Check compliance status
    const complianceResult = await db.query(
      `SELECT passed, rule_name, rule_type, details, checked_at
       FROM compliance_checks
       WHERE lot_id = $1
       ORDER BY checked_at DESC
       LIMIT 1`,
      [lotId]
    );

    if (complianceResult.rows.length === 0) {
      eligible = false;
      reasons.push('No compliance checks have been performed for this lot');
    } else {
      const compliance = complianceResult.rows[0];
      
      if (!compliance.passed) {
        const details = compliance.details || {};
        eligible = false;
        reasons.push(`Compliance check "${compliance.rule_name}" failed. Rule type: ${compliance.rule_type}`);
      }
    }

    // 6. Check if lot has processing stages (traceability)
    const stagesResult = await db.query(
      `SELECT COUNT(*) as stage_count 
       FROM processing_stages 
       WHERE lot_id = $1`,
      [lotId]
    );

    const stageCount = parseInt(stagesResult.rows[0].stage_count);
    if (stageCount < 2) {
      eligible = false;
      reasons.push(`Insufficient processing stages. Found ${stageCount}, minimum 2 required for traceability.`);
    }

    // 7. Check if lot has blockchain passport (minted NFT)
    if (!lot.blockchain_tx_hash || lot.blockchain_tx_hash.trim() === '') {
      eligible = false;
      reasons.push('Lot does not have a blockchain passport (NFT not minted)');
    }

    res.json({
      eligible,
      reasons: eligible ? [] : reasons,
      lot: {
        lotId: lot.lot_id,
        variety: lot.variety,
        quantity: lot.quantity,
        status: lot.status,
        certificateCount: certCount,
        stageCount: stageCount,
        hasBlockchainPassport: !!lot.blockchain_tx_hash
      }
    });

  } catch (error) {
    logger.error('Error checking auction eligibility:', error);
    res.status(500).json({
      eligible: false,
      reasons: ['Internal server error while checking eligibility'],
      error: error.message
    });
  }
});

/**
 * POST /api/auctions
 * Create a new auction (Governance-based approach)
 * 
 * Flow:
 * 1. Validate farmer inputs
 * 2. Check all preconditions (eligibility)
 * 3. Prepare auction payload
 * 4. Create immutable on-chain record
 * 5. Store off-chain volatile data
 * 6. Schedule auction activation
 */
router.post('/', async (req, res) => {
  try {
    const {
      lotId,
      farmerAddress,
      reservePrice,
      currency = 'ETH', // NEW - currency field (LKR or ETH)
      reservePriceEth, // NEW - pre-converted ETH value from mobile
      quantity,
      duration, // in days
      startTime,
      endTime,
      preferredDestinations = [],
      templateId // NEW - Governance template
    } = req.body;

    // === STEP 1: Validate Required Inputs ===
    if (!lotId || !farmerAddress || !reservePrice || !quantity || !duration) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields',
        required: ['lotId', 'farmerAddress', 'reservePrice', 'quantity', 'duration']
      });
    }

    // Load exchange rates for conversion
    await currencyConverter.loadRates();

    // Validate numeric inputs
    const reservePriceNum = parseFloat(reservePrice);
    
    // Handle currency conversion
    let reservePriceInEth;
    let reservePriceInLkr;
    
    if (currency === 'LKR') {
      // If farmer provided LKR, use their pre-converted ETH or convert here
      reservePriceInLkr = reservePriceNum;
      reservePriceInEth = reservePriceEth 
        ? parseFloat(reservePriceEth) 
        : currencyConverter.lkrToEth(reservePriceNum);
      
      logger.info('LKR auction', { 
        lkr: reservePriceInLkr, 
        eth: reservePriceInEth,
        preConverted: !!reservePriceEth 
      });
    } else {
      // If exporter/web provided ETH
      reservePriceInEth = reservePriceNum;
      reservePriceInLkr = currencyConverter.ethToLkr(reservePriceNum);
      
      logger.info('ETH auction', { 
        eth: reservePriceInEth, 
        lkr: reservePriceInLkr 
      });
    }
    const quantityNum = parseFloat(quantity);
    const durationNum = parseInt(duration);

    if (isNaN(reservePriceNum) || reservePriceNum <= 0) {
      return res.status(400).json({
        success: false,
        error: 'Reserve price must be a positive number'
      });
    }

    if (isNaN(quantityNum) || quantityNum <= 0) {
      return res.status(400).json({
        success: false,
        error: 'Quantity must be a positive number'
      });
    }

    if (isNaN(durationNum) || durationNum < 1 || durationNum > 30) {
      return res.status(400).json({
        success: false,
        error: 'Duration must be between 1 and 30 days'
      });
    }

    // === GOVERNANCE VALIDATION ===
    // Fetch governance settings
    const settingsResult = await db.query('SELECT * FROM governance_settings LIMIT 1');
    const settings = settingsResult.rows[0];

    if (!settings) {
      return res.status(500).json({
        success: false,
        error: 'Governance settings not configured'
      });
    }

    // Convert duration to hours for validation
    const durationHours = durationNum * 24;

    // Validate against global settings
    if (!settings.allowed_durations.includes(durationHours)) {
      return res.status(400).json({
        success: false,
        error: `Duration not allowed. Allowed durations: ${settings.allowed_durations.map(h => h / 24).join(', ')} days`
      });
    }

    // Validate against governance settings (use appropriate currency)
    const priceToValidate = currency === 'LKR' ? reservePriceInLkr : reservePriceInEth;
    const minPrice = parseFloat(currency === 'LKR' ? settings.min_reserve_price_lkr || settings.min_reserve_price : settings.min_reserve_price);
    const maxPrice = parseFloat(currency === 'LKR' ? settings.max_reserve_price_lkr || settings.max_reserve_price : settings.max_reserve_price);
    
    if (priceToValidate < minPrice) {
      return res.status(400).json({
        success: false,
        error: `Reserve price must be at least ${minPrice} ${currency}`
      });
    }

    if (priceToValidate > maxPrice) {
      return res.status(400).json({
        success: false,
        error: `Reserve price cannot exceed ${maxPrice} ${currency}`
      });
    }

    // Template-specific validation
    let template = null;
    let requiresApproval = settings.requires_admin_approval;
    let minBidIncrement = parseFloat(settings.default_bid_increment);

    if (templateId) {
      const templateResult = await db.query(
        'SELECT * FROM auction_rule_templates WHERE template_id = $1 AND active = true',
        [templateId]
      );

      if (templateResult.rows.length === 0) {
        return res.status(400).json({
          success: false,
          error: 'Invalid or inactive template'
        });
      }

      template = templateResult.rows[0];

      // Validate against template rules
      if (durationHours < template.min_duration_hours) {
        return res.status(400).json({
          success: false,
          error: `Duration must be at least ${template.min_duration_hours / 24} days for ${template.name}`
        });
      }

      if (durationHours > template.max_duration_hours) {
        return res.status(400).json({
          success: false,
          error: `Duration cannot exceed ${template.max_duration_hours / 24} days for ${template.name}`
        });
      }

      if (template.max_reserve_price && reservePriceNum > parseFloat(template.max_reserve_price)) {
        return res.status(400).json({
          success: false,
          error: `Reserve price cannot exceed ${template.max_reserve_price} LKR for ${template.name}`
        });
      }

      requiresApproval = template.requires_approval;
      minBidIncrement = parseFloat(template.min_bid_increment);
    }

    // === STEP 2: Check Eligibility (All Preconditions) ===
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

    // Verify farmer ownership
    if (lot.farmer_address.toLowerCase() !== farmerAddress.toLowerCase()) {
      return res.status(403).json({
        success: false,
        error: 'You do not own this lot'
      });
    }

    // Check quantity availability
    if (quantityNum > lot.quantity) {
      return res.status(400).json({
        success: false,
        error: `Requested quantity (${quantityNum} kg) exceeds available quantity (${lot.quantity} kg)`
      });
    }

    // Run full eligibility check
    const eligibilityReasons = [];
    let eligible = true;

    // Check lot status
    if (lot.status !== 'approved' && lot.status !== 'available') {
      eligible = false;
      eligibilityReasons.push(`Lot status must be "approved" or "available", currently "${lot.status}"`);
    }

    // Check for active auctions
    const activeAuctionResult = await db.query(
      `SELECT * FROM auctions 
       WHERE lot_id = $1 
       AND status IN ('created', 'active', 'pending', 'scheduled')
       LIMIT 1`,
      [lotId]
    );

    if (activeAuctionResult.rows.length > 0) {
      eligible = false;
      eligibilityReasons.push('This lot already has an active or scheduled auction');
    }

    // Check certificates (minimum 3)
    const certsResult = await db.query(
      `SELECT COUNT(*) as cert_count FROM certifications WHERE lot_id = $1`,
      [lotId]
    );
    const certCount = parseInt(certsResult.rows[0].cert_count);
    if (certCount < 3) {
      eligible = false;
      eligibilityReasons.push(`Minimum 3 certificates required (found ${certCount})`);
    }

    // Check compliance status
    const complianceResult = await db.query(
      `SELECT passed, rule_name, rule_type, details
       FROM compliance_checks
       WHERE lot_id = $1
       ORDER BY checked_at DESC
       LIMIT 1`,
      [lotId]
    );

    if (complianceResult.rows.length === 0) {
      eligible = false;
      eligibilityReasons.push('No compliance checks performed');
    } else {
      const compliance = complianceResult.rows[0];
      if (!compliance.passed) {
        eligible = false;
        eligibilityReasons.push(`Compliance check "${compliance.rule_name}" failed (rule type: ${compliance.rule_type})`);
      }
    }

    // Check processing stages (minimum 2)
    const stagesResult = await db.query(
      `SELECT COUNT(*) as stage_count FROM processing_stages WHERE lot_id = $1`,
      [lotId]
    );
    const stageCount = parseInt(stagesResult.rows[0].stage_count);
    if (stageCount < 2) {
      eligible = false;
      eligibilityReasons.push(`Minimum 2 processing stages required for traceability (found ${stageCount})`);
    }

    // Check blockchain passport
    if (!lot.blockchain_tx_hash || lot.blockchain_tx_hash.trim() === '') {
      eligible = false;
      eligibilityReasons.push('Blockchain passport (NFT) not minted for this lot');
    }

    if (!eligible) {
      return res.status(400).json({
        success: false,
        error: 'Lot is not eligible for auction',
        reasons: eligibilityReasons
      });
    }

    // === STEP 3: Calculate Timestamps ===
    const calculatedStartTime = startTime ? new Date(startTime) : new Date(Date.now() + 3600000); // 1 hour from now
    const calculatedEndTime = endTime 
      ? new Date(endTime) 
      : new Date(calculatedStartTime.getTime() + (durationNum * 24 * 3600000));

    // Validate time range
    if (calculatedEndTime <= calculatedStartTime) {
      return res.status(400).json({
        success: false,
        error: 'End time must be after start time'
      });
    }

    const durationSeconds = Math.floor((calculatedEndTime - calculatedStartTime) / 1000);

    // === STEP 4: Create Immutable On-Chain Record ===
    logger.info('Creating auction on blockchain', {
      lotId,
      reservePrice: reservePriceNum,
      durationSeconds
    });

    const blockchainResult = await blockchainService.createAuction({
      lotId,
      farmer: farmerAddress,
      startPrice: reservePriceNum, // Starting price = reserve price in this model
      reservePrice: reservePriceNum,
      duration: durationSeconds
    });

    // Always use timestamp-based auction ID for database
    // Blockchain IDs start from 0 and are sequential, which can cause conflicts
    // with existing database records. Timestamp ensures uniqueness.
    const blockchainAuctionId = blockchainResult.auctionId ? parseInt(blockchainResult.auctionId) : null;
    const auctionIdNum = Math.floor(Date.now() / 1000);

    logger.info('Blockchain auction created', {
      auctionId: auctionIdNum,
      blockchainAuctionId: blockchainAuctionId,
      txHash: blockchainResult.txHash
    });

    // === STEP 5: Store Off-Chain Data (Volatile + UI preferences) ===
    // Determine initial status based on approval requirement
    const initialStatus = requiresApproval 
      ? 'pending_approval' 
      : (calculatedStartTime > new Date() ? 'created' : 'active');

    const insertResult = await db.query(
      `INSERT INTO auctions (
        auction_id, lot_id, farmer_address,
        start_price, reserve_price, start_time, end_time,
        status, compliance_passed, blockchain_tx_hash,
        template_id, min_bid_increment, admin_approved,
        currency, price_lkr
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
      RETURNING *`,
      [
        auctionIdNum,
        lotId,
        farmerAddress,
        reservePriceInEth, // start_price in ETH (for blockchain)
        reservePriceInEth, // reserve_price in ETH
        calculatedStartTime,
        calculatedEndTime,
        initialStatus,
        true, // compliance_passed - lot is eligible if we reach this point
        blockchainResult.txHash,
        templateId || null,
        minBidIncrement,
        !requiresApproval, // admin_approved = true if no approval needed
        currency, // Store original currency
        reservePriceInLkr // Store LKR equivalent
      ]
    );

    const auction = insertResult.rows[0];

    logger.info('Auction stored in database', {
      auctionId: auction.auction_id,
      status: auction.status,
      startTime: auction.start_time,
      endTime: auction.end_time
    });

    // === STEP 6: Return Success Response ===
    res.status(201).json({
      success: true,
      message: 'Auction created successfully',
      auction: {
        auctionId: auction.auction_id,
        lotId: auction.lot_id,
        farmerAddress: auction.farmer_address,
        reservePrice: auction.reserve_price,
        quantity: quantityNum,
        startTime: auction.start_time,
        endTime: auction.end_time,
        status: auction.status,
        blockchainTxHash: auction.blockchain_tx_hash,
        preferredDestinations,
        onChainData: {
          immutable: true,
          auctionId: auctionIdNum,
          reservePrice: reservePriceNum,
          startTime: calculatedStartTime,
          endTime: calculatedEndTime,
          txHash: blockchainResult.txHash
        },
        offChainData: {
          volatile: true,
          preferredDestinations,
          quantity: quantityNum,
          certificateCount: certCount,
          stageCount
        }
      }
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
 * Place a bid on an auction (off-chain, real-time)
 */
router.post('/:id/bid', async (req, res) => {
  try {
    const { id } = req.params;
    const { bidderAddress, bidderName, amount, currency = 'ETH' } = req.body;

    logger.info('Bid request received', {
      auctionId: id,
      body: req.body
    });

    // Validation
    if (!bidderAddress || !amount) {
      logger.warn('Missing required fields', { bidderAddress, amount });
      return res.status(400).json({
        success: false,
        error: 'Bidder address and amount are required',
        received: { bidderAddress: !!bidderAddress, amount: !!amount }
      });
    }

    const bidAmount = parseFloat(amount);
    if (isNaN(bidAmount) || bidAmount <= 0) {
      logger.warn('Invalid bid amount', { amount, parsed: bidAmount });
      return res.status(400).json({
        success: false,
        error: 'Invalid bid amount',
        received: amount
      });
    }

    // Load exchange rates
    await currencyConverter.loadRates();

    // Get auction details
    const auctionResult = await db.query(
      'SELECT * FROM auctions WHERE auction_id = $1',
      [parseInt(id)]
    );

    if (auctionResult.rows.length === 0) {
      logger.warn('Auction not found', { auctionId: id });
      return res.status(404).json({
        success: false,
        error: 'Auction not found',
        auctionId: id
      });
    }

    const auction = auctionResult.rows[0];
    
    // Convert bid to both currencies
    let bidInEth, bidInLkr;
    if (currency === 'LKR') {
      bidInLkr = bidAmount;
      bidInEth = currencyConverter.lkrToEth(bidAmount);
    } else {
      bidInEth = bidAmount;
      bidInLkr = currencyConverter.ethToLkr(bidAmount);
    }
    
    logger.info('Auction found with currency conversion', {
      auctionId: id,
      status: auction.status,
      auctionCurrency: auction.currency || 'ETH',
      bidCurrency: currency,
      bidInEth,
      bidInLkr,
      currentBid: auction.current_bid,
      endTime: auction.end_time
    });

    // Check auction status
    if (auction.status !== 'active') {
      logger.warn('Auction not active', { status: auction.status });
      return res.status(400).json({
        success: false,
        error: 'Auction is not active',
        auctionStatus: auction.status
      });
    }

    // Check auction not ended
    const now = new Date();
    const endTime = new Date(auction.end_time);
    if (now >= endTime) {
      logger.warn('Auction has ended', { now, endTime });
      return res.status(400).json({
        success: false,
        error: 'Auction has ended',
        endTime: endTime.toISOString()
      });
    }

    // Check bidder is not the farmer
    if (bidderAddress.toLowerCase() === auction.farmer_address.toLowerCase()) {
      logger.warn('Farmer cannot bid on own auction', { bidderAddress, farmerAddress: auction.farmer_address });
      return res.status(400).json({
        success: false,
        error: 'Farmer cannot bid on own auction'
      });
    }

    // Calculate minimum bid (5% above current bid) - always compare in ETH
    const currentBidEth = parseFloat(auction.current_bid) || parseFloat(auction.start_price) || 0;
    const minIncrementPercent = 0.05; // 5%
    const minBidEth = currentBidEth > 0 ? currentBidEth * (1 + minIncrementPercent) : parseFloat(auction.start_price) || 0;

    logger.info('Bid validation', {
      bidInEth,
      currentBidEth,
      minBidEth,
      isValid: bidInEth >= minBidEth
    });

    if (bidInEth < minBidEth) {
      // Return error in both currencies for clarity
      const minBidLkr = currencyConverter.ethToLkr(minBidEth);
      const currentBidLkr = currencyConverter.ethToLkr(currentBidEth);
      
      logger.warn('Bid amount too low', { bidInEth, minBidEth, currentBidEth });
      return res.status(400).json({
        success: false,
        error: 'Bid amount too low',
        minimumBid: {
          eth: minBidEth.toFixed(4),
          lkr: minBidLkr.toFixed(2)
        },
        currentBid: {
          eth: currentBidEth.toFixed(4),
          lkr: currentBidLkr.toFixed(2)
        },
        yourBid: {
          eth: bidInEth.toFixed(4),
          lkr: bidInLkr.toFixed(2)
        },
        incrementRequired: '5%'
      });
    }

    // Insert bid into database with both currencies
    const bidResult = await db.query(
      `INSERT INTO bids (
        auction_id, bidder_address, bidder_name, amount, currency, amount_lkr, status, placed_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())
      RETURNING *`,
      [parseInt(id), bidderAddress, bidderName || null, bidInEth.toString(), currency, bidInLkr.toString(), 'pending']
    );

    const newBid = bidResult.rows[0];

    // Update auction current bid (in both currencies)
    await db.query(
      `UPDATE auctions 
       SET current_bid = $1, current_bid_lkr = $2, current_bidder = $3, bid_count = COALESCE(bid_count, 0) + 1
       WHERE auction_id = $4`,
      [bidInEth.toString(), bidInLkr.toString(), bidderAddress, parseInt(id)]
    );

    logger.info('Bid placed successfully', {
      auctionId: id,
      bidder: bidderAddress,
      eth: bidInEth,
      lkr: bidInLkr
    });

    // Broadcast bid via WebSocket (include both currencies)
    const io = req.app.get('io');
    if (io) {
      // Emit to /auction namespace and use underscore in room name
      const auctionNamespace = io.of('/auction');
      auctionNamespace.to(`auction_${id}`).emit('new_bid', {
        auctionId: parseInt(id),
        bidder: bidderAddress,
        bidderName: bidderName || 'Anonymous',
        amount: bidInEth.toString(),
        amountLkr: bidInLkr.toString(),
        currency: currency,
        timestamp: new Date().toISOString(),
        bidCount: auction.bid_count + 1
      });
      logger.info('WebSocket broadcast sent', {
        room: `auction_${id}`,
        event: 'new_bid',
        amount: bidInEth.toString()
      });
    }

    res.status(201).json({
      success: true,
      message: 'Bid placed successfully',
      bid: {
        id: newBid.id,
        auctionId: parseInt(id),
        bidderAddress,
        amount: {
          eth: bidInEth.toFixed(4),
          lkr: bidInLkr.toFixed(2)
        },
        currency: currency,
        placedAt: newBid.placed_at
      }
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
 * POST /api/auctions/request-cancellation
 * Request emergency cancellation of an auction
 */
router.post('/request-cancellation', async (req, res) => {
  try {
    const { auctionId, reason, farmerAddress } = req.body;

    if (!auctionId || !reason || !farmerAddress) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: auctionId, reason, farmerAddress'
      });
    }

    // Verify auction exists and belongs to farmer
    const auctionResult = await db.query(
      'SELECT * FROM auctions WHERE auction_id = $1',
      [auctionId]
    );

    if (auctionResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Auction not found'
      });
    }

    const auction = auctionResult.rows[0];

    if (auction.farmer_address.toLowerCase() !== farmerAddress.toLowerCase()) {
      return res.status(403).json({
        success: false,
        error: 'You are not authorized to cancel this auction'
      });
    }

    // Check if auction can be cancelled (must be active or created)
    if (!['created', 'active', 'pending_approval'].includes(auction.status)) {
      return res.status(400).json({
        success: false,
        error: `Cannot request cancellation for auction with status "${auction.status}"`
      });
    }

    // Check if cancellation request already exists
    const existingRequest = await db.query(
      `SELECT * FROM cancellation_requests 
       WHERE auction_id = $1 AND status = 'pending'`,
      [auctionId]
    );

    if (existingRequest.rows.length > 0) {
      return res.status(400).json({
        success: false,
        error: 'A cancellation request for this auction is already pending'
      });
    }

    // Create cancellation request
    const requestResult = await db.query(
      `INSERT INTO cancellation_requests 
       (auction_id, lot_id, requested_by, reason, status)
       VALUES ($1, $2, $3, $4, 'pending')
       RETURNING *`,
      [auctionId, auction.lot_id, farmerAddress, reason]
    );

    logger.info('Cancellation request created', {
      requestId: requestResult.rows[0].id,
      auctionId,
      reason
    });

    res.json({
      success: true,
      message: 'Cancellation request submitted successfully. Admin will review.',
      request: {
        id: requestResult.rows[0].id,
        auctionId: requestResult.rows[0].auction_id,
        lotId: requestResult.rows[0].lot_id,
        reason: requestResult.rows[0].reason,
        status: requestResult.rows[0].status,
        createdAt: requestResult.rows[0].created_at
      }
    });
  } catch (error) {
    logger.error('Error creating cancellation request:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to submit cancellation request'
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
 * GET /api/auctions/bids/user/:userId
 * Get all bids placed by a specific user across all auctions
 */
router.get('/bids/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const { limit = 100, offset = 0 } = req.query;

    logger.info(`Fetching bids for user ID: ${userId}`);

    // First, get the user's wallet address
    const userResult = await db.query(
      'SELECT wallet_address, name FROM users WHERE id = $1',
      [userId]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    const { wallet_address, name } = userResult.rows[0];

    if (!wallet_address) {
      logger.warn(`User ${userId} has no wallet address`);
      return res.json({
        success: true,
        count: 0,
        auctions: []
      });
    }

    logger.info(`Found wallet address for user ${userId}: ${wallet_address}`);

    // Fetch all bids by this user with auction details
    const bidsResult = await db.query(
      `SELECT 
        b.*,
        a.auction_id,
        a.lot_id,
        a.status as auction_status,
        a.current_bid as auction_current_bid,
        a.start_time,
        a.end_time,
        a.farmer_address,
        a.reserve_price,
        a.bid_count,
        p.variety,
        p.quantity,
        p.quality
       FROM bids b
       JOIN auctions a ON b.auction_id = a.auction_id
       LEFT JOIN pepper_lots p ON a.lot_id = p.lot_id
       WHERE LOWER(b.bidder_address) = LOWER($1)
       ORDER BY b.placed_at DESC
       LIMIT $2 OFFSET $3`,
      [wallet_address, limit, offset]
    );

    const countResult = await db.query(
      `SELECT COUNT(*) FROM bids WHERE LOWER(bidder_address) = LOWER($1)`,
      [wallet_address]
    );

    // Group bids by auction
    const auctionMap = new Map();

    for (const bid of bidsResult.rows) {
      const auctionId = bid.auction_id;

      if (!auctionMap.has(auctionId)) {
        // Determine if user is leading this auction by comparing their bid with current_bid
        // For active auctions, user is leading if their bid equals current_bid
        // For ended auctions, we'll check after collecting all bids
        const isLeading = bid.auction_current_bid === bid.amount;

        auctionMap.set(auctionId, {
          auctionId,
          lotId: bid.lot_id,
          status: bid.auction_status,
          currentBid: bid.auction_current_bid,
          startTime: bid.start_time,
          endTime: bid.end_time,
          farmerAddress: bid.farmer_address,
          reservePrice: bid.reserve_price,
          bidCount: bid.bid_count,
          variety: bid.variety,
          quantity: bid.quantity,
          quality: bid.quality,
          isLeading,
          myHighestBid: bid.amount,
          myHighestBidLkr: bid.amount_lkr,
          myBids: []
        });
      }

      // Update highest bid if this bid is higher
      const auction = auctionMap.get(auctionId);
      if (parseFloat(bid.amount) > parseFloat(auction.myHighestBid)) {
        auction.myHighestBid = bid.amount;
        auction.myHighestBidLkr = bid.amount_lkr;
      }

      auction.myBids.push({
        id: bid.id,
        amount: bid.amount,
        amountLkr: bid.amount_lkr,
        currency: bid.currency || 'ETH',
        placedAt: bid.placed_at,
        status: bid.status
      });
    }

    logger.info(`Found ${auctionMap.size} auctions with bids for user ${userId}`);

    res.json({
      success: true,
      count: parseInt(countResult.rows[0].count),
      auctions: Array.from(auctionMap.values())
    });
  } catch (error) {
    logger.error('Error fetching user bids:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch user bids',
      details: error.message
    });
  }
});

/**
 * GET /api/auctions/:id/bids
 * Get all bids for an auction
 */
router.get('/:id/bids', async (req, res) => {
  try {
    const { id } = req.params;
    const { limit = 50, offset = 0 } = req.query;

    const result = await db.query(
      `SELECT * FROM bids 
       WHERE auction_id = $1 
       ORDER BY amount DESC, placed_at DESC 
       LIMIT $2 OFFSET $3`,
      [parseInt(id), limit, offset]
    );

    const countResult = await db.query(
      'SELECT COUNT(*) FROM bids WHERE auction_id = $1',
      [parseInt(id)]
    );

    res.json({
      success: true,
      count: parseInt(countResult.rows[0].count),
      bids: result.rows
    });
  } catch (error) {
    logger.error('Error fetching bids:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch bids'
    });
  }
});

/**
 * POST /api/auctions/:id/escrow/lock
 * Lock escrow after auction ends (winning bidder only)
 */
router.post('/:id/escrow/lock', async (req, res) => {
  try {
    const { id } = req.params;
    const { exporterAddress, transactionHash } = req.body;

    if (!exporterAddress || !transactionHash) {
      return res.status(400).json({
        success: false,
        error: 'Exporter address and transaction hash required'
      });
    }

    // Get auction
    const auctionResult = await db.query(
      'SELECT * FROM auctions WHERE auction_id = $1',
      [parseInt(id)]
    );

    if (auctionResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Auction not found'
      });
    }

    const auction = auctionResult.rows[0];

    // Verify auction ended
    if (auction.status !== 'ended') {
      return res.status(400).json({
        success: false,
        error: 'Auction must be ended before locking escrow'
      });
    }

    // Verify this is the winning bidder
    if (exporterAddress.toLowerCase() !== auction.highest_bidder?.toLowerCase()) {
      return res.status(403).json({
        success: false,
        error: 'Only winning bidder can lock escrow'
      });
    }

    // Check if escrow already locked
    const escrowResult = await db.query(
      'SELECT * FROM escrow_deposits WHERE auction_id = $1',
      [parseInt(id)]
    );

    if (escrowResult.rows.length > 0) {
      return res.status(400).json({
        success: false,
        error: 'Escrow already locked for this auction'
      });
    }

    // Create escrow record
    await db.query(
      `INSERT INTO escrow_deposits 
       (auction_id, depositor_address, amount, transaction_hash, status, deposited_at) 
       VALUES ($1, $2, $3, $4, $5, NOW())`,
      [parseInt(id), exporterAddress, auction.current_price, transactionHash, 'locked']
    );

    // Update auction status
    await db.query(
      `UPDATE auctions 
       SET status = $1, escrow_locked = true, escrow_tx_hash = $2 
       WHERE auction_id = $3`,
      ['escrow_locked', transactionHash, parseInt(id)]
    );

    logger.info('Escrow locked', {
      auctionId: id,
      depositor: exporterAddress,
      amount: auction.current_price,
      txHash: transactionHash
    });

    res.json({
      success: true,
      message: 'Escrow locked successfully'
    });
  } catch (error) {
    logger.error('Error locking escrow:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to lock escrow'
    });
  }
});

/**
 * POST /api/auctions/:id/settle
 * Settle an auction (comprehensive workflow)
 */
router.post('/:id/settle', async (req, res) => {
  try {
    const { id } = req.params;
    const {
      complianceApproved,
      shipmentConfirmed,
      deliveryConfirmed,
      settlementTxHash
    } = req.body;

    // Get auction details
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

    // Verify auction is in correct state
    if (auction.status !== 'ended' && auction.status !== 'escrow_locked') {
      return res.status(400).json({
        success: false,
        error: 'Auction must be ended with escrow locked before settling',
        currentStatus: auction.status
      });
    }

    // Verify escrow is locked
    const escrowResult = await db.query(
      'SELECT * FROM escrow_deposits WHERE auction_id = $1 AND status = $2',
      [parseInt(id), 'locked']
    );

    if (escrowResult.rows.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Escrow must be locked before settlement'
      });
    }

    const escrow = escrowResult.rows[0];

    // Verify all preconditions
    if (!complianceApproved) {
      return res.status(400).json({
        success: false,
        error: 'Compliance approval required for settlement'
      });
    }

    if (!shipmentConfirmed) {
      return res.status(400).json({
        success: false,
        error: 'Shipment confirmation required for settlement'
      });
    }

    if (!deliveryConfirmed) {
      return res.status(400).json({
        success: false,
        error: 'Delivery confirmation required for settlement'
      });
    }

    // Calculate amounts
    const finalAmount = parseFloat(escrow.amount);
    const platformFeePercent = 2.0; // 2%
    const platformFee = finalAmount * (platformFeePercent / 100);
    const farmerPayout = finalAmount - platformFee;

    // Create settlement record
    await db.query(
      `INSERT INTO auction_settlements 
       (auction_id, farmer_address, buyer_address, final_amount, platform_fee, 
        farmer_payout, settlement_tx_hash, compliance_approved, shipment_confirmed, 
        delivery_confirmed, status) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
      [
        parseInt(id),
        auction.farmer_address,
        escrow.depositor_address,
        finalAmount,
        platformFee,
        farmerPayout,
        settlementTxHash,
        complianceApproved,
        shipmentConfirmed,
        deliveryConfirmed,
        'completed'
      ]
    );

    // Update escrow status
    await db.query(
      `UPDATE escrow_deposits 
       SET status = $1, released_at = NOW(), released_to = $2, release_tx_hash = $3 
       WHERE auction_id = $4`,
      ['released', auction.farmer_address, settlementTxHash, parseInt(id)]
    );

    // Update auction status
    await db.query(
      'UPDATE auctions SET status = $1, settlement_tx_hash = $2 WHERE auction_id = $3',
      ['settled', settlementTxHash, parseInt(id)]
    );

    // Update winning bid status
    await db.query(
      `UPDATE bids 
       SET status = $1, transaction_hash = $2 
       WHERE auction_id = $3 AND bidder_address = $4 
       ORDER BY amount DESC LIMIT 1`,
      ['won', settlementTxHash, parseInt(id), auction.highest_bidder]
    );

    // Update lot status
    await db.query(
      'UPDATE pepper_lots SET status = $1 WHERE lot_id = $2',
      ['sold', auction.lot_id]
    );

    logger.info('Auction settled successfully', {
      auctionId: id,
      farmer: auction.farmer_address,
      buyer: escrow.depositor_address,
      amount: finalAmount,
      platformFee,
      farmerPayout
    });

    // Broadcast settlement via WebSocket
    const io = req.app.get('io');
    if (io) {
      io.to(`auction-${id}`).emit('auction-settled', {
        auctionId: parseInt(id),
        status: 'settled',
        finalAmount,
        winner: escrow.depositor_address
      });
    }

    res.json({
      success: true,
      message: 'Auction settled successfully',
      settlement: {
        finalAmount: finalAmount.toFixed(4),
        platformFee: platformFee.toFixed(4),
        farmerPayout: farmerPayout.toFixed(4),
        transactionHash: settlementTxHash
      }
    });
  } catch (error) {
    logger.error('Error settling auction:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to settle auction'
    });
  }
});

/**
 * POST /api/auctions/:id/cancel
 * Cancel an auction (failure scenarios)
 */
router.post('/:id/cancel', async (req, res) => {
  try {
    const { id } = req.params;
    const { reason, detailedReason, cancelledBy, refundExporter } = req.body;

    if (!reason || !cancelledBy) {
      return res.status(400).json({
        success: false,
        error: 'Cancellation reason and cancelled_by required'
      });
    }

    const validReasons = [
      'no_valid_bids',
      'escrow_not_deposited',
      'compliance_failure',
      'shipment_failure',
      'admin_emergency',
      'fraud_detected',
      'quality_dispute',
      'delivery_failure',
      'other'
    ];

    if (!validReasons.includes(reason)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid cancellation reason',
        validReasons
      });
    }

    // Get auction
    const auctionResult = await db.query(
      'SELECT * FROM auctions WHERE auction_id = $1',
      [parseInt(id)]
    );

    if (auctionResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Auction not found'
      });
    }

    const auction = auctionResult.rows[0];

    // Check if escrow exists
    const escrowResult = await db.query(
      'SELECT * FROM escrow_deposits WHERE auction_id = $1',
      [parseInt(id)]
    );

    let refundTxHash = null;
    let escrowRefunded = false;

    // Handle escrow refund if needed
    if (escrowResult.rows.length > 0 && refundExporter) {
      const escrow = escrowResult.rows[0];
      
      // Update escrow status
      await db.query(
        `UPDATE escrow_deposits 
         SET status = $1, released_at = NOW(), released_to = $2 
         WHERE auction_id = $3`,
        ['refunded', escrow.depositor_address, parseInt(id)]
      );

      escrowRefunded = true;
      refundTxHash = req.body.refundTxHash || null;
    }

    // Create cancellation record
    await db.query(
      `INSERT INTO auction_cancellations 
       (auction_id, cancelled_by, cancellation_reason, detailed_reason, 
        escrow_refunded, refund_tx_hash, resolved) 
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [
        parseInt(id),
        cancelledBy,
        reason,
        detailedReason,
        escrowRefunded,
        refundTxHash,
        false
      ]
    );

    // Update auction status
    await db.query(
      'UPDATE auctions SET status = $1 WHERE auction_id = $2',
      ['cancelled', parseInt(id)]
    );

    // Return lot to available if no escrow
    if (!escrowRefunded) {
      await db.query(
        'UPDATE pepper_lots SET status = $1 WHERE lot_id = $2',
        ['available', auction.lot_id]
      );
    }

    logger.info('Auction cancelled', {
      auctionId: id,
      reason,
      cancelledBy,
      escrowRefunded
    });

    // Broadcast cancellation via WebSocket
    const io = req.app.get('io');
    if (io) {
      io.to(`auction-${id}`).emit('auction-cancelled', {
        auctionId: parseInt(id),
        reason,
        escrowRefunded
      });
    }

    res.json({
      success: true,
      message: 'Auction cancelled successfully',
      cancellation: {
        reason,
        escrowRefunded,
        refundTxHash
      }
    });
  } catch (error) {
    logger.error('Error cancelling auction:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to cancel auction'
    });
  }
});

module.exports = router;
