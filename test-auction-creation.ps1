# Quick Test Script - Auction Creation Feature

Write-Host "=== SmartPepper Auction Creation - Quick Test ===" -ForegroundColor Cyan
Write-Host ""

# Check if all services are running
Write-Host "Checking Services Status..." -ForegroundColor Yellow
Write-Host ""

# 1. Check Frontend
Write-Host "1. Frontend (Next.js):" -NoNewline
try {
    $frontend = Invoke-WebRequest -Uri "http://localhost:3001" -UseBasicParsing -TimeoutSec 5
    Write-Host " ✓ Running on port 3001" -ForegroundColor Green
} catch {
    Write-Host " ✗ NOT running" -ForegroundColor Red
}

# 2. Check Backend
Write-Host "2. Backend API:" -NoNewline
try {
    $backend = Invoke-WebRequest -Uri "http://localhost:3002/api/auctions" -UseBasicParsing -TimeoutSec 5
    Write-Host " ✓ Running on port 3002" -ForegroundColor Green
} catch {
    Write-Host " ✗ NOT running" -ForegroundColor Red
}

# 3. Check Blockchain
Write-Host "3. Hardhat Node:" -NoNewline
try {
    $blockchain = Invoke-WebRequest -Uri "http://localhost:8545" -Method POST -Body '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' -ContentType "application/json" -UseBasicParsing -TimeoutSec 5
    Write-Host " ✓ Running on port 8545" -ForegroundColor Green
} catch {
    Write-Host " ✗ NOT running" -ForegroundColor Red
}

# 4. Check PostgreSQL
Write-Host "4. PostgreSQL:" -NoNewline
try {
    $postgres = docker ps --filter "name=smartpepper-postgres" --format "{{.Status}}"
    if ($postgres -match "Up") {
        Write-Host " ✓ Container running" -ForegroundColor Green
    } else {
        Write-Host " ✗ Container not running" -ForegroundColor Red
    }
} catch {
    Write-Host " ✗ Docker not accessible" -ForegroundColor Red
}

# 5. Check Redis
Write-Host "5. Redis:" -NoNewline
try {
    $redis = docker ps --filter "name=smartpepper-redis" --format "{{.Status}}"
    if ($redis -match "Up") {
        Write-Host " ✓ Container running" -ForegroundColor Green
    } else {
        Write-Host " ✗ Container not running" -ForegroundColor Red
    }
} catch {
    Write-Host " ✗ Docker not accessible" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Configuration Check ===" -ForegroundColor Cyan
Write-Host ""

# Check .env.local
if (Test-Path "web\.env.local") {
    Write-Host "Frontend .env.local:" -ForegroundColor Yellow
    $envContent = Get-Content "web\.env.local"
    $contractAddress = $envContent | Select-String "NEXT_PUBLIC_CONTRACT_ADDRESS"
    $rpcUrl = $envContent | Select-String "NEXT_PUBLIC_RPC_URL"
    Write-Host "  Contract: $contractAddress" -ForegroundColor Gray
    Write-Host "  RPC URL: $rpcUrl" -ForegroundColor Gray
} else {
    Write-Host "⚠ web\.env.local not found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Test Instructions ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "To test auction creation:" -ForegroundColor White
Write-Host "1. Open browser: http://localhost:3001/create" -ForegroundColor White
Write-Host "2. Connect MetaMask wallet" -ForegroundColor White
Write-Host "3. Fill in lot details and create" -ForegroundColor White
Write-Host "4. Configure auction settings and create" -ForegroundColor White
Write-Host ""
Write-Host "MetaMask Setup:" -ForegroundColor Yellow
Write-Host "  Network: Hardhat Local" -ForegroundColor Gray
Write-Host "  RPC URL: http://127.0.0.1:8545" -ForegroundColor Gray
Write-Host "  Chain ID: 31337" -ForegroundColor Gray
Write-Host "  Test Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80" -ForegroundColor Gray
Write-Host ""
Write-Host "Documentation:" -ForegroundColor Yellow
Write-Host "  See AUCTION_CREATION_GUIDE.md for detailed instructions" -ForegroundColor Gray
Write-Host "  See AUCTION_CREATION_COMPLETE.md for implementation details" -ForegroundColor Gray
Write-Host ""
