# 🎨 Flutter Flavor Runner (PowerShell)
Write-Host "🎨 Flutter Flavor Runner" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan

param(
    [Parameter(Position=0)]
    [ValidateSet("pipze", "octa", "fleza", "onsa")]
    [string]$Flavor = "pipze"
)

switch ($Flavor.ToLower()) {
    "pipze" {
        Write-Host "🟣 Running Pipze (Purple Theme)..." -ForegroundColor Magenta
        flutter run -t lib/main_pipze.dart
    }
    "octa" {
        Write-Host "🟠 Running Octa (Orange Theme)..." -ForegroundColor Yellow
        flutter run -t lib/main_octa.dart
    }
    "fleza" {
        Write-Host "🟢 Running Fleza (Green Theme)..." -ForegroundColor Green
        flutter run -t lib/main_fleza.dart
    }
    "onsa" {
        Write-Host "🔵 Running ONSA (Blue Theme)..." -ForegroundColor Cyan
        flutter run -t lib/main_onsa.dart
    }
}

Write-Host "`n💡 Usage Examples:" -ForegroundColor Cyan
Write-Host "  .\run_flavor.ps1 pipze  - Run Pipze (Purple)" -ForegroundColor White
Write-Host "  .\run_flavor.ps1 octa   - Run Octa (Orange)" -ForegroundColor White
Write-Host "  .\run_flavor.ps1 fleza  - Run Fleza (Green)" -ForegroundColor White
Write-Host "  .\run_flavor.ps1 onsa   - Run ONSA (Blue)" -ForegroundColor White
