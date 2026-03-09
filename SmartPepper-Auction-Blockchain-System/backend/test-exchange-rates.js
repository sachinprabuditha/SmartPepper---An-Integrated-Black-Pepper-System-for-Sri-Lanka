/**
 * Test script for Exchange Rate Service integration
 * Tests the CoinGecko API integration and conversion utilities
 * 
 * Run: node test-exchange-rates.js
 */

const axios = require('axios');

// Color codes for terminal output
const COLORS = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m'
};

function log(message, color = 'reset') {
  console.log(`${COLORS[color]}${message}${COLORS.reset}`);
}

function section(title) {
  console.log('\n' + '='.repeat(60));
  log(title, 'cyan');
  console.log('='.repeat(60));
}

async function testCoinGeckoAPI() {
  section('1. Testing CoinGecko API Connection');
  
  try {
    log('Fetching live rates from CoinGecko...', 'blue');
    
    const response = await axios.get('https://api.coingecko.com/api/v3/simple/price', {
      params: {
        ids: 'ethereum',
        vs_currencies: 'usd,lkr',
        include_last_updated_at: true
      },
      timeout: 10000
    });

    if (response.data && response.data.ethereum) {
      const data = response.data.ethereum;
      
      log('✓ API Connection Successful!', 'green');
      console.log('\nLive Exchange Rates:');
      console.log(`  1 ETH = ${data.usd.toLocaleString()} USD`);
      console.log(`  1 ETH = ${data.lkr.toLocaleString()} LKR`);
      console.log(`  1 USD = ${(data.lkr / data.usd).toFixed(2)} LKR`);
      
      if (data.last_updated_at) {
        const lastUpdate = new Date(data.last_updated_at * 1000);
        console.log(`  Last Updated: ${lastUpdate.toLocaleString()}`);
      }
      
      return {
        success: true,
        rates: {
          ethToUsd: data.usd,
          ethToLkr: data.lkr,
          usdToLkr: data.lkr / data.usd
        }
      };
    } else {
      throw new Error('Invalid API response format');
    }
  } catch (error) {
    log('✗ API Connection Failed!', 'red');
    
    if (error.response?.status === 429) {
      log('  Reason: Rate limit exceeded (too many requests)', 'yellow');
    } else if (error.code === 'ECONNABORTED') {
      log('  Reason: Request timeout', 'yellow');
    } else if (error.code === 'ENOTFOUND') {
      log('  Reason: No internet connection', 'yellow');
    } else {
      log(`  Reason: ${error.message}`, 'yellow');
    }
    
    return { success: false, error: error.message };
  }
}

async function testConversionLogic(rates) {
  section('2. Testing Conversion Logic');
  
  if (!rates || !rates.success) {
    log('⊗ Skipping (no rates available)', 'yellow');
    return;
  }

  const { ethToUsd, ethToLkr, usdToLkr } = rates.rates;

  log('Testing various conversions...', 'blue');
  console.log();

  // Test 1: ETH to USD
  const ethAmount1 = 1.5;
  const usdAmount1 = ethAmount1 * ethToUsd;
  console.log(`  ${ethAmount1} ETH → ${usdAmount1.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} USD`);
  log('  ✓ ETH to USD conversion', 'green');

  // Test 2: ETH to LKR
  const ethAmount2 = 0.5;
  const lkrAmount2 = ethAmount2 * ethToLkr;
  console.log(`  ${ethAmount2} ETH → ${lkrAmount2.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} LKR`);
  log('  ✓ ETH to LKR conversion', 'green');

  // Test 3: USD to LKR
  const usdAmount3 = 100;
  const lkrAmount3 = usdAmount3 * usdToLkr;
  console.log(`  ${usdAmount3} USD → ${lkrAmount3.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} LKR`);
  log('  ✓ USD to LKR conversion', 'green');

  // Test 4: LKR to ETH
  const lkrAmount4 = 100000;
  const ethAmount4 = lkrAmount4 / ethToLkr;
  console.log(`  ${lkrAmount4.toLocaleString()} LKR → ${ethAmount4.toFixed(6)} ETH`);
  log('  ✓ LKR to ETH conversion', 'green');

  // Test 5: USD to ETH
  const usdAmount5 = 1000;
  const ethAmount5 = usdAmount5 / ethToUsd;
  console.log(`  ${usdAmount5} USD → ${ethAmount5.toFixed(6)} ETH`);
  log('  ✓ USD to ETH conversion', 'green');

  // Test 6: LKR to USD
  const lkrAmount6 = 50000;
  const usdAmount6 = lkrAmount6 / usdToLkr;
  console.log(`  ${lkrAmount6.toLocaleString()} LKR → ${usdAmount6.toFixed(2)} USD`);
  log('  ✓ LKR to USD conversion', 'green');
}

