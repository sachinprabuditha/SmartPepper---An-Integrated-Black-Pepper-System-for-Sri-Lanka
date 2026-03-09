import axios from 'axios';
import cron from 'node-cron';
import { db } from '../config/firebase.js';
import { DISTRICTS } from '../utils/districts.js';

/**
 * Fetches weather data for all districts, calculates features, and saves them to Firestore.
 */
export const updateWeatherFeatures = async () => {
    console.log(`[WeatherService] Starting weather data update job at ${new Date().toISOString()}`);

    try {
        const lats = DISTRICTS.map(d => d.lat).join(',');
        const lons = DISTRICTS.map(d => d.lon).join(',');

        const today = new Date();
        const endDate = today.toISOString().split('T')[0];

        const start = new Date();
        start.setDate(today.getDate() - 30);
        const startDate = start.toISOString().split('T')[0];

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

        const todayStr = endDate;
        const batch = db.batch();

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

                const docRef = db.collection('district_weather_features').doc(docId);
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
export const startWeatherJob = () => {
    // Schedule to run every day at 2 AM
    cron.schedule('0 2 * * *', () => {
        console.log('[WeatherService] Cron job triggered - Updating weather features');
        updateWeatherFeatures();
    });
    console.log('[WeatherService] Cron job scheduled to run daily at 2 AM');

    // Optionally trigger immediately on startup if needed, but the prompt says 2 AM daily.
    // Uncomment the following line to run it once on startup for initial population.
    // updateWeatherFeatures();
};
