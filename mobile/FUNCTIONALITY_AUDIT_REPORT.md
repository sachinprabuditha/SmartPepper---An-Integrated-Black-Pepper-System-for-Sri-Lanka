# SmartPepper Mobile App Functionality Audit Report

**Date:** December 25, 2025  
**Status:** Comprehensive Review

## Executive Summary

### ✅ IMPLEMENTED

- Registration & User Management
- Lot Creation UI
- Auction Monitoring (Real-time)
- Notifications Service
- Offline Sync Service
- QR Code Generation
- IPFS Service Structure

### ⚠️ PARTIALLY IMPLEMENTED

- Blockchain Integration (Service exists but not connected to lot creation)
- Wallet Address Management (Not captured during registration)
- Certificate Upload to IPFS (Not connected in create lot flow)

### ❌ NOT IMPLEMENTED

- Blockchain Write on Lot Creation
- Smart Contract Interaction (Auction Creation)
- NFC Tag Generation (Service exists but not integrated)
- QR Code linking to physical tags
- Blockchain verification in lot details

---

## Detailed Analysis by Core Function

## 1. Farmer Registration and Identity ⚠️

### Status: PARTIALLY IMPLEMENTED

**What Works:**

- ✅ Registration screen with farmer-specific form
- ✅ User profiles stored in database
- ✅ Role-based authentication (farmer/exporter)
- ✅ Phone number capture

**What's Missing:**

- ❌ **Blockchain wallet address NOT generated during registration**
- ❌ **No automatic wallet creation**
- ❌ Wallet address field exists in User model but never populated
- ❌ No blockchain identity linking

**Code Evidence:**

```dart
// mobile/lib/providers/auth_provider.dart
// register() method doesn't create wallet
// walletAddress is optional and never set

// mobile/lib/services/blockchain_service.dart
// Has getAddressFromPrivateKey() but never called during registration
```

**Required Fix:**

1. Generate wallet during registration
2. Store private key securely
3. Link wallet address to user profile
4. Update backend to store blockchain address

---

## 2. Pepper Lot Creation ⚠️

### Status: PARTIALLY IMPLEMENTED

**What Works:**

- ✅ Complete form UI (variety, quantity, quality, harvest date)
- ✅ Image picker for certificate photos
- ✅ Multiple certificate images support
- ✅ Form validation
- ✅ Lot data sent to backend API

**What's Missing:**

- ❌ **No blockchain write operation**
- ❌ **Certificates not uploaded to IPFS**
- ❌ **No QR code generated**
- ❌ **No NFC tag created**
- ❌ No metadata URI creation
- ❌ Certificate images stored locally only, not uploaded

**Code Evidence:**

```dart
// mobile/lib/screens/farmer/create_lot_screen.dart - Line 154-168
// Creates lotData with EMPTY values:
'metadataURI': '',
'certificateHash': '',
'certificateIpfsUrl': '',
'txHash': '',

// Images captured but never uploaded:
List<File> _certificateImages = [];
// No call to IpfsService.uploadMultipleFiles()
```

**Required Fix:**

1. Upload certificates to IPFS before API call
2. Generate QR code with lot data
3. Write lot hash to blockchain
4. Store transaction hash and IPFS URLs
5. Generate NFC tag identifier

---

## 3. Blockchain Traceability Submission ❌

### Status: NOT IMPLEMENTED

**What Exists:**

- ✅ BlockchainService class with Web3 client
- ✅ IpfsService with upload methods
- ✅ QrNfcService with generation methods

**What's Missing:**

- ❌ **No blockchain write operation in lot creation flow**
- ❌ **Contract interactions are UnimplementedError**
- ❌ No smart contract ABI loaded
- ❌ No contract address configured
- ❌ IPFS upload never called
- ❌ Blockchain transaction never sent

**Code Evidence:**

```dart
// mobile/lib/services/blockchain_service.dart - Line 54-58
Future<String> createAuction(...) async {
  throw UnimplementedError('Contract interaction not yet implemented');
}

// mobile/lib/providers/lot_provider.dart - createLot()
// Just calls apiService.createLot() - NO blockchain write
// NO IPFS upload
// NO QR generation
```

