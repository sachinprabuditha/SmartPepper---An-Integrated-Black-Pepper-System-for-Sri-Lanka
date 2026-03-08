const express = require('express');
const cors = require('cors');
const multer = require('multer');
const sharp = require('sharp');
const onnx = require('onnxruntime-node');
const fs = require('fs');
const path = require('path');
const { Jimp } = require('jimp');

const app = express();
const PORT = 3001;

app.use(cors());
app.use(express.json());

// Load Model and Labels
let session;
let labels = [];

async function loadModel() {
    try {
        const modelPath = path.join(__dirname, 'model.onnx');
        const labelsPath = path.join(__dirname, 'labels.json');

        session = await onnx.InferenceSession.create(modelPath);
        labels = JSON.parse(fs.readFileSync(labelsPath, 'utf8'));

        console.log(`Model loaded from ${modelPath}`);
        console.log(`Classes: ${labels.join(', ')}`);
    } catch (e) {
        console.error("Failed to load model:", e);
    }
}

loadModel();

// ========== SEED DETECTION HELPERS ==========

// Connected Components Labeling (Flood Fill approach)
function labelConnectedComponents(binaryImage, width, height) {
    const labels = new Int32Array(width * height);
    let currentLabel = 0;

    function floodFill(startX, startY, label) {
        const stack = [[startX, startY]];
        const pixels = [];

        while (stack.length > 0) {
            const [x, y] = stack.pop();
            const idx = y * width + x;

            if (x < 0 || x >= width || y < 0 || y >= height) continue;
            if (labels[idx] !== 0 || binaryImage[idx] === 0) continue;

            labels[idx] = label;
            pixels.push({ x, y });

            // 4-connected neighbors
            stack.push([x + 1, y], [x - 1, y], [x, y + 1], [x, y - 1]);
        }

        return pixels;
    }

    const components = [];

    for (let y = 0; y < height; y++) {
        for (let x = 0; x < width; x++) {
            const idx = y * width + x;
            if (binaryImage[idx] === 1 && labels[idx] === 0) {
                currentLabel++;
                const pixels = floodFill(x, y, currentLabel);
                if (pixels.length > 0) {
                    components.push({ label: currentLabel, pixels });
                }
            }
        }
    }

    return components;
}

// Get bounding box from component pixels
function getBoundingBox(pixels) {
    let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;

    for (const { x, y } of pixels) {
        minX = Math.min(minX, x);
        minY = Math.min(minY, y);
        maxX = Math.max(maxX, x);
        maxY = Math.max(maxY, y);
    }

    return {
        x: minX,
        y: minY,
        width: maxX - minX + 1,
        height: maxY - minY + 1,
        area: pixels.length
    };
}

