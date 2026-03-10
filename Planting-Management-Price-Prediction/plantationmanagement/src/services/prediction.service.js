import onnx from 'onnxruntime-node';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Path to the model file
// Assuming the model file is located at project_root/Models/multi_output_regressor_model.onnx
// Adjusted path to go up from src/services to root
const modelPath = path.join(__dirname, '../models/multi_output_regressor_model.onnx');

const OrderedLocations = [
    "Colombo", "Galle", "Hambantota", "Kandy", "Kegalle",
    "Kurunegala", "Matale", "Matara", "Monaragala"
];

let session = null;

export const preloadModel = async () => {
    if (!session) {
        try {
            console.log(`[PredictionService] Preloading ONNX model into memory...`);
            session = await onnx.InferenceSession.create(modelPath);
            console.log(`[PredictionService] ONNX model successfully preloaded.`);
        } catch (error) {
            console.error('[PredictionService] Failed to preload ONNX model:', error);
            throw new Error(`Model not found at ${modelPath}`);
        }
    }
    return session;
};

const getSession = async () => {
    if (!session) {
        console.warn(`[PredictionService] Model was not preloaded. Loading lazily...`);
        return await preloadModel();
    }
    return session;
};

export const predictPrice = async (request) => {
    const inputs = [];

    // 1. USD_Rate
    inputs.push(request.UsdRate);
    // 2. Temperature
    inputs.push(request.Temperature);
    // 3. Precipitation
    inputs.push(request.Precipitation);

    // Parse Date
    const date = new Date(request.Date);
    // 5. Year
    inputs.push(date.getFullYear());
    // 6. Month
    inputs.push(date.getMonth() + 1); // JS Month is 0-indexed
    // 7. Day
    inputs.push(date.getDate());

    // 8-16. Locations
    OrderedLocations.forEach(loc => {
        inputs.push(request.Location.toLowerCase() === loc.toLowerCase() ? 1.0 : 0.0);
    });

    // 17-18. Grade (GR-2, WHITE)
    // GR-1: GR-2=0, WHITE=0
    // GR-2: GR-2=1, WHITE=0
    // WHITE: GR-2=0, WHITE=1
    const isGr2 = request.Grade.toUpperCase() === "GR-2";
    const isWhite = request.Grade.toUpperCase() === "WHITE";

    inputs.push(isGr2 ? 1.0 : 0.0);
    inputs.push(isWhite ? 1.0 : 0.0);

    // Create Tensor
    const inputTensor = new onnx.Tensor('float32', Float32Array.from(inputs), [1, inputs.length]);

    const sess = await getSession();

    // Get input name (assuming single input)
    const inputName = sess.inputNames[0];

    // Run Inference
    const feeds = {};
    feeds[inputName] = inputTensor;

    const results = await sess.run(feeds);

    // Get output (Highest_Price, Average_Price)
    const outputName = sess.outputNames[0];
    const outputData = results[outputName].data;

    return {
        HighestPrice: outputData[0],
        AveragePrice: outputData[1]
    };
};
