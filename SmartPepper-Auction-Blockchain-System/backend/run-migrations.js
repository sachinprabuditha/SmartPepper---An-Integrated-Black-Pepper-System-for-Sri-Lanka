const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

// Load environment variables
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'smartpepper',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD,
});

async function runMigrations() {
  const client = await pool.connect();
  
  try {
    console.log('🔄 Starting database migrations...');
    
    // Read the SQL file
    const sqlFile = path.join(__dirname, 'create-tables.sql');
    const sql = fs.readFileSync(sqlFile, 'utf8');
    
    // Execute the SQL
    await client.query(sql);
    
    console.log('✅ All migrations completed successfully!');
    console.log('\nCreated tables:');
    console.log('  - processing_stages');
    console.log('  - certifications');
    console.log('  - compliance_rules');
    console.log('  - compliance_checks');
    console.log('\nUpdated tables:');
    console.log('  - pepper_lots (added compliance_status, compliance_checked_at)');
    console.log('  - pepper_lots (updated status constraint)');
    
  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    console.error(error.stack);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

runMigrations();
