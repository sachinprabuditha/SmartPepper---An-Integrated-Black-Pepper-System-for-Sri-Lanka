const { ethers } = require('ethers');
const logger = require('../utils/logger');

const CONTRACT_ABI = [
  "event LotCreated(string indexed lotId, address indexed farmer, string variety, uint256 quantity, bytes32 certificateHash)",
  "event AuctionCreated(uint256 indexed auctionId, string indexed lotId, address indexed farmer, uint256 startPrice, uint256 reservePrice, uint256 endTime)",
  "event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount, uint256 timestamp)",
  "event AuctionEnded(uint256 indexed auctionId, address indexed winner, uint256 finalPrice)",
  "event AuctionSettled(uint256 indexed auctionId, address indexed farmer, address indexed buyer, uint256 amount, uint256 platformFee)",
  "event ComplianceChecked(string indexed lotId, bool passed, uint256 timestamp)",
  "function createLot(string memory lotId, string memory variety, uint256 quantity, string memory quality, string memory harvestDate, bytes32 certificateHash) external",
  "function createAuction(string memory lotId, uint256 startPrice, uint256 reservePrice, uint256 duration) external returns (uint256)",
  "function setComplianceStatus(uint256 auctionId, bool passed) external",
  "function placeBid(uint256 auctionId) external payable",
  "function endAuction(uint256 auctionId) external",
  "function settleAuction(uint256 auctionId) external",
  "function withdrawEscrow() external",
  "function getAuctionBids(uint256 auctionId) external view returns (tuple(address bidder, uint256 amount, uint256 timestamp)[])",
  "function getLot(string memory lotId) external view returns (tuple(string lotId, address farmer, string variety, uint256 quantity, string quality, string harvestDate, bytes32 certificateHash, uint8 status, uint256 createdAt))",
  "function auctions(uint256) external view returns (uint256 auctionId, string lotId, address farmer, uint256 startPrice, uint256 reservePrice, uint256 currentBid, address currentBidder, uint256 startTime, uint256 endTime, uint8 status, bool compliancePassed, uint256 bidCount, uint256 escrowAmount)",
  "function getTotalAuctions() external view returns (uint256)"
];

const PASSPORT_ABI = [
  "event PassportMinted(uint256 indexed tokenId, string indexed lotId, address indexed farmer, string metadataURI)",
  "event ComplianceStatusUpdated(string indexed lotId, uint256 indexed tokenId, bool approved, address indexed checkedBy, uint256 timestamp)",
  "function mintPassport(address farmer, string memory lotId, string memory variety, uint256 quantity, string memory harvestDate, string memory origin, bytes32 certificateHash, string memory metadataURI) external returns (uint256)",
  "function updateComplianceStatus(string memory lotId, bool approved) external",
  "function isComplianceApproved(string memory lotId) external view returns (bool)",
  "function getComplianceStatus(string memory lotId) external view returns (bool approved, address checkedBy, uint256 checkedAt)",
  "function addProcessingLog(uint256 tokenId, string memory stage, string memory description, string memory location) external"
];

class BlockchainService {
  constructor() {
    this.provider = null;
    this.contract = null;
    this.passportContract = null;
    this.signer = null;
    this.pendingNonce = null; // Track pending nonce
    this.nonceLock = Promise.resolve(); // Mutex for nonce management
  }

  async initialize() {
    try {
      const rpcUrl = process.env.BLOCKCHAIN_RPC_URL || 'http://127.0.0.1:8545';
      
      const contractAddress = process.env.CONTRACT_ADDRESS;
      const passportAddress = process.env.PASSPORT_CONTRACT_ADDRESS;
      
      if (!contractAddress) {
        logger.warn('CONTRACT_ADDRESS not set - blockchain features will be disabled');
        return; // Exit gracefully without throwing
      }

      this.provider = new ethers.JsonRpcProvider(rpcUrl);
      this.contract = new ethers.Contract(contractAddress, CONTRACT_ABI, this.provider);
      
      // Initialize PepperPassport contract if address is available
      if (passportAddress) {
        this.passportContract = new ethers.Contract(passportAddress, PASSPORT_ABI, this.provider);
        logger.info('PepperPassport contract initialized', { passportAddress });
      } else {
        logger.warn('PASSPORT_CONTRACT_ADDRESS not set - passport features will be limited');
      }

      if (process.env.PRIVATE_KEY) {
        this.signer = new ethers.Wallet(process.env.PRIVATE_KEY, this.provider);
        this.contract = this.contract.connect(this.signer);
        if (this.passportContract) {
          this.passportContract = this.passportContract.connect(this.signer);
        }
      }

      logger.info('Blockchain service initialized', {
        network: await this.provider.getNetwork(),
        contractAddress,
        passportAddress
      });

      // Listen to contract events
      this.setupEventListeners();

    } catch (error) {
      logger.error('Failed to initialize blockchain service:', error);
      throw error;
    }
  }

