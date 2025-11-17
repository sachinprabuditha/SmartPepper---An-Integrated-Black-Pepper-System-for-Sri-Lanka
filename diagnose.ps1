# SmartPepper - System Diagnostic and Fix Script
# This script checks all prerequisites and helps you fix issues

Write-Host "`n=== SmartPepper System Diagnostic ===" -ForegroundColor Cyan
Write-Host "Checking all prerequisites...`n" -ForegroundColor Yellow

# Fix PATH for this session
$env:Path += ";C:\Program Files\nodejs"

# 1. Check Node.js and npm
Write-Host "[1/7] Checking Node.js..." -NoNewline
try {
    $nodeVersion = node --version 2>&1
    $npmVersion = npm --version 2>&1
    Write-Host " OK ($nodeVersion, npm $npmVersion)" -ForegroundColor Green
    $nodeOk = $true
} catch {
    Write-Host " FAILED" -ForegroundColor Red
    Write-Host "  Fix: Install from https://nodejs.org/" -ForegroundColor Yellow
    $nodeOk = $false
}

# 2. Check if dependencies are installed
Write-Host "[2/7] Checking npm packages..." -NoNewline
$allInstalled = $true
$folders = @("blockchain", "backend", "web")
foreach ($folder in $folders) {
    if (-not (Test-Path "$folder\node_modules")) {
        Write-Host " MISSING ($folder)" -ForegroundColor Red
        Write-Host "  Fix: cd $folder; npm install" -ForegroundColor Yellow
        $allInstalled = $false
    }
}
if ($allInstalled) {
    Write-Host " OK (all 3 projects)" -ForegroundColor Green
}

# 3. Check PostgreSQL
Write-Host "[3/7] Checking PostgreSQL..." -NoNewline
$pgOk = $false
try {
    # Try to connect via Docker
    $dockerPg = docker ps --filter "name=smartpepper-postgres" --format "{{.Names}}" 2>$null
    if ($dockerPg -eq "smartpepper-postgres") {
        Write-Host " OK (Docker)" -ForegroundColor Green
        $pgOk = $true
    } else {
        # Try native PostgreSQL
        $pgTest = Test-NetConnection -ComputerName localhost -Port 5432 -WarningAction SilentlyContinue
        if ($pgTest.TcpTestSucceeded) {
            Write-Host " OK (localhost:5432)" -ForegroundColor Green
            $pgOk = $true
        } else {
            throw "Not running"
        }
    }
} catch {
    Write-Host " NOT RUNNING" -ForegroundColor Red
    Write-Host "  Fix Option 1 (Docker): docker run -d --name smartpepper-postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=smartpepper -p 5432:5432 postgres:14" -ForegroundColor Yellow
    Write-Host "  Fix Option 2 (Native): Install PostgreSQL and start service" -ForegroundColor Yellow
}

# 4. Check Redis
Write-Host "[4/7] Checking Redis..." -NoNewline
$redisOk = $false
try {
    # Try Docker
    $dockerRedis = docker ps --filter "name=smartpepper-redis" --format "{{.Names}}" 2>$null
    if ($dockerRedis -eq "smartpepper-redis") {
        Write-Host " OK (Docker)" -ForegroundColor Green
        $redisOk = $true
    } else {
        # Try native Redis
        $redisTest = Test-NetConnection -ComputerName localhost -Port 6379 -WarningAction SilentlyContinue
        if ($redisTest.TcpTestSucceeded) {
            Write-Host " OK (localhost:6379)" -ForegroundColor Green
            $redisOk = $true
        } else {
            throw "Not running"
        }
    }
} catch {
    Write-Host " NOT RUNNING" -ForegroundColor Red
    Write-Host "  Fix Option 1 (Docker): docker run -d --name smartpepper-redis -p 6379:6379 redis:7-alpine" -ForegroundColor Yellow
    Write-Host "  Fix Option 2 (Native): Install Redis and start service" -ForegroundColor Yellow
}

# 5. Check Docker
Write-Host "[5/7] Checking Docker..." -NoNewline
try {
    $dockerVersion = docker --version 2>&1
    if ($dockerVersion -match "Docker version") {
        Write-Host " OK" -ForegroundColor Green
        $dockerOk = $true
    } else {
        throw "Not found"
    }
} catch {
    Write-Host " NOT INSTALLED" -ForegroundColor Yellow
    Write-Host "  Note: Docker is optional but recommended for easy database setup" -ForegroundColor Gray
    $dockerOk = $false
}

# 6. Check .env files
Write-Host "[6/7] Checking .env files..." -NoNewline
$envFiles = @(
    @{Path="blockchain\.env"; Template="blockchain\.env.example"},
    @{Path="backend\.env"; Template="backend\.env.example"},
    @{Path="web\.env.local"; Template="web\.env.example"}
)
$envOk = $true
foreach ($env in $envFiles) {
    if (-not (Test-Path $env.Path)) {
        if ($envOk) { Write-Host "" }
        Write-Host "  MISSING: $($env.Path)" -ForegroundColor Red
        Write-Host "  Fix: Copy-Item $($env.Template) $($env.Path)" -ForegroundColor Yellow
        $envOk = $false
    }
}
if ($envOk) {
    Write-Host " OK" -ForegroundColor Green
}

# 7. Check if database is migrated
Write-Host "[7/7] Checking database setup..." -NoNewline
if ($pgOk -and (Test-Path "backend\.env")) {
    Write-Host " NEEDS MIGRATION" -ForegroundColor Yellow
    Write-Host "  Fix: cd backend; node src\db\migrate.js" -ForegroundColor Yellow
} else {
    Write-Host " SKIPPED (need PostgreSQL first)" -ForegroundColor Gray
}

# Summary
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
$issues = @()
if (-not $nodeOk) { $issues += "Node.js not installed" }
if (-not $allInstalled) { $issues += "npm packages not installed" }
if (-not $pgOk) { $issues += "PostgreSQL not running" }
if (-not $redisOk) { $issues += "Redis not running" }
if (-not $envOk) { $issues += ".env files missing" }

if ($issues.Count -eq 0) {
    Write-Host "All checks passed! Ready to run." -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "  1. cd backend; node src\db\migrate.js" -ForegroundColor White
    Write-Host "  2. cd blockchain; npm run node" -ForegroundColor White
    Write-Host "  3. cd blockchain; npm run deploy:local" -ForegroundColor White
    Write-Host "  4. Update .env files with contract address" -ForegroundColor White
    Write-Host "  5. cd backend; npm run dev" -ForegroundColor White
    Write-Host "  6. cd web; npm run dev" -ForegroundColor White
} else {
    Write-Host "Found $($issues.Count) issue(s):" -ForegroundColor Red
    foreach ($issue in $issues) {
        Write-Host "  - $issue" -ForegroundColor Yellow
    }
    Write-Host "`nFix the issues above and run this script again." -ForegroundColor Cyan
}

Write-Host "`n=== Quick Fix Commands ===" -ForegroundColor Cyan
if ($dockerOk -and -not $pgOk) {
    Write-Host "Start PostgreSQL:" -ForegroundColor Yellow
    Write-Host "  docker run -d --name smartpepper-postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=smartpepper -p 5432:5432 postgres:14" -ForegroundColor White
}
if ($dockerOk -and -not $redisOk) {
    Write-Host "Start Redis:" -ForegroundColor Yellow
    Write-Host "  docker run -d --name smartpepper-redis -p 6379:6379 redis:7-alpine" -ForegroundColor White
}

Write-Host ""
