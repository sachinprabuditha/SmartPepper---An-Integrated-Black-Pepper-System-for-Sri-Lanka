const { Pool } = require('pg');

const pool = new Pool({
  host: '192.168.8.116',
  port: 5432,
  database: 'smartpepper',
  user: 'postgres',
  password: 'postgres'
});

async function addHarvestStage() {
  try {
    console.log('Adding harvest stage...');
    
    await pool.query(`
      INSERT INTO processing_stages (lot_id, stage_type, stage_name, location, timestamp, operator_name, quality_metrics, notes)
      VALUES ($1, $2, $3, $4, NOW() - INTERVAL '5 days', $5, $6, $7)
    `, [
      'LOT-1766820145306',
      'harvest',
      'Pepper Harvesting',
      'Matara Pepper Estate',
      'Farm Worker Team',
      JSON.stringify({ yield_kg: 52, quality_score: 95, harvest_method: 'manual' }),
      'Harvested at optimal maturity for premium quality'
    ]);
    
    console.log('✓ Added harvest stage');
    console.log('\n✅ Complete traceability chain now available:');
    console.log('   1. Harvest → 2. Drying → 3. Grading → 4. Packaging');
    
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await pool.end();
  }
}

addHarvestStage();
