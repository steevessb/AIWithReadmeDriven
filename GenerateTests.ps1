# This script generates Pester tests based on the AzureFixtures.psd1 file

param (
    [string]$FixturePath = "$PSScriptRoot/AzureFixtures.psd1",  # Fixed path separator
    [string]$TestsFolder = "$PSScriptRoot/tests"  # Folder to store generated tests
)

Write-Host "Loading fixtures from $FixturePath..." -ForegroundColor Cyan

# Import the fixtures
$fixtures = Import-PowerShellDataFile -Path $FixturePath

# Ensure the tests folder exists
if (-not (Test-Path -Path $TestsFolder)) {
    New-Item -ItemType Directory -Path $TestsFolder | Out-Null
    Write-Host "Created tests folder at $TestsFolder" -ForegroundColor Green
}

# Generate tests for StorageAccounts
if ($fixtures.expectedStorageAccounts) {
    $outputPath = Join-Path -Path $TestsFolder -ChildPath "StorageAccounts.Tests.ps1"
    Write-Host "Generating tests for StorageAccounts at $outputPath..." -ForegroundColor Cyan

    $testContent = @()
    $testContent += "Describe \"StorageAccount Deployment Tests\" {"

    foreach ($storageAccount in $fixtures.expectedStorageAccounts) {
        $testContent += "    Context \"$($storageAccount.FriendlyName) Deployment Validation\" {"
        $testContent += "        It \"Should exist\" { \$actual = Get-AzStorageAccount -Name '$($storageAccount.Name)'; \$actual | Should -Not -BeNullOrEmpty }"
        $testContent += "    }"
    }

    $testContent += "}"

    # Write to output file
    $testContent | Set-Content -Path $outputPath
    Write-Host "Tests for StorageAccounts written to $outputPath" -ForegroundColor Green
}

# Add similar blocks for other resource types as needed

Write-Host "Test generation completed successfully." -ForegroundColor Green