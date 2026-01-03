const { Pool } = require('pg');

const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'smartpepper',
  password: 'postgres',
  port: 5432,
});

async function checkAuctions() {
  try {
    const result = await pool.query(`
      SELECT auction_id, lot_id, blockchain_tx_hash, status, created_at 
      FROM auctions 
      ORDER BY created_at DESC 
      LIMIT 10
    `);
    
    console.log('\n📊 Recent Auctions:');
    console.log('==================');
    result.rows.forEach(row => {
      console.log(`ID: ${row.auction_id} | Lot: ${row.lot_id} | Status: ${row.status}`);
      console.log(`   TX: ${row.blockchain_tx_hash}`);
      console.log(`   Created: ${row.created_at}\n`);
    });
    
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await pool.end();
  }
}

checkAuctions();
