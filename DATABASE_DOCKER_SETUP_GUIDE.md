# 🐳 Step-by-Step Database Setup with Docker

## PostgreSQL + Redis for SmartPepper Research Project

> **Purpose**: Complete guide to set up PostgreSQL and Redis using Docker for a fresh device  
> **Time Required**: 15-20 minutes  
> **Difficulty**: Beginner-friendly

---

## 📋 Prerequisites Checklist

Before starting, ensure you have:

- [ ] Computer with Windows 10/11, macOS, or Linux
- [ ] Administrator/sudo access
- [ ] Stable internet connection
- [ ] At least 2GB free disk space
- [ ] SmartPepper project cloned from repository

---

## 🎯 What You'll Set Up

This guide will install and configure:

✅ **Docker Desktop** - Container platform  
✅ **PostgreSQL 14** - Main database (Port 5432)  
✅ **Redis 7** - Cache/session storage (Port 6379)  
✅ **pgAdmin** - Web-based database management UI  
✅ **Redis Commander** - Web-based Redis management UI  
✅ **IPFS Node** - Distributed file storage (Optional)

---

## Step 1: Install Docker Desktop

### Windows 10/11

**1.1 Download Docker Desktop**

```powershell
# Open PowerShell as Administrator and run:
# (Or download manually from https://www.docker.com/products/docker-desktop/)

# Using Chocolatey (if installed):
choco install docker-desktop

# Or using Winget:
winget install Docker.DockerDesktop
```

**Manual Download:**

1. Visit: https://www.docker.com/products/docker-desktop/
2. Click "Download for Windows"
3. Run the installer (Docker Desktop Installer.exe)
4. Follow installation wizard
5. **Restart your computer** when prompted

**1.2 Enable WSL 2 (Windows Subsystem for Linux)**

Docker Desktop requires WSL 2 on Windows:

```powershell
# Open PowerShell as Administrator
wsl --install

# If already installed, update to WSL 2:
wsl --set-default-version 2

# Restart computer
```

**1.3 Start Docker Desktop**

1. Search for "Docker Desktop" in Start Menu
2. Launch the application
3. Accept the service agreement
4. Wait for Docker Engine to start (whale icon in system tray)
5. You should see "Docker Desktop is running" notification

---

### macOS

**1.1 Download and Install**

```bash
# Using Homebrew (recommended):
brew install --cask docker

# Or download manually from:
# https://www.docker.com/products/docker-desktop/
```

**Manual Installation:**

1. Download Docker.dmg
2. Drag Docker to Applications folder
3. Open Docker from Applications
4. Grant permissions when prompted
5. Wait for Docker to start

**1.2 Verify Docker is Running**

Look for the Docker whale icon in the menu bar (top-right).

---

### Linux (Ubuntu/Debian)

**1.1 Install Docker Engine**

```bash
# Update package index
sudo apt update

# Install prerequisites
sudo apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add your user to docker group (to run without sudo)
sudo usermod -aG docker $USER

# Log out and log back in for group changes to take effect
```

---

## Step 2: Verify Docker Installation

Open a new terminal/PowerShell window and run:

```powershell
# Check Docker version
docker --version
# Expected output: Docker version 24.x.x, build...

# Check Docker Compose version
docker-compose --version
# Expected output: Docker Compose version v2.x.x

# Test Docker is working
docker run hello-world
```

**Expected Output:**

```
Hello from Docker!
This message shows that your installation appears to be working correctly.
...
```

✅ **If you see "Hello from Docker!", proceed to next step!**

❌ **If you see errors:**

- Windows: Restart Docker Desktop from system tray
- macOS: Check Docker Desktop is running in menu bar
- Linux: Run `sudo systemctl status docker` to check service

---

## Step 3: Navigate to Project Directory

```powershell
# Open terminal/PowerShell
# Navigate to your SmartPepper project

# Windows example:
cd D:\Campus\Research\SmartPepper\SmartPepper-Auction-Blockchain-System

# macOS/Linux example:
cd ~/Projects/SmartPepper-Auction-Blockchain-System

# Verify you're in correct directory
dir  # Windows
ls   # macOS/Linux

# You should see: docker-compose.yml file
```

