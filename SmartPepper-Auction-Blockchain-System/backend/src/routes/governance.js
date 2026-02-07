const express = require('express');
const router = express.Router();
const admin = require('firebase-admin');
const logger = require('../utils/logger');

const db = admin.firestore();

// GET /api/governance/settings - Fetch governance settings
router.get('/settings', async (req, res) => {
  try {
    logger.info('Fetching governance settings');

    const snapshot = await db.collection('governance_settings').limit(1).get();

    if (snapshot.empty) {
      return res.status(404).json({ error: 'Governance settings not found' });
    }

    const doc = snapshot.docs[0];
    const settings = doc.data();

    res.json({
      defaultMinDuration: settings.default_min_duration_hours,
      defaultMaxDuration: settings.default_max_duration_hours,
      defaultBidIncrement: parseFloat(settings.default_bid_increment),
      allowedDurations: settings.allowed_durations,
      minReservePrice: parseFloat(settings.min_reserve_price),
      maxReservePrice: parseFloat(settings.max_reserve_price),
      requiresAdminApproval: settings.requires_admin_approval,
      // Add exchange rates (use defaults if not set)
      lkrToEthRate: parseFloat(settings.lkr_to_eth_rate || 0.0000031),
      usdToEthRate: parseFloat(settings.usd_to_eth_rate || 0.00032),
      updatedAt: settings.updated_at,
    });
  } catch (error) {
    logger.error('Error fetching governance settings:', error);
    res.status(500).json({ error: 'Failed to fetch governance settings' });
  }
});

// PUT /api/governance/settings - Update governance settings
router.put('/settings', async (req, res) => {
  try {
    const {
      defaultMinDuration,
      defaultMaxDuration,
      defaultBidIncrement,
      allowedDurations,
      minReservePrice,
      maxReservePrice,
      requiresAdminApproval,
      updatedBy,
    } = req.body;

    logger.info('Updating governance settings');

    // Get first document or create new one
    const snapshot = await db.collection('governance_settings').limit(1).get();
    
    const settingsData = {
      default_min_duration_hours: defaultMinDuration,
      default_max_duration_hours: defaultMaxDuration,
      default_bid_increment: defaultBidIncrement,
      allowed_durations: allowedDurations,
      min_reserve_price: minReservePrice,
      max_reserve_price: maxReservePrice,
      requires_admin_approval: requiresAdminApproval,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_by: updatedBy || 'admin'
    };

    let docRef;
    if (snapshot.empty) {
      docRef = await db.collection('governance_settings').add(settingsData);
    } else {
      docRef = snapshot.docs[0].ref;
      await docRef.update(settingsData);
    }

    // Log governance action
    await db.collection('governance_logs').add({
      action: 'Settings Updated',
      performed_by: updatedBy || 'admin',
      details: 'Updated global governance settings',
      created_at: admin.firestore.FieldValue.serverTimestamp()
    });

    const updatedDoc = await docRef.get();
    res.json({
      message: 'Governance settings updated successfully',
      settings: { id: updatedDoc.id, ...updatedDoc.data() },
    });
  } catch (error) {
    logger.error('Error updating governance settings:', error);
    res.status(500).json({ error: 'Failed to update governance settings' });
  }
});

// GET /api/governance/templates - Get all auction templates
router.get('/templates', async (req, res) => {
  try {
    logger.info('Fetching auction templates');

    const snapshot = await db.collection('auction_rule_templates')
      .where('active', '==', true)
      .orderBy('created_at', 'desc')
      .get();

    const templates = [];
    snapshot.forEach(doc => {
      const row = doc.data();
      templates.push({
        id: doc.id,
        name: row.name,
        description: row.description,
        minDuration: row.min_duration_hours,
        maxDuration: row.max_duration_hours,
        minBidIncrement: parseFloat(row.min_bid_increment),
        maxReservePrice: parseFloat(row.max_reserve_price),
        requiresApproval: row.requires_approval,
        active: row.active,
        createdAt: row.created_at,
      });
    });

    res.json({ templates });
  } catch (error) {
    logger.error('Error fetching auction templates:', error);
    res.status(500).json({ error: 'Failed to fetch auction templates' });
  }
});