// Detect seeds from image buffer
async function detectSeeds(imageBuffer) {
    const image = await Jimp.read(imageBuffer);
    const width = image.width;
    const height = image.height;

    // Convert to grayscale and threshold
    const binaryImage = new Uint8Array(width * height);
    const threshold = 120; // Lowered to be stricter - only very dark pixels = seed

    // Access bitmap data directly (Jimp v1.x API)
    const data = image.bitmap.data;

    for (let y = 0; y < height; y++) {
        for (let x = 0; x < width; x++) {
            const idx = (y * width + x) * 4; // RGBA format
            const r = data[idx];
            const g = data[idx + 1];
            const b = data[idx + 2];
            const gray = Math.round(0.299 * r + 0.587 * g + 0.114 * b);

            // Invert: dark pixels become 1 (seed), light pixels become 0 (background)
            binaryImage[y * width + x] = gray < threshold ? 1 : 0;
        }
    }

    // Apply morphological erosion to remove small noise and internal texture
    // This shrinks foreground regions, removing small disconnected pixels
    function erode(img, w, h, iterations = 1) {
        let result = new Uint8Array(img);
        for (let iter = 0; iter < iterations; iter++) {
            const temp = new Uint8Array(result);
            for (let y = 1; y < h - 1; y++) {
                for (let x = 1; x < w - 1; x++) {
                    const idx = y * w + x;
                    // Only keep pixel if ALL neighbors are 1 (3x3 kernel)
                    const neighbors =
                        temp[(y - 1) * w + x - 1] && temp[(y - 1) * w + x] && temp[(y - 1) * w + x + 1] &&
                        temp[y * w + x - 1] && temp[y * w + x] && temp[y * w + x + 1] &&
                        temp[(y + 1) * w + x - 1] && temp[(y + 1) * w + x] && temp[(y + 1) * w + x + 1];
                    result[idx] = neighbors ? 1 : 0;
                }
            }
        }
        return result;
    }

    // Apply dilation to restore seed size after erosion
    function dilate(img, w, h, iterations = 1) {
        let result = new Uint8Array(img);
        for (let iter = 0; iter < iterations; iter++) {
            const temp = new Uint8Array(result);
            for (let y = 1; y < h - 1; y++) {
                for (let x = 1; x < w - 1; x++) {
                    const idx = y * w + x;
                    // Set pixel if ANY neighbor is 1 (3x3 kernel)
                    const hasNeighbor =
                        temp[(y - 1) * w + x - 1] || temp[(y - 1) * w + x] || temp[(y - 1) * w + x + 1] ||
                        temp[y * w + x - 1] || temp[y * w + x] || temp[y * w + x + 1] ||
                        temp[(y + 1) * w + x - 1] || temp[(y + 1) * w + x] || temp[(y + 1) * w + x + 1];
                    result[idx] = hasNeighbor ? 1 : 0;
                }
            }
        }
        return result;
    }

    // Opening operation (erode then dilate) removes small noise while preserving shape
    // Increased iterations for better noise removal
    const eroded = erode(binaryImage, width, height, 4);
    const cleaned = dilate(eroded, width, height, 4);

    // Find connected components
    const components = labelConnectedComponents(cleaned, width, height);

    // Filter by size (remove noise and too-large blobs)
    // Increased minimum to 0.1% of image to filter more aggressively
    const totalPixels = width * height;
    const minArea = Math.max(200, totalPixels * 0.001);  // At least 200px, or 0.1% of image
    const maxArea = totalPixels * 0.5; // No single seed should be more than 50% of image

    // Also filter by aspect ratio - seeds should be roughly circular (not thin lines)
    const seeds = components
        .map(c => ({ ...c, bbox: getBoundingBox(c.pixels) }))
        .filter(c => {
            const { width: bw, height: bh, area } = c.bbox;
            if (bw === 0 || bh === 0) return false;
            const aspectRatio = Math.max(bw, bh) / Math.min(bw, bh);
            // Seed should have area >= minArea, <= maxArea, and aspect ratio < 3 (more strict)
            return area >= minArea && area <= maxArea && aspectRatio < 3;
        });

    return { seeds, width, height, image };
}

