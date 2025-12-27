# SmartPepper Auction Blockchain System - Development Setup Guide

## 📋 Table of Contents

- [System Overview](#system-overview)
- [Prerequisites](#prerequisites)
- [Environment Setup](#environment-setup)
- [Running the System](#running-the-system)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Architecture](#architecture)

---

## 🎯 System Overview

SmartPepper is a blockchain-based pepper auction system with NFT passports for traceability. The system consists of:

- **Backend**: Node.js/Express API with PostgreSQL database
- **Blockchain**: Hardhat local network with Ethereum smart contracts
- **IPFS**: Distributed file storage for certificates and metadata
- **Web Frontend**: Next.js React application
- **Mobile App**: Flutter cross-platform mobile application

---

## 📦 Prerequisites

### Required Software

1. **Node.js** (v18+ recommended)

   - Download: https://nodejs.org/
   - Verify: `node --version`

2. **PostgreSQL** (v14+)

   - Download: https://www.postgresql.org/download/
   - Verify: `psql --version`

3. **Redis** (v7+)

   - Windows: https://github.com/microsoftarchive/redis/releases
   - Verify: `redis-cli --version`

4. **Flutter** (v3.16+)

   - Download: https://docs.flutter.dev/get-started/install
   - Verify: `flutter --version`

5. **IPFS** (Kubo v0.17+)

   - Download: https://docs.ipfs.tech/install/
   - Verify: `ipfs --version`

6. **Git**
   - Download: https://git-scm.com/
   - Verify: `git --version`

### Optional Tools

- **Visual Studio Code** (recommended IDE)
- **Android Studio** (for Android development)
- **Xcode** (for iOS development, macOS only)
- **Postman** (for API testing)

---

## 🔧 Environment Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd SmartPepper-Auction-Blockchain-System
```

### 2. Database Setup

#### PostgreSQL

1. Start PostgreSQL service
2. Create database and user:

```sql
CREATE DATABASE smartpepper;
CREATE USER smartpepper_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE smartpepper TO smartpepper_user;
```

3. Run migrations (from backend folder):

```bash
cd backend
npm install
npm run migrate
```

#### Redis

Start Redis server:

```bash
# Windows
redis-server

# Linux/Mac
sudo systemctl start redis
```

### 3. IPFS Setup

Initialize and start IPFS daemon:

```bash
# Initialize (first time only)
ipfs init

# Configure CORS for web access
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["*"]'
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods '["GET", "POST", "PUT"]'

# Start daemon
ipfs daemon
```

**Important**: Note your IPFS API address (usually `http://127.0.0.1:5001`)

### 4. Backend Setup

```bash
cd backend

# Install dependencies
npm install

# Create .env file
cp .env.example .env
```

Edit `backend/.env`:

```env
PORT=3002
NODE_ENV=development

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=smartpepper
DB_USER=smartpepper_user
DB_PASSWORD=your_password

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# JWT
JWT_SECRET=your_secret_key_here_change_in_production
JWT_EXPIRES_IN=7d

# Blockchain
BLOCKCHAIN_RPC_URL=http://localhost:8545
CHAIN_ID=1337

# IPFS
IPFS_API_URL=http://127.0.0.1:5001
IPFS_GATEWAY_URL=http://127.0.0.1:8080
```

### 5. Blockchain Setup

```bash
cd blockchain

# Install dependencies
npm install

# Compile contracts
npm run compile
```

### 6. Web Frontend Setup

```bash
cd web

# Install dependencies
npm install

# Create .env.local file
cp .env.example .env.local
```

Edit `web/.env.local`:

```env
NEXT_PUBLIC_API_URL=http://localhost:3002/api
NEXT_PUBLIC_BLOCKCHAIN_RPC_URL=http://localhost:8545
NEXT_PUBLIC_CHAIN_ID=1337
```

### 7. Mobile App Setup

```bash
cd mobile

# Install dependencies
flutter pub get

# For Android - accept licenses
flutter doctor --android-licenses
```

#### Configure Network Access

**For Physical Device Testing:**

1. Find your computer's IP address:

   ```bash
   # Windows
   ipconfig

   # Linux/Mac
   ifconfig
   ```

2. Update `mobile/lib/config/env.dart`:

   ```dart
   class Environment {
     // Replace with your computer's IP address
     static const String apiBaseUrl = 'http://192.168.x.x:3002/api';
     static const String blockchainRpcUrl = 'http://192.168.x.x:8545';
     static const int chainId = 1337;

     static const String ipfsApiUrl = 'http://192.168.x.x:5001';
     static const String ipfsGatewayUrl = 'http://192.168.x.x:8080';

     // Contract addresses (update after deployment)
     static const String passportContractAddress = '0x...';
     static const String auctionContractAddress = '0x...';
   }
   ```

**For Android Emulator:**

```dart
static const String apiBaseUrl = 'http://10.0.2.2:3002/api';
static const String blockchainRpcUrl = 'http://10.0.2.2:8545';
```

---

## 🚀 Running the System

### Complete Startup Sequence

#### Terminal 1: IPFS Daemon

```bash
ipfs daemon
```

**Expected Output**: `Daemon is ready`

#### Terminal 2: PostgreSQL & Redis

Ensure both services are running:

```bash
# Check PostgreSQL
psql -U smartpepper_user -d smartpepper -c "SELECT 1"

# Check Redis
redis-cli ping
# Should return: PONG
```

#### Terminal 3: Blockchain (Hardhat Node)

```bash
cd blockchain

# Start Hardhat node (bind to all interfaces for physical device)
npx hardhat node --hostname 0.0.0.0

# Or use the npm script (after updating package.json)
npm run node
```

**Expected Output**:

- `Started HTTP and WebSocket JSON-RPC server at http://0.0.0.0:8545/`
- List of 20 test accounts with private keys

**Important**: Keep this terminal open - the node must stay running!

#### Terminal 4: Deploy Smart Contracts

```bash
cd blockchain

# Deploy contracts to local network
npm run deploy:local
```

**Expected Output**:

```
✅ PepperPassport deployed to: 0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6
✅ PepperAuction deployed to: 0x8A791620dd6260079BF849Dc5567aDC3F2FdC318
```

**Copy these addresses and update:**

- `mobile/lib/config/env.dart`
- `web/.env.local`
- `backend/.env`

#### Terminal 5: Backend API

```bash
cd backend

# Start development server
npm run dev
```

**Expected Output**: `🚀 Server running on http://localhost:3002`

**Test the API**:

```bash
curl http://localhost:3002/api/health
# Should return: {"status":"ok","database":"connected"}
```

#### Terminal 6: Web Frontend (Optional)

```bash
cd web

# Start development server
npm run dev
```

**Expected Output**: `✓ Ready on http://localhost:3000`

**Access**: Open browser to `http://localhost:3000`

#### Terminal 7: Mobile App

```bash
cd mobile

# Run on connected device/emulator
flutter run

# Or specify device
flutter devices  # List available devices
flutter run -d <device-id>
```

**For hot reload during development**: Press `r` in the terminal

---

## 📱 Mobile App Development

### Running on Physical Device

1. **Enable Developer Options** on Android:

   - Settings → About Phone → Tap "Build Number" 7 times
   - Settings → Developer Options → Enable "USB Debugging"

2. **Connect device via USB** and verify:

   ```bash
   flutter devices
   ```

3. **Ensure device is on same WiFi** as your computer

4. **Update mobile/lib/config/env.dart** with your computer's IP address

5. **Run the app**:
   ```bash
   flutter run
   ```

### Running on Emulator

1. **Start Android Emulator**:

   ```bash
   # List emulators
   flutter emulators

   # Start specific emulator
   flutter emulators --launch <emulator-id>
   ```

2. **Use localhost forwarding** (10.0.2.2 for Android emulator)

---

## 🧪 Testing

### Backend API Tests

```bash
cd backend
npm test
```

### Smart Contract Tests

```bash
cd blockchain
npm test
```

### Create Test User (Backend)

```bash
cd backend
node scripts/create-test-user.js
```

### Create Test Lot

Use the PowerShell script:

```powershell
.\test-auction-creation.ps1
```

Or use curl:

```bash
curl -X POST http://localhost:3002/api/lots \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "lotId": "LOT-TEST-001",
    "variety": "Black Pepper Premium",
    "quantity": 100,
    "quality": "AAA",
    "harvestDate": "2025-01-15"
  }'
```

### Mobile App Testing

```bash
cd mobile

# Run tests
flutter test

# Run integration tests
flutter test integration_test/
```

---

## 🔍 Troubleshooting

### Common Issues

#### 1. "Cannot connect to blockchain" Error

**Problem**: Mobile app can't connect to Hardhat node

**Solutions**:

- Ensure Hardhat node is running with `--hostname 0.0.0.0`
- Check firewall settings allow port 8545
- Verify IP address in `mobile/lib/config/env.dart` matches your computer's IP
- Try restarting Hardhat node and redeploying contracts

**Test connection**:

```bash
curl http://YOUR_IP:8545 -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
```

#### 2. "IPFS Connection Timeout"

**Problem**: Cannot upload files to IPFS

**Solutions**:

- Verify IPFS daemon is running: `ipfs swarm peers`
- Check IPFS API is accessible: `curl http://localhost:5001/api/v0/version`
- Update IPFS config for CORS (see IPFS Setup section)
- Restart IPFS daemon

#### 3. "Insufficient Funds" Error

**Problem**: Wallet has no ETH for transactions

**Solution**: The app has auto-funding, but you can manually fund:

```bash
# Using Hardhat console
npx hardhat console --network localhost

> const [funder] = await ethers.getSigners();
> await funder.sendTransaction({
    to: "YOUR_WALLET_ADDRESS",
    value: ethers.parseEther("10")
  });
```

#### 4. Database Connection Errors

**Solutions**:

- Verify PostgreSQL is running: `pg_isready`
- Check credentials in `backend/.env`
- Ensure database exists: `psql -l | grep smartpepper`
- Run migrations: `cd backend && npm run migrate`

#### 5. "Chain ID Mismatch"

**Problem**: Wallet connected to wrong network

**Solution**:

- Ensure `chainId: 1337` in all configs
- Hardhat config: `hardhat.config.js`
- Mobile app: `mobile/lib/config/env.dart`
- Web app: `web/.env.local`

#### 6. Port Already in Use

**Solutions**:

```bash
# Windows - Kill process on port
netstat -ano | findstr :8545
taskkill /PID <PID> /F

# Linux/Mac
lsof -ti:8545 | xargs kill -9
```

#### 7. Flutter Build Errors

**Solutions**:

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub upgrade

# Clear cache
rm -rf .dart_tool/
flutter pub cache repair
```

---

## 🏗️ Architecture

### System Components

```
┌─────────────────────────────────────────────────────┐
│                   Mobile App (Flutter)               │
│                   Web App (Next.js)                  │
└───────────────────┬─────────────────────────────────┘
                    │
                    ├──────────┐
                    │          │
         ┌──────────▼──┐   ┌──▼──────────┐
         │  Backend API │   │  IPFS Node  │
         │  (Express)   │   │  (Storage)  │
         └──────┬───────┘   └─────────────┘
                │
      ┌─────────┼─────────┐
      │         │         │
┌─────▼────┐ ┌──▼────┐ ┌──▼──────────┐
│PostgreSQL│ │ Redis │ │   Hardhat   │
│ Database │ │ Cache │ │  Blockchain │
└──────────┘ └───────┘ └──────┬──────┘
                              │
                    ┌─────────┴──────────┐
                    │ Smart Contracts    │
                    │ - PepperPassport   │
                    │ - PepperAuction    │
                    └────────────────────┘
```

### Data Flow

1. **Lot Creation**:

   - Mobile app → Upload images to IPFS
   - IPFS → Returns hash
   - Mobile app → Mint NFT on blockchain
   - Blockchain → Returns transaction hash
   - Mobile app → Save lot data to backend API
   - Backend → Store in PostgreSQL

2. **Lot Verification**:

   - User scans QR code
   - App fetches blockchain transaction
   - Verify certificate hash matches IPFS content
   - Display verified lot details

3. **Auction Participation**:
   - Buyer connects wallet
   - Place bid via smart contract
   - WebSocket updates real-time bids
   - Winner receives NFT ownership transfer

---

## 📝 Development Workflow

### Daily Development

1. **Start all services** (see Running the System)
2. **Check system health**:

   ```bash
   # Test backend
   curl http://localhost:3002/api/health

   # Test blockchain
   curl http://localhost:8545 -X POST -H "Content-Type: application/json" \
     --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'

   # Test IPFS
   ipfs id
   ```

3. **Make changes** and test with hot reload:

   - Backend: Changes auto-reload with nodemon
   - Web: Next.js fast refresh
   - Mobile: Press `r` for hot reload, `R` for hot restart

4. **Commit changes**:
   ```bash
   git add .
   git commit -m "Description of changes"
   git push
   ```

### Before Committing

1. **Run tests**:

   ```bash
   cd backend && npm test
   cd ../blockchain && npm test
   cd ../mobile && flutter test
   ```

2. **Check code quality**:

   ```bash
   # Flutter
   flutter analyze

   # JavaScript (if ESLint configured)
   npm run lint
   ```

3. **Update documentation** if APIs changed

---

## 🔐 Security Notes

### Development Environment

⚠️ **WARNING**: The following are for DEVELOPMENT ONLY:

- Test account private keys are publicly known
- Use default credentials for local database
- CORS is wide open for testing
- No rate limiting or authentication checks

### Production Deployment

When deploying to production:

1. **Change all passwords and secrets**
2. **Use environment-specific `.env` files**
3. **Enable SSL/TLS** for all connections
4. **Implement proper CORS policies**
5. **Use production-grade blockchain network** (not Hardhat)
6. **Enable rate limiting** on API endpoints
7. **Set up monitoring and logging**
8. **Use proper key management** (AWS KMS, HashiCorp Vault, etc.)

---

## 📞 Support

### Documentation Files

- `README.md` - Project overview
- `API_DOCUMENTATION.yaml` - API reference
- `API_GUIDE.md` - API usage guide
- `NFT_PASSPORT_GUIDE.md` - NFT passport implementation
- `DEPLOYMENT_ROADMAP.md` - Production deployment guide

### Useful Commands

```bash
# Check system status
npm run status  # If configured

# View logs
tail -f backend/logs/app.log
tail -f blockchain/logs/node.log

# Reset everything (nuclear option)
cd backend && npm run db:reset
cd ../blockchain && npm run clean && npm run compile
cd ../mobile && flutter clean && flutter pub get
```

---

## 📚 Additional Resources

- [Hardhat Documentation](https://hardhat.org/docs)
- [Flutter Documentation](https://docs.flutter.dev/)
- [IPFS Documentation](https://docs.ipfs.tech/)
- [Web3.dart Documentation](https://pub.dev/packages/web3dart)
- [Next.js Documentation](https://nextjs.org/docs)
- [Express.js Documentation](https://expressjs.com/)

---

## ✅ Quick Start Checklist

- [ ] Install all prerequisites
- [ ] Clone repository
- [ ] Setup PostgreSQL database
- [ ] Start Redis server
- [ ] Initialize and start IPFS daemon
- [ ] Install backend dependencies
- [ ] Install blockchain dependencies
- [ ] Start Hardhat node
- [ ] Deploy smart contracts
- [ ] Update contract addresses in configs
- [ ] Start backend API
- [ ] Install mobile app dependencies
- [ ] Update mobile app network config
- [ ] Run mobile app on device/emulator
- [ ] Create test user and test lot
- [ ] Verify end-to-end flow

---

**Last Updated**: December 26, 2025
**Version**: 1.0.0
