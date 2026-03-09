import axios from 'axios';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.resolve(__dirname, '.env') });

const FALLBACK_URL = `https://latest.currency-api.pages.dev/v1/currencies/usd.json`;
const CURRENCYFREAKS_API_KEY = process.env.CURRENCYFREAKS_API_KEY;
const CURRENCYFREAKS_URL = `https://api.currencyfreaks.com/v2.0/rates/latest?apikey=${CURRENCYFREAKS_API_KEY}&symbols=LKR`;
const COINGECKO_URL = 'https://api.coingecko.com/api/v3/exchange_rates';

async function testCurrencyAPIs() {
    console.log("=====================================");
    console.log("TESTING ALL 3 EXCHANGE APIS");
    console.log("=====================================\n");

    // 1. Primary: Currency-API (Cloudflare Pages)
    try {
        console.log("1. Cloudflare Currency-API (Now Primary):");
        const response1 = await axios.get(FALLBACK_URL);
        if (response1.data && response1.data.usd && response1.data.usd.lkr) {
            console.log(`✅ SUCCESS - Rate: ${response1.data.usd.lkr} LKR/USD`);
        } else {
            console.log(`❌ FAILED - Invalid format`);
        }
    } catch (e) {
        console.log(`❌ FAILED - ${e.message}`);
    }

    console.log("\n-------------------------------------");

    // 2. Fallback 1: CurrencyFreaks
    try {
        console.log("2. CurrencyFreaks (Now Fallback 1):");
        if (!CURRENCYFREAKS_API_KEY) {
            console.log(`⚠️ WARNING - No API key found in .env`);
        }
        const response2 = await axios.get(CURRENCYFREAKS_URL);
        if (response2.data && response2.data.rates && response2.data.rates.LKR) {
            console.log(`✅ SUCCESS - Rate: ${response2.data.rates.LKR} LKR/USD`);
        } else {
            console.log(`❌ FAILED - Invalid format`);
        }
    } catch (e) {
        console.log(`❌ FAILED - ${e.message}`);
    }

    console.log("\n-------------------------------------");

    // 3. Fallback 2: CoinGecko
    try {
        console.log("3. CoinGecko (Fallback 2):");
        const response3 = await axios.get(COINGECKO_URL);
        if (response3.data && response3.data.rates && response3.data.rates.lkr && response3.data.rates.usd) {
            const lkrPerBtc = response3.data.rates.lkr.value;
            const usdPerBtc = response3.data.rates.usd.value;
            const rate = lkrPerBtc / usdPerBtc;
            console.log(`✅ SUCCESS - Calculated Rate: ${rate.toFixed(4)} LKR/USD`);
        } else {
            console.log(`❌ FAILED - Invalid format`);
        }
    } catch (e) {
        console.log(`❌ FAILED - ${e.message}`);
    }

    console.log("\n=====================================");
}

testCurrencyAPIs();
