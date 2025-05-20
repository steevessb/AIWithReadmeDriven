# Start-GenerativeFlow.ps1
# This script orchestrates the entire workflow from fixture to report

[CmdletBinding()]
param (
    [switch]$SkipTestGeneration,
    [switch]$SkipTestExecution,
    [switch]$SkipReportViewer,
    [switch]$AutoConfirm,
    [string]$ResultsPath = "$PSScriptRoot\test-results"
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Helper function for console output
function Write-Step {
    param(
        [string]$Message,
        [string]$Color = "Cyan",
        [switch]$NoNewLine
    )
    
    Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] " -NoNewline -ForegroundColor DarkGray
    Write-Host $Message -ForegroundColor $Color -NoNewline:$NoNewLine
}

# Helper function for confirmation prompts
function Confirm-Action {
    param(
        [string]$Message
    )
    
    if ($AutoConfirm) {
        return $true
    }
    
    Write-Host "`n$Message" -ForegroundColor Yellow -NoNewline
    Write-Host " (Y/n): " -ForegroundColor Gray -NoNewline
    $response = Read-Host
    
    return ($response -eq "" -or $response.ToLower() -eq "y" -or $response.ToLower() -eq "yes")
}

# Display banner
Write-Host "`n╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║                     BDD Test Generator                        ║" -ForegroundColor Magenta
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host "This unified script will generate and run tests, and display results"

# Create results directory if it doesn't exist
if (-not (Test-Path -Path $ResultsPath)) {
    New-Item -Path $ResultsPath -ItemType Directory -Force | Out-Null
}

# Step 1: Generate Tests
if (-not $SkipTestGeneration) {
    Write-Step "Step 1: Generating Pester tests from fixtures..." -Color Green
    
    if (Confirm-Action "Generate Pester tests from Azure Fixtures?") {
        & "$PSScriptRoot\GenerateTests.ps1" -Verbose
        
        if ($LASTEXITCODE -ne 0) {
            Write-Step "Test generation failed with exit code $LASTEXITCODE" -Color Red
            exit $LASTEXITCODE
        }
        
        Write-Step "Test generation complete!" -Color Green
    }
    else {
        Write-Step "Test generation skipped by user." -Color Yellow
        exit 0
    }
}
else {
    Write-Step "Test generation skipped (SkipTestGeneration parameter)." -Color Yellow
}

# Step 2: Run Tests
if (-not $SkipTestExecution) {
    Write-Step "Step 2: Running Pester tests..." -Color Green
    
    if (Confirm-Action "Run Pester tests against Azure resources?") {
        & "$PSScriptRoot\RunPesterTests.ps1" -OutputPath $ResultsPath -Verbose
        
        if ($LASTEXITCODE -ne 0) {
            Write-Step "Some tests failed. Check the results for details." -Color Yellow
        }
        else {
            Write-Step "All tests passed!" -Color Green
        }
    }
    else {
        Write-Step "Test execution skipped by user." -Color Yellow
    }
}
else {
    Write-Step "Test execution skipped (SkipTestExecution parameter)." -Color Yellow
}

# Step 3: Start Report Viewer
if (-not $SkipReportViewer) {
    Write-Step "Step 3: Starting report viewer..." -Color Green
    
    if (Confirm-Action "Start the report viewer web application?") {
        # Check if report-viewer directory exists
        $reportViewerDir = Join-Path -Path $PSScriptRoot -ChildPath "report-viewer"
        
        if (-not (Test-Path -Path $reportViewerDir)) {
            Write-Step "Report viewer directory not found. Do you want to create it?" -Color Yellow
            
            if (Confirm-Action "Create and set up the report viewer?") {
                Write-Step "Creating report viewer directory and setting up React application..." -Color Blue
                # This would be implemented later with report viewer setup
            }
            else {
                Write-Step "Report viewer setup skipped by user." -Color Yellow
                exit 0
            }
        }
        
        # Start the report viewer
        try {
            # Check if node_modules exists
            $nodeModulesDir = Join-Path -Path $reportViewerDir -ChildPath "node_modules"
            
            if (-not (Test-Path -Path $nodeModulesDir)) {
                Write-Step "Installing report viewer dependencies..." -Color Blue
                Push-Location $reportViewerDir
                npm install
                Pop-Location
            }
            
            # Start the server
            Write-Step "Starting report viewer server..." -Color Blue
            Start-Process -FilePath "node" -ArgumentList "server.js" -WorkingDirectory $reportViewerDir
            
            # Open browser
            Start-Process "http://localhost:3001"
            
            Write-Step "Report viewer started at http://localhost:3001" -Color Green
        }
        catch {
            Write-Step "Failed to start report viewer: $_" -Color Red
            exit 1
        }
    }
    else {
        Write-Step "Report viewer skipped by user." -Color Yellow
    }
}
else {
    Write-Step "Report viewer skipped (SkipReportViewer parameter)." -Color Yellow
}

Write-Host "`n╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                      Process Complete                         ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
