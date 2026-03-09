# Exchange Rate API Integration

## Overview

The SmartPepper system now uses **real-time exchange rates** from the **CoinGecko API** (free tier, no API key required) instead of hardcoded values. Exchange rates are automatically updated every 5 minutes.

## Features

✅ **Real-time exchange rates** - Live ETH to USD and LKR conversions  
✅ **Automatic updates** - Rates refresh every 5 minutes  
✅ **Fallback system** - Uses cached rates if API is unavailable  
✅ **Firebase persistence** - Rates stored for historical tracking  
✅ **Admin controls** - Manual rate updates and status monitoring  
✅ **Zero cost** - Uses free CoinGecko API (no API key needed)

## Architecture

### Components

1. **ExchangeRateService** (`src/services/exchangeRateService.js`)
   - Fetches live rates from CoinGecko API
   - Updates every 5 minutes automatically
   - Stores rates in Firebase
   - Updates governance settings
   - Provides fallback rates if API fails

2. **CurrencyConverter** (`src/utils/currencyConverter.js`)
   - Uses ExchangeRateService for live rates
   - Provides conversion utilities
   - Caches rates for performance
   - Falls back to local rates if service unavailable

3. **Admin Routes** (`src/routes/admin.js`)
   - GET `/api/admin/exchange-rates/status` - Check service health
   - POST `/api/admin/exchange-rates/update` - Force rate update
   - GET `/api/admin/exchange-rates/history` - View rate history

## API Details

### CoinGecko API

**Endpoint:** `https://api.coingecko.com/api/v3/simple/price`

**Parameters:**

- `ids`: ethereum
- `vs_currencies`: usd,lkr
- `include_last_updated_at`: true

**Rate Limits:**

- Free tier: 10-50 calls/minute (varies)
- Our usage: 1 call every 5 minutes = ~288 calls/day

**Example Response:**

```json
{
  "ethereum": {
    "usd": 3125.5,
    "lkr": 1008000.0,
    "last_updated_at": 1709971200
  }
}
```

## Configuration

### Environment Variables (Optional)

```env
# Exchange rate update interval (milliseconds)
EXCHANGE_RATE_UPDATE_INTERVAL=300000  # 5 minutes (default)
```

### Governance Settings

The service automatically updates these fields in `governance_settings`:

```javascript
{
  lkr_to_eth_rate: 0.00000099,    // 1 LKR to ETH
  usd_to_eth_rate: 0.00032,       // 1 USD to ETH
  eth_to_lkr_rate: 1008000.00,    // 1 ETH to LKR
  eth_to_usd_rate: 3125.50,       // 1 ETH to USD
  usd_to_lkr_rate: 322.50,        // 1 USD to LKR
  lkr_to_usd_rate: 0.0031,        // 1 LKR to USD
  exchange_rates_updated_at: Timestamp,
  exchange_rates_source: 'CoinGecko API'
}
```

## Usage Examples

### In Your Code

```javascript
const exchangeRateService = require("./services/exchangeRateService");

// Get current rates
const rates = exchangeRateService.getRates();
console.log("ETH to USD:", rates.ethToUsd);
console.log("ETH to LKR:", rates.ethToLkr);

// Convert amounts
const ethAmount = 1.5;
const usdAmount = exchangeRateService.convert(ethAmount, "ETH", "USD");
const lkrAmount = exchangeRateService.convert(ethAmount, "ETH", "LKR");

// Check service health
const status = exchangeRateService.getStatus();
console.log("Last update:", status.lastUpdate);
console.log("Healthy:", status.healthy);

// Force immediate update (admin only)
await exchangeRateService.forceUpdate();
```

### Using Currency Converter

```javascript
const currencyConverter = require("./utils/currencyConverter");

// Load rates (called automatically on server start)
await currencyConverter.loadRates();

// Convert LKR to ETH
const lkrAmount = 100000;
const ethAmount = currencyConverter.lkrToEth(lkrAmount);

// Convert ETH to LKR
const ethAmount = 1.0;
const lkrAmount = currencyConverter.ethToLkr(ethAmount);

// Format for display
const formatted = currencyConverter.format(ethAmount, "ETH");
// Output: "1.0000 ETH"
```

## API Endpoints

### Check Exchange Rate Status

```bash
GET /api/admin/exchange-rates/status
```

**Response:**

```json
{
  "success": true,
  "status": {
    "healthy": true,
    "lastUpdate": "2026-03-09T10:30:00.000Z",
    "rates": {
      "ethToUsd": 3125.5,
      "ethToLkr": 1008000.0,
      "usdToLkr": 322.58
    },
    "updateInterval": "5 minutes",
    "source": "CoinGecko API (free tier)"
  }
}
```

### Force Rate Update

```bash
POST /api/admin/exchange-rates/update
```

**Response:**

```json
{
  "success": true,
  "message": "Exchange rates updated successfully",
  "rates": {
    "ethToUsd": 3125.5,
    "ethToLkr": 1008000.0,
    "usdToLkr": 322.58,
    "lastUpdate": "2026-03-09T10:35:00.000Z"
  }
}
```

### View Rate History

```bash
GET /api/admin/exchange-rates/history?limit=50
```

**Response:**

