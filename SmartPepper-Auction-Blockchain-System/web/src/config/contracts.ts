export const PEPPER_AUCTION_ABI = [
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
  "function getTotalAuctions() external view returns (uint256)",
  "function platformFeePercent() external view returns (uint256)",
  "function minBidIncrement() external view returns (uint256)",
  "function escrowBalances(address) external view returns (uint256)"
] as const;

export const CONTRACT_ADDRESS = process.env.NEXT_PUBLIC_CONTRACT_ADDRESS || '';
export const CONTRACT_ABI = PEPPER_AUCTION_ABI;

export const CHAIN_CONFIG = {
  sepolia: {
    id: 11155111,
    name: 'Sepolia',
    network: 'sepolia',
    nativeCurrency: {
      decimals: 18,
      name: 'Sepolia ETH',
      symbol: 'SEP',
    },
    rpcUrls: {
      default: {
        http: ['https://sepolia.infura.io/v3/'],
      },
      public: {
        http: ['https://rpc.sepolia.org'],
      },
    },
    blockExplorers: {
      default: { name: 'Etherscan', url: 'https://sepolia.etherscan.io' },
    },
    testnet: true,
  },
  localhost: {
    id: 1337,
    name: 'Localhost',
    network: 'localhost',
    nativeCurrency: {
      decimals: 18,
      name: 'Ether',
      symbol: 'ETH',
    },
    rpcUrls: {
      default: {
        http: ['http://127.0.0.1:8545'],
      },
    },
    testnet: true,
  },
};

export enum AuctionStatus {
  Created = 0,
  Active = 1,
  Ended = 2,
  Settled = 3,
  Cancelled = 4,
}

export enum LotStatus {
  Available = 0,
  InAuction = 1,
  Sold = 2,
  Shipped = 3,
  Delivered = 4,
}
