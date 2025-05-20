function Connect-AzureSubscription {
    param (
        [string]$SubscriptionId = "38801999-1ab2-462d-99e1-9db9e1d9fc8c"
    )
    
    Write-Host "Connecting to Azure Subscription $SubscriptionId..." -ForegroundColor Cyan
    
    try {
        # Check if already connected to correct subscription
        $currentContext = Get-AzContext -ErrorAction SilentlyContinue
        
        if ($currentContext -and $currentContext.Subscription.Id -eq $SubscriptionId) {
            Write-Host "Already connected to subscription $SubscriptionId" -ForegroundColor Green
            return $true
        }
        
        # Try to set context to the specified subscription
        if ($currentContext) {
            Set-AzContext -SubscriptionId $SubscriptionId -ErrorAction Stop | Out-Null
            Write-Host "Successfully switched to subscription $SubscriptionId" -ForegroundColor Green
            return $true
        }
        
        # Need to connect
        Connect-AzAccount -SubscriptionId $SubscriptionId -ErrorAction Stop | Out-Null
        Write-Host "Successfully connected to subscription $SubscriptionId" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Failed to connect to Azure subscription: $_"
        return $false
    }
}

function Get-AzureStorageAccounts {
    Write-Host "Discovering Azure Storage Accounts..." -ForegroundColor Cyan
    
    try {
        $storageAccounts = Get-AzStorageAccount -ErrorAction Stop
        Write-Host "Discovered $($storageAccounts.Count) storage accounts" -ForegroundColor Green
        return $storageAccounts
    }
    catch {
        Write-Error "Failed to retrieve Azure Storage Accounts: $_"
        return @()
    }
}

function Export-DiscoveredResources {
    param (
        [switch]$ForceRefresh
    )
    
    $cachedDataPath = Join-Path -Path $PSScriptRoot -ChildPath "DiscoveredResources.cache.json"
    
    # Check for cached data unless force refresh is specified
    if (-not $ForceRefresh -and (Test-Path $cachedDataPath)) {
        $cacheAge = (Get-Date) - (Get-Item $cachedDataPath).LastWriteTime
        
        # Use cache if less than 15 minutes old
        if ($cacheAge.TotalMinutes -lt 15) {
            Write-Host "Using cached resource data (Age: $([math]::Round($cacheAge.TotalMinutes, 1)) minutes)" -ForegroundColor Yellow
            $cachedData = Get-Content $cachedDataPath | ConvertFrom-Json -AsHashtable
            
            if ($cachedData) {
                return $cachedData
            }
        }
    }
    
    # Connect to Azure
    $connected = Connect-AzureSubscription
    
    if (-not $connected) {
        Write-Error "Could not connect to Azure. Aborting resource discovery."
        return @{}
    }
    
    # Collect resources
    Write-Host "Starting resource discovery..." -ForegroundColor Magenta
    
    $resources = @{
        "StorageAccounts" = Get-AzureStorageAccounts
        # Add other resource types here as needed
    }
    
    # Cache the resources
    $resources | ConvertTo-Json -Depth 10 | Set-Content -Path $cachedDataPath
    Write-Host "Resource data cached to $cachedDataPath" -ForegroundColor Gray
    
    return $resources
}
