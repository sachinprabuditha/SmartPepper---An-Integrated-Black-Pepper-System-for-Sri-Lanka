const { Pool } = require('pg');

const pool = new Pool({
  host: '192.168.8.116',
  port: 5432,
  database: 'smartpepper',
  user: 'postgres',
  password: 'postgres'
});

async function updateCertTypes() {
  try {
    console.log('Updating certificate types constraint...');
    
    await pool.query(`
      ALTER TABLE certifications 
      DROP CONSTRAINT IF EXISTS certifications_cert_type_check;
    `);
    
    console.log('✓ Dropped old constraint');
    
    await pool.query(`
      ALTER TABLE certifications 
      ADD CONSTRAINT certifications_cert_type_check 
      CHECK (cert_type IN ('organic', 'fumigation', 'export', 'quality', 'phytosanitary', 'pesticide_test', 'origin', 'halal'));
    `);
    
    console.log('✓ Added new constraint with all certificate types');
    console.log('\nAllowed certificate types:');
    console.log('  - organic');
    console.log('  - fumigation');
    console.log('  - export');
    console.log('  - quality');
    console.log('  - phytosanitary');
    console.log('  - pesticide_test (NEW)');
    console.log('  - origin (NEW)');
    console.log('  - halal (NEW)');
    
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await pool.end();
  }
}

updateCertTypes();
