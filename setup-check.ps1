# SmartPepper Quick Setup Script
# Run this in PowerShell to check and guide setup

Write-Host "`n🌶️ SmartPepper System Check`n" -ForegroundColor Green

# Check Node.js
Write-Host "Checking Node.js..." -NoNewline
try {
    $nodeVersion = node --version
    $npmVersion = npm --version
    Write-Host " ✅ Node $nodeVersion, npm $npmVersion" -ForegroundColor Green
} catch {
    Write-Host " ❌ Not installed" -ForegroundColor Red
    Write-Host "Install from: https://nodejs.org/" -ForegroundColor Yellow
}

# Check PostgreSQL
Write-Host "Checking PostgreSQL..." -NoNewline
try {
    $pgVersion = & pg_config --version 2>$null
    Write-Host " ✅ $pgVersion" -ForegroundColor Green
} catch {
    Write-Host " ⚠️ Not found" -ForegroundColor Yellow
    Write-Host "  Option 1: choco install postgresql" -ForegroundColor Cyan
    Write-Host "  Option 2: docker run -d --name smartpepper-postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=smartpepper -p 5432:5432 postgres:14" -ForegroundColor Cyan
}

# Check Redis
Write-Host "Checking Redis..." -NoNewline
try {
    $redisCheck = redis-cli ping 2>$null
    if ($redisCheck -eq "PONG") {
        Write-Host " ✅ Running" -ForegroundColor Green
    } else {
        throw "Not running"
    }
} catch {
    Write-Host " ⚠️ Not running" -ForegroundColor Yellow
    Write-Host "  Option 1: redis-server (if installed)" -ForegroundColor Cyan
    Write-Host "  Option 2: docker run -d --name smartpepper-redis -p 6379:6379 redis:7-alpine" -ForegroundColor Cyan
}

# Check Docker
Write-Host "Checking Docker..." -NoNewline
try {
    $dockerVersion = docker --version 2>$null
    Write-Host " ✅ $dockerVersion" -ForegroundColor Green
    Write-Host "`n💡 Tip: Use Docker for PostgreSQL + Redis (easier on Windows):" -ForegroundColor Cyan
    Write-Host "   docker run -d --name smartpepper-postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=smartpepper -p 5432:5432 postgres:14" -ForegroundColor Gray
    Write-Host "   docker run -d --name smartpepper-redis -p 6379:6379 redis:7-alpine" -ForegroundColor Gray
} catch {
    Write-Host " ⚠️ Not installed" -ForegroundColor Yellow
    Write-Host "  Install Docker Desktop: https://www.docker.com/products/docker-desktop/" -ForegroundColor Cyan
}

# Check if .env files exist
Write-Host "`nChecking configuration files..." -ForegroundColor Yellow
$envFiles = @(
    "blockchain\.env",
    "backend\.env",
    "web\.env.local"
)

foreach ($file in $envFiles) {
    if (Test-Path $file) {
        Write-Host "  ✅ $file" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $file missing" -ForegroundColor Red
    }
}

# Check if dependencies are installed
Write-Host "`nChecking npm dependencies..." -ForegroundColor Yellow
$modules = @(
    @{Path="blockchain\node_modules"; Name="Blockchain"},
    @{Path="backend\node_modules"; Name="Backend"},
    @{Path="web\node_modules"; Name="Web"}
)

foreach ($module in $modules) {
    if (Test-Path $module.Path) {
        Write-Host "  ✅ $($module.Name) dependencies installed" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $($module.Name) dependencies missing (run: cd $($module.Path -replace '\\node_modules',''); npm install)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Green
Write-Host "1. Install PostgreSQL + Redis (or use Docker commands above)" -ForegroundColor White
Write-Host "2. Update backend\.env with database credentials" -ForegroundColor White
Write-Host "3. Run: cd backend; node scripts\migrate.js" -ForegroundColor White
Write-Host "4. Start system (see INSTALLATION_COMPLETE.md)" -ForegroundColor White
Write-Host ""
Write-Host "For full guide, open: INSTALLATION_COMPLETE.md" -ForegroundColor Cyan
Write-Host ""
