import * as predictionService from '../services/prediction.service.js';

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
