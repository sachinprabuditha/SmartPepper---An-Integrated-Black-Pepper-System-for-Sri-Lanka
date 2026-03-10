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

/**
 * GET /api/admin/recent-activity
 * Get recent system activities for admin dashboard
 */
router.get('/recent-activity', async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 10;
    const activities = [];

    // Fetch recent admin actions
    const adminActionsSnapshot = await db.collection('admin_actions')
      .orderBy('created_at', 'desc')
      .limit(limit)
      .get();

    adminActionsSnapshot.docs.forEach(doc => {
      const data = doc.data();
      const actionType = data.action_type;
      let description = '';
      let icon = '✅';
      let color = 'green';

      if (actionType === 'approve_lot') {
        description = `Lot ${data.target_id} approved`;
        icon = '✅';
        color = 'green';
      } else if (actionType === 'reject_lot') {
        description = `Lot ${data.target_id} rejected`;
        icon = '❌';
        color = 'red';
      } else {
        description = `Admin action: ${actionType}`;
        icon = '⚙️';
        color = 'purple';
      }

      activities.push({
        type: 'admin_action',
        description,
        icon,
        color,
        timestamp: data.created_at,
        details: data.details || {}
      });
    });

    // Fetch recent auctions created
    const auctionsSnapshot = await db.collection('auctions')
      .orderBy('created_at', 'desc')
      .limit(limit)
      .get();

    auctionsSnapshot.docs.forEach(doc => {
      const data = doc.data();
      activities.push({
        type: 'auction_created',
        description: `New auction created: ${data.lot_id || doc.id}`,
        icon: '🔨',
        color: 'blue',
        timestamp: data.created_at,
        details: { auction_id: doc.id, lot_id: data.lot_id }
      });
    });

    // Fetch recent lots submitted
    const lotsSnapshot = await db.collection('pepper_lots')
      .orderBy('created_at', 'desc')
      .limit(limit)
      .get();

    lotsSnapshot.docs.forEach(doc => {
      const data = doc.data();
      activities.push({
        type: 'lot_submitted',
        description: `New lot submitted: ${data.lot_id || doc.id}`,
        icon: '📦',
        color: 'orange',
        timestamp: data.created_at,
        details: { lot_id: data.lot_id, variety: data.variety, quantity: data.quantity }
      });
    });

    // Fetch recent user registrations
    const usersSnapshot = await db.collection('users')
      .orderBy('created_at', 'desc')
      .limit(limit)
      .get();

    usersSnapshot.docs.forEach(doc => {
      const data = doc.data();
      activities.push({
        type: 'user_registered',
        description: `New user registered: ${data.name || data.email}`,
        icon: '👤',
        color: 'blue',
        timestamp: data.created_at,
        details: { user_id: doc.id, role: data.role, email: data.email }
      });
    });

    // Fetch recent bids
    const bidsSnapshot = await db.collection('bids')
      .orderBy('created_at', 'desc')
      .limit(limit)
      .get();

    bidsSnapshot.docs.forEach(doc => {
      const data = doc.data();
      activities.push({
        type: 'bid_placed',
        description: `New bid placed on auction ${data.auction_id}`,
        icon: '💰',
        color: 'green',
        timestamp: data.created_at,
        details: { auction_id: data.auction_id, amount: data.amount, bidder: data.bidder_address }
      });
    });

    // Sort all activities by timestamp (most recent first)
    activities.sort((a, b) => {
      const timeA = a.timestamp?.toMillis?.() || a.timestamp?.seconds * 1000 || 0;
      const timeB = b.timestamp?.toMillis?.() || b.timestamp?.seconds * 1000 || 0;
      return timeB - timeA;
    });

    // Return only the requested limit
    const recentActivities = activities.slice(0, limit);

    // Format timestamps for frontend
    const formattedActivities = recentActivities.map(activity => ({
      ...activity,
      timestamp: activity.timestamp?.toDate?.() || activity.timestamp,
      timeAgo: getTimeAgo(activity.timestamp)
    }));

    logger.info(`Fetched ${formattedActivities.length} recent activities`);

    res.json({
      success: true,
      activities: formattedActivities
    });
  } catch (error) {
    logger.error('Error fetching recent activity:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch recent activity',
      details: error.message
    });
  }
});

/**
 * Helper function to calculate time ago
 */
