

require('dotenv').config();

const API_CONFIG = {

    SERVER: {
        HOST: process.env.HOST || '0.0.0.0',
        PORT: process.env.PORT || 5000,
        ENV: process.env.NODE_ENV || 'development',
    },

    BASE_PATHS: {
        API: '/api',
        PREDICT: '/predict',
    },


    ENDPOINTS: {
        // Disease Detection
        PREDICT: '/predict',

        // Disease Locations
        DISEASE_LOCATIONS: '/api/disease-locations',
        GET_DISEASE_LOCATIONS: '/api/disease-locations',
        SAVE_DISEASE_LOCATION: '/api/disease-locations',

        // Health Check
        HEALTH: '/health',
    },


    FIREBASE: {
        DATABASE_URL: process.env.FIREBASE_DATABASE_URL || 'https://smartpepper-645db.firebaseio.com',
        PROJECT_ID: process.env.FIREBASE_PROJECT_ID || 'smartpepper-645db',

        // Firestore Collections
        COLLECTIONS: {
            DISEASE_LOCATIONS: 'disease_locations',
        },
    },

    UPLOAD: {
        DIR: process.env.UPLOAD_DIR || 'uploads',
        MAX_FILE_SIZE: parseInt(process.env.MAX_FILE_SIZE) || 52428800, // 50MB default
        MAX_FILES: 4, // Maximum number of images for analysis
        ALLOWED_EXTENSIONS: ['.jpg', '.jpeg', '.png'],
    },


    DISEASE: {
        CLASS_NAMES: ['Footrot', 'healthy leaves', 'Pollu_Disease', 'Slow-Decline'],
        DEBUG_FOLDERS: ['Footrot', 'healthy leaves', 'Pollu_Disease', 'Slow-Decline', 'Uncertain'],
        DEBUG_ROOT: 'debug_crops',

        // Severity Thresholds
        SEVERITY_LEVELS: {
            LOW: 20,        // 0-20%
            MODERATE: 40,   // 20-40%
            HIGH: 60,       // 40-60%
            CRITICAL: 80,   // 60-80%
            SEVERE: 100,    // 80-100%
        },
    },


    MIDDLEWARE: {
        COMPRESSION: {
            LEVEL: 6,
            THRESHOLD: 500,
        },
        CORS: {
            ENABLED: true,
        },
    },


    MESSAGES: {
        SUCCESS: 'success',
        ERROR: 'error',
        NO_IMAGES: 'No images provided.',
        PREDICTION_ERROR: 'Error during prediction',
        FIREBASE_NOT_CONFIGURED: 'Firebase not configured. Disease location storage requires Firebase.',
        MISSING_REQUIRED_FIELDS: 'Missing required fields: latitude, longitude, diseaseName, severity',
        LOCATION_SAVED: 'Disease location saved successfully',
        LOCATION_RETRIEVED: 'Disease locations retrieved successfully',
    },

    // ===================================
    // HTTP STATUS CODES
    // ===================================
    STATUS_CODES: {
        OK: 200,
        CREATED: 201,
        BAD_REQUEST: 400,
        UNAUTHORIZED: 401,
        FORBIDDEN: 403,
        NOT_FOUND: 404,
        INTERNAL_SERVER_ERROR: 500,
        SERVICE_UNAVAILABLE: 503,
    },
};

// ===================================
// HELPER FUNCTIONS
// ===================================

/**
 * Get the full server URL
 * @returns {string} Full server URL (e.g., http://0.0.0.0:5000)
 */
API_CONFIG.getServerUrl = function () {
    return `http://${this.SERVER.HOST}:${this.SERVER.PORT}`;
};

/**
 * Get the full endpoint URL
 * @param {string} endpoint - Endpoint path
 * @returns {string} Full endpoint URL
 */
API_CONFIG.getEndpointUrl = function (endpoint) {
    return `${this.getServerUrl()}${endpoint}`;
};

/**
 * Check if server is in production mode
 * @returns {boolean}
 */
API_CONFIG.isProduction = function () {
    return this.SERVER.ENV === 'production';
};

/**
 * Check if server is in development mode
 * @returns {boolean}
 */
API_CONFIG.isDevelopment = function () {
    return this.SERVER.ENV === 'development';
};

module.exports = API_CONFIG;
