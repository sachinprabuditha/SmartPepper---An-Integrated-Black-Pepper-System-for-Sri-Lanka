const { ethers } = require('ethers');
const logger = require('../utils/logger');
const QRCode = require('qrcode');
const crypto = require('crypto');

const PASSPORT_CONTRACT_ABI = [
  "event PassportMinted(uint256 indexed tokenId, string indexed lotId, address indexed farmer, string metadataURI)",
  "event ProcessingLogAdded(uint256 indexed tokenId, string stage, uint256 timestamp)",
  "event CertificationAdded(uint256 indexed tokenId, string certType, string certId, uint256 expiryDate)",
  "event PassportTransferred(uint256 indexed tokenId, address indexed from, address indexed to, uint256 timestamp)",
  "function mintPassport(address farmer, string memory lotId, string memory variety, uint256 quantity, string memory harvestDate, string memory origin, bytes32 certificateHash, string memory metadataURI) external returns (uint256)",
  "function addProcessingLog(uint256 tokenId, string memory stage, string memory description, string memory location) external",
  "function addCertification(uint256 tokenId, string memory certType, string memory certId, string memory issuedBy, uint256 issuedDate, uint256 expiryDate, bytes32 documentHash) external",
  "function getPassportByLotId(string memory lotId) external view returns (uint256 tokenId, tuple(string lotId, address farmer, uint256 createdAt, string origin, string variety, uint256 quantity, string harvestDate, bytes32 certificateHash, bool isActive) passport, tuple(string stage, string description, uint256 timestamp, address recordedBy, string location)[] logs, tuple(string certType, string certId, string issuedBy, uint256 issuedDate, uint256 expiryDate, bytes32 documentHash, bool isValid)[] certs)",
  "function getPassportInfo(uint256 tokenId) external view returns (tuple(string lotId, address farmer, uint256 createdAt, string origin, string variety, uint256 quantity, string harvestDate, bytes32 certificateHash, bool isActive) passport, tuple(string stage, string description, uint256 timestamp, address recordedBy, string location)[] logs, tuple(string certType, string certId, string issuedBy, uint256 issuedDate, uint256 expiryDate, bytes32 documentHash, bool isValid)[] certs, string metadataURI)",
  "function lotIdToTokenId(string memory lotId) external view returns (uint256)",
  "function ownerOf(uint256 tokenId) external view returns (address)",
  "function tokenURI(uint256 tokenId) external view returns (string memory)"
];

class NFTPassportService {
  constructor() {
    this.provider = null;
    this.wallet = null;
    this.contract = null;
    this.ipfsClient = null;
  }

  async initialize() {
    try {
      // Initialize blockchain connection
      const rpcUrl = process.env.BLOCKCHAIN_RPC_URL || 'http://127.0.0.1:8545';
      this.provider = new ethers.JsonRpcProvider(rpcUrl);
      
      const privateKey = process.env.PRIVATE_KEY;
      if (!privateKey) {
        logger.warn('PRIVATE_KEY not found in environment - blockchain features disabled');
        return; // Don't throw, just return
      }
      
      this.wallet = new ethers.Wallet(privateKey, this.provider);
      
      const contractAddress = process.env.PASSPORT_CONTRACT_ADDRESS;
      if (contractAddress) {
        this.contract = new ethers.Contract(
          contractAddress,
          PASSPORT_CONTRACT_ABI,
          this.wallet
        );
        logger.info('NFT Passport service initialized', { contractAddress });
      } else {
        logger.warn('PASSPORT_CONTRACT_ADDRESS not set - NFT features disabled');
      }

      // Try to initialize IPFS client
      try {
        const { create } = require('ipfs-http-client');
        this.ipfsClient = create({
          host: process.env.IPFS_HOST || 'localhost',
          port: process.env.IPFS_PORT || 5001,
          protocol: process.env.IPFS_PROTOCOL || 'http'
        });
        logger.info('IPFS client initialized for NFT metadata');
      } catch (ipfsError) {
        logger.warn('IPFS not available - metadata will be generated locally', ipfsError.message);
      }

    } catch (error) {
      logger.error('Failed to initialize NFT Passport service:', error);
      // Don't re-throw - allow service to continue in limited mode
    }
  }

  /**
   * Generate metadata JSON for NFT passport
   */
  generateMetadata(lotData, farmerData = {}) {
    const metadata = {
      name: `SmartPepper Lot #${lotData.lotId}`,
      description: `Verified ${lotData.variety} pepper lot with complete blockchain traceability`,
      image: lotData.imageUrl || `https://smartpepper.app/images/lots/${lotData.lotId}.jpg`,
      external_url: `https://smartpepper.app/passport/${lotData.lotId}`,
      attributes: [
        {
          trait_type: "Lot ID",
          value: lotData.lotId
        },
        {
          trait_type: "Variety",
          value: lotData.variety
        },
        {
          trait_type: "Quantity",
          value: `${lotData.quantity} kg`,
          display_type: "number"
        },
        {
          trait_type: "Quality Grade",
          value: lotData.quality
        },
        {
          trait_type: "Harvest Date",
          value: lotData.harvestDate
        },
        {
          trait_type: "Origin",
          value: lotData.origin || "Sri Lanka"
        },
        {
          trait_type: "Farmer",
          value: farmerData.name || "Verified Farmer"
        },
        {
          trait_type: "Certified",
          value: lotData.certificateHash ? "Yes" : "No"
        }
      ],
      properties: {
        lotId: lotData.lotId,
        farmerAddress: lotData.farmerAddress,
        certificateHash: lotData.certificateHash,
        createdAt: lotData.createdAt || new Date().toISOString()
      }
    };

    return metadata;
  }