function getTimeAgo(timestamp) {
  if (!timestamp) return 'Unknown';
  
  const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
  const now = new Date();
  const seconds = Math.floor((now - date) / 1000);

  if (seconds < 60) return `${seconds} seconds ago`;
  if (seconds < 3600) return `${Math.floor(seconds / 60)} minutes ago`;
  if (seconds < 86400) return `${Math.floor(seconds / 3600)} hours ago`;
  if (seconds < 604800) return `${Math.floor(seconds / 86400)} days ago`;
  return date.toLocaleDateString();
}

/**
 * GET /api/admin/users/pending
 * Get all users pending admin approval (exporters)
 */
router.get('/users/pending', async (req, res) => {
  try {
    const { limit = 50, offset = 0 } = req.query;
    
    // Query users with pending approval status
    const pendingUsersSnapshot = await db.collection('users')
      .where('approval_status', '==', 'pending')
      .orderBy('created_at', 'desc')
      .limit(parseInt(limit))
      .offset(parseInt(offset))
      .get();
    
    const users = pendingUsersSnapshot.docs.map(doc => {
      const data = doc.data();
      return {
        id: doc.id,
        name: data.name,
        email: data.email,
        role: data.role,
        phone: data.phone || null,
        address: data.address || null,
        city: data.city || null,
        wallet_address: data.wallet_address || null,
        approval_status: data.approval_status,
        created_at: data.created_at,
        updated_at: data.updated_at
      };
    });

    // Convert timestamps
    const usersWithFormattedDates = convertTimestamps(users);

    logger.info(`Fetched ${users.length} pending users`);

    res.json({
      success: true,
      users: usersWithFormattedDates,
      total: users.length
    });
  } catch (error) {
    logger.error('Error fetching pending users:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch pending users',
      details: error.message
    });
  }
});

/**
 * GET /api/admin/users
 * Get all users with optional filtering
 */
router.get('/users', async (req, res) => {
  try {
    const { limit = 50, offset = 0, role, approval_status } = req.query;
    
    let query = db.collection('users');
    
    // Apply filters
    if (role) {
      query = query.where('role', '==', role);
    }
    
    if (approval_status) {
      query = query.where('approval_status', '==', approval_status);
    }
    
    const usersSnapshot = await query
      .orderBy('created_at', 'desc')
      .limit(parseInt(limit))
      .offset(parseInt(offset))
      .get();
    
    const users = usersSnapshot.docs.map(doc => {
      const data = doc.data();
      return {
        id: doc.id,
        name: data.name,
        email: data.email,
        role: data.role,
        phone: data.phone || null,
        address: data.address || null,
        city: data.city || null,
        wallet_address: data.wallet_address || null,
        approval_status: data.approval_status || 'approved',
        is_active: data.is_active,
        verified: data.verified || false,
        created_at: data.created_at,
        updated_at: data.updated_at,
        last_login: data.last_login || null
      };
    });

    // Convert timestamps
    const usersWithFormattedDates = convertTimestamps(users);

    logger.info(`Fetched ${users.length} users`);

    res.json({
      success: true,
      users: usersWithFormattedDates,
      total: users.length
    });
  } catch (error) {
    logger.error('Error fetching users:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch users',
      details: error.message
    });
  }
});

/**
 * POST /api/admin/users/:userId/approve
 * Approve a pending user (exporter)
 */
router.post('/users/:userId/approve', async (req, res) => {
  try {
    const { userId } = req.params;
    const { adminId, adminName } = req.body;

    // Get user document
    const userRef = db.collection('users').doc(userId);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    const userData = userDoc.data();

    // Check if user is an exporter
    if (userData.role !== 'exporter') {
      return res.status(400).json({
        success: false,
        error: 'Only exporter accounts require approval'
      });
    }

    // Update user status
    await userRef.update({
      approval_status: 'approved',
      is_active: true,
      approved_by: adminId || null,
      approved_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    });

    // Log admin action
    await db.collection('admin_actions').add({
      admin_id: adminId || 'unknown',
      admin_name: adminName || 'Admin',
      action_type: 'approve_user',
      target_id: userId,
      target_type: 'user',
      details: {
        user_email: userData.email,
        user_name: userData.name,
        user_role: userData.role
      },
      created_at: admin.firestore.FieldValue.serverTimestamp()
    });

    // Log activity
    await db.collection('activity_logs').add({
      user_id: userId,
      action: 'user_approved',
      details: {
        approved_by: adminId || 'unknown',
        admin_name: adminName || 'Admin'
      },
      created_at: admin.firestore.FieldValue.serverTimestamp()
    });

    logger.info(`User ${userId} approved by admin ${adminId || 'unknown'}`);

    res.json({
      success: true,
      message: 'User approved successfully',
      user: {
        id: userId,
        approval_status: 'approved',
        is_active: true
      }
    });
  } catch (error) {
    logger.error('Error approving user:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to approve user',
      details: error.message
    });
  }
});

