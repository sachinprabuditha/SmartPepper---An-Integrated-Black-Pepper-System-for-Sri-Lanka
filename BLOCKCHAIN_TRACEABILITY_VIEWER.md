# 🔍 Blockchain Traceability Viewer Guide

## Overview

The SmartPepper system now has a **comprehensive blockchain traceability viewer** that shows complete records for every pepper lot including:

- ✅ Complete timeline of all events
- ✅ Processing stages (harvest, drying, grading, packaging)
- ✅ Certifications (organic, quality, export)
- ✅ Compliance checks (EU, FDA, Middle East)
- ✅ Auction history and bid records
- ✅ Blockchain transaction hashes
- ✅ Ownership transfers
- ✅ Statistics and analytics

---

## 🚀 Where to View Full Blockchain Traceability

### 1. Mobile App (Flutter) - Full Traceability Screen

**Location**: `mobile/lib/screens/shared/traceability_screen.dart`

**How to Access**:

1. Open lot details from any lot card
2. Tap on "View Traceability" button
3. Full traceability screen opens with 5 tabs:
   - **Timeline**: Complete chronological history
   - **Processing**: All processing stages
   - **Certificates**: All certifications
   - **Compliance**: Compliance check results
   - **Blockchain**: NFT passport & blockchain info

**Features**:

- 📊 Statistics card showing total events, blockchain transactions, days in system
- 🔗 Clickable transaction hashes (copy to clipboard)
- ✅ Visual indicators for blockchain-verified events
- 📅 Relative timestamps (e.g., "2 hours ago")
- 🎨 Color-coded event types with icons
- 📋 Copy any blockchain hash with one tap

**API Endpoint Used**: `GET /api/traceability/{lotId}`

---

### 2. Admin Web Dashboard (Next.js) - Full Traceability Page

**Location**: `web/src/app/traceability/[lotId]/page.tsx`

**How to Access**:

```
http://localhost:3000/traceability/LOT-2025-001
```

Or from admin lot review page:

1. Go to lot details
2. Click "View Full Traceability" button
3. Opens comprehensive traceability page

**Features**:

- 🎯 **5 Interactive Tabs**:

  1. **Timeline**: Reverse chronological view with event icons
  2. **Processing**: Grid view of all processing stages
  3. **Certificates**: Certificate cards with verification status
  4. **Compliance**: Compliance check results with pass/fail stats
  5. **Blockchain**: Complete blockchain information

- 📥 **Export Functionality**: Download complete JSON export
- 📊 **Statistics Header**: 4 key metrics displayed prominently
- 🔄 **Real-time Updates**: Refresh button to reload data
- 📱 **Responsive Design**: Works on desktop, tablet, mobile

**URL Pattern**: `/traceability/{lotId}`

---

### 3. Backend API - Complete Traceability Endpoint

**Location**: `backend/src/routes/traceability.js`

**Endpoint**: `GET /api/traceability/:lotId`

**Example Request**:

```bash
curl http://192.168.8.116:3002/api/traceability/LOT-2025-001
```

**What It Returns**:

