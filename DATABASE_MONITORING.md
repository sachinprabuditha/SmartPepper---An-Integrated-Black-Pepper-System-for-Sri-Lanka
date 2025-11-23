# Database Monitoring Guide

## 🔍 How to Watch and Monitor the Database

### 1. Check Docker Containers Status

```powershell
# View running containers
docker ps --filter name=smartpepper

# View container logs
docker logs smartpepper-postgres
docker logs smartpepper-redis
```

---

### 2. Connect to PostgreSQL Database

#### Quick Connection

```powershell
docker exec -it smartpepper-postgres psql -U postgres -d smartpepper
```

#### Inside psql, you can run:

```sql
-- List all tables
\dt

-- View table structure
\d auctions
\d pepper_lots
\d users

-- Exit
\q
```

---

### 3. View Database Data

#### Check Auctions

```powershell
docker exec -it smartpepper-postgres psql -U postgres -d smartpepper -c "SELECT * FROM auctions;"
```

#### Check Pepper Lots

```powershell
docker exec -it smartpepper-postgres psql -U postgres -d smartpepper -c "SELECT * FROM pepper_lots;"
```

#### Check Users

```powershell
docker exec -it smartpepper-postgres psql -U postgres -d smartpepper -c "SELECT * FROM users;"
```

#### Check Bids

```powershell
docker exec -it smartpepper-postgres psql -U postgres -d smartpepper -c "SELECT * FROM bids ORDER BY placed_at DESC;"
```

#### Count Records

```powershell
docker exec -it smartpepper-postgres psql -U postgres -d smartpepper -c "SELECT
  (SELECT COUNT(*) FROM auctions) as auctions,
  (SELECT COUNT(*) FROM pepper_lots) as lots,
  (SELECT COUNT(*) FROM users) as users,
  (SELECT COUNT(*) FROM bids) as bids;"
```

---

### 4. Check Backend Connection

#### View Backend Logs

Look for these messages when backend starts:

```
✅ Database: PostgreSQL connected
```

or

```
✅ Database: Using MOCK in-memory database
```

#### Test API Connection

```powershell
# Get auctions (should return data from PostgreSQL)
curl http://localhost:3002/api/auctions

# Or with PowerShell
(Invoke-WebRequest -Uri http://localhost:3002/api/auctions).Content | ConvertFrom-Json
```

---

### 5. Real-time Monitoring

#### Watch Database Activity (Live)

```powershell
# Terminal 1: Watch database queries
docker exec -it smartpepper-postgres psql -U postgres -d smartpepper

# In psql:
SELECT * FROM pg_stat_activity WHERE datname = 'smartpepper';
```

#### Monitor Container Resources

```powershell
docker stats smartpepper-postgres smartpepper-redis
```

---

### 6. Database Connection Details

**PostgreSQL:**

- **Host:** localhost (from your machine) or `smartpepper-postgres` (from Docker network)
- **Port:** 5432
- **Database:** smartpepper
- **Username:** postgres
- **Password:** postgres
- **Connection String:** `postgresql://postgres:postgres@localhost:5432/smartpepper`

**Redis:**

- **Host:** localhost
- **Port:** 6379
- **No password (development mode)**

---

### 7. Using Database Management Tools

You can connect using GUI tools:

#### pgAdmin (Free)

1. Download: https://www.pgadmin.org/
2. Add New Server:
   - Name: SmartPepper
   - Host: localhost
   - Port: 5432
   - Database: smartpepper
   - Username: postgres
   - Password: postgres

#### DBeaver (Free)

1. Download: https://dbeaver.io/
2. Create New Connection → PostgreSQL
3. Use same credentials above

#### VS Code Extension

1. Install "PostgreSQL" extension by Chris Kolkman
2. Connect with:
   ```
   postgresql://postgres:postgres@localhost:5432/smartpepper
   ```

---

### 8. Check Current Backend Configuration

```powershell
# View current .env settings
cat backend\.env | Select-String "DB_"
```

