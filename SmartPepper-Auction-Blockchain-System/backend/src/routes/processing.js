const express = require('express');
const router = express.Router();
const db = require('../db/database');
const logger = require('../utils/logger');

/**
 * POST /api/processing/stages
 * Add a processing stage to a lot
 */
router.post('/stages', async (req, res) => {
  try {
    const {
      lotId,
      stageType,
      stageName,
      location,
      operatorName,
      qualityMetrics,
      notes,
      blockchainTxHash
    } = req.body;

    if (!lotId || !stageType || !stageName) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: lotId, stageType, stageName'
      });
    }

    const result = await db.query(
      `INSERT INTO processing_stages (
        lot_id, stage_type, stage_name, location, operator_name,
        quality_metrics, notes, blockchain_tx_hash
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING *`,
      [lotId, stageType, stageName, location, operatorName, qualityMetrics, notes, blockchainTxHash]
    );

    logger.info('Processing stage added:', { lotId, stageType });

    res.status(201).json({
      success: true,
      stage: result.rows[0]
    });
  } catch (error) {
    logger.error('Error adding processing stage:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to add processing stage',
      details: error.message
    });
  }
});

/**
 * GET /api/processing/stages/:lotId
 * Get all processing stages for a lot
 */
router.get('/stages/:lotId', async (req, res) => {
  try {
    const { lotId } = req.params;

    const result = await db.query(
      `SELECT * FROM processing_stages 
       WHERE lot_id = $1 
       ORDER BY timestamp ASC`,
      [lotId]
    );

    res.json({
      success: true,
      stages: result.rows
    });
  } catch (error) {
    logger.error('Error fetching processing stages:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch processing stages'
    });
  }
});

module.exports = router;
