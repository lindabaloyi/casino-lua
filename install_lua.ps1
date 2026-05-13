# Download portable Lua 5.4.6 - alternative source
Write-Host "Downloading portable Lua..." -ForegroundColor Cyan

# Try direct sourceforge link
$urls = @(
    "https://sourceforge.net/projects/luabinaries/files/5.4.6/Tools%20Executables/lua-5.4.6-win32.zip/download",
    "https://download.lua.org/5.4/lua-5.4.6-Win64_bin.zip"
)

$success = $false
foreach ($url in $urls) {
    try {
        Write-Host "Trying: $url" -ForegroundColor Yellow
        Invoke-WebRequest -Uri $url -OutFile "lua.zip" -UseBasicParsing -TimeoutSec 30
        if ((Get-Item "lua.zip").Length -gt 1000) {
            Expand-Archive -Path "lua.zip" -DestinationPath "." -Force
            Remove-Item "lua.zip" -Force
            Write-Host "Lua installed!" -ForegroundColor Green
            $success = $true
            break
        }
    } catch {
        Write-Host "Failed: $_" -ForegroundColor Red
        if (Test-Path "lua.zip") { Remove-Item "lua.zip" -Force }
    }
}

if (-not $success) {
    Write-Host "Could not download Lua automatically" -ForegroundColor Red
    Write-Host "Please download manually from: https://lua.org/download.html" -ForegroundColor Yellow
}