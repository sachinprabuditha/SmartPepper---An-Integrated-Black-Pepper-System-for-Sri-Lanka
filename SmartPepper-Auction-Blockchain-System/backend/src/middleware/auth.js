const jwt = require('jsonwebtoken');
const db = require('../db/database');
const logger = require('../utils/logger');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

/**
 * Middleware to authenticate JWT token
 */
const authenticate = async (req, res, next) => {
  try {
    // Get token from header
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        error: 'No token provided'
      });
    }

    const token = authHeader.replace('Bearer ', '');

    // Verify token
    const decoded = jwt.verify(token, JWT_SECRET);
    const firestore = db.getDb();

    // Check if session exists and is valid
    const sessionSnap = await firestore.collection('user_sessions')
      .where('token', '==', token)
      .limit(1)
      .get();

    if (sessionSnap.empty) {
      logger.info('Auth Error: Session Snap Empty for token');
      return res.status(401).json({
        success: false,
        error: 'Invalid or expired session'
      });
    }

    const session = sessionSnap.docs[0].data();
    if (session.expires_at) {
      const expiresAt = session.expires_at.toDate ? session.expires_at.toDate() : new Date(session.expires_at);
      if (expiresAt < new Date()) {
        logger.info('Auth Error: Session is expired', { expiresAt, now: new Date() });
        return res.status(401).json({
          success: false,
          error: 'Invalid or expired session'
        });
      }
    }

    // Get user details
    const userDoc = await firestore.collection('users').doc(decoded.userId).get();

    if (!userDoc.exists) {
      logger.info('Auth Error: User details not found for ID', decoded.userId);
      return res.status(401).json({
        success: false,
        error: 'User not found'
      });
    }

    const user = { id: userDoc.id, ...userDoc.data() };

    // Check if user is active
    if (!user.is_active) {
      return res.status(403).json({
        success: false,
        error: 'Account is disabled'
      });
    }

    // Attach user to request
    req.user = user;
    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        success: false,
        error: 'Invalid token'
      });
    }

    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        error: 'Token expired'
      });
    }

    logger.error('Authentication error:', error);
    res.status(500).json({
      success: false,
      error: 'Authentication failed'
    });
  }
};

/**
 * Middleware to check user role
 * @param {Array} allowedRoles - Array of allowed roles
 */
const authorize = (...allowedRoles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        error: 'Not authenticated'
      });
    }

    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        error: 'Access denied. Insufficient permissions'
      });
    }

    next();
  };
};

/**
 * Middleware to check specific permission
 * @param {string} resource - Resource type (e.g., 'auction', 'lot')
 * @param {string} action - Action type (e.g., 'create', 'read', 'update', 'delete')
 */
const checkPermission = (resource, action) => {
  return async (req, res, next) => {
    try {
      if (!req.user) {
        return res.status(401).json({
          success: false,
          error: 'Not authenticated'
        });
      }

      // Admin has all permissions
      if (req.user.role === 'admin') {
        return next();
      }

      const firestore = db.getDb();
      // Check if user has permission
      const permSnap = await firestore.collection('permissions')
        .where('role', '==', req.user.role)
        .where('resource', '==', resource)
        .where('action', '==', action)
        .limit(1)
        .get();

      if (permSnap.empty) {
        return res.status(403).json({
          success: false,
          error: `Permission denied: Cannot ${action} ${resource}`
        });
      }

      next();
    } catch (error) {
      logger.error('Permission check error:', error);
      res.status(500).json({
        success: false,
        error: 'Permission check failed'
      });
    }
  };
};

/**
 * Optional authentication - attaches user if token is valid, but doesn't require it
 */
const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return next();
    }

    const token = authHeader.replace('Bearer ', '');
    const decoded = jwt.verify(token, JWT_SECRET);

    const firestore = db.getDb();
    const userDoc = await firestore.collection('users').doc(decoded.userId).get();

    if (userDoc.exists) {
      const user = { id: userDoc.id, ...userDoc.data() };
      if (user.is_active) {
        req.user = user;
      }
    }

    next();
  } catch (error) {
    // Silently fail and continue without user
    next();
  }
};

/**
 * Middleware to log user activity
 */
const logActivity = (action) => {
  return async (req, res, next) => {
    try {
      if (req.user) {
        const firestore = db.getDb();
        const admin = require('firebase-admin');
        await firestore.collection('activity_logs').add({
          user_id: req.user.id,
          action: action,
          resource_type: req.params.resourceType || null,
          resource_id: req.params.id || req.params.lotId || req.params.auctionId || null,
          details: JSON.stringify({ method: req.method, path: req.path }),
          ip_address: req.ip,
          created_at: admin.firestore.FieldValue.serverTimestamp()
        });
      }
    } catch (error) {
      logger.error('Activity logging error:', error);
      // Don't fail the request if logging fails
    }
    next();
  };
};

module.exports = {
  authenticate,
  authorize,
  checkPermission,
  optionalAuth,
  logActivity
};
