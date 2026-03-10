const express = require('express');
const router = express.Router();
const { getDb } = require('./firebase');
const API_CONFIG = require('./api-config');

/**
 * GET /api/disease-locations
 * Retrieve all disease locations
 */
router.get('/', async (req, res) => {
    try {
        const db = getDb();
        
        if (!db) {
            return res.status(API_CONFIG.STATUS_CODES.SERVICE_UNAVAILABLE).json({
                status: API_CONFIG.MESSAGES.ERROR,
                message: API_CONFIG.MESSAGES.FIREBASE_NOT_CONFIGURED
            });
        }

        const snapshot = await db.collection(API_CONFIG.FIREBASE.COLLECTIONS.DISEASE_LOCATIONS)
            .orderBy('detectedDate', 'desc')
            .get();
        
        const locations = snapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
        }));
        
        return res.json({
            status: API_CONFIG.MESSAGES.SUCCESS,
            count: locations.length,
            data: locations
        });
    } catch (error) {
        console.error('Error retrieving disease locations:', error);
        return res.status(API_CONFIG.STATUS_CODES.INTERNAL_SERVER_ERROR).json({
            status: API_CONFIG.MESSAGES.ERROR,
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
            return res.status(API_CONFIG.STATUS_CODES.BAD_REQUEST).json({
                status: API_CONFIG.MESSAGES.ERROR,
                message: API_CONFIG.MESSAGES.MISSING_REQUIRED_FIELDS
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
            return res.status(API_CONFIG.STATUS_CODES.SERVICE_UNAVAILABLE).json({
                status: API_CONFIG.MESSAGES.ERROR,
                message: API_CONFIG.MESSAGES.FIREBASE_NOT_CONFIGURED
            });
        }

        const docRef = await db.collection(API_CONFIG.FIREBASE.COLLECTIONS.DISEASE_LOCATIONS).add(locationData);
        const savedDoc = await docRef.get();
        
        return res.status(API_CONFIG.STATUS_CODES.CREATED).json({
            status: API_CONFIG.MESSAGES.SUCCESS,
            message: API_CONFIG.MESSAGES.LOCATION_SAVED,
            data: {
                id: savedDoc.id,
                ...savedDoc.data()
            }
        });
    } catch (error) {
        console.error('Error saving disease location:', error);
        return res.status(API_CONFIG.STATUS_CODES.INTERNAL_SERVER_ERROR).json({
            status: API_CONFIG.MESSAGES.ERROR,
            message: error.message
        });
    }
});

module.exports = router;