/**
 * POST /api/admin/users/:userId/reject
 * Reject a pending user (exporter)
 */
router.post('/users/:userId/reject', async (req, res) => {
  try {
    const { userId } = req.params;
    const { reason, adminId, adminName } = req.body;

    if (!reason) {
      return res.status(400).json({
        success: false,
        error: 'Rejection reason is required'
      });
    }

    // Get user document
    const userRef = db.collection('users').doc(userId);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    const userData = userDoc.data();

    // Check if user is an exporter
    if (userData.role !== 'exporter') {
      return res.status(400).json({
        success: false,
        error: 'Only exporter accounts require approval'
      });
    }

    // Update user status
    await userRef.update({
      approval_status: 'rejected',
      is_active: false,
      rejection_reason: reason,
      rejected_by: adminId || null,
      rejected_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    });

    // Log admin action
    await db.collection('admin_actions').add({
      admin_id: adminId || 'unknown',
      admin_name: adminName || 'Admin',
      action_type: 'reject_user',
      target_id: userId,
      target_type: 'user',
      details: {
        user_email: userData.email,
        user_name: userData.name,
        user_role: userData.role,
        reason: reason
      },
      created_at: admin.firestore.FieldValue.serverTimestamp()
    });

    // Log activity
    await db.collection('activity_logs').add({
      user_id: userId,
      action: 'user_rejected',
      details: {
        rejected_by: adminId || 'unknown',
        admin_name: adminName || 'Admin',
        reason: reason
      },
      created_at: admin.firestore.FieldValue.serverTimestamp()
    });

    logger.info(`User ${userId} rejected by admin ${adminId || 'unknown'}`);

    res.json({
      success: true,
      message: 'User rejected successfully',
      user: {
        id: userId,
        approval_status: 'rejected',
        is_active: false
      }
    });
  } catch (error) {
    logger.error('Error rejecting user:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to reject user',
      details: error.message
    });
  }
});

/**
 * GET /api/admin/exchange-rates/status
 * Get current exchange rate service status
 */
router.get('/exchange-rates/status', async (req, res) => {
  try {
    const exchangeRateService = require('../services/exchangeRateService');
    const status = exchangeRateService.getStatus();
    
    res.json({
      success: true,
      status
    });
  } catch (error) {
    logger.error('Error fetching exchange rate status:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch exchange rate status',
      details: error.message
    });
  }
});

/**
 * POST /api/admin/exchange-rates/update
 * Force immediate update of exchange rates
 */
router.post('/exchange-rates/update', async (req, res) => {
  try {
    const exchangeRateService = require('../services/exchangeRateService');
    
    logger.info('Admin triggered exchange rate update');
    
    const rates = await exchangeRateService.forceUpdate();
    
    res.json({
      success: true,
      message: 'Exchange rates updated successfully',
      rates: {
        ethToUsd: rates.ethToUsd,
        ethToLkr: rates.ethToLkr,
        usdToLkr: rates.usdToLkr,
        lastUpdate: exchangeRateService.getRates().lastUpdate
      }
    });
  } catch (error) {
    logger.error('Error updating exchange rates:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update exchange rates',
      details: error.message
    });
  }
});

/**
 * GET /api/admin/exchange-rates/history
 * Get exchange rate history from Firebase
 */
router.get('/exchange-rates/history', async (req, res) => {
  try {
    const { limit = 50 } = req.query;
    
    const snapshot = await db.collection('exchange_rates')
      .orderBy('updated_at', 'desc')
      .limit(parseInt(limit))
      .get();
    
    const history = snapshot.docs.map(doc => {
      const data = doc.data();
      return {
        id: doc.id,
        ...convertTimestamps(data)
      };
    });
    
    res.json({
      success: true,
      count: history.length,
      history
    });
  } catch (error) {
    logger.error('Error fetching exchange rate history:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch exchange rate history',
      details: error.message
    });
  }
});

/**
 * POST /api/admin/auctions/fix-settlement-status
 * Fix settlement_status for auctions where escrow is deposited but status wasn't updated
 */
