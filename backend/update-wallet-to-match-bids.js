const { Pool } = require('pg');

const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'smartpepper',
  password: process.env.DB_PASSWORD || 'postgres',
  port: 5432,
});

async function updateWallet() {
  try {
    console.log('Updating exporter1 wallet address to match existing bids...');
    
    const result = await pool.query(
      `UPDATE users 
       SET wallet_address = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266' 
       WHERE email = 'exporter1@gmail.com' 
       RETURNING id, email, name, wallet_address`
    );

    if (result.rows.length > 0) {
      console.log('✅ Updated user:');
      console.log(JSON.stringify(result.rows[0], null, 2));
      
      // Verify bids exist for this wallet
      const bidsResult = await pool.query(
        `SELECT COUNT(*) as count 
         FROM bids 
         WHERE LOWER(bidder_address) = LOWER($1)`,
        ['0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266']
      );
      
      console.log(`\n✅ Found ${bidsResult.rows[0].count} bids for this wallet address`);
    } else {
      console.log('❌ User not found');
    }
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await pool.end();
  }
}

updateWallet();
