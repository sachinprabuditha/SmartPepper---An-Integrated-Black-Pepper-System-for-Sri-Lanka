# Quick Setup Script for Firebase Disease Integration
# Run this in PowerShell from the SmartPepper-Auction-Blockchain-System folder

Write-Host "🌿 SmartPepper Firebase Disease Integration Setup" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green
Write-Host ""

# Step 1: Install node_backend dependencies
Write-Host "Step 1: Installing node_backend dependencies..." -ForegroundColor Cyan
Set-Location node_backend
npm install
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Dependencies installed successfully" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 2: Check for Firebase configuration
Write-Host "Step 2: Checking Firebase configuration..." -ForegroundColor Cyan
if (Test-Path .env) {
    Write-Host "✅ .env file found" -ForegroundColor Green
    $env_content = Get-Content .env -Raw
    if ($env_content -match "FIREBASE_PROJECT_ID|FIREBASE_SERVICE_ACCOUNT") {
        Write-Host "✅ Firebase configuration detected" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Firebase variables not set in .env" -ForegroundColor Yellow
        Write-Host "   Server will use in-memory storage (data lost on restart)" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️  No .env file found" -ForegroundColor Yellow
    Write-Host "   Creating .env from template..." -ForegroundColor Yellow
    
    # Check if backend/.env exists
    if (Test-Path ..\backend\.env) {
        Write-Host "   Copying configuration from backend folder..." -ForegroundColor Cyan
        Copy-Item ..\backend\.env .env
        Write-Host "✅ Configuration copied from backend" -ForegroundColor Green
    } else {
        Copy-Item .env.example .env
        Write-Host "⚠️  Please configure Firebase in .env file" -ForegroundColor Yellow
        Write-Host "   See FIREBASE_DISEASE_INTEGRATION.md for instructions" -ForegroundColor Yellow
    }
}
Write-Host ""

# Step 3: Get IP Address
Write-Host "Step 3: Getting your IP address..." -ForegroundColor Cyan
$ipAddress = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -like "*Wi-Fi*" -or $_.InterfaceAlias -like "*Ethernet*"} | Select-Object -First 1).IPAddress
if ($ipAddress) {
    Write-Host "✅ Your IP address: $ipAddress" -ForegroundColor Green
    Write-Host ""
    Write-Host "📱 Mobile App Configuration:" -ForegroundColor Cyan
    Write-Host "   Update this line in mobile/lib/services/disease_api_service.dart:" -ForegroundColor Yellow
    Write-Host "   static const String diseaseApiBaseUrl = 'http://${ipAddress}:5000';" -ForegroundColor White
} else {
    Write-Host "⚠️  Could not detect IP address automatically" -ForegroundColor Yellow
    Write-Host "   Run 'ipconfig' to find your IPv4 Address" -ForegroundColor Yellow
}
Write-Host ""

# Step 4: Start server
Write-Host "Step 4: Starting disease detection server..." -ForegroundColor Cyan
Write-Host "   Server will start on port 5000" -ForegroundColor Yellow
Write-Host "   Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

npm start
