# PowerShell script to filter Android logs and hide WebView/GPU noise
Write-Host "Filtering Android logs to hide WebView and GPU noise..." -ForegroundColor Green
Write-Host ""

# Keywords to filter out
$filterKeywords = @(
    "setRequestedFrameRate",
    "GPUAUX",
    "GuiExtAuxCheckAuxPath", 
    "WebViewChromium",
    "WebViewProxyApi",
    "WebView.onDraw",
    "WebViewChromium.onDraw"
)

# Start adb logcat and filter out unwanted logs
try {
    adb logcat | ForEach-Object {
        $line = $_
        $shouldFilter = $false
        
        foreach ($keyword in $filterKeywords) {
            if ($line -match $keyword) {
                $shouldFilter = $true
                break
            }
        }
        
        if (-not $shouldFilter) {
            Write-Output $line
        }
    }
} catch {
    Write-Host "Error running adb logcat: $_" -ForegroundColor Red
    Write-Host "Make sure ADB is installed and device is connected." -ForegroundColor Yellow
}
