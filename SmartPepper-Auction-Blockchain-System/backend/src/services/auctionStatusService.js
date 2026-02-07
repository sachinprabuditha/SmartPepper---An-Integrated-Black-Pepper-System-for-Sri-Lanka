const db = require('../db/database');
const admin = require('firebase-admin');
const logger = require('../utils/logger');

/**
 * Updates auction statuses based on current time
 * - Changes 'created' to 'active' if start_time has passed
 * - Changes 'active' to 'ended' if end_time has passed
 */
async function updateAuctionStatuses() {
  // Skip if not using Firebase
  if (!db.isFirebase) {
    return { activated: 0, ended: 0 };
  }

  try {
    const firestore = db.getDb();
    const now = admin.firestore.Timestamp.now();
    const batch = firestore.batch();
    let activatedCount = 0;
    let endedCount = 0;
    const activatedAuctions = [];
    const endedAuctions = [];

    // Activate auctions that have passed their start time
    const toActivateSnap = await firestore.collection('auctions')
      .where('status', '==', 'created')
      .where('admin_approved', '==', true)
      .get();

    for (const doc of toActivateSnap.docs) {
      const auction = doc.data();
      // Check if start_time has passed
      if (auction.start_time && auction.start_time.toMillis() <= now.toMillis()) {
        batch.update(doc.ref, { 
          status: 'active',
          updated_at: admin.firestore.FieldValue.serverTimestamp()
        });
        activatedCount++;
        activatedAuctions.push(auction.auction_id || doc.id);
      }
    }

    // End auctions that have passed their end time
    const toEndSnap = await firestore.collection('auctions')
      .where('status', '==', 'active')
      .get();

    for (const doc of toEndSnap.docs) {
      const auction = doc.data();
      // Check if end_time has passed
      if (auction.end_time && auction.end_time.toMillis() <= now.toMillis()) {
        batch.update(doc.ref, { 
          status: 'ended',
          updated_at: admin.firestore.FieldValue.serverTimestamp()
        });
        endedCount++;
        endedAuctions.push(auction.auction_id || doc.id);
      }
    }

    // Commit all updates
    if (activatedCount > 0 || endedCount > 0) {
      await batch.commit();
    }

    if (activatedCount > 0) {
      logger.info(`✅ Activated ${activatedCount} auction(s): ${activatedAuctions.join(', ')}`);
    }

    if (endedCount > 0) {
      logger.info(`⏰ Ended ${endedCount} auction(s): ${endedAuctions.join(', ')}`);
    }

    return {
      activated: activatedCount,
      ended: endedCount
    };

  } catch (error) {
    logger.error('❌ Error updating auction statuses:', error);
    throw error;
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
