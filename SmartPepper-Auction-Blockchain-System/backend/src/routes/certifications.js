const express = require('express');
const router = express.Router();
const db = require('../db/database');
const logger = require('../utils/logger');

/**
 * POST /api/certifications
 * Add a certification to a lot
 */
router.post('/', async (req, res) => {
  try {
    const {
      lotId,
      certType,
      certNumber,
      issuer,
      issueDate,
      expiryDate,
      documentHash,
      ipfsUrl
    } = req.body;

    if (!lotId || !certType || !certNumber || !issuer || !issueDate || !expiryDate) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields'
      });
    }

    // Check if certificate is expired
    const expiry = new Date(expiryDate);
    const isValid = expiry > new Date();

    const result = await db.query(
      `INSERT INTO certifications (
        lot_id, cert_type, cert_number, issuer, issue_date, expiry_date,
        document_hash, ipfs_url, is_valid, verification_status
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
      RETURNING *`,
      [lotId, certType, certNumber, issuer, issueDate, expiryDate, documentHash, ipfsUrl, isValid, 'pending']
    );

    logger.info('Certification added:', { lotId, certType, certNumber });

    res.status(201).json({
      success: true,
      certification: result.rows[0]
    });
  } catch (error) {
    logger.error('Error adding certification:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to add certification',
      details: error.message
    });
  }
});

/**
 * GET /api/certifications/:lotId
 * Get all certifications for a lot
 */
router.get('/:lotId', async (req, res) => {
  try {
    const { lotId } = req.params;

    const result = await db.query(
      `SELECT * FROM certifications 
       WHERE lot_id = $1 
       ORDER BY created_at DESC`,
      [lotId]
    );

    res.json({
      success: true,
      certifications: result.rows
    });
  } catch (error) {
    logger.error('Error fetching certifications:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch certifications'
    });
  }
});

/**
 * PUT /api/certifications/:id/verify
 * Verify a certification
 */
router.put('/:id/verify', async (req, res) => {
  try {
    const { id } = req.params;
    const { verifiedBy, status } = req.body;

    const result = await db.query(
      `UPDATE certifications 
       SET verification_status = $1, verified_by = $2, verified_at = NOW()
       WHERE id = $3
       RETURNING *`,
      [status, verifiedBy, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Certification not found'
      });
    }

    res.json({
      success: true,
      certification: result.rows[0]
    });
  } catch (error) {
    logger.error('Error verifying certification:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to verify certification'
    });
  }
});

module.exports = router;