  /**
   * Upload metadata to IPFS
   */
  async uploadMetadataToIPFS(metadata) {
    if (!this.ipfsClient) {
      // Return local JSON string if IPFS not available
      const metadataString = JSON.stringify(metadata, null, 2);
      const hash = crypto.createHash('sha256').update(metadataString).digest('hex');
      logger.warn('IPFS not available, using local metadata with hash:', hash);
      return `local://${hash}`;
    }

    try {
      const metadataString = JSON.stringify(metadata, null, 2);
      const result = await this.ipfsClient.add(metadataString);
      const ipfsUrl = `ipfs://${result.path}`;
      logger.info('Metadata uploaded to IPFS:', ipfsUrl);
      return ipfsUrl;
    } catch (error) {
      logger.error('Failed to upload to IPFS:', error);
      // Fallback to local
      const metadataString = JSON.stringify(metadata, null, 2);
      const hash = crypto.createHash('sha256').update(metadataString).digest('hex');
      return `local://${hash}`;
    }
  }

  /**
   * Generate QR code for lot passport
   */
  async generateQRCode(lotId, tokenId) {
    try {
      const passportUrl = `https://smartpepper.app/passport/${lotId}`;
      const qrCodeDataUrl = await QRCode.toDataURL(passportUrl, {
        width: 300,
        margin: 2,
        color: {
          dark: '#000000',
          light: '#FFFFFF'
        }
      });
      
      logger.info('QR code generated', { lotId, tokenId });
      return {
        url: passportUrl,
        qrCode: qrCodeDataUrl,
        tokenId
      };
    } catch (error) {
      logger.error('Failed to generate QR code:', error);
      throw error;
    }
  }

  /**
   * Get passport information by lot ID
   */
  async getPassportByLotId(lotId) {
    if (!this.contract) {
      throw new Error('NFT Passport contract not initialized');
    }

    try {
      const result = await this.contract.getPassportByLotId(lotId);
      
      return {
        tokenId: result.tokenId.toString(),
        passport: {
          lotId: result.passport.lotId,
          farmer: result.passport.farmer,
          createdAt: new Date(Number(result.passport.createdAt) * 1000),
          origin: result.passport.origin,
          variety: result.passport.variety,
          quantity: result.passport.quantity.toString(),
          harvestDate: result.passport.harvestDate,
          certificateHash: result.passport.certificateHash,
          isActive: result.passport.isActive
        },
        processingLogs: result.logs.map(log => ({
          stage: log.stage,
          description: log.description,
          timestamp: new Date(Number(log.timestamp) * 1000),
          recordedBy: log.recordedBy,
          location: log.location
        })),
        certifications: result.certs.map(cert => ({
          certType: cert.certType,
          certId: cert.certId,
          issuedBy: cert.issuedBy,
          issuedDate: new Date(Number(cert.issuedDate) * 1000),
          expiryDate: new Date(Number(cert.expiryDate) * 1000),
          documentHash: cert.documentHash,
          isValid: cert.isValid
        }))
      };
    } catch (error) {
      logger.error('Failed to get passport:', error);
      throw error;
    }
  }

  /**
   * Get passport information by token ID
   */
  async getPassportByTokenId(tokenId) {
    if (!this.contract) {
      throw new Error('NFT Passport contract not initialized');
    }

    try {
      const result = await this.contract.getPassportInfo(tokenId);
      
      return {
        tokenId: tokenId.toString(),
        passport: {
          lotId: result.passport.lotId,
          farmer: result.passport.farmer,
          createdAt: new Date(Number(result.passport.createdAt) * 1000),
          origin: result.passport.origin,
          variety: result.passport.variety,
          quantity: result.passport.quantity.toString(),
          harvestDate: result.passport.harvestDate,
          certificateHash: result.passport.certificateHash,
          isActive: result.passport.isActive
        },
        processingLogs: result.logs.map(log => ({
          stage: log.stage,
          description: log.description,
          timestamp: new Date(Number(log.timestamp) * 1000),
          recordedBy: log.recordedBy,
          location: log.location
        })),
        certifications: result.certs.map(cert => ({
          certType: cert.certType,
          certId: cert.certId,
          issuedBy: cert.issuedBy,
          issuedDate: new Date(Number(cert.issuedDate) * 1000),
          expiryDate: new Date(Number(cert.expiryDate) * 1000),
          documentHash: cert.documentHash,
          isValid: cert.isValid
        })),
        metadataURI: result.metadataURI
      };
    } catch (error) {
      logger.error('Failed to get passport by token ID:', error);
      throw error;
    }
  }

