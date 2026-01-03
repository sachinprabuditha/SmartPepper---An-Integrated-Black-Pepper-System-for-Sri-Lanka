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
    console.log('🔄 Starting bidding system migration...\n');
    
    await client.query('BEGIN');

    // 1. Check if bids table exists and drop it for clean migration
    console.log('1️⃣ Preparing bids table...');
    const checkBids = await client.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_name = 'bids'
      );
    `);
    
    if (checkBids.rows[0].exists) {
      console.log('  ⚠️  Existing bids table found - dropping for clean migration');
      await client.query('DROP TABLE IF EXISTS bids CASCADE;');
    }
    
    await client.query(`
      CREATE TABLE bids (
        id SERIAL PRIMARY KEY,
        auction_id INTEGER NOT NULL,
        bidder_address VARCHAR(42) NOT NULL,
        bidder_name VARCHAR(255),
        amount NUMERIC(20, 8) NOT NULL,
        status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'refunded', 'won')),
        transaction_hash VARCHAR(66),
        placed_at TIMESTAMPTZ DEFAULT NOW(),
        CONSTRAINT fk_auction FOREIGN KEY (auction_id) REFERENCES auctions(auction_id) ON DELETE CASCADE
      );
    `);
    console.log('✅ Bids table created\n');

    // 2. Create escrow_deposits table
    console.log('2️⃣ Creating escrow_deposits table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS escrow_deposits (
        id SERIAL PRIMARY KEY,
        auction_id INTEGER NOT NULL UNIQUE,
        depositor_address VARCHAR(42) NOT NULL,
        amount NUMERIC(20, 8) NOT NULL,
        transaction_hash VARCHAR(66) NOT NULL,
        status VARCHAR(20) DEFAULT 'locked' CHECK (status IN ('locked', 'released', 'refunded', 'disputed')),
        deposited_at TIMESTAMPTZ DEFAULT NOW(),
        released_at TIMESTAMPTZ,
        released_to VARCHAR(42),
        release_tx_hash VARCHAR(66),
        notes TEXT,
        CONSTRAINT fk_auction_escrow FOREIGN KEY (auction_id) REFERENCES auctions(auction_id) ON DELETE CASCADE
      );
    `);
    console.log('✅ Escrow deposits table created\n');

    // 3. Create auction_settlements table
    console.log('3️⃣ Creating auction_settlements table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS auction_settlements (
        id SERIAL PRIMARY KEY,
        auction_id INTEGER NOT NULL UNIQUE,
        farmer_address VARCHAR(42) NOT NULL,
        buyer_address VARCHAR(42) NOT NULL,
        final_amount NUMERIC(20, 8) NOT NULL,
        platform_fee NUMERIC(20, 8) NOT NULL,
        farmer_payout NUMERIC(20, 8) NOT NULL,
        settlement_tx_hash VARCHAR(66),
        settlement_timestamp TIMESTAMPTZ DEFAULT NOW(),
        compliance_approved BOOLEAN DEFAULT false,
        shipment_confirmed BOOLEAN DEFAULT false,
        delivery_confirmed BOOLEAN DEFAULT false,
        status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'disputed')),
        notes TEXT,
        CONSTRAINT fk_auction_settlement FOREIGN KEY (auction_id) REFERENCES auctions(auction_id) ON DELETE CASCADE
      );
    `);
    console.log('✅ Auction settlements table created\n');

    // 4. Create auction_cancellations table (for failures and disputes)
    console.log('4️⃣ Creating auction_cancellations table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS auction_cancellations (
        id SERIAL PRIMARY KEY,
        auction_id INTEGER NOT NULL,
        cancelled_by VARCHAR(42) NOT NULL,
        cancellation_reason VARCHAR(50) NOT NULL CHECK (cancellation_reason IN (
          'no_valid_bids',
          'escrow_not_deposited',
          'compliance_failure',
          'shipment_failure',
          'admin_emergency',
          'fraud_detected',
          'quality_dispute',
          'delivery_failure',
          'other'
        )),
        detailed_reason TEXT,
        escrow_refunded BOOLEAN DEFAULT false,
        refund_tx_hash VARCHAR(66),
        cancelled_at TIMESTAMPTZ DEFAULT NOW(),
        resolved BOOLEAN DEFAULT false,
        resolution_notes TEXT,
        CONSTRAINT fk_auction_cancellation FOREIGN KEY (auction_id) REFERENCES auctions(auction_id) ON DELETE CASCADE
      );
    `);
    console.log('✅ Auction cancellations table created\n');

    // 5. Add new columns to auctions table
    console.log('5️⃣ Adding bidding-related columns to auctions table...');
    
    // Check and add escrow_locked column
    const escrowLockedCheck = await client.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'auctions' AND column_name = 'escrow_locked'
    `);
    
    if (escrowLockedCheck.rows.length === 0) {
      await client.query(`
        ALTER TABLE auctions ADD COLUMN escrow_locked BOOLEAN DEFAULT false;
      `);
      console.log('  ✓ Added escrow_locked column');
    }

    // Check and add escrow_tx_hash column
    const escrowTxCheck = await client.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'auctions' AND column_name = 'escrow_tx_hash'
    `);
    
    if (escrowTxCheck.rows.length === 0) {
      await client.query(`
        ALTER TABLE auctions ADD COLUMN escrow_tx_hash VARCHAR(66);
      `);
      console.log('  ✓ Added escrow_tx_hash column');
    }

    // Check and add settlement_tx_hash column
    const settlementTxCheck = await client.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'auctions' AND column_name = 'settlement_tx_hash'
    `);
    
    if (settlementTxCheck.rows.length === 0) {
      await client.query(`
        ALTER TABLE auctions ADD COLUMN settlement_tx_hash VARCHAR(66);
      `);
      console.log('  ✓ Added settlement_tx_hash column');
    }

    console.log('✅ Auction columns updated\n');

    // 6. Create indexes for performance
    console.log('6️⃣ Creating indexes...');
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_bids_auction ON bids(auction_id);
      CREATE INDEX IF NOT EXISTS idx_bids_bidder ON bids(bidder_address);
      CREATE INDEX IF NOT EXISTS idx_bids_placed_at ON bids(placed_at DESC);
      CREATE INDEX IF NOT EXISTS idx_escrow_auction ON escrow_deposits(auction_id);
      CREATE INDEX IF NOT EXISTS idx_escrow_depositor ON escrow_deposits(depositor_address);
      CREATE INDEX IF NOT EXISTS idx_settlements_auction ON auction_settlements(auction_id);
      CREATE INDEX IF NOT EXISTS idx_cancellations_auction ON auction_cancellations(auction_id);
    `);
    console.log('✅ Indexes created\n');

    await client.query('COMMIT');
    
    console.log('✅ Migration completed successfully!\n');
    console.log('📊 Tables created:');
    console.log('  - bids');
    console.log('  - escrow_deposits');
    console.log('  - auction_settlements');
    console.log('  - auction_cancellations');
    console.log('\n📈 Indexes created for performance optimization');
    
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Migration failed:', error);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

// Run migration
runMigration()
  .then(() => {
    console.log('\n✨ Database is ready for bidding system!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Migration error:', error);
    process.exit(1);
  });