```json
{
  "success": true,
  "lot_id": "LOT-2025-001",

  "lot_info": {
    "lot_id": "LOT-2025-001",
    "variety": "Kurunegala White",
    "quantity": "500",
    "quality": "Grade A",
    "harvest_date": "2025-01-15",
    "origin": "Kandy, Sri Lanka",
    "status": "in_auction"
  },

  "blockchain_info": {
    "primary_tx_hash": "0xabc123...",
    "total_transactions": 8,
    "certificate_hash": "0xdef456...",
    "metadata_uri": "ipfs://Qm..."
  },

  "current_status": {
    "stage": "in_auction",
    "description": "Lot is currently in an active auction",
    "current_owner": "0x70997970...",
    "current_owner_name": "Farmer John",
    "compliance_status": "passed",
    "is_in_auction": true
  },

  "stakeholders": {
    "farmer": { "wallet_address": "0x...", "name": "John Doe" },
    "buyer": null,
    "certifiers": ["Organic Board", "Quality Institute"],
    "operators": ["Processing Plant A"]
  },

  "processing_stages": [
    {
      "stage_type": "harvest",
      "stage_name": "Harvest",
      "location": "Farm A, Kandy",
      "operator_name": "John Doe",
      "timestamp": "2025-01-15T08:00:00Z",
      "blockchain_tx_hash": "0x123..."
    }
    // ... more stages
  ],

  "certifications": [
    {
      "cert_type": "Organic",
      "cert_number": "ORG-2025-001",
      "issued_by": "Sri Lanka Organic Board",
      "issue_date": "2025-01-10",
      "expiry_date": "2026-01-10",
      "verified": true,
      "verified_by": "Admin",
      "ipfs_hash": "Qm..."
    }
  ],

  "compliance_checks": [
    {
      "destination_market": "EU",
      "total_checks": 17,
      "checks_passed": 17,
      "checks_failed": 0,
      "overall_status": "passed",
      "checked_at": "2025-01-16T10:00:00Z",
      "blockchain_tx_hash": "0x456..."
    }
  ],

  "auctions": [
    {
      "auction_id": 1,
      "start_price": "50000",
      "current_bid": "75000",
      "status": "active",
      "compliance_passed": true,
      "blockchain_tx_hash": "0x789..."
    }
  ],

  "bids": [
    {
      "auction_id": 1,
      "bidder_address": "0xabc...",
      "amount": "75000",
      "timestamp": "2025-01-17T14:30:00Z",
      "blockchain_tx_hash": "0xdef..."
    }
  ],

  "timeline": [
    {
      "type": "lot_created",
      "timestamp": "2025-01-15T08:00:00Z",
      "description": "Lot registered on blockchain",
      "actor": "0x70997970...",
      "actor_name": "Farmer John",
      "blockchain_tx": "0xabc123...",
      "data": {
        "variety": "Kurunegala White",
        "quantity": "500",
        "harvest_date": "2025-01-15"
      }
    }
    // ... complete chronological timeline
  ],

  "statistics": {
    "total_events": 24,
    "processing_stages": 4,
    "certifications": 2,
    "compliance_checks": 3,
    "auctions": 1,
    "total_bids": 8,
    "blockchain_transactions": 12,
    "days_in_system": 3
  }
}
```

---

## 📊 Data Sources

The traceability API aggregates data from multiple database tables:

1. **`pepper_lots`** - Basic lot information
2. **`processing_stages`** - Harvest, drying, grading, packaging stages
3. **`certifications`** - Organic, quality, export certificates
4. **`compliance_checks`** - Compliance validation results
5. **`auctions`** - Auction creation and status
6. **`bids`** - All bid records
7. **`users`** - Farmer and buyer information

---

## 🔗 Integration Points

### From Lot Details (Mobile)

```dart
// Navigate to traceability screen
context.push('/traceability/${lot.lotId}');
```

### From Admin Dashboard (Web)

```typescript
// Navigate to traceability page
router.push(`/traceability/${lotId}`);
```

### Direct API Call

```javascript
const response = await fetch(
  `http://192.168.8.116:3002/api/traceability/${lotId}`
);
const data = await response.json();
```

---

## 🎯 Use Cases

### For Farmers:

- ✅ Track their lot's complete journey
- ✅ Verify blockchain transactions
- ✅ See processing stage history
- ✅ Monitor compliance status
- ✅ View auction activity

### For Admins:

- ✅ Complete audit trail for compliance
- ✅ Export data for reports
- ✅ Verify all blockchain transactions
- ✅ Monitor lot lifecycle
- ✅ Stakeholder management

### For Buyers/Exporters:

- ✅ Full transparency of lot history
- ✅ Verify certifications
- ✅ Check compliance for destination market
- ✅ Track provenance
- ✅ Export records for customs

---

## 🚦 Testing the Traceability Viewer

### 1. Start Backend

```bash
cd backend
npm run dev
```

### 2. Test API Endpoint

```bash
curl http://192.168.8.116:3002/api/traceability/LOT-2025-001 | jq
```

### 3. Open Mobile App

```bash
cd mobile
flutter run
```

- Login as farmer
- Go to "My Lots"
- Select any lot
- Tap "View Traceability"

### 4. Open Web Dashboard

```bash
cd web
npm run dev
```

- Navigate to `http://localhost:3000/traceability/LOT-2025-001`
- Or click "View Full Traceability" from lot details page

---

## 📈 Timeline Event Types

| Event Type            | Icon | Color  | Description                         |
| --------------------- | ---- | ------ | ----------------------------------- |
| `lot_created`         | ➕   | Green  | Lot registered on blockchain        |
| `processing_stage`    | ⚙️   | Blue   | Harvest, drying, grading, packaging |
| `certification_added` | 🏆   | Gold   | Certificate issued                  |
| `compliance_check`    | ✅   | Purple | Compliance validation               |
| `auction_created`     | 🔨   | Pink   | Auction started                     |
| `bid_placed`          | 📈   | Orange | New bid recorded                    |
| `auction_ended`       | ⏱️   | Gray   | Auction closed                      |
| `auction_settled`     | 🤝   | Green  | Ownership transferred               |

