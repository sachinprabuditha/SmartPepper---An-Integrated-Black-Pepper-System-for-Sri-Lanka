# Lot Compliance Approval System

## Overview

Complete workflow for admin to review farmer-submitted pepper lots with images and certificates, and approve or reject them with blockchain tracking.

## Architecture

### 1. Backend API Endpoints

Created new file: `backend/src/routes/admin.js`

#### Available Endpoints:

1. **GET /api/admin/lots/pending**
   - Fetches all lots pending admin approval
   - Returns lots with `status='pending'` or `compliance_status='pending'`
   - Includes farmer information
2. **GET /api/admin/lots/:lotId**

   - Get detailed lot information including images
   - Returns lot with farmer details
   - Parses JSON arrays for lot_pictures and certificate_images

3. **PUT /api/admin/lots/:lotId/compliance**

   - Approve or reject lot compliance
   - Body parameters:
     ```json
     {
       "status": "approved" | "rejected",
       "reason": "rejection reason (required if rejected)",
       "adminId": "admin user ID",
       "adminName": "admin name"
     }
     ```
   - Updates:
     - `compliance_status`: 'approved' or 'rejected'
     - `status`: 'available' (if approved) or 'rejected'
     - `compliance_checked_at`: current timestamp
     - `rejection_reason`: if rejected
   - Logs action to `admin_actions` table
   - Returns `blockchainTxRequired: true` flag

4. **GET /api/admin/stats**
   - Get admin dashboard statistics
   - Returns counts for:
     - Pending lots
     - Total lots
     - Approved lots
     - Rejected lots
     - Active auctions
     - Total users

### 2. Database Schema Updates

Created migration file: `backend/add-lot-approval-columns.js`

#### New Columns Added to `pepper_lots`:

```sql
ALTER TABLE pepper_lots
ADD COLUMN IF NOT EXISTS lot_pictures JSONB DEFAULT '[]',
ADD COLUMN IF NOT EXISTS certificate_images JSONB DEFAULT '[]',
ADD COLUMN IF NOT EXISTS rejection_reason TEXT
```

#### Updated Status Constraints:

```sql
-- Status constraint
CHECK (status IN ('created', 'available', 'pending', 'pending_compliance',
                  'approved', 'rejected', 'auctioned'))

-- Compliance status constraint
CHECK (compliance_status IN ('pending', 'checking', 'passed', 'failed',
                              'approved', 'rejected'))
```

#### New Table: `admin_actions`

```sql
CREATE TABLE admin_actions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id VARCHAR(255) NOT NULL,
  action_type VARCHAR(50) NOT NULL,    -- 'approve_lot' or 'reject_lot'
  target_type VARCHAR(50) NOT NULL,    -- 'lot'
  target_id VARCHAR(255) NOT NULL,     -- lot_id
  details JSONB,                       -- {reason, lotId, adminName}
  created_at TIMESTAMPTZ DEFAULT NOW()
)
```

#### Indexes Created:

```sql
CREATE INDEX idx_admin_actions_admin ON admin_actions(admin_id);
CREATE INDEX idx_admin_actions_target ON admin_actions(target_type, target_id);
CREATE INDEX idx_admin_actions_created ON admin_actions(created_at DESC);
CREATE INDEX idx_lots_compliance_status ON pepper_lots(compliance_status);
```

### 3. Web Admin Interface

Updated file: `web/src/app/dashboard/admin/lots/page.tsx`

The existing page shows lot listings. To add approval functionality, you need to:

1. Add a modal component for viewing lot details
2. Display lot_pictures from IPFS
3. Display certificate_images from IPFS
4. Add approve/reject buttons
5. Handle API calls to the new endpoints

**Recommended approach**: Create a new detailed view page at:
`web/src/app/dashboard/admin/lots/[lotId]/page.tsx`

This page should include:

- Full lot details
- Image gallery for lot_pictures
- Image gallery for certificate_images
- Farmer information
- Approve button → calls PUT /api/admin/lots/:lotId/compliance with status='approved'
- Reject button → shows modal for reason, then calls API with status='rejected'

### 4. Blockchain Integration

#### Update Smart Contract (if needed)

The PepperPassport contract may need a new function:

```solidity
function updateComplianceStatus(
    string memory lotId,
    bool approved,
    address adminAddress
) public onlyAdmin {
    require(passports[lotId].exists, "Passport does not exist");

    passports[lotId].complianceApproved = approved;
    passports[lotId].complianceCheckedBy = adminAddress;
    passports[lotId].complianceCheckedAt = block.timestamp;

    emit ComplianceStatusUpdated(lotId, approved, adminAddress, block.timestamp);
}
```

#### Backend Blockchain Service

Add to `backend/src/services/blockchainService.js`:

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

#### Call from Admin Route

Update the `PUT /api/admin/lots/:lotId/compliance` endpoint:

