const express = require('express');
const router = express.Router();
const db = require('../db/database');
const logger = require('../utils/logger');
const BlockchainService = require('../services/blockchainService');

// Initialize blockchain service
const blockchainService = new BlockchainService();
blockchainService.initialize().catch(err => {
  logger.error('Failed to initialize blockchain service in admin routes:', err);
});

/**
 * GET /api/admin/lots/pending
 * Get all lots pending admin approval
 * Only accessible by admin users
 */
router.get('/lots/pending', async (req, res) => {
  try {
    const { limit = 50, offset = 0 } = req.query;
    
    // TODO: Add auth middleware to verify admin role
    // For now, assuming request is from authenticated admin
    
    const query = `
      SELECT 
        pl.*,
        u.name as farmer_name,
        u.email as farmer_email,
        u.phone as farmer_phone
      FROM pepper_lots pl
      LEFT JOIN users u ON pl.farmer_id = u.id
      WHERE pl.status = 'pending' OR pl.compliance_status = 'pending'
      ORDER BY pl.created_at DESC
      LIMIT $1 OFFSET $2
    `;
    
    const countQuery = `
      SELECT COUNT(*) 
      FROM pepper_lots 
      WHERE status = 'pending' OR compliance_status = 'pending'
    `;
    
    const [result, countResult] = await Promise.all([
      db.query(query, [limit, offset]),
      db.query(countQuery)
    ]);
    
    logger.info(`Admin fetched ${result.rows.length} pending lots`);
    
    res.json({
      success: true,
      count: parseInt(countResult.rows[0].count),
      lots: result.rows
    });
  } catch (error) {
    logger.error('Error fetching pending lots:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch pending lots',
      details: error.message
    });
  }
});

/**
 * GET /api/admin/lots/:lotId
 * Get detailed lot information including images
 */
router.get('/lots/:lotId', async (req, res) => {
  try {
    const { lotId } = req.params;
    
    const result = await db.query(`
      SELECT 
        pl.*,
        u.name as farmer_name,
        u.email as farmer_email,
        u.phone as farmer_phone,
        u.wallet_address
      FROM pepper_lots pl
      LEFT JOIN users u ON pl.farmer_id = u.id
      WHERE pl.lot_id = $1
    `, [lotId]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Lot not found'
      });
    }
    
    const lot = result.rows[0];
    
    // Parse lot_pictures and certificate_images if they're stored as JSON strings
    if (lot.lot_pictures && typeof lot.lot_pictures === 'string') {
      try {
        lot.lot_pictures = JSON.parse(lot.lot_pictures);
      } catch (e) {
        logger.warn('Failed to parse lot_pictures:', e);
      }
    }
    
    if (lot.certificate_images && typeof lot.certificate_images === 'string') {
      try {
        lot.certificate_images = JSON.parse(lot.certificate_images);
      } catch (e) {
        logger.warn('Failed to parse certificate_images:', e);
      }
    }
    
    res.json({
      success: true,
      lot
    });
  } catch (error) {
    logger.error('Error fetching lot details:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch lot details',
      details: error.message
    });
  }
});

/**
 * PUT /api/admin/lots/:lotId/compliance
 * Approve or reject lot compliance
 */
