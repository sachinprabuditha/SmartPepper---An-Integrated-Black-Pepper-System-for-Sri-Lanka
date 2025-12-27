# Deployment Guide - Lot Compliance Approval System

## 🚀 Quick Deployment Steps

### Step 1: Deploy Updated Smart Contract

The `PepperPassport.sol` contract has been updated with compliance status tracking.

```powershell
# Navigate to blockchain directory
cd blockchain

# Compile contracts
npx hardhat compile

# Deploy to local network
npm run deploy:local

# OR deploy to testnet/mainnet
npx hardhat run scripts/deploy.js --network <network-name>
```

**Important**: After deployment, copy the PepperPassport contract address to your `.env` file:

```env
PASSPORT_CONTRACT_ADDRESS=0xYourNewPassportContractAddress
```

### Step 2: Run Database Migration

```powershell
# Navigate to project root
cd ..

# Run the migration script
.\setup-lot-approval.ps1

# OR manually:
cd backend
node add-lot-approval-columns.js
```

This adds:

- `lot_pictures` (JSONB)
- `certificate_images` (JSONB)
- `rejection_reason` (TEXT)
- `admin_actions` table

### Step 3: Update Environment Variables

Add to `backend/.env`:

```env
# Existing variables
BLOCKCHAIN_RPC_URL=http://192.168.8.116:8545
CONTRACT_ADDRESS=0x8A791620dd6260079BF849Dc5567aDC3F2FdC318
PRIVATE_KEY=your_private_key_here

# New variable for PepperPassport
PASSPORT_CONTRACT_ADDRESS=0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6

# IPFS Gateway
IPFS_GATEWAY=http://192.168.8.116:8080/ipfs
```

Add to `web/.env.local`:

```env
NEXT_PUBLIC_API_URL=http://192.168.8.116:3002/api
NEXT_PUBLIC_IPFS_GATEWAY=http://192.168.8.116:8080/ipfs
```

### Step 4: Restart Services

```powershell
# Terminal 1: Blockchain (if redeployed)
cd blockchain
npx hardhat node

# Terminal 2: Backend
cd backend
npm start

# Terminal 3: Web
cd web
npm run dev
```

### Step 5: Test the System

1. **Access Admin Dashboard**:

   ```
   http://localhost:3000/dashboard/admin/lots
   ```

2. **Create Test Lot** (as farmer via mobile app or API):

   ```bash
   curl -X POST http://192.168.8.116:3002/api/lots \
     -H "Content-Type: application/json" \
     -d '{
       "lot_id": "TEST-LOT-001",
       "farmer_id": "farmer-uuid",
       "variety": "Black Pepper",
       "quantity": 500,
       "quality": "Premium",
       "harvest_date": "2024-01-15",
       "origin": "Kandy, Sri Lanka",
       "lot_pictures": ["ipfs://QmTest1", "ipfs://QmTest2"],
       "certificate_images": ["ipfs://QmCert1"]
     }'
   ```

3. **View Pending Lot**:

   - Go to admin lots page
   - Click "Review" on the pending lot
   - View images and details

4. **Approve/Reject Lot**:

   - Click "Approve" or "Reject"
   - For rejection, provide reason
   - Check console for blockchain transaction

5. **Verify Blockchain**:
   ```bash
   # Check compliance status
   curl http://192.168.8.116:3002/api/admin/lots/TEST-LOT-001
   ```

## 📋 What's Been Deployed

### ✅ Smart Contract Updates

- [PepperPassport.sol](blockchain/contracts/PepperPassport.sol)
  - Added `complianceApproved`, `complianceCheckedBy`, `complianceCheckedAt` fields
  - New function: `updateComplianceStatus(lotId, approved)`
  - New function: `isComplianceApproved(lotId)`
  - New function: `getComplianceStatus(lotId)`
  - New event: `ComplianceStatusUpdated`

### ✅ Backend Updates