// Classify a single seed region
async function classifySeed(imageBuffer, bbox) {
    // Crop and resize to 224x224
    const padding = 5; // Add some padding around the seed
    const rawBuffer = await sharp(imageBuffer)
        .extract({
            left: Math.max(0, bbox.x - padding),
            top: Math.max(0, bbox.y - padding),
            width: bbox.width + padding * 2,
            height: bbox.height + padding * 2
        })
        .resize(224, 224, { fit: 'cover' })
        .removeAlpha()
        .raw()
        .toBuffer();

    // Convert to tensor
    const float32Data = new Float32Array(1 * 3 * 224 * 224);
    const mean = [0.485, 0.456, 0.406];
    const std = [0.229, 0.224, 0.225];

    for (let i = 0; i < 224 * 224; i++) {
        const r = rawBuffer[i * 3 + 0];
        const g = rawBuffer[i * 3 + 1];
        const b = rawBuffer[i * 3 + 2];

        float32Data[0 * 224 * 224 + i] = ((r / 255.0) - mean[0]) / std[0];
        float32Data[1 * 224 * 224 + i] = ((g / 255.0) - mean[1]) / std[1];
        float32Data[2 * 224 * 224 + i] = ((b / 255.0) - mean[2]) / std[2];
    }

    const inputTensor = new onnx.Tensor('float32', float32Data, [1, 3, 224, 224]);

    // Run inference
    const feeds = {};
    feeds[session.inputNames[0]] = inputTensor;
    const results = await session.run(feeds);

    const logits = results[session.outputNames[0]].data;

    // Softmax
    const maxLogit = Math.max(...logits);
    const exps = logits.map(l => Math.exp(l - maxLogit));
    const sumExps = exps.reduce((a, b) => a + b, 0);
    const probs = exps.map(e => e / sumExps);

    const maxProbIndex = probs.indexOf(Math.max(...probs));

    return {
        class: labels[maxProbIndex],
        confidence: probs[maxProbIndex],
        probs: probs
    };
}


// Image Preprocessing (ImageNet Normalization)
// Mean: [0.485, 0.456, 0.406], Std: [0.229, 0.224, 0.225]
function normalize(pixel, i) {
    const mean = [0.485, 0.456, 0.406];
    const std = [0.229, 0.224, 0.225];
    return ((pixel / 255.0) - mean[i]) / std[i];
}

const upload = multer({ storage: multer.memoryStorage() });

app.post('/predict', upload.single('image'), async (req, res) => {
    if (!req.file) return res.status(400).json({ error: "No image uploaded" });

    try {
        // 1. Resize to 224x224 and get Raw RGB Buffer
        const rawBuffer = await sharp(req.file.buffer)
            .resize(224, 224, { fit: 'cover' })
            .removeAlpha()
            .raw()
            .toBuffer();

        // 2. Convert to Float32 Tensor [1, 3, 224, 224] matching FastAI/ResNet expectation
        const float32Data = new Float32Array(1 * 3 * 224 * 224);

        for (let i = 0; i < 224 * 224; i++) {
            // Raw buffer is RGBRGB...
            const r = rawBuffer[i * 3 + 0];
            const g = rawBuffer[i * 3 + 1];
            const b = rawBuffer[i * 3 + 2];

            // Fill tensor in CHW format (Channel, Height, Width)
            // Channel 0 (R)
            float32Data[0 * 224 * 224 + i] = normalize(r, 0);
            // Channel 1 (G)
            float32Data[1 * 224 * 224 + i] = normalize(g, 1);
            // Channel 2 (B)
            float32Data[2 * 224 * 224 + i] = normalize(b, 2);
        }

        const inputTensor = new onnx.Tensor('float32', float32Data, [1, 3, 224, 224]);

        // 3. Inference
        const feeds = {};
        feeds[session.inputNames[0]] = inputTensor;
        const results = await session.run(feeds);

        const output = results[session.outputNames[0]]; // Logits
        const logits = output.data;

        // 4. Softmax & Argmax
        // Simple softmax implementation
        const maxLogit = Math.max(...logits);
        const exps = logits.map(l => Math.exp(l - maxLogit));
        const sumExps = exps.reduce((a, b) => a + b, 0);
        const probs = exps.map(e => e / sumExps);

        const maxProbIndex = probs.indexOf(Math.max(...probs));
        const prediction = labels[maxProbIndex];
        const confidence = probs[maxProbIndex];

        res.json({
            class: prediction,
            confidence: confidence,
            probs: probs,
            labels: labels
        });

    } catch (e) {
        console.error(e);
        res.status(500).json({ error: e.message });
    }
});


