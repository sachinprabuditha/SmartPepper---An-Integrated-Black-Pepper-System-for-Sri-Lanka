# Test IPFS Connection

Write-Host "`n=== Testing IPFS Accessibility ===" -ForegroundColor Cyan

# Test 1: Localhost
Write-Host "`n1. Testing localhost (127.0.0.1)..." -ForegroundColor Yellow
try {
    $response = curl.exe -X POST "http://127.0.0.1:5001/api/v0/version"
    Write-Host "✅ Localhost works: $response" -ForegroundColor Green
} catch {
    Write-Host "❌ Localhost failed: $_" -ForegroundColor Red
}

# Test 2: Network IP
Write-Host "`n2. Testing network IP (192.168.8.116)..." -ForegroundColor Yellow
try {
    $response = curl.exe -X POST "http://192.168.8.116:5001/api/v0/version"
    Write-Host "✅ Network IP works: $response" -ForegroundColor Green
} catch {
    Write-Host "❌ Network IP failed: $_" -ForegroundColor Red
}

# Test 3: Check IPFS config
Write-Host "`n3. Checking IPFS API configuration..." -ForegroundColor Yellow
$apiConfig = ipfs config Addresses.API
Write-Host "API Address: $apiConfig"
if ($apiConfig -like "*0.0.0.0*") {
    Write-Host "✅ IPFS is configured to accept network connections" -ForegroundColor Green
} else {
    Write-Host "⚠️  IPFS may only accept localhost connections" -ForegroundColor Yellow
    Write-Host "   Run: ipfs config Addresses.API /ip4/0.0.0.0/tcp/5001" -ForegroundColor Cyan
}

# Test 4: Check firewall
Write-Host "`n4. Checking Windows Firewall..." -ForegroundColor Yellow
$firewallRule = Get-NetFirewallRule -DisplayName "IPFS API" -ErrorAction SilentlyContinue
if ($firewallRule) {
    Write-Host "✅ Firewall rule 'IPFS API' exists" -ForegroundColor Green
} else {
    Write-Host "⚠️  Firewall rule 'IPFS API' not found" -ForegroundColor Yellow
    Write-Host "   Run as Administrator:" -ForegroundColor Cyan
    Write-Host "   New-NetFirewallRule -DisplayName 'IPFS API' -Direction Inbound -LocalPort 5001 -Protocol TCP -Action Allow" -ForegroundColor Gray
}

# Test 5: Check IPFS daemon status
Write-Host "`n5. Checking if IPFS daemon is running..." -ForegroundColor Yellow
$ipfsProcess = Get-Process -Name "ipfs" -ErrorAction SilentlyContinue
if ($ipfsProcess) {
    Write-Host "✅ IPFS daemon is running (PID: $($ipfsProcess.Id))" -ForegroundColor Green
} else {
    Write-Host "❌ IPFS daemon is NOT running" -ForegroundColor Red
    Write-Host "   Run: ipfs daemon" -ForegroundColor Cyan
}

# Test 6: Test file upload
Write-Host "`n6. Testing file upload..." -ForegroundColor Yellow
try {
    $testFile = "$env:TEMP\ipfs_test.txt"
    "Hello from SmartPepper" | Out-File -FilePath $testFile -Encoding UTF8
    
    $uploadResponse = ipfs add $testFile 2>&1
    if ($uploadResponse -match "added\s+(\w+)") {
        $hash = $Matches[1]
        Write-Host "✅ File upload works! Hash: $hash" -ForegroundColor Green
        
        # Test gateway
        $gatewayUrl = "http://192.168.8.116:8080/ipfs/$hash"
        Write-Host "   Gateway URL: $gatewayUrl" -ForegroundColor Cyan
    } else {
        Write-Host "⚠️  File upload response: $uploadResponse" -ForegroundColor Yellow
    }
    
    Remove-Item $testFile -ErrorAction SilentlyContinue
} catch {
    Write-Host "❌ File upload failed: $_" -ForegroundColor Red
}

# Summary
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "IPFS API URL: http://192.168.8.116:5001" -ForegroundColor White
Write-Host "IPFS Gateway: http://192.168.8.116:8080" -ForegroundColor White
Write-Host "`nFor mobile app to work:" -ForegroundColor Yellow
Write-Host "1. IPFS daemon must be running (ipfs daemon)" -ForegroundColor White
Write-Host "2. Firewall must allow port 5001" -ForegroundColor White
Write-Host "3. Mobile device must be on same Wi-Fi network" -ForegroundColor White
Write-Host "4. Test from mobile browser: http://192.168.8.116:5001/webui" -ForegroundColor White

Write-Host "`nPress any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
