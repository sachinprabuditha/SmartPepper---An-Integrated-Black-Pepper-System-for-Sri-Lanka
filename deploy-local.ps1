# Deploy SmartPepper Contract to Local Blockchain
# Run this AFTER starting the local blockchain (start-local-blockchain.ps1)

Write-Host "🌶️ SmartPepper Contract Deployment" -ForegroundColor Green
Write-Host "===================================`n" -ForegroundColor Green

$blockchainPath = "D:\Campus\Research\SmartPepper\SmartPepper-Auction-Blockchain-System\blockchain"

# Check if blockchain folder exists
if (-not (Test-Path $blockchainPath)) {
    Write-Host "❌ Error: Blockchain folder not found at $blockchainPath" -ForegroundColor Red
    exit 1
}

Write-Host "⚠️  Make sure the local blockchain is running!" -ForegroundColor Yellow
Write-Host "   (Run start-local-blockchain.ps1 in another terminal)`n" -ForegroundColor Yellow

$continue = Read-Host "Is the blockchain running? (y/n)"
if ($continue -ne "y") {
    Write-Host "❌ Start the blockchain first, then run this script again." -ForegroundColor Red
    exit 1
}

Write-Host "`n⚡ Deploying PepperAuction contract to localhost..." -ForegroundColor Cyan

Set-Location $blockchainPath
npx hardhat run scripts/deploy.js --network localhost

Write-Host "`n✅ Deployment complete!" -ForegroundColor Green
Write-Host "📋 Copy the contract address above and update:" -ForegroundColor Yellow
Write-Host "   web/src/config/contracts.ts" -ForegroundColor White
Write-Host "`n💡 Next steps:" -ForegroundColor Cyan
Write-Host "1. Update CONTRACT_ADDRESS in web/src/config/contracts.ts" -ForegroundColor White
Write-Host "2. Add Hardhat Local network to MetaMask (Chain ID: 1337)" -ForegroundColor White
Write-Host "3. Import a test account to MetaMask using private key" -ForegroundColor White
Write-Host "4. Start testing! 🎉`n" -ForegroundColor White