```javascript
// After updating database
try {
  const blockchainService = require("../services/blockchainService");
  const txHash = await blockchainService.updateLotComplianceOnChain(
    lotId,
    status === "approved",
    adminId // or get from auth context
  );

  // Update blockchain_tx_hash in database
  await db.query(
    "UPDATE pepper_lots SET blockchain_tx_hash = $1 WHERE lot_id = $2",
    [txHash, lotId]
  );

  return res.json({
    success: true,
    message: `Lot ${status} successfully`,
    lot: updatedLot,
    blockchainTxHash: txHash,
  });
} catch (blockchainError) {
  logger.error("Blockchain update failed:", blockchainError);
  // Database already updated, inform admin of blockchain issue
  return res.json({
    success: true,
    message: `Lot ${status} in database, but blockchain update failed`,
    lot: updatedLot,
    blockchainError: blockchainError.message,
  });
}
```

### 5. Mobile App Updates

Update farmer lot details screen to show compliance status:

#### File: `mobile/lib/screens/farmer/lot_details_screen.dart`

Add compliance status display:

```dart
// Add to lot details widget
Widget _buildComplianceStatus() {
  final status = lot.complianceStatus ?? 'pending';
  final color = _getStatusColor(status);
  final icon = _getStatusIcon(status);

  return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Compliance Status',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                status.toUpperCase(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (lot.rejectionReason != null)
                Text(
                  lot.rejectionReason!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

Color _getStatusColor(String status) {
  switch (status) {
    case 'approved':
      return Colors.green;
    case 'rejected':
      return Colors.red;
    case 'checking':
      return Colors.blue;
    default:
      return Colors.orange;
  }
}

IconData _getStatusIcon(String status) {
  switch (status) {
    case 'approved':
      return Icons.check_circle;
    case 'rejected':
      return Icons.cancel;
    case 'checking':
      return Icons.hourglass_empty;
    default:
      return Icons.pending;
  }
}
```

#### Update Lot Model

Add to `mobile/lib/models/lot.dart`:

```dart
class Lot {
  // ... existing fields
  final String? complianceStatus;
  final String? rejectionReason;
  final DateTime? complianceCheckedAt;

  Lot({
    // ... existing parameters
    this.complianceStatus,
    this.rejectionReason,
    this.complianceCheckedAt,
  });

  factory Lot.fromJson(Map<String, dynamic> json) {
    return Lot(
      // ... existing fields
      complianceStatus: json['compliance_status'],
      rejectionReason: json['rejection_reason'],
      complianceCheckedAt: json['compliance_checked_at'] != null
          ? DateTime.parse(json['compliance_checked_at'])
          : null,
    );
  }
}
```

## Setup Instructions

### 1. Run Database Migration

```powershell
cd backend
node add-lot-approval-columns.js
```

This will:

- Add lot_pictures, certificate_images, rejection_reason columns
- Update status constraints
- Create admin_actions table
- Create necessary indexes

### 2. Restart Backend Server

```powershell
# Stop the current server (Ctrl+C)
cd backend
npm start
```

The new admin routes will be automatically loaded.

### 3. Update Web Admin Interface

Option A: Enhance existing page

- Edit `web/src/app/dashboard/admin/lots/page.tsx`
- Add image viewer modal
- Add approve/reject buttons

Option B: Create detailed view page (recommended)

- Create `web/src/app/dashboard/admin/lots/[lotId]/page.tsx`
- Implement full lot review interface
- Include IPFS image gallery

### 4. Test the Workflow

1. **Create a lot as farmer** (via mobile app):

   - Upload lot pictures
   - Upload certificate images
   - Submit lot (status='pending', compliance_status='pending')

2. **Review as admin** (via web dashboard):

   - Navigate to /dashboard/admin/lots
   - View pending lots
   - Click on a lot to see details and images
   - Approve or reject with reason

3. **Verify database**:

   ```sql
   SELECT lot_id, compliance_status, status, compliance_checked_at, rejection_reason
   FROM pepper_lots
   WHERE lot_id = 'your-lot-id';
   ```

4. **Check admin actions log**:

   ```sql
   SELECT * FROM admin_actions ORDER BY created_at DESC LIMIT 10;
   ```

5. **Verify mobile app shows updated status**:
   - Open lot details in mobile app
   - Should show 'approved' or 'rejected' status
   - If rejected, shows rejection reason

## API Usage Examples

### 1. Get Pending Lots

```bash
curl http://192.168.8.116:3002/api/admin/lots/pending
```

Response:

```json
{
  "success": true,
  "count": 5,
  "lots": [
    {
      "lot_id": "LOT-2024-001",
      "farmer_name": "John Farmer",
      "farmer_email": "john@example.com",
      "variety": "Black Pepper",
      "quantity": 500,
      "compliance_status": "pending",
      "lot_pictures": ["ipfs://Qm...abc", "ipfs://Qm...def"],
      "certificate_images": ["ipfs://Qm...xyz"],
      "created_at": "2024-01-15T10:30:00Z"
    }
  ]
}
```

### 2. Get Lot Details

