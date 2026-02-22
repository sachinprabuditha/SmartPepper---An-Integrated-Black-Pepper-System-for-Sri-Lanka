# Optional Services Configuration

The SmartPepper backend works with Firebase as the primary database. The following services are **optional** and provide enhanced functionality when configured:

## Service Overview

### ✅ **Required Services**
- **Firebase/Firestore** - Primary database (already configured)
- **Node.js Backend API** - Core REST API

### 📦 **Optional Services**

#### 1. **Redis** (Real-time Caching & WebSocket Support)
**Status**: Not configured (shows info message on startup)
**Purpose**: 
- Enables real-time WebSocket updates during auctions
- Caches auction state for faster bid processing
- Improves performance for concurrent auction participants

**When you need it**:
- High-frequency bidding (many bids per second)
- Real-time auction room updates
- Multiple concurrent auctions

**How to enable**:
```bash
# Install Redis on Windows (using Chocolatey)
choco install redis-64

# Or download from: https://github.com/microsoftarchive/redis/releases

# Start Redis
redis-server

# Update .env
REDIS_HOST=localhost
REDIS_PORT=6379
```

**What happens without it**:
- System works normally with Firebase
- No real-time WebSocket updates (users must refresh)
- Slightly slower bid processing

---

#### 2. **IPFS** (Decentralized NFT Metadata Storage)
**Status**: Not configured (shows info message on startup)
**Purpose**:
- Stores NFT passport metadata in a decentralized manner
- Provides immutable storage for product traceability data
- Required for full blockchain compliance

**When you need it**:
- Creating NFT passports for pepper lots
- Full blockchain traceability implementation
- Compliance with decentralized storage standards

**How to enable**:
```bash
# Install IPFS Desktop
# Download from: https://docs.ipfs.tech/install/ipfs-desktop/

# Or install via command line
npm install -g ipfs

# Initialize and start IPFS
ipfs init
ipfs daemon

# Update .env
IPFS_HOST=localhost
IPFS_PORT=5001
IPFS_PROTOCOL=http
```

**What happens without it**:
- NFT metadata stored locally with SHA-256 hash
- System generates `local://` URIs instead of `ipfs://`
- Full functionality maintained, just not decentralized

---

## Current System Status

Your system is currently running with:
- ✅ **Firebase/Firestore** - Active (primary database)
- ℹ️  **Redis** - Not configured (optional for WebSocket)
- ℹ️  **IPFS** - Not configured (optional for NFT storage)

## Startup Messages Explained

### Before (Warning Messages):
```
[warn]: IPFS not available - metadata will be generated locally
[warn]: Redis connection failed (continuing without Redis)
[warn]: WebSocket not initialized (Redis unavailable)
```

### After (Info Messages):
```
[info]: ℹ️  IPFS not configured - NFT metadata will be stored locally (this is optional)
[info]: ℹ️  Redis not configured - WebSocket real-time updates disabled (optional)
[info]: ℹ️  WebSocket real-time updates disabled (requires Redis)
```

These are **informational messages**, not errors. The system is working correctly.

## Recommendations

### For Development/Testing:
✅ Current setup is sufficient
- Firebase provides all core functionality
- No need for Redis or IPFS during development

### For Production (High-Traffic Auctions):
Consider enabling:
- ✅ **Redis** - For better performance with multiple bidders
- ⚠️ **IPFS** - Optional, only if NFT compliance is critical

### For Full Blockchain Compliance:
Enable all services:
- ✅ **Firebase** - Database
- ✅ **Redis** - Performance
- ✅ **IPFS** - Decentralized storage
- ✅ **Blockchain Network** - Smart contracts

## Testing Without Optional Services

You can verify everything works without Redis/IPFS:

```bash
# Test auction creation
curl -X POST http://localhost:3000/api/auctions \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Auction","startDate":"2026-02-22T10:00:00Z"}'

# Test health check
curl http://localhost:3000/health
```

## Need Help?

If you want to enable these services later, refer to:
- Redis: https://redis.io/docs/getting-started/
- IPFS: https://docs.ipfs.tech/
- Firebase: https://firebase.google.com/docs

---

**Summary**: Your system is working correctly. The messages you're seeing are just informing you that optional features are not configured. Firebase handles all core database operations successfully.
