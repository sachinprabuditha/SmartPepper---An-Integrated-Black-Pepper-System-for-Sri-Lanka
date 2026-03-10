const path = require('path');
const fs = require('fs');
const API_CONFIG = require('./api-config');

// Directory setup
const BASE_DIR = path.resolve(__dirname, '..');
const DEBUG_ROOT = path.join(BASE_DIR, API_CONFIG.DISEASE.DEBUG_ROOT);

const class_names = API_CONFIG.DISEASE.CLASS_NAMES;
const folders_to_create = API_CONFIG.DISEASE.DEBUG_FOLDERS;

// Ensure debug directories exist
folders_to_create.forEach(f => {
    const dir = path.join(DEBUG_ROOT, f);
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
    }
});

module.exports = {
    BASE_DIR,
    DEBUG_ROOT,
    class_names,
};
