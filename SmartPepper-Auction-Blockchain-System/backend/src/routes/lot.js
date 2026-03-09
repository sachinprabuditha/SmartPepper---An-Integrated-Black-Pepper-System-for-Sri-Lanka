const express = require('express');
const router = express.Router();
const db = require('../db/database');
const logger = require('../utils/logger');
const admin = require('firebase-admin');

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
 * GET /api/lots
 * Get all pepper lots
 */
router.get('/', async (req, res) => {
  try {
    const { status, farmer, limit = 50, offset = 0 } = req.query;
    
    const firestore = db.getDb();
    let query = firestore.collection('pepper_lots');
    let countQuery = firestore.collection('pepper_lots');

    // Apply filters
    if (status) {
      query = query.where('status', '==', status);
      countQuery = countQuery.where('status', '==', status);
    }

    if (farmer) {
      // Check if farmer is a wallet address (starts with 0x) or a user ID
      if (farmer.startsWith('0x')) {
        // Filter by wallet address
        const farmerLower = farmer.toLowerCase();
        query = query.where('farmer_address_lower', '==', farmerLower);
        countQuery = countQuery.where('farmer_address_lower', '==', farmerLower);
        logger.info('Filtering lots by wallet address:', { farmer, farmerLower });
      } else {
        // Filter by user ID (farmer_id)
        query = query.where('farmer_id', '==', farmer);
        countQuery = countQuery.where('farmer_id', '==', farmer);
        logger.info('Filtering lots by farmer ID:', { farmer });
      }
    }

    // Get count
    const countSnap = await countQuery.get();
    const count = countSnap.size;

    // Get paginated results
    query = query.orderBy('created_at', 'desc')
      .limit(parseInt(limit))
      .offset(parseInt(offset));
    
    const lotsSnap = await query.get();
    const lots = lotsSnap.docs.map(doc => {
      const data = doc.data();
      return convertTimestamps({ id: doc.id, ...data });
    });

    // Fetch farmer names for all lots
    for (let lot of lots) {
      let farmerData = null;
      
      // Try to find farmer by ID first
      if (lot.farmer_id) {
        try {
          const farmerDoc = await firestore.collection('users').doc(lot.farmer_id).get();
          if (farmerDoc.exists) {
            farmerData = farmerDoc.data();
          }
        } catch (error) {
          logger.error('Error fetching farmer by ID:', error);
        }
      }
      
      // If no farmer found by ID, try by wallet address
      if (!farmerData && lot.farmer_address) {
        try {
          const farmerSnapshot = await firestore.collection('users')
            .where('wallet_address_lower', '==', lot.farmer_address.toLowerCase())
            .limit(1)
            .get();
          
          if (!farmerSnapshot.empty) {
            farmerData = farmerSnapshot.docs[0].data();
          }
        } catch (error) {
          logger.error('Error fetching farmer by wallet:', error);
        }
      }
      
      // Add farmer name to lot
      if (farmerData) {
        lot.farmer_name = farmerData.name || 'Unknown Farmer';
      } else {
        lot.farmer_name = 'Unknown Farmer';
      }
    }

    logger.info('Query results:', { 
      count,
      lotsReturned: lots.length,
      firstLot: lots[0] ? { lot_id: lots[0].lot_id, farmer: lots[0].farmer_address, farmer_name: lots[0].farmer_name } : null
    });

    res.json({
      success: true,
      count,
      lots
    });
  } catch (error) {
    logger.error('Error fetching lots:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch lots'
    });
  }
});

/**
 * GET /api/lots/:lotId
 * Get lot details with farmer information
 */
router.get('/:lotId', async (req, res) => {
  try {
    const { lotId } = req.params;
    
    const firestore = db.getDb();
    const lotsSnap = await firestore.collection('pepper_lots')
      .where('lot_id', '==', lotId)
      .limit(1)
      .get();

    if (lotsSnap.empty) {
      return res.status(404).json({
        success: false,
        error: 'Lot not found'
      });
    }

    const lotDoc = lotsSnap.docs[0];
    const lot = convertTimestamps({ id: lotDoc.id, ...lotDoc.data() });

    // Fetch farmer details
    let farmerData = null;
    
    if (lot.farmer_id) {
      const farmerDoc = await firestore.collection('users').doc(lot.farmer_id).get();
      if (farmerDoc.exists) {
        farmerData = farmerDoc.data();
        logger.info('Found farmer by ID:', { farmer_id: lot.farmer_id, name: farmerData.name });
      }
    }
    
    // If no farmer found by ID, try by wallet address
    if (!farmerData && lot.farmer_address) {
      const farmerSnapshot = await firestore.collection('users')
        .where('wallet_address_lower', '==', lot.farmer_address.toLowerCase())
        .limit(1)
        .get();
      
      if (!farmerSnapshot.empty) {
        farmerData = farmerSnapshot.docs[0].data();
        logger.info('Found farmer by wallet:', { wallet: lot.farmer_address, name: farmerData.name });
      } else {
        logger.warn('No farmer found for wallet:', lot.farmer_address);
      }
    }
    
    // Add farmer details to lot if found
    if (farmerData) {
      lot.farmer_name = farmerData.name || 'Unknown Farmer';
      lot.farmer_email = farmerData.email;
      lot.farmer_phone = farmerData.phone;
    } else {
      logger.warn('No farmer data available for lot:', lotId);
    }

    res.json({
      success: true,
      lot
    });
  } catch (error) {
    logger.error('Error fetching lot:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch lot'
    });
  }
});