---

## Step 4: Understand Docker Configuration

**4.1 View the docker-compose.yml file:**

```powershell
# Windows
notepad docker-compose.yml

# macOS/Linux
cat docker-compose.yml
```

**What's Inside:**

```yaml
services:
  postgres: # PostgreSQL database
    - Port: 5432
    - Username: smartpepper
    - Password: smartpepper2024
    - Database: smartpepper

  redis: # Redis cache
    - Port: 6379
    - Password: smartpepper2024

  ipfs: # IPFS node (optional)
    - API Port: 5001
    - Gateway: 8080

  pgadmin: # Database UI
    - Port: 5050
    - Email: admin@smartpepper.com
    - Password: smartpepper2024
```

**🔑 Remember these credentials - you'll need them later!**

---

## Step 5: Start Database Services

**5.1 Start PostgreSQL and Redis Only (Recommended for beginners)**

```powershell
# Start just the core database services
docker-compose up -d postgres redis

# Wait 10-15 seconds for services to initialize
```

**5.2 Start All Services Including Management UIs**

```powershell
# Start everything including pgAdmin and Redis Commander
docker-compose --profile tools up -d

# This starts:
# - PostgreSQL
# - Redis
# - IPFS
# - pgAdmin (database UI)
# - Redis Commander (Redis UI)
```

**Expected Output:**

```
[+] Running 5/5
 ✔ Network smartpepper-auction-blockchain-system_smartpepper-network  Created
 ✔ Volume "smartpepper-auction-blockchain-system_postgres_data"      Created
 ✔ Volume "smartpepper-auction-blockchain-system_redis_data"         Created
 ✔ Container smartpepper-postgres                                     Started
 ✔ Container smartpepper-redis                                        Started
```

---

## Step 6: Verify Services Are Running

**6.1 Check Container Status**

```powershell
docker-compose ps
```

**Expected Output:**

```
NAME                    IMAGE               STATUS          PORTS
smartpepper-postgres    postgres:14-alpine  Up 2 minutes    0.0.0.0:5432->5432/tcp
smartpepper-redis       redis:7-alpine      Up 2 minutes    0.0.0.0:6379->6379/tcp
```

✅ **STATUS should show "Up" for all services**

**6.2 Check Container Logs**

```powershell
# View PostgreSQL logs
docker-compose logs postgres

# View Redis logs
docker-compose logs redis

# View all logs (live updates)
docker-compose logs -f
# Press Ctrl+C to exit log view
```

**6.3 Check Container Health**

```powershell
# Check if containers are healthy
docker ps

# You should see "healthy" in STATUS column
```

---

## Step 7: Test PostgreSQL Connection

**7.1 Connect to PostgreSQL Using Docker**

```powershell
# Method 1: Connect using docker exec
docker exec -it smartpepper-postgres psql -U smartpepper -d smartpepper

# You should see:
# psql (14.x)
# Type "help" for help.
# smartpepper=#
```

**7.2 Test Database Inside PostgreSQL**

```sql
-- Check PostgreSQL version
SELECT version();

-- List databases
\l

-- You should see "smartpepper" database

-- List tables (should be empty initially)
\dt

-- Exit PostgreSQL
\q
```

**7.3 Test Connection from Host Machine**

If you have `psql` installed locally:

```powershell
# Connect from host machine
psql -h localhost -U smartpepper -d smartpepper

# When prompted for password, enter: smartpepper2024
```

✅ **If you can connect and see the prompt, PostgreSQL is working!**

---

## Step 8: Create Database Tables

**8.1 Check if create-tables.sql Exists**

```powershell
# Navigate to backend directory
cd backend

# Windows
dir create-tables.sql

# macOS/Linux
ls -l create-tables.sql
```

**8.2 Import Database Schema**

**Method 1: Using Docker (Recommended)**

```powershell
# Make sure you're in project root directory
cd ..

# Import SQL file into PostgreSQL container
docker exec -i smartpepper-postgres psql -U smartpepper -d smartpepper < backend/create-tables.sql
```

**Method 2: Using psql on Host**

