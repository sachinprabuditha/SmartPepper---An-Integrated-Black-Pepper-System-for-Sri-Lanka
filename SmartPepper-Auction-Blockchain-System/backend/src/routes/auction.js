const express = require('express');
const router = express.Router();
const admin = require('firebase-admin');
const BlockchainService = require('../services/blockchainService');
const ComplianceService = require('../services/complianceService');
const currencyConverter = require('../utils/currencyConverter');
const logger = require('../utils/logger');
const { v4: uuidv4 } = require('uuid');

const firestore = admin.firestore();
const blockchainService = new BlockchainService();
const complianceService = new ComplianceService();

// Initialize services
blockchainService.initialize().catch(err => logger.error('Blockchain init failed:', err));
complianceService.initialize().catch(err => logger.error('Compliance init failed:', err));

/**
 * Helper function to convert Firestore Timestamps to ISO strings
 */
const convertTimestamps = (obj) => {
  if (!obj || typeof obj !== 'object') return obj;
  
  const converted = Array.isArray(obj) ? [] : {};
  
  for (const key in obj) {
    const value = obj[key];
    
    // Check if it's a Firestore Timestamp
    if (value && typeof value === 'object' && '_seconds' in value && '_nanoseconds' in value) {
      // Convert to ISO string
      const date = new Date(value._seconds * 1000 + value._nanoseconds / 1000000);
      converted[key] = date.toISOString();
    } else if (value && typeof value.toDate === 'function') {
      // Firestore Timestamp object with toDate method
      converted[key] = value.toDate().toISOString();
    } else if (Array.isArray(value)) {
      // Recursively convert arrays
      converted[key] = value.map(item => convertTimestamps(item));
    } else if (value && typeof value === 'object') {
      // Recursively convert nested objects
      converted[key] = convertTimestamps(value);
    } else {
      converted[key] = value;
    }
  }
  
  return converted;
};

/**
 * GET /api/auctions
 * Get all auctions with optional filters
 */
