const express = require('express');
const router = express.Router();
const db = require('../db/firebase');
const logger = require('../utils/logger');

/**
 * @route GET /api/pepper-varieties
 * @desc Get all pepper varieties from Firebase
 * @access Public (No authentication required for basic data)
 */
router.get('/', async (req, res) => {
    try {
        logger.info('Fetching pepper varieties from Firebase');

        const firestore = db.getDb();
        const varietiesSnapshot = await firestore.collection('pepperVarieties').get();

        if (varietiesSnapshot.empty) {
            return res.status(200).json({
                success: true,
                count: 0,
                data: []
            });
        }

        const varieties = [];
        varietiesSnapshot.forEach(doc => {
            varieties.push({
                id: doc.id,
                ...doc.data()
            });
        });

        logger.info(`Successfully fetched ${varieties.length} pepper varieties`);

        return res.status(200).json({
            success: true,
            count: varieties.length,
            data: varieties
        });

    } catch (error) {
        logger.error('Error fetching pepper varieties:', error);
        return res.status(500).json({
            success: false,
            error: 'Failed to fetch pepper varieties',
            message: error.message
        });
    }
});

/**
 * @route GET /api/pepper-varieties/:id
 * @desc Get a specific pepper variety by ID
 * @access Public
 */
router.get('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        logger.info(`Fetching pepper variety: ${id}`);

        const firestore = db.getDb();
        const varietyDoc = await firestore.collection('pepperVarieties').doc(id).get();

        if (!varietyDoc.exists) {
            return res.status(404).json({
                success: false,
                error: 'Pepper variety not found'
            });
        }

        return res.status(200).json({
            success: true,
            data: {
                id: varietyDoc.id,
                ...varietyDoc.data()
            }
        });

    } catch (error) {
        logger.error('Error fetching pepper variety:', error);
        return res.status(500).json({
            success: false,
            error: 'Failed to fetch pepper variety',
            message: error.message
        });
    }
});

/**
 * @route GET /api/pepper-varieties/simple/names
 * @desc Get simplified list of pepper variety names for dropdown
 * @access Public
 */
router.get('/simple/names', async (req, res) => {
    try {
        const language = req.query.lang || 'en'; // Default to English
        logger.info(`Fetching simplified pepper variety names (lang: ${language})`);

        const firestore = db.getDb();
        const varietiesSnapshot = await firestore.collection('pepperVarieties').get();

        if (varietiesSnapshot.empty) {
            return res.status(200).json({
                success: true,
                count: 0,
                data: []
            });
        }

        const varietyNames = [];
        varietiesSnapshot.forEach(doc => {
            const data = doc.data();
            const name = data.name?.[language] || data.name?.en || doc.id;
            varietyNames.push({
                id: doc.id,
                name: name,
                nameEn: data.name?.en || doc.id,
                nameSi: data.name?.si || data.name?.en || doc.id
            });
        });

        logger.info(`Successfully fetched ${varietyNames.length} variety names`);

        return res.status(200).json({
            success: true,
            count: varietyNames.length,
            data: varietyNames
        });

    } catch (error) {
        logger.error('Error fetching variety names:', error);
        return res.status(500).json({
            success: false,
            error: 'Failed to fetch variety names',
            message: error.message
        });
    }
});

module.exports = router;
