import axios from 'axios';
import dotenv from 'dotenv';

dotenv.config();

const CURRENCYFREAKS_API_KEY = process.env.CURRENCYFREAKS_API_KEY;
const CURRENCYFREAKS_URL = `https://api.currencyfreaks.com/v2.0/rates/latest?apikey=${CURRENCYFREAKS_API_KEY}&symbols=LKR`;
const FALLBACK_URL = `https://latest.currency-api.pages.dev/v1/currencies/usd.json`;

// Cache storage
let cache = {
    data: null,
    lastFetched: 0
};

const CACHE_TTL = 10 * 60 * 1000; // 10 minutes

/**
 * Normalizes the exchange rate data from different sources
 */
const normalizeResponse = (rate, source, dateStr) => {
    // Format date string to YYYY-MM-DD
    const date = dateStr ? dateStr.split(' ')[0] : new Date().toISOString().split('T')[0];

    return {
        base: "USD",
        currency: "LKR",
        rate: parseFloat(rate),
        buyRate: parseFloat(rate), // Using same rate for both as per requirement
        sellRate: parseFloat(rate), // Using same rate for both as per requirement
        source: source,
        date: date
    };
};

/**
 * Fetches the USD to LKR exchange rate with fallback and caching
 */
export const getUSDToLKR = async () => {
    const now = Date.now();

    // 1. Check if we have valid cached data
    if (cache.data && (now - cache.lastFetched < CACHE_TTL)) {
        console.log(`[ExchangeService] Returning cached rate: ${cache.data.rate} (Source: ${cache.data.source})`);
        return cache.data;
    }

    // 2. Try Primary API (currency-api pages.dev)
    try {
        console.log('[ExchangeService] Fetching from ExchangeAPI (Primary)...');
        const response = await axios.get(FALLBACK_URL);

        if (response.data && response.data.usd && response.data.usd.lkr) {
            const rate = response.data.usd.lkr;
            cache.data = normalizeResponse(rate, "currency-api", response.data.date);
            cache.lastFetched = now;
            console.log(`[ExchangeService] Successfully updated from ExchangeAPI (Primary): ${cache.data.rate}`);
            return cache.data;
        } else {
            throw new Error("Invalid response format from Primary API");
        }
    } catch (error) {
        console.error(`[ExchangeService] Primary API failed: ${error.message}`);
    }

    // 3. Try Fallback API (CurrencyFreaks)
    try {
        console.log('[ExchangeService] Fetching from CurrencyFreaks (Fallback)...');
        const response = await axios.get(CURRENCYFREAKS_URL);

        if (response.data && response.data.rates && response.data.rates.LKR) {
            const rate = response.data.rates.LKR;
            cache.data = normalizeResponse(rate, "currencyfreaks", response.data.date);
            cache.lastFetched = now;
            console.log(`[ExchangeService] Successfully updated from CurrencyFreaks (Fallback): ${cache.data.rate}`);
            return cache.data;
        } else {
            throw new Error("Invalid response format from CurrencyFreaks");
        }
    } catch (error) {
        console.error(`[ExchangeService] CurrencyFreaks failed: ${error.message}`);
    }

    // 4. Try CoinGecko API (Cross-rate BTC/LKR / BTC/USD)
    try {
        console.log('[ExchangeService] Fetching from CoinGecko...');
        const COINGECKO_URL = 'https://api.coingecko.com/api/v3/exchange_rates';
        const response = await axios.get(COINGECKO_URL);

        if (response.data && response.data.rates && response.data.rates.lkr && response.data.rates.usd) {
            const lkrPerBtc = response.data.rates.lkr.value;
            const usdPerBtc = response.data.rates.usd.value;
            const rate = lkrPerBtc / usdPerBtc;

            cache.data = normalizeResponse(rate, "coingecko", new Date().toISOString());
            cache.lastFetched = now;
            console.log(`[ExchangeService] Successfully updated from CoinGecko: ${cache.data.rate}`);
            return cache.data;
        } else {
            throw new Error("Invalid response format from CoinGecko");
        }
    } catch (error) {
        console.error(`[ExchangeService] CoinGecko failed: ${error.message}`);
    }

    // 5. Return stale cache if all APIs fail but we have data
    if (cache.data) {
        console.warn('[ExchangeService] All APIs failed. Using stale cache.');
        return cache.data;
    }

    throw new Error("Failed to fetch exchange rates from all sources.");
};

// Background refresh every 10 minutes
setInterval(async () => {
    try {
        console.log('[ExchangeService] Background refreshing rate...');
        await getUSDToLKR();
    } catch (err) {
        console.error(`[ExchangeService] Background refresh failed: ${err.message}`);
    }
}, CACHE_TTL);

export default {
    getUSDToLKR
};
