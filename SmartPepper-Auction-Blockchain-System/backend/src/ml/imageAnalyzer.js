const sharp = require('sharp');
const onnx = require('onnxruntime-node');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

let session;
let labels = [];

async function loadModel() {
    try {
        const modelPath = path.join(__dirname, 'model.onnx');
        const labelsPath = path.join(__dirname, 'labels.json');
        session = await onnx.InferenceSession.create(modelPath);
        labels = JSON.parse(fs.readFileSync(labelsPath, 'utf8'));
        console.log(`ML Model loaded. Classes: ${labels.join(', ')}`);
    } catch (e) {
        console.error("Failed to load ML model:", e);
    }
}

loadModel();

// ========== PYTHON SEED DETECTOR ==========

/**
 * Call seed_counter.py via child process.
 * Pipes imageBuffer (JPEG bytes) into stdin, gets JSON from stdout.
 * Returns: { seeds: [{x,y,w,h}, ...], count: N }
 */
function runPythonDetector(imageBuffer) {
    return new Promise((resolve, reject) => {
        const scriptPath = path.join(__dirname, 'seed_counter.py');
        const py = spawn('python', [scriptPath], {
            stdio: ['pipe', 'pipe', 'pipe']
        });

        let stdout = '';
        let stderr = '';

        py.stdout.on('data', d => stdout += d.toString());
        py.stderr.on('data', d => stderr += d.toString());

        py.on('close', code => {
            if (stderr) console.log('[seed_counter.py]', stderr.trim());
            if (code !== 0) {
                return reject(new Error(`seed_counter.py exited with code ${code}: ${stderr}`));
            }
            try {
                resolve(JSON.parse(stdout));
            } catch (e) {
                reject(new Error(`Failed to parse seed_counter output: ${stdout}`));
            }
        });

        py.on('error', err => reject(err));

        // Send image buffer into stdin
        py.stdin.write(imageBuffer);
        py.stdin.end();
    });
}

// ========== ONNX CLASSIFIER ==========

/**
 * Crop a seed region from the image and classify it with the ONNX model.
 * bbox: {x, y, w, h}
 */
async function classifySeed(imageBuffer, bbox) {
    if (!session) {
        throw new Error("ONNX model is not loaded yet.");
    }

    const padding = 4;

    // Apply EXIF rotation so Node.js pixel layout matches Python/OpenCV
    const correctedBuffer = await sharp(imageBuffer).rotate().toBuffer();

    // Get actual (post-rotation) image dimensions
    const meta = await sharp(correctedBuffer).metadata();
    const imgW = meta.width || 9999;
    const imgH = meta.height || 9999;

    const left   = Math.max(0, bbox.x - padding);
    const top    = Math.max(0, bbox.y - padding);
    const right  = Math.min(imgW, bbox.x + bbox.w + padding);
    const bottom = Math.min(imgH, bbox.y + bbox.h + padding);
    const cropW  = right - left;
    const cropH  = bottom - top;

    // Skip degenerate crops
    if (cropW < 15 || cropH < 15) {
        throw new Error(`Crop too small: ${cropW}x${cropH} (bbox y=${bbox.y}, imgH=${imgH})`);
    }

    const rawBuffer = await sharp(correctedBuffer)
        .extract({ left, top, width: cropW, height: cropH })
        .resize(224, 224, { fit: 'cover' })
        .removeAlpha()
        .raw()
        .toBuffer();

    const float32Data = new Float32Array(3 * 224 * 224);
    const mean = [0.485, 0.456, 0.406];
    const std  = [0.229, 0.224, 0.225];

    for (let i = 0; i < 224 * 224; i++) {
        float32Data[0 * 224 * 224 + i] = ((rawBuffer[i * 3 + 0] / 255.0) - mean[0]) / std[0];
        float32Data[1 * 224 * 224 + i] = ((rawBuffer[i * 3 + 1] / 255.0) - mean[1]) / std[1];
        float32Data[2 * 224 * 224 + i] = ((rawBuffer[i * 3 + 2] / 255.0) - mean[2]) / std[2];
    }

    const inputTensor = new onnx.Tensor('float32', float32Data, [1, 3, 224, 224]);
    const feeds = {};
    feeds[session.inputNames[0]] = inputTensor;

    const results = await session.run(feeds);
    const rawLogits = results[session.outputNames[0]].data;

    const biases = {
        'pure': 3.0,        
        'molded': -1.0,     
        'discolored': 0.0   
    };

    const logits = Array.from(rawLogits);
    for (let i = 0; i < labels.length; i++) {
        const labelStr = labels[i];
        if (biases[labelStr] !== undefined) {
            logits[i] += biases[labelStr];
        }
    }

    // Softmax
    const maxLogit = Math.max(...logits);
    const exps     = logits.map(l => Math.exp(l - maxLogit));
    const sumExps  = exps.reduce((a, b) => a + b, 0);
    const probs    = exps.map(e => e / sumExps);

    const maxIdx = probs.indexOf(Math.max(...probs));
    return { class: labels[maxIdx], confidence: probs[maxIdx] };
}

// ========== MAIN ANALYZE FUNCTION ==========

async function analyzeGradingImage(imageBuffer) {
    // 1. Save raw capture for debugging
    try {
        fs.writeFileSync(path.join(__dirname, 'last_capture.jpg'), imageBuffer);
    } catch (e) {
        console.warn('[ML] Could not save last_capture.jpg:', e.message);
    }

    // 2. Detect seeds using OpenCV Python microservice
    let detection;
    try {
        detection = await runPythonDetector(imageBuffer);
    } catch (e) {
        console.error('[ML] Python seed detector failed:', e.message);
        return { totalSeeds: 0, breakdown: {}, labels };
    }

    const { seeds, count } = detection;
    console.log(`[ML] Python detector found ${count} seeds (${seeds.length} classification regions)`);

    if (count === 0) {
        return { totalSeeds: 0, breakdown: {}, labels };
    }

    // 3. Classify each detected bbox with the ONNX model
    const classCounts = {};
    for (const label of labels) classCounts[label] = 0;

    // Limit classification to 80 regions max to keep response time reasonable.
    // For large piles, we classify a sample and extrapolate.
    const maxToClassify = Math.min(seeds.length, 80);
    const sampleBboxes = seeds.slice(0, maxToClassify);
    let classifiedCount = 0;

    for (const bbox of sampleBboxes) {
        try {
            const result = await classifySeed(imageBuffer, bbox);
            classCounts[result.class]++;
            classifiedCount++;
        } catch (err) {
            console.error('[ML] classifySeed error:', err.message);
        }
    }

    // Extrapolate proportionally if we sampled a subset
    if (classifiedCount > 0 && count > classifiedCount) {
        const scale = count / classifiedCount;
        for (const label of labels) {
            classCounts[label] = Math.round(classCounts[label] * scale);
        }
    }

    return {
        totalSeeds: count,
        breakdown:  classCounts,
        labels
    };
}

module.exports = { analyzeGradingImage, runPythonDetector };
