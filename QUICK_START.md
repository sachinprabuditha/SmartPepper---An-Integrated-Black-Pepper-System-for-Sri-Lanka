# 🚀 Quick Start Guide - SmartPepper

## ✅ What's Done

- ✅ Node.js installed (v24.11.1)
- ✅ All npm dependencies installed (blockchain, backend, web)
- ✅ Smart contract compiled
- ✅ Configuration files created

## 📋 What You Need to Do

### Option A: Using Docker (Recommended - Easiest!)

**1. Start Docker Desktop**

- Open Docker Desktop application
- Wait for it to say "Docker is running"

**2. Start Database Services**

```powershell
# Start PostgreSQL
docker run -d --name smartpepper-postgres `
  -e POSTGRES_PASSWORD=postgres `
  -e POSTGRES_DB=smartpepper `
  -p 5432:5432 postgres:14

# Start Redis
docker run -d --name smartpepper-redis `
  -p 6379:6379 redis:7-alpine

# Verify they're running
docker ps
```

**3. Configure Backend**

The `backend\.env` file already exists. Make sure it has:

```
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/smartpepper
REDIS_URL=redis://localhost:6379
```

**4. Run Database Migrations**

```powershell
cd backend
node scripts/migrate.js
```

### Option B: Without Docker (Windows Native)

**1. Install PostgreSQL**

```powershell
# Using Chocolatey
choco install postgresql

# Or download installer from:
# https://www.postgresql.org/download/windows/

# After install, create database:
psql -U postgres
CREATE DATABASE smartpepper;
\q
```

**2. Install Redis**

```powershell
# Using Chocolatey
choco install redis-64

# Start Redis
redis-server
```

**3. Same as Docker: Configure backend/.env and run migrations**

## 🎯 Run the System

Once PostgreSQL and Redis are running:

### Terminal 1: Blockchain

```powershell
cd blockchain
npm run node
```

Wait for: "Started HTTP and WebSocket JSON-RPC server at http://127.0.0.1:8545/"

### Terminal 2: Deploy Contract

```powershell
cd blockchain
npm run deploy:local
```

Copy the contract address that appears!

### Terminal 3: Update Contract Address

Edit these files with the deployed address:

**backend\.env:**

```
CONTRACT_ADDRESS=0xYourContractAddressHere
```

**web\.env.local:**

```
NEXT_PUBLIC_CONTRACT_ADDRESS=0xYourContractAddressHere
```

### Terminal 4: Backend

```powershell
cd backend
npm run dev
```

### Terminal 5: Web Dashboard

```powershell
cd web
npm run dev
```

## 🌐 Access the App

Open your browser: **http://localhost:3001**

## 🔧 If Something Goes Wrong

**Docker not working?**

- Make sure Docker Desktop is running (check system tray)
- Try restarting Docker Desktop

**PostgreSQL connection error?**

```powershell
# Check if container is running
docker ps

# Check logs
docker logs smartpepper-postgres

# Restart container
docker restart smartpepper-postgres
```

**Redis connection error?**

```powershell
# Check if container is running
docker ps

# Restart container
docker restart smartpepper-redis
```

**Can't connect wallet?**

- Install MetaMask extension
- Add "Hardhat Local" network:
  - RPC: http://127.0.0.1:8545
  - Chain ID: 31337
- Import test account:
  - Private key: `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80`

## 📞 Need Help?

Run this to check your system:

```powershell
.\setup-check.ps1
```

---

**Ready to test?** Start Docker Desktop, then follow the steps above! 🌶️
