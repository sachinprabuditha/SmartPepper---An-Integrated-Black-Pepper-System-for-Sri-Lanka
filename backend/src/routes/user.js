const express = require('express');
const router = express.Router();
const db = require('../db/database');
const logger = require('../utils/logger');

/**
 * GET /api/users/:address
 * Get user by wallet address
 */
router.get('/:address', async (req, res) => {
  try {
    const { address } = req.params;
    
    const result = await db.query(
      'SELECT * FROM users WHERE wallet_address = $1',
      [address]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    res.json({
      success: true,
      user: result.rows[0]
    });
  } catch (error) {
    logger.error('Error fetching user:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch user'
    });
  }
});

/**
 * POST /api/users
 * Create or update user profile
 */
router.post('/', async (req, res) => {
  try {
    const {
      walletAddress,
      userType,
      name,
      email,
      phone,
      location
    } = req.body;

    if (!walletAddress || !userType) {
      return res.status(400).json({
        success: false,
        error: 'walletAddress and userType are required'
      });
    }

    // Upsert user
    const result = await db.query(
      `INSERT INTO users (
        wallet_address, user_type, name, email, phone, location
      ) VALUES ($1, $2, $3, $4, $5, $6)
      ON CONFLICT (wallet_address) 
      DO UPDATE SET
        user_type = EXCLUDED.user_type,
        name = EXCLUDED.name,
        email = EXCLUDED.email,
        phone = EXCLUDED.phone,
        location = EXCLUDED.location,
        updated_at = NOW()
      RETURNING *`,
      [walletAddress, userType, name, email, phone, JSON.stringify(location)]
    );

    res.status(201).json({
      success: true,
      user: result.rows[0]
    });
  } catch (error) {
    logger.error('Error creating/updating user:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to create/update user'
    });
  }
});

module.exports = router;
