const db = require('../db/database');
const logger = require('./logger');

/**
 * Currency Converter Utility
 * Handles conversion between LKR, ETH, and USD
 */
class CurrencyConverter {
  constructor() {
    this.rates = {
      'LKR_TO_ETH': 0.0000031,
      'ETH_TO_LKR': 322580.65,
      'USD_TO_ETH': 0.00032,
      'ETH_TO_USD': 3125.00,
      'LKR_TO_USD': 0.0031,
      'USD_TO_LKR': 322.58
    };
    this.lastUpdate = null;
  }

  /**
   * Load exchange rates from database
   */
  async loadRates() {
    try {
      const result = await db.query(`
        SELECT from_currency, to_currency, rate 
        FROM exchange_rates 
        WHERE is_active = true
      `);

      result.rows.forEach(row => {
        const key = `${row.from_currency}_TO_${row.to_currency}`;
        this.rates[key] = parseFloat(row.rate);
      });

      this.lastUpdate = new Date();
      logger.info('Exchange rates loaded', { rates: this.rates });
    } catch (error) {
      logger.error('Failed to load exchange rates', error);
      // Continue with default rates
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
   * Update exchange rate in database
   */
  async updateRate(from, to, rate) {
    try {
      await db.query(`
        INSERT INTO exchange_rates (from_currency, to_currency, rate, updated_at)
        VALUES ($1, $2, $3, NOW())
        ON CONFLICT (from_currency, to_currency, is_active)
        DO UPDATE SET 
          rate = $3,
          updated_at = NOW()
      `, [from, to, rate]);

      // Update in-memory rate
      const key = `${from}_TO_${to}`;
      this.rates[key] = parseFloat(rate);

      logger.info('Exchange rate updated', { from, to, rate });
      return true;
    } catch (error) {
      logger.error('Failed to update exchange rate', error);
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
