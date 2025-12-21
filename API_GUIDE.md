# SmartPepper API Guide

Complete API documentation for the SmartPepper Auction Blockchain System.

---

## 📚 Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Authentication](#authentication)
- [Base URL](#base-url)
- [Core Workflows](#core-workflows)
- [REST API Endpoints](#rest-api-endpoints)
- [WebSocket Events](#websocket-events)
- [Error Handling](#error-handling)
- [Rate Limits](#rate-limits)
- [Code Examples](#code-examples)

---

## Overview

The SmartPepper API provides programmatic access to:

- **Lot Registration**: Register pepper lots with full traceability
- **Compliance Validation**: Automated market-specific compliance checks
- **Auction Management**: Create and manage blockchain-based auctions
- **Real-Time Bidding**: WebSocket-based live auction updates
- **Certificate Storage**: IPFS-based immutable document storage

### Key Features

✅ **Blockchain-verified**: All transactions recorded on Ethereum  
✅ **Real-time updates**: WebSocket support for live auctions  
✅ **Regulatory compliance**: EU, FDA, Middle East market validators  
✅ **IPFS integration**: Decentralized certificate storage  
✅ **Full traceability**: End-to-end supply chain tracking

---

## Quick Start

### 1. Install Dependencies

```bash
# Node.js/JavaScript
npm install axios socket.io-client ethers

# Python
pip install requests python-socketio web3
```

### 2. Connect to API

```javascript
const axios = require("axios");

const api = axios.create({
  baseURL: "http://localhost:3002/api",
  headers: {
    "Content-Type": "application/json",
  },
});

// Example: Get all auctions
const response = await api.get("/auctions");
console.log(response.data.auctions);
```

### 3. Connect to WebSocket

```javascript
const io = require("socket.io-client");

const socket = io("http://localhost:3002/auction", {
  transports: ["websocket", "polling"],
});

socket.on("connect", () => {
  console.log("Connected to auction server");
  socket.emit("join_auction", {
    auctionId: 1,
    userAddress: "0x...",
  });
});

socket.on("new_bid", (bidData) => {
  console.log("New bid received:", bidData);
});
```

---

## Authentication

**Current**: Wallet address verification  
**Future**: JWT token-based authentication

### Wallet Address Header

```http
X-Wallet-Address: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
```

All requests should include the wallet address of the authenticated user.

---

## Base URL

| Environment     | URL                              |
| --------------- | -------------------------------- |
| **Development** | `http://localhost:3002/api`      |
| **Production**  | `https://api.smartpepper.io/api` |

---

## Core Workflows

### Workflow 1: Register & Sell Pepper Lot

```
1. Create User Profile
   POST /api/users

2. Register Pepper Lot
   POST /api/lots

3. Add Processing Stages
   POST /api/lots/{lotId}/processing
   (Repeat for: harvest, drying, grading, packaging, storage)

4. Upload Certificates
   POST /api/certifications
   (Upload: organic, fumigation, pesticide_test, etc.)

5. Run Compliance Check
   POST /api/compliance/check/{lotId}
   Body: { "destination": "EU" }

6. Create Auction (if compliance passed)
   POST /api/auctions

7. Monitor Auction (WebSocket)
   Connect to /auction namespace
   Listen for: new_bid, auction_ended
```

### Workflow 2: Bid on Auction

```
1. Get Auction Details
   GET /api/auctions/{auctionId}

2. Connect WebSocket
   io.connect('http://localhost:3002/auction')

3. Join Auction Room
   socket.emit('join_auction', { auctionId, userAddress })

4. Place Bid (via Smart Contract)
   Use Web3/Ethers to call placeBid() on contract

5. Record Bid in Backend
   POST /api/auctions/{auctionId}/bids
   Body: { bidderAddress, amount, txHash }

6. Receive Real-Time Updates
   socket.on('new_bid', (data) => ...)
```

---

## REST API Endpoints

### Lots

#### `GET /api/lots`

Get all pepper lots with pagination and filters.

**Query Parameters:**

- `status` (optional): `available`, `in_auction`, `sold`, `expired`
- `farmer` (optional): Farmer wallet address (0x...)
- `limit` (optional): Results per page (default: 50, max: 100)
- `offset` (optional): Pagination offset (default: 0)

**Example Request:**

```bash
curl http://localhost:3002/api/lots?status=available&limit=10
```

**Example Response:**

```json
{
  "success": true,
  "count": 42,
  "lots": [
    {
      "id": "uuid-123",
      "lot_id": "LOT-2025-KL-001",
      "farmer_address": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
      "variety": "Tellicherry",
      "quantity": 1000.5,
      "quality": "AAA",
      "harvest_date": "2025-01-15",
      "origin": "Kerala, India",
      "organic_certified": true,
      "status": "available",
      "created_at": "2025-01-20T10:30:00Z"
    }
  ]
}
```

---

#### `POST /api/lots`

Create a new pepper lot.

**Request Body:**

```json
{
  "lotId": "LOT-2025-KL-002",
  "farmerAddress": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
  "variety": "Tellicherry",
  "quantity": 1500.75,
  "quality": "AAA",
  "harvestDate": "2025-01-20",
  "origin": "Kerala, India",
  "farmLocation": "Wayanad District",
  "organicCertified": true
}
```

**Response:**

```json
{
  "success": true,
  "lot": {
    /* lot object */
  }
}
```

---

#### `GET /api/lots/{lotId}`

Get detailed information about a specific lot.

**Example:**

```bash
curl http://localhost:3002/api/lots/LOT-2025-KL-001
```

---

#### `POST /api/lots/{lotId}/processing`

Add a processing stage to the lot's traceability chain.

**Request Body:**

```json
{
  "stageType": "drying",
  "stageName": "Sun Drying - Day 3",
  "location": "Wayanad Processing Center",
  "timestamp": "2025-01-22T14:00:00Z",
  "operatorName": "Rajesh Kumar",
  "qualityMetrics": {
    "moisture": "12.0",
    "temperature": "35",
    "humidity": "65"
  },
  "notes": "Optimal drying conditions maintained"
}
```

**Stage Types:**

- `harvest`: Initial harvest data
- `drying`: Drying process with moisture tracking
- `grading`: Quality grading and sorting
- `packaging`: Packaging details (material, batch info)
- `storage`: Warehouse storage conditions

---

### Certifications

#### `POST /api/certifications`

Upload certificate metadata with IPFS document hash.

**Request Body:**

```json
{
  "lotId": "LOT-2025-KL-001",
  "certType": "organic",
  "certNumber": "ORG-2025-KL-001",
  "issuer": "Organic Lanka",
  "issueDate": "2025-01-10",
  "expiryDate": "2026-01-10",
  "documentHash": "0xabc123def456...",
  "ipfsUrl": "ipfs://QmX4x7abc123..."
}
```

**Certificate Types:**

- `organic`: EU organic certification
- `fumigation`: Fumigation treatment certificate
- `phytosanitary`: FDA phytosanitary certificate
- `quality`: Quality test certificate
- `export`: Export authorization
- `pesticide_test`: Pesticide residue lab test (NEW)
- `halal`: Halal certification for Middle East (NEW)
- `origin`: Certificate of origin for customs (NEW)

**Response:**

```json
{
  "success": true,
  "certification": {
    /* certificate object */
  }
}
```

---

#### `GET /api/lots/{lotId}/certifications`

Get all certificates for a specific lot.

**Example:**

```bash
curl http://localhost:3002/api/lots/LOT-2025-KL-001/certifications
```

---

### Compliance

#### `POST /api/compliance/check/{lotId}`

Run automated compliance validation for a specific market.

**Request Body:**

```json
{
  "destination": "EU"
}
```

**Supported Destinations:**

- `EU`: European Union market
- `FDA`: United States (FDA)
- `MIDDLE_EAST`: Middle East markets

**Response:**

```json
{
  "success": true,
  "complianceStatus": "passed",
  "results": [
    {
      "code": "EU_MOISTURE_LIMIT",
      "name": "EU Moisture Content Limit",
      "category": "quality",
      "severity": "major",
      "passed": true,
      "details": "Moisture 12.0% meets EU limit (≤12.5%)"
    },
    {
      "code": "EU_ORGANIC_CERT",
      "name": "EU Organic Certification",
      "category": "certification",
      "severity": "critical",
      "passed": true,
      "details": "Valid organic certificate found (ORG-2025-KL-001)"
    }
  ],
  "timestamp": "2025-01-23T10:00:00Z"
}
```

**EU Market Validators:**

- ✅ Organic certification (critical)
- ✅ Moisture ≤12.5% (major)
- ✅ Pesticide residue test (critical)
- ✅ EU packaging standards (major)
- ✅ Full traceability (major)

**FDA Market Validators:**

- ✅ Phytosanitary certificate (critical)
- ✅ Moisture ≤13.0% (major)
- ✅ FDA-approved packaging (critical)
- ✅ Pesticide MRL compliance (critical)

**Middle East Market Validators:**

- ✅ Quality grade AA/AAA/Premium (major)
- ✅ Moisture ≤11.0% (major - strictest!)
- ✅ Jute with liner packaging (minor)
- ✅ Certificate of origin (major)

---

### Auctions

#### `GET /api/auctions`

Get all auctions with filters.

**Query Parameters:**

- `status`: `created`, `active`, `ended`, `settled`, `failed_compliance`
- `farmer`: Farmer wallet address
- `limit`, `offset`: Pagination

**Example:**

```bash
curl http://localhost:3002/api/auctions?status=active
```

---

#### `POST /api/auctions`

Create a new auction.

**Request Body:**

```json
{
  "lotId": "LOT-2025-KL-001",
  "farmerAddress": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
  "startPrice": "0.01",
  "reservePrice": "0.015",
  "startTime": "2025-01-25T10:00:00Z",
  "endTime": "2025-01-25T18:00:00Z"
}
```

**Requirements:**

- Lot must pass compliance check
- Start time must be in future
- Reserve price ≥ start price

---

#### `GET /api/auctions/{auctionId}`

Get detailed auction information with bid history.

**Response:**

```json
{
  "success": true,
  "auction": {
    "auction_id": 1,
    "lot_id": "LOT-2025-KL-001",
    "current_bid": "1500000000000000",
    "current_bidder_address": "0x...",
    "start_time": "2025-01-25T10:00:00Z",
    "end_time": "2025-01-25T18:00:00Z",
    "status": "active",
    "bid_count": 5
  },
  "bids": [
    {
      "bidder_address": "0x...",
      "amount": "1500000000000000",
      "timestamp": "2025-01-25T12:30:00Z",
      "blockchain_tx_hash": "0xabc123..."
    }
  ]
}
```

---

#### `POST /api/auctions/{auctionId}/bids`

Record a bid in the database (after blockchain confirmation).

**⚠️ Important**: Actual bid placement happens via smart contract using Web3/Ethers. This endpoint only records the confirmed transaction.

**Request Body:**

```json
{
  "bidderAddress": "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
  "amount": "0.0125",
  "txHash": "0xabc123def456..."
}
```

**Workflow:**

```javascript
// 1. Place bid on blockchain
const tx = await auctionContract.placeBid(auctionId, { value: bidAmount });
await tx.wait();

// 2. Record in database
await api.post(`/auctions/${auctionId}/bids`, {
  bidderAddress: address,
  amount: ethers.utils.formatEther(bidAmount),
  txHash: tx.hash,
});
```

---

### Users

#### `GET /api/users/{address}`

Get user profile by wallet address.

**Example:**

```bash
curl http://localhost:3002/api/users/0x70997970C51812dc3A010C7d01b50e0d17dc79C8
```

---

#### `POST /api/users`

Create or update user profile.

**Request Body:**

```json
{
  "walletAddress": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
  "userType": "farmer",
  "name": "Rajesh Kumar",
  "email": "rajesh@example.com",
  "phone": "+91-9876543210",
  "location": {
    "country": "India",
    "state": "Kerala",
    "district": "Wayanad"
  }
}
```

**User Types:**

- `farmer`: Pepper farmer selling lots
- `buyer`: Direct buyer participating in auctions
- `exporter`: Export company purchasing lots
- `regulator`: Compliance/regulatory authority

---

## WebSocket Events

### Connection

```javascript
const socket = io("http://localhost:3002/auction", {
  transports: ["websocket", "polling"],
});

socket.on("connect", () => {
  console.log("Connected:", socket.id);
});
```

### Join Auction Room

**Emit:**

```javascript
socket.emit("join_auction", {
  auctionId: 1,
  userAddress: "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
});
```

**Response:**

```javascript
socket.on("auction_joined", (data) => {
  console.log(`Joined auction ${data.auctionId}`);
  console.log(`Current viewers: ${data.viewerCount}`);
});
```

---

### Listen for Events

#### `new_bid`

Fired when a new bid is placed.

```javascript
socket.on("new_bid", (bidData) => {
  console.log("New bid:", {
    bidder: bidData.bidder,
    amount: bidData.amount, // in wei
    timestamp: bidData.timestamp,
  });
});
```

**Data Structure:**

```json
{
  "auctionId": 1,
  "bidder": "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
  "amount": "1500000000000000",
  "timestamp": "2025-01-25T12:30:00Z"
}
```

---

#### `user_joined`

Fired when a user joins the auction room.

```javascript
socket.on("user_joined", (data) => {
  console.log(`User ${data.userAddress} joined`);
});
```

---

#### `user_left`

Fired when a user leaves the auction room.

```javascript
socket.on("user_left", (data) => {
  console.log(`User ${data.userAddress} left`);
});
```

---

#### `auction_ended`

Fired when the auction time expires.

```javascript
socket.on("auction_ended", (data) => {
  console.log("Auction ended:", {
    auctionId: data.auctionId,
    winner: data.winner,
    finalBid: data.finalBid,
  });
});
```

---

#### `error`

Fired on errors.

```javascript
socket.on("error", (error) => {
  console.error("WebSocket error:", error.message);
});
```

---

### Leave Auction Room

```javascript
socket.emit("leave_auction", { auctionId: 1 });
```

---

### Disconnect

```javascript
socket.disconnect();
```

---

## Error Handling

### HTTP Status Codes

| Code | Meaning      | Example                              |
| ---- | ------------ | ------------------------------------ |
| 200  | Success      | Request completed successfully       |
| 201  | Created      | Resource created (lot, auction, bid) |
| 400  | Bad Request  | Invalid parameters or missing fields |
| 404  | Not Found    | Resource doesn't exist               |
| 500  | Server Error | Internal server error                |

### Error Response Format

```json
{
  "success": false,
  "error": "Detailed error message here"
}
```

### Common Error Scenarios

**Invalid Lot ID:**

```json
{
  "success": false,
  "error": "Lot LOT-2025-XYZ-999 not found"
}
```

**Compliance Check Failed:**

```json
{
  "success": false,
  "error": "Lot failed EU compliance: Missing organic certification"
}
```

**Bid Too Low:**

```json
{
  "success": false,
  "error": "Bid amount must be greater than current bid"
}
```

---

## Rate Limits

| Endpoint Type             | Limit                      |
| ------------------------- | -------------------------- |
| **General API**           | 100 requests/minute        |
| **Bid Placement**         | 10 bids/minute per address |
| **WebSocket Connections** | 5 concurrent per IP        |

**Rate Limit Headers:**

```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1643040000
```

**Rate Limit Exceeded:**

```json
{
  "success": false,
  "error": "Rate limit exceeded. Try again in 45 seconds."
}
```

---

## Code Examples

### Example 1: Complete Lot Registration (Node.js)

```javascript
const axios = require("axios");
const FormData = require("form-data");
const { uploadToIPFS, generateDocumentHash } = require("./ipfs-service");

const api = axios.create({
  baseURL: "http://localhost:3002/api",
});

async function registerPepperLot() {
  // 1. Create lot
  const lot = await api.post("/lots", {
    lotId: "LOT-2025-KL-003",
    farmerAddress: "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
    variety: "Tellicherry",
    quantity: 2000,
    quality: "AAA",
    harvestDate: "2025-01-20",
    origin: "Kerala, India",
    organicCertified: true,
  });

  const lotId = lot.data.lot.lot_id;
  console.log("✅ Lot created:", lotId);

  // 2. Add processing stages
  const stages = [
    {
      stageType: "harvest",
      stageName: "Initial Harvest",
      location: "Wayanad Farm A-12",
      timestamp: "2025-01-20T06:00:00Z",
      qualityMetrics: { grade: "AAA", size: "large" },
    },
    {
      stageType: "drying",
      stageName: "Sun Drying - Day 5",
      location: "Processing Center 1",
      timestamp: "2025-01-25T14:00:00Z",
      qualityMetrics: { moisture: "12.0", temperature: "35" },
    },
    {
      stageType: "packaging",
      stageName: "Final Packaging",
      location: "Warehouse B",
      timestamp: "2025-01-26T10:00:00Z",
      qualityMetrics: { package_material: "HDPE", batch_number: "B2025-001" },
    },
  ];

  for (const stage of stages) {
    await api.post(`/lots/${lotId}/processing`, stage);
  }
  console.log("✅ Processing stages added");

  // 3. Upload certificate to IPFS
  const certFile = fs.readFileSync("./organic-cert.pdf");
  const { cid, ipfsUrl, gatewayUrl } = await uploadToIPFS(certFile);
  const docHash = await generateDocumentHash(certFile);

  // 4. Add certificate to database
  await api.post("/certifications", {
    lotId: lotId,
    certType: "organic",
    certNumber: "ORG-2025-KL-003",
    issuer: "Organic Lanka",
    issueDate: "2025-01-10",
    expiryDate: "2026-01-10",
    documentHash: docHash,
    ipfsUrl: ipfsUrl,
  });
  console.log("✅ Certificate uploaded:", gatewayUrl);

  // 5. Run compliance check
  const compliance = await api.post(`/compliance/check/${lotId}`, {
    destination: "EU",
  });

  console.log("✅ Compliance result:", compliance.data.complianceStatus);

  if (compliance.data.complianceStatus === "passed") {
    // 6. Create auction
    const auction = await api.post("/auctions", {
      lotId: lotId,
      farmerAddress: "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
      startPrice: "0.01",
      reservePrice: "0.015",
      startTime: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
      endTime: new Date(Date.now() + 25 * 60 * 60 * 1000).toISOString(),
    });

    console.log("✅ Auction created:", auction.data.auction.auction_id);
  }
}

registerPepperLot().catch(console.error);
```

---

### Example 2: Real-Time Auction Monitoring (React)

```jsx
import React, { useState, useEffect } from "react";
import io from "socket.io-client";
import axios from "axios";

function AuctionMonitor({ auctionId, userAddress }) {
  const [socket, setSocket] = useState(null);
  const [auction, setAuction] = useState(null);
  const [bids, setBids] = useState([]);
  const [viewers, setViewers] = useState(0);
  const [connected, setConnected] = useState(false);

  useEffect(() => {
    // Fetch initial auction data
    axios.get(`http://localhost:3002/api/auctions/${auctionId}`).then((res) => {
      setAuction(res.data.auction);
      setBids(res.data.bids);
    });

    // Connect WebSocket
    const newSocket = io("http://localhost:3002/auction", {
      transports: ["websocket", "polling"],
    });

    newSocket.on("connect", () => {
      setConnected(true);
      newSocket.emit("join_auction", { auctionId, userAddress });
    });

    newSocket.on("auction_joined", (data) => {
      setViewers(data.viewerCount);
    });

    newSocket.on("new_bid", (bidData) => {
      // Update auction state
      setAuction((prev) => ({
        ...prev,
        current_bid: bidData.amount,
        current_bidder_address: bidData.bidder,
        bid_count: prev.bid_count + 1,
      }));

      // Add to bid history
      setBids((prev) => [
        {
          bidder_address: bidData.bidder,
          amount: bidData.amount,
          timestamp: bidData.timestamp,
        },
        ...prev,
      ]);
    });

    newSocket.on("user_joined", () => setViewers((prev) => prev + 1));
    newSocket.on("user_left", () => setViewers((prev) => prev - 1));

    newSocket.on("auction_ended", (data) => {
      setAuction((prev) => ({ ...prev, status: "ended" }));
      alert(`Auction ended! Winner: ${data.winner}`);
    });

    setSocket(newSocket);

    return () => {
      newSocket.disconnect();
    };
  }, [auctionId, userAddress]);

  return (
    <div className="auction-monitor">
      <div className="status-bar">
        {connected && <span className="badge green">🟢 Live</span>}
        <span>{viewers} viewers</span>
      </div>

      {auction && (
        <div className="auction-details">
          <h2>Lot: {auction.lot_id}</h2>
          <p>
            Current Bid: {(parseFloat(auction.current_bid) / 1e18).toFixed(4)}{" "}
            ETH
          </p>
          <p>Total Bids: {auction.bid_count}</p>
          <p>Status: {auction.status}</p>
        </div>
      )}

      <div className="bid-history">
        <h3>Live Bid History</h3>
        {bids.map((bid, idx) => (
          <div key={idx} className="bid-item">
            <span>{bid.bidder_address.slice(0, 8)}...</span>
            <span>{(parseFloat(bid.amount) / 1e18).toFixed(4)} ETH</span>
            <span>{new Date(bid.timestamp).toLocaleTimeString()}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

export default AuctionMonitor;
```

---

### Example 3: Place Bid (with Smart Contract)

```javascript
import { ethers } from "ethers";
import axios from "axios";
import auctionABI from "./contracts/PepperAuction.json";

async function placeBid(auctionId, bidAmount) {
  // 1. Connect to blockchain
  const provider = new ethers.providers.Web3Provider(window.ethereum);
  await provider.send("eth_requestAccounts", []);
  const signer = provider.getSigner();
  const address = await signer.getAddress();

  // 2. Get contract instance
  const contractAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
  const contract = new ethers.Contract(contractAddress, auctionABI.abi, signer);

  try {
    // 3. Place bid on blockchain
    const tx = await contract.placeBid(auctionId, {
      value: ethers.utils.parseEther(bidAmount),
    });

    console.log("Transaction sent:", tx.hash);
    await tx.wait();
    console.log("✅ Bid confirmed on blockchain");

    // 4. Record bid in database
    await axios.post(`http://localhost:3002/api/auctions/${auctionId}/bids`, {
      bidderAddress: address,
      amount: bidAmount,
      txHash: tx.hash,
    });

    console.log("✅ Bid recorded in database");
    return { success: true, txHash: tx.hash };
  } catch (error) {
    console.error("❌ Bid failed:", error.message);
    return { success: false, error: error.message };
  }
}

// Usage
placeBid(1, "0.0125").then((result) => console.log("Bid result:", result));
```

---

### Example 4: Compliance Check with Details (Python)

```python
import requests

api_url = "http://localhost:3002/api"

def check_compliance(lot_id, destination):
    """
    Run compliance check for a specific lot and market.

    Args:
        lot_id: Lot identifier (e.g., "LOT-2025-KL-001")
        destination: Target market ("EU", "FDA", "MIDDLE_EAST")

    Returns:
        dict: Compliance result with details
    """
    response = requests.post(
        f"{api_url}/compliance/check/{lot_id}",
        json={"destination": destination}
    )

    result = response.json()

    print(f"Compliance Status: {result['complianceStatus'].upper()}")
    print(f"\nValidation Results:")
    print("-" * 60)

    for check in result['results']:
        status_icon = "✅" if check['passed'] else "❌"
        print(f"{status_icon} {check['name']} ({check['severity']})")
        print(f"   {check['details']}\n")

    return result

# Example usage
result = check_compliance("LOT-2025-KL-001", "EU")

if result['complianceStatus'] == 'passed':
    print("✅ Lot is ready for auction!")
else:
    print("❌ Lot failed compliance. Fix issues before creating auction.")
```

---

## OpenAPI Specification

Full OpenAPI 3.0 specification available at:

📄 **[API_DOCUMENTATION.yaml](./API_DOCUMENTATION.yaml)**

Use with tools like:

- **Swagger UI**: Visual API documentation
- **Postman**: Import spec for testing
- **OpenAPI Generator**: Generate client SDKs

---

## Support & Resources

- **API Documentation**: `API_DOCUMENTATION.yaml`
- **Quick Start Guide**: `QUICK_START.md`
- **IPFS Integration**: `IPFS_INTEGRATION_GUIDE.md`
- **WebSocket Guide**: `PRIORITY_4_WEBSOCKET_COMPLETE.md`
- **Compliance Rules**: `COMPLIANCE_RULES_DOCUMENTATION.md`

---

## Performance Metrics

| Metric                | Target  | Achieved  |
| --------------------- | ------- | --------- |
| **WebSocket Latency** | <300ms  | 150ms avg |
| **Compliance Check**  | <2000ms | 300-500ms |
| **API Response Time** | <500ms  | 200ms avg |

Performance validated via:

- `backend/test/performance/auction-latency.test.js`
- `backend/test/performance/compliance-timing.test.js`

---

## Security Best Practices

1. **Never expose private keys**: Use environment variables
2. **Validate all inputs**: Prevent SQL injection
3. **Rate limiting**: Prevent abuse
4. **HTTPS in production**: Encrypt all traffic
5. **IPFS pinning**: Ensure document availability
6. **Smart contract audits**: Security review before mainnet

---

**Built with ❤️ for the SmartPepper Research Project**

For questions or issues, contact the development team.
