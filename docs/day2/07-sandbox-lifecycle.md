# Sandbox Lifecycle Management

## Purpose
Manage sandbox resources, monitor expiry dates, and ensure automated cleanup runs properly.

## Background
The Sandbox subscription is designed for experimentation with automatic resource cleanup after 30 days. All sandbox resources must have:
- `environment=sandbox` tag
- `expiry_date` tag (format: YYYY-MM-DD)

## Prerequisites
- Reader access to Sandbox subscription
- Contributor access to Management subscription (for automation account)

---

## Understanding Sandbox Policies

### Policy 1: Environment Tag Enforcement
**Policy**: `enforce-sandbox-environment-tag`  
**Effect**: Deny deployment if `environment` tag is not exactly "sandbox"

**What it does**:
- Prevents resources with `environment=prod` or `environment=nonprod` in Sandbox
- Forces all sandbox resources to be properly tagged

### Policy 2: Expiry Date Requirement
**Policy**: `require-sandbox-expiry-tag`  
**Effect**: Deny deployment if `expiry_date` tag is missing

**What it does**:
- Requires all sandbox resources to have an expiry date
- Ensures cleanup automation can identify resources to delete

### Policy 3: VNet Peering Denial
**Policy**: `deny-sandbox-vnet-peering`  
**Effect**: Deny any VNet peering creation

**What it does**:
- Maintains air-gap (no connectivity to hubs or spokes)
- Prevents accidental connectivity to production

---

## Automated Cleanup Process

### How It Works
1. **Azure Automation Runbook** runs daily at 02:00 UTC
2. **Scans** all resources in Sandbox subscription
3. **Identifies** resources with `expiry_date` > 30 days old
4. **Deletes** expired resources and resource groups
5. **Logs** all actions to Automation Account job history

### Cleanup Runbook Details
- **Name**: `Cleanup-ExpiredSandboxResources`
- **Location**: Automation Account `aa-platform-scus-prod-01`
- **Schedule**: Daily at 02:00 UTC
- **Authentication**: System-assigned managed identity
- **RBAC Required**: Contributor on Sandbox subscription

---

## Daily Tasks

### 1. Verify Cleanup Ran Successfully

**Steps**:
1. Open Azure Portal
2. Navigate to **Automation Accounts**
3. Open `aa-platform-scus-prod-01`
4. Go to **Jobs** (under Process Automation)
5. Find today's job for `Cleanup-ExpiredSandboxResources`
6. Verify status is **Completed**
7. Review job output

**Check output for**:
- "Total expired items found: X"
- List of deleted resources
- Any error messages

