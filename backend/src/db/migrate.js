const db = require('./database');
const logger = require('../utils/logger');

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
    status VARCHAR(20) DEFAULT 'available',
    blockchain_tx_hash VARCHAR(66),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
  )`,

  // Auctions table
  `CREATE TABLE IF NOT EXISTS auctions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auction_id INTEGER UNIQUE NOT NULL,
    lot_id VARCHAR(50) REFERENCES pepper_lots(lot_id),
    farmer_id UUID REFERENCES users(id),
    farmer_address VARCHAR(42) NOT NULL,
    start_price DECIMAL(18, 8) NOT NULL,
    reserve_price DECIMAL(18, 8) NOT NULL,
    current_bid DECIMAL(18, 8) DEFAULT 0,
    current_bidder_address VARCHAR(42),
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    status VARCHAR(20) DEFAULT 'created',
    compliance_passed BOOLEAN DEFAULT false,
    bid_count INTEGER DEFAULT 0,
    escrow_amount DECIMAL(18, 8) DEFAULT 0,
    blockchain_tx_hash VARCHAR(66),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
  )`,

  // Bids table
  `CREATE TABLE IF NOT EXISTS bids (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auction_id INTEGER REFERENCES auctions(auction_id),
    bidder_id UUID REFERENCES users(id),
    bidder_address VARCHAR(42) NOT NULL,
    amount DECIMAL(18, 8) NOT NULL,
    blockchain_tx_hash VARCHAR(66),
    timestamp TIMESTAMPTZ DEFAULT NOW()
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

  // Create indexes
  `CREATE INDEX IF NOT EXISTS idx_users_wallet ON users(wallet_address)`,
  `CREATE INDEX IF NOT EXISTS idx_lots_farmer ON pepper_lots(farmer_address)`,
  `CREATE INDEX IF NOT EXISTS idx_lots_status ON pepper_lots(status)`,
  `CREATE INDEX IF NOT EXISTS idx_auctions_status ON auctions(status)`,
  `CREATE INDEX IF NOT EXISTS idx_auctions_end_time ON auctions(end_time)`,
  `CREATE INDEX IF NOT EXISTS idx_bids_auction ON bids(auction_id)`,
  `CREATE INDEX IF NOT EXISTS idx_bids_bidder ON bids(bidder_address)`,
  `CREATE INDEX IF NOT EXISTS idx_compliance_lot ON compliance_checks(lot_id)`
];

async function runMigrations() {
  try {
    logger.info('Starting database migrations...');
    
    for (let i = 0; i < migrations.length; i++) {
      await db.query(migrations[i]);
      logger.info(`Migration ${i + 1}/${migrations.length} completed`);
    }
    
    logger.info('All migrations completed successfully');
  } catch (error) {
    logger.error('Migration failed:', error);
    throw error;
  }
}

// Run migrations if called directly
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
