const express = require('express');
const router = express.Router();
const db = require('../db/database');
const logger = require('../utils/logger');

// GET /api/governance/settings - Fetch governance settings
router.get('/settings', async (req, res) => {
  try {
    logger.info('Fetching governance settings');

    const result = await db.query('SELECT * FROM governance_settings LIMIT 1');

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Governance settings not found' });
    }

    const settings = result.rows[0];

    res.json({
      defaultMinDuration: settings.default_min_duration_hours,
      defaultMaxDuration: settings.default_max_duration_hours,
      defaultBidIncrement: parseFloat(settings.default_bid_increment),
      allowedDurations: settings.allowed_durations,
      minReservePrice: parseFloat(settings.min_reserve_price),
      maxReservePrice: parseFloat(settings.max_reserve_price),
      requiresAdminApproval: settings.requires_admin_approval,
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

    const result = await db.query(
      `UPDATE governance_settings 
       SET default_min_duration_hours = $1,
           default_max_duration_hours = $2,
           default_bid_increment = $3,
           allowed_durations = $4,
           min_reserve_price = $5,
           max_reserve_price = $6,
           requires_admin_approval = $7,
           updated_at = NOW(),
           updated_by = $8
       RETURNING *`,
      [
        defaultMinDuration,
        defaultMaxDuration,
        defaultBidIncrement,
        allowedDurations,
        minReservePrice,
        maxReservePrice,
        requiresAdminApproval,
        updatedBy || 'admin',
      ]
    );

    // Log governance action
    await db.query(
      `INSERT INTO governance_logs (action, performed_by, details)
       VALUES ($1, $2, $3)`,
      ['Settings Updated', updatedBy || 'admin', 'Updated global governance settings']
    );

    res.json({
      message: 'Governance settings updated successfully',
      settings: result.rows[0],
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

    const result = await db.query(
      `SELECT * FROM auction_rule_templates 
       WHERE active = true 
       ORDER BY created_at DESC`
    );

    const templates = result.rows.map((row) => ({
      id: row.template_id,
      name: row.name,
      description: row.description,
      minDuration: row.min_duration_hours,
      maxDuration: row.max_duration_hours,
      minBidIncrement: parseFloat(row.min_bid_increment),
      maxReservePrice: parseFloat(row.max_reserve_price),
      requiresApproval: row.requires_approval,
      active: row.active,
      createdAt: row.created_at,
    }));

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

    const result = await db.query(
      `INSERT INTO auction_rule_templates 
       (template_id, name, description, min_duration_hours, max_duration_hours, 
        min_bid_increment, max_reserve_price, requires_approval)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [
        templateId,
        name,
        description,
        minDuration,
        maxDuration,
        minBidIncrement,
        maxReservePrice,
        requiresApproval,
      ]
    );

    // Log governance action
    await db.query(
      `INSERT INTO governance_logs (action, performed_by, details)
       VALUES ($1, $2, $3)`,
      ['Template Created', createdBy || 'admin', `Created template: ${name}`]
    );

    res.json({
      message: 'Template created successfully',
      template: result.rows[0],
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

    const result = await db.query(
      `UPDATE auction_rule_templates 
       SET name = $1, description = $2, min_duration_hours = $3,
           max_duration_hours = $4, min_bid_increment = $5,
           max_reserve_price = $6, requires_approval = $7, updated_at = NOW()
       WHERE template_id = $8
       RETURNING *`,
      [
        name,
        description,
        minDuration,
        maxDuration,
        minBidIncrement,
        maxReservePrice,
        requiresApproval,
        id,
      ]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Template not found' });
    }

    // Log governance action
    await db.query(
      `INSERT INTO governance_logs (action, performed_by, details)
       VALUES ($1, $2, $3)`,
      ['Template Updated', updatedBy || 'admin', `Updated template: ${name}`]
    );

    res.json({
      message: 'Template updated successfully',
      template: result.rows[0],
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

    const result = await db.query(
      `UPDATE auction_rule_templates 
       SET active = false, updated_at = NOW()
       WHERE template_id = $1
       RETURNING *`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Template not found' });
    }

    // Log governance action
    await db.query(
      `INSERT INTO governance_logs (action, performed_by, details)
       VALUES ($1, $2, $3)`,
      ['Template Deleted', deletedBy || 'admin', `Deleted template: ${result.rows[0].name}`]
    );

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

    let query = 'SELECT * FROM cancellation_requests ORDER BY created_at DESC';
    const params = [];

    if (status) {
      query = 'SELECT * FROM cancellation_requests WHERE status = $1 ORDER BY created_at DESC';
      params.push(status);
    }

    const result = await db.query(query, params);

    const requests = result.rows.map((row) => ({
      id: row.id,
      auctionId: row.auction_id,
      lotId: row.lot_id,
      requestedBy: row.requested_by,
      reason: row.reason,
      status: row.status,
      createdAt: row.created_at,
      reviewedAt: row.reviewed_at,
      reviewedBy: row.reviewed_by,
      adminComments: row.admin_comments,
    }));

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
    const requestResult = await db.query(
      'SELECT * FROM cancellation_requests WHERE id = $1',
      [id]
    );

    if (requestResult.rows.length === 0) {
      return res.status(404).json({ error: 'Cancellation request not found' });
    }

    const request = requestResult.rows[0];

    // Update request status
    await db.query(
      `UPDATE cancellation_requests 
       SET status = 'approved', reviewed_at = NOW(), 
           reviewed_by = $1, admin_comments = $2
       WHERE id = $3`,
      [reviewedBy, comments, id]
    );

    // Update auction status to ended
    await db.query(
      'UPDATE auctions SET status = $1 WHERE auction_id = $2',
      ['ended', request.auction_id]
    );

    // Log governance action
    await db.query(
      `INSERT INTO governance_logs (action, performed_by, details)
       VALUES ($1, $2, $3)`,
      [
        'Cancellation Approved',
        reviewedBy || 'admin',
        `Approved cancellation for auction: ${request.auction_id}`,
      ]
    );

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
    const requestResult = await db.query(
      'SELECT * FROM cancellation_requests WHERE id = $1',
      [id]
    );

    if (requestResult.rows.length === 0) {
      return res.status(404).json({ error: 'Cancellation request not found' });
    }

    const request = requestResult.rows[0];

    // Update request status
    await db.query(
      `UPDATE cancellation_requests 
       SET status = 'rejected', reviewed_at = NOW(), 
           reviewed_by = $1, admin_comments = $2
       WHERE id = $3`,
      [reviewedBy, comments, id]
    );

    // Log governance action
    await db.query(
      `INSERT INTO governance_logs (action, performed_by, details)
       VALUES ($1, $2, $3)`,
      [
        'Cancellation Rejected',
        reviewedBy || 'admin',
        `Rejected cancellation for auction: ${request.auction_id}`,
      ]
    );

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

    const result = await db.query(
      `SELECT * FROM governance_logs 
       ORDER BY created_at DESC 
       LIMIT $1`,
      [limit]
    );

    const logs = result.rows.map((row) => ({
      id: row.id,
      action: row.action,
      performedBy: row.performed_by,
      details: row.details,
      blockchainTxHash: row.blockchain_tx_hash,
      createdAt: row.created_at,
    }));

    res.json({ logs });
  } catch (error) {
    logger.error('Error fetching governance logs:', error);
    res.status(500).json({ error: 'Failed to fetch governance logs' });
  }
});

module.exports = router;
