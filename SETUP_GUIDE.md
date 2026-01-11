# 🌶️ SmartPepper Blockchain Auction System

## Complete Setup & Deployment Guide

> **Version**: 1.0.0 (60% Implementation Complete)  
> **Last Updated**: January 7, 2026  
> **Estimated Setup Time**: 45-60 minutes

---

## 📋 Table of Contents

1. [System Overview](#system-overview)
2. [Prerequisites](#prerequisites)
3. [Architecture Components](#architecture-components)
4. [Installation Guide](#installation-guide)
5. [Configuration](#configuration)
6. [Database Setup](#database-setup)
7. [Blockchain Deployment](#blockchain-deployment)
8. [Backend Setup](#backend-setup)
9. [Web Frontend Setup](#web-frontend-setup)
10. [Mobile App Setup](#mobile-app-setup)
11. [Running the Complete System](#running-the-complete-system)
12. [Testing & Verification](#testing-verification)
13. [Troubleshooting](#troubleshooting)
14. [Production Deployment](#production-deployment)

---

## 🎯 System Overview

SmartPepper is a decentralized blockchain-based auction platform for Sri Lankan pepper trading, featuring:

- **Blockchain**: Ethereum smart contracts (Solidity 0.8.20)
- **NFT Traceability**: ERC-721 tokens for pepper lot passports
- **Real-time Bidding**: WebSocket-based live auctions
- **Distributed Storage**: IPFS for documents and images
- **Multi-platform**: Web dashboard + Mobile app (Flutter)

### Current Implementation Status (60%)

| Component        | Status         | Completion |
| ---------------- | -------------- | ---------- |
| Smart Contracts  | ✅ Complete    | 100%       |
| Backend API      | ✅ Complete    | 100%       |
| Database Schema  | ✅ Complete    | 100%       |
| WebSocket System | ✅ Complete    | 100%       |
| Web Dashboard    | 🔄 In Progress | 70%        |
| Mobile App       | 🔄 In Progress | 95%        |
| IPFS Integration | ✅ Complete    | 100%       |
| Payment System   | ⏳ Pending     | 0%         |

---

## 📦 Prerequisites

### Required Software

#### 1. Node.js 18+ (CRITICAL - Install First!)

**Windows:**

```powershell
# Option A: Direct Download (Recommended)
# Visit: https://nodejs.org/
# Download LTS version (20.x)
# Run installer with default options

# Option B: Using Chocolatey
choco install nodejs-lts

# Option C: Using Winget
winget install OpenJS.NodeJS.LTS

# Verify installation
node --version  # Should show v18.x or higher
npm --version   # Should show v9.x or higher
```

**macOS:**

```bash
# Using Homebrew
brew install node@20

# Verify
node --version
npm --version
```

**Linux (Ubuntu/Debian):**

```bash
# Using NodeSource repository
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify
node --version
npm --version
```

---

#### 2. PostgreSQL 14+

**Windows:**

```powershell
# Option A: Direct Download
# Visit: https://www.postgresql.org/download/windows/
# Download installer for Windows x86-64
# Default port: 5432
# Remember the password you set for 'postgres' user!

# Option B: Using Chocolatey
choco install postgresql14

# Start PostgreSQL service
net start postgresql-x64-14

# Verify installation
psql --version
```

**macOS:**

```bash
# Using Homebrew
brew install postgresql@14
brew services start postgresql@14

# Verify
psql --version
```

**Linux:**

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install postgresql postgresql-contrib

# Start service
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Verify
psql --version
```

---

#### 3. Git

**Windows:**

```powershell
# Download from: https://git-scm.com/download/win
# Or use Chocolatey
choco install git

# Verify
git --version
```

**macOS:**

```bash
# Homebrew
brew install git

# Or use Xcode Command Line Tools
xcode-select --install
```

**Linux:**

```bash
sudo apt install git
```

---

### 🐳 Docker Setup (Recommended - Easiest Method!)

**Why Docker?**

- No manual PostgreSQL/Redis installation needed
- Consistent environment across all platforms
- Easy to start/stop/reset
- Includes management UIs (pgAdmin, Redis Commander)

#### Install Docker Desktop

**Windows:**

```powershell
# Download from: https://www.docker.com/products/docker-desktop/
# Or use Chocolatey
choco install docker-desktop

# Verify
docker --version
docker-compose --version
```

**macOS:**

```bash
# Download Docker Desktop for Mac
# Or use Homebrew
brew install --cask docker

# Verify
docker --version
docker-compose --version
```

**Linux:**

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo apt install docker-compose-plugin

# Verify
docker --version
docker compose version
```

#### Start Services with Docker

```powershell
# Navigate to project root
cd D:\Campus\Research\SmartPepper\SmartPepper-Auction-Blockchain-System

# Start PostgreSQL + Redis + IPFS
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

**🔑 Default Credentials:**

**PostgreSQL:**

- Host: `localhost`
- Port: `5432`
- Database: `smartpepper`
- Username: `smartpepper`
- Password: `smartpepper2024`

**Redis:**

- Host: `localhost`
- Port: `6379`
- Password: `smartpepper2024`

**IPFS:**

- API: `http://localhost:5001`
- Gateway: `http://localhost:8080`

**pgAdmin (Database UI):**

- URL: `http://localhost:5050`
- Email: `admin@smartpepper.com`
- Password: `smartpepper2024`

**See [DOCKER_SETUP.md](DOCKER_SETUP.md) for complete Docker documentation.**

---

### Manual Installation (Alternative to Docker)

#### 4. PostgreSQL 14+ (Skip if using Docker)

**Windows:**

```powershell
# Direct Download
# Visit: https://www.postgresql.org/download/windows/
# Set password during installation (remember it!)

# Or use Chocolatey
choco install postgresql14

# Start service
net start postgresql-x64-14

# Verify
psql --version
```

**macOS:**

```bash
brew install postgresql@14
brew services start postgresql@14
```

**Linux:**

```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
```

---

#### 5. Redis (Skip if using Docker)

**Windows:**

```powershell
# Using Chocolatey
choco install redis-64

# Or use WSL2 with Docker
wsl
docker run -d -p 6379:6379 redis:7-alpine

# Verify
redis-cli ping  # Should return "PONG"
```

**macOS:**

```bash
brew install redis
brew services start redis
```

**Linux:**

```bash
sudo apt install redis-server
sudo systemctl start redis
```

---

#### 5. IPFS (for distributed file storage)

**All Platforms:**

```powershell
# Option A: IPFS Desktop (Recommended for development)
# Download from: https://docs.ipfs.tech/install/ipfs-desktop/

# Option B: Command Line
# Windows (Chocolatey)
choco install go-ipfs

# macOS (Homebrew)
brew install ipfs

# Linux
wget https://dist.ipfs.tech/kubo/v0.24.0/kubo_v0.24.0_linux-amd64.tar.gz
tar -xvzf kubo_v0.24.0_linux-amd64.tar.gz
cd kubo
sudo bash install.sh

# Initialize and start
ipfs init
ipfs daemon
```

---

#### 6. MetaMask Browser Extension

- **Install**: [https://metamask.io/](https://metamask.io/)
- Required for interacting with blockchain through web interface
- Create a new wallet or import existing one
- **IMPORTANT**: Save your seed phrase securely!

---

#### 7. Flutter (for mobile app development)

**Windows:**

```powershell
# Download Flutter SDK
# Visit: https://docs.flutter.dev/get-started/install/windows

# Extract to C:\src\flutter
# Add to PATH: C:\src\flutter\bin

# Install Android Studio
# Visit: https://developer.android.com/studio

# Verify
flutter doctor
```

**macOS:**

```bash
# Download Flutter SDK
cd ~/development
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Add to .zshrc or .bashrc
echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zshrc

# Install Xcode from App Store

# Verify
flutter doctor
```

---

## 🏗️ Architecture Components

```
┌─────────────────────────────────────────────────────────┐
│                    SMARTPEPPER SYSTEM                    │
└─────────────────────────────────────────────────────────┘

┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   Farmer     │  │   Exporter   │  │    Admin     │
│   Mobile     │  │   Web App    │  │  Dashboard   │
│  (Flutter)   │  │  (Next.js)   │  │  (Next.js)   │
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                 │                  │
       └─────────────────┼──────────────────┘
                         │
         ┌───────────────▼────────────────┐
         │   Backend API (Node.js)        │
         │  ┌──────────────────────────┐  │
         │  │   Express REST API       │  │
         │  │   - Authentication       │  │
         │  │   - Lot Management       │  │
         │  │   - Auction Control      │  │
         │  └──────────────────────────┘  │
         │  ┌──────────────────────────┐  │
         │  │   WebSocket (Socket.IO)  │  │
         │  │   - Real-time Updates    │  │
         │  │   - Bid Broadcasting     │  │
         │  └──────────────────────────┘  │
         └────────┬──────────┬────────────┘
                  │          │
     ┌────────────▼──┐  ┌────▼─────────┐
     │  PostgreSQL   │  │  IPFS Node   │
     │   Database    │  │  (Files)     │
     └───────────────┘  └──────────────┘
                  │
     ┌────────────▼──────────────────────┐
     │   Ethereum Blockchain             │
     │  ┌────────────────────────────┐   │
     │  │  Smart Contracts           │   │
     │  │  ├─ PepperAuction.sol      │   │
     │  │  └─ PepperPassport.sol     │   │
     │  └────────────────────────────┘   │
     │  Local: Hardhat (Chain ID 1337)   │
     │  Testnet: Sepolia (Chain ID 11155111) │
     └────────────────────────────────────┘
```

---

## 📥 Installation Guide

### Step 1: Clone the Repository

```powershell
# Choose your project directory
cd D:\Campus\Research\

# Clone repository
git clone https://github.com/yourusername/SmartPepper-Auction-Blockchain-System.git

# Navigate to project
cd SmartPepper-Auction-Blockchain-System

# Verify structure
dir  # Windows
ls   # macOS/Linux
```

**Expected Directory Structure:**

```
SmartPepper-Auction-Blockchain-System/
├── blockchain/          # Smart contracts & Hardhat
├── backend/            # Node.js API server
├── web/                # Next.js web dashboard
├── mobile/             # Flutter mobile app
├── docs/               # Documentation
└── README.md
```

---

### Step 2: Install Dependencies

#### Blockchain Dependencies

```powershell
cd blockchain
npm install

# Expected packages:
# - hardhat: ^2.19.0
# - @openzeppelin/contracts: ^5.0.0
# - ethers: ^6.9.0
```

#### Backend Dependencies

```powershell
cd ..\backend
npm install

# Expected packages:
# - express: ^4.18.2
# - pg: ^8.11.0 (PostgreSQL client)
# - socket.io: ^4.6.0
# - ethers: ^6.9.0
# - ipfs-http-client: ^60.0.0
```

#### Web Frontend Dependencies

```powershell
cd ..\web
npm install

# Expected packages:
# - next: ^14.0.0
# - react: ^18.2.0
# - ethers: ^6.9.0
# - socket.io-client: ^4.6.0
```

#### Mobile App Dependencies

```powershell
cd ..\mobile
flutter pub get

# Expected packages:
# - flutter_sdk
# - web3dart: ^2.7.0
# - socket_io_client: ^2.0.0
# - dio: ^5.3.0
```

---

## ⚙️ Configuration

### Step 3: Environment Variables

#### 3.1 Blockchain Configuration

```powershell
cd blockchain
copy .env.example .env  # Windows
# cp .env.example .env  # macOS/Linux

# Edit .env
notepad .env  # Windows
# nano .env   # macOS/Linux
```

**blockchain/.env:**

```env
# Local Hardhat Network
HARDHAT_NETWORK=localhost
HARDHAT_CHAIN_ID=1337

# Sepolia Testnet (for production testing)
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_KEY
SEPOLIA_PRIVATE_KEY=0xYOUR_PRIVATE_KEY_HERE
SEPOLIA_CHAIN_ID=11155111

# Etherscan API (for contract verification)
ETHERSCAN_API_KEY=YOUR_ETHERSCAN_API_KEY

# Deployer Account (Hardhat default account #0)
DEPLOYER_PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

**🔒 Security Warning**: Never commit real private keys to Git! Use `.env.example` for templates.

---

#### 3.2 Backend Configuration

```powershell
cd ..\backend
copy .env.example .env
notepad .env
```

**backend/.env:**

```env
# Server Configuration
NODE_ENV=development
PORT=3002
HOST=0.0.0.0

# ============================================
# Database Configuration
# ============================================

# OPTION 1: Using Docker (Recommended)
DB_HOST=localhost
DB_PORT=5432
DB_NAME=smartpepper
DB_USER=smartpepper
DB_PASSWORD=smartpepper2024

# OPTION 2: Manual PostgreSQL Installation
# Uncomment and update with your credentials:
# DB_HOST=localhost
# DB_PORT=5432
# DB_NAME=smartpepper
# DB_USER=postgres
# DB_PASSWORD=your_postgres_password

# ============================================
# Redis Configuration
# ============================================

# OPTION 1: Using Docker (Recommended)
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=smartpepper2024

# OPTION 2: Manual Redis Installation
# Uncomment if you installed Redis manually (usually no password):
# REDIS_HOST=localhost
# REDIS_PORT=6379
# REDIS_PASSWORD=

# ============================================
# Blockchain Configuration
# ============================================

BLOCKCHAIN_RPC_URL=http://127.0.0.1:8545
CHAIN_ID=1337

# Smart Contract Addresses (Update after deployment!)
CONTRACT_ADDRESS=0x70e0bA845a1A0F2DA3359C97E0285013525FFC49
PASSPORT_CONTRACT_ADDRESS=0x998abeb3E57409262aE5b751f60747921B33613E

# ============================================
# IPFS Configuration
# ============================================

# OPTION 1: Using Docker
IPFS_API_URL=http://127.0.0.1:5001
IPFS_GATEWAY_URL=http://127.0.0.1:8080

# OPTION 2: Public Gateway (No local IPFS needed)
# IPFS_API_URL=http://127.0.0.1:5001
# IPFS_GATEWAY_URL=https://ipfs.io/ipfs

# ============================================
# Security & Authentication
# ============================================

# JWT Secret (CHANGE THIS IN PRODUCTION!)
JWT_SECRET=your_super_secret_jwt_key_change_this_in_production

# CORS Origins (comma-separated)
CORS_ORIGIN=http://localhost:3000,http://localhost:3001

# ============================================
# WebSocket Configuration
# ============================================

WS_PORT=3002

# ============================================
# Logging
# ============================================

LOG_LEVEL=info
LOG_FILE=logs/app.log
```

**💡 Quick Setup Tips:**

- **Using Docker?** Use the Docker credentials (smartpepper/smartpepper2024)
- **Manual Install?** Use your own PostgreSQL password and leave Redis password empty
- **Contract Addresses:** Will be updated after blockchain deployment (Step 5)

---

#### 3.3 Web Frontend Configuration

```powershell
cd ..\web
copy .env.example .env.local
notepad .env.local
```

**web/.env.local:**

```env
# API Configuration
NEXT_PUBLIC_API_URL=http://localhost:3002
NEXT_PUBLIC_WS_URL=http://localhost:3002

# Blockchain Configuration
NEXT_PUBLIC_BLOCKCHAIN_RPC_URL=http://127.0.0.1:8545
NEXT_PUBLIC_CHAIN_ID=1337

# Smart Contract Addresses (Update after deployment!)
NEXT_PUBLIC_CONTRACT_ADDRESS=0x70e0bA845a1A0F2DA3359C97E0285013525FFC49
NEXT_PUBLIC_PASSPORT_CONTRACT_ADDRESS=0x998abeb3E57409262aE5b751f60747921B33613E

# IPFS Configuration
NEXT_PUBLIC_IPFS_GATEWAY=https://ipfs.io/ipfs

# App Configuration
NEXT_PUBLIC_APP_NAME=SmartPepper
NEXT_PUBLIC_APP_VERSION=1.0.0
```

---

#### 3.4 Mobile App Configuration

**mobile/lib/config/env.dart:**

```dart
class Environment {
  // API Configuration
  // IMPORTANT: Update based on your device:
  // - Android Emulator: 'http://10.0.2.2:3002/api'
  // - iOS Simulator: 'http://localhost:3002/api'
  // - Physical Device: Use your computer's IP

  static const String apiBaseUrl = 'http://192.168.1.190:3002/api';

  // Blockchain Configuration
  static const String blockchainRpcUrl = 'http://192.168.1.190:8545';
  static const int chainId = 1337;

  // Smart Contract Addresses (Update after deployment!)
  static const String passportContractAddress =
      '0x998abeb3E57409262aE5b751f60747921B33613E';
  static const String auctionContractAddress =
      '0x70e0bA845a1A0F2DA3359C97E0285013525FFC49';

  // WebSocket Configuration
  static const String wsUrl = 'ws://192.168.1.190:3002/auction';

  // IPFS Configuration
  static const String ipfsGatewayUrl = 'https://ipfs.io/ipfs';
}
```

**📱 Note**: For physical devices, find your computer's IP address:

```powershell
# Windows
ipconfig

# macOS/Linux
ifconfig  # or: ip addr show
```

Look for IPv4 address (e.g., 192.168.1.190)

---

## 🗄️ Database Setup

### Step 4: PostgreSQL Database Creation

#### 4.1 Create Database

**Windows:**

```powershell
# Open PostgreSQL command line
psql -U postgres

# Or use pgAdmin GUI
```

**macOS/Linux:**

```bash
# Switch to postgres user
sudo -u postgres psql
```

**SQL Commands:**

```sql
-- Create database
CREATE DATABASE smartpepper;

-- Create user (optional, for security)
CREATE USER smartpepper_user WITH PASSWORD 'secure_password_here';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE smartpepper TO smartpepper_user;

-- Connect to database
\c smartpepper

-- Verify connection
\dt  -- Should show empty (no tables yet)

-- Exit
\q
```

---

#### 4.2 Run Database Migrations

```powershell
cd backend

# Create tables schema
node -e "const { Pool } = require('pg'); const pool = new Pool({ user: 'postgres', host: 'localhost', database: 'smartpepper', password: 'your_password', port: 5432 }); pool.query(require('fs').readFileSync('create-tables.sql', 'utf8')).then(() => { console.log('✅ Tables created!'); pool.end(); }).catch(err => { console.error('❌ Error:', err); pool.end(); });"

# Or manually:
psql -U postgres -d smartpepper -f create-tables.sql
```

**Verify Tables Created:**

```sql
-- Connect to database
psql -U postgres -d smartpepper

-- List tables
\dt

-- Expected tables:
-- - users
-- - pepper_lots
-- - auctions
-- - bids
-- - transactions

-- View schema
\d pepper_lots
\d auctions
\d bids

\q
```

---

#### 4.3 Add Missing Columns (From Recent Updates)

```powershell
# Add blockchain_tx_hash columns
node add-blockchain-tx-hash-column.js
```

**Expected Output:**

```
Adding blockchain_tx_hash column to pepper_lots table...
✅ Column added to pepper_lots!
Adding blockchain_tx_hash column to bids table...
✅ Column added to bids!
✅ Verified: pepper_lots.blockchain_tx_hash exists
✅ Verified: bids.blockchain_tx_hash exists
```

---

## ⛓️ Blockchain Deployment

### Step 5: Deploy Smart Contracts

#### 5.1 Start Local Hardhat Node

**Terminal 1 (Keep Running):**

```powershell
cd blockchain
npm run node
```

**Expected Output:**

```
Started HTTP and WebSocket JSON-RPC server at http://127.0.0.1:8545/

Accounts
========
Account #0: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 (10000 ETH)
Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

Account #1: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 (10000 ETH)
Private Key: 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d

... (18 more accounts)

WARNING: These accounts, and their private keys, are publicly known.
Any funds sent to them on Mainnet or any other live network WILL BE LOST.
```

**⚠️ IMPORTANT**: Keep this terminal running! Do not close it.

---

#### 5.2 Deploy Contracts

**Terminal 2 (New Terminal):**

```powershell
cd blockchain
npm run deploy:local
```

**Expected Output:**

```
📦 Deploying SmartPepper Contracts to localhost...
==========================================

Deployer Address: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

1️⃣ Deploying PepperPassport (NFT Contract)...
   ⏳ Waiting for confirmation...
   ✅ PepperPassport deployed to: 0x998abeb3E57409262aE5b751f60747921B33613E
   📝 Transaction Hash: 0x7d7f0a545dca98289c68e67c4cd42889e831c8e809e9ab44dc7c36df1c7c0e51

2️⃣ Deploying PepperAuction...
   ⏳ Waiting for confirmation...
   ✅ PepperAuction deployed to: 0x70e0bA845a1A0F2DA3359C97E0285013525FFC49
   📝 Transaction Hash: 0xa2d44e4ddb30bd4e2dc7c1f42ae6db95dd52f2c0c70c83e70a22b1be35a37c7c

3️⃣ Linking contracts...
   Setting PepperPassport address in PepperAuction...
   ✅ Contracts linked successfully!

4️⃣ Transferring PepperPassport ownership to PepperAuction...
   ✅ PepperPassport ownership transferred to PepperAuction
   New Owner: 0x70e0bA845a1A0F2DA3359C97E0285013525FFC49

==========================================
🎉 Deployment Complete!

📋 Contract Addresses:
   PepperAuction:  0x70e0bA845a1A0F2DA3359C97E0285013525FFC49
   PepperPassport: 0x998abeb3E57409262aE5b751f60747921B33613E

📝 Next Steps:
   1. Update backend/.env with CONTRACT_ADDRESS
   2. Update web/.env.local with NEXT_PUBLIC_CONTRACT_ADDRESS
   3. Update mobile/lib/config/env.dart with contract addresses
   4. Start backend server: cd backend && npm run dev
```

---

#### 5.3 Update Configuration Files

**🚨 CRITICAL**: Copy the contract addresses from deployment output and update:

**1. Backend (.env):**

```env
CONTRACT_ADDRESS=0x70e0bA845a1A0F2DA3359C97E0285013525FFC49
PASSPORT_CONTRACT_ADDRESS=0x998abeb3E57409262aE5b751f60747921B33613E
```

**2. Web (.env.local):**

```env
NEXT_PUBLIC_CONTRACT_ADDRESS=0x70e0bA845a1A0F2DA3359C97E0285013525FFC49
NEXT_PUBLIC_PASSPORT_CONTRACT_ADDRESS=0x998abeb3E57409262aE5b751f60747921B33613E
```

**3. Mobile (env.dart):**

```dart
static const String auctionContractAddress =
    '0x70e0bA845a1A0F2DA3359C97E0285013525FFC49';
static const String passportContractAddress =
    '0x998abeb3E57409262aE5b751f60747921B33613E';
```

---

### Step 6: Verify Deployment

```powershell
# Test contract interaction
cd blockchain
npx hardhat console --network localhost
```

**In Hardhat Console:**

```javascript
const PepperAuction = await ethers.getContractFactory("PepperAuction");
const auction = PepperAuction.attach("0x70e0bA845a1A0F2DA3359C97E0285013525FFC49");

// Check passport contract address
const passportAddress = await auction.passportContract();
console.log("Passport Contract:", passportAddress);
// Should print: 0x998abeb3E57409262aE5b751f60747921B33613E

// Check ownership
const owner = await auction.owner();
console.log("Auction Owner:", owner);
// Should print: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

.exit
```

---

## 🖥️ Backend Setup

## 📝 Prerequisites

### Required Software

#### 1. Node.js 18+ (REQUIRED - Install First!)

**Option A: Direct Download (Recommended)**

1. Visit [https://nodejs.org/](https://nodejs.org/)
2. Download LTS version (20.x or higher)
3. Run installer (select "Automatically install necessary tools")
4. Restart PowerShell/Command Prompt
5. Verify installation:
   ```powershell
   node --version
   npm --version
   ```

**Option B: Using Chocolatey (if installed)**

```powershell
choco install nodejs-lts
```

**Option C: Using Winget**

```powershell
winget install OpenJS.NodeJS.LTS
```

#### 2. PostgreSQL 14+

- [Download](https://www.postgresql.org/download/)
- Or use: `choco install postgresql`

#### 3. Redis 7+

- [Download](https://redis.io/download) (or use Docker/WSL)
- Or use: `choco install redis-64`

### Step 7: Start Backend Server

**Terminal 3 (Keep Running):**

```powershell
cd backend
npm run dev
```

**Expected Output:**

```
🌶️  SmartPepper Backend Server Starting...
==========================================

✅ Environment Variables Loaded
✅ PostgreSQL Connected (smartpepper database)
✅ Redis Connected (localhost:6379)
✅ IPFS Connected (http://127.0.0.1:5001)

🔗 Blockchain Configuration:
   Network: Hardhat Local
   RPC URL: http://127.0.0.1:8545
   Chain ID: 1337

📝 Smart Contracts:
   PepperAuction: 0x70e0bA845a1A0F2DA3359C97E0285013525FFC49
   PepperPassport: 0x998abeb3E57409262aE5b751f60747921B33613E

🚀 Server Running:
   HTTP API: http://localhost:3002
   WebSocket: ws://localhost:3002/auction

📊 Available Endpoints:
   GET  /api/health          - Health check
   POST /api/auth/login      - User authentication
   POST /api/auth/register   - User registration
   GET  /api/lots            - List all lots
   POST /api/lots            - Create new lot
   GET  /api/auctions        - List auctions
   POST /api/auctions        - Create auction
   POST /api/auctions/:id/bid - Place bid
   GET  /api/traceability/:lotId - Get lot traceability

🔌 WebSocket Events:
   join_auction       - Join auction room
   leave_auction      - Leave auction room
   new_bid            - New bid placed (broadcast)
   auction_ended      - Auction ended (broadcast)
   auction_update     - Auction status update

⏰ Background Jobs:
   ✅ Auction Monitor Started (checks every 30s)
   ✅ Price Oracle Started (updates every 5min)

==========================================
✅ Server ready! Press Ctrl+C to stop
```

---

### Step 8: Test Backend Health

**Open new terminal:**

```powershell
# Test health endpoint
curl http://localhost:3002/api/health

# Or use browser: http://localhost:3002/api/health
```

**Expected Response:**

```json
{
  "status": "ok",
  "timestamp": "2026-01-07T10:30:45.123Z",
  "services": {
    "database": "connected",
    "redis": "connected",
    "blockchain": "connected",
    "ipfs": "connected"
  },
  "contracts": {
    "pepperAuction": "0x70e0bA845a1A0F2DA3359C97E0285013525FFC49",
    "pepperPassport": "0x998abeb3E57409262aE5b751f60747921B33613E"
  },
  "version": "1.0.0"
}
```

---

## 🌐 Web Frontend Setup

### Step 9: Start Web Dashboard

**Terminal 4 (Keep Running):**

```powershell
cd web
npm run dev
```

**Expected Output:**

```
  ▲ Next.js 14.0.4
  - Local:        http://localhost:3000
  - Network:      http://192.168.1.190:3000

 ✓ Ready in 3.2s
 ○ Compiling / ...
 ✓ Compiled / in 1.5s
```

**Open Browser:**

- Navigate to: **http://localhost:3000**
- You should see the SmartPepper dashboard

---

### Step 10: Configure MetaMask

#### 10.1 Add Hardhat Network to MetaMask

1. **Open MetaMask** (browser extension)
2. Click network dropdown (top center)
3. Click "Add Network" → "Add a network manually"
4. Enter details:

```
Network Name: Hardhat Local
RPC URL: http://127.0.0.1:8545
Chain ID: 1337
Currency Symbol: ETH
Block Explorer URL: (leave empty)
```

5. Click "Save"

---

#### 10.2 Import Test Account

1. Click account icon (top right)
2. "Import Account"
3. Select "Private Key"
4. Paste Hardhat Account #0 private key:

```
0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

5. Click "Import"
6. **Rename account** to "Hardhat Deployer" for clarity

**Import Additional Accounts** (optional):

- **Account #1** (Farmer):
  ```
  0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
  ```
- **Account #2** (Exporter):
  ```
  0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
  ```

---

#### 10.3 Connect Wallet to Application

1. Open http://localhost:3000
2. Click "Connect Wallet" button
3. Select MetaMask
4. Approve connection
5. Select "Hardhat Local" network
6. You should see your balance (10000 ETH)

---

## 📱 Mobile App Setup

### Step 11: Configure Flutter Environment

#### 11.1 Verify Flutter Installation

```powershell
flutter doctor
```

**Expected Output:**

```
Doctor summary (to see all details, run flutter doctor -v):
[✓] Flutter (Channel stable, 3.7.0)
[✓] Android toolchain - develop for Android devices
[✓] Chrome - develop for the web
[✓] Android Studio (version 2022.1)
[✓] VS Code (version 1.85.0)
[✓] Connected device (2 available)
[✓] HTTP Host Availability

• No issues found!
```

---

#### 11.2 Update IP Address Configuration

**Find Your Computer's IP Address:**

```powershell
# Windows
ipconfig

# Look for IPv4 Address under your active network adapter
# Example: 192.168.1.190
```

**Update mobile/lib/config/env.dart:**

```dart
class Environment {
  static const String apiBaseUrl = 'http://192.168.1.190:3002/api';
  static const String blockchainRpcUrl = 'http://192.168.1.190:8545';
  static const String wsUrl = 'ws://192.168.1.190:3002/auction';

  // Contract addresses (from deployment)
  static const String auctionContractAddress =
      '0x70e0bA845a1A0F2DA3359C97E0285013525FFC49';
  static const String passportContractAddress =
      '0x998abeb3E57409262aE5b751f60747921B33613E';
}
```

**⚠️ IMPORTANT**: Replace `192.168.1.190` with YOUR computer's IP address!

---

#### 11.3 Run Mobile App

**Android Emulator:**

```powershell
cd mobile

# List available emulators
flutter emulators

# Launch emulator
flutter emulators --launch <emulator_id>

# Or open Android Studio → AVD Manager → Start emulator

# Run app
flutter run
```

**Physical Device:**

```powershell
# Enable USB debugging on your Android device:
# Settings → About Phone → Tap "Build number" 7 times
# Settings → Developer Options → Enable "USB Debugging"

# Connect device via USB
# Allow USB debugging when prompted

# Verify device connected
flutter devices

# Run app
flutter run
```

**iOS Simulator (macOS only):**

```bash
# Open simulator
open -a Simulator

# Run app
cd mobile
flutter run
```

**Expected Output:**

```
Launching lib/main.dart on Android SDK built for x86 in debug mode...
Running Gradle task 'assembleDebug'...
✓ Built build/app/outputs/flutter-apk/app-debug.apk.

🎉 App installed!
📱 Running on Android SDK (emulator-5554)

Hot reload enabled. Press 'r' to hot reload, 'R' to restart.
```

---

## 🚀 Running the Complete System

### Step 12: Full System Startup Checklist

Open **5 terminals** (or use tabs in Windows Terminal):

#### Terminal 1: Blockchain Node

```powershell
cd blockchain
npm run node
```

**Status**: ✅ Running on http://127.0.0.1:8545

---

#### Terminal 2: IPFS Node (Optional)

```powershell
ipfs daemon
```

**Status**: ✅ Running on http://127.0.0.1:5001 (API) and http://127.0.0.1:8080 (Gateway)

**Alternative**: Use IPFS Desktop app (GUI)

---

#### Terminal 3: Backend Server

```powershell
cd backend
npm run dev
```

**Status**: ✅ Running on http://localhost:3002

---

#### Terminal 4: Web Frontend

```powershell
cd web
npm run dev
```

**Status**: ✅ Running on http://localhost:3000

---

#### Terminal 5: Mobile App

```powershell
cd mobile
flutter run
```

**Status**: ✅ Running on emulator/device

---

### System Status Dashboard

```
┌─────────────────────────────────────────────┐
│      SMARTPEPPER SYSTEM STATUS              │
├─────────────────────────────────────────────┤
│                                             │
│  ✅ Blockchain Node    http://localhost:8545 │
│  ✅ IPFS Gateway       http://localhost:8080 │
│  ✅ Backend API        http://localhost:3002 │
│  ✅ Web Dashboard      http://localhost:3000 │
│  ✅ Mobile App         Running on device    │
│  ✅ PostgreSQL         Port 5432            │
│  ✅ Redis              Port 6379            │
│                                             │
│  📝 Contract Addresses:                     │
│     Auction:  0x70e0bA845a...525FFC49      │
│     Passport: 0x998abeb3E...21B33613E      │
│                                             │
└─────────────────────────────────────────────┘
```

---

## ✅ Testing & Verification

### Step 13: End-to-End Test Flow

#### Test 1: Create Pepper Lot (Mobile App)

1. **Open Mobile App**
2. Navigate to "Create Lot"
3. Fill in details:
   - **Lot ID**: Auto-generated (LOT-1767513...)
   - **Variety**: Tellicherry
   - **Quantity**: 100 kg
   - **Origin**: Wayanad, Kerala
   - **Harvest Date**: Select date
   - **Grade**: Premium
4. **Upload Documents**:
   - Farm photo (JPEG/PNG)
   - Quality certificate (PDF)
5. Click "Submit"
6. **Wait for Confirmation** (~15 seconds)

**Expected Result:**

```
✅ Lot Created Successfully!

Lot ID: LOT-1767513191165
NFT Token ID: #1
Transaction Hash: 0x7d7f0a...1c7c0e51

Your lot is now registered on the blockchain
and an NFT passport has been minted!
```

---

#### Test 2: Create Auction (Mobile App)

1. Go to "My Lots"
2. Select the created lot
3. Click "Create Auction"
4. Set auction parameters:
   - **Reserve Price**: 50000 LKR (or 0.02 ETH)
   - **Duration**: 1 day
   - **Start Time**: Immediate
5. Click "Create Auction"

**Expected Result:**

```
✅ Auction Created!

Auction ID: 1767473660742
Blockchain Auction ID: 0
Starting Price: 50000 LKR
Status: Active

Your auction is now live!
Exporters can start bidding.
```

---

#### Test 3: View Auction (Web Dashboard)

1. **Open Web Browser**: http://localhost:3000
2. Click "Live Auctions"
3. You should see your auction listed:

```
┌────────────────────────────────────┐
│  Tellicherry Pepper - 100 kg       │
│  Current Bid: 50000 LKR            │
│  Time Remaining: 23h 59m           │
│  Bids: 0                           │
│  [View Details]                    │
└────────────────────────────────────┘
```

---

#### Test 4: Place Bid (Web Dashboard)

1. Click "View Details" on the auction
2. Connect MetaMask wallet
3. Switch to **Account #2** (Exporter account)
4. Enter bid amount: **55000 LKR** (or 0.022 ETH)
5. Click "Place Bid"
6. **Confirm transaction** in MetaMask

**Expected Result:**

```
✅ Bid Placed Successfully!

Your Bid: 55000 LKR
Transaction Hash: 0xa2d44e...35a37c7c

You are now the highest bidder!
```

---

#### Test 5: Real-time Update (Mobile App)

1. **Check Mobile App** (Farmer view)
2. Navigate to "Live Auctions"
3. **You should see the new bid instantly** (no refresh needed!)

```
🔔 New Bid Received!

Auction: LOT-1767513191165
Bidder: 0x7099...dc79C8
Amount: 55000 LKR
Time: Just now
```

**This confirms WebSocket real-time updates are working!**

---

#### Test 6: Traceability View (Web Dashboard)

1. Click "Traceability" in navigation
2. Enter Lot ID: `LOT-1767513191165`
3. Click "Search"

**Expected Display:**

```
┌───────────────────────────────────────────────┐
│        PEPPER LOT TRACEABILITY                │
├───────────────────────────────────────────────┤
│                                               │
│  📦 Lot Information                           │
│     Variety: Tellicherry                      │
│     Quantity: 100 kg                          │
│     Grade: Premium                            │
│     Origin: Wayanad, Kerala                   │
│                                               │
│  🌾 Farmer Details                            │
│     Address: 0xf39F...2266                    │
│     Harvest Date: Jan 5, 2026                 │
│                                               │
│  🎫 NFT Passport                              │
│     Token ID: #1                              │
│     Contract: 0x998a...613E                   │
│     View on Blockchain →                      │
│                                               │
│  📜 Event Timeline                            │
│     ✅ Lot Registered - Jan 5, 10:30 AM       │
│        TX: 0x7d7f...0e51                      │
│                                               │
│     ✅ NFT Minted - Jan 5, 10:30 AM           │
│        TX: 0x7d7f...0e51                      │
│                                               │
│     ✅ Auction Created - Jan 5, 11:15 AM      │
│        TX: 0xa2d4...7c7c                      │
│                                               │
│     ✅ Bid Placed (55000 LKR) - Jan 5, 2:30 PM│
│        Bidder: 0x7099...dc79C8                │
│        TX: 0xb3e5...8d8d                      │
│                                               │
│  📄 Documents                                 │
│     🖼️ Farm Photo                            │
│     📋 Quality Certificate                    │
│                                               │
└───────────────────────────────────────────────┘
```

---

### Step 14: Verify Blockchain Records

```powershell
cd blockchain
npx hardhat console --network localhost
```

**In Console:**

```javascript
// Get contract instances
const PepperAuction = await ethers.getContractFactory("PepperAuction");
const auction = PepperAuction.attach("0x70e0bA845a1A0F2DA3359C97E0285013525FFC49");

const PepperPassport = await ethers.getContractFactory("PepperPassport");
const passport = PepperPassport.attach("0x998abeb3E57409262aE5b751f60747921B33613E");

// Check NFT was minted
const tokenId = 1;
const owner = await passport.ownerOf(tokenId);
console.log("NFT Owner:", owner);
// Should be farmer's address: 0xf39F...2266

// Get passport data
const passportData = await passport.passports(tokenId);
console.log("Passport Data:", passportData);

// Check auction
const auctionId = 0;
const auctionData = await auction.auctions(auctionId);
console.log("Auction Data:", auctionData);

// Check current bid
console.log("Current Bid:", ethers.formatEther(auctionData.currentBid), "ETH");
console.log("Highest Bidder:", auctionData.highestBidder);

.exit
```

---

## 🔧 Troubleshooting

### Common Issues & Solutions

#### Issue 1: "npm is not recognized"

**Windows PowerShell Execution Policy Error:**

```powershell
# Run PowerShell as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or for current session only:
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

**PATH not updated:**

```powershell
# Add Node.js to PATH temporarily
$env:Path += ";C:\Program Files\nodejs"

# Permanent fix: Restart computer or log out/in
```

---

#### Issue 2: PostgreSQL Connection Failed

**Error: `connection refused` or `password authentication failed`**

**Solutions:**

```powershell
# 1. Check PostgreSQL is running
pg_isready
# If not: net start postgresql-x64-14

# 2. Test connection
psql -U postgres -d smartpepper

# 3. Check credentials in backend/.env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=smartpepper
DB_USER=postgres
DB_PASSWORD=your_actual_password

# 4. Reset password (if forgotten)
# Edit: C:\Program Files\PostgreSQL\14\data\pg_hba.conf
# Change: md5 → trust (temporarily)
# Restart: net stop postgresql-x64-14 && net start postgresql-x64-14
# Connect and reset: ALTER USER postgres WITH PASSWORD 'new_password';
```

---

#### Issue 3: Port Already in Use

**Error: `EADDRINUSE: address already in use :::3002`**

**Solution:**

```powershell
# Find process using port 3002
netstat -ano | findstr :3002

# Kill process (replace PID with actual number)
taskkill /PID <PID> /F

# Or change port in backend/.env
PORT=3003
```

---

#### Issue 4: MetaMask Network Error

**Error: `Incorrect network` or `Chain ID mismatch`**

**Solution:**

1. Open MetaMask
2. Click network dropdown
3. Select "Hardhat Local" (Chain ID 1337)
4. If missing, add manually:
   - RPC: http://127.0.0.1:8545
   - Chain ID: 1337

**Reset MetaMask (if corrupted):**

1. Settings → Advanced → Reset Account
2. Re-import private key
3. Reconnect to application

---

#### Issue 5: Mobile App Can't Connect to Backend

**Error: `Connection refused` or `Failed to connect`**

**Checklist:**

```powershell
# 1. Find your computer's IP
ipconfig
# Note IPv4 address (e.g., 192.168.1.190)

# 2. Update mobile/lib/config/env.dart
static const String apiBaseUrl = 'http://YOUR_IP:3002/api';

# 3. Ensure firewall allows connections
# Windows Defender Firewall → Allow an app
# Add Node.js to allowed apps

# 4. Test connection from phone browser
# Open: http://YOUR_IP:3002/api/health
# Should return JSON response

# 5. Ensure phone and computer on same Wi-Fi network
```

---

#### Issue 6: IPFS Not Working

**Error: `IPFS connection failed`**

**Solution:**

```powershell
# Option 1: Use public gateway (no local IPFS needed)
# backend/.env:
IPFS_GATEWAY_URL=https://ipfs.io/ipfs

# web/.env.local:
NEXT_PUBLIC_IPFS_GATEWAY=https://ipfs.io/ipfs

# Option 2: Start local IPFS
ipfs daemon

# Or use IPFS Desktop app (GUI)
# Download: https://docs.ipfs.tech/install/ipfs-desktop/
```

---

#### Issue 7: Blockchain Transaction Fails

**Error: `Transaction reverted` or `insufficient funds`**

**Solutions:**

```javascript
// 1. Check account has ETH
// Hardhat accounts have 10000 ETH each

// 2. Check gas limits in contract calls
// backend/src/services/blockchainService.js:
const gasLimit = 5000000; // Increase if needed

// 3. Restart Hardhat node (clears state)
// Terminal 1: Ctrl+C, then: npm run node
// Terminal 2: npm run deploy:local

// 4. Check contract ownership
// Only auction contract can mint NFTs
```

---

#### Issue 8: WebSocket Not Connecting

**Error: `WebSocket connection failed`**

**Check:**

```javascript
// 1. Backend WebSocket running
// Look for: "WebSocket server listening on port 3002"

// 2. Correct namespace in mobile app
// mobile/lib/services/socket_service.dart:
socket = IO.io("ws://YOUR_IP:3002/auction");

// 3. CORS settings in backend
// backend/src/index.js:
const cors = require("cors");
app.use(cors({ origin: "*" })); // For development

// 4. Test WebSocket
// Browser console:
const socket = io("http://localhost:3002/auction");
socket.on("connect", () => console.log("Connected!"));
```

---

#### Issue 9: Database Migration Errors

**Error: `relation "pepper_lots" does not exist`**

**Solution:**

```powershell
cd backend

# Drop and recreate database
psql -U postgres
DROP DATABASE smartpepper;
CREATE DATABASE smartpepper;
\q

# Run migrations again
psql -U postgres -d smartpepper -f create-tables.sql

# Add missing columns
node add-blockchain-tx-hash-column.js

# Verify
psql -U postgres -d smartpepper
\dt
\d pepper_lots
\q
```

---

#### Issue 10: Flutter Build Errors

**Error: `Gradle build failed` or `Pod install failed`**

**Android:**

```powershell
cd mobile/android
./gradlew clean

cd ..
flutter clean
flutter pub get
flutter run
```

**iOS (macOS only):**

```bash
cd mobile/ios
pod deintegrate
pod install

cd ..
flutter clean
flutter pub get
flutter run
```

---

## 🚀 Production Deployment

### Step 15: Deploy to Testnet (Sepolia)

#### 15.1 Get Sepolia Test ETH

1. **Get Sepolia Faucet ETH**:
   - Visit: https://sepoliafaucet.com/
   - Or: https://faucet.sepolia.dev/
   - Enter your wallet address
   - Request test ETH (0.5 ETH usually sufficient)

---

#### 15.2 Configure Sepolia Deployment

**blockchain/.env:**

```env
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_API_KEY
SEPOLIA_PRIVATE_KEY=0xYOUR_PRIVATE_KEY_WITH_TEST_ETH
ETHERSCAN_API_KEY=YOUR_ETHERSCAN_API_KEY
```

**Get Infura API Key**:

1. Visit: https://infura.io/
2. Sign up / Log in
3. Create new project
4. Copy API key

**Get Etherscan API Key**:

1. Visit: https://etherscan.io/
2. Sign up
3. API Keys → Create API Key

---

#### 15.3 Deploy to Sepolia

```powershell
cd blockchain
npm run deploy:sepolia
```

**Expected Output:**

```
📦 Deploying to Sepolia Testnet...
==========================================

Deployer: 0xYourAddress
Balance: 0.5 ETH

1️⃣ Deploying PepperPassport...
   ⏳ Waiting for 2 confirmations...
   ✅ Deployed to: 0xSepoliaPassportAddress
   📝 TX: 0x...

2️⃣ Deploying PepperAuction...
   ⏳ Waiting for 2 confirmations...
   ✅ Deployed to: 0xSepoliaAuctionAddress
   📝 TX: 0x...

3️⃣ Verifying contracts on Etherscan...
   ✅ PepperPassport verified
   ✅ PepperAuction verified

==========================================
🎉 Deployment Complete!

View on Etherscan:
https://sepolia.etherscan.io/address/0xSepoliaAuctionAddress
```

---

#### 15.4 Update Configuration for Sepolia

**backend/.env:**

```env
BLOCKCHAIN_RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_KEY
CHAIN_ID=11155111
CONTRACT_ADDRESS=0xSepoliaAuctionAddress
PASSPORT_CONTRACT_ADDRESS=0xSepoliaPassportAddress
```

**web/.env.local:**

```env
NEXT_PUBLIC_BLOCKCHAIN_RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_KEY
NEXT_PUBLIC_CHAIN_ID=11155111
NEXT_PUBLIC_CONTRACT_ADDRESS=0xSepoliaAuctionAddress
NEXT_PUBLIC_PASSPORT_CONTRACT_ADDRESS=0xSepoliaPassportAddress
```

**mobile/lib/config/env.dart:**

```dart
static const String blockchainRpcUrl = 'https://sepolia.infura.io/v3/YOUR_INFURA_KEY';
static const int chainId = 11155111;
static const String auctionContractAddress = '0xSepoliaAuctionAddress';
static const String passportContractAddress = '0xSepoliaPassportAddress';
```

---

### Step 16: Production Checklist

Before deploying to production mainnet:

#### Security Audit

- [ ] Smart contract audit by external firm
- [ ] Penetration testing
- [ ] Code review by senior developers
- [ ] Test coverage > 90%

#### Environment Hardening

- [ ] Use environment variables (never hardcode secrets)
- [ ] Enable HTTPS/TLS for all connections
- [ ] Set up firewall rules
- [ ] Use strong database passwords
- [ ] Enable PostgreSQL SSL connections
- [ ] Set up Redis password authentication

#### Monitoring & Logging

- [ ] Set up error tracking (Sentry, Rollbar)
- [ ] Configure log aggregation (ELK, Datadog)
- [ ] Set up uptime monitoring (UptimeRobot)
- [ ] Configure alerts for critical errors
- [ ] Set up blockchain event monitoring

#### Backup Strategy

- [ ] Automated database backups (daily)
- [ ] IPFS pin important files to multiple nodes
- [ ] Keep private keys in hardware wallet / KMS
- [ ] Document recovery procedures

#### Performance Optimization

- [ ] Database indexing on frequently queried columns
- [ ] Redis caching for expensive queries
- [ ] CDN for static assets
- [ ] Image optimization (WebP, lazy loading)
- [ ] WebSocket connection pooling

---

## 📚 Additional Resources

### Documentation

- **Smart Contracts**: [blockchain/contracts/README.md](blockchain/contracts/README.md)
- **API Documentation**: [API_DOCUMENTATION.yaml](API_DOCUMENTATION.yaml)
- **Database Schema**: [backend/create-tables.sql](backend/create-tables.sql)
- **Mobile App Guide**: [mobile/README.md](mobile/README.md)

### External Links

- **Hardhat**: https://hardhat.org/docs
- **Ethers.js**: https://docs.ethers.org/v6/
- **Next.js**: https://nextjs.org/docs
- **Flutter**: https://docs.flutter.dev/
- **IPFS**: https://docs.ipfs.tech/
- **PostgreSQL**: https://www.postgresql.org/docs/

### Community Support

- **GitHub Issues**: Report bugs and request features
- **Discord**: (coming soon)
- **Stack Overflow**: Tag questions with `smartpepper`

---

## 🎓 Development Tips

### Hot Reload

- **Web**: Next.js auto-reloads on file changes
- **Mobile**: Press `r` in Flutter terminal for hot reload, `R` for restart
- **Backend**: Uses nodemon for auto-restart

### Debugging

**Backend Logs:**

```powershell
cd backend
tail -f logs/app.log  # macOS/Linux
Get-Content logs/app.log -Wait  # Windows PowerShell
```

**Blockchain Events:**

```powershell
cd blockchain
npx hardhat console --network localhost

# Listen to events
const auction = await ethers.getContractAt("PepperAuction", "0x70e0...");
auction.on("AuctionCreated", (auctionId, lotId, farmer) => {
  console.log("New auction:", auctionId, lotId, farmer);
});
```

**Browser Console:**

- Press F12 → Console tab
- Check for JavaScript errors
- Monitor network requests (Network tab)
- Inspect WebSocket connections

**Mobile App:**

```powershell
# View logs
flutter logs

# Or use Android Studio / Xcode debugger
```

---

### Testing

**Backend Unit Tests:**

```powershell
cd backend
npm test
```

**Smart Contract Tests:**

```powershell
cd blockchain
npx hardhat test
```

**Frontend Tests:**

```powershell
cd web
npm test
```

---

## ✅ Final Verification Checklist

After completing setup, verify all systems:

```
┌────────────────────────────────────────────────┐
│      FINAL SYSTEM VERIFICATION                 │
├────────────────────────────────────────────────┤
│                                                │
│  ✅ Node.js installed (v18+)                   │
│  ✅ PostgreSQL installed and running           │
│  ✅ Database 'smartpepper' created             │
│  ✅ All tables created successfully            │
│  ✅ Hardhat node running                       │
│  ✅ Smart contracts deployed                   │
│  ✅ Backend server started                     │
│  ✅ Web dashboard accessible                   │
│  ✅ Mobile app running                         │
│  ✅ MetaMask configured with Hardhat network   │
│  ✅ Test account imported to MetaMask          │
│  ✅ Created test lot successfully              │
│  ✅ Created test auction successfully          │
│  ✅ Placed test bid successfully               │
│  ✅ Real-time updates working                  │
│  ✅ Traceability page displays correctly       │
│  ✅ IPFS images loading                        │
│                                                │
│  🎉 ALL SYSTEMS OPERATIONAL!                   │
│                                                │
└────────────────────────────────────────────────┘
```

---

## 🎯 Next Steps

### For Developers

1. **Explore Codebase**:

   - Read smart contract comments
   - Review API endpoints
   - Understand database relationships
   - Study component architecture

2. **Implement Remaining Features** (40%):

   - Payment integration
   - Multi-language support
   - Advanced analytics
   - Automated auction finalization

3. **Optimize Performance**:
   - Database query optimization
   - Smart contract gas reduction
   - Frontend bundle size reduction
   - Image lazy loading

### For Researchers

1. **Data Collection**:

   - Run user acceptance testing
   - Collect performance metrics
   - Analyze blockchain transaction costs
   - Study user behavior patterns

2. **Research Analysis**:

   - Compare with traditional auction systems
   - Measure transparency improvements
   - Calculate cost savings
   - Evaluate farmer adoption barriers

3. **Documentation**:
   - Write research paper
   - Create user manuals
   - Prepare presentation materials
   - Document lessons learned

---

## 🌶️ Congratulations!

You have successfully set up the SmartPepper Blockchain Auction System!

**System Features Available:**

✅ Decentralized auction platform  
✅ NFT-based traceability  
✅ Real-time bidding  
✅ Transparent price discovery  
✅ Immutable record keeping  
✅ Multi-platform access (Web + Mobile)  
✅ IPFS document storage  
✅ Farmer-friendly mobile interface  
✅ Exporter web dashboard

**What's Next?**

- Test the system thoroughly
- Gather user feedback
- Implement remaining features
- Prepare for production deployment
- Scale to handle real-world load

---

## 📞 Support & Contact

**Issues?** Check the [Troubleshooting](#troubleshooting) section above.

**Still stuck?** Open an issue on GitHub with:

- Error message (full text)
- System information (OS, Node version)
- Steps to reproduce
- Screenshots (if relevant)

**Contributions Welcome!** Submit pull requests for:

- Bug fixes
- Feature enhancements
- Documentation improvements
- Test coverage

---

**Last Updated**: January 7, 2026  
**Version**: 1.0.0  
**Status**: 60% Implementation Complete