router.get('/', async (req, res) => {
  try {
    const { status, farmer, limit = 50, offset = 0 } = req.query;
    
    let auctionsQuery = firestore.collection('auctions');
    
    if (status) {
      auctionsQuery = auctionsQuery.where('status', '==', status);
    }
    
    if (farmer) {
      // Check if farmer is a wallet address (starts with 0x) or a user ID
      if (farmer.startsWith('0x')) {
        auctionsQuery = auctionsQuery.where('farmer_address_lower', '==', farmer.toLowerCase());
      } else {
        // Filter by farmer_id field
        auctionsQuery = auctionsQuery.where('farmer_id', '==', farmer);
      }
    }
    
    // Only add orderBy if we have filtering, otherwise it requires composite index
    if (status || farmer) {
      auctionsQuery = auctionsQuery.limit(parseInt(limit));
      if (parseInt(offset) > 0) {
        auctionsQuery = auctionsQuery.offset(parseInt(offset));
      }
    } else {
      auctionsQuery = auctionsQuery.orderBy('created_at', 'desc')
                                   .limit(parseInt(limit))
                                   .offset(parseInt(offset));
    }
    
    const auctionsSnapshot = await auctionsQuery.get();
    
    // Count total matching documents
    let countQuery = firestore.collection('auctions');
    if (status) {
      countQuery = countQuery.where('status', '==', status);
    }
    if (farmer) {
      if (farmer.startsWith('0x')) {
        countQuery = countQuery.where('farmer_address_lower', '==', farmer.toLowerCase());
      } else {
        countQuery = countQuery.where('farmer_id', '==', farmer);
      }
    }
    const countSnapshot = await countQuery.count().get();
    
    const auctions = [];
    
    // Fetch lot details for each auction
    for (const doc of auctionsSnapshot.docs) {
      const auctionData = { auction_id: doc.id, ...doc.data() };
      
      // Fetch associated lot by lot_id field
      if (auctionData.lot_id) {
        const lotSnapshot = await firestore.collection('pepper_lots')
          .where('lot_id', '==', auctionData.lot_id)
          .limit(1)
          .get();
        if (!lotSnapshot.empty) {
          const lotData = lotSnapshot.docs[0].data();
          auctionData.variety = lotData.variety;
          auctionData.quantity = lotData.quantity;
          auctionData.quality = lotData.quality;
          auctionData.origin = lotData.origin;
        }
      }
      
      auctions.push(convertTimestamps(auctionData));
    }

    res.json({
      success: true,
      count: countSnapshot.data().count,
      auctions
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
    
    const auctionDoc = await firestore.collection('auctions').doc(id).get();

    if (!auctionDoc.exists) {
      return res.status(404).json({
        success: false,
        error: 'Auction not found'
      });
    }

    const auctionData = { auction_id: auctionDoc.id, ...auctionDoc.data() };

    // Get bids
    const bidsSnapshot = await firestore.collection('bids')
      .where('auction_id', '==', id)
      .orderBy('placed_at', 'desc')
      .get();

    const bids = bidsSnapshot.docs.map(doc => convertTimestamps({ id: doc.id, ...doc.data() }));

    res.json({
      success: true,
      auction: convertTimestamps(auctionData),
      bids
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

    // 1. Check if lot exists - Query by lot_id field, not document ID
    const lotSnapshot = await firestore.collection('pepper_lots')
      .where('lot_id', '==', lotId)
      .limit(1)
      .get();

    if (lotSnapshot.empty) {
      eligible = false;
      reasons.push('Pepper lot does not exist in the system');
      return res.json({ eligible, reasons });
    }

    const lot = lotSnapshot.docs[0].data();

    // 2. Check if lot is approved/available
    if (lot.status !== 'approved' && lot.status !== 'available') {
      eligible = false;
      reasons.push(`Lot status is "${lot.status}". Only approved or available lots can be auctioned.`);
    }

    // 3. Check if lot already has an active auction
    const activeAuctionSnapshot = await firestore.collection('auctions')
      .where('lot_id', '==', lotId)
      .where('status', 'in', ['created', 'active', 'pending'])
      .limit(1)
      .get();

    if (!activeAuctionSnapshot.empty) {
      eligible = false;
      reasons.push('This lot already has an active auction');
    }

    // 4. Check if required certificates are uploaded
    const certsSnapshot = await firestore.collection('certifications')
      .where('lot_id', '==', lotId)
      .get();

    const certCount = certsSnapshot.size;
    if (certCount < 3) {
      eligible = false;
      reasons.push(`Insufficient certificates uploaded. Found ${certCount}, minimum 3 required.`);
    }

    // 5. Check compliance status
    const complianceSnapshot = await firestore.collection('compliance_checks')
      .where('lot_id', '==', lotId)
      .orderBy('checked_at', 'desc')
      .limit(1)
      .get();

    if (complianceSnapshot.empty) {
      eligible = false;
      reasons.push('No compliance checks have been performed for this lot');
    } else {
      const compliance = complianceSnapshot.docs[0].data();
      
      if (!compliance.passed) {
        eligible = false;
        reasons.push(`Compliance check "${compliance.rule_name}" failed. Rule type: ${compliance.rule_type}`);
      }
    }

    // 6. Check if lot has processing stages (traceability)
    const stagesSnapshot = await firestore.collection('processing_stages')
      .where('lot_id', '==', lotId)
      .get();

    const stageCount = stagesSnapshot.size;
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
        lotId: lotId,
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
      currency = 'ETH',
      reservePriceEth,
      quantity,
      duration,
      startTime,
      endTime,
      preferredDestinations = [],
      templateId
    } = req.body;

    // === STEP 1: Validate Required Inputs ===
    if (!lotId || !farmerAddress || !reservePrice || !quantity || !duration) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields',
        required: ['lotId', 'farmerAddress', 'reservePrice', 'quantity', 'duration']
      });
    }

    // === GOVERNANCE VALIDATION - Get exchange rates from settings ===
    // Fetch governance settings early to get exchange rates
    const settingsSnapshot = await firestore.collection('governance_settings').limit(1).get();
    
    if (settingsSnapshot.empty) {
      return res.status(500).json({
        success: false,
        error: 'Governance settings not configured'
      });
    }

    const settings = settingsSnapshot.docs[0].data();
    const lkrToEthRate = parseFloat(settings.lkr_to_eth_rate || 0.0000031);
    const usdToEthRate = parseFloat(settings.usd_to_eth_rate || 0.00032);

    // Validate numeric inputs
    const reservePriceNum = parseFloat(reservePrice);
    
    // Handle currency conversion using governance settings rates
    let reservePriceInEth;
    let reservePriceInLkr;
    
    if (currency === 'LKR') {
      reservePriceInLkr = reservePriceNum;
      reservePriceInEth = reservePriceEth 
        ? parseFloat(reservePriceEth) 
        : reservePriceNum * lkrToEthRate;
      
      logger.info('LKR auction', { 
        lkr: reservePriceInLkr, 
        eth: reservePriceInEth,
        preConverted: !!reservePriceEth,
        rate: lkrToEthRate
      });
    } else if (currency === 'USD') {
      const reservePriceInUsd = reservePriceNum;
      reservePriceInEth = reservePriceNum * usdToEthRate;
      reservePriceInLkr = reservePriceNum * 320; // Approx USD to LKR
      
      logger.info('USD auction', { 
        usd: reservePriceInUsd, 
        eth: reservePriceInEth,
        lkr: reservePriceInLkr,
        rate: usdToEthRate
      });
    } else {
      reservePriceInEth = reservePriceNum;
      reservePriceInLkr = reservePriceNum / lkrToEthRate;
      
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

    // Convert duration to hours for validation (settings already fetched above)
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
      const templateDoc = await firestore.collection('auction_rule_templates')
        .doc(templateId)
        .get();

      if (!templateDoc.exists || !templateDoc.data().active) {
        return res.status(400).json({
          success: false,
          error: 'Invalid or inactive template'
        });
      }

      template = templateDoc.data();

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
    // Query lot by lot_id field, not document ID
    const lotSnapshot = await firestore.collection('pepper_lots')
      .where('lot_id', '==', lotId)
      .limit(1)
      .get();

    if (lotSnapshot.empty) {
      return res.status(404).json({
        success: false,
        error: 'Lot not found'
      });
    }

    const lot = lotSnapshot.docs[0].data();
    const lotDocRef = lotSnapshot.docs[0].ref;

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
    const activeAuctionSnapshot = await firestore.collection('auctions')
      .where('lot_id', '==', lotId)
      .where('status', 'in', ['created', 'active', 'pending', 'scheduled'])
      .limit(1)
      .get();

    if (!activeAuctionSnapshot.empty) {
      eligible = false;
      eligibilityReasons.push('This lot already has an active or scheduled auction');
    }

    // Check certificates (minimum 3)
    const certsSnapshot = await firestore.collection('certifications')
      .where('lot_id', '==', lotId)
      .get();
    const certCount = certsSnapshot.size;
    if (certCount < 3) {
      eligible = false;
      eligibilityReasons.push(`Minimum 3 certificates required (found ${certCount})`);
    }

    // Check compliance status
    const complianceSnapshot = await firestore.collection('compliance_checks')
      .where('lot_id', '==', lotId)
      .orderBy('checked_at', 'desc')
      .limit(1)
      .get();

    if (complianceSnapshot.empty) {
      eligible = false;
      eligibilityReasons.push('No compliance checks performed');
    } else {
      const compliance = complianceSnapshot.docs[0].data();
      if (!compliance.passed) {
        eligible = false;
        eligibilityReasons.push(`Compliance check "${compliance.rule_name}" failed (rule type: ${compliance.rule_type})`);
      }
    }

    // Check processing stages (minimum 2)
    const stagesSnapshot = await firestore.collection('processing_stages')
      .where('lot_id', '==', lotId)
      .get();
    const stageCount = stagesSnapshot.size;
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
    const calculatedStartTime = startTime ? new Date(startTime) : new Date(Date.now() + 3600000);
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
      startPrice: reservePriceNum,
      reservePrice: reservePriceNum,
      duration: durationSeconds
    });

    const blockchainAuctionId = blockchainResult.auctionId ? parseInt(blockchainResult.auctionId) : null;
    const auctionIdNum = Math.floor(Date.now() / 1000);

    logger.info('Blockchain auction created', {
      auctionId: auctionIdNum,
      blockchainAuctionId: blockchainAuctionId,
      txHash: blockchainResult.txHash
    });

    // === STEP 5: Store Off-Chain Data (Volatile + UI preferences) ===
    const initialStatus = requiresApproval 
      ? 'pending_approval' 
      : (calculatedStartTime > new Date() ? 'created' : 'active');

    const auctionData = {
      lot_id: lotId,
      farmer_address: farmerAddress,
      farmer_address_lower: farmerAddress.toLowerCase(),
      start_price: reservePriceInEth,
      reserve_price: reservePriceInEth,
      start_time: admin.firestore.Timestamp.fromDate(calculatedStartTime),
      end_time: admin.firestore.Timestamp.fromDate(calculatedEndTime),
      status: initialStatus,
      compliance_passed: true,
      blockchain_tx_hash: blockchainResult.txHash,
      template_id: templateId || null,
      min_bid_increment: minBidIncrement,
      admin_approved: !requiresApproval,
      currency: currency,
      price_lkr: reservePriceInLkr,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      bid_count: 0
    };

    await firestore.collection('auctions').doc(auctionIdNum.toString()).set(auctionData);

    logger.info('Auction stored in database', {
      auctionId: auctionIdNum,
      status: auctionData.status,
      startTime: calculatedStartTime,
      endTime: calculatedEndTime
    });

    // === STEP 6: Return Success Response ===
    res.status(201).json({
      success: true,
      message: 'Auction created successfully',
      auction: {
        auctionId: auctionIdNum,
        lotId: lotId,
        farmerAddress: farmerAddress,
        reservePrice: reservePriceInEth,
        quantity: quantityNum,
        startTime: calculatedStartTime,
        endTime: calculatedEndTime,
        status: initialStatus,
        blockchainTxHash: blockchainResult.txHash,
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
    const auctionDoc = await firestore.collection('auctions').doc(id).get();

    if (!auctionDoc.exists) {
      logger.warn('Auction not found', { auctionId: id });
      return res.status(404).json({
        success: false,
        error: 'Auction not found',
        auctionId: id
      });
    }

    const auction = auctionDoc.data();
    
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
    const endTime = auction.end_time.toDate();
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
    const minIncrementPercent = 0.05;
    const minBidEth = currentBidEth > 0 ? currentBidEth * (1 + minIncrementPercent) : parseFloat(auction.start_price) || 0;

    logger.info('Bid validation', {
      bidInEth,
      currentBidEth,
      minBidEth,
      isValid: bidInEth >= minBidEth
    });

    if (bidInEth < minBidEth) {
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
    const bidData = {
      auction_id: id,
      bidder_address: bidderAddress,
      bidder_address_lower: bidderAddress.toLowerCase(),
      bidder_name: bidderName || null,
      amount: bidInEth.toString(),
      currency: currency,
      amount_lkr: bidInLkr.toString(),
      status: 'pending',
      placed_at: admin.firestore.FieldValue.serverTimestamp()
    };

    const bidRef = await firestore.collection('bids').add(bidData);

    // Update auction current bid (in both currencies)
    await firestore.collection('auctions').doc(id).update({
      current_bid: bidInEth.toString(),
      current_bid_lkr: bidInLkr.toString(),
      current_bidder: bidderAddress,
      bid_count: admin.firestore.FieldValue.increment(1)
    });

    logger.info('Bid placed successfully', {
      auctionId: id,
      bidder: bidderAddress,
      eth: bidInEth,
      lkr: bidInLkr
    });

    // Broadcast bid via WebSocket (include both currencies)
    const io = req.app.get('io');
    if (io) {
      const auctionNamespace = io.of('/auction');
      auctionNamespace.to(`auction_${id}`).emit('new_bid', {
        auctionId: id,
        bidder: bidderAddress,
        bidderName: bidderName || 'Anonymous',
        amount: bidInEth.toString(),
        amountLkr: bidInLkr.toString(),
        currency: currency,
        timestamp: new Date().toISOString(),
        bidCount: (auction.bid_count || 0) + 1
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
        id: bidRef.id,
        auctionId: id,
        bidderAddress,
        amount: {
          eth: bidInEth.toFixed(4),
          lkr: bidInLkr.toFixed(2)
        },
        currency: currency,
        placedAt: new Date()
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
    const auctionDoc = await firestore.collection('auctions').doc(auctionId).get();

    if (!auctionDoc.exists) {
      return res.status(404).json({
        success: false,
        error: 'Auction not found'
      });
    }

    const auction = auctionDoc.data();

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
    const existingRequestSnapshot = await firestore.collection('cancellation_requests')
      .where('auction_id', '==', auctionId)
      .where('status', '==', 'pending')
      .get();

    if (!existingRequestSnapshot.empty) {
      return res.status(400).json({
        success: false,
        error: 'A cancellation request for this auction is already pending'
      });
    }

    // Create cancellation request
    const requestData = {
      auction_id: auctionId,
      lot_id: auction.lot_id,
      requested_by: farmerAddress,
      reason: reason,
      status: 'pending',
      created_at: admin.firestore.FieldValue.serverTimestamp()
    };

    const requestRef = await firestore.collection('cancellation_requests').add(requestData);

    logger.info('Cancellation request created', {
      requestId: requestRef.id,
      auctionId,
      reason
    });

    res.json({
      success: true,
      message: 'Cancellation request submitted successfully. Admin will review.',
      request: {
        id: requestRef.id,
        auctionId: auctionId,
        lotId: auction.lot_id,
        reason: reason,
        status: 'pending',
        createdAt: new Date()
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

    const auctionDoc = await firestore.collection('auctions').doc(id).get();

    if (!auctionDoc.exists) {
      return res.status(404).json({
        success: false,
        error: 'Auction not found'
      });
    }

    const auction = auctionDoc.data();

    // Update status
    await firestore.collection('auctions').doc(id).update({
      status: 'ended'
    });

    res.json({
      success: true,
      message: 'Auction ended successfully',
      auction: { ...auction, auction_id: id, status: 'ended' }
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
    const userDoc = await firestore.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    const userData = userDoc.data();
    const { wallet_address, name } = userData;

    if (!wallet_address) {
      logger.warn(`User ${userId} has no wallet address`);
      return res.json({
        success: true,
        count: 0,
        auctions: [],
        message: 'No wallet address connected. Please connect your wallet to place bids and view bid history.'
      });
    }

    logger.info(`Found wallet address for user ${userId}: ${wallet_address}`);

    // Fetch all bids by this user with auction details
    const bidsSnapshot = await firestore.collection('bids')
      .where('bidder_address_lower', '==', wallet_address.toLowerCase())
      .orderBy('placed_at', 'desc')
      .limit(parseInt(limit))
      .offset(parseInt(offset))
      .get();

    const countSnapshot = await firestore.collection('bids')
      .where('bidder_address_lower', '==', wallet_address.toLowerCase())
      .count()
      .get();

    // Group bids by auction
    const auctionMap = new Map();

    for (const bidDoc of bidsSnapshot.docs) {
      const bid = bidDoc.data();
      const auctionId = bid.auction_id;

      if (!auctionMap.has(auctionId)) {
        // Fetch auction details
        const auctionDoc = await firestore.collection('auctions').doc(auctionId).get();
        const auction = auctionDoc.exists ? auctionDoc.data() : {};

        // Fetch lot details by lot_id field
        let lotData = {};
        if (auction.lot_id) {
          const lotSnapshot = await firestore.collection('pepper_lots')
            .where('lot_id', '==', auction.lot_id)
            .limit(1)
            .get();
          if (!lotSnapshot.empty) {
            lotData = lotSnapshot.docs[0].data();
          }
        }

        const isLeading = auction.current_bid === bid.amount;

        auctionMap.set(auctionId, {
          auctionId,
          lotId: auction.lot_id,
          status: auction.status,
          currentBid: auction.current_bid,
          startTime: auction.start_time,
          endTime: auction.end_time,
          farmerAddress: auction.farmer_address,
          reservePrice: auction.reserve_price,
          bidCount: auction.bid_count,
          variety: lotData.variety,
          quantity: lotData.quantity,
          quality: lotData.quality,
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
        id: bidDoc.id,
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
      count: countSnapshot.data().count,
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

    const bidsSnapshot = await firestore.collection('bids')
      .where('auction_id', '==', id)
      .orderBy('amount', 'desc')
      .limit(parseInt(limit))
      .offset(parseInt(offset))
      .get();

    const countSnapshot = await firestore.collection('bids')
      .where('auction_id', '==', id)
      .count()
      .get();

    const bids = bidsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    res.json({
      success: true,
      count: countSnapshot.data().count,
      bids
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
    const auctionDoc = await firestore.collection('auctions').doc(id).get();

    if (!auctionDoc.exists) {
      return res.status(404).json({
        success: false,
        error: 'Auction not found'
      });
    }

    const auction = auctionDoc.data();

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
    const escrowSnapshot = await firestore.collection('escrow_deposits')
      .where('auction_id', '==', id)
      .get();

    if (!escrowSnapshot.empty) {
      return res.status(400).json({
        success: false,
        error: 'Escrow already locked for this auction'
      });
    }

    // Create escrow record
    const escrowData = {
      auction_id: id,
      depositor_address: exporterAddress,
      depositor_address_lower: exporterAddress.toLowerCase(),
      amount: auction.current_price,
      transaction_hash: transactionHash,
      status: 'locked',
      deposited_at: admin.firestore.FieldValue.serverTimestamp()
    };

    await firestore.collection('escrow_deposits').add(escrowData);

    // Update auction status
    await firestore.collection('auctions').doc(id).update({
      status: 'escrow_locked',
      escrow_locked: true,
      escrow_tx_hash: transactionHash
    });

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
    const auctionDoc = await firestore.collection('auctions').doc(id).get();

    if (!auctionDoc.exists) {
      return res.status(404).json({
        success: false,
        error: 'Auction not found'
      });
    }

    const auction = auctionDoc.data();

    // Verify auction is in correct state
    if (auction.status !== 'ended' && auction.status !== 'escrow_locked') {
      return res.status(400).json({
        success: false,
        error: 'Auction must be ended with escrow locked before settling',
        currentStatus: auction.status
      });
    }

    // Verify escrow is locked
    const escrowSnapshot = await firestore.collection('escrow_deposits')
      .where('auction_id', '==', id)
      .where('status', '==', 'locked')
      .get();

    if (escrowSnapshot.empty) {
      return res.status(400).json({
        success: false,
        error: 'Escrow must be locked before settlement'
      });
    }

    const escrow = escrowSnapshot.docs[0].data();

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
    const platformFeePercent = 2.0;
    const platformFee = finalAmount * (platformFeePercent / 100);
    const farmerPayout = finalAmount - platformFee;

    // Create settlement record
    const settlementData = {
      auction_id: id,
      farmer_address: auction.farmer_address,
      farmer_address_lower: auction.farmer_address.toLowerCase(),
      buyer_address: escrow.depositor_address,
      buyer_address_lower: escrow.depositor_address.toLowerCase(),
      final_amount: finalAmount,
      platform_fee: platformFee,
      farmer_payout: farmerPayout,
      settlement_tx_hash: settlementTxHash,
      compliance_approved: complianceApproved,
      shipment_confirmed: shipmentConfirmed,
      delivery_confirmed: deliveryConfirmed,
      status: 'completed',
      created_at: admin.firestore.FieldValue.serverTimestamp()
    };

    await firestore.collection('auction_settlements').add(settlementData);

    // Update escrow status
    await firestore.collection('escrow_deposits').doc(escrowSnapshot.docs[0].id).update({
      status: 'released',
      released_at: admin.firestore.FieldValue.serverTimestamp(),
      released_to: auction.farmer_address,
      release_tx_hash: settlementTxHash
    });

    // Update auction status
    await firestore.collection('auctions').doc(id).update({
      status: 'settled',
      settlement_tx_hash: settlementTxHash
    });

    // Update winning bid status
    const winningBidSnapshot = await firestore.collection('bids')
      .where('auction_id', '==', id)
      .where('bidder_address_lower', '==', auction.highest_bidder?.toLowerCase())
      .orderBy('amount', 'desc')
      .limit(1)
      .get();

    if (!winningBidSnapshot.empty) {
      await firestore.collection('bids').doc(winningBidSnapshot.docs[0].id).update({
        status: 'won',
        transaction_hash: settlementTxHash
      });
    }

    // Update lot status
    await firestore.collection('pepper_lots').doc(auction.lot_id).update({
      status: 'sold'
    });

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
        auctionId: id,
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
    const auctionDoc = await firestore.collection('auctions').doc(id).get();

    if (!auctionDoc.exists) {
      return res.status(404).json({
        success: false,
        error: 'Auction not found'
      });
    }

    const auction = auctionDoc.data();

    // Check if escrow exists
    const escrowSnapshot = await firestore.collection('escrow_deposits')
      .where('auction_id', '==', id)
      .get();

    let refundTxHash = null;
    let escrowRefunded = false;

    // Handle escrow refund if needed
    if (!escrowSnapshot.empty && refundExporter) {
      const escrow = escrowSnapshot.docs[0].data();
      
      // Update escrow status
      await firestore.collection('escrow_deposits').doc(escrowSnapshot.docs[0].id).update({
        status: 'refunded',
        released_at: admin.firestore.FieldValue.serverTimestamp(),
        released_to: escrow.depositor_address
      });

      escrowRefunded = true;
      refundTxHash = req.body.refundTxHash || null;
    }

    // Create cancellation record
    const cancellationData = {
      auction_id: id,
      cancelled_by: cancelledBy,
      cancelled_by_lower: cancelledBy.toLowerCase(),
      cancellation_reason: reason,
      detailed_reason: detailedReason,
      escrow_refunded: escrowRefunded,
      refund_tx_hash: refundTxHash,
      resolved: false,
      created_at: admin.firestore.FieldValue.serverTimestamp()
    };

    await firestore.collection('auction_cancellations').add(cancellationData);

    // Update auction status
    await firestore.collection('auctions').doc(id).update({
      status: 'cancelled'
    });

    // Return lot to available if no escrow
    if (!escrowRefunded) {
      await firestore.collection('pepper_lots').doc(auction.lot_id).update({
        status: 'available'
      });
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
        auctionId: id,
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

/**
 * POST /api/auctions/:id/finalize
 * Manually trigger auction finalization (admin only)
 */
router.post('/:id/finalize', async (req, res) => {
  try {
    const { id } = req.params;
    const auctionFinalizationService = require('../services/auctionFinalizationService');

    logger.info('Manual finalization requested for auction:', id);

    const result = await auctionFinalizationService.finalizeEndedAuctions([id]);

    res.json({
      success: true,
      message: 'Finalization triggered',
      result
    });
  } catch (error) {
    logger.error('Error finalizing auction:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to finalize auction',
      details: error.message
    });
  }
});

/**
 * POST /api/auctions/:id/settle
 * Manually trigger auction settlement (after escrow received)
 */
router.post('/:id/settle', async (req, res) => {
  try {
    const { id } = req.params;
    const auctionFinalizationService = require('../services/auctionFinalizationService');

    logger.info('Manual settlement requested for auction:', id);

    await auctionFinalizationService.settleAuction(id);

    res.json({
      success: true,
      message: 'Settlement completed'
    });
  } catch (error) {
    logger.error('Error settling auction:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to settle auction',
      details: error.message
    });
  }
});

/**
 * GET /api/auctions/:id/settlement-status
 * Get detailed settlement status for an auction
 */
router.get('/:id/settlement-status', async (req, res) => {
  try {
    const { id } = req.params;

    const auctionDoc = await firestore.collection('auctions').doc(id).get();

    if (!auctionDoc.exists) {
      return res.status(404).json({
        success: false,
        error: 'Auction not found'
      });
    }

    const auction = auctionDoc.data();

    const status = {
      auctionId: id,
      status: auction.status,
      finalized: auction.finalized || false,
      finalizedAt: auction.finalized_at,
      settlementStatus: auction.settlement_status || 'not_started',
      blockchainFinalized: auction.blockchain_finalized || false,
      blockchainFinalizationTx: auction.blockchain_finalization_tx,
      escrowTxHash: auction.escrow_tx_hash,
      settlementTxHash: auction.settlement_tx_hash,
      settledAt: auction.settled_at,
      winner: auction.winner_address || auction.current_bidder,
      finalPrice: {
        eth: auction.final_price || auction.current_bid,
        lkr: auction.final_price_lkr || auction.current_bid_lkr
      },
      errors: auction.blockchain_error
    };

    res.json({
      success: true,
      settlement: status
    });
  } catch (error) {
    logger.error('Error getting settlement status:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get settlement status'
    });
  }
});

module.exports = router;
