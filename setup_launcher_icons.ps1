# PowerShell script to setup launcher icon directories for all flavors

Write-Host "================================================"
Write-Host "Setting up launcher icon directories for all flavors"
Write-Host "================================================" -ForegroundColor Green

$flavors = @("onsa", "pipze", "octa", "fleza", "tenax")
$densities = @("mdpi", "hdpi", "xhdpi", "xxhdpi", "xxxhdpi")

foreach ($flavor in $flavors) {
    Write-Host ""
    Write-Host "Creating directories for $flavor..."
    
    foreach ($density in $densities) {
        $dir = "android\app\src\$flavor\res\mipmap-$density"
        
        if (!(Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Host "  [OK] Created: $dir" -ForegroundColor Green
        } else {
            Write-Host "  [SKIP] Already exists: $dir"
        }
    }
}

Write-Host ""
Write-Host "================================================"
Write-Host "Next steps:"
Write-Host "================================================" -ForegroundColor Yellow
Write-Host "1. Get your logo files ready (PNG format)"
Write-Host "2. Update the YAML config files with correct image paths"
Write-Host "3. Run: flutter pub run flutter_launcher_icons -f flutter_launcher_icons_onsa.yaml"
Write-Host "4. Copy the generated icons to each flavor mipmap folders"
Write-Host "================================================"
Write-Host ""
Write-Host "Done!" -ForegroundColor Green
