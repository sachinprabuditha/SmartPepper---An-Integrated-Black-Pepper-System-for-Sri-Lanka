const { Pool } = require('pg');
const logger = require('../utils/logger');
require('dotenv').config();

// Direct PostgreSQL connection (bypassing the mock database wrapper)
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'smartpepper',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || '',
});

const migrations = [
  // Users table
  `CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wallet_address VARCHAR(42) UNIQUE NOT NULL,
    user_type VARCHAR(20) NOT NULL CHECK (user_type IN ('farmer', 'buyer', 'exporter', 'regulator')),
    name VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(20),
    location JSONB,
    verified BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
  )`,

  // Pepper lots table
  `CREATE TABLE IF NOT EXISTS pepper_lots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lot_id VARCHAR(50) UNIQUE NOT NULL,
    farmer_id UUID REFERENCES users(id),
    farmer_address VARCHAR(42) NOT NULL,
    variety VARCHAR(100) NOT NULL,
    quantity DECIMAL(10, 2) NOT NULL,
    quality VARCHAR(50),
    harvest_date DATE,
    certificate_hash VARCHAR(66),
    certificate_ipfs_url TEXT,
    status VARCHAR(20) DEFAULT 'created' CHECK (status IN ('created', 'pending_compliance', 'approved', 'rejected', 'auctioned')),
    blockchain_tx_hash VARCHAR(66),
    created_at TIMESTAMPTZ DEFAULT NOW()
  )`,

  // Auctions table
  `CREATE TABLE IF NOT EXISTS auctions (
    auction_id SERIAL PRIMARY KEY,
    lot_id VARCHAR(50) REFERENCES pepper_lots(lot_id),
    farmer_address VARCHAR(42) NOT NULL,
    start_price VARCHAR(100) NOT NULL,
    reserve_price VARCHAR(100) NOT NULL,
    current_bid VARCHAR(100) DEFAULT '0',
    current_bidder VARCHAR(42),
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    status VARCHAR(20) DEFAULT 'created' CHECK (status IN ('created', 'active', 'ended', 'settled', 'failed_compliance')),
    compliance_passed BOOLEAN DEFAULT false,
    bid_count INTEGER DEFAULT 0,
    blockchain_tx_hash VARCHAR(66),
    created_at TIMESTAMPTZ DEFAULT NOW()
  )`,

  // Bids table
  `CREATE TABLE IF NOT EXISTS bids (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auction_id INTEGER REFERENCES auctions(auction_id),
    bidder_address VARCHAR(42) NOT NULL,
    amount VARCHAR(100) NOT NULL,
    blockchain_tx_hash VARCHAR(66),
    placed_at TIMESTAMPTZ DEFAULT NOW()
  )`,

  // Compliance checks table
  `CREATE TABLE IF NOT EXISTS compliance_checks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lot_id VARCHAR(50) REFERENCES pepper_lots(lot_id),
    auction_id INTEGER REFERENCES auctions(auction_id),
    rule_name VARCHAR(100) NOT NULL,
    rule_type VARCHAR(50) NOT NULL,
    passed BOOLEAN NOT NULL,
    details JSONB,
    checked_at TIMESTAMPTZ DEFAULT NOW()
  )`,

  // Indexes
  `CREATE INDEX IF NOT EXISTS idx_users_wallet ON users(wallet_address)`,
  `CREATE INDEX IF NOT EXISTS idx_lots_farmer ON pepper_lots(farmer_address)`,
  `CREATE INDEX IF NOT EXISTS idx_lots_status ON pepper_lots(status)`,
  `CREATE INDEX IF NOT EXISTS idx_auctions_status ON auctions(status)`,
  `CREATE INDEX IF NOT EXISTS idx_auctions_end_time ON auctions(end_time)`,
  `CREATE INDEX IF NOT EXISTS idx_bids_auction ON bids(auction_id)`,
  `CREATE INDEX IF NOT EXISTS idx_bids_bidder ON bids(bidder_address)`,
  `CREATE INDEX IF NOT EXISTS idx_compliance_lot ON compliance_checks(lot_id)`,
];

async function runMigrations() {
  try {
    logger.info('Starting database migrations...');
    
    // Test connection
    await pool.query('SELECT NOW()');
    logger.info('✅ Database connection successful');

    for (let i = 0; i < migrations.length; i++) {
      const migration = migrations[i];
      logger.info(`Running migration ${i + 1}/${migrations.length}...`);
      await pool.query(migration);
      logger.info(`✅ Migration ${i + 1}/${migrations.length} completed`);
    }

    logger.info('✅ All migrations completed successfully');
    
  } catch (error) {
    logger.error('Migration failed:', error);
    throw error;
  } finally {
    await pool.end();
    logger.info('Database connection closed');
  }
}

if (require.main === module) {
  runMigrations()
    .then(() => {
      logger.info('Migration script completed');
      process.exit(0);
    })
    .catch((error) => {
      logger.error('Migration script failed:', error);
      process.exit(1);
    });
}

module.exports = { runMigrations };
