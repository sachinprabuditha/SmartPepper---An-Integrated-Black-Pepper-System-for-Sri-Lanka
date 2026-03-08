const express = require('express');
const cors = require('cors');
const compression = require('compression');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const { calculateForecast } = require('./remedies');
const { runPythonInference } = require('./inference_bridge');

const app = express();
const PORT = 5000;

// Middleware
app.use(cors());
app.use(compression({
    level: 6,
    threshold: 500,
    filter: (req, res) => {
        if (req.headers['x-no-compression']) {
            return false;
        }
        return compression.filter(req, res);
    }
}));

// Setup Multer for parsing multipart/form-data
// We'll store files temporarily, process them, then delete them to save space.
const uploadDir = path.join(__dirname, 'uploads');
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
    limits: { fileSize: 50 * 1024 * 1024 } // 50MB max file size
});

app.post('/predict', upload.any(), async (req, res) => {
    try {
        let files = req.files || [];

        // Emulate Python logic of attempting to find files under different keys
        // (multer.any() captures all files regardless of field name)

        if (files.length === 0) {
            return res.status(400).json({
                status: "error",
                message: `No images provided.`
            });
        }

        // Limit to 4 images
        files = files.slice(0, 4);

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
            status: "success",
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

        return res.status(500).json({ status: "error", message: error.message });
    }
});

app.listen(PORT, '0.0.0.0', () => {
    console.log("🌿 PEPPER LEAF DISEASE DETECTION SERVER MODULAR (Node.js)");
    console.log(`🚀 Server running on http://0.0.0.0:${PORT}`);
});
