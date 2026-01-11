const express = require('express');
const router = express.Router();
const db = require('../db/database');
const logger = require('../utils/logger');

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

    // 1. Get Lot Information
    const lotResult = await db.query(
      `SELECT 
        lot_id,
        farmer_address,
        variety,
        quantity,
        quality,
        harvest_date,
        origin,
        farm_location,
        organic_certified,
        certificate_hash,
        certificate_ipfs_url,
        lot_pictures,
        certificate_images,
        metadata_uri,
        status,
        blockchain_tx_hash,
        created_at,
        updated_at
      FROM pepper_lots 
      WHERE lot_id = $1`,
      [lotId]
    );

    if (lotResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Lot not found'
      });
    }

    const lot = lotResult.rows[0];

    // 2. Get Processing Stages
    const processingResult = await db.query(
      `SELECT 
        stage_type,
        stage_name,
        location,
        operator_name,
        quality_metrics,
        notes,
        blockchain_tx_hash,
        timestamp
      FROM processing_stages 
      WHERE lot_id = $1 
      ORDER BY timestamp ASC`,
      [lotId]
    );

    // 3. Get Certifications
    const certificationsResult = await db.query(
      `SELECT 
        cert_type,
        cert_number,
        issuer,
        issue_date,
        expiry_date,
        document_hash,
        ipfs_url,
        is_valid,
        verification_status,
        verified_by,
        verified_at,
        created_at
      FROM certifications 
      WHERE lot_id = $1 
      ORDER BY created_at ASC`,
      [lotId]
    );

    // 4. Get Compliance Checks
    const complianceResult = await db.query(
      `SELECT 
        rule_name,
        rule_type,
        passed,
        details,
        checked_at
      FROM compliance_checks 
      WHERE lot_id = $1 
      ORDER BY checked_at DESC`,
      [lotId]
    );

    // 5. Get Auction History
    const auctionResult = await db.query(
      `SELECT 
        auction_id,
        start_price,
        reserve_price,
        current_bid,
        current_bidder,
        start_time,
        end_time,
        status,
        compliance_passed,
        blockchain_tx_hash,
        created_at
      FROM auctions 
      WHERE lot_id = $1 
      ORDER BY created_at DESC`,
      [lotId]
    );

    // 6. Get Bid History for auctions
    let allBids = [];
    if (auctionResult.rows.length > 0) {
      for (const auction of auctionResult.rows) {
        const bidsResult = await db.query(
          `SELECT 
            bidder_address,
            amount,
            blockchain_tx_hash,
            placed_at
          FROM bids 
          WHERE auction_id = $1 
          ORDER BY placed_at DESC`,
          [auction.auction_id]
        );
        
        allBids = allBids.concat(bidsResult.rows.map(bid => ({
          ...bid,
          auction_id: auction.auction_id
        })));
      }
    }

    // 7. Get User Information (Farmer)
    const farmerResult = await db.query(
      `SELECT 
        wallet_address,
        user_type,
        name,
        email,
        location
      FROM users 
      WHERE wallet_address = $1`,
      [lot.farmer_address]
    );

    // 8. Get Buyer Information (if sold)
    let buyerInfo = null;
    const soldAuction = auctionResult.rows.find(a => a.status === 'settled');
    if (soldAuction && soldAuction.current_bidder) {
      const buyerResult = await db.query(
        `SELECT 
          wallet_address,
          user_type,
          name,
          email,
          location
        FROM users 
        WHERE wallet_address = $1`,
        [soldAuction.current_bidder]
      );
      buyerInfo = buyerResult.rows[0] || null;
    }

    // 9. Build Complete Timeline
    const timeline = [];

    // Add lot creation
    timeline.push({
      type: 'lot_created',
      timestamp: lot.created_at,
      description: 'Lot registered on blockchain',
      actor: lot.farmer_address,
      actor_name: farmerResult.rows[0]?.name || 'Farmer',
      blockchain_tx: lot.blockchain_tx_hash,
      data: {
        variety: lot.variety,
        quantity: lot.quantity,
        harvest_date: lot.harvest_date,
        origin: lot.origin
      }
    });

    // Add processing stages
    processingResult.rows.forEach(stage => {
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
    certificationsResult.rows.forEach(cert => {
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
    complianceResult.rows.forEach(check => {
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
    auctionResult.rows.forEach(auction => {
      timeline.push({
        type: 'auction_created',
        timestamp: auction.created_at,
        description: 'Auction created',
        actor: lot.farmer_address,
        actor_name: farmerResult.rows[0]?.name || 'Farmer',
        blockchain_tx: auction.blockchain_tx_hash,
        data: {
          auction_id: auction.auction_id,
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
            auction_id: auction.auction_id,
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
            auction_id: auction.auction_id,
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
    timeline.sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp));

    // 10. Calculate Statistics
    const stats = {
      total_events: timeline.length,
      processing_stages: processingResult.rows.length,
      certifications: certificationsResult.rows.length,
      compliance_checks: complianceResult.rows.length,
      auctions: auctionResult.rows.length,
      total_bids: allBids.length,
      blockchain_transactions: timeline.filter(e => e.blockchain_tx).length,
      days_in_system: Math.ceil((new Date() - new Date(lot.created_at)) / (1000 * 60 * 60 * 24))
    };

    // 11. Determine Current Status
    const passedChecks = complianceResult.rows.filter(c => c.passed).length;
    const totalChecks = complianceResult.rows.length;
    const complianceStatus = totalChecks === 0 ? 'not_checked' : 
                            passedChecks === totalChecks ? 'passed' : 
                            passedChecks > 0 ? 'partial' : 'failed';
    
    let currentStatus = {
      stage: lot.status,
      description: getStatusDescription(lot.status),
      current_owner: lot.farmer_address,
      current_owner_name: farmerResult.rows[0]?.name || 'Farmer',
      compliance_status: complianceStatus,
      compliance_checks_passed: passedChecks,
      compliance_checks_total: totalChecks,
      is_in_auction: auctionResult.rows.some(a => a.status === 'active')
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
        lot_id: lot.lot_id,
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
        farmer: farmerResult.rows[0] || { wallet_address: lot.farmer_address },
        buyer: buyerInfo,
        certifiers: certificationsResult.rows.map(c => c.issuer),
        operators: [...new Set(processingResult.rows.map(p => p.operator_name).filter(Boolean))]
      },

      // Processing History
      processing_stages: processingResult.rows,

      // Certifications
      certifications: certificationsResult.rows,

      // Compliance History
      compliance_checks: complianceResult.rows,

      // Auction History
      auctions: auctionResult.rows,

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

    res.json(traceabilityData);

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
