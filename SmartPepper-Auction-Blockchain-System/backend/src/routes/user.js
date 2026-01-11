const express = require('express');
const router = express.Router();
const db = require('../db/database');
const logger = require('../utils/logger');

/**
 * GET /api/users
 * Get all users (admin only)
 */
router.get('/', async (req, res) => {
  try {
    const result = await db.query(
      `SELECT 
        id,
        wallet_address as "walletAddress",
        user_type as role,
        name,
        email,
        phone,
        verified,
        created_at as "createdAt",
        updated_at as "updatedAt"
      FROM users
      ORDER BY created_at DESC`
    );

    res.json({
      success: true,
      users: result.rows
    });
  } catch (error) {
    logger.error('Error fetching all users:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch users'
    });
  }
});

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

/**
 * PUT /api/users/:id
 * Update user (admin only)
 */
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { name, email, phone, role, verified } = req.body;

    const updates = [];
    const values = [];
    let paramCount = 1;

    if (name !== undefined) {
      updates.push(`name = $${paramCount}`);
      values.push(name);
      paramCount++;
    }
    if (email !== undefined) {
      updates.push(`email = $${paramCount}`);
      values.push(email);
      paramCount++;
    }
    if (phone !== undefined) {
      updates.push(`phone = $${paramCount}`);
      values.push(phone);
      paramCount++;
    }
    if (role !== undefined) {
      updates.push(`user_type = $${paramCount}`);
      values.push(role);
      paramCount++;
    }
    if (verified !== undefined) {
      updates.push(`verified = $${paramCount}`);
      values.push(verified);
      paramCount++;
    }

    if (updates.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'No fields to update'
      });
    }

    updates.push(`updated_at = NOW()`);
    values.push(id);

    const result = await db.query(
      `UPDATE users SET ${updates.join(', ')} WHERE id = $${paramCount} RETURNING *`,
      values
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
    logger.error('Error updating user:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update user'
    });
  }
});

/**
 * GET /api/users/:id/blockchain
 * Get user's blockchain activity
 */
router.get('/:id/blockchain', async (req, res) => {
  try {
    const { id } = req.params;

    // Get user
    const userResult = await db.query('SELECT * FROM users WHERE id = $1', [id]);
    if (userResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    const user = userResult.rows[0];
    const walletAddress = user.wallet_address || user.walletAddress;

    if (!walletAddress) {
      // Return empty data if no wallet connected
      return res.json({
        success: true,
        data: {
          walletAddress: null,
          auctionsCreated: 0,
          bidsPlaced: 0,
          nftPassports: 0
        }
      });
    }

    // Get auctions created by user (if farmer)
    const auctionsResult = await db.query(
      'SELECT COUNT(*) as count FROM auctions WHERE farmer_address = $1',
      [walletAddress]
    );

    // Get bids placed by user (if exporter)
    const bidsResult = await db.query(
      'SELECT COUNT(*) as count FROM bids WHERE bidder_address = $1',
      [walletAddress]
    );

    // Get NFT passports
    const passportsResult = await db.query(
      'SELECT COUNT(*) as count FROM nft_passports WHERE owner_address = $1',
      [walletAddress]
    );

    res.json({
      success: true,
      data: {
        walletAddress,
        auctionsCreated: parseInt(auctionsResult.rows[0]?.count || 0),
        bidsPlaced: parseInt(bidsResult.rows[0]?.count || 0),
        nftPassports: parseInt(passportsResult.rows[0]?.count || 0)
      }
    });
  } catch (error) {
    logger.error('Error fetching blockchain data:', error);
    // Return empty data instead of error
    res.json({
      success: true,
      data: {
        walletAddress: null,
        auctionsCreated: 0,
        bidsPlaced: 0,
        nftPassports: 0
      }
    });
  }
});

module.exports = router;
