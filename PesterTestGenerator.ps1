function Find-FixtureVariables {
    param (
        [string]$fixturesFilePath = ".\AzureFixtures.psd1"
    )
    
    Write-Host "Discovering fixture variables from $fixturesFilePath..." -ForegroundColor Cyan
    
    # Import the fixtures
    try {
        $fixtures = Import-PowerShellDataFile -Path $fixturesFilePath -ErrorAction Stop
        Write-Host "Successfully loaded fixtures data file" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to import fixtures from $fixturesFilePath. Error: $_"
        return @()
    }
    
    # Extract the variable names that start with "expected"
    $fixtureVariables = @{}
    foreach ($key in $fixtures.Keys) {
        if ($key -like "expected*") {
            $resourceType = $key -replace '^expected', ''
            $fixtureVariables[$key] = @{
                ResourceType = $resourceType
                Value = $fixtures[$key]
            }
        }
    }
    
    Write-Host "Discovered $($fixtureVariables.Count) fixture variables" -ForegroundColor Green
    return $fixtureVariables
}

function New-DescribeContextItFromExpectedFixtureVariable {
    param (
        [Parameter(Mandatory = $true)]
        [string]$variableName,
        
        [Parameter(Mandatory = $true)]
        [string]$resourceType,
        
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$fixtureContent
    )
    
    Write-Host "Generating test blocks for $resourceType from $variableName..." -ForegroundColor Cyan
    
    # Create a describe block for the resource type
    $pluralResourceType = $resourceType
    if (-not $pluralResourceType.EndsWith('s')) {
        $pluralResourceType += 's'
    }
    
    $sb = [System.Text.StringBuilder]::new()
    
    [void]$sb.AppendLine("Describe `"$resourceType Deployment Tests`" {")
    
    # For each instance in the fixture, create a context block
    foreach ($instance in $fixtureContent.Value) {
        $friendlyName = $instance.FriendlyName
        if (-not $friendlyName) {
            $friendlyName = $instance.Name
        }
        
        [void]$sb.AppendLine("    Context `"$friendlyName Deployment Validation`" -ForEach `$$variableName {")
        [void]$sb.AppendLine("        BeforeAll {")
        [void]$sb.AppendLine("            `$actual = `$actualDeployedResources['$pluralResourceType'] | Where-Object { `$_.Name -eq `$Name }")
        [void]$sb.AppendLine("        }")
        [void]$sb.AppendLine("")
        
        # Resource existence test
        [void]$sb.AppendLine("        It `"$friendlyName should exist`" {")
        [void]$sb.AppendLine("            `$actual | Should -Not -BeNullOrEmpty -Because `"$resourceType should be created`"")
        [void]$sb.AppendLine("        }")
        [void]$sb.AppendLine("")
        
        # Generate an It block for each property in the instance
        foreach ($prop in $instance.Keys) {
            if ($prop -eq "FriendlyName") { continue } # Skip the FriendlyName property
            
            $value = $instance[$prop]
            $formattedValue = if ($value -is [string]) { "'$value'" } else { $value }
            
            if ($prop -eq "Name") {
                [void]$sb.AppendLine("        It `"Should be named $formattedValue`" {")
                [void]$sb.AppendLine("            `$actual.Name | Should -Be `$Name -Because `"Resource name should match specification`"")
                [void]$sb.AppendLine("        }")
            }
            elseif ($prop -eq "rgName") {
                [void]$sb.AppendLine("        It `"Should be in the $formattedValue resource group`" {")
                [void]$sb.AppendLine("            `$actual.ResourceGroupName | Should -Be `$rgName -Because `"Resource should be in the specified resource group`"")
                [void]$sb.AppendLine("        }")
            }
            else {
                $propertyName = $prop
                
                # Map common fixture property names to Azure resource property names
                $propertyMappings = @{
                    "Location" = "Location"
                    "Tier" = "SkuName"
                }
                
                $azurePropertyName = if ($propertyMappings.ContainsKey($propertyName)) { 
                    $propertyMappings[$propertyName] 
                } else { 
                    $propertyName 
                }
                
                [void]$sb.AppendLine("        It `"Should have $propertyName of $formattedValue`" {")
                [void]$sb.AppendLine("            `$actual.$azurePropertyName | Should -Be `$$propertyName -Because `"Resource $propertyName should match specification`"")
                [void]$sb.AppendLine("        }")
            }
            
            [void]$sb.AppendLine("")
        }
        
        [void]$sb.AppendLine("    }")
    }
    
    [void]$sb.AppendLine("}")
    
    Write-Host "Generated $resourceType tests successfully" -ForegroundColor Green
    return $sb.ToString()
}

function Write-GeneratedTestsToFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$outputFilePath,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$resourceTests,
        
        [switch]$backup = $true
    )
    
    Write-Host "Writing tests to $outputFilePath..." -ForegroundColor Cyan
    
    # Create backup of existing file if specified
    if ($backup -and (Test-Path $outputFilePath)) {
        $backupPath = "$outputFilePath.bak"
        Copy-Item -Path $outputFilePath -Destination $backupPath -Force
        Write-Host "Created backup at $backupPath" -ForegroundColor Yellow
    }
    
    # Add required imports at the beginning
    $content = @"
# Auto-generated tests from fixtures - DO NOT EDIT DIRECTLY
# Any manual changes should be made to AzureFixtures.psd1

# Import the fixtures
`$fixturesPath = Join-Path -Path `$PSScriptRoot -ChildPath "AzureFixtures.psd1"
`$fixtures = Import-PowerShellDataFile -Path `$fixturesPath

# Import the variables from fixtures
foreach (`$key in `$fixtures.Keys) {
    Set-Variable -Name `$key -Value `$fixtures[`$key] -Scope Script
}

# Import functions from DiscoveryPhase.ps1
. (Join-Path -Path `$PSScriptRoot -ChildPath "DiscoveryPhase.ps1")

# Get discovered resources
`$actualDeployedResources = Export-DiscoveredResources


"@
    
    # Add the test blocks for each resource type
    foreach ($testBlock in $resourceTests.Values) {
        $content += $testBlock + "`n`n"
    }
    
    # Write the content to the file
    Set-Content -Path $outputFilePath -Value $content
    
    Write-Host "Successfully wrote tests to $outputFilePath" -ForegroundColor Green
}
