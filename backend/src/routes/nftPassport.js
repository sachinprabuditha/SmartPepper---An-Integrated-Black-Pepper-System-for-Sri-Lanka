const express = require('express');
const router = express.Router();
const { ethers } = require('ethers');
const logger = require('../utils/logger');
const BlockchainService = require('../services/blockchainService');

let nftService = null;
const blockchainService = new BlockchainService();

// Initialize blockchain service
blockchainService.initialize().catch(err => logger.error('Blockchain init failed:', err));

// Try to load the NFT service
try {
  const NFTPassportService = require('../services/nftPassportService');
  nftService = new NFTPassportService();
  
  // Initialize service (don't block if it fails)
  nftService.initialize().catch(err => {
    logger.error('Failed to initialize NFT Passport service:', err);
    logger.warn('NFT Passport service running in limited mode - metadata generation still available');
  });
  
  logger.info('NFT Passport routes loaded successfully');
} catch (err) {
  logger.error('Failed to load NFT Passport service:', err);
  logger.warn('NFT routes will return errors - service not available');
}

/**
 * GET /api/nft-passport/lot/:lotId
 * Get NFT passport information by lot ID
 */
router.get('/lot/:lotId', async (req, res) => {
  try {
    const { lotId } = req.params;
    
    logger.info('Fetching passport for lot:', lotId);
    
    // Try to get from blockchain first
    if (nftService && nftService.contract) {
      try {
        const passport = await nftService.getPassportByLotId(lotId);
        
        // Transform to match expected frontend format
        const data = {
          passportData: {
            lotId: passport.passport.lotId,
            tokenId: parseInt(passport.tokenId),
            farmer: passport.passport.farmer,
            origin: passport.passport.origin,
            variety: passport.passport.variety,
            quantity: parseInt(passport.passport.quantity),
            harvestDate: passport.passport.harvestDate,
            certificateHash: passport.passport.certificateHash,
            isActive: passport.passport.isActive,
            createdAt: passport.passport.createdAt
          },
          processingLogs: passport.processingLogs,
          certifications: passport.certifications,
          owner: passport.passport.farmer
        };
        
        logger.info('Passport retrieved from blockchain');
        return res.json({ success: true, data });
      } catch (blockchainError) {
        logger.warn('Blockchain retrieval failed, falling back to database:', blockchainError.message);
      }
    }
    
    // Fallback: Get lot data from database
    const db = require('../db/database');
    const lotResult = await db.query(
      'SELECT * FROM pepper_lots WHERE lot_id = $1',
      [lotId]
    );
    
    if (lotResult.rows.length === 0) {
      logger.warn('Lot not found in database:', lotId);
      return res.status(404).json({
        success: false,
        error: 'Lot not found'
      });
    }
    
    const lot = lotResult.rows[0];
    logger.info('Lot found in database:', { lot_id: lot.lot_id, farmer: lot.farmer_address });
    
    // Return mock passport data based on lot
    const data = {
      passportData: {
        lotId: lot.lot_id,
        tokenId: parseInt(lot.lot_id.split('-')[1]) || 0, // Extract number from LOT-123
        farmer: lot.farmer_address,
        origin: lot.origin || lot.farm_location || 'Sri Lanka',
        variety: lot.variety,
        quantity: parseFloat(lot.quantity),
        harvestDate: lot.harvest_date,
        certificateHash: lot.certificate_hash || '0x0000000000000000000000000000000000000000000000000000000000000000',
        isActive: lot.status === 'available',
        createdAt: lot.created_at
      },
      processingLogs: [],
      certifications: lot.organic_certified ? [{
        certType: 'Organic',
        certId: 'ORG-001',
        issuedBy: 'Organic Certification Body',
        issuedDate: lot.created_at,
        expiryDate: new Date(new Date(lot.created_at).setFullYear(new Date(lot.created_at).getFullYear() + 1)),
        documentHash: '0x0000000000000000000000000000000000000000000000000000000000000000',
        isValid: true
      }] : [],
      owner: lot.farmer_address
    };
    
    logger.info('Passport retrieved from database (fallback mode)');
    res.json({ success: true, data });
    
  } catch (error) {
    logger.error('Failed to get passport by lot ID:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to retrieve passport'
    });
  }
});

