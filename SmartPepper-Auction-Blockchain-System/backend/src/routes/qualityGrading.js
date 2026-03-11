const express = require('express');
const router = express.Router();
const multer = require('multer');
const { authenticate } = require('../middleware/auth');
const db = require('../db/firebase');
const { analyzeGradingImage } = require('../ml/imageAnalyzer');

const upload = multer({ storage: multer.memoryStorage() });

// Utility to calculate final grade
// Rules: 
// High Density (570+) & Pure > 90% -> Grade A (Premium)
// Medium Density (550+) & Pure > 80% -> Grade B (Standard High)
// Lightweight (500+) & Pure > 70% -> Grade C (Lightweight)
// Low Density (<500) OR Pure < 70% -> Grade D (Low Quality)
const calculateFinalGrade = (density, visualPercentages) => {
    const pure = visualPercentages.pure || 0;

    if (density >= 570 && pure >= 90) return 'Grade A (Premium High Density)';
    if (density >= 550 && pure >= 80) return 'Grade B (Standard High Quality)';
    if (density >= 500 && pure >= 70) return 'Grade C (Lightweight / Industrial)';
    return 'Grade D (Low Density / Waste)';
};

// Route: Save a new quality grading entry
// @route POST /api/quality-grading
// @access Private (Farmer only)
router.post('/', authenticate, async (req, res) => {
    try {
        if (req.user.role !== 'farmer') {
            return res.status(403).json({ success: false, error: 'Only farmers can save quality grading data' });
        }

        const { weightGrams, density, visualPercentages } = req.body;

        if (!weightGrams || !density || !visualPercentages) {
            return res.status(400).json({ success: false, error: 'Missing required fields' });
        }

        const finalGrade = calculateFinalGrade(density, visualPercentages);

        const gradingData = {
            farmerId: req.user.id,
            farmerName: req.user.name,
            weightGrams,
            density,
            visualPercentages, // { pure, molded, discolored }
            finalGrade,
            timestamp: db.admin.firestore.FieldValue.serverTimestamp()
        };

        const result = await db.query.insert('quality_gradings', gradingData);

        return res.status(201).json({
            success: true,
            data: {
                ...gradingData,
                id: result.rows[0].id
            }
        });

    } catch (error) {
        console.error('Save quality grading error:', error);
        return res.status(500).json({ success: false, error: 'Failed to save quality grading data' });
    }
});

// Route: Analyze an image for quality grading using ML model
// @route POST /api/quality-grading/analyze
// @access Private (Farmer only)
router.post('/analyze', authenticate, upload.single('image'), async (req, res) => {
    try {
        if (req.user.role !== 'farmer') {
            return res.status(403).json({ success: false, error: 'Only farmers can analyze images' });
        }

        if (!req.file) {
            return res.status(400).json({ success: false, error: 'No image uploaded' });
        }

        const result = await analyzeGradingImage(req.file.buffer);

        return res.status(200).json({
            success: true,
            data: result
        });
    } catch (error) {
        console.error('Analyze grading image error:', error);
        return res.status(500).json({ success: false, error: 'Failed to analyze image' });
    }
});

// Route: Get quality grading history for the logged-in user
// route: GET /api/quality-grading/history
// @access Private
router.get('/history', authenticate, async (req, res) => {
    try {
        if (req.user.role !== 'farmer' && req.user.role !== 'admin') {
            return res.status(403).json({ success: false, error: 'Unauthorized to view grading history' });
        }

        const options = {
            where: [
                ['farmerId', '==', req.user.id] // Get only this farmer's data
            ],
            orderBy: [
                ['timestamp', 'desc']
            ]
        };

        const result = await db.query.select('quality_gradings', options);

        // Map timestamps cleanly
        const mappedData = result.rows.map(item => ({
            ...item,
            timestamp: item.created_at ? item.created_at.toDate() : new Date().toISOString()
        }));

        return res.status(200).json({
            success: true,
            count: result.rowCount,
            data: mappedData
        });

    } catch (error) {
        console.error('Fetch quality grading history error:', error);
        return res.status(500).json({ success: false, error: 'Failed to retrieve quality grading history' });
    }
});

module.exports = router;
