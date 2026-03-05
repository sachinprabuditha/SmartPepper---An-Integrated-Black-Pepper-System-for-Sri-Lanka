# WebSocket Setup Guide

## Overview

The SmartPepper auction system uses Socket.IO for real-time bidding functionality. This works for both **mobile (Flutter)** and **web (Next.js)** platforms.

## Backend Configuration

### Server Details

- **Port:** 3002
- **Namespace:** `/auction`
- **Full WebSocket URL:** `http://192.168.8.116:3002/auction`
- **Transports:** WebSocket (primary), Long Polling (fallback)

### Redis Caching (Optional)

- Redis is **optional** for caching auction states
- System works without Redis using in-memory cache
- To enable Redis, set in `.env`:
  ```
  REDIS_HOST=localhost
  REDIS_PORT=6379
  ```

## Mobile App (Flutter)

### Configuration

File: `mobile/lib/config/env.dart`

```dart
static const String wsBaseUrl = 'http://192.168.8.116:3002';
static const String wsNamespace = '/auction';
static const String wsUrl = '$wsBaseUrl$wsNamespace';
```

### Connection

The socket service automatically connects at app startup:

- File: `mobile/lib/services/socket_service.dart`
- Initialized in: `mobile/lib/main.dart`
- Dual transport: WebSocket + Polling for maximum compatibility
- Auto-reconnection: 10 attempts with exponential backoff

### Features

- **Connection Queue:** Actions queued before connection are executed automatically once connected
- **Auto-Reconnect:** Handles network interruptions gracefully
- **Comprehensive Logging:** Debug-friendly console output

## Web App (Next.js)

### Configuration

File: `web/src/config/socket.ts` (create if not exists)

```typescript
import { io, Socket } from "socket.io-client";

const SOCKET_URL = "http://192.168.8.116:3002/auction";

export const socket: Socket = io(SOCKET_URL, {
  transports: ["websocket", "polling"],
  autoConnect: true,
  reconnection: true,
  reconnectionDelay: 1000,
  reconnectionDelayMax: 5000,
  reconnectionAttempts: 10,
  timeout: 10000,
});
```

### Usage

```typescript
import { socket } from "@/config/socket";

// Join an auction
socket.emit("join_auction", { auctionId: "123" });

// Listen for new bids
socket.on("new_bid", (data) => {
  console.log("New bid:", data);
});
```

## WebSocket Events

### Client → Server

| Event           | Data                                    | Description                                               |
| --------------- | --------------------------------------- | --------------------------------------------------------- |
| `join_auction`  | `{ auctionId: string }`                 | Join an auction room to receive real-time updates         |
| `leave_auction` | `{ auctionId: string }`                 | Leave an auction room                                     |
| `place_bid`     | `{ auctionId: string, amount: number }` | Place a bid (handled via REST API, WebSocket for updates) |

### Server → Client

| Event               | Data                                       | Description                   |
| ------------------- | ------------------------------------------ | ----------------------------- |
| `new_bid`           | `{ auctionId, bidder, amount, timestamp }` | New bid placed in auction     |
| `auction_ended`     | `{ auctionId, winner, finalAmount }`       | Auction has ended             |
| `auction_settled`   | `{ auctionId, txHash }`                    | Auction settled on blockchain |
| `compliance_update` | `{ auctionId, status }`                    | Compliance status changed     |

## Troubleshooting

### Mobile App Not Connecting

1. **Check Backend is Running**

   ```bash
   cd backend
   npm start
   ```

   Look for: `✅ WebSocket server initialized`

2. **Verify IP Address**
   - Update `mobile/lib/config/env.dart` with your computer's IP
   - Use `ipconfig` (Windows) or `ifconfig` (Mac/Linux) to find IP
   - Phone must be on same WiFi network

3. **Check Firewall**
   - Allow port 3002 through firewall
   - Windows: `netsh advfirewall firewall add rule name="SmartPepper" dir=in action=allow protocol=TCP localport=3002`

4. **Check Console Logs**
   - Look for `✅ Socket connected successfully` (success)
   - Or `❌ Socket connect_error` (failure with troubleshooting tips)

### Web App Not Connecting

1. **CORS Issues**
   - Backend already configured to allow all origins
   - Check browser console for CORS errors

2. **Build Issues**
   - Ensure `socket.io-client` is installed:
     ```bash
     cd web
     npm install socket.io-client
     ```

3. **Next.js SSR Issues**
   - Socket.IO client should only run on client-side
   - Use dynamic import with `ssr: false` if needed

## Testing Connection

### Mobile App

1. Open app and navigate to "Live Auctions"
2. Check debug console for connection messages
3. Join an auction by tapping it
4. Look for: `✅ Successfully joined auction room: <id>`

### Web App

1. Open browser developer tools
2. Go to Network tab → Filter by "WS" (WebSocket)
3. Look for successful WebSocket connection
4. Check Console for connection logs

## Performance Notes

- **With Redis:** Auction states cached for 24 hours, reducing database queries
- **Without Redis:** In-memory cache with automatic cleanup after 24 hours
- **Mobile:** Dual transport ensures connection even on restrictive networks
- **Web:** WebSocket upgrade provides real-time, low-latency updates

## Security Considerations

1. **Production Environment:**
   - Use HTTPS/WSS (secure WebSocket)
   - Configure specific CORS origins (not wildcard `*`)
   - Add authentication middleware to socket connections

2. **Rate Limiting:**
   - Already implemented in REST API
   - Consider adding rate limiting to WebSocket events

3. **Data Validation:**
   - Always validate auction IDs before joining rooms
   - Verify user permissions before emitting bid events
