const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'smartpepper',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
});

async function runMigration() {
  const client = await pool.connect();

  try {
    console.log('🔄 Starting governance schema migration...');

    await client.query('BEGIN');

    // 1. Add template_id column to auctions table
    console.log('Adding template_id column to auctions table...');
    await client.query(`
      ALTER TABLE auctions 
      ADD COLUMN IF NOT EXISTS template_id VARCHAR(255);
    `);

    // 2. Add min_bid_increment column to auctions table
    console.log('Adding min_bid_increment column to auctions table...');
    await client.query(`
      ALTER TABLE auctions 
      ADD COLUMN IF NOT EXISTS min_bid_increment DECIMAL(5,2);
    `);

    // 3. Create cancellation_requests table
    console.log('Creating cancellation_requests table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS cancellation_requests (
        id SERIAL PRIMARY KEY,
        auction_id VARCHAR(255) NOT NULL,
        lot_id VARCHAR(255) NOT NULL,
        requested_by VARCHAR(255) NOT NULL,
        reason TEXT NOT NULL,
        status VARCHAR(50) DEFAULT 'pending',
        created_at TIMESTAMP DEFAULT NOW(),
        reviewed_at TIMESTAMP,
        reviewed_by VARCHAR(255),
        admin_comments TEXT
      );
    `);

    // 4. Create auction_rule_templates table
    console.log('Creating auction_rule_templates table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS auction_rule_templates (
        id SERIAL PRIMARY KEY,
        template_id VARCHAR(255) UNIQUE NOT NULL,
        name VARCHAR(255) NOT NULL,
        description TEXT,
        min_duration_hours INT NOT NULL,
        max_duration_hours INT NOT NULL,
        min_bid_increment DECIMAL(5,2) NOT NULL,
        max_reserve_price DECIMAL(15,2),
        requires_approval BOOLEAN DEFAULT false,
        active BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      );
    `);

    // 5. Create governance_settings table
    console.log('Creating governance_settings table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS governance_settings (
        id SERIAL PRIMARY KEY,
        default_min_duration_hours INT NOT NULL DEFAULT 24,
        default_max_duration_hours INT NOT NULL DEFAULT 168,
        default_bid_increment DECIMAL(5,2) NOT NULL DEFAULT 5.0,
        allowed_durations INT[] DEFAULT ARRAY[24, 48, 72, 96, 168],
        min_reserve_price DECIMAL(15,2) DEFAULT 100,
        max_reserve_price DECIMAL(15,2) DEFAULT 1000000,
        requires_admin_approval BOOLEAN DEFAULT false,
        updated_at TIMESTAMP DEFAULT NOW(),
        updated_by VARCHAR(255)
      );
    `);

    // 6. Create governance_logs table
    console.log('Creating governance_logs table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS governance_logs (
        id SERIAL PRIMARY KEY,
        action VARCHAR(255) NOT NULL,
        performed_by VARCHAR(255) NOT NULL,
        details TEXT,
        blockchain_tx_hash VARCHAR(255),
        created_at TIMESTAMP DEFAULT NOW()
      );
    `);

    // 7. Insert default governance settings
    console.log('Inserting default governance settings...');
    const settingsResult = await client.query(`
      SELECT COUNT(*) FROM governance_settings;
    `);

    if (parseInt(settingsResult.rows[0].count) === 0) {
      await client.query(`
        INSERT INTO governance_settings (
          default_min_duration_hours,
          default_max_duration_hours,
          default_bid_increment,
          allowed_durations,
          min_reserve_price,
          max_reserve_price,
          requires_admin_approval
        ) VALUES (
          24,
          168,
          5.0,
          ARRAY[24, 48, 72, 96, 168],
          100,
          1000000,
          false
        );
      `);
      console.log('✅ Default governance settings inserted');
    }

    // 8. Insert default templates
    console.log('Inserting default auction templates...');
    const templatesResult = await client.query(`
      SELECT COUNT(*) FROM auction_rule_templates;
    `);

    if (parseInt(templatesResult.rows[0].count) === 0) {
      await client.query(`
        INSERT INTO auction_rule_templates (
          template_id, name, description, min_duration_hours, 
          max_duration_hours, min_bid_increment, max_reserve_price, 
          requires_approval, active
        ) VALUES 
        (
          'standard-auction',
          'Standard Auction',
          'Basic auction rules for regular pepper lots',
          24,
          168,
          5.0,
          500000,
          false,
          true
        ),
        (
          'premium-auction',
          'Premium Lot Auction',
          'Enhanced rules for premium quality pepper with admin approval',
          48,
          240,
          10.0,
          1000000,
          true,
          true
        );
      `);
      console.log('✅ Default auction templates inserted');
    }

    await client.query('COMMIT');
    console.log('✅ Governance schema migration completed successfully!');

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
    console.log('Migration script finished');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Migration script failed:', error);
    process.exit(1);
  });
