const express = require('express');
const router = express.Router();
const admin = require('firebase-admin');
const logger = require('../utils/logger');
const BlockchainService = require('../services/blockchainService');

// Get Firestore instance
const db = admin.firestore();

/**
 * Helper function to convert Firestore Timestamps to ISO strings
 */
const convertTimestamps = (obj) => {
  if (!obj || typeof obj !== 'object') return obj;
  
  const converted = Array.isArray(obj) ? [] : {};
  
  for (const key in obj) {
    const value = obj[key];
    
    // Check if it's a Firestore Timestamp
    if (value && typeof value === 'object' && '_seconds' in value && '_nanoseconds' in value) {
      // Convert to ISO string
      const date = new Date(value._seconds * 1000 + value._nanoseconds / 1000000);
      converted[key] = date.toISOString();
    } else if (value && typeof value.toDate === 'function') {
      // Firestore Timestamp object with toDate method
      converted[key] = value.toDate().toISOString();
    } else if (Array.isArray(value)) {
      // Recursively convert arrays
      converted[key] = value.map(item => convertTimestamps(item));
    } else if (value && typeof value === 'object') {
      // Recursively convert nested objects
      converted[key] = convertTimestamps(value);
    } else {
      converted[key] = value;
    }
  }
  
  return converted;
};

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
    
    // Query pepper_lots collection for pending lots
    const lotsSnapshot = await db.collection('pepper_lots')
      .where('status', 'in', ['pending'])
      .orderBy('created_at', 'desc')
      .limit(parseInt(limit))
      .offset(parseInt(offset))
      .get();
    
    const compliancePendingSnapshot = await db.collection('pepper_lots')
      .where('compliance_status', '==', 'pending')
      .orderBy('created_at', 'desc')
      .limit(parseInt(limit))
      .offset(parseInt(offset))
      .get();
    
    // Combine results and remove duplicates
    const lotMap = new Map();
    
    for (const doc of lotsSnapshot.docs) {
      lotMap.set(doc.id, { id: doc.id, ...doc.data() });
    }
    
    for (const doc of compliancePendingSnapshot.docs) {
      if (!lotMap.has(doc.id)) {
        lotMap.set(doc.id, { id: doc.id, ...doc.data() });
      }
    }
    
    const lots = Array.from(lotMap.values());
    
    // Fetch farmer details for each lot
    const lotsWithFarmers = await Promise.all(
      lots.map(async (lot) => {
        let farmerData = null;
        
        // Try to fetch by farmer_id first
        if (lot.farmer_id) {
          const farmerDoc = await db.collection('users').doc(lot.farmer_id).get();
          if (farmerDoc.exists) {
            farmerData = farmerDoc.data();
          }
        }
        
        // If no farmer found by ID, try by wallet address
        if (!farmerData && lot.farmer_address) {
          const farmerSnapshot = await db.collection('users')
            .where('wallet_address_lower', '==', lot.farmer_address.toLowerCase())
            .limit(1)
            .get();
          
          if (!farmerSnapshot.empty) {
            farmerData = farmerSnapshot.docs[0].data();
          }
        }
        
        // Add farmer details if found
        if (farmerData) {
          return {
            ...lot,
            farmer_name: farmerData.name,
            farmer_email: farmerData.email,
            farmer_phone: farmerData.phone
          };
        }
        
        return lot;
      })
    );
    
    // Get count for pending lots
    const pendingStatusSnapshot = await db.collection('pepper_lots')
      .where('status', '==', 'pending')
      .get();
    
    const pendingComplianceSnapshot = await db.collection('pepper_lots')
      .where('compliance_status', '==', 'pending')
      .get();
    
    // Count unique lots
    const countSet = new Set();
    pendingStatusSnapshot.docs.forEach(doc => countSet.add(doc.id));
    pendingComplianceSnapshot.docs.forEach(doc => countSet.add(doc.id));
    
    logger.info(`Admin fetched ${lotsWithFarmers.length} pending lots`);
    
    res.json({
      success: true,
      count: countSet.size,
      lots: lotsWithFarmers.map(lot => convertTimestamps(lot))
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
    
    // Get lot by lot_id field
    const lotsSnapshot = await db.collection('pepper_lots')
      .where('lot_id', '==', lotId)
      .limit(1)
      .get();
    
    if (lotsSnapshot.empty) {
      return res.status(404).json({
        success: false,
        error: 'Lot not found'
      });
    }
    
    const lotDoc = lotsSnapshot.docs[0];
    const lot = { id: lotDoc.id, ...lotDoc.data() };
    
    // Fetch farmer details - try by farmer_id first, then by farmer_address
    let farmerData = null;
    
    if (lot.farmer_id) {
      const farmerDoc = await db.collection('users').doc(lot.farmer_id).get();
      if (farmerDoc.exists) {
        farmerData = farmerDoc.data();
      }
    }
    
    // If no farmer found by ID, try by wallet address
    if (!farmerData && lot.farmer_address) {
      const farmerSnapshot = await db.collection('users')
        .where('wallet_address_lower', '==', lot.farmer_address.toLowerCase())
        .limit(1)
        .get();
      
      if (!farmerSnapshot.empty) {
        farmerData = farmerSnapshot.docs[0].data();
      }
    }
    
    // Add farmer details to lot if found
    if (farmerData) {
      lot.farmer_name = farmerData.name;
      lot.farmer_email = farmerData.email;
      lot.farmer_phone = farmerData.phone;
      lot.wallet_address = farmerData.wallet_address || lot.farmer_address;
    } else {
      // Fallback: set farmer_address as the wallet_address
      lot.wallet_address = lot.farmer_address;
    }
    
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
    
    logger.info('Returning lot details:', { lotId, hasFarmerData: !!farmerData });
    
    res.json({
      success: true,
      lot: convertTimestamps(lot)
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
    
    // Find lot by lot_id
    const lotsSnapshot = await db.collection('pepper_lots')
      .where('lot_id', '==', lotId)
      .limit(1)
      .get();
    
    if (lotsSnapshot.empty) {
      return res.status(404).json({
        success: false,
        error: 'Lot not found'
      });
    }
    
    const lotDocRef = lotsSnapshot.docs[0].ref;
    const newStatus = status === 'approved' ? 'approved' : 'rejected';
    const lotStatus = status === 'approved' ? 'available' : 'rejected';
    
    // Update lot compliance status
    const updateData = {
      compliance_status: newStatus,
      status: lotStatus,
      compliance_checked_at: admin.firestore.FieldValue.serverTimestamp(),
      rejection_reason: status === 'rejected' ? reason : null,
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    };
    
    await lotDocRef.update(updateData);
    
    // Get updated lot
    const updatedLotDoc = await lotDocRef.get();
    const updatedLot = { id: updatedLotDoc.id, ...updatedLotDoc.data() };
    
    // Log the admin action
    try {
      await db.collection('admin_actions').add({
        admin_id: adminId || 'system',
        action_type: status === 'approved' ? 'approve_lot' : 'reject_lot',
        target_type: 'lot',
        target_id: lotId,
        details: { reason, lotId, adminName },
        created_at: admin.firestore.FieldValue.serverTimestamp()
      });
    } catch (err) {
      // Don't fail the main operation if logging fails
      logger.warn('Failed to log admin action:', err);
    }
    
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
        await lotDocRef.update({
          blockchain_tx_hash: blockchainTxHash
        });
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
    // Execute all queries in parallel
    const [
      pendingStatusSnapshot,
      pendingComplianceSnapshot,
      totalLotsSnapshot,
      approvedLotsSnapshot,
      rejectedLotsSnapshot,
      activeAuctionsSnapshot,
      totalUsersSnapshot
    ] = await Promise.all([
      db.collection('pepper_lots').where('status', '==', 'pending').get(),
      db.collection('pepper_lots').where('compliance_status', '==', 'pending').get(),
      db.collection('pepper_lots').get(),
      db.collection('pepper_lots').where('compliance_status', '==', 'approved').get(),
      db.collection('pepper_lots').where('compliance_status', '==', 'rejected').get(),
      db.collection('auctions').where('status', '==', 'active').get(),
      db.collection('users').get()
    ]);
    
    // Count unique pending lots (status OR compliance_status = pending)
    const pendingSet = new Set();
    pendingStatusSnapshot.docs.forEach(doc => pendingSet.add(doc.id));
    pendingComplianceSnapshot.docs.forEach(doc => pendingSet.add(doc.id));
    
    res.json({
      success: true,
      stats: {
        pendingLots: pendingSet.size,
        totalLots: totalLotsSnapshot.size,
        approvedLots: approvedLotsSnapshot.size,
        rejectedLots: rejectedLotsSnapshot.size,
        activeAuctions: activeAuctionsSnapshot.size,
        totalUsers: totalUsersSnapshot.size
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
