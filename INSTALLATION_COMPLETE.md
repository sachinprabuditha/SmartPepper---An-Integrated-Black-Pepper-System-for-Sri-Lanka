# ✅ SmartPepper Installation Complete!

## 🎉 What's Been Done

### 1. ✅ Fixed Windows Environment Issues

- **PowerShell Execution Policy**: Set to RemoteSigned for npm scripts
- **Node.js PATH**: Added to environment (v24.11.1 + npm v11.6.2)
- **Dependencies**: All npm packages installed successfully

### 2. ✅ Blockchain Layer

- Smart contract compiled successfully (`PepperAuction.sol`)
- Hardhat configuration ready for localhost/Sepolia/Polygon
- OpenZeppelin contracts updated to v5
- Artifacts generated in `blockchain/artifacts/`
- `.env` file created with test private key

**Installed (579 packages):**

- hardhat@2.19.2
- ethers@6.9.0
- @openzeppelin/contracts@5.0.1
- @nomicfoundation/hardhat-toolbox@4.0.0

### 3. ✅ Backend Layer

- Express + Socket.IO server configured
- PostgreSQL, Redis, IPFS client ready
- API routes and services created
- `.env` file created from template

**Installed (668 packages):**

- express@4.18.2
- socket.io@4.6.1
- pg (PostgreSQL client)
- redis@4.6.5
- ipfs-http-client@60.0.1
- ethers@6.9.0

### 4. ✅ Web Dashboard

- Next.js 14 App Router configured
- React 18 + TypeScript
- Web3 integration (Wagmi, RainbowKit)
- Real-time WebSocket components
- `.env.local` file created from template

**Installed (908 packages):**

- next@14.0.4
- react@18.2.0
- wagmi@2.5.7
- @rainbow-me/rainbowkit@2.0.2
- viem@2.7.15
- socket.io-client@4.6.1
- tailwindcss@3.4.1

## 📋 Required Setup (Before Running)

### Step 1: Install PostgreSQL (if not installed)

**Option A: Official Installer**

```powershell
# Download from: https://www.postgresql.org/download/windows/
# Or use Chocolatey:
choco install postgresql

# Start service
net start postgresql-x64-14

# Create database
psql -U postgres
CREATE DATABASE smartpepper;
\q
```

**Option B: Docker (Recommended for testing)**

```powershell
# If you have Docker Desktop installed
docker run -d --name smartpepper-postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=smartpepper -p 5432:5432 postgres:14
```

### Step 2: Install Redis (if not installed)

**Option A: Windows Native (via Chocolatey)**

```powershell
choco install redis-64
redis-server
```

**Option B: Docker (Recommended)**

```powershell
docker run -d --name smartpepper-redis -p 6379:6379 redis:7-alpine
```

**Option C: WSL (if you use Windows Subsystem for Linux)**

```powershell
wsl
sudo apt update
sudo apt install redis-server
redis-server --daemonize yes
```

### Step 3: Configure Backend .env

Edit `backend/.env`:

```properties
# Database
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/smartpepper

# Redis
REDIS_URL=redis://localhost:6379

# Blockchain (update after deployment)
CONTRACT_ADDRESS=0x5FbDB2315678afecb367f032d93F642f64180aa3
BLOCKCHAIN_RPC_URL=http://127.0.0.1:8545

# IPFS (optional for testing)
IPFS_HOST=localhost
IPFS_PORT=5001
IPFS_PROTOCOL=http
```

### Step 4: Run Database Migrations

```powershell
cd backend
node scripts/migrate.js
```

This creates tables:

- `users` (farmers, buyers, admins)
- `pepper_lots` (lot details, certificates)
- `auctions` (auction state, timing)
- `bids` (bidding history)
- `compliance_checks` (certificate validation)

## 🚀 How to Run the System

### Terminal 1: Start Local Blockchain

```powershell
cd blockchain
npm run node
```

**Output:** Local Hardhat network running on `http://127.0.0.1:8545`

- 20 test accounts with 10,000 ETH each
- Instant mining (no waiting for blocks)

### Terminal 2: Deploy Smart Contract

```powershell
cd blockchain
npm run deploy:local
```

**Output:**

```
PepperAuction deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
```

**Important:** Copy this address to `backend/.env` and `web/.env.local`!

### Terminal 3: Start Backend Server

```powershell
cd backend
npm run dev
```

**Output:**

```
✅ Database connected
✅ Redis connected
✅ Blockchain service initialized
✅ Server running on http://localhost:3000
✅ WebSocket server ready
```

### Terminal 4: Start Web Dashboard

```powershell
cd web
npm run dev
```

**Output:**

```
✓ Ready in 2.5s
- Local: http://localhost:3001
```

## 🌐 Access Points

