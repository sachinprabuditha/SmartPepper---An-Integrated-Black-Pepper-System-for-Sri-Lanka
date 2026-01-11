# SmartPepper - Blockchain Pepper Auction System

🌶️ A blockchain-based real-time auction platform for pepper trading with supply chain traceability and compliance automation.

## 🎯 Project Overview

SmartPepper is a **modular blockchain system** that enables transparent, efficient, and compliant pepper auctions. This repository contains the **50% midpoint implementation** focusing on:

- ✅ Core auction smart contract with escrow
- ✅ Real-time bidding engine with WebSocket
- ✅ Basic compliance rule engine (IPFS certificate validation)
- ✅ PostgreSQL + Redis backend
- ✅ Flutter mobile app (in progress)
- ✅ Web dashboard (in progress)

Future modules (post-midpoint) will add: traceability, QR/NFC, advanced compliance, and multi-chain support.

## 📁 Project Structure

```
SmartPepper/
├── blockchain/           # Smart contracts (Solidity + Hardhat)
│   ├── contracts/
│   │   └── PepperAuction.sol
│   ├── scripts/
│   │   └── deploy.js
│   ├── test/
│   ├── hardhat.config.js
│   └── package.json
│
├── backend/              # Node.js backend with WebSocket
│   ├── src/
│   │   ├── routes/       # API routes (auction, lot, user, compliance)
│   │   ├── services/     # Blockchain, compliance, IPFS services
│   │   ├── websocket/    # Real-time auction WebSocket
│   │   ├── db/           # PostgreSQL database, migrations
│   │   └── utils/        # Logger, validators
│   ├── .env.example
│   └── package.json
│
├── mobile/               # Flutter mobile app
│   └── (Coming soon)
│
├── web/                  # Web dashboard
│   └── (Coming soon)
│
└── DEPLOYMENT_ROADMAP.md # Complete architecture & future plans
```

## 🚀 Quick Start

### Prerequisites

- Node.js >= 18.x
- PostgreSQL >= 14
- Redis >= 7
- IPFS node (optional for certificate storage)
- MetaMask or Web3 wallet

### 1. Clone and Install

```bash
git clone <repository-url>
cd SmartPepper
```

### 2. Setup Blockchain

```bash
cd blockchain
npm install

# Copy environment file
copy .env.example .env

# Edit .env with your configuration
# - Add Sepolia RPC URL (Infura/Alchemy)
# - Add private key for deployment

# Compile contracts
npm run compile

# Deploy to local network
npm run node         # Terminal 1
npm run deploy:local # Terminal 2

# Deploy to Sepolia testnet
npm run deploy:sepolia
```

### 3. Setup Backend

```bash
cd ../backend
npm install

# Copy environment file
copy .env.example .env

# Configure .env:
# - Database credentials
# - Redis connection
# - Contract address from deployment
# - IPFS settings

# Run migrations
npm run migrate

# Start backend
npm run dev
```

### 4. Verify Setup

```bash
# Check health endpoint
curl http://localhost:3000/health

# Response should be:
# {"status":"healthy","timestamp":"...","uptime":...}
```

## 🔧 Configuration

### Environment Variables

**Blockchain (.env)**

```env
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_PROJECT_ID
PRIVATE_KEY=your_deployer_private_key
```

**Backend (.env)**

```env
PORT=3000
DB_HOST=localhost
DB_NAME=smartpepper
DB_USER=postgres
DB_PASSWORD=your_password

REDIS_HOST=localhost
REDIS_PORT=6379

CONTRACT_ADDRESS=0x... # From deployment
BLOCKCHAIN_RPC_URL=http://127.0.0.1:8545

IPFS_HOST=localhost
IPFS_PORT=5001
```

## 📡 API Endpoints

### Auctions

| Method | Endpoint                   | Description         |
| ------ | -------------------------- | ------------------- |
| GET    | `/api/auctions`            | List all auctions   |
| GET    | `/api/auctions/:id`        | Get auction details |
| POST   | `/api/auctions`            | Create new auction  |
| POST   | `/api/auctions/:id/bid`    | Place a bid         |
| POST   | `/api/auctions/:id/end`    | End auction         |
| POST   | `/api/auctions/:id/settle` | Settle auction      |

