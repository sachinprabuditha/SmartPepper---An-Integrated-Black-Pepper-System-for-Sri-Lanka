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
    console.log('Running escrow tables migration...\n');
    
    const sqlFile = path.join(__dirname, 'migrations', 'add-escrow-tables.sql');
    const sql = fs.readFileSync(sqlFile, 'utf8');
    
    await pool.query(sql);
    
    console.log('✅ Migration completed successfully!');
    console.log('\nCreated/Updated:');
    console.log('  - Added escrow columns to auctions table');
    console.log('  - Created escrow_deposits table');
    console.log('  - Created indexes for better performance');
    
  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    console.error(error.stack);
  } finally {
    await pool.end();
  }
}

runMigration();
