const path = require('path');
const fs = require('fs');

// Directory setup
const BASE_DIR = path.resolve(__dirname, '..');
const DEBUG_ROOT = path.join(BASE_DIR, 'debug_crops');

const class_names = ["Footrot", "Pollu_Disease", "Slow-Decline", "healthy leaves"];
const folders_to_create = [...class_names, "Uncertain"];

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
