require('dotenv').config();
const db = require('./src/db/database');
const logger = require('./src/utils/logger');

async function addUpdatedAt() {
  try {
    logger.info('Adding updated_at column to pepper_lots table...');
    
    const alterQuery = `
      ALTER TABLE pepper_lots 
      ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
    `;
    
    await db.query(alterQuery);
    logger.info('Column added successfully!');
    
    process.exit(0);
  } catch (error) {
    logger.error('Error adding column:', error);
    process.exit(1);
  }
}

addUpdatedAt();
