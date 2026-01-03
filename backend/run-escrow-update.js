const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'smartpepper',
  password: process.env.DB_PASSWORD || 'postgres',
  port: 5432,
});

async function runMigration() {
  try {
    console.log('Running escrow tables update migration...\n');
    
    const sqlFile = path.join(__dirname, 'migrations', 'update-escrow-tables.sql');
    const sql = fs.readFileSync(sqlFile, 'utf8');
    
    await pool.query(sql);
    
    console.log('✅ Migration completed successfully!');
    console.log('\nChanges applied:');
    console.log('  - Added escrow columns to auctions table');
    console.log('  - Added user_id, verified, verified_at to escrow_deposits table');
    console.log('  - Renamed columns for consistency (if needed)');
    console.log('  - Created performance indexes');
    
  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    console.error(error);
  } finally {
    await pool.end();
  }
}

runMigration();
