const { Pool } = require('pg');

const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'smartpepper',
  password: process.env.DB_PASSWORD || 'postgres',
  port: 5432,
});

async function checkAndFix() {
  try {
    console.log('Checking wallet address assignments...\n');
    
    // Check who has the wallet with bids
    const walletWithBids = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';
    const result1 = await pool.query(
      `SELECT id, email, name, role, wallet_address 
       FROM users 
       WHERE LOWER(wallet_address) = LOWER($1)`,
      [walletWithBids]
    );

    console.log('User with wallet that has bids:');
    console.log(JSON.stringify(result1.rows[0], null, 2));
    
    // Check exporter1
    const result2 = await pool.query(
      `SELECT id, email, name, role, wallet_address 
       FROM users 
       WHERE email = 'exporter1@gmail.com'`
    );
    
    console.log('\nExporter1 user:');
    console.log(JSON.stringify(result2.rows[0], null, 2));
    
    // Count bids for each wallet
    const bidsCount1 = await pool.query(
      `SELECT COUNT(*) as count 
       FROM bids 
       WHERE LOWER(bidder_address) = LOWER($1)`,
      [walletWithBids]
    );
    
    console.log(`\nBids for 0xf39F...2266: ${bidsCount1.rows[0].count}`);
    
    if (result2.rows[0]?.wallet_address) {
      const bidsCount2 = await pool.query(
        `SELECT COUNT(*) as count 
         FROM bids 
         WHERE LOWER(bidder_address) = LOWER($1)`,
        [result2.rows[0].wallet_address]
      );
      console.log(`Bids for ${result2.rows[0].wallet_address.substring(0, 10)}...: ${bidsCount2.rows[0].count}`);
    }
    
    // Solution: Swap wallet addresses or clear the other user's wallet
    if (result1.rows[0] && result2.rows[0] && result1.rows[0].id !== result2.rows[0].id) {
      console.log('\n🔄 Swapping wallet addresses between users...');
      
      const exporter1Wallet = result2.rows[0].wallet_address;
      
      // Temporarily set first user's wallet to null
      await pool.query(
        `UPDATE users SET wallet_address = NULL WHERE id = $1`,
        [result1.rows[0].id]
      );
      
      // Set exporter1's wallet to the one with bids
      await pool.query(
        `UPDATE users SET wallet_address = $1 WHERE id = $2`,
        [walletWithBids, result2.rows[0].id]
      );
      
      // Set first user's wallet to exporter1's old wallet
      if (exporter1Wallet) {
        await pool.query(
          `UPDATE users SET wallet_address = $1 WHERE id = $2`,
          [exporter1Wallet, result1.rows[0].id]
        );
      }
      
      console.log('✅ Wallet addresses swapped successfully!');
      
      // Verify
      const verify = await pool.query(
        `SELECT email, wallet_address FROM users WHERE id IN ($1, $2)`,
        [result1.rows[0].id, result2.rows[0].id]
      );
      console.log('\n✅ Updated users:');
      verify.rows.forEach(row => {
        console.log(`  ${row.email}: ${row.wallet_address}`);
      });
    }
  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error(error.stack);
  } finally {
    await pool.end();
  }
}

checkAndFix();
