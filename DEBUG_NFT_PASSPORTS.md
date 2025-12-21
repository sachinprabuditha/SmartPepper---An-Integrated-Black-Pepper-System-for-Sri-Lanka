# 🔍 NFT Passport Debugging Guide

## Issue

NFT passports created successfully but not appearing in "My NFT Passport" page.

## Root Causes Found

### 1. **Case-Sensitivity Issue in Wallet Address Lookup**

The backend was doing exact case-sensitive wallet address lookups, but Ethereum addresses can be in different cases (checksummed vs lowercase).

### 2. **Missing Error Handling**

The frontend wasn't showing detailed error messages when the API returned empty results.

## Fixes Applied

### Backend Changes (`backend/src/routes/lot.js`)

1. **Case-Insensitive Farmer Lookup**

   ```javascript
   // OLD (case-sensitive)
   SELECT id FROM users WHERE wallet_address = $1

   // NEW (case-insensitive)
   SELECT id FROM users WHERE LOWER(wallet_address) = LOWER($1)
   ```

2. **Enhanced Logging**
   - Added detailed logs when creating lots
   - Added query parameter logging
   - Added result count logging

### Frontend Changes (`web/src/app/dashboard/farmer/passports/page.tsx`)

1. **Better Error Messages**

   - Show wallet address being used
   - Show API response details
   - Show count of lots returned

2. **Enhanced Debugging**
   - Log wallet address format
   - Log each lot being processed
   - Visual console messages with emojis

## How to Test

### Step 1: Start Backend with Logging

```bash
cd backend
npm run dev
```

Watch the console for:

- ✅ Lot created successfully
- 🔍 Filtering lots by farmer
- 📊 Query results

### Step 2: Open Browser Console

1. Navigate to http://localhost:3001/dashboard/farmer/passports
2. Open DevTools (F12)
3. Check Console tab for:
   - `=== Fetching NFT Passports ===`
   - `User wallet address: 0x...`
   - `✅ Lots found: X`
   - `📦 Processing lot: {...}`

### Step 3: Verify Data Flow

**Expected Console Output (Frontend):**

```
=== Fetching NFT Passports ===
User wallet address: 0xYourWalletAddress
User role: farmer
API URL: http://localhost:3002/api/lots?farmer=0xYourWalletAddress
API response status: 200
API response data: { success: true, count: 1, lots: [...] }
✅ Lots found: 1
📦 Processing lot: { lot_id: 'LOT-...', farmer_address: '0x...', ... }
```

**Expected Console Output (Backend):**

```
info: Creating new lot: { lotId: 'LOT-1733...' farmerAddress: '0x...' }
info: Creating new farmer user: { farmerAddress: '0x...' }
info: New farmer created with ID: 1
info: ✅ Lot created successfully: { lotId: 'LOT-...', farmerAddress: '0x...', farmer_id: 1 }
```

## Common Issues & Solutions

### Issue 1: "No lots found"

**Check:**

- Does the wallet address match between registration and viewing?
- Check backend logs: Is the farmer filter being applied correctly?

**Solution:**

```bash
# In backend, check database directly
cd backend
# Connect to your database and run:
SELECT lot_id, farmer_address, variety, quantity, created_at
FROM pepper_lots
ORDER BY created_at DESC
LIMIT 5;
```

### Issue 2: "No wallet address found"

**Check:**

- Is MetaMask connected?
- Is the user logged in?
- Check AuthContext: `user?.walletAddress`

**Solution:**

- Reconnect MetaMask
- Log out and log back in
- Clear browser cache and refresh

### Issue 3: Lots appear after refresh

**Root Cause:** The `useEffect` dependency array might not be triggering properly.

**Solution:** Already fixed - added `user?.walletAddress` to dependency array:

```typescript
useEffect(() => {
  if (user?.walletAddress) {
    fetchMyPassports();
  }
}, [user, user?.walletAddress]);
```

## Testing Checklist

- [ ] Backend server running on port 3002
- [ ] Frontend running on port 3001
- [ ] MetaMask connected
- [ ] User logged in as farmer
- [ ] Created at least one harvest
- [ ] Browser console open (F12)
- [ ] Backend logs visible

## Quick Test

1. **Create a test lot:**

   ```bash
   curl -X POST http://localhost:3002/api/lots \
     -H "Content-Type: application/json" \
     -d '{
       "lotId": "TEST-LOT-001",
       "farmerAddress": "0xYOUR_WALLET_ADDRESS",
       "variety": "Black Pepper",
       "quantity": 100,
       "quality": "A",
       "harvestDate": "2025-12-05",
       "origin": "Sri Lanka",
       "farmLocation": "Kandy",
       "organicCertified": true
     }'
   ```

2. **Verify it was created:**

   ```bash
   curl "http://localhost:3002/api/lots?farmer=0xYOUR_WALLET_ADDRESS"
   ```

3. **Check in browser:**
   - Go to `/dashboard/farmer/passports`
   - Should see TEST-LOT-001

## Next Steps if Still Not Working

1. **Check Database Connection**

   - Verify `backend/.env` has correct DB credentials
   - Test database connection manually

2. **Clear All Caches**

   ```bash
   # Frontend
   cd web
   rm -rf .next
   npm run dev

   # Browser
   - Hard refresh: Ctrl+Shift+R
   - Clear site data in DevTools
   ```

3. **Enable Verbose Logging**

   - Open `backend/src/utils/logger.js`
   - Set level to 'debug'

4. **Check Network Tab**
   - Open DevTools > Network
   - Filter by "lots"
   - Check request/response details

## Success Indicators

✅ Backend logs show "✅ Lot created successfully"  
✅ Frontend console shows "✅ Lots found: 1"  
✅ Passport cards appear in grid  
✅ QR code button visible  
✅ "View Details" link works

---

**Last Updated:** December 5, 2025  
**Status:** Debugging improvements deployed  
**Action Required:** Test harvest registration and verify lots appear in passport page