// POST /api/governance/templates - Create new template
router.post('/templates', async (req, res) => {
  try {
    const {
      name,
      description,
      minDuration,
      maxDuration,
      minBidIncrement,
      maxReservePrice,
      requiresApproval,
      createdBy,
    } = req.body;

    logger.info('Creating auction template:', name);

    // Generate template_id from name
    const templateId = name.toLowerCase().replace(/\s+/g, '-');

    const templateData = {
      template_id: templateId,
      name,
      description,
      min_duration_hours: minDuration,
      max_duration_hours: maxDuration,
      min_bid_increment: minBidIncrement,
      max_reserve_price: maxReservePrice,
      requires_approval: requiresApproval,
      active: true,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    };

    const docRef = await db.collection('auction_rule_templates').add(templateData);

    // Log governance action
    await db.collection('governance_logs').add({
      action: 'Template Created',
      performed_by: createdBy || 'admin',
      details: `Created template: ${name}`,
      created_at: admin.firestore.FieldValue.serverTimestamp()
    });

    const doc = await docRef.get();
    res.json({
      message: 'Template created successfully',
      template: { id: doc.id, ...doc.data() },
    });
  } catch (error) {
    logger.error('Error creating template:', error);
    res.status(500).json({ error: 'Failed to create template' });
  }
});

// PUT /api/governance/templates/:id - Update template
router.put('/templates/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const {
      name,
      description,
      minDuration,
      maxDuration,
      minBidIncrement,
      maxReservePrice,
      requiresApproval,
      updatedBy,
    } = req.body;

    logger.info('Updating auction template:', id);

    const docRef = db.collection('auction_rule_templates').doc(id);
    const doc = await docRef.get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Template not found' });
    }

    await docRef.update({
      name,
      description,
      min_duration_hours: minDuration,
      max_duration_hours: maxDuration,
      min_bid_increment: minBidIncrement,
      max_reserve_price: maxReservePrice,
      requires_approval: requiresApproval,
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    });

    // Log governance action
    await db.collection('governance_logs').add({
      action: 'Template Updated',
      performed_by: updatedBy || 'admin',
      details: `Updated template: ${name}`,
      created_at: admin.firestore.FieldValue.serverTimestamp()
    });

    const updatedDoc = await docRef.get();
    res.json({
      message: 'Template updated successfully',
      template: { id: updatedDoc.id, ...updatedDoc.data() },
    });
  } catch (error) {
    logger.error('Error updating template:', error);
    res.status(500).json({ error: 'Failed to update template' });
  }
});

// DELETE /api/governance/templates/:id - Delete (deactivate) template
router.delete('/templates/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { deletedBy } = req.body;

    logger.info('Deleting auction template:', id);

    const docRef = db.collection('auction_rule_templates').doc(id);
    const doc = await docRef.get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Template not found' });
    }

    await docRef.update({
      active: false,
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    });

    // Log governance action
    await db.collection('governance_logs').add({
      action: 'Template Deleted',
      performed_by: deletedBy || 'admin',
      details: `Deleted template: ${doc.data().name}`,
      created_at: admin.firestore.FieldValue.serverTimestamp()
    });

    res.json({ message: 'Template deleted successfully' });
  } catch (error) {
    logger.error('Error deleting template:', error);
    res.status(500).json({ error: 'Failed to delete template' });
  }
});

// GET /api/governance/cancellations - Get all cancellation requests
router.get('/cancellations', async (req, res) => {
  try {
    const { status } = req.query;

    logger.info('Fetching cancellation requests');

    let query = db.collection('cancellation_requests');

    if (status) {
      query = query.where('status', '==', status);
    }

    const snapshot = await query.orderBy('created_at', 'desc').get();

    const requests = [];
    snapshot.forEach(doc => {
      const row = doc.data();
      requests.push({
        id: doc.id,
        auctionId: row.auction_id,
        lotId: row.lot_id,
        requestedBy: row.requested_by,
        reason: row.reason,
        status: row.status,
        createdAt: row.created_at,
        reviewedAt: row.reviewed_at,
        reviewedBy: row.reviewed_by,
        adminComments: row.admin_comments,
      });
    });

    res.json({ requests });
  } catch (error) {
    logger.error('Error fetching cancellation requests:', error);
    res.status(500).json({ error: 'Failed to fetch cancellation requests' });
  }
});