  setupEventListeners() {
    this.contract.on('BidPlaced', (auctionId, bidder, amount, timestamp, event) => {
      logger.info('BidPlaced event', {
        auctionId: auctionId.toString(),
        bidder,
        amount: ethers.formatEther(amount),
        timestamp: timestamp.toString(),
        txHash: event.log.transactionHash
      });
    });

    this.contract.on('AuctionEnded', (auctionId, winner, finalPrice, event) => {
      logger.info('AuctionEnded event', {
        auctionId: auctionId.toString(),
        winner,
        finalPrice: ethers.formatEther(finalPrice),
        txHash: event.log.transactionHash
      });
    });

    this.contract.on('ComplianceChecked', (lotId, passed, timestamp, event) => {
      logger.info('ComplianceChecked event', {
        lotId,
        passed,
        timestamp: timestamp.toString(),
        txHash: event.log.transactionHash
      });
    });
  }

  /**
   * Get the next nonce for transactions with proper synchronization
   * Prevents nonce conflicts when sending multiple transactions rapidly
   */
  async getNextNonce() {
    // Wait for any pending nonce operations to complete
    await this.nonceLock;
    
    // Create a new lock for this operation
    let releaseLock;
    this.nonceLock = new Promise(resolve => {
      releaseLock = resolve;
    });

    try {
      if (!this.signer) {
        throw new Error('Signer not initialized');
      }

      // Get current nonce from blockchain
      const currentNonce = await this.provider.getTransactionCount(
        this.signer.address,
        'pending' // Include pending transactions
      );

      // If we have a pending nonce that's higher, use it
      if (this.pendingNonce !== null && this.pendingNonce >= currentNonce) {
        this.pendingNonce++;
      } else {
        this.pendingNonce = currentNonce;
      }

      logger.debug('Nonce allocated', { 
        nonce: this.pendingNonce,
        address: this.signer.address 
      });

      return this.pendingNonce;
    } finally {
      // Release the lock
      releaseLock();
    }
  }

  /**
   * Reset nonce tracking (useful after errors)
   */
  resetNonce() {
    this.pendingNonce = null;
    logger.debug('Nonce tracking reset');
  }

  async createLot(lotData) {
    try {
      const { lotId, variety, quantity, quality, harvestDate, certificateHash } = lotData;
      
      // Get next nonce with proper synchronization
      const nonce = await this.getNextNonce();
      
      const tx = await this.contract.createLot(
        lotId,
        variety,
        ethers.parseUnits(quantity.toString(), 0),
        quality,
        harvestDate,
        certificateHash,
        { nonce } // Explicitly set nonce
      );

      const receipt = await tx.wait();
      logger.info('Lot created on blockchain', { lotId, txHash: receipt.hash, nonce });
      
      return receipt.hash;
    } catch (error) {
      logger.error('Failed to create lot on blockchain:', error);
      // Reset nonce on error to resync
      this.resetNonce();
      throw error;
    }
  }

  async createAuction(auctionData) {
    try {
      const { lotId, startPrice, reservePrice, duration } = auctionData;
      
      // Get next nonce with proper synchronization
      const nonce = await this.getNextNonce();
      
      const tx = await this.contract.createAuction(
        lotId,
        ethers.parseEther(startPrice.toString()),
        ethers.parseEther(reservePrice.toString()),
        duration,
        { nonce } // Explicitly set nonce
      );

      const receipt = await tx.wait();
      
      // Extract auction ID from event
      let auctionId = null;
      
      // Try to parse events from receipt
      if (receipt.logs && receipt.logs.length > 0) {
        for (const log of receipt.logs) {
          try {
            const parsed = this.contract.interface.parseLog({
              topics: log.topics,
              data: log.data
            });
            
            if (parsed && parsed.name === 'AuctionCreated') {
              auctionId = parsed.args.auctionId;
              logger.info('Parsed AuctionCreated event', { auctionId: auctionId.toString() });
              break;
            }
          } catch (e) {
            // Skip logs that don't match our interface
            continue;
          }
        }
      }

      // Fallback: Get total auctions count - 1 (since counter was already incremented)
      if (!auctionId) {
        try {
          const totalAuctions = await this.contract.getTotalAuctions();
          // The newly created auction ID is totalAuctions - 1 (counter increments before storing)
          auctionId = totalAuctions > 0 ? totalAuctions - 1n : 0n;
          logger.warn('Used getTotalAuctions as fallback for auction ID', { 
            totalAuctions: totalAuctions.toString(),
            auctionId: auctionId.toString() 
          });
        } catch (fallbackError) {
          logger.error('Failed to get auction ID from event or fallback', fallbackError);
          // Last resort: use 0 and let the database handle it
          auctionId = 0n;
          logger.error('Using default auction ID 0 - this may cause issues');
        }
      }

      logger.info('Auction created on blockchain', {
        lotId,
        auctionId: auctionId.toString(),
        txHash: receipt.hash,
        nonce
      });
      
      return {
        txHash: receipt.hash,
        auctionId: auctionId.toString()
      };
    } catch (error) {
      logger.error('Failed to create auction on blockchain:', error);
      // Reset nonce on error to resync
      this.resetNonce();
      throw error;
    }
  }

