# Sandbox Cleanup Automation Runbook
# Deletes resources in Sandbox subscription with expiry_date tag older than 30 days

param(
    [Parameter(Mandatory = $true)]
    [string]$SandboxSubscriptionId,
    
    [Parameter(Mandatory = $false)]
    [string]$DryRun = "false"
)

$ErrorActionPreference = "Stop"

# Connect using managed identity
Write-Output "Connecting to Azure using managed identity..."
Connect-AzAccount -Identity

# Set context to sandbox subscription
Write-Output "Setting context to Sandbox subscription: $SandboxSubscriptionId"
Set-AzContext -SubscriptionId $SandboxSubscriptionId

# Get current date
$now = Get-Date
$expiryThreshold = $now.AddDays(-30)

Write-Output "Current date: $now"
Write-Output "Expiry threshold: $expiryThreshold (30 days ago)"

# Get all resource groups in sandbox subscription
$resourceGroups = Get-AzResourceGroup

$expiredResources = @()

foreach ($rg in $resourceGroups) {
    # Check resource group expiry date
    if ($rg.Tags.ContainsKey("expiry_date")) {
        $expiryDate = [DateTime]::Parse($rg.Tags["expiry_date"])
        
        if ($expiryDate -lt $expiryThreshold) {
            Write-Output "EXPIRED: Resource Group '$($rg.ResourceGroupName)' expired on $expiryDate"
            $expiredResources += @{
                Type = "ResourceGroup"
                Name = $rg.ResourceGroupName
                ExpiryDate = $expiryDate
            }
        }
    }
    
    # Check individual resources in resource group
    $resources = Get-AzResource -ResourceGroupName $rg.ResourceGroupName
    foreach ($resource in $resources) {
        if ($resource.Tags.ContainsKey("expiry_date")) {
            $expiryDate = [DateTime]::Parse($resource.Tags["expiry_date"])
            
            if ($expiryDate -lt $expiryThreshold) {
                Write-Output "EXPIRED: Resource '$($resource.Name)' (type: $($resource.ResourceType)) expired on $expiryDate"
                $expiredResources += @{
                    Type = "Resource"
                    Name = $resource.Name
                    ResourceType = $resource.ResourceType
                    ResourceGroupName = $rg.ResourceGroupName
                    ExpiryDate = $expiryDate
                }
            }
        }
    }
}

# Summary
Write-Output "`n===== SUMMARY ====="
Write-Output "Total expired items found: $($expiredResources.Count)"

if ($DryRun -eq "true") {
    Write-Output "`nDRY RUN MODE - No resources will be deleted"
    foreach ($item in $expiredResources) {
        Write-Output "Would delete: $($item.Type) - $($item.Name) (expired: $($item.ExpiryDate))"
    }
} else {
    Write-Output "`nDELETING expired resources..."
    
    # Delete individual resources first
    $resourcesToDelete = $expiredResources | Where-Object { $_.Type -eq "Resource" }
    foreach ($item in $resourcesToDelete) {
        Write-Output "Deleting resource: $($item.Name)"
        try {
            Remove-AzResource -ResourceGroupName $item.ResourceGroupName `
                             -ResourceName $item.Name `
                             -ResourceType $item.ResourceType `
                             -Force
            Write-Output "Successfully deleted: $($item.Name)"
        } catch {
            Write-Warning "Failed to delete resource $($item.Name): $_"
        }
    }
    
    # Delete expired resource groups
    $rgToDelete = $expiredResources | Where-Object { $_.Type -eq "ResourceGroup" }
    foreach ($item in $rgToDelete) {
        Write-Output "Deleting resource group: $($item.Name)"
        try {
            Remove-AzResourceGroup -Name $item.Name -Force
            Write-Output "Successfully deleted: $($item.Name)"
        } catch {
            Write-Warning "Failed to delete resource group $($item.Name): $_"
        }
    }
}

Write-Output "`nSandbox cleanup completed."
