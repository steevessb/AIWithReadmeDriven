# This script generates Pester tests based on the AzureFixtures.psd1 file

param (
    [string]$FixturePath = "$PSScriptRoot/AzureFixtures.psd1",  # Fixed path separator
    [string]$OutputPath = "$PSScriptRoot/DeploymentsSpecification.Tests.ps1"
)

Write-Host "Loading fixtures from $FixturePath..." -ForegroundColor Cyan

# Import the fixtures
$fixtures = Import-PowerShellDataFile -Path $FixturePath

# Generate tests
Write-Host "Generating tests..." -ForegroundColor Cyan
$testContent = @()

foreach ($storageAccount in $fixtures.expectedStorageAccounts) {
    $testContent += "Describe \"StorageAccount Deployment Tests\" {"
    $testContent += "    Context \"$($storageAccount.FriendlyName) Deployment Validation\" {"
    $testContent += "        It \"Should exist\" { \"Test logic here\" }"
    $testContent += "    }"
    $testContent += "}"
}

# Write to output file
Write-Host "Writing tests to $OutputPath..." -ForegroundColor Cyan
$testContent | Set-Content -Path $OutputPath

Write-Host "Test generation completed successfully." -ForegroundColor Green