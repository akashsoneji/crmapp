# 🏗️ Flutter Flavor Builder (PowerShell)
Write-Host "🏗️ Flutter Flavor Builder" -ForegroundColor Cyan
Write-Host "=======================" -ForegroundColor Cyan

param(
    [Parameter(Position=0)]
    [ValidateSet("pipze", "octa", "fleza")]
    [string]$Flavor = "pipze",
    
    [Parameter(Position=1)]
    [ValidateSet("aab", "apk")]
    [string]$BuildType = "aab"
)

Write-Host "🎯 Building $Flavor $BuildType..." -ForegroundColor Yellow

switch ($BuildType.ToLower()) {
    "aab" {
        Write-Host "📦 Building Android App Bundle (AAB) for $Flavor..." -ForegroundColor Green
        flutter build appbundle --flavor $Flavor --release
    }
    "apk" {
        Write-Host "📱 Building APK for $Flavor..." -ForegroundColor Green
        flutter build apk --flavor $Flavor --release
    }
}

Write-Host "`n✅ Build completed!" -ForegroundColor Green
Write-Host "📁 Check build/app/outputs/ folder for your files" -ForegroundColor Cyan

Write-Host "`n💡 Usage Examples:" -ForegroundColor Cyan
Write-Host "  .\build_flavor.ps1 pipze aab   - Build Pipze AAB" -ForegroundColor White
Write-Host "  .\build_flavor.ps1 octa apk    - Build Octa APK" -ForegroundColor White
Write-Host "  .\build_flavor.ps1 fleza aab   - Build Fleza AAB" -ForegroundColor White
