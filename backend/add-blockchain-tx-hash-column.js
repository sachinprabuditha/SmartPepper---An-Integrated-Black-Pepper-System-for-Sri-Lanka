const { Pool } = require('pg');

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'smartpepper',
  password: process.env.DB_PASSWORD || 'postgres',
  port: process.env.DB_PORT || 5432,
});

async function addColumn() {
  try {
    console.log('Adding blockchain_tx_hash column to pepper_lots table...');
    
    await pool.query(`
      ALTER TABLE pepper_lots 
      ADD COLUMN IF NOT EXISTS blockchain_tx_hash VARCHAR(66);
    `);
    
    console.log('✅ Column added to pepper_lots!');
    
    console.log('Adding blockchain_tx_hash column to bids table...');
    
    await pool.query(`
      ALTER TABLE bids 
      ADD COLUMN IF NOT EXISTS blockchain_tx_hash VARCHAR(66);
    `);
    
    console.log('✅ Column added to bids!');
    
    // Verify the columns exist
    const lotsResult = await pool.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'pepper_lots' AND column_name = 'blockchain_tx_hash';
    `);
    
    const bidsResult = await pool.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'bids' AND column_name = 'blockchain_tx_hash';
    `);
    
    if (lotsResult.rows.length > 0) {
      console.log('✅ Verified: pepper_lots.blockchain_tx_hash exists');
    }
    
    if (bidsResult.rows.length > 0) {
      console.log('✅ Verified: bids.blockchain_tx_hash exists');
    }
    
  } catch (error) {
    console.error('❌ Error adding column:', error.message);
    throw error;
  } finally {
    await pool.end();
  }
}

addColumn().catch(console.error);
