import axios from 'axios';
import cron from 'node-cron';
import { db } from '../config/firebase.js';
import { DISTRICTS } from '../utils/districts.js';

/** Returns today's date string (YYYY-MM-DD) in Sri Lanka time (Asia/Colombo). */
const getSriLankaDateStr = () =>
    new Date().toLocaleDateString('en-CA', { timeZone: 'Asia/Colombo' });

/**
 * Fetches weather data for all districts, calculates features, and saves them to Firestore.
 */
export const updateWeatherFeatures = async () => {
    console.log(`[WeatherService] Starting weather data update job at ${new Date().toISOString()}`);

    try {
        const lats = DISTRICTS.map(d => d.lat).join(',');
        const lons = DISTRICTS.map(d => d.lon).join(',');

        // Archive API has a 1-2 day data lag — use yesterday as end_date to avoid HTTP 400
        const slNow = new Date(new Date().toLocaleString('en-US', { timeZone: 'Asia/Colombo' }));
        const yesterdayObj = new Date(slNow);
        yesterdayObj.setDate(slNow.getDate() - 1);
        const endDate = yesterdayObj.toLocaleDateString('en-CA', { timeZone: 'Asia/Colombo' });

        // startDate = 30 days before yesterday
        const startDateObj = new Date(slNow);
        startDateObj.setDate(slNow.getDate() - 31);
        const startDate = startDateObj.toLocaleDateString('en-CA', { timeZone: 'Asia/Colombo' });

        // todayStr is still today's SL date — used for the Firestore document ID/date field
        const todayStr = getSriLankaDateStr();

        const url =
            `https://archive-api.open-meteo.com/v1/archive` +
            `?latitude=${lats}` +
            `&longitude=${lons}` +
            `&start_date=${startDate}` +
            `&end_date=${endDate}` +
            `&daily=temperature_2m_mean,precipitation_sum` +
            `&timezone=Asia%2FColombo`;

        const response = await axios.get(url, { timeout: 30000 }); // 30s timeout

        // Open-Meteo returns an Array of objects if multiple points are requested
        const results = Array.isArray(response.data) ? response.data : [response.data];

        const batch = db.batch();

        // Delete existing data
        const snapshot = await db.collection('daily_weather_forecast').get();
        snapshot.docs.forEach(doc => {
            batch.delete(doc.ref);
        });

        for (let idx = 0; idx < DISTRICTS.length; idx++) {
            const districtData = DISTRICTS[idx];
            // Results array index corresponds to the requested coordinates
            const dataForLocation = results[idx]?.daily;

            if (dataForLocation) {
                const temps = dataForLocation.temperature_2m_mean;
                const rains = dataForLocation.precipitation_sum;

                // Total rainfall in last 30 days
                const rain_30d = rains.reduce((sum, val) => sum + (val || 0), 0);

                // Average temperature in last 30 days
                let sumMeanTemp = 0;
                let validDays = 0;
                for (let i = 0; i < temps.length; i++) {
                    if (temps[i] !== null) {
                        sumMeanTemp += temps[i];
                        validDays++;
                    }
                }
                const avg_temp_30d = validDays > 0 ? (sumMeanTemp / validDays) : 0;

                const featureData = {
                    district: districtData.district,
                    date: todayStr,
                    rain_30d: Number(rain_30d.toFixed(2)),
                    avg_temp_30d: Number(avg_temp_30d.toFixed(2)),
                    created_at: new Date()
                };

                const docId = `${districtData.district}_${todayStr}`;
                featureData.id = docId;

                const docRef = db.collection('daily_weather_forecast').doc(docId);
                batch.set(docRef, featureData);
            }
        }

        await batch.commit();
        console.log(`[WeatherService] Successfully updated features for all ${DISTRICTS.length} districts using bulk request.`);
    } catch (error) {
        console.error(`[WeatherService] Error fetching weather data in bulk:`, error.message);
    }

    console.log(`[WeatherService] Completed weather data update job at ${new Date().toISOString()}`);
};

/**
 * Initializes the cron scheduler to run the weather update job daily.
 */
export const startWeatherJob = async () => {
    // Schedule to run every day at 4:00 AM Sri Lanka time
    cron.schedule('0 4 * * *', () => {
        console.log('[WeatherService] Cron job triggered - Updating weather features');
        updateWeatherFeatures();
    }, { timezone: 'Asia/Colombo' });
    console.log('[WeatherService] Cron job scheduled to run daily at 4:00 AM (Asia/Colombo)');

    // Check if today's data exists on startup
    try {
        const todayStr = getSriLankaDateStr();
        const snapshot = await db.collection('daily_weather_forecast').limit(1).get();

        let needsUpdate = true;
        if (!snapshot.empty) {
            const docData = snapshot.docs[0].data();
            if (docData.date === todayStr) {
                needsUpdate = false;
            }
        }

        if (needsUpdate) {
            console.log(`[WeatherService] Today's data (${todayStr}) not found or collection is empty. Running update on startup.`);
            updateWeatherFeatures();
        } else {
            console.log(`[WeatherService] Today's data (${todayStr}) already exists. Skipping startup update.`);
        }
    } catch (err) {
        console.error('[WeatherService] Error checking startup data:', err);
    }
};
