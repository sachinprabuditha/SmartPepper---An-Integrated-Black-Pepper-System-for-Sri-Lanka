/**
 * Exchange Rate Service for Web UI
 * Fetches live exchange rates from backend
 */

interface ExchangeRates {
  ethToUsd: number;
  ethToLkr: number;
  usdToLkr: number;
  lkrToEth: number;
  usdToEth: number;
  lkrToUsd: number;
  lastUpdate: string | null;
  source: string;
}

interface RateStatus {
  healthy: boolean;
  lastUpdate: string | null;
  rates: {
    ethToUsd: number;
    ethToLkr: number;
    usdToLkr: number;
  };
  updateInterval: string;
  source: string;
}

class ExchangeRateService {
  private static instance: ExchangeRateService;
  private rates: ExchangeRates | null = null;
  private updateInterval: NodeJS.Timeout | null = null;
  private apiBaseUrl: string;
  
  // Fallback rates (used if API fails)
  private fallbackRates: ExchangeRates = {
    ethToUsd: 3125.00,
    ethToLkr: 1007812.50,
    usdToLkr: 322.58,
    lkrToEth: 0.0000031,
    usdToEth: 0.00032,
    lkrToUsd: 0.0031,
    lastUpdate: null,
    source: 'Fallback'
  };

  private constructor() {
    this.apiBaseUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';
  }

  static getInstance(): ExchangeRateService {
    if (!ExchangeRateService.instance) {
      ExchangeRateService.instance = new ExchangeRateService();
    }
    return ExchangeRateService.instance;
  }

  /**
   * Initialize the service and start periodic updates
   */
  async initialize(): Promise<void> {
    await this.fetchRates();
    
    // Update every 5 minutes
    this.updateInterval = setInterval(() => {
      this.fetchRates().catch(console.error);
    }, 5 * 60 * 1000);
  }

  /**
   * Stop periodic updates
   */
  stopUpdates(): void {
    if (this.updateInterval) {
      clearInterval(this.updateInterval);
      this.updateInterval = null;
    }
  }

  /**
   * Fetch latest rates from backend
   */
  async fetchRates(): Promise<ExchangeRates> {
    try {
      const response = await fetch(`${this.apiBaseUrl}/api/admin/exchange-rates/status`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      const data = await response.json();

      if (data.success && data.status.rates) {
        const apiRates = data.status.rates;
        
        this.rates = {
          ethToUsd: apiRates.ethToUsd,
          ethToLkr: apiRates.ethToLkr,
          usdToLkr: apiRates.usdToLkr,
          lkrToEth: 1 / apiRates.ethToLkr,
          usdToEth: 1 / apiRates.ethToUsd,
          lkrToUsd: 1 / apiRates.usdToLkr,
          lastUpdate: data.status.lastUpdate,
          source: data.status.source
        };

        console.log('✅ Exchange rates loaded:', {
          ethToUsd: this.rates.ethToUsd,
          ethToLkr: this.rates.ethToLkr,
          lastUpdate: this.rates.lastUpdate
        });

        return this.rates;
      }

      throw new Error('Invalid response format');
    } catch (error) {
      console.warn('⚠️ Failed to fetch exchange rates, using fallback:', error);
      
      if (!this.rates) {
        this.rates = { ...this.fallbackRates };
      }
      
      return this.rates;
    }
  }

  /**
   * Get current exchange rates
   */
  getRates(): ExchangeRates {
    if (!this.rates) {
      console.warn('Exchange rates not loaded yet, using fallback');
      return { ...this.fallbackRates };
    }
    return this.rates;
  }

  /**
   * Convert amount between currencies
   */
  convert(amount: number, from: 'ETH' | 'USD' | 'LKR', to: 'ETH' | 'USD' | 'LKR'): number {
    if (from === to) return amount;

    const rates = this.getRates();
    const key = `${from.toLowerCase()}To${to.charAt(0) + to.slice(1).toLowerCase()}` as keyof ExchangeRates;
    
    const rate = rates[key];
    if (typeof rate === 'number') {
      return amount * rate;
    }

    console.error(`No conversion rate found for ${from} to ${to}`);
    return amount;
  }

  /**
   * ETH to LKR conversion
   */
  ethToLkr(ethAmount: number): number {
    return this.convert(ethAmount, 'ETH', 'LKR');
  }

  /**
   * LKR to ETH conversion
   */
  lkrToEth(lkrAmount: number): number {
    return this.convert(lkrAmount, 'LKR', 'ETH');
  }

  /**
   * ETH to USD conversion
   */
  ethToUsd(ethAmount: number): number {
    return this.convert(ethAmount, 'ETH', 'USD');
  }

  /**
   * USD to ETH conversion
   */
  usdToEth(usdAmount: number): number {
    return this.convert(usdAmount, 'USD', 'ETH');
  }

  /**
   * Format amount with currency symbol
   */
  formatLkr(amount: number): string {
    return new Intl.NumberFormat('en-LK', {
      style: 'currency',
      currency: 'LKR',
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }).format(amount);
  }

  formatEth(amount: number): string {
    return `${amount.toFixed(4)} ETH`;
  }

  formatUsd(amount: number): string {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }).format(amount);
  }

  /**
   * Check if rates are healthy
   */
  isHealthy(): boolean {
    if (!this.rates || !this.rates.lastUpdate) {
      return false;
    }

    const lastUpdate = new Date(this.rates.lastUpdate);
    const now = new Date();
    const minutesSinceUpdate = (now.getTime() - lastUpdate.getTime()) / (1000 * 60);

    // Consider healthy if updated within last 15 minutes
    return minutesSinceUpdate < 15;
  }

  /**
   * Get rate status for display
   */
  getStatus(): { healthy: boolean; lastUpdate: string | null; source: string } {
    const rates = this.getRates();
    return {
      healthy: this.isHealthy(),
      lastUpdate: rates.lastUpdate,
      source: rates.source
    };
  }
}

// Export singleton instance
export const exchangeRateService = ExchangeRateService.getInstance();
export default exchangeRateService;
