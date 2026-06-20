# Run as Administrator
# === CONFIG ===
$CabUrl  = "https://catalog.s.download.windowsupdate.com/c/msdownload/update/driver/drvs/2025/02/16b0eb24-6a3f-4100-b70d-8fb09f7eda20_22e8c3b17cb9a9948d347f1e7e46acc36d9e16a1.cab"
$TempDir = "$env:TEMP\AsusSCI_Downgrade"
$CabFile = "$TempDir\AsusSCI.cab"
$InfName = "asussci2.inf"
# === SETUP ===
Write-Host "Preparing temporary directory..." -ForegroundColor Cyan
if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
New-Item -Path $TempDir -ItemType Directory | Out-Null
# === DOWNLOAD ===
Write-Host "Downloading ASUS SCI driver CAB..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $CabUrl -OutFile $CabFile
# === EXTRACT ===
Write-Host "Extracting CAB contents..." -ForegroundColor Cyan
expand $CabFile -F:* $TempDir | Out-Null
# === REMOVE EXISTING ===
Write-Host "Searching for existing ASUS SCI drivers..." -ForegroundColor Cyan
$drivers = pnputil /enum-drivers | Select-String -Pattern "Published Name|Original Name" -Context 4,0 |
    Where-Object { $_.ToString() -match "$InfName" }
if ($drivers) {
    $oemFiles = ($drivers | Select-String -Pattern "Published Name").ToString() -replace "Published Name : ", ""
    foreach ($oem in $oemFiles) {
        Write-Host "Removing $oem..." -ForegroundColor Yellow
        pnputil /delete-driver $oem /uninstall /force
    }
} else {
    Write-Host "No existing asussci2.inf driver found." -ForegroundColor Gray
}
# === INSTALL OLD ONE ===
$InfPath = Join-Path $TempDir $InfName
Write-Host "Installing driver from $InfPath..." -ForegroundColor Green
pnputil /add-driver "$InfPath" /install
Write-Host "`nAll done. Reboot is recommended." -ForegroundColor Cyan
