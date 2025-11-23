const { Pool } = require('pg');
const logger = require('../utils/logger');
require('dotenv').config();

// Direct PostgreSQL connection
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'smartpepper',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || '',
});

const authMigrations = [
  // Update users table to support authentication
  `ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255)`,
  `ALTER TABLE users ADD COLUMN IF NOT EXISTS role VARCHAR(20) CHECK (role IN ('farmer', 'exporter', 'admin'))`,
  `ALTER TABLE users ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true`,
  `ALTER TABLE users ADD COLUMN IF NOT EXISTS last_login TIMESTAMPTZ`,
  `ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_image TEXT`,
  `ALTER TABLE users ADD COLUMN IF NOT EXISTS address TEXT`,
  `ALTER TABLE users ADD COLUMN IF NOT EXISTS city VARCHAR(100)`,
  `ALTER TABLE users ADD COLUMN IF NOT EXISTS country VARCHAR(100) DEFAULT 'Sri Lanka'`,
  `ALTER TABLE users ADD COLUMN IF NOT EXISTS language VARCHAR(10) DEFAULT 'en'`,
  
  // Create sessions table for JWT token management
  `CREATE TABLE IF NOT EXISTS user_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    refresh_token TEXT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
  )`,

  // Create password reset tokens table
  `CREATE TABLE IF NOT EXISTS password_reset_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    used BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
  )`,

  // Create activity logs table
  `CREATE TABLE IF NOT EXISTS activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50),
    resource_id VARCHAR(100),
    details JSONB,
    ip_address VARCHAR(45),
    created_at TIMESTAMPTZ DEFAULT NOW()
  )`,

  // Create permissions table
  `CREATE TABLE IF NOT EXISTS permissions (
    id SERIAL PRIMARY KEY,
    role VARCHAR(20) NOT NULL,
    resource VARCHAR(50) NOT NULL,
    action VARCHAR(20) NOT NULL,
    UNIQUE(role, resource, action)
  )`,

  // Indexes for performance
  `CREATE INDEX IF NOT EXISTS idx_sessions_user ON user_sessions(user_id)`,
  `CREATE INDEX IF NOT EXISTS idx_sessions_token ON user_sessions(token)`,
  `CREATE INDEX IF NOT EXISTS idx_sessions_expires ON user_sessions(expires_at)`,
  `CREATE INDEX IF NOT EXISTS idx_reset_tokens_user ON password_reset_tokens(user_id)`,
  `CREATE INDEX IF NOT EXISTS idx_reset_tokens_token ON password_reset_tokens(token)`,
  `CREATE INDEX IF NOT EXISTS idx_activity_user ON activity_logs(user_id)`,
  `CREATE INDEX IF NOT EXISTS idx_activity_created ON activity_logs(created_at)`,
  `CREATE INDEX IF NOT EXISTS idx_permissions_role ON permissions(role)`,

  // Insert default permissions for each role
  `INSERT INTO permissions (role, resource, action) VALUES
    -- Farmer permissions
    ('farmer', 'lot', 'create'),
    ('farmer', 'lot', 'read'),
    ('farmer', 'lot', 'update'),
    ('farmer', 'auction', 'create'),
    ('farmer', 'auction', 'read'),
    ('farmer', 'auction', 'end'),
    ('farmer', 'bid', 'read'),
    ('farmer', 'profile', 'update'),
    
    -- Exporter/Seller permissions
    ('exporter', 'auction', 'read'),
    ('exporter', 'lot', 'read'),
    ('exporter', 'bid', 'create'),
    ('exporter', 'bid', 'read'),
    ('exporter', 'profile', 'update'),
    
    -- Admin permissions (full access)
    ('admin', 'lot', 'create'),
    ('admin', 'lot', 'read'),
    ('admin', 'lot', 'update'),
    ('admin', 'lot', 'delete'),
    ('admin', 'auction', 'create'),
    ('admin', 'auction', 'read'),
    ('admin', 'auction', 'update'),
    ('admin', 'auction', 'delete'),
    ('admin', 'bid', 'read'),
    ('admin', 'bid', 'delete'),
    ('admin', 'user', 'create'),
    ('admin', 'user', 'read'),
    ('admin', 'user', 'update'),
    ('admin', 'user', 'delete'),
    ('admin', 'compliance', 'manage'),
    ('admin', 'settings', 'manage')
  ON CONFLICT (role, resource, action) DO NOTHING`,
];

async function runAuthMigrations() {
  const client = await pool.connect();
  
  try {
    logger.info('Starting authentication migrations...');
    
    await client.query('BEGIN');
    
    for (let i = 0; i < authMigrations.length; i++) {
      logger.info(`Running migration ${i + 1}/${authMigrations.length}`);
      await client.query(authMigrations[i]);
    }
    
    await client.query('COMMIT');
    logger.info('✅ Authentication migrations completed successfully');
    
  } catch (error) {
    await client.query('ROLLBACK');
    logger.error('❌ Migration failed:', error);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

// Run migrations if called directly
if (require.main === module) {
  runAuthMigrations()
    .then(() => {
      logger.info('Migration script completed');
      process.exit(0);
    })
    .catch((error) => {
      logger.error('Migration script failed:', error);
      process.exit(1);
    });
}

module.exports = runAuthMigrations;
