const express = require('express');
const router = express.Router();
const admin = require('firebase-admin');
const logger = require('../utils/logger');

const db = admin.firestore();

/**
 * Helper function to convert Firestore Timestamps to ISO strings
 */
const convertTimestamps = (obj) => {
  if (!obj || typeof obj !== 'object') return obj;
  
  const converted = Array.isArray(obj) ? [] : {};
  
  for (const key in obj) {
    const value = obj[key];
    
    // Check if it's a Firestore Timestamp
    if (value && typeof value === 'object' && '_seconds' in value && '_nanoseconds' in value) {
      // Convert to ISO string
      const date = new Date(value._seconds * 1000 + value._nanoseconds / 1000000);
      converted[key] = date.toISOString();
    } else if (value && typeof value.toDate === 'function') {
      // Firestore Timestamp object with toDate method
      converted[key] = value.toDate().toISOString();
    } else if (Array.isArray(value)) {
      // Recursively convert arrays
      converted[key] = value.map(item => convertTimestamps(item));
    } else if (value && typeof value === 'object') {
      // Recursively convert nested objects
      converted[key] = convertTimestamps(value);
    } else {
      converted[key] = value;
    }
  }
  
  return converted;
};

/**
 * GET /api/traceability/:lotId
 * Get complete blockchain traceability records for a lot
 * 
 * Returns:
 * - Lot information
 * - NFT Passport data
 * - Processing logs (harvest, drying, grading, packaging, etc.)
 * - Certifications (organic, quality, export)
 * - Compliance checks
 * - Auction history
 * - Ownership transfers
 * - Complete audit trail
 */
