# SmartPepper - Quick Setup Guide

## 🚀 Complete System Setup

### 1. Blockchain (Smart Contracts)

```powershell
cd blockchain
npm install
copy .env.example .env

# Edit .env with your Sepolia RPC URL and private key

# Compile contracts
npm run compile

# Start local blockchain (Terminal 1)
npm run node

# Deploy contracts (Terminal 2)
npm run deploy:local

# Or deploy to Sepolia testnet
npm run deploy:sepolia
```

### 2. Backend (API + WebSocket)

```powershell
cd ..\backend
npm install
copy .env.example .env

# Edit .env:
# - Database credentials
# - Redis connection
# - CONTRACT_ADDRESS from deployment
# - IPFS settings

# Set up PostgreSQL database
# Create database: createdb smartpepper

# Run migrations
npm run migrate

# Start backend server
npm run dev
```

### 3. Web Dashboard

```powershell
cd ..\web
npm install
copy .env.example .env

# Edit .env:
# NEXT_PUBLIC_API_URL=http://localhost:3000
# NEXT_PUBLIC_WS_URL=http://localhost:3000
# NEXT_PUBLIC_CONTRACT_ADDRESS=<from deployment>
# NEXT_PUBLIC_CHAIN_ID=11155111

# Start web dashboard
npm run dev
```

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

#### 4. Git

- [Download](https://git-scm.com/downloads)
- Or use: `choco install git`

### Optional

- IPFS node (for certificate storage)
- MetaMask wallet extension

## 🔧 Detailed Configuration

### PostgreSQL Setup

```powershell
# Windows (using chocolatey)
choco install postgresql

# Start PostgreSQL service
net start postgresql-x64-14

# Create database
psql -U postgres
CREATE DATABASE smartpepper;
\q
```

### Redis Setup

```powershell
# Windows (using chocolatey)
choco install redis-64

# Or use WSL with Docker
wsl
docker run -d -p 6379:6379 redis:7-alpine
```

### IPFS Setup (Optional)

```powershell
# Download IPFS Desktop
# https://docs.ipfs.tech/install/ipfs-desktop/

# Or use command line
choco install go-ipfs
ipfs init
ipfs daemon
```

## 🌐 Access the Application

After starting all services:

- **Web Dashboard:** http://localhost:3001
- **Backend API:** http://localhost:3000
- **API Health:** http://localhost:3000/health
- **Local Blockchain:** http://127.0.0.1:8545

## 🔐 Wallet Setup

1. Install [MetaMask](https://metamask.io/)
2. Add Sepolia testnet:
   - Network Name: Sepolia
   - RPC URL: https://sepolia.infura.io/v3/YOUR_KEY
   - Chain ID: 11155111
   - Currency: ETH
3. Get test ETH from [Sepolia Faucet](https://sepoliafaucet.com/)

## 📊 Testing the System

### Create a Test Auction

1. Connect MetaMask to the web dashboard
2. Click "Create Auction"
3. Fill in lot details:
   - Lot ID: `LOT-001`
   - Variety: `Tellicherry`
   - Quantity: `100` kg
   - Start Price: `0.01` ETH
4. Upload certificate (any PDF/image)
5. Submit and wait for blockchain confirmation

### Place a Test Bid

1. Navigate to "Live Auctions"
2. Click on an active auction
3. Enter bid amount (must be higher than current bid)
4. Click "Place Bid"
5. Confirm transaction in MetaMask
6. Watch real-time updates!

## 🐛 Troubleshooting

### npm command not working (Windows)

**Error: "npm is not recognized" or "scripts is disabled"**

**Fix 1: PowerShell Execution Policy**

```powershell
# Run as Administrator or current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Fix 2: PATH not updated after Node.js install**

```powershell
# Temporary fix (current session only)
$env:Path += ";C:\Program Files\nodejs"

# Permanent fix: Close and reopen PowerShell
# Or restart your computer
```

**Fix 3: Verify Node.js installation**

```powershell
& "C:\Program Files\nodejs\node.exe" --version
```

### Backend won't start

```powershell
# Check PostgreSQL is running
pg_isready

# Check Redis is running
redis-cli ping

# Check port 3000 is free
netstat -ano | findstr :3000
```

### Web dashboard errors

```powershell
# Clear Next.js cache
cd web
rm -rf .next
npm run dev
```

### Blockchain deployment fails

```powershell
# Check you have test ETH
# Verify RPC URL is correct
# Ensure private key has 0x prefix
```

### WebSocket not connecting

- Check backend is running on port 3000
- Verify NEXT_PUBLIC_WS_URL in web/.env
- Check browser console for errors

## 📚 Next Steps

1. **Add Test Data:**

   - Create multiple lots
   - Set up farmer and buyer accounts
   - Run test auctions

2. **Explore Features:**

   - Real-time bidding
   - Compliance checking
   - Bid history
   - Wallet integration

3. **Customize:**
   - Modify smart contract parameters
   - Add custom compliance rules
   - Adjust UI theme

## 🎯 Current Capabilities (50% Implementation)

✅ Smart contract deployed  
✅ Real-time auction engine  
✅ WebSocket bidding  
✅ Web3 wallet integration  
✅ Compliance validation (basic)  
✅ Escrow management  
✅ Web dashboard

## 🔜 Coming Soon (Future Modules)

- Full traceability system
- QR/NFC integration
- Advanced compliance rules
- Mobile app (Flutter)
- Multi-chain support

## 💡 Tips

- Use Sepolia testnet for testing (free ETH)
- Keep MetaMask unlocked while bidding
- Check browser console for debugging
- Monitor backend logs for API issues

## 📞 Support

- Check logs in `backend/logs/`
- Review `DEPLOYMENT_ROADMAP.md` for architecture
- Open GitHub issues for bugs

---

🌶️ **Happy Testing!** Your SmartPepper blockchain auction system is ready!
