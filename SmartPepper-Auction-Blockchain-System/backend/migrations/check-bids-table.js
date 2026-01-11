const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'smartpepper',
  user: process.env.DB_USER || 'admin',
  password: process.env.DB_PASSWORD || 'admin'
});

async function checkTable() {
  try {
    const result = await pool.query(`
      SELECT column_name, data_type, column_default
      FROM information_schema.columns
      WHERE table_name = 'bids'
      ORDER BY ordinal_position;
    `);
    
    console.log('📋 Bids table structure:');
    console.table(result.rows);
    
    await pool.end();
  } catch (error) {
    console.error('❌ Error:', error.message);
    await pool.end();
    process.exit(1);
  }
}

checkTable();
