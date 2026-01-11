const db = require('./src/db/database');
const logger = require('./src/utils/logger');

async function addLotApprovalColumns() {
  try {
    logger.info('Adding lot approval columns...');
    
    // Add lot_pictures and certificate_images columns for storing IPFS URLs
    await db.query(`
      ALTER TABLE pepper_lots 
      ADD COLUMN IF NOT EXISTS lot_pictures JSONB DEFAULT '[]',
      ADD COLUMN IF NOT EXISTS certificate_images JSONB DEFAULT '[]',
      ADD COLUMN IF NOT EXISTS rejection_reason TEXT
    `);
    
    logger.info('Added lot_pictures, certificate_images, and rejection_reason columns');
    
    // Update existing status constraint to include 'approved' and 'rejected'
    await db.query(`
      ALTER TABLE pepper_lots DROP CONSTRAINT IF EXISTS pepper_lots_status_check
    `);
    
    await db.query(`
      ALTER TABLE pepper_lots 
      ADD CONSTRAINT pepper_lots_status_check 
      CHECK (status IN ('created', 'available', 'pending', 'pending_compliance', 'approved', 'rejected', 'auctioned'))
    `);
    
    logger.info('Updated status constraint');
    
    // Update compliance_status constraint to include 'approved' and 'rejected'
    await db.query(`
      ALTER TABLE pepper_lots DROP CONSTRAINT IF EXISTS pepper_lots_compliance_status_check
    `);
    
    await db.query(`
      ALTER TABLE pepper_lots 
      ADD CONSTRAINT pepper_lots_compliance_status_check 
      CHECK (compliance_status IN ('pending', 'checking', 'passed', 'failed', 'approved', 'rejected'))
    `);
    
    logger.info('Updated compliance_status constraint');
    
    // Create admin_actions table if it doesn't exist
    await db.query(`
      CREATE TABLE IF NOT EXISTS admin_actions (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        admin_id VARCHAR(255) NOT NULL,
        action_type VARCHAR(50) NOT NULL,
        target_type VARCHAR(50) NOT NULL,
        target_id VARCHAR(255) NOT NULL,
        details JSONB,
        created_at TIMESTAMPTZ DEFAULT NOW()
      )
    `);
    
    logger.info('Created admin_actions table');
    
    // Create index for admin_actions
    await db.query(`
      CREATE INDEX IF NOT EXISTS idx_admin_actions_admin ON admin_actions(admin_id);
      CREATE INDEX IF NOT EXISTS idx_admin_actions_target ON admin_actions(target_type, target_id);
      CREATE INDEX IF NOT EXISTS idx_admin_actions_created ON admin_actions(created_at DESC);
    `);
    
    logger.info('Created admin_actions indexes');
    
    // Add index for compliance_status
    await db.query(`
      CREATE INDEX IF NOT EXISTS idx_lots_compliance_status ON pepper_lots(compliance_status)
    `);
    
    logger.info('Created compliance_status index');
    
    logger.info('✅ All lot approval columns added successfully');
    
  } catch (error) {
    logger.error('Error adding lot approval columns:', error);
    throw error;
  }
}

// Run if called directly
if (require.main === module) {
  addLotApprovalColumns()
    .then(() => {
      logger.info('Migration completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      logger.error('Migration failed:', error);
      process.exit(1);
    });
}

module.exports = { addLotApprovalColumns };
