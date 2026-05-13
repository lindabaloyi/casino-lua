# download_luasocket.ps1
# Run this script to download LuaSocket DLLs for multiplayer support
# Run from PowerShell: .\download_luasocket.ps1

Write-Host "Downloading LuaSocket for Windows..." -ForegroundColor Cyan

$zipUrl = "https://github.com/lunarmodules/luasocket/releases/download/v3.1.0/socket-v3.1.0-2.windows-x86.zip"
$outputZip = "luasocket.zip"
$extractDir = "luasocket_extract"

# Download
try {
    Invoke-WebRequest -Uri $zipUrl -OutFile $outputZip -UseBasicParsing
    Write-Host "Download complete!" -ForegroundColor Green
} catch {
    Write-Host "Failed to download from GitHub releases" -ForegroundColor Red
    Write-Host "Trying alternative method..." -ForegroundColor Yellow
    # Try alternative download
    $altUrl = "https://sourceforge.net/projects/luasocket/files/luasocket-3.1.0/luasocket-3.1.0.zip/download"
    try {
        Invoke-WebRequest -Uri $altUrl -OutFile $outputZip -UseBasicParsing -SessionVariable sv
        Write-Host "Download from SourceForge complete!" -ForegroundColor Green
    } catch {
        Write-Host "Both download methods failed. Please download manually:" -ForegroundColor Red
        Write-Host "1. Go to: https://github.com/lunarmodules/luasocket/releases" -ForegroundColor Yellow
        Write-Host "2. Download the Windows zip file" -ForegroundColor Yellow
        Write-Host "3. Extract socket/core.dll and mime/core.dll to this folder" -ForegroundColor Yellow
        exit 1
    }
}

# Extract
if (Test-Path $outputZip) {
    # Create extract directory
    if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force }
    New-Item -ItemType Directory -Path $extractDir | Out-Null
    
    # Extract
    Expand-Archive -Path $outputZip -DestinationPath $extractDir -Force
    
    # Copy DLLs to project root
    $dlls = Get-ChildItem -Path $extractDir -Filter "*.dll" -Recurse
    foreach ($dll in $dlls) {
        Copy-Item $dll.FullName -Destination "." -Force
        Write-Host "Copied: $($dll.Name)" -ForegroundColor Green
    }
    
    # Also try socket folder
    $socketCore = Get-ChildItem -Path $extractDir -Filter "core.dll" -Recurse
    if ($socketCore) {
        if (!(Test-Path "socket")) { New-Item -ItemType Directory -Path "socket" | Out-Null }
        Copy-Item $socketCore.FullName -Destination "socket\core.dll" -Force
    }
    
    # Cleanup
    Remove-Item $outputZip -Force
    Remove-Item $extractDir -Recurse -Force
    
    Write-Host "`nLuaSocket DLLs installed!" -ForegroundColor Green
    Write-Host "You can now run multiplayer!" -ForegroundColor Cyan
} else {
    Write-Host "Download failed. Please download manually." -ForegroundColor Red
}