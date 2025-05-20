# This script installs required dependencies: Az and Pester (version 5.3.3)

# Check if Az module is installed
if (-not (Get-Module -ListAvailable -Name Az)) {
    Write-Host "Az module not found. Installing..." -ForegroundColor Yellow
    Install-Module -Name Az -Force -AllowClobber
    Write-Host "Az module installed successfully." -ForegroundColor Green
} else {
    Write-Host "Az module is already installed." -ForegroundColor Green
}

# Check if Pester version 5.3.3 is installed
$pesterModule = Get-Module -ListAvailable -Name Pester | Where-Object { $_.Version -eq [Version]'5.3.3' }
if (-not $pesterModule) {
    Write-Host "Pester 5.3.3 not found. Installing..." -ForegroundColor Yellow
    Install-Module -Name Pester -RequiredVersion 5.3.3 -Force
    Write-Host "Pester 5.3.3 installed successfully." -ForegroundColor Green
} else {
    Write-Host "Pester 5.3.3 is already installed." -ForegroundColor Green
}
