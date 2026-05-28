# Incident Triage and Response

## Purpose
Provide step-by-step guidance for responding to alerts, incidents, and service degradation.

## Incident Severity Levels

| Severity | Definition | Response Time | Examples |
|---|---|---|---|
| **P1 - Critical** | Complete service outage affecting production | Immediate (< 15 min) | Hub firewall down, all production apps unreachable |
| **P2 - High** | Significant service degradation affecting production | < 1 hour | DR region connectivity lost, backup failures |
| **P3 - Medium** | Minor service impact or non-production issue | < 4 hours | Sandbox policy non-compliance, non-critical alerts |
| **P4 - Low** | No immediate impact, informational | < 24 hours | Resource tag drift, documentation updates |

---

## General Incident Response Process

### Step 1: Initial Assessment (First 5 Minutes)

1. **Acknowledge the alert** (if from monitoring system)
2. **Determine severity** using table above
3. **Check Azure Service Health**:
   - Are there known Azure platform issues?
   - Navigate to: Portal > Service Health > Service Issues
4. **Gather initial evidence**:
   - Screenshot of error
   - Time incident started
   - Affected resources
5. **Notify stakeholders** if P1/P2:
   - Post to incident channel
   - Page on-call engineer (P1 only)

---

### Step 2: Containment (First 15 Minutes)

**Goal**: Stop the bleeding, prevent further impact

**Common containment actions**:
- Isolate affected resources (disable firewall rules, disconnect peering)
- Scale down failing services
- Redirect traffic to DR region
- Enable maintenance mode

**Do NOT**:
- Make irreversible changes without documentation
- Delete resources without backup
- Modify production firewall rules without approval

---

### Step 3: Investigation (15-60 Minutes)

**Gather diagnostic data**:

1. **Check Azure Monitor logs**:
   ```kql
   // Review errors in last hour
   AzureDiagnostics
   | where TimeGenerated > ago(1h)
   | where Level == "Error" or Level == "Critical"
   | summarize count() by Resource, Category, ResultDescription
   | order by count_ desc
   ```

2. **Check firewall logs**:
   ```kql
   AzureDiagnostics
   | where Category == "AzureFirewallApplicationRule" or Category == "AzureFirewallNetworkRule"
   | where TimeGenerated > ago(1h)
   | where Action == "Deny"
   | summarize count() by SourceIp, DestinationIp, DestinationPort, Action
   ```

3. **Check resource health**:
   - Portal > Resource > Resource Health
   - Review health history for affected resources

4. **Review recent changes**:
   - Check GitHub Actions recent runs
   - Portal > Activity Log > filter to last 24h

---

### Step 4: Resolution

See specific incident types below for resolution steps.

---

### Step 5: Communication

**During incident**:
- Update incident channel every 30 minutes (P1/P2)
- Provide status updates to stakeholders

**After resolution**:
- Post resolution summary
- Schedule post-mortem (P1/P2)
- Document in incident tracking system

---

## Common Incident Types

### 1. Hub Firewall Unreachable

**Symptoms**:
- Spoke resources cannot reach internet
- Application connectivity failures
- Firewall health metrics show 0% availability

**Triage Steps**:
1. Check firewall resource health:
   ```powershell
   Get-AzResource -Name "azfw-hub-scus-prod-01" | Get-AzResourceHealth
   ```

2. Verify firewall is running:
   - Portal > Firewalls > azfw-hub-scus-prod-01
   - Check "Provisioning State" and "Health State"

3. Check NSG/UDR configuration:
   - Verify UDRs point to correct firewall IP
   - Check for NSG blocking firewall traffic

4. Review firewall logs for errors:
   ```kql
   AzureDiagnostics
   | where ResourceType == "AZUREFIREWALLS"
   | where TimeGenerated > ago(1h)
   | where Level == "Error"
   ```

**Resolution**:
- **If firewall stopped**: Restart via Portal or:
  ```powershell
  $firewall = Get-AzFirewall -Name "azfw-hub-scus-prod-01" -ResourceGroupName "rg-connectivity-scus-prod-01"
  Set-AzFirewall -AzureFirewall $firewall
  ```
- **If firewall rules misconfigured**: Review and correct rules
- **If Azure platform issue**: Engage Azure Support, failover to DR hub if possible

**Escalation**: Escalate to platform team lead if not resolved in 30 minutes

---

### 2. VNet Peering Failure

**Symptoms**:
- Spoke cannot reach hub resources
- Cross-region connectivity lost
- Peering status shows "Disconnected"

**Triage Steps**:
1. Check peering status:
   ```powershell
   Get-AzVirtualNetworkPeering -VirtualNetworkName "vnet-prod-app-scus-prod-01" -ResourceGroupName "rg-prod-app-scus-prod-01"
   ```

2. Verify peering exists in both directions (spoke→hub and hub→spoke)

3. Check for address space overlap:
   - Peerings fail if VNets have overlapping address spaces

4. Review activity log for peering modification:
   ```kql
   AzureActivity
   | where TimeGenerated > ago(24h)
   | where OperationNameValue contains "virtualNetworks/virtualNetworkPeerings"
   | where ActivityStatusValue == "Failed"
   ```

**Resolution**:
- **If peering disconnected**: Delete and recreate peering
- **If address overlap**: One VNet must be re-addressed (requires planning)
- **If gateway transit misconfigured**: Update peering settings

**Escalation**: Network operations team for VNet re-addressing

---

### 3. Backup Job Failures

**Symptoms**:
- Backup job shows "Failed" status
- Alert: "Azure VM backup failed"

**Triage Steps**:
1. Check backup job details:
   - Portal > Recovery Services Vault > Backup Jobs
   - Find failed job, click for error details