### Lots

| Method | Endpoint           | Description          |
| ------ | ------------------ | -------------------- |
| GET    | `/api/lots`        | List all pepper lots |
| GET    | `/api/lots/:lotId` | Get lot details      |
| POST   | `/api/lots`        | Create new lot       |

### Compliance

| Method | Endpoint                 | Description                |
| ------ | ------------------------ | -------------------------- |
| POST   | `/api/compliance/check`  | Run compliance check       |
| GET    | `/api/compliance/:lotId` | Get compliance history     |
| POST   | `/api/compliance/upload` | Upload certificate to IPFS |

## 🔌 WebSocket Events

Connect to: `ws://localhost:3000/auction`

### Client → Server

```javascript
// Join auction room
socket.emit("join_auction", {
  auctionId: 1,
  userAddress: "0x...",
});

// Leave auction room
socket.emit("leave_auction", {
  auctionId: 1,
  userAddress: "0x...",
});
```

### Server → Client

```javascript
// New bid placed
socket.on("new_bid", (data) => {
  // data: { auctionId, bidder, amount, timestamp, bidCount }
});

// Auction ended
socket.on("auction_ended", (data) => {
  // data: { auctionId, winner, finalPrice, timestamp }
});

// Compliance update
socket.on("compliance_update", (data) => {
  // data: { auctionId, passed, timestamp }
});
```

## 🧪 Testing

### Smart Contract Tests

```bash
cd blockchain
npm test

# With coverage
npm run coverage
```

### Backend Tests

```bash
cd backend
npm test
```

## 📊 Database Schema

### Key Tables

- **users** - Farmers, buyers, exporters, regulators
- **pepper_lots** - Pepper lots with harvest details
- **auctions** - Live auctions with bidding state
- **bids** - Bid history
- **compliance_checks** - Compliance validation results

See `backend/src/db/migrate.js` for full schema.

## 🎨 Smart Contract Features

### PepperAuction.sol

**Core Functions:**

- `createLot()` - Register new pepper lot
- `createAuction()` - Start auction for a lot
- `setComplianceStatus()` - Set compliance result (owner only)
- `placeBid()` - Place bid with automatic escrow
- `endAuction()` - End auction after time expires
- `settleAuction()` - Transfer funds and ownership
- `withdrawEscrow()` - Withdraw refunded bids

**Security Features:**

- ReentrancyGuard for bid/settlement functions
- Pausable for emergency stops
- Access control (Ownable)
- Escrow management for safe fund handling

## 🌐 Future Modules (Post-Midpoint)

See `DEPLOYMENT_ROADMAP.md` for detailed plans:

1. **Traceability System** - Farm-to-port supply chain logging
2. **Advanced Compliance** - Multi-rule engine with YAML configs
3. **QR/NFC Integration** - Digital pepper passports
4. **Smart Contract Automation** - Shipment tracking, alerts
5. **Enhanced Platform** - Multilingual, offline-first, analytics

## 🔐 Security Considerations

⚠️ **Important:** This is a development/demo version. Before production:

1. Get smart contract professional audit
2. Implement proper key management (HSM/MPC)
3. Add rate limiting and DDoS protection
4. Enable SSL/TLS for all connections
5. Implement proper authentication (JWT + Web3 signatures)
6. Set up monitoring and alerting
7. Test with limited funds on testnet first

## 📜 License

MIT License - see LICENSE file

## 🤝 Contributing

This is an academic/demo project. Contributions welcome:

1. Fork the repository
2. Create feature branch (`git checkout -b feature/YourFeature`)
3. Commit changes (`git commit -m 'Add YourFeature'`)
4. Push to branch (`git push origin feature/YourFeature`)
5. Open Pull Request

## 📞 Support

For questions or issues:

- Open an issue on GitHub
- Check `DEPLOYMENT_ROADMAP.md` for architecture details

---

**Built with:** Solidity • Hardhat • Node.js • Express • WebSocket • PostgreSQL • Redis • IPFS • Ethers.js

🌶️ **SmartPepper** - Bringing transparency to pepper supply chains through blockchain technology.
