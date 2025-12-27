# Lot Approval Workflow - Quick Start Guide

## Overview

This system allows admin to review and approve/reject farmer-submitted pepper lots with images and certificates. The compliance status is tracked in the database and will be written to the blockchain.

## 🎯 What's Been Created

### 1. Backend API (New File)

**File**: `backend/src/routes/admin.js`

Four new endpoints:

- `GET /api/admin/lots/pending` - Get all pending lots
- `GET /api/admin/lots/:lotId` - Get lot details with images
- `PUT /api/admin/lots/:lotId/compliance` - Approve or reject
- `GET /api/admin/stats` - Dashboard statistics

### 2. Database Migration (New File)

**File**: `backend/add-lot-approval-columns.js`

Adds to `pepper_lots` table:

- `lot_pictures` (JSONB) - Array of IPFS image URLs
- `certificate_images` (JSONB) - Array of certificate image URLs
- `rejection_reason` (TEXT) - Why lot was rejected

Creates new `admin_actions` table for audit trail.

### 3. Server Configuration (Updated)

**File**: `backend/src/server.js`

- Added admin routes import
- Registered `/api/admin` endpoints

### 4. Documentation (New Files)

- `LOT_COMPLIANCE_APPROVAL_SYSTEM.md` - Complete technical documentation
- `LOT_APPROVAL_WORKFLOW_GUIDE.md` - This quick start guide
- `setup-lot-approval.ps1` - Automated setup script

## 🚀 Quick Setup (3 Steps)

### Step 1: Run Database Migration

```powershell
# Navigate to project root
cd "d:\Campus\Research\SmartPepper\SmartPepper-Auction-Blockchain-System"

# Run setup script
.\setup-lot-approval.ps1
```

Or manually:

```powershell
cd backend
node add-lot-approval-columns.js
```

This adds necessary database columns and tables.

### Step 2: Restart Backend Server

```powershell
# In your backend terminal (Ctrl+C to stop if running)
cd backend
npm start
```

The new admin endpoints are now available at:

- http://192.168.8.116:3002/api/admin/*

### Step 3: Test the API

Open browser or use curl:

**Get pending lots:**

```
http://192.168.8.116:3002/api/admin/lots/pending
```

**Get admin stats:**

```
http://192.168.8.116:3002/api/admin/stats
```

## 📱 Complete Workflow

### Farmer Side (Mobile App)

1. **Create Lot**

   - Fill in lot details (variety, quantity, quality, etc.)
   - Upload lot pictures to IPFS
   - Upload certificate images to IPFS
   - Submit lot → status becomes 'pending'

2. **View Status**
   - Check lot details screen
   - See compliance status: pending/approved/rejected
   - If rejected, see reason

### Admin Side (Web Dashboard)

1. **View Pending Lots**

   ```
   GET /api/admin/lots/pending
   ```

   Shows all lots waiting for review.

2. **Review Lot Details**

   ```
   GET /api/admin/lots/:lotId
   ```

   Returns:

   - Lot information
   - Farmer details
   - IPFS image URLs
   - Certificate URLs

3. **Approve Lot**

   ```
   PUT /api/admin/lots/:lotId/compliance
   {
     "status": "approved",
     "adminId": "admin-user-id",
     "adminName": "Admin Name"
   }
   ```

   Updates:

   - `compliance_status` → 'approved'
   - `status` → 'available'
   - `compliance_checked_at` → current time
   - Logs action in `admin_actions` table

4. **Reject Lot**
   ```
   PUT /api/admin/lots/:lotId/compliance
   {
     "status": "rejected",
     "reason": "Quality certificates are expired",
     "adminId": "admin-user-id",
     "adminName": "Admin Name"
   }
   ```
   Updates:
   - `compliance_status` → 'rejected'
   - `status` → 'rejected'
   - `rejection_reason` → reason text
   - `compliance_checked_at` → current time

## 🖼️ Viewing Images

### IPFS URL Formats

Images are stored as:

```
ipfs://QmXXXXXXXXXXXXXXXXXXXXXXXXX
```

### Converting to Gateway URL

In your web app:

```typescript
const IPFS_GATEWAY = "http://192.168.8.116:8080/ipfs";

function getIPFSUrl(ipfsUrl: string) {
  if (ipfsUrl.startsWith("ipfs://")) {
    return ipfsUrl.replace("ipfs://", `${IPFS_GATEWAY}/`);
  }
  return ipfsUrl;
}

// Usage
<img src={getIPFSUrl(lot.lot_pictures[0])} alt="Lot" />;
```