// POST /api/governance/cancellations/:id/approve - Approve cancellation
router.post('/cancellations/:id/approve', async (req, res) => {
  try {
    const { id } = req.params;
    const { reviewedBy, comments } = req.body;

    logger.info('Approving cancellation request:', id);

    // Get request details
    const requestRef = db.collection('cancellation_requests').doc(id);
    const requestDoc = await requestRef.get();

    if (!requestDoc.exists) {
      return res.status(404).json({ error: 'Cancellation request not found' });
    }

    const request = requestDoc.data();

    // Update request status
    await requestRef.update({
      status: 'approved',
      reviewed_at: admin.firestore.FieldValue.serverTimestamp(),
      reviewed_by: reviewedBy,
      admin_comments: comments
    });

    // Update auction status to ended
    const auctionRef = db.collection('auctions').doc(request.auction_id);
    await auctionRef.update({
      status: 'ended',
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    });

    // Log governance action
    await db.collection('governance_logs').add({
      action: 'Cancellation Approved',
      performed_by: reviewedBy || 'admin',
      details: `Approved cancellation for auction: ${request.auction_id}`,
      created_at: admin.firestore.FieldValue.serverTimestamp()
    });

    res.json({ message: 'Cancellation request approved successfully' });
  } catch (error) {
    logger.error('Error approving cancellation:', error);
    res.status(500).json({ error: 'Failed to approve cancellation' });
  }
});

// POST /api/governance/cancellations/:id/reject - Reject cancellation
router.post('/cancellations/:id/reject', async (req, res) => {
  try {
    const { id } = req.params;
    const { reviewedBy, comments } = req.body;

    logger.info('Rejecting cancellation request:', id);

    // Get request details
    const requestRef = db.collection('cancellation_requests').doc(id);
    const requestDoc = await requestRef.get();

    if (!requestDoc.exists) {
      return res.status(404).json({ error: 'Cancellation request not found' });
    }

    const request = requestDoc.data();

    // Update request status
    await requestRef.update({
      status: 'rejected',
      reviewed_at: admin.firestore.FieldValue.serverTimestamp(),
      reviewed_by: reviewedBy,
      admin_comments: comments
    });

    // Log governance action
    await db.collection('governance_logs').add({
      action: 'Cancellation Rejected',
      performed_by: reviewedBy || 'admin',
      details: `Rejected cancellation for auction: ${request.auction_id}`,
      created_at: admin.firestore.FieldValue.serverTimestamp()
    });

    res.json({ message: 'Cancellation request rejected successfully' });
  } catch (error) {
    logger.error('Error rejecting cancellation:', error);
    res.status(500).json({ error: 'Failed to reject cancellation' });
  }
});

// GET /api/governance/logs - Get governance audit logs
router.get('/logs', async (req, res) => {
  try {
    const { limit = 50 } = req.query;

    logger.info('Fetching governance logs');

    const snapshot = await db.collection('governance_logs')
      .orderBy('created_at', 'desc')
      .limit(parseInt(limit))
      .get();

    const logs = [];
    snapshot.forEach(doc => {
      const row = doc.data();
      logs.push({
        id: doc.id,
        action: row.action,
        performedBy: row.performed_by,
        details: row.details,
        blockchainTxHash: row.blockchain_tx_hash,
        createdAt: row.created_at,
      });
    });

    res.json({ logs });
  } catch (error) {
    logger.error('Error fetching governance logs:', error);
    res.status(500).json({ error: 'Failed to fetch governance logs' });
  }
});

module.exports = router;
