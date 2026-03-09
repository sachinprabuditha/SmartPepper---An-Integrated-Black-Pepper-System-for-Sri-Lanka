const admin = require('firebase-admin');
const logger = require('./logger');

/**
 * Currency Converter Utility
 * Handles conversion between LKR, ETH, and USD
 * Now uses ExchangeRateService for real-time rates from CoinGecko API
 */
class CurrencyConverter {
  constructor() {
    // Fallback rates (used only if exchange rate service is unavailable)
    this.fallbackRates = {
      'LKR_TO_ETH': 0.0000031,
      'ETH_TO_LKR': 322580.65,
      'USD_TO_ETH': 0.00032,
      'ETH_TO_USD': 3125.00,
      'LKR_TO_USD': 0.0031,
      'USD_TO_LKR': 322.58
    };
    this.rates = { ...this.fallbackRates };
    this.lastUpdate = null;
    this.exchangeRateService = null;
  }

  /**
   * Initialize with exchange rate service
   */
  setExchangeRateService(service) {
    this.exchangeRateService = service;
    logger.info('Currency converter linked to exchange rate service');
  }

  /**
   * Load exchange rates from Firebase and Exchange Rate Service
   */
  async loadRates() {
    try {
      // First, try to get rates from the live exchange rate service
      if (this.exchangeRateService) {
        const liveRates = this.exchangeRateService.getRates();
        
        if (liveRates.ethToUsd && liveRates.ethToLkr && liveRates.usdToLkr) {
          this.rates = {
            'ETH_TO_USD': liveRates.ethToUsd,
            'USD_TO_ETH': 1 / liveRates.ethToUsd,
            'ETH_TO_LKR': liveRates.ethToLkr,
            'LKR_TO_ETH': 1 / liveRates.ethToLkr,
            'USD_TO_LKR': liveRates.usdToLkr,
            'LKR_TO_USD': 1 / liveRates.usdToLkr
          };
          this.lastUpdate = liveRates.lastUpdate;
          logger.info('Exchange rates loaded from live API', {
            ethToUsd: liveRates.ethToUsd,
            ethToLkr: liveRates.ethToLkr,
            lastUpdate: this.lastUpdate
          });
          return;
        }
      }

      // Fallback: Load from Firebase
      const firestore = admin.firestore();
      const snapshot = await firestore.collection('exchange_rates')
        .where('is_active', '==', true)
        .get();

      if (!snapshot.empty) {
        snapshot.forEach(doc => {
          const data = doc.data();
          const key = `${data.from_currency}_TO_${data.to_currency}`;
          this.rates[key] = parseFloat(data.rate);
        });

        this.lastUpdate = new Date();
        logger.info('Exchange rates loaded from Firebase', { count: snapshot.size });
      } else {
        logger.info('No exchange rates available, using fallback rates');
        this.rates = { ...this.fallbackRates };
      }
    } catch (error) {
      logger.warn('Failed to load exchange rates, using fallback:', error.message);
      this.rates = { ...this.fallbackRates };
    }
  }

  /**
   * Convert amount from one currency to another
   * @param {number} amount - Amount to convert
   * @param {string} from - Source currency (LKR, ETH, USD)
   * @param {string} to - Target currency (LKR, ETH, USD)
   * @returns {number} - Converted amount
   */
  convert(amount, from, to) {
    if (from === to) return amount;

    const key = `${from}_TO_${to}`;
    const rate = this.rates[key];

    if (!rate) {
      logger.warn(`No exchange rate found for ${from} to ${to}`, { available: Object.keys(this.rates) });
      return amount; // Return original amount if rate not found
    }

    return amount * rate;
  }

  /**
   * Convert LKR to ETH
   */
  lkrToEth(amountLKR) {
    return this.convert(amountLKR, 'LKR', 'ETH');
  }

  /**
   * Convert ETH to LKR
   */
  ethToLkr(amountETH) {
    return this.convert(amountETH, 'ETH', 'LKR');
  }

  /**
   * Get current exchange rate
   */
  getRate(from, to) {
    const key = `${from}_TO_${to}`;
    return this.rates[key] || null;
  }

  /**
   * Update exchange rate in Firebase
   */
  async updateRate(from, to, rate) {
    try {
      const firestore = admin.firestore();
      const rateId = `${from}_${to}`;
      
      await firestore.collection('exchange_rates').doc(rateId).set({
        from_currency: from,
        to_currency: to,
        rate: parseFloat(rate),
        is_active: true,
        updated_at: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });

      // Update in-memory rate
      const key = `${from}_TO_${to}`;
      this.rates[key] = parseFloat(rate);

      logger.info('Exchange rate updated in Firebase', { from, to, rate });
      return true;
    } catch (error) {
      logger.error('Failed to update exchange rate:', error.message);
      return false;
    }
  }

  /**
   * Format amount with currency symbol
   */
  format(amount, currency) {
    const decimals = currency === 'ETH' ? 4 : 2;
    const formatted = parseFloat(amount).toFixed(decimals);

    switch (currency) {
      case 'ETH':
        return `${formatted} ETH`;
      case 'LKR':
        return `LKR ${formatted}`;
      case 'USD':
        return `$${formatted}`;
      default:
        return `${formatted} ${currency}`;
    }
  }

  /**
   * Get all current rates
   */
  getAllRates() {
    return {
      ...this.rates,
      lastUpdate: this.lastUpdate
    };
  }
}

// Export singleton instance
const converter = new CurrencyConverter();
module.exports = converter;