## 🔗 Blockchain Integration (Next Step)

The API returns `blockchainTxRequired: true` when a lot is approved/rejected.

### To Implement:

1. **Add Smart Contract Function**

   ```solidity
   function updateComplianceStatus(
       string memory lotId,
       bool approved,
       address adminAddress
   ) public onlyAdmin {
       passports[lotId].complianceApproved = approved;
       passports[lotId].complianceCheckedBy = adminAddress;
       passports[lotId].complianceCheckedAt = block.timestamp;
       emit ComplianceStatusUpdated(lotId, approved, adminAddress);
   }
   ```

2. **Add Backend Service Function**

   In `backend/src/services/blockchainService.js`:

   ```javascript
   async updateLotComplianceOnChain(lotId, approved, adminAddress) {
     const contract = this.getPepperPassportContract();
     const tx = await contract.updateComplianceStatus(
       lotId,
       approved,
       adminAddress
     );
     await tx.wait();
     return tx.hash;
   }
   ```

3. **Call from Admin Route**

   Update `backend/src/routes/admin.js` PUT endpoint:

   ```javascript
   // After database update
   const blockchainService = require("../services/blockchainService");
   const txHash = await blockchainService.updateLotComplianceOnChain(
     lotId,
     status === "approved",
     adminId
   );

   await db.query(
     "UPDATE pepper_lots SET blockchain_tx_hash = $1 WHERE lot_id = $2",
     [txHash, lotId]
   );
   ```

## 🖥️ Web Admin UI (To Create)

### Option 1: Enhance Existing Page

Update `web/src/app/dashboard/admin/lots/page.tsx`:

- Add modal to view lot details
- Display IPFS images
- Add Approve/Reject buttons

### Option 2: Create Detail Page (Recommended)

Create `web/src/app/dashboard/admin/lots/[lotId]/page.tsx`:

```tsx
"use client";

export default function LotDetailPage({ params }) {
  const [lot, setLot] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch(`/api/admin/lots/${params.lotId}`)
      .then((res) => res.json())
      .then((data) => setLot(data.lot));
  }, [params.lotId]);

  const handleApprove = async () => {
    await fetch(`/api/admin/lots/${params.lotId}/compliance`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        status: "approved",
        adminId: "current-admin-id",
        adminName: "Admin Name",
      }),
    });
    // Refresh lot data
  };

  const handleReject = async (reason) => {
    await fetch(`/api/admin/lots/${params.lotId}/compliance`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        status: "rejected",
        reason,
        adminId: "current-admin-id",
        adminName: "Admin Name",
      }),
    });
    // Refresh lot data
  };

  return (
    <div>
      {/* Display lot details */}
      {/* Image gallery for lot_pictures */}
      {/* Image gallery for certificate_images */}
      {/* Approve/Reject buttons */}
    </div>
  );
}
```

## 📊 Database Schema

### pepper_lots Table (Updated)