router.post('/auctions/fix-settlement-status', async (req, res) => {
  try {
    logger.info('Fixing settlement status for auctions with deposited escrow...');

    // Find all auctions where escrow_deposited is true but settlement_status is still pending_escrow
    const snapshot = await db.collection('auctions')
      .where('escrow_deposited', '==', true)
      .where('settlement_status', '==', 'pending_escrow')
      .get();

    if (snapshot.empty) {
      return res.json({
        success: true,
        message: 'No auctions need fixing',
        fixed: 0
      });
    }

    const batch = db.batch();
    const auctionIds = [];

    snapshot.forEach(doc => {
      auctionIds.push(doc.id);
      batch.update(doc.ref, {
        settlement_status: 'escrow_received',
        updated_at: admin.firestore.FieldValue.serverTimestamp()
      });
    });

    await batch.commit();

    logger.info(`Fixed settlement status for ${auctionIds.length} auctions`, { auctionIds });

    res.json({
      success: true,
      message: `Fixed settlement status for ${auctionIds.length} auction(s)`,
      fixed: auctionIds.length,
      auctionIds
    });
  } catch (error) {
    logger.error('Error fixing settlement status:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fix settlement status',
      details: error.message
    });
  }
});

/**
 * POST /api/admin/auctions/mark-blockchain-finalized
 * Mark auctions as blockchain finalized when escrow is deposited but blockchain_auction_id was missing
 * This is for auctions created before blockchain integration was properly implemented
 */
router.post('/auctions/mark-blockchain-finalized', async (req, res) => {
  try {
    const { auctionId } = req.body;

    logger.info('Marking auction as blockchain finalized', { auctionId });

    if (!auctionId) {
      return res.status(400).json({
        success: false,
        error: 'auctionId is required'
      });
    }

    const auctionDoc = await db.collection('auctions').doc(String(auctionId)).get();

    if (!auctionDoc.exists) {
      return res.status(404).json({
        success: false,
        error: 'Auction not found'
      });
    }

    const auction = auctionDoc.data();

    // Check if escrow is deposited
    if (!auction.escrow_deposited) {
      return res.status(400).json({
        success: false,
        error: 'Escrow must be deposited before marking as blockchain finalized'
      });
    }

    // Update auction
    await auctionDoc.ref.update({
      blockchain_finalized: true,
      blockchain_finalization_tx: auction.escrow_tx_hash || null,
      blockchain_finalization_note: 'Manually marked as finalized - auction created before blockchain integration',
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    });

    logger.info(`Marked auction ${auctionId} as blockchain finalized`);

    res.json({
      success: true,
      message: 'Auction marked as blockchain finalized',
      auctionId,
      blockchainFinalized: true
    });
  } catch (error) {
    logger.error('Error marking auction as blockchain finalized:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to mark auction as blockchain finalized',
      details: error.message
    });
  }
});

/**
 * POST /api/admin/auctions/init-settlement-approval-field
 * Initialize admin_settlement_approved field for existing auctions
 * For auctions deposited before this field was added
 */
router.post('/auctions/init-settlement-approval-field', async (req, res) => {
  try {
    logger.info('Initializing settlement approval field for existing auctions');

    // Find auctions with escrow deposited but missing admin_settlement_approved field
    const snapshot = await db.collection('auctions')
      .where('escrow_deposited', '==', true)
      .where('status', '==', 'ended')
      .get();

    let updated = 0;
    let skipped = 0;
    const batch = db.batch();

    snapshot.docs.forEach(doc => {
      const auction = doc.data();
      
      // Only update if field is missing or undefined
      if (auction.admin_settlement_approved === undefined || auction.admin_settlement_approved === null) {
        batch.update(doc.ref, {
          admin_settlement_approved: false,
          updated_at: admin.firestore.FieldValue.serverTimestamp()
        });
        updated++;
      } else {
        skipped++;
      }
    });

    if (updated > 0) {
      await batch.commit();
    }

    logger.info(`Settlement approval field initialized: ${updated} updated, ${skipped} skipped`);

    res.json({
      success: true,
      message: 'Settlement approval field initialized',
      updated,
      skipped,
      total: snapshot.docs.length
    });
  } catch (error) {
    logger.error('Error initializing settlement approval field:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to initialize settlement approval field',
      details: error.message
    });
  }
});

/**
 * POST /api/admin/auctions/:id/approve-settlement
 * Admin approval for final settlement (after escrow deposited)
 * This marks the auction as ready for final payment release to farmer
 */