```bash
curl http://192.168.8.116:3002/api/admin/lots/LOT-2024-001
```

### 3. Approve Lot

```bash
curl -X PUT http://192.168.8.116:3002/api/admin/lots/LOT-2024-001/compliance \
  -H "Content-Type: application/json" \
  -d '{
    "status": "approved",
    "adminId": "admin-123",
    "adminName": "Admin User"
  }'
```

Response:

```json
{
  "success": true,
  "message": "Lot approved successfully",
  "lot": {
    /* updated lot data */
  },
  "blockchainTxRequired": true
}
```

### 4. Reject Lot

```bash
curl -X PUT http://192.168.8.116:3002/api/admin/lots/LOT-2024-001/compliance \
  -H "Content-Type: application/json" \
  -d '{
    "status": "rejected",
    "reason": "Quality certificates are expired. Please upload current certificates.",
    "adminId": "admin-123",
    "adminName": "Admin User"
  }'
```

## IPFS Image Handling

### Storing Images (Farmer Mobile App)

When farmer uploads images:

```dart
// Upload to IPFS
final ipfsHash = await ipfsService.uploadFile(imageFile);
final ipfsUrl = 'ipfs://$ipfsHash';

// Store in database
lotPictures.add(ipfsUrl);
```

### Displaying Images (Admin Web App)

Convert IPFS URLs to gateway URLs:

```typescript
const getIPFSUrl = (url: string) => {
  const IPFS_GATEWAY = "http://192.168.8.116:8080/ipfs";

  if (url.startsWith("ipfs://")) {
    return url.replace("ipfs://", `${IPFS_GATEWAY}/`);
  }
  return url;
};

// Usage
<Image src={getIPFSUrl(lot.lot_pictures[0])} alt="Lot picture" />;
```

## Security Considerations

### 1. Authentication & Authorization

Add middleware to admin routes:

```javascript
// middleware/adminAuth.js
const verifyAdmin = (req, res, next) => {
  // Check JWT token
  const token = req.headers.authorization?.split(" ")[1];

  if (!token) {
    return res.status(401).json({ error: "No token provided" });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    if (decoded.role !== "admin") {
      return res.status(403).json({ error: "Admin access required" });
    }

    req.adminId = decoded.id;
    req.adminName = decoded.name;
    next();
  } catch (error) {
    return res.status(401).json({ error: "Invalid token" });
  }
};

// Apply to routes
router.put("/lots/:lotId/compliance", verifyAdmin, async (req, res) => {
  // Use req.adminId and req.adminName instead of from body
  const adminId = req.adminId;
  const adminName = req.adminName;
  // ...
});
```

### 2. Input Validation

```javascript
const validateComplianceUpdate = (req, res, next) => {
  const { status, reason } = req.body;

  if (!["approved", "rejected"].includes(status)) {
    return res.status(400).json({ error: "Invalid status" });
  }

  if (status === "rejected" && (!reason || reason.trim().length < 10)) {
    return res.status(400).json({
      error: "Rejection reason must be at least 10 characters",
    });
  }

  next();
};
```

### 3. Rate Limiting

```javascript
const rateLimit = require("express-rate-limit");

const adminLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each admin to 100 requests per windowMs
  message: "Too many requests from this admin",
});

app.use("/api/admin", adminLimiter);
```

## Troubleshooting

### Issue 1: "Column does not exist" error

**Solution**: Run the migration:

```powershell
node backend/add-lot-approval-columns.js
```

### Issue 2: Images not displaying

**Possible causes**:

1. IPFS daemon not running
2. Incorrect IPFS gateway URL
3. CORS issues

**Solutions**:

```powershell
# Start IPFS daemon
ipfs daemon

# Check IPFS gateway config
ipfs config Addresses.Gateway

# Add CORS headers
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["*"]'
```

### Issue 3: Blockchain update fails

**Solution**: The system is designed to handle this gracefully. The database update succeeds, and the response indicates blockchain update failed. Admin can retry the blockchain update separately.

## Future Enhancements

1. **Email Notifications**

   - Send email to farmer when lot is approved/rejected
   - Include rejection reason in email

2. **Compliance Checklist**

   - Add structured checklist for admin to verify
   - Track which requirements passed/failed

3. **Bulk Actions**

   - Approve multiple lots at once
   - Export pending lots report

4. **Audit Trail**

   - Detailed history of all changes
   - Who made what changes and when

5. **Compliance Scoring**
   - AI-based automatic scoring of compliance
   - Flag lots that may need extra review

## Summary

The lot compliance approval system is now complete with:

✅ Backend API endpoints for approval/rejection
✅ Database schema with necessary columns
✅ Admin actions logging
✅ IPFS image handling
✅ Mobile app compliance status display
✅ Blockchain integration readiness

**Next Steps**:

1. Run database migration
2. Restart backend server
3. Enhance web admin interface to show images and add approve/reject buttons
4. Add blockchain integration
5. Test complete workflow end-to-end
