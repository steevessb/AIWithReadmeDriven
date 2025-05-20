# GenerateTests.ps1
# This script orchestrates the test generation process by reading fixtures and creating Pester tests

#Requires -Modules Pester

# Import the PesterTestGenerator module
. "$PSScriptRoot\PesterTestGenerator.ps1"

# Parameters
param (
    [string]$FixturePath = "$PSScriptRoot\AzureFixtures.psd1",
    [string]$OutputPath = "$PSScriptRoot\DeploymentsSpecification.Tests.ps1",
    [switch]$Force = $false,
    [switch]$Quiet = $false
)

function Write-ColorOutput {
    param (
        [string]$Message,
        [string]$ForegroundColor = "White",
        [switch]$NoNewLine
    )
    
    if (-not $Quiet) {
        Write-Host $Message -ForegroundColor $ForegroundColor -NoNewline:$NoNewLine
    }
}

function Test-PowerShellSyntax {
    param (
        [string]$FilePath
    )

    try {
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content -Path $FilePath -Raw), [ref]$null)
        return $true
    }
    catch {
        Write-ColorOutput "Syntax error in generated file: $_" -ForegroundColor Red
        return $false
    }
}

# Main execution
Write-ColorOutput "Starting test generation process..." -ForegroundColor Cyan

# Check if fixture file exists
if (-not (Test-Path $FixturePath)) {
    Write-ColorOutput "Error: Fixture file not found at $FixturePath" -ForegroundColor Red
    exit 1
}

# Check if output file exists and handle backing up if needed
if (Test-Path $OutputPath) {
    if (-not $Force) {
        Write-ColorOutput "Warning: Output file already exists at $OutputPath" -ForegroundColor Yellow
        $confirmation = Read-Host "Do you want to overwrite? (Y/N)"
        if ($confirmation -ne 'Y') {
            Write-ColorOutput "Test generation aborted." -ForegroundColor Red
            exit 0
        }
    }
    
    # Create backup
    $backupPath = "$OutputPath.backup"
    Copy-Item -Path $OutputPath -Destination $backupPath -Force
    Write-ColorOutput "Backup created at $backupPath" -ForegroundColor Gray
}

# Find fixture variables from the fixtures file
Write-ColorOutput "Discovering fixtures from $FixturePath..." -ForegroundColor Cyan
$fixtureVariables = Find-FixtureVariables -FixturePath $FixturePath

if ($fixtureVariables.Count -eq 0) {
    Write-ColorOutput "Error: No fixture variables found in $FixturePath" -ForegroundColor Red
    exit 1
}

Write-ColorOutput "Found $($fixtureVariables.Count) fixture variables:" -ForegroundColor Green
foreach ($var in $fixtureVariables.Keys) {
    Write-ColorOutput " - $var" -ForegroundColor Green
}

# Generate test blocks for each fixture variable
Write-ColorOutput "`nGenerating test blocks..." -ForegroundColor Cyan
$generatedTests = @()

foreach ($var in $fixtureVariables.Keys) {
    Write-ColorOutput " - Processing $var..." -ForegroundColor Gray
    $resourceType = $var -replace '^expected', ''
    
    $generatedTest = New-DescribeContextItFromExpectedFixtureVariable -FixtureVariableName $var -ResourceType $resourceType
    $generatedTests += $generatedTest
}

# Write the generated tests to the output file
Write-ColorOutput "`nWriting tests to $OutputPath..." -ForegroundColor Cyan
$result = Write-GeneratedTestsToFile -Tests $generatedTests -OutputPath $OutputPath

# Validate syntax of the generated file
if (Test-Path $OutputPath) {
    $syntaxValid = Test-PowerShellSyntax -FilePath $OutputPath
    
    if ($syntaxValid) {
        Write-ColorOutput "Test generation completed successfully!" -ForegroundColor Green
        Write-ColorOutput "Generated tests written to $OutputPath" -ForegroundColor Green
    }
    else {
        Write-ColorOutput "Warning: The generated file may contain syntax errors." -ForegroundColor Yellow
    }
}
else {
    Write-ColorOutput "Error: Failed to create output file." -ForegroundColor Red
    exit 1
}