/**
 * POST /api/lots
 * Create a new pepper lot
 */
router.post('/', async (req, res) => {
  try {
    const {
      lotId,
      farmerAddress,
      farmerName,
      farmerEmail,
      farmerPhone,
      variety,
      quantity,
      quality,
      harvestDate,
      origin,
      farmLocation,
      organicCertified,
      metadataURI,
      certificateHash,
      certificateIpfsUrl,
      lotPictures,
      certificateImages,
      txHash
    } = req.body;

    // Validate required fields
    if (!lotId || !farmerAddress || !variety || !quantity) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields'
      });
    }

    logger.info('Creating new lot:', { 
      lotId, 
      farmerAddress,
      farmerName,
      farmerEmail,
      farmerPhone,
      variety, 
      quantity,
      origin,
      farmLocation,
      lotPictures: lotPictures ? lotPictures.length : 0,
      certificateImages: certificateImages ? certificateImages.length : 0
    });

    const firestore = db.getDb();
    const farmerLower = farmerAddress.toLowerCase();

    // Get or create farmer (case-insensitive lookup)
    const farmerSnap = await firestore.collection('users')
      .where('wallet_address_lower', '==', farmerLower)
      .limit(1)
      .get();

    let farmerId;
    if (farmerSnap.empty) {
      // Create new farmer user with provided details
      logger.info('Creating new farmer user:', { farmerAddress, farmerName, farmerEmail, farmerPhone });
      const newFarmerData = {
        name: farmerName || 'Unknown Farmer',
        wallet_address: farmerAddress,
        wallet_address_lower: farmerLower,
        user_type: 'farmer',
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp()
      };
      
      // Add optional fields if provided
      if (farmerEmail) newFarmerData.email = farmerEmail;
      if (farmerPhone) newFarmerData.phone = farmerPhone;
      
      const newFarmerRef = await firestore.collection('users').add(newFarmerData);
      farmerId = newFarmerRef.id;
      logger.info('New farmer created with ID:', farmerId);
    } else {
      farmerId = farmerSnap.docs[0].id;
      logger.info('Found existing farmer with ID:', farmerId);
      
      // Update farmer details if provided and different
      const existingFarmer = farmerSnap.docs[0].data();
      const updates = {};
      
      if (farmerName && existingFarmer.name !== farmerName) {
        updates.name = farmerName;
      }
      if (farmerEmail && existingFarmer.email !== farmerEmail) {
        updates.email = farmerEmail;
      }
      if (farmerPhone && existingFarmer.phone !== farmerPhone) {
        updates.phone = farmerPhone;
      }
      
      if (Object.keys(updates).length > 0) {
        updates.updated_at = admin.firestore.FieldValue.serverTimestamp();
        await firestore.collection('users').doc(farmerId).update(updates);
        logger.info('Updated farmer details:', { farmerId, updates });
      }
    }

    // Insert lot
    const lotData = {
      lot_id: lotId,
      farmer_id: farmerId,
      farmer_address: farmerAddress,
      farmer_address_lower: farmerLower,
      variety,
      quantity,
      quality: quality || null,
      harvest_date: harvestDate || null,
      origin: origin || null,
      farm_location: farmLocation || null,
      organic_certified: organicCertified || false,
      metadata_uri: metadataURI || null,
      certificate_hash: certificateHash || null,
      certificate_ipfs_url: certificateIpfsUrl || null,
      lot_pictures: lotPictures || [],
      certificate_images: certificateImages || [],
      blockchain_tx_hash: txHash || null,
      status: 'available',
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    };

    const lotRef = await firestore.collection('pepper_lots').add(lotData);
    const lotDoc = await lotRef.get();
    const lot = { id: lotDoc.id, ...lotDoc.data() };

    logger.info('✅ Lot created successfully:', { 
      lotId, 
      farmerAddress, 
      farmer_id: farmerId,
      lot_db_id: lot.id 
    });

    res.status(201).json({
      success: true,
      lot,
      message: 'Lot created successfully'
    });
  } catch (error) {
    logger.error('Error creating lot:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to create lot',
      details: error.message
    });
  }
});

/**
 * GET /api/lots/farmer/:address
 * Get lots for a specific farmer with optional compliance status filter
 */
router.get('/farmer/:address', async (req, res) => {
  try {
    const { address } = req.params;
    const { compliance_status } = req.query;
    
    const firestore = db.getDb();
    const addressLower = address.toLowerCase();
    let query = firestore.collection('pepper_lots')
      .where('farmer_address_lower', '==', addressLower);
    
    if (compliance_status) {
      query = query.where('compliance_status', '==', compliance_status);
    }
    
    query = query.orderBy('created_at', 'desc');
    
    const lotsSnap = await query.get();
    const lots = lotsSnap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    
    res.json({
      success: true,
      lots
    });
  } catch (error) {
    logger.error('Error fetching farmer lots:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch lots',
      details: error.message
    });
  }
});

module.exports = router;