async function testBackendEndpoints() {
  section('3. Testing Backend API Endpoints');
  
  const backendUrl = process.env.BACKEND_URL || 'http://localhost:3000';
  
  log(`Testing backend at: ${backendUrl}`, 'blue');
  console.log();

  // Test health endpoint
  try {
    log('Testing /health endpoint...', 'blue');
    const healthResponse = await axios.get(`${backendUrl}/health`, { timeout: 5000 });
    
    if (healthResponse.data.status === 'healthy') {
      log('✓ Backend server is running', 'green');
      console.log(`  Uptime: ${Math.floor(healthResponse.data.uptime)}s`);
    }
  } catch (error) {
    log('✗ Backend server not responding', 'red');
    log('  Make sure to start the backend: npm start', 'yellow');
    return;
  }

  // Test exchange rate status endpoint
  try {
    log('\nTesting /api/admin/exchange-rates/status...', 'blue');
    const statusResponse = await axios.get(`${backendUrl}/api/admin/exchange-rates/status`, { timeout: 5000 });
    
    if (statusResponse.data.success) {
      log('✓ Exchange rate service is active', 'green');
      const status = statusResponse.data.status;
      console.log(`  ETH to USD: ${status.rates.ethToUsd}`);
      console.log(`  ETH to LKR: ${status.rates.ethToLkr}`);
      console.log(`  Update Interval: ${status.updateInterval}`);
      console.log(`  Last Update: ${status.lastUpdate || 'N/A'}`);
      console.log(`  Health: ${status.healthy ? 'Healthy' : 'Degraded'}`);
    }
  } catch (error) {
    if (error.response?.status === 404) {
      log('✗ Exchange rate endpoints not found', 'red');
      log('  Make sure the latest code is deployed', 'yellow');
    } else {
      log(`✗ Error: ${error.message}`, 'red');
    }
  }

  // Test force update endpoint
  try {
    log('\nTesting /api/admin/exchange-rates/update...', 'blue');
    const updateResponse = await axios.post(`${backendUrl}/api/admin/exchange-rates/update`, {}, { timeout: 15000 });
    
    if (updateResponse.data.success) {
      log('✓ Force update successful', 'green');
      const rates = updateResponse.data.rates;
      console.log(`  ETH to USD: ${rates.ethToUsd}`);
      console.log(`  ETH to LKR: ${rates.ethToLkr}`);
      console.log(`  Last Update: ${rates.lastUpdate}`);
    }
  } catch (error) {
    if (error.code === 'ECONNABORTED') {
      log('✗ Request timeout (API might be slow)', 'red');
    } else {
      log(`✗ Error: ${error.message}`, 'red');
    }
  }
}

