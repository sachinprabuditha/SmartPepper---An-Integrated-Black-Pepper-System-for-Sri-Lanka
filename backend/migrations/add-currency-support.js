const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'smartpepper',
  user: process.env.DB_USER || 'admin',
  password: process.env.DB_PASSWORD || 'admin'
});

async function runMigration() {
  const client = await pool.connect();
  
  try {
    console.log('🔄 Starting currency support migration...\n');
    
    await client.query('BEGIN');

    // 1. Add currency column to auctions table
    console.log('1️⃣ Adding currency column to auctions table...');
    await client.query(`
      ALTER TABLE auctions 
      ADD COLUMN IF NOT EXISTS currency VARCHAR(10) DEFAULT 'ETH',
      ADD COLUMN IF NOT EXISTS price_lkr NUMERIC(20, 2),
      ADD COLUMN IF NOT EXISTS current_bid_lkr NUMERIC(20, 2);
    `);
    console.log('✅ Currency columns added\n');

    // 2. Add currency column to bids table
    console.log('2️⃣ Adding currency column to bids table...');
    await client.query(`
      ALTER TABLE bids 
      ADD COLUMN IF NOT EXISTS currency VARCHAR(10) DEFAULT 'ETH',
      ADD COLUMN IF NOT EXISTS amount_lkr NUMERIC(20, 2);
    `);
    console.log('✅ Bid currency columns added\n');

    // 3. Create exchange_rates table for currency conversion
    console.log('3️⃣ Creating exchange_rates table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS exchange_rates (
        id SERIAL PRIMARY KEY,
        from_currency VARCHAR(10) NOT NULL,
        to_currency VARCHAR(10) NOT NULL,
        rate NUMERIC(20, 10) NOT NULL,
        updated_at TIMESTAMPTZ DEFAULT NOW(),
        source VARCHAR(50) DEFAULT 'manual',
        is_active BOOLEAN DEFAULT true,
        CONSTRAINT unique_currency_pair UNIQUE (from_currency, to_currency, is_active)
      );
    `);
    console.log('✅ Exchange rates table created\n');

    // 4. Insert default exchange rates
    console.log('4️⃣ Inserting default exchange rates...');
    await client.query(`
      INSERT INTO exchange_rates (from_currency, to_currency, rate, source)
      VALUES 
        ('LKR', 'ETH', 0.0000031, 'manual'),
        ('ETH', 'LKR', 322580.65, 'manual'),
        ('USD', 'ETH', 0.00032, 'manual'),
        ('ETH', 'USD', 3125.00, 'manual'),
        ('LKR', 'USD', 0.0031, 'manual'),
        ('USD', 'LKR', 322.58, 'manual')
      ON CONFLICT (from_currency, to_currency, is_active) 
      DO UPDATE SET 
        rate = EXCLUDED.rate,
        updated_at = NOW();
    `);
    console.log('✅ Default exchange rates inserted\n');

    // 5. Update existing auctions to have currency = 'ETH'
    console.log('5️⃣ Updating existing auctions...');
    await client.query(`
      UPDATE auctions 
      SET currency = 'ETH'
      WHERE currency IS NULL;
    `);
    console.log('✅ Existing auctions updated\n');

    // 6. Update existing bids to have currency = 'ETH'
    console.log('6️⃣ Updating existing bids...');
    await client.query(`
      UPDATE bids 
      SET currency = 'ETH'
      WHERE currency IS NULL;
    `);
    console.log('✅ Existing bids updated\n');

    // 7. Add governance column for LKR exchange rate
    console.log('7️⃣ Adding LKR exchange rate to governance settings...');
    
    // Check if column exists
    const columnCheck = await client.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'governance_settings' 
      AND column_name = 'lkr_to_eth_rate'
    `);
    
    if (columnCheck.rows.length === 0) {
      await client.query(`
        ALTER TABLE governance_settings 
        ADD COLUMN lkr_to_eth_rate NUMERIC(20, 10) DEFAULT 0.0000031;
      `);
    }
    
    // Update the rate value
    await client.query(`
      UPDATE governance_settings 
      SET lkr_to_eth_rate = 0.0000031
      WHERE id = 1;
    `);
    
    console.log('✅ Governance settings updated\n');

    await client.query('COMMIT');

    console.log('✅ Migration completed successfully!\n');
    console.log('📊 Currency support added:');
    console.log('  - Auctions can now store prices in LKR or ETH');
    console.log('  - Bids can be placed in either currency');
    console.log('  - Exchange rates table created');
    console.log('  - Default rates: 1 LKR ≈ 0.0000031 ETH (~320 LKR/USD, ~3100 USD/ETH)');
    console.log('\n✨ Database is ready for multi-currency support!');

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Migration failed:', error);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

runMigration().catch(err => {
  console.error('❌ Migration error:', err);
  process.exit(1);
});
