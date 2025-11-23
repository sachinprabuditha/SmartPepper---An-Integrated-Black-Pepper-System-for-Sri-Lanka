Write-Host "=== SmartPepper Database Status ===" -ForegroundColor Green

# Check containers
Write-Host "`n📦 Docker Containers:" -ForegroundColor Yellow
docker ps --filter name=smartpepper --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Check database connection
Write-Host "`n📋 Database Tables:" -ForegroundColor Yellow
docker exec smartpepper-postgres psql -U postgres -d smartpepper -c "\dt" 2>$null

# Count records
Write-Host "`n📊 Record Counts:" -ForegroundColor Yellow
docker exec smartpepper-postgres psql -U postgres -d smartpepper -c "SELECT 
  (SELECT COUNT(*) FROM auctions) as auctions,
  (SELECT COUNT(*) FROM pepper_lots) as lots,
  (SELECT COUNT(*) FROM users) as users,
  (SELECT COUNT(*) FROM bids) as bids;" 2>$null

# Check backend API
Write-Host "`n🌐 Backend API Status:" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3002/api/auctions" -TimeoutSec 2
    $data = $response.Content | ConvertFrom-Json
    Write-Host "✅ API responding - $($data.Count) auctions found" -ForegroundColor Green
} catch {
    Write-Host "❌ Backend not responding on port 3002" -ForegroundColor Red
}

# Check frontend
Write-Host "`n💻 Frontend Status:" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3001" -TimeoutSec 2
    Write-Host "✅ Frontend responding on port 3001" -ForegroundColor Green
} catch {
    Write-Host "❌ Frontend not responding on port 3001" -ForegroundColor Red
}

# Check blockchain
Write-Host "`n⛓️  Blockchain Status:" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://127.0.0.1:8545" -Method POST -Body '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' -ContentType "application/json" -TimeoutSec 2
    Write-Host "✅ Hardhat node responding on port 8545" -ForegroundColor Green
} catch {
    Write-Host "❌ Hardhat node not responding on port 8545" -ForegroundColor Red
}

Write-Host "`n===============================================" -ForegroundColor Green