```powershell
psql -h localhost -U smartpepper -d smartpepper -f backend/create-tables.sql
# Password: smartpepper2024
```

**8.3 Verify Tables Were Created**

```powershell
# Connect to database
docker exec -it smartpepper-postgres psql -U smartpepper -d smartpepper

# List all tables
\dt

# You should see:
# - users
# - pepper_lots
# - auctions
# - bids
# - transactions

# View structure of a table
\d pepper_lots

# Exit
\q
```

**8.4 Run Additional Migrations**

```powershell
# Navigate to backend
cd backend

# Run blockchain transaction hash column migration
node add-blockchain-tx-hash-column.js
```

**Expected Output:**

```
Adding blockchain_tx_hash column to pepper_lots table...
✅ Column added to pepper_lots!
Adding blockchain_tx_hash column to bids table...
✅ Column added to bids!
✅ Verified: pepper_lots.blockchain_tx_hash exists
✅ Verified: bids.blockchain_tx_hash exists
```

---

## Step 9: Test Redis Connection

**9.1 Connect to Redis Using Docker**

```powershell
# Connect to Redis CLI with authentication
docker exec -it smartpepper-redis redis-cli -a smartpepper2024
```

**Expected Output:**

```
Warning: Using a password with '-a' or '-u' option on the command line interface may not be safe.
127.0.0.1:6379>
```

**9.2 Test Redis Commands**

```redis
# Test connection
PING
# Should return: PONG

# Set a test key
SET test "Hello SmartPepper"
# Should return: OK

# Get the test key
GET test
# Should return: "Hello SmartPepper"

# Delete the test key
DEL test
# Should return: (integer) 1

# Exit Redis CLI
EXIT
```

**9.3 Test Redis from Host Machine**

If you have `redis-cli` installed locally:

```powershell
redis-cli -h localhost -p 6379 -a smartpepper2024 PING
# Should return: PONG
```

✅ **If you see "PONG", Redis is working perfectly!**

---

## Step 10: Access Management UIs (Optional)

### pgAdmin (PostgreSQL Database UI)

**10.1 Open pgAdmin in Browser**

```
URL: http://localhost:5050
```

**10.2 Login to pgAdmin**

```
Email:    admin@smartpepper.com
Password: smartpepper2024
```

**10.3 Add PostgreSQL Server**

1. Click "Add New Server"
2. **General Tab**:
   - Name: `SmartPepper Database`
3. **Connection Tab**:
   - Host name: `postgres` (or `host.docker.internal` on Windows/Mac)
   - Port: `5432`
   - Database: `smartpepper`
   - Username: `smartpepper`
   - Password: `smartpepper2024`
4. Click "Save"

**10.4 Browse Database**

1. Expand "SmartPepper Database" in left sidebar
2. Expand "Databases" → "smartpepper"
3. Expand "Schemas" → "public"
4. Expand "Tables"
5. Right-click any table → "View/Edit Data" → "All Rows"

---

### Redis Commander (Redis UI)

**10.1 Open Redis Commander in Browser**

```
URL: http://localhost:8081
```

**No login required** - connects automatically to Redis

**10.2 Test Redis Commander**

1. You should see Redis server connected
2. Click "Add Key"
3. Set: Key = `test`, Value = `Hello SmartPepper`
4. Click "Save"
5. You should see the key appear in the list

---

## Step 11: Configure Backend to Use Docker Databases

**11.1 Navigate to Backend Directory**

```powershell
cd backend
```

**11.2 Create/Update .env File**

```powershell
# Windows
copy .env.example .env
notepad .env

# macOS/Linux
cp .env.example .env
nano .env
```

**11.3 Update Database Configuration**

```env
# ============================================
# Database Configuration (Docker)
# ============================================

DB_HOST=localhost
DB_PORT=5432
DB_NAME=smartpepper
DB_USER=smartpepper
DB_PASSWORD=smartpepper2024

# ============================================
# Redis Configuration (Docker)
# ============================================

REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=smartpepper2024

# ============================================
# IPFS Configuration (Docker - Optional)
# ============================================

IPFS_API_URL=http://localhost:5001
IPFS_GATEWAY_URL=http://localhost:8080
```

