const { Pool } = require('pg');

const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'smartpepper',
  password: 'postgres',
  port: 5432,
});

async function checkAuctionsSchema() {
  try {
    const result = await pool.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'auctions' 
      AND column_name LIKE '%escrow%'
      ORDER BY ordinal_position
    `);
    
    console.log('\n📋 Escrow-related columns in auctions table:');
    if (result.rows.length === 0) {
      console.log('  ❌ No escrow columns found!');
    } else {
      result.rows.forEach(row => {
        console.log(`  ✅ ${row.column_name}: ${row.data_type}`);
      });
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await pool.end();
  }
}

checkAuctionsSchema();