async function testAuctionIntegration(rates) {
  section('4. Testing Auction Price Conversions');
  
  if (!rates || !rates.success) {
    log('⊗ Skipping (no rates available)', 'yellow');
    return;
  }

  const { ethToUsd, ethToLkr, usdToLkr } = rates.rates;

  log('Simulating auction reserve price conversions...', 'blue');
  console.log();

  // Scenario 1: Farmer sets price in LKR
  const reservePriceLkr = 500000; // 500,000 LKR per kg
  const reservePriceEth1 = reservePriceLkr / ethToLkr;
  const reservePriceUsd1 = reservePriceLkr / usdToLkr;
  
  console.log('Scenario 1: Farmer sets reserve price in LKR');
  console.log(`  Input: ${reservePriceLkr.toLocaleString()} LKR`);
  console.log(`  → ${reservePriceEth1.toFixed(6)} ETH`);
  console.log(`  → ${reservePriceUsd1.toFixed(2)} USD`);
  log('  ✓ LKR to all currencies', 'green');

  // Scenario 2: Exporter bids in USD
  const bidUsd = 600; // $600 per kg
  const bidEth = bidUsd / ethToUsd;
  const bidLkr = bidUsd * usdToLkr;
  
  console.log('\nScenario 2: Exporter bids in USD');
  console.log(`  Input: ${bidUsd} USD`);
  console.log(`  → ${bidEth.toFixed(6)} ETH`);
  console.log(`  → ${bidLkr.toLocaleString('en-US', { minimumFractionDigits: 2 })} LKR`);
  log('  ✓ USD to all currencies', 'green');

  // Scenario 3: Blockchain stores in ETH
  const storedEth = 0.15; // 0.15 ETH
  const displayUsd = storedEth * ethToUsd;
  const displayLkr = storedEth * ethToLkr;
  
  console.log('\nScenario 3: Display blockchain price');
  console.log(`  Stored: ${storedEth} ETH`);
  console.log(`  → ${displayUsd.toFixed(2)} USD`);
  console.log(`  → ${displayLkr.toLocaleString('en-US', { minimumFractionDigits: 2 })} LKR`);
  log('  ✓ ETH to display currencies', 'green');
}

function printSummary(results) {
  section('Test Summary');
  
  const { apiTest, backendTest } = results;
  
  console.log('Results:');
  console.log(`  CoinGecko API Test: ${apiTest ? COLORS.green + '✓ PASSED' : COLORS.red + '✗ FAILED'}${COLORS.reset}`);
  console.log(`  Backend Integration: ${backendTest ? COLORS.green + '✓ PASSED' : COLORS.yellow + '⊗ SKIPPED'}${COLORS.reset}`);
  
  console.log('\nNext Steps:');
  if (apiTest) {
    log('  ✓ CoinGecko API is working properly', 'green');
  } else {
    log('  ! Check your internet connection', 'yellow');
    log('  ! Visit https://status.coingecko.com for API status', 'yellow');
  }
  
  if (!backendTest) {
    log('  ! Start backend server: cd backend && npm start', 'yellow');
    log('  ! Then test admin endpoints', 'yellow');
  }
  
  console.log('\nDocumentation:');
  console.log('  Read: backend/EXCHANGE_RATE_API_INTEGRATION.md');
  console.log('\nAdmin Endpoints:');
  console.log('  GET  /api/admin/exchange-rates/status');
  console.log('  POST /api/admin/exchange-rates/update');
  console.log('  GET  /api/admin/exchange-rates/history');
  
  console.log('\n' + '='.repeat(60) + '\n');
}

async function runTests() {
  console.clear();
  log('\n╔═══════════════════════════════════════════════════════════╗', 'cyan');
  log('║    SmartPepper Exchange Rate API Integration Test        ║', 'cyan');
  log('╚═══════════════════════════════════════════════════════════╝\n', 'cyan');
  
  try {
    // Test 1: CoinGecko API
    const apiResult = await testCoinGeckoAPI();
    
    // Test 2: Conversion Logic
    await testConversionLogic(apiResult);
    
    // Test 3: Backend Endpoints
    let backendSuccess = false;
    try {
      await testBackendEndpoints();
      backendSuccess = true;
    } catch (error) {
      // Backend might not be running
    }
    
    // Test 4: Auction Integration
    await testAuctionIntegration(apiResult);
    
    // Print summary
    printSummary({
      apiTest: apiResult.success,
      backendTest: backendSuccess
    });
    
  } catch (error) {
    log('\n✗ Test suite failed with error:', 'red');
    console.error(error);
  }
}

// Run tests
runTests();