2. Common errors:
   - **"VM agent not responding"**: VM or agent issue
   - **"Snapshot operation timed out"**: Disk performance issue
   - **"Insufficient permissions"**: RBAC issue

3. Verify VM is running:
   ```powershell
   Get-AzVM -Name "<VM_NAME>" -Status
   ```

4. Check VM agent status:
   - Portal > VM > Extensions > check "WindowsAgent" or "LinuxAgent" status

**Resolution**:
- **VM agent issue**: Restart VM or reinstall agent
- **Disk performance**: Check for high disk latency, consider disk tier upgrade
- **Permissions**: Verify RSV managed identity has VM Contributor on VM

**Retry backup**:
```powershell
$vault = Get-AzRecoveryServicesVault -Name "rsv-platform-scus-prod-01"
Set-AzRecoveryServicesVaultContext -Vault $vault
$backupItem = Get-AzRecoveryServicesBackupItem -WorkloadType AzureVM -VaultId $vault.ID | Where-Object {$_.Name -eq "<VM_NAME>"}
Backup-AzRecoveryServicesBackupItem -Item $backupItem
```

**Escalation**: Backup team if failures persist after retry

---

### 4. Sandbox Policy Violation

**Symptoms**:
- Alert: "Policy compliance dropped below threshold"
- Resources deployed in Sandbox without proper tags
- Deployment failed due to policy deny

**Triage Steps**:
1. Identify non-compliant resources:
   - Portal > Policy > Compliance > filter to Sandbox MG

2. Check which policy is violated:
   - Click on non-compliant resources
   - Review "Policy Details" pane

3. Common violations:
   - Missing `owner` tag
   - Missing `expiry_date` tag
   - `environment` tag not set to "sandbox"
   - Attempted VNet peering

**Resolution**:
- **Missing tags**: Add tags to resource:
  ```powershell
  $resource = Get-AzResource -ResourceId "<RESOURCE_ID>"
  $tags = $resource.Tags
  $tags['owner'] = "<OWNER_EMAIL>"
  $tags['expiry_date'] = (Get-Date).AddDays(30).ToString("yyyy-MM-dd")
  Set-AzResource -ResourceId $resource.ResourceId -Tag $tags -Force
  ```

- **Wrong environment tag**: Update to "sandbox"

- **VNet peering attempt**: Contact user, explain air-gap policy

**Escalation**: None needed unless policy itself needs exemption (requires platform team approval)

---

### 5. Terraform State Lock

**Symptoms**:
- GitHub Actions workflow stuck on "Acquiring state lock"
- Manual `terraform plan` fails with "Error locking state"

**Triage Steps**:
1. Check for active Terraform runs:
   - GitHub Actions > check for running workflows

2. Check state blob lease status:
   ```powershell
   $storageAccount = Get-AzStorageAccount -Name "<STATE_STORAGE_ACCOUNT_NAME>" -ResourceGroupName "<STATE_RG_NAME>"
   $ctx = $storageAccount.Context
   $blob = Get-AzStorageBlob -Container "<CONTAINER_NAME>" -Blob "terraform.tfstate" -Context $ctx
   $blob.ICloudBlob.Properties.LeaseStatus
   ```

3. If lease is "Locked", find lease ID:
   ```powershell
   $blob.ICloudBlob.Properties.LeaseState
   # Shows "Leased" if locked
   ```

**Resolution**:
- **Active workflow running**: Wait for it to complete (or cancel if stuck)
- **Orphaned lock** (no active workflow):
  ```powershell
  # Force break lease
  $blob.ICloudBlob.BreakLease()
  ```

**Important**: Only break lease if you're certain no Terraform operation is actually running!

**Escalation**: Platform team lead before breaking lease

---

### 6. DR Region Connectivity Lost

**Symptoms**:
- Hub-to-hub peering shows disconnected
- Cannot reach DR region resources
- Gateway shows "Not Connected"

**Triage Steps**:
1. Check Azure Service Health for DR region (North Central US)

2. Verify hub-to-hub peering status:
   ```powershell
   Get-AzVirtualNetworkPeering -VirtualNetworkName "vnet-hub-scus-prod-01" -ResourceGroupName "rg-connectivity-scus-prod-01"
   Get-AzVirtualNetworkPeering -VirtualNetworkName "vnet-hub-ncus-prod-01" -ResourceGroupName "rg-connectivity-ncus-prod-01"
   ```

3. Check for recent changes to hubs or peerings

4. Test connectivity between hubs:
   - Deploy test VM in each hub (or use Bastion)
   - Run ping/traceroute across peering

**Resolution**:
- **Service outage**: Wait for Azure resolution, notify stakeholders
- **Peering misconfigured**: Delete and recreate global peering
- **Gateway issue**: Review gateway configuration, check routes

**Escalation**: Immediate escalation to network operations and platform lead (P1 incident if production impacted)

---

## Post-Incident Checklist

After resolving any P1 or P2 incident:

- [ ] Update incident ticket with resolution details
- [ ] Schedule post-mortem meeting (within 48 hours)
- [ ] Document lessons learned
- [ ] Identify preventive measures
- [ ] Create action items for improvements
- [ ] Update runbooks if needed
- [ ] Notify all stakeholders of resolution

---

## Escalation Contacts

See [Escalation Matrix](./10-escalation-matrix.md) for detailed contact information.

**Quick reference**:
- **P1 Critical**: Page on-call engineer + platform team lead
- **P2 High**: Notify platform team lead
- **P3 Medium**: Assign to appropriate team
- **P4 Low**: Self-service or next business day
