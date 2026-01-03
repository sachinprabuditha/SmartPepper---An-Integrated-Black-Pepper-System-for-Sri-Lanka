# WebSocket Real-Time Updates Fix

## Problem Identified

The farmer's mobile app auction monitor screen was not receiving real-time bid updates when exporters placed bids. This was due to **three critical mismatches** between the mobile app and backend WebSocket implementation:

### 1. Event Name Mismatch

- **Backend emits**: `new_bid`
- **Mobile listens for**: `bid_placed` ❌

### 2. WebSocket Namespace Mismatch

- **Backend uses**: `/auction` namespace
- **Mobile connects to**: root namespace `/` ❌

### 3. Room Name Pattern

- **Backend uses**: `auction_${id}` (underscore)
- **Backend bid route was using**: `auction-${id}` (hyphen) ❌

## Fixes Applied

### 1. Mobile App Changes

#### ✅ [auction_monitor_screen.dart](d:\Campus\Research\SmartPepper\SmartPepper-Auction-Blockchain-System\mobile\lib\screens\farmer\auction_monitor_screen.dart)

Changed event listener from `bid_placed` to `new_bid`:

```dart
// OLD: socketService.on('bid_placed', (data) => { ... });
// NEW: socketService.on('new_bid', (data) => { ... });
```

Added debug logging:

```dart
socketService.on('new_bid', (data) {
  print('📡 Received new_bid event: $data');
  // ... handle bid update
});
```

Added auction joined confirmation listener:

```dart
socketService.on('auction_joined', (data) {
  print('✅ Successfully joined auction room: ${data['auctionId']}');
});
```

Updated bid data field names:

```dart
// Backend sends 'amount' (not 'bidAmount') and 'bidder' (not 'bidderId')
final bidAmount = data['amount'] ?? data['bidAmount'];
highestBidder: data['bidder']?.toString() ?? data['bidderId']?.toString()
```

#### ✅ [env.dart](d:\Campus\Research\SmartPepper\SmartPepper-Auction-Blockchain-System\mobile\lib\config\env.dart)

Updated WebSocket URL to include `/auction` namespace:

```dart
// OLD: static const String wsUrl = 'ws://192.168.8.116:3002';
// NEW: static const String wsUrl = 'ws://192.168.8.116:3002/auction';
```

#### ✅ [socket_service.dart](d:\Campus\Research\SmartPepper\SmartPepper-Auction-Blockchain-System\mobile\lib\services\socket_service.dart)

Enhanced connection logging and error handling:

```dart
void connect() {
  print('🔌 Connecting to WebSocket: ${Environment.wsUrl}');
  _socket = IO.io(
    Environment.wsUrl,
    IO.OptionBuilder()
      .setTransports(['websocket'])
      .enableAutoConnect()
      .enableReconnection()           // Added
      .setReconnectionDelay(1000)     // Added
      .build(),
  );

  // Added connect_error listener
  _socket.on('connect_error', (error) {
    print('❌ Socket connect_error: $error');
  });
}
```

Improved auction room join/leave logging:

```dart
void joinAuction(String auctionId) {
  if (_connected) {
    print('📡 Emitting join_auction for: $auctionId');
    _socket.emit('join_auction', {'auctionId': auctionId});
  } else {
    print('⚠️ Cannot join auction - socket not connected');
  }
}
```

### 2. Backend Changes

#### ✅ [auction.js](d:\Campus\Research\SmartPepper\SmartPepper-Auction-Blockchain-System\backend\src\routes\auction.js)

Fixed WebSocket broadcast to use correct namespace and room name:

```javascript
// OLD:
io.to(`auction-${id}`).emit('new_bid', { ... });

// NEW:
const auctionNamespace = io.of('/auction');
auctionNamespace.to(`auction_${id}`).emit('new_bid', { ... });
```

Added broadcast logging:

```javascript
logger.info("WebSocket broadcast sent", {
  room: `auction_${id}`,
  event: "new_bid",
  amount: bidInEth.toString(),
});
```

## Testing Steps

### 1. Restart Backend Server

```powershell
cd backend
npm start
```

Check logs for:

```
✅ WebSocket server initialized
✅ WebSocket server initialized on /auction namespace
```

### 2. Restart Mobile App

Hot restart Flutter app (R in terminal or restart button)

Check debug console for:

```
🔌 Connecting to WebSocket: ws://192.168.8.116:3002/auction
✅ Socket connected to ws://192.168.8.116:3002/auction
📡 Joining auction room: <auction_id>
✅ Successfully joined auction room: <auction_id>
```

### 3. Place Test Bid from Web

1. Open web app as exporter
2. Navigate to auction
3. Place a bid
4. Watch mobile app update in real-time

### 4. Verify Bid Updates

Mobile app should show:

```
📡 Received new_bid event: {auctionId: 1, bidder: 0x..., amount: 0.0170, ...}
```

And the UI should update with:

- ✅ New current bid amount (ETH)
- ✅ New current bid in LKR
- ✅ Highest bidder address
- ✅ Bid count increment

## Event Flow Diagram