| Service              | URL                          | Purpose                     |
| -------------------- | ---------------------------- | --------------------------- |
| **Web Dashboard**    | http://localhost:3001        | User interface for auctions |
| **Backend API**      | http://localhost:3000        | REST API + WebSocket        |
| **Health Check**     | http://localhost:3000/health | System status               |
| **Local Blockchain** | http://127.0.0.1:8545        | Hardhat node RPC            |

## 🔐 MetaMask Setup

1. Install [MetaMask Extension](https://metamask.io/)
2. Add custom network:
   - **Network Name:** Hardhat Local
   - **RPC URL:** http://127.0.0.1:8545
   - **Chain ID:** 31337
   - **Currency Symbol:** ETH
3. Import test account:
   - Private key: `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80`
   - (This is Account #0 from Hardhat, has 10,000 ETH)

## 🧪 Test the System

### 1. Create a Test Auction

```powershell
# In a new terminal
cd blockchain
npx hardhat console --network localhost
```

```javascript
const PepperAuction = await ethers.getContractFactory("PepperAuction");
const auction = await PepperAuction.attach(
  "0x5FbDB2315678afecb367f032d93F642f64180aa3"
);

// Create a lot
await auction.createLot(
  "LOT-001",
  "Tellicherry",
  1000, // 1000 kg
  "Premium",
  "2024-11-01",
  "QmHash123456789"
);

// Create auction
await auction.createAuction(
  "LOT-001",
  ethers.parseEther("0.01"), // Start price: 0.01 ETH
  Math.floor(Date.now() / 1000) + 3600 // Ends in 1 hour
);
```

### 2. Place Bids via Web Dashboard

1. Open http://localhost:3001
2. Click "Connect Wallet" (top right)
3. Select "Hardhat Local" network
4. Navigate to "Live Auctions"
5. Click on LOT-001
6. Enter bid amount (e.g., 0.015 ETH)
7. Click "Place Bid"
8. Confirm in MetaMask
9. Watch real-time updates! 🔥

### 3. Monitor in Real-Time

- **WebSocket Events:** Open browser console to see live updates
- **Backend Logs:** Check terminal running backend
- **Blockchain Events:** Check terminal running Hardhat node

## 📊 Current Status

```
✅ Node.js installed (v24.11.1)
✅ npm working (v11.6.2)
✅ PowerShell configured
✅ Blockchain dependencies installed
✅ Backend dependencies installed
✅ Web dependencies installed
✅ Smart contract compiled
✅ .env files created
⏳ PostgreSQL (needs setup)
⏳ Redis (needs setup)
⏳ Database migrations (needs run)
⏳ Contract deployment (needs run)
```

## 🐛 Common Issues & Fixes

### "pg" module error

```powershell
# PostgreSQL not running
net start postgresql-x64-14

# Or start Docker container
docker start smartpepper-postgres
```

### "Redis connection refused"

```powershell
# Redis not running
redis-server

# Or start Docker container
docker start smartpepper-redis
```

### "Cannot connect to blockchain"

```powershell
# Make sure Hardhat node is running
cd blockchain
npm run node
```

### "Transaction failed"

```powershell
# Check MetaMask is on Hardhat Local network (Chain ID: 31337)
# Check you have test ETH
# Check contract address in .env files matches deployment
```

## 📚 Next Steps

### Immediate (For Testing)

1. ✅ Install PostgreSQL + Redis (or use Docker)
2. ✅ Run database migrations
3. ✅ Start all 4 terminals (blockchain, deploy, backend, web)
4. ✅ Connect MetaMask
5. ✅ Create test auction
6. ✅ Place bids and see real-time updates!

### Future Development (50% Remaining)

- [ ] Build Flutter mobile app
- [ ] Add automated tests (smart contract + API)
- [ ] Deploy to Sepolia testnet
- [ ] Implement advanced compliance rules
- [ ] Add QR/NFC integration
- [ ] Multi-chain support (Polygon)

## 💡 Pro Tips

1. **Use Docker for dependencies** - Easier than native Windows install
2. **Keep Hardhat node running** - Your test blockchain
3. **Watch backend logs** - See WebSocket events in real-time
4. **Browser DevTools** - Monitor WebSocket messages
5. **Hardhat Console** - Interact with contracts directly

## 🎯 You're Ready!

Everything is installed and configured. Follow the "How to Run the System" section above to start your SmartPepper blockchain auction system!

### Quick Start Command Summary

```powershell
# Terminal 1
cd blockchain; npm run node

# Terminal 2 (wait for Terminal 1 to be ready)
cd blockchain; npm run deploy:local

# Terminal 3
cd backend; npm run dev

# Terminal 4
cd web; npm run dev
```

Then open http://localhost:3001 and start bidding! 🌶️🔥

---

**Need Help?**

- Check `SETUP_GUIDE.md` for detailed instructions
- Review `DEPLOYMENT_ROADMAP.md` for architecture overview
- Check troubleshooting section above
