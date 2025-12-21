# SmartPepper Test User Creation Script
# Creates test users for mobile app development

Write-Host "`n=== SmartPepper Test User Creation ===" -ForegroundColor Cyan
Write-Host "Creating test users for mobile development...`n" -ForegroundColor White

# Test users to create
$users = @(
    @{
        email="farmer@smartpepper.com"
        password="Farmer123!"
        name="Test Farmer"
        role="farmer"
        phone="+94771234567"
    },
    @{
        email="exporter@smartpepper.com"
        password="Exporter123!"
        name="Test Exporter"
        role="exporter"
        phone="+94771234568"
    },
    @{
        email="admin@smartpepper.com"
        password="Admin123!"
        name="Test Admin"
        role="admin"
        phone="+94771234569"
    }
)

$baseUrl = "http://localhost:3002"
$successCount = 0
$failCount = 0

# Check if backend is running
Write-Host "Checking backend status..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/users" -Method Get -TimeoutSec 3 -ErrorAction Stop
    Write-Host "[OK] Backend is running!" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Backend is not responding at $baseUrl" -ForegroundColor Red
    Write-Host "  Please start the backend first with: cd backend; npm start" -ForegroundColor Yellow
    exit 1
}

Write-Host "`nCreating users..." -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

foreach ($user in $users) {
    $body = $user | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod `
            -Uri "$baseUrl/api/auth/register" `
            -Method Post `
            -Body $body `
            -ContentType "application/json" `
            -ErrorAction Stop
        
        Write-Host "[SUCCESS] Created: $($user.email)" -ForegroundColor Green
        Write-Host "  Name: $($user.name)" -ForegroundColor Gray
        Write-Host "  Role: $($user.role)" -ForegroundColor Gray
        Write-Host "  Password: $($user.password)" -ForegroundColor Gray
        Write-Host ""
        $successCount++
        
    } catch {
        $errorMessage = $_.Exception.Message
        
        # Check if user already exists
        if ($errorMessage -like "*already registered*" -or $errorMessage -like "*409*") {
            Write-Host "[EXISTS] Already exists: $($user.email)" -ForegroundColor Yellow
            Write-Host "  You can use: $($user.password)" -ForegroundColor Gray
        } else {
            Write-Host "[FAILED] Failed: $($user.email)" -ForegroundColor Red
            Write-Host "  Error: $errorMessage" -ForegroundColor Red
            $failCount++
        }
        Write-Host ""
    }
}

Write-Host "----------------------------------------" -ForegroundColor Gray
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Successfully created: $successCount users" -ForegroundColor Green
if ($failCount -gt 0) {
    Write-Host "Failed: $failCount users" -ForegroundColor Red
}

Write-Host "`n=== Test Credentials ===" -ForegroundColor Cyan
Write-Host "Use these credentials in your mobile app:`n" -ForegroundColor White

Write-Host "Farmer Account:" -ForegroundColor Green
Write-Host "  Email: farmer@smartpepper.com"
Write-Host "  Password: Farmer123!"
Write-Host ""

Write-Host "Exporter Account:" -ForegroundColor Magenta
Write-Host "  Email: exporter@smartpepper.com"
Write-Host "  Password: Exporter123!"
Write-Host ""

Write-Host "Admin Account:" -ForegroundColor Blue
Write-Host "  Email: admin@smartpepper.com"
Write-Host "  Password: Admin123!"
Write-Host ""

# List all users
Write-Host "=== All Users in Database ===" -ForegroundColor Cyan
try {
    $allUsers = Invoke-RestMethod -Uri "$baseUrl/api/users" -Method Get
    
    if ($allUsers.users.Count -gt 0) {
        Write-Host "Total users: $($allUsers.users.Count)`n" -ForegroundColor White
        
        foreach ($u in $allUsers.users) {
            $roleColor = switch ($u.role) {
                "farmer" { "Green" }
                "exporter" { "Magenta" }
                "buyer" { "Blue" }
                "admin" { "Cyan" }
                "regulator" { "Yellow" }
                default { "White" }
            }
            
            Write-Host "- $($u.email)" -ForegroundColor $roleColor -NoNewline
            Write-Host " - $($u.role)" -ForegroundColor Gray -NoNewline
            if ($u.name) {
                Write-Host " ($($u.name))" -ForegroundColor DarkGray
            } else {
                Write-Host ""
            }
        }
    } else {
        Write-Host "No users found in database" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Could not retrieve users list" -ForegroundColor Red
}

Write-Host "`n=== Next Steps ===" -ForegroundColor Cyan
Write-Host "1. Open your mobile app (Flutter)" -ForegroundColor White
Write-Host "2. Navigate to Login screen" -ForegroundColor White
Write-Host "3. Enter one of the test credentials above" -ForegroundColor White
Write-Host "4. Login and start testing!" -ForegroundColor White

Write-Host "`n=== Quick Test Login ===" -ForegroundColor Cyan
Write-Host "Test login with cURL:" -ForegroundColor White
Write-Host 'curl http://localhost:3002/api/auth/login -Method POST -Body ''{"email":"farmer@smartpepper.com","password":"Farmer123!"}'' -ContentType "application/json"' -ForegroundColor Gray

Write-Host "`nSetup complete!`n" -ForegroundColor Green