```
Exporter (Web)                Backend                    Farmer (Mobile)
     |                           |                              |
     |-- POST /api/auctions/:id/bid ------------------>|        |
     |                           |                              |
     |                    [Process bid]                         |
     |                           |                              |
     |                    [Save to DB]                          |
     |                           |                              |
     |                           |-- emit('new_bid') ---------> |
     |                           |   namespace: /auction        |
     |                           |   room: auction_123          |
     |                           |                              |
     |                           |                    [Update UI]
     |<-- 201 Bid placed --------|                              |
     |                           |                              |
```

## WebSocket Connection Flow

```
Mobile App Startup
       |
       v
  Connect to ws://host:3002/auction
       |
       v
  ✅ Socket connected
       |
       v
  User opens auction monitor screen
       |
       v
  emit('join_auction', {auctionId: 123})
       |
       v
  Backend: socket.join('auction_123')
       |
       v
  Backend: emit('auction_joined', {...})
       |
       v
  ✅ Successfully joined auction room
       |
       v
  [Now receiving real-time updates]
```

## Debugging Commands

### Check WebSocket Connections (Backend Terminal)

```javascript
// Add to auctionSocket.js temporarily
console.log("Active rooms:", Array.from(socket.rooms));
console.log("Connected clients:", this.auctionNamespace.sockets.size);
```

### Check Mobile Debug Logs

Look for these patterns:

```
🔌 Connecting to WebSocket: ...
✅ Socket connected to ...
📡 Emitting join_auction for: ...
✅ Successfully joined auction room: ...
📡 Received new_bid event: ...
```

### Test WebSocket Manually (Optional)

Use a WebSocket testing tool (like wscat):

```bash
npm install -g wscat
wscat -c ws://192.168.8.116:3002/auction

# After connection:
> 42["join_auction",{"auctionId":"1"}]
< 42["auction_joined",{"auctionId":"1",...}]
```

## Common Issues & Solutions

### Issue: "Socket not connected" errors

**Solution**: Ensure backend is running and mobile device can reach the IP address

### Issue: "auction_joined" never fires

**Solution**: Check if Redis is running (WebSocket requires Redis)

### Issue: Bid updates work for some auctions but not others

**Solution**: Ensure auctionId is correctly passed (string vs number mismatch)

### Issue: Connection drops frequently

**Solution**: Check network stability, enable reconnection (already added)

## Verification Checklist

- [ ] Backend WebSocket server starts successfully
- [ ] Mobile app connects to `/auction` namespace
- [ ] Mobile app joins auction room on screen open
- [ ] Mobile app receives `auction_joined` confirmation
- [ ] Web bid triggers `new_bid` event broadcast
- [ ] Mobile app receives and logs `new_bid` event
- [ ] Mobile UI updates with new bid amount
- [ ] Mobile UI shows correct LKR conversion
- [ ] Multiple bids update sequentially
- [ ] Connection survives app backgrounding

## Files Modified

### Mobile App

1. `mobile/lib/screens/farmer/auction_monitor_screen.dart`

   - Changed event listener: `bid_placed` → `new_bid`
   - Added debug logging for events
   - Added `auction_joined` confirmation listener
   - Updated field names: `bidAmount` → `amount`, `bidderId` → `bidder`

2. `mobile/lib/config/env.dart`

   - Updated WebSocket URL to include `/auction` namespace

3. `mobile/lib/services/socket_service.dart`
   - Enhanced connection logging
   - Added reconnection support
   - Added `connect_error` event listener
   - Improved join/leave logging

### Backend

1. `backend/src/routes/auction.js`
   - Fixed WebSocket broadcast to use `/auction` namespace
   - Changed room name from `auction-${id}` to `auction_${id}`
   - Added broadcast logging

## Expected Behavior After Fix

1. **Farmer opens auction monitor screen**:

   - Mobile connects to WebSocket
   - Joins auction room
   - Sees confirmation in logs

2. **Exporter places bid from web**:

   - Backend processes bid
   - Backend emits to `/auction` namespace, room `auction_123`
   - Mobile receives event immediately
   - Mobile UI updates within 100ms

3. **Multiple rapid bids**:

   - Each bid triggers separate event
   - Mobile processes them sequentially
   - UI updates smoothly without lag

4. **Network interruption**:
   - Mobile auto-reconnects (1 second delay)
   - Automatically rejoins auction room
   - Continues receiving updates

## Success Criteria

✅ Farmer sees bid updates in real-time (< 500ms delay)  
✅ Bid amount displays correctly in both ETH and LKR  
✅ Highest bidder address updates  
✅ No console errors or warnings  
✅ Works across multiple auctions simultaneously  
✅ Survives app backgrounding and network changes

## Next Steps

1. **Test the fix**: Follow testing steps above
2. **Monitor logs**: Watch for the debug prints
3. **Report results**: Confirm bids are updating
4. **Production**: Remove debug logs after verification
5. **Enhancement**: Consider adding reconnection UI indicator

## Support

If issues persist, check:

- Backend logs: `backend/logs/combined.log`
- Mobile logs: Flutter debug console
- Network connectivity: Ping backend server
- Redis status: `redis-cli ping` should return `PONG`
