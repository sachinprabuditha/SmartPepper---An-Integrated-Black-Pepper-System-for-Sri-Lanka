# 🚨 Why You Can't Run SmartPepper

## ❌ Current Issues Found

1. **PostgreSQL** - Not running (needed for database)
2. **Redis** - Not running (needed for real-time caching)

## ✅ How to Fix (Choose One Option)

### Option A: Using Docker (EASIEST! - Recommended)

#### Step 1: Start Docker Desktop
1. Open **Docker Desktop** application
2. Wait for it to show "Docker is running" (green icon in system tray)
3. This might take 1-2 minutes

#### Step 2: Start Services
Once Docker is running, open PowerShell and run:

```powershell
# Start PostgreSQL
docker run -d --name smartpepper-postgres `
  -e POSTGRES_PASSWORD=postgres `
  -e POSTGRES_DB=smartpepper `
  -p 5432:5432 postgres:14

# Start Redis  
docker run -d --name smartpepper-redis `
  -p 6379:6379 redis:7-alpine

# Verify both are running
docker ps
```

You should see both containers listed!

#### Step 3: Setup Database
```powershell
cd backend
node src\db\migrate.js
```

---

### Option B: Without Docker (Windows Native)

#### Install PostgreSQL
```powershell
# Using Chocolatey (if you have it)
choco install postgresql

# Or download installer from:
# https://www.postgresql.org/download/windows/
```

After installation:
```powershell
# Create database
psql -U postgres
CREATE DATABASE smartpepper;
\q
```

#### Install Redis
```powershell
# Using Chocolatey
choco install redis-64

# Start Redis
redis-server
```

#### Setup Database
```powershell
cd backend
node src\db\migrate.js
```

---

## 🚀 After Services Are Running

Run this to verify everything is ready:
```powershell
.\diagnose.ps1
```

You should see: **"All checks passed! Ready to run."**

Then follow these steps:

### Terminal 1: Start Blockchain
```powershell
cd blockchain
npm run node
```

### Terminal 2: Deploy Contract
```powershell
cd blockchain  
npm run deploy:local
```
**Copy the contract address that appears!**

### Terminal 3: Update .env Files

Edit `backend\.env`:
```
CONTRACT_ADDRESS=0xYourContractAddressFromAbove
```

Edit `web\.env.local`:
```
NEXT_PUBLIC_CONTRACT_ADDRESS=0xYourContractAddressFromAbove
```

### Terminal 4: Start Backend
```powershell
cd backend
npm run dev
```

### Terminal 5: Start Web Dashboard
```powershell
cd web
npm run dev
```

## 🌐 Access the App

Open browser: **http://localhost:3001**

---

## 💡 Quick Troubleshooting

**Docker not working?**
- Make sure Docker Desktop is **running** (green icon in system tray)
- Try restarting Docker Desktop
- Check if virtualization is enabled in BIOS

**Still stuck?**
Run the diagnostic script:
```powershell
.\diagnose.ps1
```

It will tell you exactly what's missing!

---

## 📋 TL;DR (Too Long; Didn't Read)

**Why it's not working:** You need PostgreSQL and Redis running

**Fastest fix:** 
1. Start Docker Desktop
2. Run the 2 docker commands above
3. Run `.\diagnose.ps1` to verify
4. Follow the "After Services Are Running" steps

That's it! 🎉
