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

class BlockchainService {
  constructor() {
    this.provider = null;
    this.contract = null;
    this.signer = null;
  }

  async initialize() {
    try {
      const rpcUrl = process.env.BLOCKCHAIN_RPC_URL || 'http://127.0.0.1:8545';
      this.provider = new ethers.JsonRpcProvider(rpcUrl);

      const contractAddress = process.env.CONTRACT_ADDRESS;
      if (!contractAddress) {
        throw new Error('CONTRACT_ADDRESS not set in environment');
      }

      this.contract = new ethers.Contract(contractAddress, CONTRACT_ABI, this.provider);

      if (process.env.PRIVATE_KEY) {
        this.signer = new ethers.Wallet(process.env.PRIVATE_KEY, this.provider);
        this.contract = this.contract.connect(this.signer);
      }

      logger.info('Blockchain service initialized', {
        network: await this.provider.getNetwork(),
        contractAddress
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

  async createLot(lotData) {
    try {
      const { lotId, variety, quantity, quality, harvestDate, certificateHash } = lotData;
      
      const tx = await this.contract.createLot(
        lotId,
        variety,
        ethers.parseUnits(quantity.toString(), 0),
        quality,
        harvestDate,
        certificateHash
      );

      const receipt = await tx.wait();
      logger.info('Lot created on blockchain', { lotId, txHash: receipt.hash });
      
      return receipt.hash;
    } catch (error) {
      logger.error('Failed to create lot on blockchain:', error);
      throw error;
    }
  }

  async createAuction(auctionData) {
    try {
      const { lotId, startPrice, reservePrice, duration } = auctionData;
      
      const tx = await this.contract.createAuction(
        lotId,
        ethers.parseEther(startPrice.toString()),
        ethers.parseEther(reservePrice.toString()),
        duration
      );

      const receipt = await tx.wait();
      
      // Extract auction ID from event
      const event = receipt.logs.find(log => {
        try {
          const parsed = this.contract.interface.parseLog(log);
          return parsed.name === 'AuctionCreated';
        } catch (e) {
          return false;
        }
      });

      const auctionId = event ? 
        this.contract.interface.parseLog(event).args.auctionId : 
        null;

      logger.info('Auction created on blockchain', {
        lotId,
        auctionId: auctionId?.toString(),
        txHash: receipt.hash
      });
      
      return {
        txHash: receipt.hash,
        auctionId: auctionId ? auctionId.toString() : null
      };
    } catch (error) {
      logger.error('Failed to create auction on blockchain:', error);
      throw error;
    }
  }

  async setComplianceStatus(auctionId, passed) {
    try {
      const tx = await this.contract.setComplianceStatus(auctionId, passed);
      const receipt = await tx.wait();
      
      logger.info('Compliance status set', {
        auctionId,
        passed,
        txHash: receipt.hash
      });
      
      return receipt.hash;
    } catch (error) {
      logger.error('Failed to set compliance status:', error);
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