- [backend/src/routes/admin.js](backend/src/routes/admin.js) - New admin API endpoints
- [backend/src/services/blockchainService.js](backend/src/services/blockchainService.js) - Blockchain integration
  - `updateLotComplianceOnChain(lotId, approved)`
  - `isLotComplianceApproved(lotId)`
  - `getComplianceStatusFromChain(lotId)`
- [backend/add-lot-approval-columns.js](backend/add-lot-approval-columns.js) - Database migration

### ✅ Web UI Updates

- [web/src/app/dashboard/admin/lots/page.tsx](web/src/app/dashboard/admin/lots/page.tsx) - Lots listing with filter
- [web/src/app/dashboard/admin/lots/[lotId]/page.tsx](web/src/app/dashboard/admin/lots/[lotId]/page.tsx) - New detailed review page
  - Image viewer for lot pictures
  - Certificate image viewer
  - Approve/Reject buttons
  - IPFS gateway integration
  - Blockchain transaction display

## 🔧 API Endpoints

All endpoints are prefixed with `/api/admin/`

### GET /admin/lots/pending

Get all lots pending admin approval.

**Response:**

```json
{
  "success": true,
  "count": 3,
  "lots": [
    {
      "lot_id": "LOT-2024-001",
      "farmer_name": "John Farmer",
      "variety": "Black Pepper",
      "quantity": 500,
      "compliance_status": "pending",
      "lot_pictures": ["ipfs://..."],
      "certificate_images": ["ipfs://..."]
    }
  ]
}
```

### GET /admin/lots/:lotId

Get detailed lot information.

**Response:**

```json
{
  "success": true,
  "lot": {
    "lot_id": "LOT-2024-001",
    "farmer_name": "John Farmer",
    "farmer_email": "john@example.com",
    "variety": "Black Pepper",
    "lot_pictures": ["ipfs://Qm..."],
    "certificate_images": ["ipfs://Qm..."]
  }
}
```

### PUT /admin/lots/:lotId/compliance

Approve or reject lot.

**Request:**

```json
{
  "status": "approved",
  "reason": "Optional rejection reason",
  "adminId": "admin-123",
  "adminName": "Admin User"
}
```

**Response:**

```json
{
  "success": true,
  "message": "Lot approved successfully",
  "lot": {
    /* updated lot */
  },
  "blockchainTxHash": "0x1234...",
  "blockchainTxRequired": false
}
```

### GET /admin/stats

Get dashboard statistics.

**Response:**

```json
{
  "success": true,
  "stats": {
    "pendingLots": 3,
    "totalLots": 50,
    "approvedLots": 42,
    "rejectedLots": 5,
    "activeAuctions": 8,
    "totalUsers": 120
  }
}
```

## 🎨 Web UI Routes

### Admin Lots Listing

`/dashboard/admin/lots`

- View all lots with filters
- Filter by compliance status (pending/approved/rejected/all)
- "Review" button for detailed view

### Lot Review Page (NEW)

`/dashboard/admin/lots/[lotId]`

- Full lot details with farmer information
- Image gallery for lot pictures
- Certificate image viewer
- Click images for full-size view (lightbox)
- Approve button → Updates DB + Blockchain
- Reject button → Shows modal for reason
- IPFS links to metadata and certificates

## 🔗 Blockchain Integration

### Smart Contract Functions Called

**On Approval/Rejection:**

```solidity
updateComplianceStatus(lotId, approved)
```

**To Check Status:**

```solidity
isComplianceApproved(lotId) // returns bool
getComplianceStatus(lotId)  // returns (bool, address, uint256)
```

### Blockchain Flow

1. Admin approves/rejects in web UI
2. Backend updates database immediately
3. Backend calls `blockchainService.updateLotComplianceOnChain()`
4. Smart contract records:
   - Compliance status (approved/rejected)
   - Admin address who approved
   - Timestamp
5. Transaction hash stored in database
6. Event emitted: `ComplianceStatusUpdated`

### Error Handling