**11.4 Save and Close the File**

---

## Step 12: Test Backend Connection

**12.1 Install Backend Dependencies**

```powershell
# Make sure you're in backend directory
cd backend

# Install Node.js packages
npm install
```

**12.2 Test Database Connection**

Create a test file: `test-db-connection.js`

```javascript
const { Pool } = require("pg");

const pool = new Pool({
  host: "localhost",
  port: 5432,
  database: "smartpepper",
  user: "smartpepper",
  password: "smartpepper2024",
});

async function testConnection() {
  try {
    const result = await pool.query("SELECT NOW()");
    console.log("✅ PostgreSQL Connected Successfully!");
    console.log("Current Time:", result.rows[0].now);

    const tables = await pool.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
    `);
    console.log("\n📋 Available Tables:");
    tables.rows.forEach((row) => console.log("  -", row.table_name));

    await pool.end();
  } catch (error) {
    console.error("❌ Connection Error:", error.message);
  }
}

testConnection();
```

**Run the test:**

```powershell
node test-db-connection.js
```

**Expected Output:**

```
✅ PostgreSQL Connected Successfully!
Current Time: 2026-01-08T10:30:45.123Z

📋 Available Tables:
  - users
  - pepper_lots
  - auctions
  - bids
  - transactions
```

**12.3 Test Redis Connection**

Create a test file: `test-redis-connection.js`

```javascript
const redis = require("redis");

async function testRedis() {
  const client = redis.createClient({
    socket: {
      host: "localhost",
      port: 6379,
    },
    password: "smartpepper2024",
  });

  client.on("error", (err) => {
    console.error("❌ Redis Error:", err);
  });

  try {
    await client.connect();
    console.log("✅ Redis Connected Successfully!");

    await client.set("test_key", "Hello from SmartPepper!");
    const value = await client.get("test_key");
    console.log("Test Value:", value);

    await client.del("test_key");
    console.log("✅ Redis is working perfectly!");

    await client.disconnect();
  } catch (error) {
    console.error("❌ Connection Error:", error.message);
  }
}

testRedis();
```

**Run the test:**

```powershell
node test-redis-connection.js
```

**Expected Output:**

```
✅ Redis Connected Successfully!
Test Value: Hello from SmartPepper!
✅ Redis is working perfectly!
```

---

## Step 13: Common Commands Reference

### Daily Use Commands

**Start Services (when you begin work)**

```powershell
docker-compose up -d
```

**Stop Services (when you finish work)**

```powershell
docker-compose down
```

**Restart Services**

```powershell
docker-compose restart
```

**View Logs**

```powershell
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f postgres
docker-compose logs -f redis
```

**Check Status**

```powershell
docker-compose ps
```

---

## 🔧 Troubleshooting

### Issue 1: "Cannot connect to Docker daemon"

**Windows:**

```powershell
# Open Docker Desktop from Start Menu
# Wait for Docker Engine to start (whale icon in system tray)
```

**Linux:**

```bash
# Start Docker service
sudo systemctl start docker

# Check status
sudo systemctl status docker
```

---

### Issue 2: Port Already in Use

**Error:** `Bind for 0.0.0.0:5432 failed: port is already allocated`

**Solution:**

```powershell
# Check what's using port 5432
netstat -ano | findstr :5432

# Option A: Stop the other service
# Option B: Change port in docker-compose.yml

# Edit docker-compose.yml:
services:
  postgres:
    ports:
      - "5433:5432"  # Use 5433 on host, 5432 in container

# Update backend/.env:
DB_PORT=5433
```

---

### Issue 3: Permission Denied

**Linux:**

```bash
# Add your user to docker group
sudo usermod -aG docker $USER

# Log out and log back in
# Or run: newgrp docker
```

---

### Issue 4: Container Keeps Restarting

```powershell
# Check container logs
docker-compose logs postgres

# Common causes:
# - Port conflict
# - Insufficient memory
# - Corrupted data volume

