const express = require('express');
const router = express.Router();
const { getDb } = require('./firebase');

/**
 * GET /api/disease-locations
 * Retrieve all disease locations
 */
router.get('/', async (req, res) => {
    try {
        const db = getDb();
        
        if (!db) {
            return res.status(503).json({
                status: 'error',
                message: 'Firebase not configured. Disease location storage requires Firebase.'
            });
        }

        const snapshot = await db.collection('disease_locations')
            .orderBy('detectedDate', 'desc')
            .get();
        
        const locations = snapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
        }));
        
        return res.json({
            status: 'success',
            count: locations.length,
            data: locations
        });
    } catch (error) {
        console.error('Error retrieving disease locations:', error);
        return res.status(500).json({
            status: 'error',
            message: error.message
        });
    }
});

/**
 * POST /api/disease-locations
 * Save a new disease location
 */
router.post('/', async (req, res) => {
    try {
        const {
            latitude,
            longitude,
            diseaseName,
            severity,
            detectedDate,
            totalLeaves,
            diseaseCounts,
            imagePath
        } = req.body;

        // Validate required fields
        if (!latitude || !longitude || !diseaseName || severity === undefined) {
            return res.status(400).json({
                status: 'error',
                message: 'Missing required fields: latitude, longitude, diseaseName, severity'
            });
        }

        const locationData = {
            latitude: parseFloat(latitude),
            longitude: parseFloat(longitude),
            diseaseName,
            severity: parseFloat(severity),
            detectedDate: detectedDate || new Date().toISOString(),
            totalLeaves: totalLeaves || 0,
            diseaseCounts: diseaseCounts || {},
            imagePath: imagePath || null,
            createdAt: new Date().toISOString()
        };

        const db = getDb();
        
        if (!db) {
            return res.status(503).json({
                status: 'error',
                message: 'Firebase not configured. Disease location storage requires Firebase.'
            });
        }

        const docRef = await db.collection('disease_locations').add(locationData);
        const savedDoc = await docRef.get();
        
        return res.status(201).json({
            status: 'success',
            message: 'Disease location saved successfully',
            data: {
                id: savedDoc.id,
                ...savedDoc.data()
            }
        });
    } catch (error) {
        console.error('Error saving disease location:', error);
        return res.status(500).json({
            status: 'error',
            message: error.message
        });
    }
});

module.exports = router;
