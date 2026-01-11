const { Pool } = require('pg');
const logger = require('../utils/logger');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'smartpepper',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || '',
});

async function seedDatabase() {
  try {
    logger.info('Starting database seeding...');

    // Insert users
    await pool.query(`
      INSERT INTO users (wallet_address, user_type, name) VALUES
      ('0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266', 'farmer', 'Test Farmer 1'),
      ('0x70997970C51812dc3A010C7d01b50e0d17dc79C8', 'buyer', 'Test Buyer 1'),
      ('0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC', 'farmer', 'Test Farmer 2')
      ON CONFLICT (wallet_address) DO NOTHING
    `);
    logger.info('✅ Users seeded');

    // Insert pepper lots
    await pool.query(`
      INSERT INTO pepper_lots (
        lot_id, farmer_address, variety, quantity, quality, harvest_date,
        certificate_hash, status
      ) VALUES
      ('LOT001', '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266', 'Red Bell Pepper', 500, 'Grade A', '2025-11-20',
       '0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef', 'auctioned'),
      ('LOT002', '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266', 'Green Chili', 300, 'Grade A', '2025-11-21',
       '0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890', 'auctioned'),
      ('LOT003', '0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC', 'Yellow Bell Pepper', 800, 'Premium', '2025-11-19',
       '0xfedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210', 'auctioned')
      ON CONFLICT (lot_id) DO NOTHING
    `);
    logger.info('✅ Pepper lots seeded');

    // Insert auctions
    await pool.query(`
      INSERT INTO auctions (
        auction_id, lot_id, farmer_address, start_price, reserve_price,
        current_bid, current_bidder, start_time, end_time, status, compliance_passed, bid_count
      ) VALUES
      (1, 'LOT001', '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
       '1000000000000000000', '2000000000000000000', '1500000000000000000',
       '0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
       NOW() - INTERVAL '1 hour', NOW() + INTERVAL '2 hours',
       'active', true, 3),
      (2, 'LOT002', '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
       '500000000000000000', '1000000000000000000', '0', NULL,
       NOW() + INTERVAL '1 hour', NOW() + INTERVAL '3 hours',
       'created', true, 0),
      (3, 'LOT003', '0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC',
       '2000000000000000000', '3000000000000000000', '2500000000000000000',
       '0x90F79bf6EB2c4f870365E785982E1f101E93b906',
       NOW() - INTERVAL '2 hours', NOW() + INTERVAL '30 minutes',
       'active', true, 7)
      ON CONFLICT (auction_id) DO NOTHING
    `);
    logger.info('✅ Auctions seeded');

    // Insert bids
    await pool.query(`
      INSERT INTO bids (auction_id, bidder_address, amount, placed_at) VALUES
      (1, '0x70997970C51812dc3A010C7d01b50e0d17dc79C8', '1500000000000000000', NOW() - INTERVAL '30 minutes'),
      (1, '0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC', '1200000000000000000', NOW() - INTERVAL '40 minutes'),
      (1, '0x70997970C51812dc3A010C7d01b50e0d17dc79C8', '1100000000000000000', NOW() - INTERVAL '50 minutes'),
      (3, '0x90F79bf6EB2c4f870365E785982E1f101E93b906', '2500000000000000000', NOW() - INTERVAL '15 minutes')
    `);
    logger.info('✅ Bids seeded');

    logger.info('✅ Database seeding completed successfully!');

  } catch (error) {
    logger.error('Seeding failed:', error);
    throw error;
  } finally {
    await pool.end();
  }
}

if (require.main === module) {
  seedDatabase()
    .then(() => {
      logger.info('Seed script completed');
      process.exit(0);
    })
    .catch((error) => {
      logger.error('Seed script failed:', error);
      process.exit(1);
    });
}

module.exports = { seedDatabase };