router.put('/lots/:lotId/compliance', async (req, res) => {
  try {
    const { lotId } = req.params;
    const { status, reason, adminId, adminName } = req.body;
    
    // Validate status
    if (!['approved', 'rejected'].includes(status)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid status. Must be "approved" or "rejected"'
      });
    }
    
    // If rejected, reason is required
    if (status === 'rejected' && !reason) {
      return res.status(400).json({
        success: false,
        error: 'Rejection reason is required'
      });
    }
    
    logger.info(`Admin ${adminName || adminId} ${status} lot ${lotId}`, { reason });
    
    // Update lot compliance status
    const updateQuery = `
      UPDATE pepper_lots
      SET 
        compliance_status = $1,
        status = $2,
        compliance_checked_at = NOW(),
        rejection_reason = $3,
        updated_at = NOW()
      WHERE lot_id = $4
      RETURNING *
    `;
    
    const newStatus = status === 'approved' ? 'approved' : 'rejected';
    const lotStatus = status === 'approved' ? 'available' : 'rejected';
    
    const result = await db.query(updateQuery, [
      newStatus,
      lotStatus,
      status === 'rejected' ? reason : null,
      lotId
    ]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Lot not found'
      });
    }
    
    const updatedLot = result.rows[0];
    
    // Log the admin action
    await db.query(`
      INSERT INTO admin_actions (
        admin_id,
        action_type,
        target_type,
        target_id,
        details,
        created_at
      ) VALUES ($1, $2, $3, $4, $5, NOW())
    `, [
      adminId || 'system',
      status === 'approved' ? 'approve_lot' : 'reject_lot',
      'lot',
      lotId,
      JSON.stringify({ reason, lotId, adminName })
    ]).catch(err => {
      // Don't fail the main operation if logging fails
      logger.warn('Failed to log admin action:', err);
    });
    
    // Update blockchain with compliance status
    let blockchainTxHash = null;
    let blockchainError = null;
    
    try {
      logger.info('Attempting to update compliance status on blockchain', { lotId, status });
      blockchainTxHash = await blockchainService.updateLotComplianceOnChain(
        lotId,
        status === 'approved'
      );
      
      // Update blockchain_tx_hash in database
      if (blockchainTxHash) {
        await db.query(
          'UPDATE pepper_lots SET blockchain_tx_hash = $1 WHERE lot_id = $2',
          [blockchainTxHash, lotId]
        );
        logger.info('Blockchain transaction hash updated in database', { lotId, blockchainTxHash });
      }
    } catch (blockchainErr) {
      blockchainError = blockchainErr.message;
      logger.error('Blockchain update failed (database update succeeded):', blockchainErr);
      // Don't fail the entire operation if blockchain update fails
      // The database update already succeeded
    }
    
    res.json({
      success: true,
      message: `Lot ${status} successfully`,
      lot: updatedLot,
      blockchainTxHash,
      blockchainError,
      blockchainTxRequired: !blockchainTxHash // True if blockchain update failed
    });
    
  } catch (error) {
    logger.error('Error updating lot compliance:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update lot compliance',
      details: error.message
    });
  }
});

/**
 * GET /api/admin/stats
 * Get admin dashboard statistics
 */
router.get('/stats', async (req, res) => {
  try {
    const statsQueries = [
      // Pending lots
      db.query(`SELECT COUNT(*) as count FROM pepper_lots WHERE status = 'pending' OR compliance_status = 'pending'`),
      // Total lots
      db.query(`SELECT COUNT(*) as count FROM pepper_lots`),
      // Approved lots
      db.query(`SELECT COUNT(*) as count FROM pepper_lots WHERE compliance_status = 'approved'`),
      // Rejected lots
      db.query(`SELECT COUNT(*) as count FROM pepper_lots WHERE compliance_status = 'rejected'`),
      // Active auctions
      db.query(`SELECT COUNT(*) as count FROM auctions WHERE status = 'active'`),
      // Total users
      db.query(`SELECT COUNT(*) as count FROM users`),
    ];
    
    const [pending, total, approved, rejected, activeAuctions, totalUsers] = await Promise.all(statsQueries);
    
    res.json({
      success: true,
      stats: {
        pendingLots: parseInt(pending.rows[0].count),
        totalLots: parseInt(total.rows[0].count),
        approvedLots: parseInt(approved.rows[0].count),
        rejectedLots: parseInt(rejected.rows[0].count),
        activeAuctions: parseInt(activeAuctions.rows[0].count),
        totalUsers: parseInt(totalUsers.rows[0].count)
      }
    });
  } catch (error) {
    logger.error('Error fetching admin stats:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch stats',
      details: error.message
    });
  }
});

module.exports = router;
