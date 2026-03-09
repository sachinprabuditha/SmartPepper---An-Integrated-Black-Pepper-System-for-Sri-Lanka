import express from 'express';
import { getUSDToLKR } from '../services/exchangeService.js';

const router = express.Router();

/**
 * GET /api/exchange/usd-lkr
 * Fetches the USD to LKR exchange rate with fallback and caching
 * Returns same value for buyRate and sellRate
 */
router.get('/usd-lkr', async (req, res) => {
    try {
        const rateData = await getUSDToLKR();
        res.json(rateData);
    } catch (error) {
        console.error(`[ExchangeRoutes] Error fetching rate: ${error.message}`);
        res.status(503).json({
            error: "Exchange rate service unavailable",
            message: error.message
        });
    }
});

export default router;