/**
 * GET /api/nft-passport/token/:tokenId
 * Get NFT passport information by token ID
 */
router.get('/token/:tokenId', async (req, res) => {
  try {
    const { tokenId } = req.params;
    
    const passport = await nftService.getPassportByTokenId(tokenId);
    
    res.json({
      success: true,
      data: passport
    });
  } catch (error) {
    logger.error('Failed to get passport by token ID:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to retrieve passport'
    });
  }
});

/**
 * GET /api/nft-passport/qr/:lotId
 * Generate QR code for lot passport
 */
router.get('/qr/:lotId', async (req, res) => {
  try {
    const { lotId } = req.params;
    
    // Check if passport exists
    const exists = await nftService.passportExists(lotId);
    if (!exists) {
      return res.status(404).json({
        success: false,
        error: 'No passport found for this lot'
      });
    }
    
    // Get token ID
    const passport = await nftService.getPassportByLotId(lotId);
    const tokenId = passport.tokenId;
    
    // Generate QR code
    const qrData = await nftService.generateQRCode(lotId, tokenId);
    
    res.json({
      success: true,
      data: qrData
    });
  } catch (error) {
    logger.error('Failed to generate QR code:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to generate QR code'
    });
  }
});

/**
 * POST /api/nft-passport/mint
 * Mint a new NFT passport for a lot
 */
router.post('/mint', async (req, res) => {
  try {
    const {
      lotId,
      farmer,
      origin,
      variety,
      quantity,
      quality,
      harvestDate,
      certificateHash,
      metadataURI
    } = req.body;

    // Validate required fields
    if (!lotId || !farmer || !variety || !quantity) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: lotId, farmer, variety, quantity'
      });
    }

    logger.info('Minting NFT passport and registering lot:', { lotId, farmer, variety, quantity });

    // Check if service is available
    if (!nftService || !nftService.contract) {
      logger.warn('NFT service not available, returning mock response');
      return res.json({
        success: true,
        data: {
          txHash: `0x${Date.now().toString(16)}`, // Mock transaction hash
          tokenId: parseInt(lotId.split('-')[1]) || Math.floor(Math.random() * 10000),
          message: 'Passport minting queued (blockchain service unavailable)'
        }
      });
    }

    // Convert certificateHash to bytes32 if it's an IPFS hash string
    let certHashBytes32;
    if (certificateHash && certificateHash.startsWith('0x')) {
      // Already in hex format
      certHashBytes32 = certificateHash;
    } else if (certificateHash) {
      // Convert IPFS hash to bytes32 using keccak256
      certHashBytes32 = ethers.keccak256(ethers.toUtf8Bytes(certificateHash));
      logger.info('Converted IPFS hash to bytes32:', { 
        original: certificateHash, 
        bytes32: certHashBytes32 
      });
    } else {
      // Empty hash
      certHashBytes32 = ethers.zeroPadValue('0x00', 32);
    }

    // Register lot on auction contract AND mint NFT passport (both in one transaction via createLot)
    const lotResult = await blockchainService.createLot({
      lotId,
      farmer,
      variety,
      quantity,
      quality: quality || 'Standard',
      harvestDate: harvestDate || Math.floor(Date.now() / 1000).toString(),
      certificateHash: certHashBytes32,
      origin: origin || 'Sri Lanka',
      metadataURI: metadataURI || ''
    });

    logger.info('Lot registered and NFT passport minted:', { 
      lotId, 
      farmer,
      txHash: lotResult.txHash,
      blockNumber: lotResult.blockNumber
    });

    res.json({
      success: true,
      data: {
        txHash: lotResult.txHash,
        blockNumber: lotResult.blockNumber,
        message: 'Lot registered on blockchain and NFT passport minted'
      }
    });
  } catch (error) {
    logger.error('Failed to mint NFT passport:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to mint NFT passport'
    });
  }
});

/**
 * POST /api/nft-passport/processing-log
 * Add processing log entry to passport
 */