---

## 🔐 Blockchain Verification

**Every blockchain-verified event shows**:

- ✅ Green checkmark icon
- 🔗 Full transaction hash (clickable/copyable)
- 📅 Exact timestamp
- 👤 Actor who performed the action

**To verify on blockchain**:

1. Copy transaction hash
2. Use Hardhat console or block explorer
3. Query transaction: `await ethers.provider.getTransaction("0x...")`

---

## 📥 Export Functionality

### Web Dashboard

- Click "Export JSON" button in header
- Downloads `traceability-{lotId}.json`
- Contains complete dataset

### API Endpoint

```bash
curl http://192.168.8.116:3002/api/traceability/LOT-2025-001/export \
  -o traceability.json
```

---

## 🎨 UI Features

### Mobile App

- **Tab Navigation**: 5 tabs with icons
- **Pull to Refresh**: Swipe down to reload
- **Copy Functionality**: Long-press any hash
- **Relative Timestamps**: "2 hours ago", "3 days ago"
- **Visual Timeline**: Vertical timeline with connecting lines
- **Statistics Card**: Prominent metrics display

### Web Dashboard

- **Gradient Header**: Eye-catching with statistics
- **Tab Navigation**: Horizontal tabs with icons
- **Export Button**: One-click JSON download
- **Responsive Design**: Mobile-friendly
- **Hover Effects**: Interactive elements
- **Copy Buttons**: Click to copy any hash
- **Color-Coded Cards**: Different colors for event types

---

## 🔄 Real-Time Updates

The traceability data is **live** and updates when:

- ✅ New processing stage added
- ✅ Certification uploaded
- ✅ Compliance check completed
- ✅ Auction created or bid placed
- ✅ Ownership transferred

Simply refresh the page or pull down to reload.

---

## 📋 Compliance with Research Requirements

### ✅ Farmer Side (100%)

- Farmer identity (wallet address)
- Lot creation birth record
- Harvest/processing events
- Certification submission
- Auction listing approval

### ✅ Admin Side (80%)

- Compliance approval/rejection
- Transaction hash tracking
- Rule enforcement validation
- Certificate verification
- Audit trail

### ✅ Buyer/Exporter Side (85%)

- Auction participation
- Escrow deposits
- Ownership transfer
- Shipment tracking (partial)
- Delivery confirmation (partial)

---

## 🎯 Quick Access URLs

### Mobile Routes

```dart
'/traceability/:lotId'  // Full traceability screen
```

### Web Routes

```
/traceability/:lotId           // Full traceability page
/dashboard/admin/lots/:lotId   // Admin lot review (has traceability link)
/dashboard/farmer/lots         // Farmer lots (has traceability access)
```

### API Endpoints

```
GET  /api/traceability/:lotId         // Complete records
GET  /api/traceability/:lotId/export  // JSON export
```

---

## 🎓 For Research Documentation

**This traceability system demonstrates**:

1. ✅ Complete blockchain transparency
2. ✅ Immutable audit trail
3. ✅ Multi-stakeholder visibility
4. ✅ Compliance automation
5. ✅ Real-time tracking
6. ✅ Export capabilities for analysis

**Research Evidence**:

- 📊 Timeline shows every state change
- 🔗 Every blockchain transaction is visible
- 👥 All actors are recorded
- 📅 Timestamps prove chronology
- ✅ Verification status is clear

---

## 📞 Support

If you need to view traceability for a specific lot:

**Mobile**: Tap lot → View Traceability
**Web**: Visit `/traceability/{lotId}`
**API**: `curl http://192.168.8.116:3002/api/traceability/{lotId}`

---

## 🎉 Summary

You can now watch **full blockchain traceability** in **3 places**:

1. **📱 Mobile App** - Complete 5-tab interface with statistics
2. **💻 Web Dashboard** - Comprehensive page with export functionality
3. **🔌 API Endpoint** - Raw JSON data for integration

All three show the **same complete dataset** with:

- Timeline of all events
- Processing stages
- Certifications
- Compliance checks
- Blockchain transactions
- Statistics
- Stakeholder information

**Every blockchain-verified event is marked with ✅ and shows the transaction hash!**
