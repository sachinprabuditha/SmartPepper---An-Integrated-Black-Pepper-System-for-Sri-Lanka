require('dotenv').config();
const express = require('express');
const cors = require('cors');
const compression = require('compression');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const API_CONFIG = require('./api-config');
const { calculateForecast } = require('./remedies');
const { runPythonInference } = require('./inference_bridge');
const { initializeFirebase } = require('./firebase');
const diseaseLocationsRoutes = require('./disease_locations_routes');

// Initialize Firebase
initializeFirebase();

const app = express();
const PORT = API_CONFIG.SERVER.PORT;

// Middleware
app.use(cors());
app.use(express.json()); // Add JSON parsing middleware
app.use(compression({
    level: API_CONFIG.MIDDLEWARE.COMPRESSION.LEVEL,
    threshold: API_CONFIG.MIDDLEWARE.COMPRESSION.THRESHOLD,
    filter: (req, res) => {
        if (req.headers['x-no-compression']) {
            return false;
        }
        return compression.filter(req, res);
    }
}));

// Setup Multer for parsing multipart/form-data
// We'll store files temporarily, process them, then delete them to save space.
const uploadDir = path.join(__dirname, API_CONFIG.UPLOAD.DIR);
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir);
}

const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, uploadDir)
    },
    filename: function (req, file, cb) {
        cb(null, Date.now() + '-' + Math.round(Math.random() * 1E9) + path.extname(file.originalname))
    }
});

const upload = multer({
    storage: storage,
    limits: { fileSize: API_CONFIG.UPLOAD.MAX_FILE_SIZE }
});

app.post(API_CONFIG.ENDPOINTS.PREDICT, upload.any(), async (req, res) => {
    try {
        let files = req.files || [];

        // Emulate Python logic of attempting to find files under different keys
        // (multer.any() captures all files regardless of field name)

        if (files.length === 0) {
            return res.status(API_CONFIG.STATUS_CODES.BAD_REQUEST).json({
                status: API_CONFIG.MESSAGES.ERROR,
                message: API_CONFIG.MESSAGES.NO_IMAGES
            });
        }

        // Limit to max number of images
        files = files.slice(0, API_CONFIG.UPLOAD.MAX_FILES);

        const timestamp = new Date().toISOString().replace(/[-:T]/g, '').slice(0, 14); // YYYYMMDD_HHMMSS
        console.log(`🔍 Analyzing ${files.length} frames...`);

        const imagePaths = files.map(f => f.path);

        // Run python inference
        const analysisResults = await runPythonInference(imagePaths, timestamp);

        let forecastReport = [];
        for (const [disease, severityVal] of Object.entries(analysisResults.disease_specific_severity || {})) {
            const forecastData = calculateForecast(disease, severityVal);
            if (forecastData) {
                forecastReport.push(forecastData);
            }
        }

        const response = {
            status: API_CONFIG.MESSAGES.SUCCESS,
            severity: parseFloat((analysisResults.severity || 0).toFixed(2)),
            global_health_score: parseFloat((analysisResults.global_health_score || 0).toFixed(2)),
            disease_specific_severity: analysisResults.disease_specific_severity || {},
            forecast_report: forecastReport,
            total_detected: analysisResults.total_leaves || 0,
            counts: analysisResults.stats || {}
        };

        // Clean up uploaded files asynchronously
        files.forEach(f => {
            fs.unlink(f.path, err => {
                if (err) console.error(`Failed to delete temp file ${f.path}:`, err);
            });
        });

        res.set('Connection', 'keep-alive');
        return res.json(response);

    } catch (error) {
        console.error("Prediction error:", error);

        // Clean up files on error too
        if (req.files) {
            req.files.forEach(f => {
                if (fs.existsSync(f.path)) fs.unlinkSync(f.path);
            });
        }

        return res.status(API_CONFIG.STATUS_CODES.INTERNAL_SERVER_ERROR).json({ 
            status: API_CONFIG.MESSAGES.ERROR, 
            message: error.message 
        });
    }
});

// Disease locations API routes
app.use(API_CONFIG.BASE_PATHS.API + '/disease-locations', diseaseLocationsRoutes);

// Health check endpoint
app.get(API_CONFIG.ENDPOINTS.HEALTH, (req, res) => {
    res.json({ 
        status: API_CONFIG.MESSAGES.SUCCESS, 
        message: 'Disease Detection API is running',
        timestamp: new Date().toISOString()
    });
});

app.listen(PORT, API_CONFIG.SERVER.HOST, () => {
    console.log("🌿 PEPPER LEAF DISEASE DETECTION SERVER MODULAR (Node.js)");
    console.log(`🚀 Server running on ${API_CONFIG.getServerUrl()}`);
    console.log(`📍 Environment: ${API_CONFIG.SERVER.ENV}`);
    console.log(`\n📋 Available Endpoints:`);
    console.log(`   POST ${API_CONFIG.ENDPOINTS.PREDICT} - Analyze disease from images`);
    console.log(`   GET  ${API_CONFIG.ENDPOINTS.DISEASE_LOCATIONS} - Get all disease locations`);
    console.log(`   POST ${API_CONFIG.ENDPOINTS.DISEASE_LOCATIONS} - Save disease location`);
    console.log(`   GET  ${API_CONFIG.ENDPOINTS.HEALTH} - Health check`);
});
