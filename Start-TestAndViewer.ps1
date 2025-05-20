# Start-TestAndViewer.ps1
# This script runs tests and launches the report viewer without regenerating tests

[CmdletBinding()]
param (
    [switch]$SkipTestGeneration = $true, # Default to true since this script is specifically for running tests
    [switch]$SkipTestExecution,
    [switch]$AutoConfirm,
    [string]$ResultsPath = "$PSScriptRoot\test-results"
)

# Simply call the main Start-GenerativeFlow script with appropriate parameters
& "$PSScriptRoot\Start-GenerativeFlow.ps1" `
    -SkipTestGeneration:$SkipTestGeneration `
    -SkipTestExecution:$SkipTestExecution `
    -AutoConfirm:$AutoConfirm `
    -ResultsPath $ResultsPath