```json
{
  "success": true,
  "count": 50,
  "history": [
    {
      "id": "ETH_USD",
      "from_currency": "ETH",
      "to_currency": "USD",
      "rate": 3125.5,
      "inverse_rate": 0.00032,
      "is_active": true,
      "source": "CoinGecko API",
      "updated_at": "2026-03-09T10:30:00.000Z"
    }
  ]
}
```

## Fallback Behavior

### When API Fails

1. **First failure**: Uses last known rates from Firebase
2. **No Firebase data**: Uses hardcoded fallback rates
3. **Automatic retry**: Continues trying on next scheduled update
4. **Logging**: All failures logged for monitoring

### Fallback Rates

```javascript
{
  ethToUsd: 3125.00,
  ethToLkr: 1007812.50,
  usdToLkr: 322.58
}
```

## Monitoring

### Server Logs

The service logs important events:

```
✅ Exchange Rate Service initialized (CoinGecko API)
💱 Live exchange rates: { ethToUsd: 3125.50, ethToLkr: 1008000.00, updateInterval: '5 minutes' }
Exchange rates updated successfully { ethToUsd: 3125.50, ethToLkr: 1008000.00, ... }
```

### Error Handling

```
⚠️ CoinGecko API rate limit exceeded, will retry later
❌ Failed to update exchange rates: [error details]
Using fallback exchange rates
```

## Testing

### Manual Test

```bash
# Start the backend server
cd backend
npm start

# In another terminal, test the API
curl http://localhost:3000/api/admin/exchange-rates/status

# Force an update
curl -X POST http://localhost:3000/api/admin/exchange-rates/update
```

### Integration Test

Create `test-exchange-rates.js`:

```javascript
const exchangeRateService = require("./src/services/exchangeRateService");

async function test() {
  console.log("Testing Exchange Rate Service...\n");

  // Initialize
  await exchangeRateService.initialize();

  // Get rates
  const rates = exchangeRateService.getRates();
  console.log("Current Rates:", rates);

  // Convert
  const ethAmount = 1.5;
  const usdAmount = exchangeRateService.convert(ethAmount, "ETH", "USD");
  console.log(`${ethAmount} ETH = ${usdAmount} USD`);

  // Status
  const status = exchangeRateService.getStatus();
  console.log("\nService Status:", status);

  // Stop
  exchangeRateService.stopPeriodicUpdates();
}

test().catch(console.error);
```

Run: `node test-exchange-rates.js`

## Troubleshooting

### Issue: Rates Not Updating

**Check:**

1. Internet connectivity
2. CoinGecko API status (https://status.coingecko.com)
3. Server logs for errors
4. Firebase connectivity

**Solution:**

```bash
# Check status
curl http://localhost:3000/api/admin/exchange-rates/status

# Force update
curl -X POST http://localhost:3000/api/admin/exchange-rates/update
```

### Issue: API Rate Limit

**Symptoms:** `CoinGecko API rate limit exceeded`

**Solution:**

- Wait for rate limit to reset (usually 1 minute)
- Service will automatically retry
- Consider increasing `updateInterval` if persistent

### Issue: Firebase Connection Failed

**Symptoms:** Rates not persisting, only in-memory

**Solution:**

- Check Firebase configuration
- Verify `FIREBASE_PROJECT_ID` in .env
- Service will continue with in-memory rates

## Migration from Hardcoded Rates

### Old Code (Hardcoded)

```javascript
// Old approach ❌
const lkrToEthRate = 0.0000031;
const usdToEthRate = 0.00032;
const ethToLkr = amount / lkrToEthRate;
```

### New Code (Live Rates)

```javascript
// New approach ✅
const exchangeRateService = require("./services/exchangeRateService");
const ethToLkr = exchangeRateService.convert(amount, "ETH", "LKR");
```

## Alternative APIs (Future)

If you need to switch from CoinGecko, here are alternatives:

1. **CryptoCompare** - https://www.cryptocompare.com/api/
2. **Binance API** - https://api.binance.com
3. **CoinCap API** - https://api.coincap.io
4. **CoinMarketCap** - https://coinmarketcap.com/api/ (requires API key)

## Performance Impact

- **Startup time**: +200-500ms (initial rate fetch)
- **Memory**: +1-2 MB (service and cache)
- **Network**: 1 API call every 5 minutes (~10 KB/call)
- **CPU**: Negligible (background updates)

## Security Considerations

1. **No API keys**: CoinGecko free tier doesn't require authentication
2. **Rate limiting**: Respects API limits (1 call/5 min)
3. **Fallback rates**: System continues working if API fails
4. **Admin only**: Force update endpoint should be admin-protected

## Benefits

✅ Always accurate prices  
✅ No manual rate updates needed  
✅ Automatic governance synchronization  
✅ Historical rate tracking  
✅ Resilient to API failures  
✅ Zero cost implementation

## Next Steps

1. ✅ Service integrated and running
2. ✅ Admin endpoints available
3. ⏳ Add authentication to admin endpoints
4. ⏳ Create admin dashboard UI
5. ⏳ Add email alerts for rate anomalies
6. ⏳ Implement rate change webhooks

---

**Documentation Version:** 1.0  
**Last Updated:** March 9, 2026  
**Maintained by:** SmartPepper Team
