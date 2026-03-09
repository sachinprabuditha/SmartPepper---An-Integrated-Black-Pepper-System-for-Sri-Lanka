import * as predictionService from '../services/prediction.service.js';
import { db } from '../config/firebase.js';


export const predict = async (req, res) => {
    try {
        const body = req.body;

        // Map camelCase from frontend to PascalCase for service
        const request = {
            UsdBuyRate: body.usdBuyRate || body.UsdBuyRate,
            UsdSellRate: body.usdSellRate || body.UsdSellRate,
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

        let docRef = await db.collection('district_weather_features').doc(docId).get();

        // If data isn't in Firestore (e.g. server was off at 2 AM), fetch it on-demand
        if (!docRef.exists) {
            console.log(`[PredictionController] Weather data missing for ${district} on ${todayStr}. Triggering on-demand fetch.`);
            const { updateWeatherFeatures } = await import('../services/weatherService.js');
            await updateWeatherFeatures();

            // Try getting the document again after the fetch
            docRef = await db.collection('district_weather_features').doc(docId).get();

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
