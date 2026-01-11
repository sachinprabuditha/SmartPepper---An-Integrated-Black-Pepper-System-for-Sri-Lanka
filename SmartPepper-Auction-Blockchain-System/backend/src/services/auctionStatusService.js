const db = require('../db/database');

/**
 * Updates auction statuses based on current time
 * - Changes 'created' to 'active' if start_time has passed
 * - Changes 'active' to 'ended' if end_time has passed
 */
async function updateAuctionStatuses() {
  // Skip if using mock database
  if (db.isMock || !db.pool) {
    return { activated: 0, ended: 0 };
  }

  const client = await db.pool.connect();
  
  try {
    await client.query('BEGIN');

    // Activate auctions that have passed their start time
    const activatedResult = await client.query(`
      UPDATE auctions 
      SET status = 'active' 
      WHERE status = 'created' 
        AND start_time <= NOW()
        AND admin_approved = true
      RETURNING auction_id, lot_id
    `);

    // End auctions that have passed their end time
    const endedResult = await client.query(`
      UPDATE auctions 
      SET status = 'ended' 
      WHERE status = 'active' 
        AND end_time <= NOW()
      RETURNING auction_id, lot_id, current_bid, current_bidder
    `);

    await client.query('COMMIT');

    if (activatedResult.rows.length > 0) {
      console.log(`✅ Activated ${activatedResult.rows.length} auction(s):`, 
        activatedResult.rows.map(r => r.auction_id).join(', '));
    }

    if (endedResult.rows.length > 0) {
      console.log(`⏰ Ended ${endedResult.rows.length} auction(s):`, 
        endedResult.rows.map(r => r.auction_id).join(', '));
    }

    return {
      activated: activatedResult.rows.length,
      ended: endedResult.rows.length
    };

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Error updating auction statuses:', error);
    throw error;
  } finally {
    client.release();
  }
}

/**
 * Starts a periodic check every minute to update auction statuses
 */
function startAuctionStatusMonitor() {
  console.log('🔄 Starting auction status monitor...');
  
  // Run immediately on startup
  updateAuctionStatuses().catch(err => 
    console.error('Failed to update auction statuses:', err)
  );

  // Then run every minute
  setInterval(() => {
    updateAuctionStatuses().catch(err => 
      console.error('Failed to update auction statuses:', err)
    );
  }, 60 * 1000); // 60 seconds
}

module.exports = {
  updateAuctionStatuses,
  startAuctionStatusMonitor
};
