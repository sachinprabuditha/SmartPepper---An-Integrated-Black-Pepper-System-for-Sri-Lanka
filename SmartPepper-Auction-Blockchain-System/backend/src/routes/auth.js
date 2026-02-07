const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../db/database');
const logger = require('../utils/logger');
const admin = require('firebase-admin');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';
const JWT_EXPIRES_IN = '7d';
const REFRESH_TOKEN_EXPIRES_IN = '30d';

/**
 * POST /api/auth/register
 * Register a new user
 */
router.post('/register', async (req, res) => {
  try {
    const {
      email,
      password,
      name,
      role,
      walletAddress,
      phone,
      address,
      city,
      language = 'en'
    } = req.body;

    // Validation
    if (!email || !password || !name || !role) {
      return res.status(400).json({
        success: false,
        error: 'Email, password, name, and role are required'
      });
    }

    // Validate role
    if (!['farmer', 'exporter', 'admin'].includes(role)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid role. Must be farmer, exporter, or admin'
      });
    }

    // Check if email already exists
    const firestore = db.getDb();
    const existingUserSnap = await firestore.collection('users')
      .where('email', '==', email)
      .limit(1)
      .get();

    if (!existingUserSnap.empty) {
      return res.status(409).json({
        success: false,
        error: 'Email already registered'
      });
    }

    // Check if wallet address already exists (if provided)
    if (walletAddress) {
      const existingWalletSnap = await firestore.collection('users')
        .where('wallet_address', '==', walletAddress)
        .limit(1)
        .get();

      if (!existingWalletSnap.empty) {
        return res.status(409).json({
          success: false,
          error: 'Wallet address already registered'
        });
      }
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    // Create user
    // Map auth roles to user_type: admin->regulator, exporter->exporter, farmer->farmer
    const userTypeMap = {
      'admin': 'regulator',
      'exporter': 'exporter',
      'farmer': 'farmer'
    };
    
    const userData = {
      email,
      password_hash: passwordHash,
      name,
      role,
      wallet_address: walletAddress || null,
      phone: phone || null,
      address: address || null,
      city: city || null,
      language,
      user_type: userTypeMap[role],
      verified: false,
      is_active: true,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    };
    
    const userRef = await firestore.collection('users').add(userData);
    const userDoc = await userRef.get();
    const user = { id: userDoc.id, ...userDoc.data() };

    // Generate JWT token
    const token = jwt.sign(
      { userId: user.id, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );

    // Log activity
    await firestore.collection('activity_logs').add({
      user_id: user.id,
      action: 'user_registered',
      ip_address: req.ip,
      created_at: admin.firestore.FieldValue.serverTimestamp()
    });

    res.status(201).json({
      success: true,
      message: 'Registration successful',
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        walletAddress: user.wallet_address
      },
      token
    });
  } catch (error) {
    logger.error('Registration error:', error);
    res.status(500).json({
      success: false,
      error: 'Registration failed'
    });
  }
});

/**
 * POST /api/auth/login
 * User login
 */
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validation
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        error: 'Email and password are required'
      });
    }

    // Find user
    const firestore = db.getDb();
    const userSnap = await firestore.collection('users')
      .where('email', '==', email)
      .limit(1)
      .get();

    if (userSnap.empty) {
      return res.status(401).json({
        success: false,
        error: 'Invalid email or password'
      });
    }

    const userDoc = userSnap.docs[0];
    const user = { id: userDoc.id, ...userDoc.data() };

    // Check if user is active
    if (!user.is_active) {
      return res.status(403).json({
        success: false,
        error: 'Account is disabled. Please contact administrator'
      });
    }

    // Verify password
    const isValidPassword = await bcrypt.compare(password, user.password_hash);

    if (!isValidPassword) {
      return res.status(401).json({
        success: false,
        error: 'Invalid email or password'
      });
    }

    // Generate tokens
    const token = jwt.sign(
      { userId: user.id, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );

    const refreshToken = jwt.sign(
      { userId: user.id, type: 'refresh' },
      JWT_SECRET,
      { expiresIn: REFRESH_TOKEN_EXPIRES_IN }
    );

    // Store session
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

    await firestore.collection('user_sessions').add({
      user_id: user.id,
      token,
      refresh_token: refreshToken,
      ip_address: req.ip,
      user_agent: req.headers['user-agent'],
      expires_at: admin.firestore.Timestamp.fromDate(expiresAt),
      created_at: admin.firestore.FieldValue.serverTimestamp()
    });

    // Update last login
    await firestore.collection('users').doc(user.id).update({
      last_login: admin.firestore.FieldValue.serverTimestamp()
    });

    // Log activity
    await firestore.collection('activity_logs').add({
      user_id: user.id,
      action: 'user_login',
      ip_address: req.ip,
      created_at: admin.firestore.FieldValue.serverTimestamp()
    });

    res.json({
      success: true,
      message: 'Login successful',
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        walletAddress: user.wallet_address,
        verified: user.verified,
        phone: user.phone,
        address: user.address,
        city: user.city,
        language: user.language
      },
      token,
      refreshToken
    });
  } catch (error) {
    logger.error('Login error:', error);
    res.status(500).json({
      success: false,
      error: 'Login failed'
    });
  }
});

/**
 * POST /api/auth/logout
 * User logout
 */
router.post('/logout', async (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');

    if (token) {
      // Remove session
      const firestore = db.getDb();
      const sessionsSnap = await firestore.collection('user_sessions')
        .where('token', '==', token)
        .get();
      
      const batch = firestore.batch();
      sessionsSnap.docs.forEach(doc => {
        batch.delete(doc.ref);
      });
      await batch.commit();
    }

    res.json({
      success: true,
      message: 'Logout successful'
    });
  } catch (error) {
    logger.error('Logout error:', error);
    res.status(500).json({
      success: false,
      error: 'Logout failed'
    });
  }
});

/**
 * POST /api/auth/refresh
 * Refresh access token
 */
router.post('/refresh', async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({
        success: false,
        error: 'Refresh token required'
      });
    }

    // Verify refresh token
    const decoded = jwt.verify(refreshToken, JWT_SECRET);

    if (decoded.type !== 'refresh') {
      return res.status(401).json({
        success: false,
        error: 'Invalid refresh token'
      });
    }

    // Get user
    const firestore = db.getDb();
    const userDoc = await firestore.collection('users').doc(decoded.userId).get();

    if (!userDoc.exists || !userDoc.data().is_active) {
      return res.status(401).json({
        success: false,
        error: 'User not found'
      });
    }

    const user = { id: userDoc.id, ...userDoc.data() };

    // Generate new access token
    const newToken = jwt.sign(
      { userId: user.id, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );

    res.json({
      success: true,
      token: newToken
    });
  } catch (error) {
    logger.error('Token refresh error:', error);
    res.status(401).json({
      success: false,
      error: 'Invalid or expired refresh token'
    });
  }
});

module.exports = router;
