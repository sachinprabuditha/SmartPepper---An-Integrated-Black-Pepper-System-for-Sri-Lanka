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

    // Check if session exists and is valid
    const sessionResult = await db.query(
      `SELECT user_id, expires_at FROM user_sessions 
       WHERE token = $1 AND expires_at > NOW()`,
      [token]
    );

    if (sessionResult.rows.length === 0) {
      return res.status(401).json({
        success: false,
        error: 'Invalid or expired session'
      });
    }

    // Get user details
    const userResult = await db.query(
      `SELECT id, email, role, wallet_address, is_active 
       FROM users WHERE id = $1`,
      [decoded.userId]
    );

    if (userResult.rows.length === 0) {
      return res.status(401).json({
        success: false,
        error: 'User not found'
      });
    }

    const user = userResult.rows[0];

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

      // Check if user has permission
      const result = await db.query(
        `SELECT id FROM permissions 
         WHERE role = $1 AND resource = $2 AND action = $3`,
        [req.user.role, resource, action]
      );

      if (result.rows.length === 0) {
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

    const userResult = await db.query(
      `SELECT id, email, role, wallet_address 
       FROM users WHERE id = $1 AND is_active = true`,
      [decoded.userId]
    );

    if (userResult.rows.length > 0) {
      req.user = userResult.rows[0];
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
        await db.query(
          `INSERT INTO activity_logs (user_id, action, resource_type, resource_id, details, ip_address)
           VALUES ($1, $2, $3, $4, $5, $6)`,
          [
            req.user.id,
            action,
            req.params.resourceType || null,
            req.params.id || req.params.lotId || req.params.auctionId || null,
            JSON.stringify({ method: req.method, path: req.path }),
            req.ip
          ]
        );
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
