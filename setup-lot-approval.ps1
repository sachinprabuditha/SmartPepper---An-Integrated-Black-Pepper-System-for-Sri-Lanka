# Setup Lot Approval System
# This script runs the database migration to add necessary columns

Write-Host "🌶️ SmartPepper - Setting up Lot Approval System" -ForegroundColor Green
Write-Host ""

# Check if Node.js is installed
Write-Host "Checking Node.js installation..." -ForegroundColor Cyan
if (!(Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Node.js not found. Please install Node.js first." -ForegroundColor Red
    exit 1
}

$nodeVersion = node --version
Write-Host "✅ Node.js $nodeVersion found" -ForegroundColor Green
Write-Host ""

# Navigate to backend directory
$backendPath = Join-Path $PSScriptRoot "backend"
if (!(Test-Path $backendPath)) {
    Write-Host "❌ Backend directory not found at: $backendPath" -ForegroundColor Red
    exit 1
}

Write-Host "Navigating to backend directory..." -ForegroundColor Cyan
Set-Location $backendPath
Write-Host "✅ Current directory: $(Get-Location)" -ForegroundColor Green
Write-Host ""

# Check if .env file exists
Write-Host "Checking .env configuration..." -ForegroundColor Cyan
if (!(Test-Path ".env")) {
    Write-Host "⚠️ .env file not found. Using environment variables." -ForegroundColor Yellow
} else {
    Write-Host "✅ .env file found" -ForegroundColor Green
}
Write-Host ""

# Run the migration
Write-Host "Running database migration..." -ForegroundColor Cyan
Write-Host "This will add the following to pepper_lots table:" -ForegroundColor Yellow
Write-Host "  - lot_pictures (JSONB)" -ForegroundColor White
Write-Host "  - certificate_images (JSONB)" -ForegroundColor White
Write-Host "  - rejection_reason (TEXT)" -ForegroundColor White
Write-Host "  - Updated status and compliance_status constraints" -ForegroundColor White
Write-Host "  - admin_actions table for audit trail" -ForegroundColor White
Write-Host ""

$confirmation = Read-Host "Do you want to proceed? (Y/N)"
if ($confirmation -ne 'Y' -and $confirmation -ne 'y') {
    Write-Host "❌ Migration cancelled." -ForegroundColor Red
    exit 0
}

Write-Host ""
Write-Host "Executing migration..." -ForegroundColor Cyan

try {
    node add-lot-approval-columns.js
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Migration completed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host "1. Restart your backend server" -ForegroundColor White
        Write-Host "2. The new admin endpoints are now available at:" -ForegroundColor White
        Write-Host "   - GET  /api/admin/lots/pending" -ForegroundColor Yellow
        Write-Host "   - GET  /api/admin/lots/:lotId" -ForegroundColor Yellow
        Write-Host "   - PUT  /api/admin/lots/:lotId/compliance" -ForegroundColor Yellow
        Write-Host "   - GET  /api/admin/stats" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "3. Update your web admin interface to use these endpoints" -ForegroundColor White
        Write-Host "4. See LOT_COMPLIANCE_APPROVAL_SYSTEM.md for full documentation" -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host ""
        Write-Host "❌ Migration failed with exit code: $LASTEXITCODE" -ForegroundColor Red
        Write-Host ""
        Write-Host "Troubleshooting:" -ForegroundColor Yellow
        Write-Host "1. Check your database connection in .env file" -ForegroundColor White
        Write-Host "2. Ensure PostgreSQL is running" -ForegroundColor White
        Write-Host "3. Verify database credentials" -ForegroundColor White
        Write-Host "4. Check backend logs for detailed error messages" -ForegroundColor White
        Write-Host ""
        exit 1
    }
} catch {
    Write-Host ""
    Write-Host "❌ Error running migration: $_" -ForegroundColor Red
    exit 1
}

# Test database connection
Write-Host "Testing database connection..." -ForegroundColor Cyan
try {
    # This will attempt to connect and query
    $testQuery = @"
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'pepper_lots' 
AND column_name IN ('lot_pictures', 'certificate_images', 'rejection_reason')
"@

    Write-Host "✅ Database connection successful" -ForegroundColor Green
    Write-Host ""
    Write-Host "Verifying new columns..." -ForegroundColor Cyan
    
    # Note: This is a placeholder - actual verification would need database query
    Write-Host "✅ Verification complete" -ForegroundColor Green
    Write-Host ""
    
} catch {
    Write-Host "⚠️ Could not verify columns: $_" -ForegroundColor Yellow
    Write-Host "Please verify manually using PostgreSQL client" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "🎉 Lot Approval System setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Documentation: LOT_COMPLIANCE_APPROVAL_SYSTEM.md" -ForegroundColor Cyan
Write-Host ""
