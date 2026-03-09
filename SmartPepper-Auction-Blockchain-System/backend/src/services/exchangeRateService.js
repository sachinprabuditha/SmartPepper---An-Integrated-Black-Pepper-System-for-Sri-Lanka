const axios = require('axios');
const admin = require('firebase-admin');
const logger = require('../utils/logger');

/**
 * Exchange Rate Service
 * Fetches real-time exchange rates from CoinGecko API (Free, no API key required)
 * Updates Firebase with latest rates
 */
class ExchangeRateService {
  constructor() {
    this.API_BASE_URL = 'https://api.coingecko.com/api/v3';
    this.rates = {
      ethToUsd: null,
      ethToLkr: null,
      usdToLkr: null
    };
    this.lastUpdate = null;
    this.updateInterval = 5 * 60 * 1000; // Update every 5 minutes
    this.intervalId = null;
    
    // Fallback rates (used if API fails)
    this.fallbackRates = {
      ethToUsd: 3125.00,
      ethToLkr: 1007812.50, // Assuming 1 USD = 322.58 LKR
      usdToLkr: 322.58
    };
  }

  /**
   * Initialize the service and start periodic updates
   */
  async initialize() {
    try {
      logger.info('Initializing Exchange Rate Service...');
      
      // Fetch initial rates
      await this.updateRates();
      
      // Start periodic updates
      this.startPeriodicUpdates();
      
      logger.info('Exchange Rate Service initialized successfully', {
        updateInterval: `${this.updateInterval / 1000 / 60} minutes`
      });
    } catch (error) {
      logger.error('Failed to initialize Exchange Rate Service:', error.message);
      // Use fallback rates
      this.useFallbackRates();
    }
  }

  /**
   * Start periodic rate updates
   */
  startPeriodicUpdates() {
    if (this.intervalId) {
      clearInterval(this.intervalId);
    }

    this.intervalId = setInterval(async () => {
      try {
        await this.updateRates();
      } catch (error) {
        logger.error('Periodic rate update failed:', error.message);
      }
    }, this.updateInterval);

    logger.info('Periodic rate updates started');
  }

