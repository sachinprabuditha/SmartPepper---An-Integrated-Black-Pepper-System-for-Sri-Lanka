import * as predictionService from '../services/prediction.service.js';
import { db } from '../config/firebase.js';


export const predict = async (req, res) => {
    try {
        const body = req.body;

        // Map camelCase from frontend to PascalCase for service
        const request = {
            UsdRate: body.usdRate || body.UsdRate,
            Temperature: body.temperature || body.Temperature,
            Precipitation: body.precipitation || body.Precipitation,
            Date: body.date || body.Date,
            Location: body.location || body.Location,
            Grade: body.grade || body.Grade
        };

        // Basic validation
        if (!request.Date || !request.Location || !request.Grade) {
            return res.status(400).json({ success: false, message: 'Missing required fields', received: body });
        }

        const result = await predictionService.predictPrice(request);

        // Map PascalCase from service to camelCase for frontend
        const responseData = {
            highestPrice: result.HighestPrice,
            averagePrice: result.AveragePrice,
            currency: 'LKR' // Service doesn't return currency, adding default
        };

        res.status(200).json(responseData);
        // .NET implementation returned `Ok(result)`, so it returns JSON of PricePredictionResult directly.
        // { HighestPrice: ..., AveragePrice: ... }
    } catch (error) {
        console.error('Prediction error:', error);
        res.status(500).json({ message: 'An error occurred during prediction.', details: error.message });
    }
};

export const getLatestWeather = async (req, res) => {
    try {
        const { district } = req.params;
        if (!district) {
            return res.status(400).json({ success: false, message: 'District is required' });
        }

        // The ID is structured as `${district}_${YYYY-MM-DD}`
        const todayStr = new Date().toISOString().split('T')[0];
        const docId = `${district}_${todayStr}`;

        let docRef = await db.collection('daily_weather_forecast').doc(docId).get();

        // If data isn't in Firestore (e.g. server was off at 2 AM), fetch it on-demand
        if (!docRef.exists) {
            console.log(`[PredictionController] Weather data missing for ${district} on ${todayStr}. Triggering on-demand fetch.`);
            const { updateWeatherFeatures } = await import('../services/weatherService.js');
            await updateWeatherFeatures();

            // Try getting the document again after the fetch
            docRef = await db.collection('daily_weather_forecast').doc(docId).get();

            if (!docRef.exists) {
                return res.status(404).json({ success: false, message: `No weather data found for district: ${district} today, even after on-demand fetch.` });
            }
        }

        const data = docRef.data();

        res.status(200).json({
            success: true,
            data: {
                temperature: data.avg_temp_30d,
                precipitation: data.rain_30d,
                date: data.date
            }
        });
    } catch (error) {
        console.error('Error fetching weather data:', error);
        res.status(500).json({ success: false, message: 'An error occurred while fetching weather data.' });
    }
};
export const getPriceAnalytics = async (req, res) => {
    try {
        const { district } = req.params;
        if (!district) {
            return res.status(400).json({ success: false, message: 'District is required' });
        }

        const trimmedDistrict = district.trim();

        // Calculate the date range for the last 7 days
        const dates = [];
        for (let i = 0; i < 7; i++) {
            const d = new Date();
            // Using setDate is fine as long as we are consistent with ISOString 
            // the daily weather fetch uses local date, so we should too.
            d.setDate(d.getDate() - i);
            dates.push(d.toISOString().split('T')[0]);
        }

        // To avoid requiring a composite index for (district == ... AND date in [...]), 
        // we query by district only and then filter by date in memory.
        // This is efficient because the number of records per district is small.
        const snapshot = await db.collection('previous_price_predictions')
            .where('district', '==', trimmedDistrict)
            .get();

        let data = snapshot.docs.map(doc => doc.data());

        // Filter for the last 7 days in memory
        data = data.filter(item => dates.includes(item.date));

        // Group data by grade or just return the list
        // Sorting by date naturally helps the frontend charts
        data.sort((a, b) => a.date.localeCompare(b.date));

        res.status(200).json({
            success: true,
            data: data
        });
    } catch (error) {
        console.error('Error fetching price analytics:', error);
        res.status(500).json({ success: false, message: 'An error occurred while fetching price analytics.' });
    }
};