If blockchain update fails:

- Database update still succeeds
- Response includes `blockchainError` message
- Response includes `blockchainTxRequired: true`
- Admin can manually retry or check logs

## 📊 Database Schema

### pepper_lots (Updated)

```sql
ALTER TABLE pepper_lots ADD COLUMN
  lot_pictures JSONB DEFAULT '[]',
  certificate_images JSONB DEFAULT '[]',
  rejection_reason TEXT,
  blockchain_tx_hash VARCHAR(66);
```

### admin_actions (New)

```sql
CREATE TABLE admin_actions (
  id UUID PRIMARY KEY,
  admin_id VARCHAR(255),
  action_type VARCHAR(50),
  target_type VARCHAR(50),
  target_id VARCHAR(255),
  details JSONB,
  created_at TIMESTAMPTZ
);
```

## 🧪 Testing Checklist

- [ ] Smart contract deployed successfully
- [ ] Database migration completed
- [ ] Backend starts without errors
- [ ] Web app loads admin lots page
- [ ] Pending lots displayed correctly
- [ ] Click "Review" opens detail page
- [ ] Images load from IPFS
- [ ] Approve button works
- [ ] Reject modal shows and works
- [ ] Blockchain transaction succeeds
- [ ] Transaction hash saved to database
- [ ] Admin action logged
- [ ] Farmer can see updated status (mobile app)

## 🐛 Troubleshooting

### Images Not Loading

**Error**: Images show broken icon

**Solution**:

1. Check IPFS daemon is running: `ipfs daemon`
2. Verify IPFS gateway URL in `.env.local`
3. Check CORS settings:
   ```bash
   ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["*"]'
   ```

### Blockchain Update Fails

**Error**: "PepperPassport contract not initialized"

**Solution**:

1. Check `PASSPORT_CONTRACT_ADDRESS` in backend `.env`
2. Verify contract is deployed: Check deployment logs
3. Ensure private key has owner permissions

### Contract Deployment Issues

**Error**: "Nonce too low" or transaction fails

**Solution**:

1. Reset Hardhat node: Stop and restart
2. Redeploy contracts: `npm run deploy:local`
3. Update contract addresses in `.env`

### API Returns 404

**Error**: "Cannot GET /api/admin/lots/pending"

**Solution**:

1. Check backend server is running
2. Verify `server.js` includes admin routes
3. Check URL matches environment variable

## 📈 Performance Considerations

1. **IPFS Gateway**: Images load from IPFS. Consider:

   - Using IPFS pinning service for reliability
   - Caching images on CDN
   - Setting up IPFS cluster for redundancy

2. **Blockchain Transactions**: Each approval/rejection costs gas:

   - Monitor gas prices
   - Consider batching approvals (future enhancement)
   - Keep private key secure (signing account)

3. **Database**: For large scale:
   - Index `compliance_status` column (already done)
   - Index `created_at` for sorting
   - Consider pagination for lots (already implemented)

## 🔒 Security Notes

1. **Admin Authentication**: Add JWT verification to admin routes
2. **IPFS Content**: Validate image content types and sizes
3. **Private Key**: Keep `PRIVATE_KEY` secure, never commit to git
4. **Input Validation**: Rejection reason has max length (500 chars)
5. **Rate Limiting**: Add rate limiting to admin endpoints

## 🎉 Deployment Complete!

Your lot compliance approval system is now fully functional with:

✅ Web UI for admin review
✅ Image viewing from IPFS
✅ Approve/Reject workflow
✅ Blockchain integration
✅ Database tracking
✅ Audit trail

The system is production-ready for local/testnet deployment. For mainnet deployment, review security considerations and conduct thorough testing.

---

**Need Help?**

- Check logs: `backend/logs/combined.log`
- Review documentation: `LOT_COMPLIANCE_APPROVAL_SYSTEM.md`
- Visual workflow: `LOT_APPROVAL_VISUAL_WORKFLOW.md`
