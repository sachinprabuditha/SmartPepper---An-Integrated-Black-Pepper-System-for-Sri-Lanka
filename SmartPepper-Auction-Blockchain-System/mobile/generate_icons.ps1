# Generate App Icons Script
Write-Host "🎨 Generating SmartPepper App Icons..." -ForegroundColor Green

# Navigate to mobile directory
Set-Location $PSScriptRoot

# Install flutter_launcher_icons if not already installed
Write-Host "`n📦 Installing flutter_launcher_icons..." -ForegroundColor Cyan
flutter pub get

# Generate icons
Write-Host "`n🔨 Generating launcher icons..." -ForegroundColor Cyan
flutter pub run flutter_launcher_icons

Write-Host "`n✅ App icons generated successfully!" -ForegroundColor Green
Write-Host "📱 App name changed to: SmartPepper" -ForegroundColor Green
Write-Host "`n⚠️  Next steps:" -ForegroundColor Yellow
Write-Host "   1. Clean the build: flutter clean" -ForegroundColor White
Write-Host "   2. Rebuild the app: flutter run" -ForegroundColor White
Write-Host "   3. Uninstall old app from device if needed" -ForegroundColor White
Write-Host "`n🚀 Ready to launch!" -ForegroundColor Green