```sql
CREATE TABLE pepper_lots (
  -- Existing columns
  lot_id VARCHAR(50) PRIMARY KEY,
  farmer_id UUID,
  farmer_address VARCHAR(42),
  variety VARCHAR(100),
  quantity DECIMAL(10, 2),
  quality VARCHAR(50),
  harvest_date DATE,
  origin VARCHAR(255),
  farm_location TEXT,
  organic_certified BOOLEAN,

  -- New columns for images
  lot_pictures JSONB DEFAULT '[]',
  certificate_images JSONB DEFAULT '[]',

  -- Compliance tracking
  compliance_status VARCHAR(20) DEFAULT 'pending',
  compliance_checked_at TIMESTAMPTZ,
  rejection_reason TEXT,

  -- Status
  status VARCHAR(20) DEFAULT 'available',
  blockchain_tx_hash VARCHAR(66),

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### admin_actions Table (New)

```sql
CREATE TABLE admin_actions (
  id UUID PRIMARY KEY,
  admin_id VARCHAR(255) NOT NULL,
  action_type VARCHAR(50) NOT NULL,
  target_type VARCHAR(50) NOT NULL,
  target_id VARCHAR(255) NOT NULL,
  details JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

## 🧪 Testing

### Test Flow

1. **Create test lot as farmer**:

   ```sql
   INSERT INTO pepper_lots (
     lot_id, farmer_id, variety, quantity, quality,
     harvest_date, status, compliance_status,
     lot_pictures, certificate_images
   ) VALUES (
     'TEST-LOT-001',
     'farmer-uuid',
     'Black Pepper',
     500,
     'Premium',
     '2024-01-15',
     'pending',
     'pending',
     '["ipfs://QmTest1", "ipfs://QmTest2"]',
     '["ipfs://QmCert1"]'
   );
   ```

2. **Get pending lots**:

   ```bash
   curl http://192.168.8.116:3002/api/admin/lots/pending
   ```

3. **Approve lot**:

   ```bash
   curl -X PUT http://192.168.8.116:3002/api/admin/lots/TEST-LOT-001/compliance \
     -H "Content-Type: application/json" \
     -d '{
       "status": "approved",
       "adminId": "test-admin",
       "adminName": "Test Admin"
     }'
   ```

4. **Verify in database**:

   ```sql
   SELECT lot_id, compliance_status, status, compliance_checked_at
   FROM pepper_lots
   WHERE lot_id = 'TEST-LOT-001';

   SELECT * FROM admin_actions WHERE target_id = 'TEST-LOT-001';
   ```

## 📝 API Response Examples

### GET /api/admin/lots/pending

```json
{
  "success": true,
  "count": 3,
  "lots": [
    {
      "lot_id": "LOT-2024-001",
      "farmer_name": "John Farmer",
      "farmer_email": "john@example.com",
      "farmer_phone": "+94771234567",
      "farmer_address": "0x1234...5678",
      "variety": "Black Pepper",
      "quantity": 500,
      "quality": "Premium",
      "harvest_date": "2024-01-15",
      "origin": "Kandy, Sri Lanka",
      "farm_location": "Estate Road, Matale",
      "organic_certified": true,
      "lot_pictures": ["ipfs://QmXXXXXXXXXXXX", "ipfs://QmYYYYYYYYYYYY"],
      "certificate_images": ["ipfs://QmZZZZZZZZZZZZ"],
      "status": "pending",
      "compliance_status": "pending",
      "created_at": "2024-01-20T10:30:00Z"
    }
  ]
}
```

### PUT /api/admin/lots/:lotId/compliance (Success)

```json
{
  "success": true,
  "message": "Lot approved successfully",
  "lot": {
    "lot_id": "LOT-2024-001",
    "compliance_status": "approved",
    "status": "available",
    "compliance_checked_at": "2024-01-21T14:25:00Z"
  },
  "blockchainTxRequired": true
}
```

## 🔒 Security Notes

1. **Authentication**: Add JWT verification middleware
2. **Authorization**: Verify user has admin role
3. **Input Validation**: Validate status and reason fields
4. **Rate Limiting**: Prevent abuse of approval endpoints
5. **Audit Trail**: All actions logged in admin_actions table

## 🐛 Troubleshooting

### Migration Fails

**Error**: "Column already exists"

- The migration is idempotent, it's safe
- Columns already added from previous run

**Error**: "Connection refused"

- Check PostgreSQL is running
- Verify database credentials in `.env`

### Images Not Displaying

**Error**: "Failed to load image"

- Check IPFS daemon is running: `ipfs daemon`
- Verify IPFS gateway URL
- Check CORS settings

### API Returns 404

**Error**: "Cannot GET /api/admin/lots/pending"

- Restart backend server
- Check server.js includes admin routes
- Verify endpoint URL is correct

## 📚 Full Documentation

For complete technical details, see:

- `LOT_COMPLIANCE_APPROVAL_SYSTEM.md` - Full system documentation
- API reference
- Database schema
- Blockchain integration guide
- Security best practices

## ✅ Checklist

Before using the system:

- [ ] Database migration completed
- [ ] Backend server restarted
- [ ] Test API endpoints with curl/Postman
- [ ] IPFS daemon running
- [ ] Web admin UI updated (or created)
- [ ] Mobile app shows compliance status
- [ ] (Optional) Blockchain integration added

## 🎉 You're Ready!

The lot approval backend is complete. Now you can:

1. ✅ Farmers create lots via mobile app
2. ✅ Images stored on IPFS
3. ✅ Admin can fetch pending lots
4. ✅ Admin can approve/reject with API
5. ✅ Compliance status tracked in database
6. ✅ Actions logged for audit
7. ⏳ Next: Add web UI and blockchain integration

---

**Questions?** Check `LOT_COMPLIANCE_APPROVAL_SYSTEM.md` for detailed documentation.
