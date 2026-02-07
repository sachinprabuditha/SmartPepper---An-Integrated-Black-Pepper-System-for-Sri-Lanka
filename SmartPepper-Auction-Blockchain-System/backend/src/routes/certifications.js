const express = require('express');
const router = express.Router();
const admin = require('firebase-admin');
const logger = require('../utils/logger');

const db = admin.firestore();

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

    const certificationData = {
      lot_id: lotId,
      cert_type: certType,
      cert_number: certNumber,
      issuer,
      issue_date: admin.firestore.Timestamp.fromDate(new Date(issueDate)),
      expiry_date: admin.firestore.Timestamp.fromDate(new Date(expiryDate)),
      document_hash: documentHash || null,
      ipfs_url: ipfsUrl || null,
      is_valid: isValid,
      verification_status: 'pending',
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    };

    const docRef = await db.collection('certifications').add(certificationData);

    logger.info('Certification added:', { lotId, certType, certNumber });

    const doc = await docRef.get();
    res.status(201).json({
      success: true,
      certification: { id: doc.id, ...doc.data() }
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

    const snapshot = await db.collection('certifications')
      .where('lot_id', '==', lotId)
      .orderBy('created_at', 'desc')
      .get();

    const certifications = [];
    snapshot.forEach(doc => {
      certifications.push({ id: doc.id, ...doc.data() });
    });

    res.json({
      success: true,
      certifications
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

    const docRef = db.collection('certifications').doc(id);
    const doc = await docRef.get();

    if (!doc.exists) {
      return res.status(404).json({
        success: false,
        error: 'Certification not found'
      });
    }

    await docRef.update({
      verification_status: status,
      verified_by: verifiedBy,
      verified_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    });

    const updatedDoc = await docRef.get();
    res.json({
      success: true,
      certification: { id: updatedDoc.id, ...updatedDoc.data() }
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