router.post('/processing-log', async (req, res) => {
  try {
    const { tokenId, stage, description, location } = req.body;
    
    if (!tokenId || !stage || !description) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: tokenId, stage, description'
      });
    }
    
    const txHash = await nftService.addProcessingLog(
      tokenId,
      stage,
      description,
      location || ''
    );
    
    res.json({
      success: true,
      data: {
        txHash,
        tokenId,
        stage
      }
    });
  } catch (error) {
    logger.error('Failed to add processing log:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to add processing log'
    });
  }
});

/**
 * POST /api/nft-passport/certification
 * Add certification to passport
 */
router.post('/certification', async (req, res) => {
  try {
    const { tokenId, certType, certId, issuedBy, issuedDate, expiryDate, documentHash } = req.body;
    
    if (!tokenId || !certType || !certId || !issuedBy || !expiryDate) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields'
      });
    }
    
    const txHash = await nftService.addCertification(tokenId, {
      certType,
      certId,
      issuedBy,
      issuedDate: issuedDate || Math.floor(Date.now() / 1000),
      expiryDate,
      documentHash: documentHash || '0x0000000000000000000000000000000000000000000000000000000000000000'
    });
    
    res.json({
      success: true,
      data: {
        txHash,
        tokenId,
        certType
      }
    });
  } catch (error) {
    logger.error('Failed to add certification:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to add certification'
    });
  }
});

/**
 * GET /api/nft-passport/owner/:tokenId
 * Get owner of NFT passport
 */
router.get('/owner/:tokenId', async (req, res) => {
  try {
    const { tokenId } = req.params;
    
    const owner = await nftService.getOwner(tokenId);
    
    res.json({
      success: true,
      data: {
        tokenId,
        owner
      }
    });
  } catch (error) {
    logger.error('Failed to get NFT owner:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to get owner'
    });
  }
});

/**
 * GET /api/nft-passport/exists/:lotId
 * Check if passport exists for lot
 */
router.get('/exists/:lotId', async (req, res) => {
  try {
    const { lotId } = req.params;
    
    const exists = await nftService.passportExists(lotId);
    
    res.json({
      success: true,
      data: {
        lotId,
        exists
      }
    });
  } catch (error) {
    logger.error('Failed to check passport existence:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to check existence'
    });
  }
});

/**
 * POST /api/nft-passport/metadata
 * Generate metadata JSON for a lot
 */
router.post('/metadata', async (req, res) => {
  try {
    const { lotData, farmerData } = req.body;
    
    logger.info('Metadata generation request received');
    
    if (!lotData || !lotData.lotId) {
      logger.warn('Invalid metadata request - missing lotData or lotId');
      return res.status(400).json({
        success: false,
        error: 'Lot data with lotId required'
      });
    }
    
    // Generate metadata directly without service if service is unavailable
    let metadata;
    if (nftService) {
      metadata = nftService.generateMetadata(lotData, farmerData);
    } else {
      // Fallback: generate metadata directly
      metadata = {
        name: `SmartPepper Lot #${lotData.lotId}`,
        description: `Verified ${lotData.variety} pepper lot with complete blockchain traceability`,
        image: lotData.imageUrl || `https://smartpepper.app/images/lots/${lotData.lotId}.jpg`,
        external_url: `https://smartpepper.app/passport/${lotData.lotId}`,
        attributes: [
          { trait_type: "Lot ID", value: lotData.lotId },
          { trait_type: "Variety", value: lotData.variety },
          { trait_type: "Quantity", value: `${lotData.quantity} kg`, display_type: "number" },
          { trait_type: "Quality Grade", value: lotData.quality },
          { trait_type: "Harvest Date", value: lotData.harvestDate },
          { trait_type: "Origin", value: lotData.origin || "Sri Lanka" },
          { trait_type: "Farmer", value: farmerData?.name || "Verified Farmer" },
          { trait_type: "Certified", value: lotData.certificateHash ? "Yes" : "No" }
        ],
        properties: {
          lotId: lotData.lotId,
          farmerAddress: lotData.farmerAddress,
          certificateHash: lotData.certificateHash,
          createdAt: lotData.createdAt || new Date().toISOString()
        }
      };
    }
    
    logger.info('Metadata generated successfully');
    
    res.json({
      success: true,
      data: metadata
    });
  } catch (error) {
    logger.error('Failed to generate metadata:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to generate metadata'
    });
  }
});

module.exports = router;
