const express = require('express');
const router = express.Router();
const db = require('../db/database');
const ComplianceService = require('../services/complianceService');
const logger = require('../utils/logger');

const complianceService = new ComplianceService();
complianceService.initialize().catch(err => logger.error('Compliance init failed:', err));

/**
 * POST /api/compliance/check
 * Run compliance check for a lot
 */
router.post('/check', async (req, res) => {
  try {
    const { lotId } = req.body;

    if (!lotId) {
      return res.status(400).json({
        success: false,
        error: 'lotId is required'
      });
    }

    // Get lot data
    const lotResult = await db.query(
      'SELECT * FROM pepper_lots WHERE lot_id = $1',
      [lotId]
    );

    if (lotResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Lot not found'
      });
    }

    const lot = lotResult.rows[0];

    // Run compliance check
    const complianceResult = await complianceService.checkCompliance({
      lotId: lot.lot_id,
      certificateHash: lot.certificate_hash,
      certificateIpfsUrl: lot.certificate_ipfs_url,
      variety: lot.variety,
      quantity: lot.quantity,
      quality: lot.quality
    });

    // Store results
    for (const result of complianceResult.results) {
      await db.query(
        `INSERT INTO compliance_checks (
          lot_id, rule_name, rule_type, passed, details
        ) VALUES ($1, $2, $3, $4, $5)`,
        [
          lotId,
          result.ruleName,
          result.ruleType,
          result.passed,
          JSON.stringify(result.details)
        ]
      );
    }

    res.json({
      success: true,
      compliance: complianceResult
    });
  } catch (error) {
    logger.error('Error running compliance check:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to run compliance check',
      details: error.message
    });
  }
});

/**
 * GET /api/compliance/:lotId
 * Get compliance history for a lot
 */
router.get('/:lotId', async (req, res) => {
  try {
    const { lotId } = req.params;
    
    const result = await db.query(
      `SELECT * FROM compliance_checks 
       WHERE lot_id = $1 
       ORDER BY checked_at DESC`,
      [lotId]
    );

    res.json({
      success: true,
      checks: result.rows
    });
  } catch (error) {
    logger.error('Error fetching compliance history:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch compliance history'
    });
  }
});

/**
 * POST /api/compliance/upload
 * Upload certificate to IPFS
 */
router.post('/upload', async (req, res) => {
  try {
    const { file, fileName } = req.body;

    if (!file) {
      return res.status(400).json({
        success: false,
        error: 'file is required'
      });
    }

    // Convert base64 to buffer if needed
    const fileBuffer = Buffer.isBuffer(file) ? file : Buffer.from(file, 'base64');

    const ipfsResult = await complianceService.uploadToIPFS(fileBuffer);

    res.json({
      success: true,
      ipfs: ipfsResult
    });
  } catch (error) {
    logger.error('Error uploading to IPFS:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to upload to IPFS',
      details: error.message
    });
  }
});

module.exports = router;