router.get('/:lotId', async (req, res) => {
  try {
    const { lotId } = req.params;
    
    logger.info('Fetching complete traceability for lot:', lotId);

    // 1. Get Lot Information - query by lot_id field
    const lotSnapshot = await db.collection('pepper_lots')
      .where('lot_id', '==', lotId)
      .limit(1)
      .get();

    if (lotSnapshot.empty) {
      return res.status(404).json({
        success: false,
        error: 'Lot not found'
      });
    }

    const lotDoc = lotSnapshot.docs[0];
    const lot = { id: lotDoc.id, ...lotDoc.data() };

    // 2. Get Processing Stages
    const processingSnapshot = await db.collection('processing_stages')
      .where('lot_id', '==', lotId)
      .orderBy('timestamp', 'asc')
      .get();

    const processingStages = [];
    processingSnapshot.forEach(doc => {
      processingStages.push(doc.data());
    });

    // 3. Get Certifications
    const certificationsSnapshot = await db.collection('certifications')
      .where('lot_id', '==', lotId)
      .orderBy('created_at', 'asc')
      .get();

    const certifications = [];
    certificationsSnapshot.forEach(doc => {
      certifications.push(doc.data());
    });

    // 4. Get Compliance Checks
    const complianceSnapshot = await db.collection('compliance_checks')
      .where('lot_id', '==', lotId)
      .orderBy('checked_at', 'desc')
      .get();

    const complianceChecks = [];
    complianceSnapshot.forEach(doc => {
      complianceChecks.push(doc.data());
    });

    // 5. Get Auction History
    const auctionSnapshot = await db.collection('auctions')
      .where('lot_id', '==', lotId)
      .orderBy('created_at', 'desc')
      .get();

    const auctions = [];
    auctionSnapshot.forEach(doc => {
      auctions.push({ id: doc.id, ...doc.data() });
    });

    // 6. Get Bid History for auctions
    let allBids = [];
    for (const auction of auctions) {
      const bidsSnapshot = await db.collection('bids')
        .where('auction_id', '==', auction.id)
        .orderBy('placed_at', 'desc')
        .get();
      
      bidsSnapshot.forEach(doc => {
        const bid = doc.data();
        allBids.push({
          ...bid,
          auction_id: auction.id
        });
      });
    }

    // 7. Get User Information (Farmer)
    let farmerInfo = null;
    if (lot.farmer_address) {
      const farmerSnapshot = await db.collection('users')
        .where('wallet_address', '==', lot.farmer_address)
        .limit(1)
        .get();
      
      if (!farmerSnapshot.empty) {
        farmerInfo = farmerSnapshot.docs[0].data();
      }
    }

    // 8. Get Buyer Information (if sold)
    let buyerInfo = null;
    const soldAuction = auctions.find(a => a.status === 'settled');
    if (soldAuction && soldAuction.current_bidder) {
      const buyerSnapshot = await db.collection('users')
        .where('wallet_address', '==', soldAuction.current_bidder)
        .limit(1)
        .get();
      
      if (!buyerSnapshot.empty) {
        buyerInfo = buyerSnapshot.docs[0].data();
      }
    }

    // 9. Build Complete Timeline
    const timeline = [];

    // Add lot creation
    timeline.push({
      type: 'lot_created',
      timestamp: lot.created_at,
      description: 'Lot registered on blockchain',
      actor: lot.farmer_address,
      actor_name: farmerInfo?.name || 'Farmer',
      blockchain_tx: lot.blockchain_tx_hash,
      data: {
        variety: lot.variety,
        quantity: lot.quantity,
        harvest_date: lot.harvest_date,
        origin: lot.origin
      }
    });

    // Add processing stages
    processingStages.forEach(stage => {
      timeline.push({
        type: 'processing_stage',
        timestamp: stage.timestamp,
        description: `${stage.stage_name} completed`,
        actor: stage.operator_name || lot.farmer_address,
        actor_name: stage.operator_name || 'Farmer',
        blockchain_tx: stage.blockchain_tx_hash,
        data: {
          stage_type: stage.stage_type,
          location: stage.location,
          quality_metrics: stage.quality_metrics,
          notes: stage.notes
        }
      });
    });

    // Add certifications
    certifications.forEach(cert => {
      timeline.push({
        type: 'certification_added',
        timestamp: cert.created_at,
        description: `${cert.cert_type} certification issued`,
        actor: cert.issuer,
        actor_name: cert.issuer,
        blockchain_tx: null,
        data: {
          cert_number: cert.cert_number,
          issue_date: cert.issue_date,
          expiry_date: cert.expiry_date,
          is_valid: cert.is_valid,
          verification_status: cert.verification_status,
          verified_by: cert.verified_by,
          document_hash: cert.document_hash,
          ipfs_url: cert.ipfs_url
        }
      });
    });

    // Add compliance checks
    complianceChecks.forEach(check => {
      timeline.push({
        type: 'compliance_check',
        timestamp: check.checked_at,
        description: `${check.rule_type} rule check: ${check.rule_name}`,
        actor: 'System',
        actor_name: 'Compliance System',
        blockchain_tx: null,
        data: {
          rule_name: check.rule_name,
          rule_type: check.rule_type,
          passed: check.passed,
          details: check.details
        }
      });
    });

    // Add auction events
    auctions.forEach(auction => {
      timeline.push({
        type: 'auction_created',
        timestamp: auction.created_at,
        description: 'Auction created',
        actor: lot.farmer_address,
        actor_name: farmerInfo?.name || 'Farmer',
        blockchain_tx: auction.blockchain_tx_hash,
        data: {
          auction_id: auction.id,
          start_price: auction.start_price,
          reserve_price: auction.reserve_price,
          start_time: auction.start_time,
          end_time: auction.end_time
        }
      });

      if (auction.status === 'ended' || auction.status === 'settled') {
        timeline.push({
          type: 'auction_ended',
          timestamp: auction.end_time,
          description: 'Auction ended',
          actor: 'System',
          actor_name: 'Auction System',
          blockchain_tx: null,
          data: {
            auction_id: auction.id,
            final_price: auction.current_bid,
            winner: auction.current_bidder
          }
        });
      }

      if (auction.status === 'settled') {
        timeline.push({
          type: 'auction_settled',
          timestamp: auction.updated_at || auction.end_time,
          description: 'Ownership transferred to buyer',
          actor: auction.current_bidder,
          actor_name: buyerInfo?.name || 'Buyer',
          blockchain_tx: null,
          data: {
            auction_id: auction.id,
            price_paid: auction.current_bid,
            new_owner: auction.current_bidder
          }
        });
      }
    });

    // Add bid events
    allBids.forEach(bid => {
      timeline.push({
        type: 'bid_placed',
        timestamp: bid.placed_at,
        description: 'Bid placed',
        actor: bid.bidder_address,
        actor_name: 'Bidder',
        blockchain_tx: bid.blockchain_tx_hash,
        data: {
          auction_id: bid.auction_id,
          amount: bid.amount
        }
      });
    });

    // Sort timeline by timestamp
    timeline.sort((a, b) => {
      const aTime = a.timestamp?.toDate ? a.timestamp.toDate() : new Date(a.timestamp);
      const bTime = b.timestamp?.toDate ? b.timestamp.toDate() : new Date(b.timestamp);
      return aTime - bTime;
    });

    // 10. Calculate Statistics
    const stats = {
      total_events: timeline.length,
      processing_stages: processingStages.length,
      certifications: certifications.length,
      compliance_checks: complianceChecks.length,
      auctions: auctions.length,
      total_bids: allBids.length,
      blockchain_transactions: timeline.filter(e => e.blockchain_tx).length,
      days_in_system: lot.created_at ? Math.ceil((new Date() - lot.created_at.toDate()) / (1000 * 60 * 60 * 24)) : 0
    };

    // 11. Determine Current Status
    const passedChecks = complianceChecks.filter(c => c.passed).length;
    const totalChecks = complianceChecks.length;
    const complianceStatus = totalChecks === 0 ? 'not_checked' : 
                            passedChecks === totalChecks ? 'passed' : 
                            passedChecks > 0 ? 'partial' : 'failed';
    
    let currentStatus = {
      stage: lot.status,
      description: getStatusDescription(lot.status),
      current_owner: lot.farmer_address,
      current_owner_name: farmerInfo?.name || 'Farmer',
      compliance_status: complianceStatus,
      compliance_checks_passed: passedChecks,
      compliance_checks_total: totalChecks,
      is_in_auction: auctions.some(a => a.status === 'active')
    };

    if (soldAuction) {
      currentStatus.current_owner = soldAuction.current_bidder;
      currentStatus.current_owner_name = buyerInfo?.name || 'Buyer';
    }

    // 12. Build Response
    const traceabilityData = {
      success: true,
      lot_id: lotId,
      
      // Basic Lot Info
      lot_info: {
        lot_id: lot.lot_id || lotId,
        variety: lot.variety,
        quantity: lot.quantity,
        quality: lot.quality,
        harvest_date: lot.harvest_date,
        origin: lot.origin,
        farm_location: lot.farm_location,
        organic_certified: lot.organic_certified,
        status: lot.status,
        created_at: lot.created_at
      },

      // Blockchain Info
      blockchain_info: {
        primary_tx_hash: lot.blockchain_tx_hash,
        total_transactions: stats.blockchain_transactions,
        certificate_hash: lot.certificate_hash,
        metadata_uri: lot.metadata_uri,
        lot_pictures: lot.lot_pictures,
        certificate_images: lot.certificate_images
      },

      // Current Status
      current_status: currentStatus,

      // Stakeholders
      stakeholders: {
        farmer: farmerInfo || { wallet_address: lot.farmer_address },
        buyer: buyerInfo,
        certifiers: certifications.map(c => c.issuer),
        operators: [...new Set(processingStages.map(p => p.operator_name).filter(Boolean))]
      },

      // Processing History
      processing_stages: processingStages,

      // Certifications
      certifications: certifications,

      // Compliance History
      compliance_checks: complianceChecks,

      // Auction History
      auctions: auctions,

      // Bid History
      bids: allBids,

      // Complete Timeline
      timeline: timeline,

      // Statistics
      statistics: stats
    };

    logger.info('Complete traceability retrieved:', { 
      lotId, 
      events: timeline.length, 
      blockchain_tx: stats.blockchain_transactions 
    });

    // Convert all timestamps before sending response
    res.json(convertTimestamps(traceabilityData));

  } catch (error) {
    logger.error('Error fetching traceability:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch traceability data',
      details: error.message
    });
  }
});

/**
 * Helper function to get status description
 */
function getStatusDescription(status) {
  const descriptions = {
    'available': 'Lot is available and ready for auction',
    'in_auction': 'Lot is currently in an active auction',
    'sold': 'Lot has been sold to a buyer',
    'expired': 'Lot listing has expired',
    'processing': 'Lot is undergoing processing',
    'compliance_check': 'Lot is under compliance review'
  };
  return descriptions[status] || 'Unknown status';
}

/**
 * GET /api/traceability/:lotId/export
 * Export traceability data as JSON
 */
router.get('/:lotId/export', async (req, res) => {
  try {
    const { lotId } = req.params;
    
    // Get complete traceability (reuse the main endpoint logic)
    const response = await router.handle({ params: { lotId } }, res);
    
    res.setHeader('Content-Type', 'application/json');
    res.setHeader('Content-Disposition', `attachment; filename="traceability-${lotId}.json"`);
    
  } catch (error) {
    logger.error('Error exporting traceability:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to export traceability data'
    });
  }
});

module.exports = router;
