require('dotenv').config();
const db = require('./src/db/database');
const logger = require('./src/utils/logger');

async function updateConstraint() {
  try {
    logger.info('Updating status constraint...');
    
    // Drop old constraint
    await db.query('ALTER TABLE pepper_lots DROP CONSTRAINT IF EXISTS pepper_lots_status_check;');
    logger.info('Old constraint dropped');
    
    // Add new constraint with 'available' included
    const addConstraint = `
      ALTER TABLE pepper_lots 
      ADD CONSTRAINT pepper_lots_status_check 
      CHECK (status IN ('created', 'available', 'pending_compliance', 'approved', 'rejected', 'auctioned'));
    `;
    
    await db.query(addConstraint);
    logger.info('New constraint added with available status');
    
    process.exit(0);
  } catch (error) {
    logger.error('Error:', error);
    process.exit(1);
  }
}

updateConstraint();
