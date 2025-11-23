# Auction Creation Feature - User Guide

## Overview

The SmartPepper auction system now has a fully functional auction creation page that allows farmers to list their pepper lots for auction on the blockchain.

## Prerequisites

Before creating an auction, ensure you have:

1. **Running Services:**

   - ✅ Hardhat blockchain node running (Port 8545)
   - ✅ Backend API server running (Port 3002)
   - ✅ Frontend Next.js app running (Port 3001)
   - ✅ PostgreSQL database running (Port 5432)
   - ✅ Redis cache running (Port 6379)

2. **MetaMask Wallet:**
   - Install MetaMask browser extension
   - Import the test account with private key from `.env`:
     ```
     Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
     ```
   - Add local Hardhat network to MetaMask:
     - Network Name: Hardhat Local
     - RPC URL: http://127.0.0.1:8545
     - Chain ID: 31337
     - Currency Symbol: ETH

## How to Create an Auction

### Step 1: Navigate to Create Page

1. Open the web app at http://localhost:3001
2. Click "Create Auction" button in the header or home page
3. You'll be redirected to http://localhost:3001/create

### Step 2: Connect Wallet

1. Click "Connect MetaMask" button
2. MetaMask will prompt you to connect
3. Select your account and approve the connection
4. Your wallet address will be displayed

### Step 3: Fill Lot Details

The first form collects information about your pepper lot:

- **Lot ID** (Optional): Auto-generated if left empty (e.g., LOT123456789)
- **Pepper Variety** (Required): Type of pepper (e.g., "Kampot Black Pepper", "Tellicherry")
- **Quantity** (Required): Amount in kilograms (e.g., 1000)
- **Quality Grade** (Required):
  - A - Premium
  - B - High Quality
  - C - Standard
- **Harvest Date** (Required): Date when the peppers were harvested

Click **"Create Lot & Continue"** to register the lot on the blockchain.

### Step 4: Configure Auction Settings

After the lot is created, you'll configure the auction parameters:

- **Starting Price** (Required): Initial bid price in ETH (e.g., 0.1)
- **Reserve Price** (Required): Minimum acceptable price in ETH (e.g., 0.5)
  - Must be greater than or equal to starting price
- **Auction Duration** (Required): Choose from:
  - 1 Day
  - 3 Days
  - 7 Days
  - 14 Days
  - 30 Days

Review the summary and click **"Create Auction"** to start the auction.

### Step 5: Confirmation

Upon success:

- ✅ Lot registered on blockchain
- ✅ Auction created and saved to database
- ✅ Auction becomes visible on the auctions page
- 🔄 Automatically redirected to auctions list

## Technical Details

### Blockchain Transactions

The create auction process involves **2 blockchain transactions**:

1. **Create Lot Transaction:**

   ```solidity
   createLot(lotId, variety, quantity, quality, harvestDate, certificateHash)
   ```

   - Registers the pepper lot on the smart contract
   - Emits `LotCreated` event
   - Gas cost: ~150,000 gas

2. **Create Auction Transaction:**
   ```solidity
   createAuction(lotId, startPrice, reservePrice, duration)
   ```
   - Creates the auction for the registered lot
   - Emits `AuctionCreated` event
   - Gas cost: ~200,000 gas

### Backend API Calls

1. **POST /api/lots** - Saves lot data to PostgreSQL
2. **POST /api/auctions** - Saves auction data to PostgreSQL

### Data Flow

```
User Form → MetaMask (Sign TX) → Smart Contract → Blockchain Event
                ↓
         Backend API → PostgreSQL Database
                ↓
         WebSocket → Live Updates
```

## Common Issues & Solutions

### Issue: "Please install MetaMask"

**Solution:** Install MetaMask browser extension from https://metamask.io

### Issue: "Failed to connect wallet"

**Solution:**

- Check if MetaMask is unlocked
- Refresh the page and try again
- Make sure you're on the correct network

### Issue: "Insufficient funds"

**Solution:**

- Import the test account with 10,000 ETH
- Or request funds from a faucet

### Issue: "Transaction failed"

**Solution:**

- Check if Hardhat node is running
- Verify contract address in `.env.local`
- Check console logs for specific error

### Issue: "Lot already exists"

**Solution:**

- Use a different Lot ID
- Or leave Lot ID empty for auto-generation

### Issue: "Reserve price must be >= start price"

**Solution:**

- Make sure reserve price is equal to or higher than start price

### Issue: "Minimum auction duration is 5 minutes"

**Solution:**

- The smart contract enforces minimum 5 minutes (300 seconds)
- Use the preset durations in the dropdown

## Verification

After creating an auction, you can verify it was successful:

1. **Frontend:** Check auctions page at http://localhost:3001/auctions
2. **Backend API:**
   ```bash
   curl http://localhost:3002/api/auctions
   ```
3. **Database:**
   ```sql
   docker exec -it smartpepper-postgres psql -U postgres -d smartpepper
   SELECT * FROM auctions ORDER BY created_at DESC LIMIT 1;
   ```
4. **Blockchain:**
   - Check transaction hash on Hardhat console
   - Verify event was emitted

## Example Values

For testing, you can use these sample values:

**Lot Details:**

- Variety: Kampot Black Pepper
- Quantity: 500
- Quality: A
- Harvest Date: 2024-01-15

**Auction Settings:**

- Starting Price: 0.05
- Reserve Price: 0.1
- Duration: 3 Days

## Next Steps

After creating auctions, users can:

- Browse all auctions
- Place bids on active auctions
- Monitor auction status
- View bid history
- Settle completed auctions

## Support

For issues or questions:

1. Check browser console for errors
2. Check backend logs: `backend/logs/`
3. Check Hardhat node console for transaction details
4. Review PostgreSQL logs if database issues occur