Expected output:

```
DB_HOST=localhost
DB_PORT=5432
DB_NAME=smartpepper
DB_USER=postgres
DB_PASSWORD=postgres
```

---

### 9. Interactive SQL Queries

```powershell
# Connect to database
docker exec -it smartpepper-postgres psql -U postgres -d smartpepper
```

Then run SQL queries:

```sql
-- View active auctions
SELECT
  auction_id,
  lot_id,
  status,
  current_bid::numeric / 1000000000000000000 as current_bid_eth,
  bid_count,
  end_time
FROM auctions
WHERE status = 'active';

-- View recent bids
SELECT
  b.auction_id,
  a.lot_id,
  b.bidder_address,
  b.amount::numeric / 1000000000000000000 as bid_eth,
  b.placed_at
FROM bids b
JOIN auctions a ON b.auction_id = a.auction_id
ORDER BY b.placed_at DESC
LIMIT 10;

-- View farmer lots
SELECT
  pl.lot_id,
  pl.variety,
  pl.quantity,
  pl.status,
  u.name as farmer_name
FROM pepper_lots pl
JOIN users u ON pl.farmer_address = u.wallet_address;
```

---

### 10. Troubleshooting

#### If backend says "Database not configured":

```powershell
# Check if DB_PASSWORD is set
cat backend\.env | Select-String "DB_PASSWORD"

# Should show: DB_PASSWORD=postgres
# If empty, set it and restart backend
```

#### If connection fails:

```powershell
# Check if containers are running
docker ps

# If not running, start them
docker start smartpepper-postgres smartpepper-redis

# Test connection manually
docker exec -it smartpepper-postgres psql -U postgres -c "SELECT version();"
```

#### Clear and reset database:

```powershell
# WARNING: This deletes all data!
cd backend
node src/db/migratePostgres.js  # Recreate tables
node src/db/seed.js             # Re-add sample data
```

---

### 11. Quick Status Check Script

Create a file `check-db.ps1`:

```powershell
Write-Host "=== SmartPepper Database Status ===" -ForegroundColor Green

# Check containers
Write-Host "`nDocker Containers:" -ForegroundColor Yellow
docker ps --filter name=smartpepper --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Check database connection
Write-Host "`nDatabase Tables:" -ForegroundColor Yellow
docker exec smartpepper-postgres psql -U postgres -d smartpepper -c "\dt" 2>$null

# Count records
Write-Host "`nRecord Counts:" -ForegroundColor Yellow
docker exec smartpepper-postgres psql -U postgres -d smartpepper -c "SELECT
  (SELECT COUNT(*) FROM auctions) as auctions,
  (SELECT COUNT(*) FROM pepper_lots) as lots,
  (SELECT COUNT(*) FROM users) as users,
  (SELECT COUNT(*) FROM bids) as bids;" 2>$null

# Check backend API
Write-Host "`nBackend API Status:" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3002/health" -TimeoutSec 2
    $response.Content
} catch {
    Write-Host "Backend not responding" -ForegroundColor Red
}
```

Run it:

```powershell
.\check-db.ps1
```

---

## 🎯 Quick Reference Commands

| Task              | Command                                                                                                |
| ----------------- | ------------------------------------------------------------------------------------------------------ |
| View all auctions | `docker exec smartpepper-postgres psql -U postgres -d smartpepper -c "SELECT * FROM auctions;"`        |
| Connect to DB     | `docker exec -it smartpepper-postgres psql -U postgres -d smartpepper`                                 |
| Check containers  | `docker ps --filter name=smartpepper`                                                                  |
| View backend logs | Check terminal where `npm run dev` is running                                                          |
| Test API          | `curl http://localhost:3002/api/auctions`                                                              |
| Count records     | `docker exec smartpepper-postgres psql -U postgres -d smartpepper -c "SELECT COUNT(*) FROM auctions;"` |

---

**Your database is live and accessible! 🎉**
