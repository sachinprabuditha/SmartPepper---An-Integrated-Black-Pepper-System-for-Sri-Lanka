const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'smartpepper',
  user: 'postgres',
  password: 'postgres'
});

async function updateAuctionStatus() {
  try {
    const result = await pool.query(
      'UPDATE auctions SET status = $1 WHERE auction_id = $2 RETURNING *',
      ['active', 1766917103]
    );
    console.log('Auction status updated to active:');
    console.log(result.rows[0]);
  } catch (error) {
    console.error('Error updating auction:', error);
  } finally {
    await pool.end();
  }
}

updateAuctionStatus();
