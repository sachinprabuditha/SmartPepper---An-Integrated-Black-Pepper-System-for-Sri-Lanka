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
    
    // Exporters require admin approval before they can login
    const requiresApproval = role === 'exporter';
    
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
      is_active: requiresApproval ? false : true,
      approval_status: requiresApproval ? 'pending' : 'approved',
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

    // For exporters, return different message as they need approval
    const responseMessage = user.role === 'exporter' 
      ? 'Registration successful. Your account is pending admin approval. You will be able to login once approved.'
      : 'Registration successful';

    res.status(201).json({
      success: true,
      message: responseMessage,
      requiresApproval: user.role === 'exporter',
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        walletAddress: user.wallet_address,
        approval_status: user.approval_status
      },
      token: user.role === 'exporter' ? null : token // Don't provide token for exporters until approved
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

    // Check approval status for exporters
    if (user.role === 'exporter') {
      const approvalStatus = user.approval_status || 'pending';
      
      if (approvalStatus === 'pending') {
        return res.status(403).json({
          success: false,
          error: 'Your account is pending admin approval. Please wait for approval before logging in.',
          approval_status: 'pending'
        });
      }
      
      if (approvalStatus === 'rejected') {
        return res.status(403).json({
          success: false,
          error: 'Your account registration has been rejected. Please contact administrator for more information.',
          approval_status: 'rejected'
        });
      }
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
 * GET /api/auth/me
 * Get current authenticated user
 */
router.get('/me', async (req, res) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        error: 'No token provided'
      });
    }

    const token = authHeader.replace('Bearer ', '');

    let decoded;
    try {
      decoded = jwt.verify(token, JWT_SECRET);
    } catch (err) {
      return res.status(401).json({
        success: false,
        error: 'Invalid or expired token'
      });
    }

    const firestore = db.getDb();
    const userDoc = await firestore.collection('users').doc(decoded.userId).get();

    if (!userDoc.exists) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    const userData = userDoc.data();

    if (!userData.is_active) {
      return res.status(403).json({
        success: false,
        error: 'Account is disabled'
      });
    }

    res.json({
      success: true,
      user: {
        id: userDoc.id,
        email: userData.email,
        name: userData.name,
        role: userData.role,
        walletAddress: userData.wallet_address,
        verified: userData.verified,
        phone: userData.phone,
        address: userData.address,
        city: userData.city,
        language: userData.language
      }
    });
  } catch (error) {
    logger.error('Get current user error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get user'
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

/**
 * PUT /api/auth/profile
 * Update user profile
 */
router.put('/profile', async (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');

    if (!token) {
      return res.status(401).json({
        success: false,
        error: 'No token provided'
      });
    }

    const decoded = jwt.verify(token, JWT_SECRET);
    const { name, phone, address, city, language, walletAddress } = req.body;

    // Build update object dynamically
    const updates = {};

    if (name !== undefined) updates.name = name;
    if (phone !== undefined) updates.phone = phone;
    if (address !== undefined) updates.address = address;
    if (city !== undefined) updates.city = city;
    if (language !== undefined) updates.language = language;
    if (walletAddress !== undefined) {
      updates.wallet_address = walletAddress;
      updates.wallet_address_lower = walletAddress.toLowerCase();
    }

    if (Object.keys(updates).length === 0) {
      return res.status(400).json({
        success: false,
        error: 'No fields to update'
      });
    }

    updates.updated_at = admin.firestore.FieldValue.serverTimestamp();

    // Get user and update
    const firestore = db.getDb();
    const userRef = firestore.collection('users').doc(decoded.userId);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    await userRef.update(updates);
    const updatedDoc = await userRef.get();
    const userData = updatedDoc.data();

    // Return sanitized user data
    const user = {
      id: updatedDoc.id,
      email: userData.email,
      name: userData.name,
      role: userData.role || userData.user_type,
      walletAddress: userData.wallet_address,
      phone: userData.phone,
      address: userData.address,
      city: userData.city,
      language: userData.language
    };

    res.json({
      success: true,
      message: 'Profile updated successfully',
      user
    });
  } catch (error) {
    logger.error('Update profile error:', error);

    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        success: false,
        error: 'Invalid token'
      });
    }

    res.status(500).json({
      success: false,
      error: 'Failed to update profile'
    });
  }
});

/**
 * POST /api/auth/connect-wallet
 * Connect/update wallet address for authenticated user
 */
router.post('/connect-wallet', async (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');

    if (!token) {
      return res.status(401).json({
        success: false,
        error: 'No token provided'
      });
    }

    const decoded = jwt.verify(token, JWT_SECRET);
    const { walletAddress } = req.body;

    if (!walletAddress) {
      return res.status(400).json({
        success: false,
        error: 'Wallet address is required'
      });
    }

    // Validate wallet address format (basic check for Ethereum address)
    if (!/^0x[a-fA-F0-9]{40}$/.test(walletAddress)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid wallet address format'
      });
    }

    const firestore = db.getDb();
    const userRef = firestore.collection('users').doc(decoded.userId);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    const userData = userDoc.data();

    // Check if this wallet is already connected to another account
    const existingWalletSnap = await firestore.collection('users')
      .where('wallet_address_lower', '==', walletAddress.toLowerCase())
      .limit(1)
      .get();

    if (!existingWalletSnap.empty) {
      const existingUser = existingWalletSnap.docs[0];
      
      // Allow if it's the same user updating their wallet
      if (existingUser.id !== decoded.userId) {
        return res.status(409).json({
          success: false,
          error: 'This wallet address is already connected to another account'
        });
      }
    }

    // Update wallet address
    await userRef.update({
      wallet_address: walletAddress,
      wallet_address_lower: walletAddress.toLowerCase(),
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    });

    logger.info('Wallet connected successfully', {
      userId: decoded.userId,
      walletAddress,
      previousWallet: userData.wallet_address || 'none'
    });

    res.json({
      success: true,
      message: 'Wallet connected successfully',
      walletAddress
    });
  } catch (error) {
    logger.error('Connect wallet error:', error);

    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        success: false,
        error: 'Invalid token'
      });
    }

    res.status(500).json({
      success: false,
      error: 'Failed to connect wallet'
    });
  }
});

module.exports = router;
