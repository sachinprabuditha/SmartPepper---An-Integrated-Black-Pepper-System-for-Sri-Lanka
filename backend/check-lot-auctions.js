const { Pool } = require('pg');

const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'smartpepper',
  password: 'postgres',
  port: 5432,
});

async function checkLotAuctions() {
  try {
    const lotId = 'LOT-1767472240326';
    
    console.log(`\n🔍 Checking auctions for lot: ${lotId}\n`);
    
    const result = await pool.query(`
      SELECT 
        auction_id, 
        lot_id, 
        status, 
        start_time, 
        end_time,
        blockchain_tx_hash,
        created_at
      FROM auctions 
      WHERE lot_id = $1
      ORDER BY created_at DESC
    `, [lotId]);
    
    if (result.rows.length === 0) {
      console.log('❌ No auctions found for this lot in database');
    } else {
      console.log(`✅ Found ${result.rows.length} auction(s):\n`);
      result.rows.forEach((row, idx) => {
        console.log(`Auction ${idx + 1}:`);
        console.log(`  ID: ${row.auction_id}`);
        console.log(`  Status: ${row.status}`);
        console.log(`  Start: ${row.start_time}`);
        console.log(`  End: ${row.end_time}`);
        console.log(`  TX: ${row.blockchain_tx_hash}`);
        console.log(`  Created: ${row.created_at}\n`);
      });
    }
    
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await pool.end();
  }
}

checkLotAuctions();