// ========== MULTI-SEED PREDICTION ==========
app.post('/predict-multi', upload.single('image'), async (req, res) => {
    if (!req.file) return res.status(400).json({ error: "No image uploaded" });

    try {
        console.log("Starting multi-seed detection...");

        // 1. Detect seeds in the image
        const { seeds } = await detectSeeds(req.file.buffer);
        console.log(`Detected ${seeds.length} seeds`);

        if (seeds.length === 0) {
            return res.json({
                totalSeeds: 0,
                breakdown: {},
                overallGrade: "No seeds detected",
                individualResults: [],
                labels: labels
            });
        }

        // 2. Classify each seed
        const individualResults = [];
        const classCounts = {};

        // Initialize counts for all labels
        for (const label of labels) {
            classCounts[label] = 0;
        }

        for (let i = 0; i < seeds.length; i++) {
            const seed = seeds[i];
            try {
                const result = await classifySeed(req.file.buffer, seed.bbox);
                individualResults.push({
                    id: i + 1,
                    class: result.class,
                    confidence: result.confidence,
                    bbox: seed.bbox
                });
                classCounts[result.class]++;
            } catch (err) {
                console.error(`Failed to classify seed ${i + 1}:`, err.message);
            }
        }

        // 3. Build breakdown with percentages
        const breakdown = {};
        const totalClassified = individualResults.length;

        for (const label of labels) {
            breakdown[label] = {
                count: classCounts[label],
                percent: totalClassified > 0 ? Math.round((classCounts[label] / totalClassified) * 100) : 0
            };
        }

        // 4. Determine overall grade based on "Pure" percentage
        let overallGrade = "Poor";
        const purePercent = breakdown["Pure"]?.percent || breakdown[labels[0]]?.percent || 0;

        if (purePercent >= 90) overallGrade = "Excellent";
        else if (purePercent >= 75) overallGrade = "Good";
        else if (purePercent >= 50) overallGrade = "Fair";
        else overallGrade = "Poor";

        res.json({
            totalSeeds: seeds.length,
            breakdown: breakdown,
            overallGrade: overallGrade,
            individualResults: individualResults,
            labels: labels
        });

    } catch (e) {
        console.error("Multi-predict error:", e);
        res.status(500).json({ error: e.message });
    }
});


// --- Hardware Integration (ESP32) ---
const ESP_IP = 'http://192.168.1.129';

// Proxy helper to talk to ESP32
async function fetchFromEsp(endpoint, method = 'GET') {
    try {
        const response = await fetch(`${ESP_IP}${endpoint}`, {
            method,
            headers: { 'Content-Type': 'application/json' }
        });
        if (!response.ok) throw new Error(`ESP32 Error: ${response.statusText}`);
        return await response.json();
    } catch (error) {
        console.error("ESP32 Bridge Error:", error.message);
        throw error;
    }
}


app.get('/hardware/status', async (req, res) => {
    try {
        const data = await fetchFromEsp('/status');
        res.json(data);
    } catch (e) {
        res.json({ weight: 0.00, running: false, speed: 800, offline: true });
    }
});


app.post('/hardware/control', async (req, res) => {
    try {
        // req.body should contain { running, speed }
        const response = await fetch(`${ESP_IP}/control`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(req.body)
        });
        if (!response.ok) throw new Error("ESP Error");
        const data = await response.json();
        res.json(data);
    } catch (e) {
        res.status(502).json({ error: "Failed to communicate with ESP32" });
    }
});

app.post('/hardware/tare', async (req, res) => {
    try {
        await fetch(`${ESP_IP}/control/tare`, { method: 'POST' });
        res.json({ success: true });
    } catch (e) {
        res.status(502).json({ error: "Failed to tare" });
    }
});

app.post('/hardware/calibrate', async (req, res) => {
    try {
        // req.body = { knownWeight }
        const response = await fetch(`${ESP_IP}/control/calibrate`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(req.body)
        });
        const data = await response.json();
        res.json(data);
    } catch (e) {
        res.status(502).json({ error: "Failed to calibrate" });
    }
});

app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
    console.log(`ESP32 Bridge configured for ${ESP_IP}`);
});
