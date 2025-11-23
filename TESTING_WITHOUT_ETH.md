# 🚀 Testing SmartPepper Without Real ETH

## Option 1: Local Hardhat Network (Recommended) ✅

### Step 1: Start Local Blockchain

Open a terminal in the `blockchain` folder and run:

```powershell
cd blockchain
npx hardhat node
```

This will:

- ✅ Start a local Ethereum network on http://localhost:8545
- ✅ Give you 20 accounts with **10,000 ETH each (FREE!)**
- ✅ Show private keys you can import to MetaMask

### Step 2: Deploy Contract to Local Network

Open another terminal:

```powershell
cd blockchain
npx hardhat run scripts/deploy.js --network localhost
```

Copy the deployed contract address and update `web/src/config/contracts.ts`

### Step 3: Connect MetaMask to Local Network

1. Open MetaMask
2. Click network dropdown (top left)
3. Click "Add Network" → "Add a network manually"
4. Enter these details:
   - **Network Name**: Hardhat Local
   - **RPC URL**: http://127.0.0.1:8545
   - **Chain ID**: 1337
   - **Currency Symbol**: ETH
5. Click "Save"

### Step 4: Import Test Account to MetaMask

From the Hardhat node terminal output, copy one of the private keys (NOT Account #0, use #1 or #2):

1. MetaMask → Click account icon → "Import Account"
2. Paste the private key
3. You'll have 10,000 ETH! 💰

### Step 5: Start Testing!

Now you can:

- ✅ Create auctions (costs ~0.001 ETH gas)
- ✅ Place bids (costs ~0.0005 ETH gas)
- ✅ Test all blockchain features for FREE

---

## Option 2: Use Sepolia Testnet (Get Free Test ETH from Faucets)

### Get Free Sepolia ETH:

**Faucet Sites:**

1. **Alchemy Faucet**: https://sepoliafaucet.com/
2. **Infura Faucet**: https://www.infura.io/faucet/sepolia
3. **Chainlink Faucet**: https://faucets.chain.link/sepolia

**How to use:**

1. Copy your MetaMask wallet address
2. Visit one of the faucet sites
3. Paste your address
4. Get 0.5 - 1 ETH (takes 1-5 minutes)

### Connect MetaMask to Sepolia:

- MetaMask → Networks → Show test networks (Settings)
- Select "Sepolia" from dropdown

### Deploy to Sepolia:

```powershell
cd blockchain
npx hardhat run scripts/deploy.js --network sepolia
```

**Note**: You'll need to add your private key to `.env` file:

```
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
PRIVATE_KEY=your_metamask_private_key
```

---

## Option 3: Mock Mode (No Blockchain Required)

If you want to test without blockchain at all, you can:

1. Disable blockchain calls in the frontend
2. Use only the backend API for testing
3. Mock transaction responses

Let me know which option you want and I'll help you set it up!

---

## 🎯 Recommendation

**For Development**: Use **Option 1 (Hardhat Local)** - It's:

- ✅ Completely free
- ✅ Fast (instant transactions)
- ✅ No internet required
- ✅ Unlimited ETH
- ✅ Perfect for testing

**For Demo/Production**: Use **Option 2 (Sepolia Testnet)** - It's:

- ✅ Real network conditions
- ✅ Shareable with others
- ✅ Free test ETH from faucets
- ✅ Good for final testing before mainnet

---

## Quick Start (Hardhat Local)

```powershell
# Terminal 1: Start blockchain
cd D:\Campus\Research\SmartPepper\SmartPepper-Auction-Blockchain-System\blockchain
npx hardhat node

# Terminal 2: Deploy contract
cd D:\Campus\Research\SmartPepper\SmartPepper-Auction-Blockchain-System\blockchain
npx hardhat run scripts/deploy.js --network localhost

# Terminal 3: Start backend
cd D:\Campus\Research\SmartPepper\SmartPepper-Auction-Blockchain-System\backend
npm start

# Terminal 4: Start web
cd D:\Campus\Research\SmartPepper\SmartPepper-Auction-Blockchain-System\web
npm run dev
```

Then import a Hardhat account to MetaMask and start testing! 🎉
