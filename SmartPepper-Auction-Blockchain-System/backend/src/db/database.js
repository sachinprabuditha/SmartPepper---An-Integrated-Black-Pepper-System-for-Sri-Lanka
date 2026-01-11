const { Pool } = require('pg');
const logger = require('../utils/logger');

// Only create pool if password is provided
let pool = null;
let useMockDb = false;

if (process.env.DB_PASSWORD) {
  pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME || 'smartpepper',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD,
    max: 20,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 2000,
  });

  pool.on('error', (err) => {
    logger.error('Unexpected database error:', err);
  });
  
  logger.info('Database: Using PostgreSQL');
} else {
  // Use mock database for development
  useMockDb = true;
  logger.warn('Database: PostgreSQL not configured, using in-memory mock database');
  logger.warn('To use PostgreSQL, set DB_PASSWORD in .env file');
}

// Load mock database if needed
const mockDb = useMockDb ? require('./mockDatabase') : null;

module.exports = {
  query: (text, params) => {
    if (useMockDb) {
      return mockDb.query(text, params);
    }
    if (!pool) throw new Error('Database not configured');
    return pool.query(text, params);
  },
  
  connect: async () => {
    if (useMockDb) {
      return mockDb.connect();
    }
    if (!pool) {
      throw new Error('Database not configured - DB_PASSWORD is missing');
    }
    const client = await pool.connect();
    client.release();
    return true;
  },
  
  disconnect: () => {
    if (useMockDb) {
      return mockDb.disconnect();
    }
    return pool ? pool.end() : Promise.resolve();
  },
  
  isMock: useMockDb,
  pool
};
