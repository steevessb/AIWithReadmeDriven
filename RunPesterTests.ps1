# RunPesterTests.ps1
# Runs Pester tests and outputs results in NUnit XML format

#Requires -Modules Pester

param (
    [string]$TestPath = "$PSScriptRoot\DeploymentsSpecification.Tests.ps1",
    [string]$OutputFolder = "$PSScriptRoot\TestResults",
    [switch]$Detail = $false,
    [switch]$ForceDiscovery = $false,
    [switch]$PassThru
)

# Ensure output folder exists
if (-not (Test-Path -Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
}

# Define output paths
$xmlOutputPath = Join-Path -Path $OutputFolder -ChildPath "TestResults.xml"
$jsonOutputPath = Join-Path -Path $OutputFolder -ChildPath "TestResults.json"

# Import required modules
. "$PSScriptRoot\DiscoveryPhase.ps1"

# Prepare test configuration
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $TestPath
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = if ($Detail) { 'Detailed' } else { 'Normal' }
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputFormat = 'NUnitXml'
$pesterConfig.TestResult.OutputPath = $xmlOutputPath

# Display information about the test run
Write-Host "Starting Pester tests..." -ForegroundColor Cyan
Write-Host "Test file: $TestPath" -ForegroundColor Cyan
Write-Host "Output folder: $OutputFolder" -ForegroundColor Cyan
Write-Host "Force discovery: $ForceDiscovery" -ForegroundColor Cyan

# Force resource discovery if specified
if ($ForceDiscovery) {
    Write-Host "Forcing fresh resource discovery from Azure..." -ForegroundColor Yellow
    $null = Export-DiscoveredResources -ForceRefresh
}

# Run Pester tests
Write-Host "`nExecuting tests..." -ForegroundColor Magenta
$testResults = Invoke-Pester -Configuration $pesterConfig

# Generate JSON output for the report viewer
$testResults | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonOutputPath

# Calculate summary metrics
$totalTests = $testResults.TotalCount
$passedTests = $testResults.PassedCount
$failedTests = $testResults.FailedCount
$skippedTests = $testResults.SkippedCount
$notRunTests = $testResults.NotRunCount
$passRate = if ($totalTests -gt 0) { [math]::Round(($passedTests / $totalTests) * 100, 1) } else { 0 }

# Display summary
Write-Host "`n======= Test Results Summary =======" -ForegroundColor Cyan
Write-Host "Total Tests: $totalTests" -ForegroundColor White
Write-Host "Passed: $passedTests" -ForegroundColor ([System.ConsoleColor]::Green)
Write-Host "Failed: $failedTests" -ForegroundColor ([System.ConsoleColor]::Red)
Write-Host "Skipped: $skippedTests" -ForegroundColor ([System.ConsoleColor]::Yellow)
Write-Host "Not Run: $notRunTests" -ForegroundColor ([System.ConsoleColor]::Gray)
Write-Host "Pass Rate: $passRate%" -ForegroundColor ([System.ConsoleColor]::Cyan)
Write-Host "==================================" -ForegroundColor Cyan

Write-Host "`nTest results saved to:" -ForegroundColor Cyan
Write-Host " - XML: $xmlOutputPath" -ForegroundColor Gray
Write-Host " - JSON: $jsonOutputPath" -ForegroundColor Gray

# Return results if PassThru is specified
if ($PassThru) {
    return $testResults
}
