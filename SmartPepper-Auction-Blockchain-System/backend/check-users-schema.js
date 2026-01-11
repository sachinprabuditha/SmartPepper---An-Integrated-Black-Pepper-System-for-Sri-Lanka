const { Pool } = require('pg');

const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'smartpepper',
  password: 'postgres',
  port: 5432,
});

async function checkSchema() {
  try {
    // Check users table structure
    const usersResult = await pool.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'users' 
      ORDER BY ordinal_position
    `);
    
    console.log('\n📋 Users table columns:');
    usersResult.rows.forEach(row => {
      console.log(`  - ${row.column_name}: ${row.data_type}`);
    });
    
    // Check if escrow_deposits table exists
    const tableCheck = await pool.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name = 'escrow_deposits'
    `);
    
    if (tableCheck.rows.length > 0) {
      console.log('\n✅ escrow_deposits table already exists');
      
      const escrowResult = await pool.query(`
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_name = 'escrow_deposits' 
        ORDER BY ordinal_position
      `);
      
      console.log('\n📋 Escrow_deposits table columns:');
      escrowResult.rows.forEach(row => {
        console.log(`  - ${row.column_name}: ${row.data_type}`);
      });
    } else {
      console.log('\n❌ escrow_deposits table does not exist');
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await pool.end();
  }
}

checkSchema();
