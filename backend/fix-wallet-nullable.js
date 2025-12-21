/**
 * Fix: Make wallet_address nullable for email/password authentication
 * This allows users to register without a wallet address initially
 */

const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'smartpepper',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || '',
});

async function fixWalletAddressColumn() {
  try {
    console.log('Fixing wallet_address column to allow NULL values...');
    
    // Remove NOT NULL constraint from wallet_address
    await pool.query(`
      ALTER TABLE users 
      ALTER COLUMN wallet_address DROP NOT NULL
    `);
    
    console.log('✓ wallet_address column is now nullable');
    
    // Make wallet_address unique constraint conditional (only check when not null)
    // First, drop existing unique constraint if it exists
    await pool.query(`
      DO $$ 
      BEGIN
        IF EXISTS (
          SELECT 1 FROM pg_constraint 
          WHERE conname = 'users_wallet_address_key'
        ) THEN
          ALTER TABLE users DROP CONSTRAINT users_wallet_address_key;
        END IF;
      END $$;
    `);
    
    console.log('✓ Removed old wallet_address unique constraint');
    
    // Create a unique partial index instead (only enforces uniqueness for non-null values)
    await pool.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS users_wallet_address_unique 
      ON users (wallet_address) 
      WHERE wallet_address IS NOT NULL
    `);
    
    console.log('✓ Created partial unique index for wallet_address');
    
    // Make sure email is unique when provided
    await pool.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS users_email_unique 
      ON users (email) 
      WHERE email IS NOT NULL
    `);
    
    console.log('✓ Created unique index for email');
    
    console.log('\n=== Migration Complete ===');
    console.log('Users can now register with:');
    console.log('  1. Email + Password (no wallet)');
    console.log('  2. Wallet address only (no email)');
    console.log('  3. Both email and wallet');
    
  } catch (error) {
    console.error('Error:', error.message);
    throw error;
  } finally {
    await pool.end();
  }
}

// Run the fix
fixWalletAddressColumn()
  .then(() => {
    console.log('\n✓ Database schema updated successfully!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n✗ Migration failed:', error);
    process.exit(1);
  });
