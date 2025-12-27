# PowerShell script to add test certifications and compliance checks to a lot

param(
    [Parameter(Mandatory=$true)]
    [string]$LotId
)

$backend = "http://192.168.8.116:3002"

Write-Host "Adding test traceability data for lot: $LotId" -ForegroundColor Cyan
Write-Host ""

# 1. Add certifications
Write-Host "1. Adding certifications..." -ForegroundColor Yellow

$certs = @(
    @{
        lotId = $LotId
        certType = "organic"
        certNumber = "ORG-2025-001"
        issuer = "Sri Lanka Organic Certification"
        issueDate = "2025-01-15"
        expiryDate = "2026-01-15"
        documentHash = "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
        ipfsUrl = "ipfs://QmTest123..."
    },
    @{
        lotId = $LotId
        certType = "fumigation"
        certNumber = "FUM-2025-001"
        issuer = "Export Authority"
        issueDate = "2025-12-01"
        expiryDate = "2026-12-01"
        documentHash = "0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"
        ipfsUrl = "ipfs://QmTest456..."
    },
    @{
        lotId = $LotId
        certType = "quality"
        certNumber = "QUAL-2025-001"
        issuer = "Quality Assurance Board"
        issueDate = "2025-11-20"
        expiryDate = "2026-11-20"
        documentHash = "0x7890abcdef1234567890abcdef1234567890abcdef1234567890abcdef123456"
        ipfsUrl = "ipfs://QmTest789..."
    }
)

foreach ($cert in $certs) {
    try {
        $response = Invoke-RestMethod -Uri "$backend/api/certifications" -Method Post -Body ($cert | ConvertTo-Json) -ContentType "application/json"
        Write-Host "  ✓ Added $($cert.certType) certificate: $($cert.certNumber)" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ Failed to add $($cert.certType) certificate: $_" -ForegroundColor Red
    }
}

Write-Host ""

# 2. Run compliance check
Write-Host "2. Running compliance check..." -ForegroundColor Yellow

try {
    $complianceBody = @{ destination = "EU" } | ConvertTo-Json
    $response = Invoke-RestMethod -Uri "$backend/api/compliance/check/$LotId" -Method Post -Body $complianceBody -ContentType "application/json"
    
    if ($response.success) {
        Write-Host "  ✓ Compliance check completed: $($response.complianceStatus)" -ForegroundColor Green
        Write-Host "  - Total checks: $($response.results.Count)" -ForegroundColor Gray
        Write-Host "  - Passed: $($response.passedCount)" -ForegroundColor Gray
        Write-Host "  - Failed: $($response.failedCount)" -ForegroundColor Gray
    } else {
        Write-Host "  ✗ Compliance check failed: $($response.error)" -ForegroundColor Red
    }
} catch {
    Write-Host "  ✗ Failed to run compliance check: $_" -ForegroundColor Red
}

Write-Host ""

# 3. Verify data was added
Write-Host "3. Verifying traceability data..." -ForegroundColor Yellow

try {
    $traceability = Invoke-RestMethod -Uri "$backend/api/traceability/$LotId" -Method Get
    
    if ($traceability.success) {
        $certCount = $traceability.certifications.Count
        $complianceCount = $traceability.compliance_checks.Count
        
        Write-Host "  ✓ Traceability data loaded" -ForegroundColor Green
        Write-Host "  - Certifications: $certCount" -ForegroundColor Gray
        Write-Host "  - Compliance checks: $complianceCount" -ForegroundColor Gray
        Write-Host "  - Compliance status: $($traceability.current_status.compliance_status)" -ForegroundColor Gray
    } else {
        Write-Host "  ✗ Failed to load traceability: $($traceability.error)" -ForegroundColor Red
    }
} catch {
    Write-Host "  ✗ Failed to verify traceability: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "Done! You can now view the full traceability in the app." -ForegroundColor Green
Write-Host ""
Write-Host "Access traceability at:" -ForegroundColor Cyan
Write-Host "  Web:    http://localhost:3000/traceability/$LotId" -ForegroundColor White
Write-Host "  Mobile: Navigate to lot details and click Full Traceability" -ForegroundColor White
