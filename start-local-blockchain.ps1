# SmartPepper Local Testing Setup
# This script helps you start the local blockchain and deploy contracts

Write-Host "🌶️ SmartPepper Local Blockchain Setup" -ForegroundColor Green
Write-Host "======================================`n" -ForegroundColor Green

$blockchainPath = "D:\Campus\Research\SmartPepper\SmartPepper-Auction-Blockchain-System\blockchain"

# Check if blockchain folder exists
if (-not (Test-Path $blockchainPath)) {
    Write-Host "❌ Error: Blockchain folder not found at $blockchainPath" -ForegroundColor Red
    exit 1
}

Write-Host "📋 Instructions:" -ForegroundColor Cyan
Write-Host "1. This will start a local Hardhat blockchain" -ForegroundColor White
Write-Host "2. You'll get 20 accounts with 10,000 ETH each (FREE!)" -ForegroundColor White
Write-Host "3. Keep this window open while testing" -ForegroundColor White
Write-Host "4. Import one of the private keys to MetaMask`n" -ForegroundColor White

Write-Host "🔧 MetaMask Setup:" -ForegroundColor Cyan
Write-Host "Network Name: Hardhat Local" -ForegroundColor White
Write-Host "RPC URL: http://127.0.0.1:8545" -ForegroundColor White
Write-Host "Chain ID: 1337" -ForegroundColor White
Write-Host "Currency: ETH`n" -ForegroundColor White

Write-Host "⚡ Starting local blockchain..." -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop`n" -ForegroundColor Yellow

Set-Location $blockchainPath
npx hardhat node
