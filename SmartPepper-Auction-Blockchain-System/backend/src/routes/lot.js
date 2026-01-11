const express = require('express');
const router = express.Router();
const db = require('../db/database');
const logger = require('../utils/logger');

/**
 * GET /api/lots
 * Get all pepper lots
 */
router.get('/', async (req, res) => {
  try {
    const { status, farmer, limit = 50, offset = 0 } = req.query;
    
    let query = 'SELECT * FROM pepper_lots WHERE 1=1';
    let countQuery = 'SELECT COUNT(*) FROM pepper_lots WHERE 1=1';
    const params = [];
    const countParams = [];
    let paramIndex = 1;
    let countParamIndex = 1;

    if (status) {
      query += ` AND status = $${paramIndex++}`;
      countQuery += ` AND status = $${countParamIndex++}`;
      params.push(status);
      countParams.push(status);
    }

    if (farmer) {
      query += ` AND LOWER(farmer_address) = LOWER($${paramIndex++})`;
      countQuery += ` AND LOWER(farmer_address) = LOWER($${countParamIndex++})`;
      params.push(farmer);
      countParams.push(farmer);
      logger.info('Filtering lots by farmer:', { farmer, farmerLower: farmer.toLowerCase() });
    }

    query += ` ORDER BY created_at DESC LIMIT $${paramIndex++} OFFSET $${paramIndex++}`;
    params.push(limit, offset);

    logger.info('Executing lot query:', { query, params });
    
    const [result, countResult] = await Promise.all([
      db.query(query, params),
      db.query(countQuery, countParams)
    ]);

    logger.info('Query results:', { 
      count: parseInt(countResult.rows[0].count),
      lotsReturned: result.rows.length,
      firstLot: result.rows[0] ? { lot_id: result.rows[0].lot_id, farmer: result.rows[0].farmer_address } : null
    });

    res.json({
      success: true,
      count: parseInt(countResult.rows[0].count),
      lots: result.rows
    });
  } catch (error) {
    logger.error('Error fetching lots:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch lots'
    });
  }
});

/**
 * GET /api/lots/:lotId
 * Get lot details
 */
router.get('/:lotId', async (req, res) => {
  try {
    const { lotId } = req.params;
    
    const result = await db.query(
      'SELECT * FROM pepper_lots WHERE lot_id = $1',
      [lotId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Lot not found'
      });
    }

    res.json({
      success: true,
      lot: result.rows[0]
    });
  } catch (error) {
    logger.error('Error fetching lot:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch lot'
    });
  }
});

/**
 * POST /api/lots
 * Create a new pepper lot
 */
router.post('/', async (req, res) => {
  try {
    const {
      lotId,
      farmerAddress,
      variety,
      quantity,
      quality,
      harvestDate,
      origin,
      farmLocation,
      organicCertified,
      metadataURI,
      certificateHash,
      certificateIpfsUrl,
      lotPictures,
      certificateImages,
      txHash
    } = req.body;

    // Validate required fields
    if (!lotId || !farmerAddress || !variety || !quantity) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields'
      });
    }

    logger.info('Creating new lot:', { 
      lotId, 
      farmerAddress, 
      variety, 
      quantity,
      origin,
      farmLocation,
      lotPictures: lotPictures ? lotPictures.length : 0,
      certificateImages: certificateImages ? certificateImages.length : 0
    });

    // Get or create farmer (case-insensitive lookup)
    let farmerResult = await db.query(
      'SELECT id FROM users WHERE LOWER(wallet_address) = LOWER($1)',
      [farmerAddress]
    );

    let farmerId;
    if (farmerResult.rows.length === 0) {
      // Create new farmer user
      logger.info('Creating new farmer user:', { farmerAddress });
      const newFarmer = await db.query(
        `INSERT INTO users (wallet_address, user_type)
         VALUES ($1, $2)
         RETURNING id`,
        [farmerAddress, 'farmer']
      );
      farmerId = newFarmer.rows[0].id;
      logger.info('New farmer created with ID:', farmerId);
    } else {
      farmerId = farmerResult.rows[0].id;
      logger.info('Found existing farmer with ID:', farmerId);
    }

    // Insert lot
    const result = await db.query(
      `INSERT INTO pepper_lots (
        lot_id, farmer_id, farmer_address, variety, quantity,
        quality, harvest_date, origin, farm_location, organic_certified,
        metadata_uri, certificate_hash, certificate_ipfs_url,
        lot_pictures, certificate_images, blockchain_tx_hash, status
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)
      RETURNING *`,
      [
        lotId,
        farmerId,
        farmerAddress,
        variety,
        quantity,
        quality,
        harvestDate,
        origin,
        farmLocation,
        organicCertified || false,
        metadataURI,
        certificateHash,
        certificateIpfsUrl,
        lotPictures ? JSON.stringify(lotPictures) : '[]',
        certificateImages ? JSON.stringify(certificateImages) : '[]',
        txHash,
        'available'
      ]
    );

    logger.info('✅ Lot created successfully:', { 
      lotId, 
      farmerAddress, 
      farmer_id: farmerId,
      lot_db_id: result.rows[0].id 
    });

    res.status(201).json({
      success: true,
      lot: result.rows[0],
      message: 'Lot created successfully'
    });
  } catch (error) {
    logger.error('Error creating lot:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to create lot',
      details: error.message
    });
  }
});

/**
 * GET /api/lots/farmer/:address
 * Get lots for a specific farmer with optional compliance status filter
 */
router.get('/farmer/:address', async (req, res) => {
  try {
    const { address } = req.params;
    const { compliance_status } = req.query;
    
    let query = 'SELECT * FROM pepper_lots WHERE LOWER(farmer_address) = LOWER($1)';
    const params = [address];
    
    if (compliance_status) {
      query += ' AND compliance_status = $2';
      params.push(compliance_status);
    }
    
    query += ' ORDER BY created_at DESC';
    
    const result = await db.query(query, params);
    
    res.json({
      success: true,
      lots: result.rows
    });
  } catch (error) {
    logger.error('Error fetching farmer lots:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch lots',
      details: error.message
    });
  }
});

module.exports = router;