**Action if job failed**:
- Check error message in job output
- Verify managed identity has Contributor access to Sandbox subscription
- See [Troubleshooting](#troubleshooting-cleanup-issues)

---

### 2. Check Resources Expiring Soon

**Run this query in Azure Resource Graph Explorer**:

```kql
Resources
| where subscriptionId == "<SANDBOX_SUBSCRIPTION_ID>"
| where tags has "expiry_date"
| extend expiryDate = todatetime(tags['expiry_date'])
| extend daysUntilExpiry = datetime_diff('day', expiryDate, now())
| where daysUntilExpiry between (-30 .. 7)
| project name, resourceGroup, type, expiryDate, daysUntilExpiry, owner = tags['owner']
| order by daysUntilExpiry asc
```

**Take action**:
- **< 3 days**: Email owner with expiry warning
- **< 0 days (past expiry)**: Should be deleted next cleanup run
- **No owner tag**: Escalate to platform team

---

## Weekly Tasks

### 1. Review Sandbox Usage Report

**Generate usage report**:

```powershell
# Connect to Azure
Connect-AzAccount

# Set context to Sandbox subscription
Set-AzContext -Subscription "<SANDBOX_SUBSCRIPTION_ID>"

# Get all resource groups and resources
$resourceGroups = Get-AzResourceGroup
$report = @()

foreach ($rg in $resourceGroups) {
    $resources = Get-AzResource -ResourceGroupName $rg.ResourceGroupName
    
    foreach ($resource in $resources) {
        $report += [PSCustomObject]@{
            ResourceGroup = $rg.ResourceGroupName
            ResourceName  = $resource.Name
            ResourceType  = $resource.ResourceType
            Owner         = $resource.Tags['owner']
            Application   = $resource.Tags['application']
            ExpiryDate    = $resource.Tags['expiry_date']
            CreatedDate   = $rg.Tags['created_date']
        }
    }
}

# Export to CSV
$report | Export-Csv -Path "SandboxUsageReport-$(Get-Date -Format 'yyyy-MM-dd').csv" -NoTypeInformation

# Summary
Write-Host "Total Resource Groups: $($resourceGroups.Count)"
Write-Host "Total Resources: $($report.Count)"
Write-Host "Unique Owners: $(($report | Select-Object -ExpandProperty Owner -Unique).Count)"
```

**Review**:
- Total resource count trends
- Most active users
- Most common resource types
- Resources without proper tagging

---

### 2. Validate Policy Compliance

**Check sandbox policy compliance**:

1. Navigate to **Policy** > **Compliance**
2. Filter to **Sandbox** management group
3. Review compliance for:
   - `enforce-sandbox-environment-tag` (should be 100%)
   - `require-sandbox-expiry-tag` (should be 100%)
   - `deny-sandbox-vnet-peering` (should be 100%)

**Action if non-compliant**:
- Resources created before policy deployment: May need manual tagging
- Exemptions: Verify exemption is documented and approved
- Non-compliant resources > 24h old: Investigate and remediate

---

## Monthly Tasks

### 1. Review Cleanup History

**Steps**:
1. Open Automation Account `aa-platform-scus-prod-01`
2. Go to **Jobs**
3. Filter to `Cleanup-ExpiredSandboxResources`
4. Review last 30 days of job executions
5. Export job statistics:
   - Total resources deleted
   - Avg resources deleted per day
   - Any job failures

**Generate report**:
```powershell
# Get last 30 days of cleanup jobs
$jobs = Get-AzAutomationJob `
    -ResourceGroupName "rg-automation-scus-prod-01" `
    -AutomationAccountName "aa-platform-scus-prod-01" `
    -RunbookName "Cleanup-ExpiredSandboxResources" `
    -StartTime (Get-Date).AddDays(-30)

# Analyze
$successCount = ($jobs | Where-Object Status -eq "Completed").Count
$failCount = ($jobs | Where-Object Status -eq "Failed").Count
$totalRuns = $jobs.Count

Write-Host "Cleanup Summary (Last 30 Days)"
Write-Host "Total Runs: $totalRuns"
Write-Host "Successful: $successCount"
Write-Host "Failed: $failCount"
Write-Host "Success Rate: $([math]::Round(($successCount / $totalRuns) * 100, 2))%"
```

---

### 2. Audit Sandbox User Access

**Review who has access to Sandbox subscription**:

```powershell
# Get role assignments in Sandbox subscription
$assignments = Get-AzRoleAssignment -Scope "/subscriptions/<SANDBOX_SUBSCRIPTION_ID>"

# Group by user
$assignments | Group-Object SignInName | Select-Object Name, Count, @{
    Name='Roles'; Expression={($_.Group | Select-Object -ExpandProperty RoleDefinitionName) -join ', '}
}
```

**Verify**:
- All users have valid business justification
- No users have Owner role (unless platform admin)
- Temporary access has been removed

---

## User Requests

### Extending Resource Expiry

**When**: User requests to extend expiry date for existing resources

**Process**:
1. Verify user is owner of the resource(s)
2. Confirm extension is < 30 additional days
3. Update `expiry_date` tag:

```powershell
# Update resource expiry date
$newExpiryDate = (Get-Date).AddDays(30).ToString("yyyy-MM-dd")

# For a specific resource
Update-AzTag -ResourceId "<RESOURCE_ID>" -Tag @{expiry_date=$newExpiryDate} -Operation Merge

# For entire resource group
$rg = Get-AzResourceGroup -Name "<RESOURCE_GROUP_NAME>"
Update-AzTag -ResourceId $rg.ResourceId -Tag @{expiry_date=$newExpiryDate} -Operation Merge
```

4. Document in tracking system
5. Maximum extension: 30 days (policy limit)

---

### Manual Resource Deletion

**When**: User requests early deletion of sandbox resources

**Process**:
1. Verify user is owner
2. Export resource configuration (if needed):
   ```powershell
   Export-AzResourceGroup -ResourceGroupName "<RG_NAME>" -Path "backup-$((Get-Date).ToString('yyyy-MM-dd')).json"
   ```
3. Delete resource group:
   ```powershell
   Remove-AzResourceGroup -Name "<RG_NAME>" -Force
   ```
4. Confirm deletion completed
5. Notify user

---

## Troubleshooting Cleanup Issues

### Issue: Cleanup Runbook Failed

**Symptoms**: Job status shows "Failed" or "Suspended"

**Common causes**:
1. Managed identity lost Contributor access to Sandbox subscription
2. Resource group has delete lock
3. Resource has dependencies (e.g., VM with attached disk)

**Resolution**:
```powershell
# 1. Verify managed identity has access
$aa = Get-AzAutomationAccount -ResourceGroupName "rg-automation-scus-prod-01" -Name "aa-platform-scus-prod-01"
$principalId = $aa.Identity.PrincipalId

Get-AzRoleAssignment -ObjectId $principalId -Scope "/subscriptions/<SANDBOX_SUBSCRIPTION_ID>"
# Should show "Contributor" role

# 2. If missing, assign role:
New-AzRoleAssignment -ObjectId $principalId -RoleDefinitionName "Contributor" -Scope "/subscriptions/<SANDBOX_SUBSCRIPTION_ID>"

# 3. Check for delete locks:
Get-AzResourceLock -Scope "/subscriptions/<SANDBOX_SUBSCRIPTION_ID>"

# Remove any locks found:
Remove-AzResourceLock -LockId "<LOCK_ID>"
```

---

### Issue: Resource Not Deleted Despite Expiry

**Symptoms**: Resource expiry_date is > 30 days ago but still exists

**Troubleshooting**:
1. Check if resource has `expiry_date` tag:
   ```powershell
   Get-AzResource -ResourceId "<RESOURCE_ID>" | Select-Object -ExpandProperty Tags
   ```

2. Verify tag format is correct (YYYY-MM-DD)

3. Check last cleanup job output for errors

4. Manually run cleanup in dry-run mode:
   ```powershell
   Start-AzAutomationRunbook `
       -ResourceGroupName "rg-automation-scus-prod-01" `
       -AutomationAccountName "aa-platform-scus-prod-01" `
       -Name "Cleanup-ExpiredSandboxResources" `
       -Parameters @{
           SandboxSubscriptionId = "<SANDBOX_SUBSCRIPTION_ID>"
           DryRun = "true"
       }
   ```

5. Review job output to see if resource was identified

---

## Escalation

**Escalate to Platform Team if**:
- Cleanup runbook fails for > 2 consecutive days
- Resources with correct tags not being deleted
- Managed identity permissions issues
- Policy compliance drops below 90%
- User reports unexpected resource deletion

**Provide when escalating**:
- Job run ID and output
- Resource ID or resource group name
- Screenshot of tags
- Any error messages