# Solution: Reset everything
docker-compose down -v
docker-compose up -d
```

---

### Issue 5: Cannot Connect to Database

**Check 1: Is container running?**

```powershell
docker-compose ps
# postgres should show "Up"
```

**Check 2: Is PostgreSQL ready?**

```powershell
docker exec -it smartpepper-postgres pg_isready
# Should return: accepting connections
```

**Check 3: Are credentials correct?**

```
Username: smartpepper
Password: smartpepper2024
Database: smartpepper
Host: localhost
Port: 5432
```

**Check 4: Test connection manually**

```powershell
docker exec -it smartpepper-postgres psql -U smartpepper -d smartpepper
```

---

### Issue 6: Redis Authentication Error

**Error:** `NOAUTH Authentication required`

**Solution:**

```powershell
# Always use password with Redis
docker exec -it smartpepper-redis redis-cli -a smartpepper2024

# In backend/.env, ensure:
REDIS_PASSWORD=smartpepper2024
```

---

### Issue 7: Data Loss After Restart

**Problem:** Tables/data disappear after stopping Docker

**Cause:** Using `docker-compose down -v` (deletes volumes)

**Solution:**

```powershell
# DON'T use -v flag unless you want to delete data
docker-compose down       # Keeps data ✅
docker-compose down -v    # Deletes data ❌

# To keep data, always use:
docker-compose down
docker-compose up -d
```

---

## Step 14: Verify Complete Setup

Run this checklist to confirm everything works:

```powershell
# ✅ Docker is running
docker --version

# ✅ Containers are up
docker-compose ps
# Should show: postgres (Up), redis (Up)

# ✅ PostgreSQL is accessible
docker exec -it smartpepper-postgres psql -U smartpepper -d smartpepper -c "SELECT 1;"
# Should return: 1

# ✅ Redis is accessible
docker exec -it smartpepper-redis redis-cli -a smartpepper2024 PING
# Should return: PONG

# ✅ Tables exist
docker exec -it smartpepper-postgres psql -U smartpepper -d smartpepper -c "\dt"
# Should list: users, pepper_lots, auctions, bids, etc.

# ✅ Backend can connect
cd backend
node test-db-connection.js
# Should show: ✅ PostgreSQL Connected Successfully!
```

---

## 🎉 Success! What's Next?

Your database environment is now set up! Next steps:

1. **Start Blockchain Node**

   ```powershell
   cd blockchain
   npm run node
   ```

2. **Deploy Smart Contracts**

   ```powershell
   npm run deploy:local
   ```

3. **Start Backend Server**

   ```powershell
   cd backend
   npm run dev
   ```

4. **Start Web Frontend**
   ```powershell
   cd web
   npm run dev
   ```

---

## 📚 Additional Resources

- **Docker Documentation**: https://docs.docker.com/
- **PostgreSQL Docs**: https://www.postgresql.org/docs/
- **Redis Docs**: https://redis.io/docs/
- **SmartPepper Setup Guide**: [SETUP_GUIDE.md](SETUP_GUIDE.md)
- **Docker Setup Reference**: [DOCKER_SETUP.md](DOCKER_SETUP.md)
- **Credentials Reference**: [CREDENTIALS_REFERENCE.md](CREDENTIALS_REFERENCE.md)

---

## 🔒 Security Notes

⚠️ **IMPORTANT:** These credentials are for development only!

For production deployment:

1. Change all passwords in `docker-compose.yml`
2. Use strong, unique passwords (20+ characters)
3. Enable SSL/TLS connections
4. Restrict network access
5. Use environment variables from secure vault
6. Enable PostgreSQL SSL mode
7. Configure Redis in protected mode

---

## 📞 Need Help?

If you encounter issues:

1. Check the [Troubleshooting](#-troubleshooting) section above
2. View container logs: `docker-compose logs -f`
3. Check Docker Desktop is running
4. Verify ports 5432 and 6379 are free
5. Restart Docker Desktop
6. Consult [DOCKER_SETUP.md](DOCKER_SETUP.md) for advanced configuration

---

**Last Updated**: January 8, 2026  
**Version**: 1.0.0  
**Tested On**: Windows 11, macOS Ventura, Ubuntu 22.04

---

✅ **Database setup complete! You're ready to start developing!** 🚀
