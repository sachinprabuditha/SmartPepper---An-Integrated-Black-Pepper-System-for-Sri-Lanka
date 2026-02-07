const express = require('express');
const router = express.Router();
const admin = require('firebase-admin');
const logger = require('../utils/logger');

const db = admin.firestore();

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

    const stageData = {
      lot_id: lotId,
      stage_type: stageType,
      stage_name: stageName,
      location: location || null,
      operator_name: operatorName || null,
      quality_metrics: qualityMetrics || null,
      notes: notes || null,
      blockchain_tx_hash: blockchainTxHash || null,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      created_at: admin.firestore.FieldValue.serverTimestamp()
    };

    const docRef = await db.collection('processing_stages').add(stageData);

    logger.info('Processing stage added:', { lotId, stageType });

    const doc = await docRef.get();
    res.status(201).json({
      success: true,
      stage: { id: doc.id, ...doc.data() }
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

    const snapshot = await db.collection('processing_stages')
      .where('lot_id', '==', lotId)
      .orderBy('timestamp', 'asc')
      .get();

    const stages = [];
    snapshot.forEach(doc => {
      stages.push({ id: doc.id, ...doc.data() });
    });

    res.json({
      success: true,
      stages
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
