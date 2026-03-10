import { runPredictionJob } from '../src/services/predictionCron.service.js';
import { preloadModel } from '../src/services/prediction.service.js';
import dotenv from 'dotenv';
dotenv.config();

const run = async () => {
    try {
        console.log('Preloading model...');
        await preloadModel();

        console.log('Force running prediction update...');
        await runPredictionJob();

        console.log('Prediction update executed.');
        process.exit(0);
    } catch (err) {
        console.error('Error:', err);
        process.exit(1);
    }
};

run();
