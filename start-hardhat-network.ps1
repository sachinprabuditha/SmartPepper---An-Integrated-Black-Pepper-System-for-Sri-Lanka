# SmartPepper - Start Hardhat Network for Mobile Access
# This script starts Hardhat with network binding and firewall configuration

Write-Host "🚀 Starting Hardhat Blockchain Node..." -ForegroundColor Cyan
Write-Host ""

# Check if running as administrator for firewall rule
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    Write-Host "✅ Running with administrator privileges" -ForegroundColor Green
    
    # Add firewall rule for Hardhat port 8545
    $ruleName = "Hardhat Blockchain Port 8545"
    $existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
    
    if ($existingRule) {
        Write-Host "✅ Firewall rule already exists: $ruleName" -ForegroundColor Green
    } else {
        Write-Host "⚙️  Creating firewall rule..." -ForegroundColor Yellow
        New-NetFirewallRule -DisplayName $ruleName `
                            -Direction Inbound `
                            -LocalPort 8545 `
                            -Protocol TCP `
                            -Action Allow `
                            -Profile Any `
                            -Enabled True | Out-Null
        Write-Host "✅ Firewall rule created successfully" -ForegroundColor Green
    }
} else {
    Write-Host "⚠️  Not running as administrator - firewall rule may not be created" -ForegroundColor Yellow
    Write-Host "   If connection fails, run PowerShell as Administrator and execute:" -ForegroundColor Yellow
    Write-Host "   New-NetFirewallRule -DisplayName 'Hardhat Blockchain Port 8545' -Direction Inbound -LocalPort 8545 -Protocol TCP -Action Allow" -ForegroundColor Gray
}

Write-Host ""
Write-Host "📡 Network Configuration:" -ForegroundColor Cyan

# Get local IP address
$localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "192.168.*"}).IPAddress
if ($localIP) {
    Write-Host "   Local IP: $localIP" -ForegroundColor White
    Write-Host "   Mobile app should use: http://${localIP}:8545" -ForegroundColor White
} else {
    Write-Host "   Could not detect local IP address" -ForegroundColor Red
}

Write-Host ""
Write-Host "🔗 Starting Hardhat node on 0.0.0.0:8545..." -ForegroundColor Cyan
Write-Host "   Press Ctrl+C to stop" -ForegroundColor Gray
Write-Host ""

# Change to blockchain directory and start Hardhat
Set-Location -Path (Join-Path $PSScriptRoot "blockchain")
npx hardhat node --hostname 0.0.0.0