  /**
   * Add processing log entry
   */
  async addProcessingLog(tokenId, stage, description, location = '') {
    if (!this.contract) {
      throw new Error('NFT Passport contract not initialized');
    }

    try {
      const tx = await this.contract.addProcessingLog(
        tokenId,
        stage,
        description,
        location
      );
      const receipt = await tx.wait();
      
      logger.info('Processing log added', {
        tokenId: tokenId.toString(),
        stage,
        txHash: receipt.hash
      });
      
      return receipt.hash;
    } catch (error) {
      logger.error('Failed to add processing log:', error);
      throw error;
    }
  }

  /**
   * Add certification
   */
  async addCertification(tokenId, certData) {
    if (!this.contract) {
      throw new Error('NFT Passport contract not initialized');
    }

    try {
      const tx = await this.contract.addCertification(
        tokenId,
        certData.certType,
        certData.certId,
        certData.issuedBy,
        certData.issuedDate,
        certData.expiryDate,
        certData.documentHash
      );
      const receipt = await tx.wait();
      
      logger.info('Certification added', {
        tokenId: tokenId.toString(),
        certType: certData.certType,
        txHash: receipt.hash
      });
      
      return receipt.hash;
    } catch (error) {
      logger.error('Failed to add certification:', error);
      throw error;
    }
  }

  /**
   * Get NFT owner
   */
  async getOwner(tokenId) {
    if (!this.contract) {
      throw new Error('NFT Passport contract not initialized');
    }

    try {
      return await this.contract.ownerOf(tokenId);
    } catch (error) {
      logger.error('Failed to get NFT owner:', error);
      throw error;
    }
  }

  /**
   * Check if passport exists for lot
   */
  async passportExists(lotId) {
    if (!this.contract) {
      return false;
    }

    try {
      const tokenId = await this.contract.lotIdToTokenId(lotId);
      return tokenId > 0;
    } catch (error) {
      return false;
    }
  }

  /**
   * Mint a new NFT passport
   */
  async mintPassport(passportData) {
    if (!this.contract) {
      throw new Error('NFT Passport contract not initialized');
    }

    try {
      const {
        farmer,
        lotId,
        variety,
        quantity,
        harvestDate,
        origin,
        certificateHash,
        metadataURI
      } = passportData;

      logger.info('Minting NFT passport on blockchain:', { lotId, farmer, variety });

      // Convert certificateHash to bytes32 if it's a string
      let certHashBytes32;
      if (certificateHash && certificateHash.startsWith('0x')) {
        // Already in hex format
        certHashBytes32 = certificateHash;
      } else if (certificateHash) {
        // Convert IPFS hash to bytes32 (take first 32 bytes of hash)
        const hash = ethers.keccak256(ethers.toUtf8Bytes(certificateHash));
        certHashBytes32 = hash;
      } else {
        // Empty hash
        certHashBytes32 = ethers.zeroPadValue('0x00', 32);
      }

      // Call the smart contract mintPassport function
      const tx = await this.contract.mintPassport(
        farmer,
        lotId,
        variety,
        quantity.toString(),
        harvestDate.toString(),
        origin || 'Sri Lanka',
        certHashBytes32,
        metadataURI || ''
      );

      logger.info('NFT mint transaction sent:', { txHash: tx.hash });

      // Wait for transaction confirmation
      const receipt = await tx.wait();
      
      logger.info('NFT mint transaction confirmed:', { 
        txHash: receipt.hash,
        blockNumber: receipt.blockNumber,
        gasUsed: receipt.gasUsed.toString()
      });

      // Extract tokenId from events
      let tokenId = null;
      if (receipt.logs && receipt.logs.length > 0) {
        try {
          // Parse the PassportMinted event
          const iface = new ethers.Interface(PASSPORT_CONTRACT_ABI);
          for (const log of receipt.logs) {
            try {
              const parsed = iface.parseLog(log);
              if (parsed && parsed.name === 'PassportMinted') {
                tokenId = Number(parsed.args.tokenId);
                logger.info('Extracted tokenId from event:', tokenId);
                break;
              }
            } catch (e) {
              // Skip logs that don't match our interface
              continue;
            }
          }
        } catch (error) {
          logger.warn('Failed to parse mint event logs:', error.message);
        }
      }

      // If we couldn't get tokenId from events, query the contract
      if (tokenId === null) {
        try {
          tokenId = Number(await this.contract.lotIdToTokenId(lotId));
          logger.info('Retrieved tokenId from contract:', tokenId);
        } catch (error) {
          logger.warn('Failed to retrieve tokenId from contract:', error.message);
          // Use a fallback tokenId
          tokenId = 0;
        }
      }

      return {
        txHash: receipt.hash,
        tokenId: tokenId,
        blockNumber: receipt.blockNumber
      };

    } catch (error) {
      logger.error('Failed to mint NFT passport:', error);
      throw error;
    }
  }
}

module.exports = NFTPassportService;
