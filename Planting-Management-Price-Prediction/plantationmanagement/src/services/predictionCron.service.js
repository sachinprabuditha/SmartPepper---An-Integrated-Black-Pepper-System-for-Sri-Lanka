import cron from 'node-cron';
import { db } from '../config/firebase.js';
import { DISTRICTS } from '../utils/districts.js';
import { getUSDToLKR } from './exchangeService.js';
import { predictPrice } from './prediction.service.js';

/** Returns today's date string (YYYY-MM-DD) in Sri Lanka time (Asia/Colombo). */
const getSriLankaDateStr = () =>
    new Date().toLocaleDateString('en-CA', { timeZone: 'Asia/Colombo' });

const GRADES = ['GR-1', 'GR-2', 'WHITE'];
const TRAINED_DISTRICTS = [
    "Colombo", "Galle", "Hambantota", "Kandy", "Kegalle",
    "Kurunegala", "Matale", "Matara", "Monaragala"
];

const formatGradeForCollection = (grade) => {
    if (grade === 'GR-1') return 'GR1';
    if (grade === 'GR-2') return 'GR2';
    if (grade === 'WHITE') return 'White';
    return grade;
};

export const runPredictionJob = async () => {
    console.log(`[PredictionCron] Starting price prediction job at ${new Date().toISOString()}`);

    try {
        const todayStr = getSriLankaDateStr();

        // 1. Fetch current USD to LKR rate
        let usdRate = 300; // Fallback
        try {
            const usdData = await getUSDToLKR();
            if (usdData && usdData.rate) {
                usdRate = usdData.rate;
            }
        } catch (err) {
            console.warn('[PredictionCron] Failed to fetch USD rate, using fallback:', err.message);
        }

        // 2. Fetch today's weather data
        const weatherSnapshot = await db.collection('daily_weather_forecast').where('date', '==', todayStr).get();
        if (weatherSnapshot.empty) {
            console.error(`[PredictionCron] No weather data found for today (${todayStr}). Make sure weather job runs first.`);
            return;
        }

        const weatherMap = {};
        weatherSnapshot.forEach(doc => {
            const data = doc.data();
            weatherMap[data.district] = data;
        });

        // 3. Clear existing predictions for today in the single collection
        try {
            const existingDocs = await db.collection('daily_price_predictions').get();
            if (!existingDocs.empty) {
                const batchDelete = db.batch();
                existingDocs.forEach(d => batchDelete.delete(d.ref));
                await batchDelete.commit();
                console.log(`[PredictionCron] Cleared daily collection.`);
            }
        } catch (archiveErr) {
            console.error(`[PredictionCron] Error clearing daily_price_predictions:`, archiveErr.message);
        }

        // 4. Clean up previous collection (Keep last 7 days including today)
        try {
            const sixDaysAgoSL = new Date(new Date().toLocaleString('en-US', { timeZone: 'Asia/Colombo' }));
            sixDaysAgoSL.setDate(sixDaysAgoSL.getDate() - 6);
            const cutoffDateStr = sixDaysAgoSL.toLocaleDateString('en-CA', { timeZone: 'Asia/Colombo' });

            // Using direct string comparison since dates are formatted as YYYY-MM-DD
            const oldDocs = await db.collection('previous_price_predictions')
                .where('date', '<', cutoffDateStr)
                .get();

            if (!oldDocs.empty) {
                const batchDeletePrev = db.batch();
                oldDocs.forEach(d => batchDeletePrev.delete(d.ref));
                await batchDeletePrev.commit();
                console.log(`[PredictionCron] Cleaned up ${oldDocs.size} outdated records from previous collection.`);
            }
        } catch (cleanErr) {
            console.error(`[PredictionCron] Error cleaning previous_price_predictions:`, cleanErr.message);
        }

        // 5. Loop through combinations and run predictions
        for (const grade of GRADES) {
            for (const districtObj of DISTRICTS) {
                const district = districtObj.district;

                // Skip districts the model hasn't been trained on
                if (!TRAINED_DISTRICTS.includes(district)) {
                    continue;
                }

                const weatherData = weatherMap[district];

                if (!weatherData) {
                    console.warn(`[PredictionCron] Missing weather data for district: ${district}. Skipping.`);
                    continue;
                }

                // 6. Predict Price
                const request = {
                    UsdRate: usdRate,
                    Temperature: weatherData.avg_temp_30d,
                    Precipitation: weatherData.rain_30d,
                    Date: todayStr,
                    Location: district,
                    Grade: grade
                };

                let predictionResult;
                try {
                    predictionResult = await predictPrice(request);
                } catch (predErr) {
                    console.error(`[PredictionCron] Error predicting for ${district} ${grade}:`, predErr.message);
                    continue;
                }

                // 7. Save Prediction to both collections
                const docId = `${grade}_${district}_${todayStr}`;
                const predictionData = {
                    date: todayStr,
                    district: district,
                    grade: grade,
                    usd_rate: usdRate,
                    avg_temp_30d: weatherData.avg_temp_30d,
                    rain_30d: weatherData.rain_30d,
                    highest_price: predictionResult.HighestPrice,
                    average_price: predictionResult.AveragePrice,
                    created_at: new Date(),
                    id: docId
                };

                try {
                    await db.collection('daily_price_predictions').doc(docId).set(predictionData);
                    await db.collection('previous_price_predictions').doc(docId).set(predictionData);
                } catch (saveErr) {
                    console.error(`[PredictionCron] Error saving to price prediction collections:`, saveErr.message);
                }
            }
        }
        console.log(`[PredictionCron] Successfully completed prediction job.`);
    } catch (error) {
        console.error(`[PredictionCron] Critical error in prediction job:`, error);
    }
};

export const initPredictionJob = async () => {
    // Schedule to run every day at 4:30 AM Sri Lanka time
    cron.schedule('30 4 * * *', () => {
        console.log('[PredictionCron] Cron job triggered - Running price predictions');
        runPredictionJob();
    }, { timezone: 'Asia/Colombo' });
    console.log('[PredictionCron] Cron job scheduled to run daily at 4:30 AM (Asia/Colombo)');

    // Check if today's data exists on startup
    try {
        const todayStr = getSriLankaDateStr();
        const snapshot = await db.collection('daily_price_predictions').where('date', '==', todayStr).limit(1).get();

        let needsUpdate = true;
        if (!snapshot.empty) {
            needsUpdate = false;
        }

        if (needsUpdate) {
            console.log(`[PredictionCron] Today's predictions (${todayStr}) not found. Running prediction job on startup.`);
            // Delay slightly to ensure weather job completes if it was also triggered on startup
            setTimeout(() => {
                runPredictionJob();
            }, 15000); // 15 seconds delay
        } else {
            console.log(`[PredictionCron] Today's predictions (${todayStr}) already exist. Skipping startup run.`);
        }
    } catch (err) {
        console.error('[PredictionCron] Error checking startup data:', err);
    }
};
