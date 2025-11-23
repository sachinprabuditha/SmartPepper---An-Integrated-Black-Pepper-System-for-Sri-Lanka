Write-Host "=== SmartPepper Auction Creation Test ===" -ForegroundColor Cyan
Write-Host ""

# Check Frontend
Write-Host "Checking Frontend..." -NoNewline
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3001" -UseBasicParsing -TimeoutSec 3
    Write-Host " OK (Port 3001)" -ForegroundColor Green
} catch {
    Write-Host " FAILED" -ForegroundColor Red
}

# Check Backend
Write-Host "Checking Backend API..." -NoNewline
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3002/api/auctions" -UseBasicParsing -TimeoutSec 3
    Write-Host " OK (Port 3002)" -ForegroundColor Green
} catch {
    Write-Host " FAILED" -ForegroundColor Red
}

# Check Blockchain
Write-Host "Checking Hardhat Node..." -NoNewline
try {
    $body = '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
    $response = Invoke-WebRequest -Uri "http://localhost:8545" -Method POST -Body $body -ContentType "application/json" -UseBasicParsing -TimeoutSec 3
    Write-Host " OK (Port 8545)" -ForegroundColor Green
} catch {
    Write-Host " FAILED" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Next Steps ===" -ForegroundColor Cyan
Write-Host "1. Open: http://localhost:3001/create" -ForegroundColor White
Write-Host "2. Connect MetaMask wallet" -ForegroundColor White
Write-Host "3. Create auction with test data" -ForegroundColor White
Write-Host ""
Write-Host "See AUCTION_CREATION_GUIDE.md for details" -ForegroundColor Yellow
Write-Host ""
