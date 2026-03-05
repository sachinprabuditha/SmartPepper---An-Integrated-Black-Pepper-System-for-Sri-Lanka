const express = require('express');
const router = express.Router();
const db = require('../db/database');
const logger = require('../utils/logger');
const admin = require('firebase-admin');

/**
 * GET /api/users
 * Get all users (admin only)
 */
router.get('/', async (req, res) => {
  try {
    const firestore = db.getDb();
    const usersSnap = await firestore.collection('users')
      .orderBy('created_at', 'desc')
      .get();

    const users = usersSnap.docs.map(doc => {
      const data = doc.data();
      return {
        id: doc.id,
        walletAddress: data.wallet_address,
        role: data.user_type || data.role,
        name: data.name,
        email: data.email,
        phone: data.phone,
        verified: data.verified,
        createdAt: data.created_at,
        updatedAt: data.updated_at
      };
    });

    res.json({
      success: true,
      users
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
    
    const firestore = db.getDb();
    const usersSnap = await firestore.collection('users')
      .where('wallet_address', '==', address)
      .limit(1)
      .get();

    if (usersSnap.empty) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    const userDoc = usersSnap.docs[0];
    const user = { id: userDoc.id, ...userDoc.data() };

    res.json({
      success: true,
      user
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

    const firestore = db.getDb();
    
    // Check if user exists
    const existingUserSnap = await firestore.collection('users')
      .where('wallet_address', '==', walletAddress)
      .limit(1)
      .get();

    let userData = {
      wallet_address: walletAddress,
      user_type: userType,
      name: name || null,
      email: email || null,
      phone: phone || null,
      location: location || null,
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    };

    let user;
    if (existingUserSnap.empty) {
      // Create new user
      userData.created_at = admin.firestore.FieldValue.serverTimestamp();
      const userRef = await firestore.collection('users').add(userData);
      const userDoc = await userRef.get();
      user = { id: userDoc.id, ...userDoc.data() };
    } else {
      // Update existing user
      const userDoc = existingUserSnap.docs[0];
      await userDoc.ref.update(userData);
      const updatedDoc = await userDoc.ref.get();
      user = { id: updatedDoc.id, ...updatedDoc.data() };
    }

    res.status(201).json({
      success: true,
      user
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

    const updates = {};
    if (name !== undefined) updates.name = name;
    if (email !== undefined) updates.email = email;
    if (phone !== undefined) updates.phone = phone;
    if (role !== undefined) updates.user_type = role;
    if (verified !== undefined) updates.verified = verified;

    if (Object.keys(updates).length === 0) {
      return res.status(400).json({
        success: false,
        error: 'No fields to update'
      });
    }

    updates.updated_at = admin.firestore.FieldValue.serverTimestamp();

    const firestore = db.getDb();
    const userRef = firestore.collection('users').doc(id);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    await userRef.update(updates);
    const updatedDoc = await userRef.get();
    const user = { id: updatedDoc.id, ...updatedDoc.data() };

    res.json({
      success: true,
      user
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
    const firestore = db.getDb();

    // Get user
    const userDoc = await firestore.collection('users').doc(id).get();
    if (!userDoc.exists) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    const user = userDoc.data();
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
    const auctionsSnap = await firestore.collection('auctions')
      .where('farmer_address', '==', walletAddress)
      .get();

    // Get bids placed by user (if exporter)
    const bidsSnap = await firestore.collection('bids')
      .where('bidder_address', '==', walletAddress)
      .get();

    // Get NFT passports
    const passportsSnap = await firestore.collection('nft_passports')
      .where('owner_address', '==', walletAddress)
      .get();

    res.json({
      success: true,
      data: {
        walletAddress,
        auctionsCreated: auctionsSnap.size,
        bidsPlaced: bidsSnap.size,
        nftPassports: passportsSnap.size
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
