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
    origin VARCHAR(255),
    farm_location TEXT,
    organic_certified BOOLEAN DEFAULT false,
    metadata_uri TEXT,
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

  // Processing stages table (for traceability)
  `CREATE TABLE IF NOT EXISTS processing_stages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lot_id VARCHAR(50) REFERENCES pepper_lots(lot_id),
    stage_type VARCHAR(50) NOT NULL CHECK (stage_type IN ('harvest', 'drying', 'grading', 'packaging', 'storage')),
    stage_name VARCHAR(100) NOT NULL,
    location TEXT,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    operator_name VARCHAR(255),
    quality_metrics JSONB,
    notes TEXT,
    blockchain_tx_hash VARCHAR(66),
    created_at TIMESTAMPTZ DEFAULT NOW()
  )`,

  // Certifications table
  `CREATE TABLE IF NOT EXISTS certifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lot_id VARCHAR(50) REFERENCES pepper_lots(lot_id),
    cert_type VARCHAR(50) NOT NULL CHECK (cert_type IN ('organic', 'fumigation', 'export', 'quality', 'phytosanitary', 'pesticide_test', 'halal', 'origin')),
    cert_number VARCHAR(100) NOT NULL,
    issuer VARCHAR(255) NOT NULL,
    issue_date DATE NOT NULL,
    expiry_date DATE NOT NULL,
    document_hash VARCHAR(66),
    ipfs_url TEXT,
    is_valid BOOLEAN DEFAULT true,
    verification_status VARCHAR(20) DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'rejected', 'expired')),
    verified_by VARCHAR(255),
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
  )`,

  // Compliance rules table (for rule engine)
  `CREATE TABLE IF NOT EXISTS compliance_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_code VARCHAR(50) UNIQUE NOT NULL,
    rule_name VARCHAR(255) NOT NULL,
    destination_country VARCHAR(100),
    rule_category VARCHAR(50) CHECK (rule_category IN ('certification', 'packaging', 'labeling', 'quality', 'documentation')),
    rule_definition JSONB NOT NULL,
    is_active BOOLEAN DEFAULT true,
    severity VARCHAR(20) DEFAULT 'critical' CHECK (severity IN ('critical', 'major', 'minor', 'warning')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
  )`,

  // Create indexes
  `CREATE INDEX IF NOT EXISTS idx_users_wallet ON users(wallet_address)`,
  `CREATE INDEX IF NOT EXISTS idx_lots_farmer ON pepper_lots(farmer_address)`,
  `CREATE INDEX IF NOT EXISTS idx_lots_status ON pepper_lots(status)`,
  `CREATE INDEX IF NOT EXISTS idx_auctions_status ON auctions(status)`,
  `CREATE INDEX IF NOT EXISTS idx_auctions_end_time ON auctions(end_time)`,
  `CREATE INDEX IF NOT EXISTS idx_bids_auction ON bids(auction_id)`,
  `CREATE INDEX IF NOT EXISTS idx_bids_bidder ON bids(bidder_address)`,
  `CREATE INDEX IF NOT EXISTS idx_compliance_lot ON compliance_checks(lot_id)`,
  `CREATE INDEX IF NOT EXISTS idx_processing_lot ON processing_stages(lot_id)`,
  `CREATE INDEX IF NOT EXISTS idx_processing_stage ON processing_stages(stage_type)`,
  `CREATE INDEX IF NOT EXISTS idx_certifications_lot ON certifications(lot_id)`,
  `CREATE INDEX IF NOT EXISTS idx_certifications_type ON certifications(cert_type)`,
  `CREATE INDEX IF NOT EXISTS idx_certifications_expiry ON certifications(expiry_date)`,
  `CREATE INDEX IF NOT EXISTS idx_compliance_rules_country ON compliance_rules(destination_country)`,
  `CREATE INDEX IF NOT EXISTS idx_compliance_rules_category ON compliance_rules(rule_category)`,

  // Add new columns to pepper_lots table (for existing databases)
  `ALTER TABLE pepper_lots 
   ADD COLUMN IF NOT EXISTS origin VARCHAR(255),
   ADD COLUMN IF NOT EXISTS farm_location TEXT,
   ADD COLUMN IF NOT EXISTS organic_certified BOOLEAN DEFAULT false,
   ADD COLUMN IF NOT EXISTS metadata_uri TEXT`,

  // Update status constraint to include 'available'
  `ALTER TABLE pepper_lots DROP CONSTRAINT IF EXISTS pepper_lots_status_check`,
  `ALTER TABLE pepper_lots 
   ADD CONSTRAINT pepper_lots_status_check 
   CHECK (status IN ('created', 'available', 'pending_compliance', 'approved', 'rejected', 'auctioned'))`,

  // Add compliance_status column to pepper_lots
  `ALTER TABLE pepper_lots ADD COLUMN IF NOT EXISTS compliance_status VARCHAR(20) DEFAULT 'pending' CHECK (compliance_status IN ('pending', 'checking', 'passed', 'failed'))`,
  `ALTER TABLE pepper_lots ADD COLUMN IF NOT EXISTS compliance_checked_at TIMESTAMPTZ`
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