**Required Implementation:**

```dart
// Needs to be added to createLot() flow:
1. Upload certificates to IPFS → get IPFS hashes
2. Create metadata JSON with lot details
3. Upload metadata to IPFS → get metadata URI
4. Write to blockchain smart contract
5. Get transaction hash
6. Generate QR code with lot ID + blockchain hash
7. Save all hashes to backend
```

---

## 4. Auction Participation ✅

### Status: FULLY IMPLEMENTED

**What Works:**

- ✅ Farmers can list approved lots for auction
- ✅ Real-time auction monitoring screen
- ✅ Live highest bid display
- ✅ Bidder count tracking
- ✅ Countdown timer
- ✅ WebSocket integration for live updates
- ✅ Auction timeline visualization
- ✅ Bidding activity history
- ✅ View-only interface (farmers don't bid)

**Code Evidence:**

```dart
// mobile/lib/screens/farmer/auction_monitor_screen.dart
- _setupRealtimeUpdates() - WebSocket listeners ✅
- _startCountdownTimer() - Live countdown ✅
- Auction model with timeRemaining calculation ✅
- UI shows current bid, bidder count, time ✅
```

**Status: ✅ COMPLETE**

---

## 5. Notifications ✅

### Status: FULLY IMPLEMENTED

**What Works:**

- ✅ NotificationService with local notifications
- ✅ Notification types: auction_start, auction_end, bid_update, compliance, payment
- ✅ Unread count badge
- ✅ Priority levels (urgent, high, normal)
- ✅ Notification screen with filtering
- ✅ Mark as read functionality
- ✅ Notification data for navigation

**Code Evidence:**

```dart
// mobile/lib/services/notification_service.dart
- initialize() - Flutter Local Notifications setup ✅
- notifyAuctionStart() ✅
- notifyAuctionEnd() ✅
- notifyBidUpdate() ✅
- notifyCompliance() ✅
- notifyPayment() ✅
- getUnreadCount() ✅

// mobile/lib/screens/farmer/notifications_screen.dart
- Filter by type ✅
- Mark as read ✅
- Navigate to related screens ✅
```

**Status: ✅ COMPLETE**

---

## 6. Offline Support ✅

### Status: FULLY IMPLEMENTED

**What Works:**

- ✅ OfflineSyncService with connectivity monitoring
- ✅ Queue pending operations locally
- ✅ Auto-sync when connection restored
- ✅ Manual sync trigger
- ✅ Pending count display
- ✅ Sync status banner in dashboard
- ✅ Uses flutter_secure_storage for local persistence

**Code Evidence:**

```dart
// mobile/lib/services/offline_sync_service.dart
- initialize() - Connectivity monitoring ✅
- savePendingLot() - Local storage ✅
- syncPendingData() - Auto upload ✅
- getPendingCount() ✅

// mobile/lib/screens/farmer/farmer_dashboard.dart
- Offline sync banner ✅
- Manual sync button ✅
- Pending count display ✅
```

**Status: ✅ COMPLETE**

---

## Critical Missing Components

### 1. Blockchain Integration in Lot Creation Flow

**Current State:**

```dart
// create_lot_screen.dart - _submitLot()
final success = await lotProvider.createLot(lotData); // ❌ NO BLOCKCHAIN

// Should be:
// 1. Upload certificates to IPFS
final ipfsHashes = await ipfsService.uploadMultipleFiles(_certificateImages);
final metadata = await ipfsService.uploadJson(lotMetadata);

// 2. Write to blockchain
final txHash = await blockchainService.writeLotToBlockchain(
  lotId: lotId,
  metadataUri: metadata,
  certificateHash: ipfsHashes[0],
);

// 3. Generate QR
final qrData = qrNfcService.generateQrData(...);

// 4. Then save to backend with blockchain data
final success = await lotProvider.createLot({
  ...lotData,
  'txHash': txHash,
  'metadataURI': metadata,
  'certificateIpfsUrl': ipfsHashes[0],
  'qrCode': qrData,
});
```

### 2. Smart Contract Loading

**Current State:**

```dart
// BlockchainService has no contract ABI
throw UnimplementedError('Contract interaction not yet implemented');
```

**Required:**

```dart
// Need to add:
import 'package:flutter/services.dart' show rootBundle;

late DeployedContract _pepperTraceabilityContract;
late ContractFunction _createLotFunction;
late ContractFunction _createAuctionFunction;

Future<void> loadContract() async {
  final abiString = await rootBundle.loadString('assets/abis/PepperTraceability.json');
  final abi = jsonDecode(abiString)['abi'];

  _pepperTraceabilityContract = DeployedContract(
    ContractAbi.fromJson(jsonEncode(abi), 'PepperTraceability'),
    EthereumAddress.fromHex(Environment.contractAddress),
  );

  _createLotFunction = _pepperTraceabilityContract.function('createLot');
}
```

### 3. Wallet Generation During Registration

**Required:**

```dart
// auth_provider.dart - register()
Future<bool> register(...) async {
  // Generate blockchain wallet
  final privateKey = EthPrivateKey.createRandom(Random.secure());
  final walletAddress = await blockchainService.getAddressFromPrivateKey(
    privateKey.hex
  );

  // Store private key securely
  await storageService.savePrivateKey(privateKey.hex);

  // Include in registration
  final response = await apiService.register({
    ...
    'walletAddress': walletAddress.hex,
  });
}
```

---

## Summary Matrix

| Function            | UI  | Service | API | Blockchain | IPFS | Status  |
| ------------------- | --- | ------- | --- | ---------- | ---- | ------- |
| 1. Registration     | ✅  | ✅      | ✅  | ❌         | N/A  | ⚠️ 60%  |
| 2. Lot Creation     | ✅  | ✅      | ✅  | ❌         | ❌   | ⚠️ 50%  |
| 3. Blockchain Trace | N/A | ⚠️      | N/A | ❌         | ❌   | ❌ 0%   |
| 4. Auction View     | ✅  | ✅      | ✅  | N/A        | N/A  | ✅ 100% |
| 5. Notifications    | ✅  | ✅      | ✅  | N/A        | N/A  | ✅ 100% |
| 6. Offline Sync     | ✅  | ✅      | ✅  | N/A        | N/A  | ✅ 100% |

**Overall Completion: 65%**

---

## Action Items (Priority Order)

### HIGH PRIORITY (Blockchain Core)

1. ✅ Load smart contract ABI to assets/abis/
2. ✅ Implement contract interaction in BlockchainService
3. ✅ Generate wallet during farmer registration
4. ✅ Integrate IPFS upload in lot creation flow
5. ✅ Write lot data to blockchain in lot creation
6. ✅ Generate and link QR codes

### MEDIUM PRIORITY

7. ⚠️ Test blockchain write with local Hardhat network
8. ⚠️ Verify IPFS node is running and accessible
9. ⚠️ Add blockchain verification in lot details screen
10. ⚠️ Show blockchain transaction status to user

### LOW PRIORITY

11. Add NFC tag generation
12. Implement smart contract auction creation
13. Add blockchain explorer link in UI

---

## Next Steps

1. **Deploy Contract**: Ensure SmartPepper contracts deployed to Hardhat
2. **Copy ABI**: Copy contract ABI to `mobile/assets/abis/`
3. **Update BlockchainService**: Implement contract interactions
4. **Integrate Services**: Connect IPFS + Blockchain to lot creation
5. **Test End-to-End**: Create lot → Upload IPFS → Write blockchain → Verify
6. **Update UI**: Show blockchain status and transaction links

---

## Conclusion

The mobile app has **excellent UI/UX and service architecture** but **lacks blockchain integration**, which is the core differentiator of SmartPepper. The infrastructure exists (BlockchainService, IpfsService, QrNfcService) but these are **not connected to the lot creation flow**.

**Critical Gap:** Lot creation bypasses blockchain entirely and goes straight to database, defeating the purpose of blockchain traceability.

**Recommendation:** Prioritize blockchain integration before any other features.
