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
      certificateHash,
      certificateIpfsUrl,
      txHash
    } = req.body;

    // Validate required fields
    if (!lotId || !farmerAddress || !variety || !quantity) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields'
      });
    }

    // Get or create farmer
    let farmerResult = await db.query(
      'SELECT id FROM users WHERE wallet_address = $1',
      [farmerAddress]
    );

    let farmerId;
    if (farmerResult.rows.length === 0) {
      // Create new farmer user
      const newFarmer = await db.query(
        `INSERT INTO users (wallet_address, user_type)
         VALUES ($1, $2)
         RETURNING id`,
        [farmerAddress, 'farmer']
      );
      farmerId = newFarmer.rows[0].id;
    } else {
      farmerId = farmerResult.rows[0].id;
    }

    // Insert lot
    const result = await db.query(
      `INSERT INTO pepper_lots (
        lot_id, farmer_id, farmer_address, variety, quantity,
        quality, harvest_date, certificate_hash, certificate_ipfs_url,
        blockchain_tx_hash, status
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
      RETURNING *`,
      [
        lotId,
        farmerId,
        farmerAddress,
        variety,
        quantity,
        quality,
        harvestDate,
        certificateHash,
        certificateIpfsUrl,
        txHash,
        'available'
      ]
    );

    res.status(201).json({
      success: true,
      lot: result.rows[0]
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

module.exports = router;