router.post('/auctions/:id/approve-settlement', async (req, res) => {
  try {
    const { id } = req.params;
    const { notes } = req.body;

    logger.info('Admin approving settlement for auction', { auctionId: id });

    const auctionDoc = await db.collection('auctions').doc(id).get();

    if (!auctionDoc.exists) {
      return res.status(404).json({
        success: false,
        error: 'Auction not found'
      });
    }

    const auction = auctionDoc.data();

    // Verify auction is ended
    if (auction.status !== 'ended') {
      return res.status(400).json({
        success: false,
        error: 'Auction must be ended before settlement approval',
        currentStatus: auction.status
      });
    }

    // Verify escrow is deposited
    if (!auction.escrow_deposited) {
      return res.status(400).json({
        success: false,
        error: 'Escrow must be deposited before settlement approval'
      });
    }

    // Check if already approved
    if (auction.admin_settlement_approved) {
      return res.status(400).json({
        success: false,
        error: 'Settlement already approved by admin',
        approvedAt: auction.admin_settlement_approved_at
      });
    }

    // Update auction with admin approval
    await auctionDoc.ref.update({
      admin_settlement_approved: true,
      admin_settlement_approved_at: admin.firestore.FieldValue.serverTimestamp(),
      admin_settlement_notes: notes || 'Approved for final settlement',
      settlement_status: 'approved_for_settlement',
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    });

    logger.info(`Admin approved settlement for auction ${id}`);

    // Create notification for farmer
    try {
      await db.collection('notifications').add({
        user_id: auction.farmer_address,
        user_address: auction.farmer_address,
        type: 'settlement_approved',
        title: 'Settlement Approved',
        message: `Admin has approved settlement for your auction. Payment will be processed shortly.`,
        auction_id: id,
        read: false,
        created_at: admin.firestore.FieldValue.serverTimestamp()
      });
    } catch (notifError) {
      logger.error('Failed to create notification:', notifError);
    }

    // Create notification for buyer
    try {
      const winnerAddress = auction.winner_address || auction.current_bidder;
      if (winnerAddress) {
        await db.collection('notifications').add({
          user_id: winnerAddress,
          user_address: winnerAddress,
          type: 'settlement_approved',
          title: 'Settlement Approved',
          message: `Admin has approved settlement for auction. Shipment will be arranged soon.`,
          auction_id: id,
          read: false,
          created_at: admin.firestore.FieldValue.serverTimestamp()
        });
      }
    } catch (notifError) {
      logger.error('Failed to create notification for buyer:', notifError);
    }

    res.json({
      success: true,
      message: 'Settlement approved successfully',
      auctionId: id,
      approvedAt: new Date().toISOString()
    });

  } catch (error) {
    logger.error('Error approving settlement:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to approve settlement',
      details: error.message
    });
  }
});

/**
 * GET /api/admin/auctions/pending-settlement
 * Get auctions with escrow deposited pending admin approval
 */
router.get('/auctions/pending-settlement', async (req, res) => {
  try {
    logger.info('Fetching auctions pending settlement approval');

    const snapshot = await db.collection('auctions')
      .where('escrow_deposited', '==', true)
      .where('admin_settlement_approved', '==', false)
      .where('status', '==', 'ended')
      .orderBy('end_time', 'desc')
      .limit(50)
      .get();

    const auctions = [];
    for (const doc of snapshot.docs) {
      const auction = doc.data();
      
      // Get lot details
      let lotDetails = null;
      if (auction.lot_id) {
        const lotSnapshot = await db.collection('pepper_lots')
          .where('lot_id', '==', auction.lot_id)
          .limit(1)
          .get();
        
        if (!lotSnapshot.empty) {
          const lot = lotSnapshot.docs[0].data();
          lotDetails = {
            variety: lot.variety,
            quantity: lot.quantity,
            quality: lot.quality
          };
        }
      }

      auctions.push({
        auctionId: doc.id,
        lotId: auction.lot_id,
        farmerAddress: auction.farmer_address,
        winnerAddress: auction.winner_address || auction.current_bidder,
        finalPrice: auction.current_bid,
        finalPriceLkr: auction.current_bid_lkr,
        escrowDeposited: auction.escrow_deposited,
        escrowDepositDate: auction.escrow_deposit_date,
        endTime: auction.end_time,
        settlementStatus: auction.settlement_status,
        lotDetails
      });
    }

    logger.info(`Found ${auctions.length} auctions pending settlement approval`);

    res.json({
      success: true,
      auctions,
      total: auctions.length
    });

  } catch (error) {
    logger.error('Error fetching pending settlements:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch pending settlements',
      details: error.message
    });
  }
});

module.exports = router;