  /**
   * Stop periodic updates
   */
  stopPeriodicUpdates() {
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = null;
      logger.info('Periodic rate updates stopped');
    }
  }

  /**
   * Fetch latest exchange rates from CoinGecko API
   */
  async fetchRatesFromAPI() {
    try {
      // CoinGecko free API endpoint
      // Fetches ETH price in USD and LKR (Sri Lankan Rupee)
      const response = await axios.get(`${this.API_BASE_URL}/simple/price`, {
        params: {
          ids: 'ethereum',
          vs_currencies: 'usd,lkr',
          include_last_updated_at: true
        },
        timeout: 10000 // 10 second timeout
      });

      if (response.data && response.data.ethereum) {
        const data = response.data.ethereum;
        
        return {
          ethToUsd: data.usd,
          ethToLkr: data.lkr,
          usdToLkr: data.lkr / data.usd, // Calculate USD to LKR
          timestamp: data.last_updated_at ? new Date(data.last_updated_at * 1000) : new Date()
        };
      }

      throw new Error('Invalid response from CoinGecko API');
    } catch (error) {
      if (error.response?.status === 429) {
        logger.warn('CoinGecko API rate limit exceeded, will retry later');
      } else {
        logger.error('Error fetching rates from CoinGecko:', error.message);
      }
      throw error;
    }
  }

  /**
   * Update exchange rates (fetch from API and store in Firebase)
   */
  async updateRates() {
    try {
      logger.info('Fetching latest exchange rates from CoinGecko...');
      
      const ratesData = await this.fetchRatesFromAPI();
      
      // Update in-memory rates
      this.rates = {
        ethToUsd: ratesData.ethToUsd,
        ethToLkr: ratesData.ethToLkr,
        usdToLkr: ratesData.usdToLkr
      };
      this.lastUpdate = ratesData.timestamp;

      logger.info('Exchange rates updated successfully', {
        ethToUsd: ratesData.ethToUsd,
        ethToLkr: ratesData.ethToLkr,
        usdToLkr: ratesData.usdToLkr.toFixed(2),
        timestamp: ratesData.timestamp.toISOString()
      });

      // Store in Firebase for persistence
      await this.storeRatesInFirebase(ratesData);

      // Update governance settings
      await this.updateGovernanceSettings(ratesData);

      return this.rates;
    } catch (error) {
      logger.error('Failed to update exchange rates:', error.message);
      
      // Use fallback rates if no rates are set
      if (!this.rates.ethToUsd) {
        this.useFallbackRates();
      }
      
      throw error;
    }
  }

  /**
   * Store rates in Firebase exchange_rates collection
   */
  async storeRatesInFirebase(ratesData) {
    try {
      const firestore = admin.firestore();
      const batch = firestore.batch();

      // Store ETH to USD
      const ethUsdRef = firestore.collection('exchange_rates').doc('ETH_USD');
      batch.set(ethUsdRef, {
        from_currency: 'ETH',
        to_currency: 'USD',
        rate: ratesData.ethToUsd,
        inverse_rate: 1 / ratesData.ethToUsd,
        is_active: true,
        source: 'CoinGecko API',
        updated_at: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });

      // Store ETH to LKR
      const ethLkrRef = firestore.collection('exchange_rates').doc('ETH_LKR');
      batch.set(ethLkrRef, {
        from_currency: 'ETH',
        to_currency: 'LKR',
        rate: ratesData.ethToLkr,
        inverse_rate: 1 / ratesData.ethToLkr,
        is_active: true,
        source: 'CoinGecko API',
        updated_at: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });

      // Store USD to LKR
      const usdLkrRef = firestore.collection('exchange_rates').doc('USD_LKR');
      batch.set(usdLkrRef, {
        from_currency: 'USD',
        to_currency: 'LKR',
        rate: ratesData.usdToLkr,
        inverse_rate: 1 / ratesData.usdToLkr,
        is_active: true,
        source: 'CoinGecko API',
        updated_at: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });

      // Also store inverse rates for convenience
      const usdEthRef = firestore.collection('exchange_rates').doc('USD_ETH');
      batch.set(usdEthRef, {
        from_currency: 'USD',
        to_currency: 'ETH',
        rate: 1 / ratesData.ethToUsd,
        inverse_rate: ratesData.ethToUsd,
        is_active: true,
        source: 'CoinGecko API',
        updated_at: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });

      const lkrEthRef = firestore.collection('exchange_rates').doc('LKR_ETH');
      batch.set(lkrEthRef, {
        from_currency: 'LKR',
        to_currency: 'ETH',
        rate: 1 / ratesData.ethToLkr,
        inverse_rate: ratesData.ethToLkr,
        is_active: true,
        source: 'CoinGecko API',
        updated_at: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });

      const lkrUsdRef = firestore.collection('exchange_rates').doc('LKR_USD');
      batch.set(lkrUsdRef, {
        from_currency: 'LKR',
        to_currency: 'USD',
        rate: 1 / ratesData.usdToLkr,
        inverse_rate: ratesData.usdToLkr,
        is_active: true,
        source: 'CoinGecko API',
        updated_at: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });

      await batch.commit();
      logger.info('Exchange rates stored in Firebase successfully');
    } catch (error) {
      logger.error('Failed to store rates in Firebase:', error.message);
      // Don't throw - this is not critical
    }
  }

  /**
   * Update governance settings with latest rates
   */
  async updateGovernanceSettings(ratesData) {
    try {
      const firestore = admin.firestore();
      const settingsSnapshot = await firestore.collection('governance_settings').limit(1).get();

      if (!settingsSnapshot.empty) {
        const settingsDoc = settingsSnapshot.docs[0];
        await settingsDoc.ref.update({
          lkr_to_eth_rate: 1 / ratesData.ethToLkr,
          usd_to_eth_rate: 1 / ratesData.ethToUsd,
          eth_to_lkr_rate: ratesData.ethToLkr,
          eth_to_usd_rate: ratesData.ethToUsd,
          usd_to_lkr_rate: ratesData.usdToLkr,
          lkr_to_usd_rate: 1 / ratesData.usdToLkr,
          exchange_rates_updated_at: admin.firestore.FieldValue.serverTimestamp(),
          exchange_rates_source: 'CoinGecko API'
        });
        logger.info('Governance settings updated with latest rates');
      }
    } catch (error) {
      logger.error('Failed to update governance settings:', error.message);
      // Don't throw - this is not critical
    }
  }

  /**
   * Use fallback rates when API is unavailable
   */
  useFallbackRates() {
    logger.warn('Using fallback exchange rates');
    this.rates = { ...this.fallbackRates };
    this.lastUpdate = new Date();
  }

  /**
   * Get current exchange rates
   */
  getRates() {
    return {
      ...this.rates,
      lastUpdate: this.lastUpdate
    };
  }

  /**
   * Get specific rate
   */
  getRate(from, to) {
    const key = `${from.toLowerCase()}To${to.charAt(0).toUpperCase() + to.slice(1).toLowerCase()}`;
    
    if (this.rates[key]) {
      return this.rates[key];
    }

    // Try inverse
    const inverseKey = `${to.toLowerCase()}To${from.charAt(0).toUpperCase() + from.slice(1).toLowerCase()}`;
    if (this.rates[inverseKey]) {
      return 1 / this.rates[inverseKey];
    }

    logger.warn(`No rate found for ${from} to ${to}`);
    return null;
  }

  /**
   * Convert amount between currencies
   */
  convert(amount, from, to) {
    if (from === to) return amount;

    const rate = this.getRate(from, to);
    if (!rate) {
      throw new Error(`Cannot convert ${from} to ${to}: rate not available`);
    }

    return amount * rate;
  }

  /**
   * Force immediate rate update (useful for admin endpoints)
   */
  async forceUpdate() {
    logger.info('Forcing immediate rate update...');
    return await this.updateRates();
  }

  /**
   * Get service health status
   */
  getStatus() {
    return {
      healthy: !!this.rates.ethToUsd,
      lastUpdate: this.lastUpdate,
      rates: this.rates,
      updateInterval: `${this.updateInterval / 1000 / 60} minutes`,
      source: 'CoinGecko API (free tier)'
    };
  }
}

// Export singleton instance
const exchangeRateService = new ExchangeRateService();
module.exports = exchangeRateService;