  async setComplianceStatus(auctionId, passed) {
    try {
      // Get next nonce with proper synchronization
      const nonce = await this.getNextNonce();
      
      const tx = await this.contract.setComplianceStatus(auctionId, passed, { nonce });
      const receipt = await tx.wait();
      
      logger.info('Compliance status set', {
        auctionId,
        passed,
        txHash: receipt.hash,
        nonce
      });
      
      return receipt.hash;
    } catch (error) {
      logger.error('Failed to set compliance status:', error);
      // Reset nonce on error to resync
      this.resetNonce();
      throw error;
    }
  }

  async getAuction(auctionId) {
    try {
      const auction = await this.contract.auctions(auctionId);
      
      return {
        auctionId: auction.auctionId.toString(),
        lotId: auction.lotId,
        farmer: auction.farmer,
        startPrice: ethers.formatEther(auction.startPrice),
        reservePrice: ethers.formatEther(auction.reservePrice),
        currentBid: ethers.formatEther(auction.currentBid),
        currentBidder: auction.currentBidder,
        startTime: new Date(Number(auction.startTime) * 1000),
        endTime: new Date(Number(auction.endTime) * 1000),
        status: auction.status,
        compliancePassed: auction.compliancePassed,
        bidCount: auction.bidCount.toString(),
        escrowAmount: ethers.formatEther(auction.escrowAmount)
      };
    } catch (error) {
      logger.error('Failed to get auction:', error);
      throw error;
    }
  }

  async getAuctionBids(auctionId) {
    try {
      const bids = await this.contract.getAuctionBids(auctionId);
      
      return bids.map(bid => ({
        bidder: bid.bidder,
        amount: ethers.formatEther(bid.amount),
        timestamp: new Date(Number(bid.timestamp) * 1000)
      }));
    } catch (error) {
      logger.error('Failed to get auction bids:', error);
      throw error;
    }
  }

  async getLot(lotId) {
    try {
      const lot = await this.contract.getLot(lotId);
      
      return {
        lotId: lot.lotId,
        farmer: lot.farmer,
        variety: lot.variety,
        quantity: lot.quantity.toString(),
        quality: lot.quality,
        harvestDate: lot.harvestDate,
        certificateHash: lot.certificateHash,
        status: lot.status,
        createdAt: new Date(Number(lot.createdAt) * 1000)
      };
    } catch (error) {
      logger.error('Failed to get lot:', error);
      throw error;
    }
  }

  /**
   * Update compliance status on blockchain
   * @param {string} lotId - The lot ID
   * @param {boolean} approved - Whether lot is approved or rejected
   * @returns {string} Transaction hash
   */
  async updateLotComplianceOnChain(lotId, approved) {
    try {
      if (!this.passportContract) {
        throw new Error('PepperPassport contract not initialized');
      }

      if (!this.signer) {
        throw new Error('Signer not available - check PRIVATE_KEY in .env');
      }

      logger.info('Updating compliance status on blockchain', { 
        lotId, 
        approved,
        signer: this.signer.address 
      });

      const nonce = await this.getNextNonce();
      
      const tx = await this.passportContract.updateComplianceStatus(
        lotId,
        approved,
        { nonce }
      );

      logger.info('Compliance update transaction sent', {
        lotId,
        approved,
        txHash: tx.hash,
        nonce
      });

      const receipt = await tx.wait();

      logger.info('Compliance status updated on blockchain', {
        lotId,
        approved,
        txHash: receipt.hash,
        blockNumber: receipt.blockNumber,
        gasUsed: receipt.gasUsed.toString()
      });

      return receipt.hash;
    } catch (error) {
      logger.error('Failed to update compliance status on blockchain:', error);
      this.resetNonce(); // Reset nonce on error
      throw error;
    }
  }

  /**
   * Check if a lot is compliance approved on blockchain
   * @param {string} lotId - The lot ID
   * @returns {boolean} Whether lot is approved
   */
  async isLotComplianceApproved(lotId) {
    try {
      if (!this.passportContract) {
        logger.warn('PepperPassport contract not initialized');
        return false;
      }

      const approved = await this.passportContract.isComplianceApproved(lotId);
      return approved;
    } catch (error) {
      logger.error('Failed to check compliance status:', error);
      return false;
    }
  }

  /**
   * Get compliance status details from blockchain
   * @param {string} lotId - The lot ID
   * @returns {Object} Compliance status details
   */
  async getComplianceStatusFromChain(lotId) {
    try {
      if (!this.passportContract) {
        throw new Error('PepperPassport contract not initialized');
      }

      const [approved, checkedBy, checkedAt] = await this.passportContract.getComplianceStatus(lotId);
      
      return {
        approved,
        checkedBy,
        checkedAt: new Date(Number(checkedAt) * 1000)
      };
    } catch (error) {
      logger.error('Failed to get compliance status from blockchain:', error);
      throw error;
    }
  }

  async getTotalAuctions() {
    try {
      const total = await this.contract.getTotalAuctions();
      return total.toString();
    } catch (error) {
      logger.error('Failed to get total auctions:', error);
      throw error;
    }
  }
}

module.exports = BlockchainService;
