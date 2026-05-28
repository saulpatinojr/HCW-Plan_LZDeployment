# Azure Landing Zone - Deployment Guide

## Overview

This guide walks you through deploying the complete Azure Landing Zone from scratch. Follow these steps in order.

**Estimated total deployment time**: 2-4 hours (depending on approval gates)

---

## Prerequisites

### Required Tools
- [ ] Azure CLI 2.60+ installed
- [ ] Terraform 1.9+ installed
- [ ] Git installed
- [ ] PowerShell 7+ (or Bash if Linux/Mac)
- [ ] Code editor (VS Code recommended)

**Verify installations**:
```powershell
az --version
terraform --version
git --version
pwsh --version
```

### Required Access
- [ ] Owner or User Access Administrator at tenant root (for management groups)
- [ ] Contributor on all target subscriptions
- [ ] Ability to create app registrations in Entra ID (for GitHub OIDC)

### Required Information
Gather these before starting:
- [ ] Tenant ID
- [ ] Subscription IDs (6 subscriptions: Identity, Connectivity, Management, Prod, NonProd, Sandbox)
- [ ] Organization prefix (2-4 letters, e.g., "hcw")
- [ ] Primary region (default: South Central US)
- [ ] DR region (default: North Central US)
- [ ] Hub address spaces (primary and DR, non-overlapping)
- [ ] Firewall choice (azfw, palo, or fortinet)

---

## Phase 1: Repository Setup

### 1.1 Clone Repository

```powershell
git clone https://github.com/saulpatinojr/HCW-Demo-LZDeployment.git
cd HCW-Demo-LZDeployment
```

### 1.2 Review Structure

```powershell
tree /F
# or
ls -R
```

Familiarize yourself with:
- `terraform/modules/` - Reusable components
- `terraform/live/` - Environment-specific deployments
- `.github/workflows/` - CI/CD automation
- `docs/day2/` - Operational documentation

---

## Phase 2: Bootstrap Terraform State Backend

### 2.1 Configure Backend Variables

```powershell
cd terraform/backend-bootstrap
cp terraform.tfvars.example terraform.tfvars
code terraform.tfvars  # or nano, vim, etc.
```

**Edit terraform.tfvars**:
```hcl
management_subscription_id = "REPLACE-WITH-YOUR-MANAGEMENT-SUBSCRIPTION-ID"
org_prefix                 = "hcw"  # Change to your org prefix
primary_region             = "southcentralus"
primary_region_code        = "scus"
allow_public_access_during_setup = true  # Set to false after private endpoint configured

default_tags = {
  owner       = "Platform Team"
  application = "Landing Zone Infrastructure"
  environment = "prod"
  cost_center = "IT-Platform"
  managed_by  = "Terraform"
}
```

### 2.2 Deploy State Backend

```powershell
# Authenticate to Azure
az login

# Set context to Management subscription
az account set --subscription "<MANAGEMENT_SUBSCRIPTION_ID>"

# Initialize Terraform
terraform init

# Review plan
terraform plan -out=tfplan

# Apply (this creates the state storage account)
terraform apply tfplan
```

### 2.3 Save Backend Configuration

**Important**: Note the outputs from the apply:
```powershell
terraform output
```

Copy the **storage_account_name** value. You'll need this for all subsequent layers.

**Example output**:
```
storage_account_name = "sthcwtfstate4k7n2x"
```

---

## Phase 3: Configure GitHub OIDC (for CI/CD)

### 3.1 Create Entra ID App Registration

```powershell
# Create app registration
$app = az ad app create --display-name "GitHub-Actions-HCW-LZ" | ConvertFrom-Json

# Create service principal
$sp = az ad sp create --id $app.appId | ConvertFrom-Json

# Assign Contributor at Management Group level (after MGs created) or subscription level for now
# For now, assign at each subscription:
$subscriptions = @(
    "<IDENTITY_SUBSCRIPTION_ID>",
    "<CONNECTIVITY_SUBSCRIPTION_ID>",
    "<MANAGEMENT_SUBSCRIPTION_ID>",
    "<WORKLOAD_PROD_SUBSCRIPTION_ID>",
    "<WORKLOAD_NONPROD_SUBSCRIPTION_ID>",
    "<SANDBOX_SUBSCRIPTION_ID>"
)

foreach ($subId in $subscriptions) {
    az role assignment create `
        --role "Contributor" `
        --assignee $sp.id `
        --scope "/subscriptions/$subId"
}

# Grant Storage Blob Data Contributor on state storage account
$storageAccountName = "<OUTPUT_FROM_BOOTSTRAP>"
$storageAccountId = az storage account show --name $storageAccountName --resource-group "rg-tfstate-scus-prod-01" --query id -o tsv

az role assignment create `
    --role "Storage Blob Data Contributor" `
    --assignee $sp.id `
    --scope $storageAccountId
```

### 3.2 Configure Federated Credentials

```powershell
$tenantId = az account show --query tenantId -o tsv

# For main branch deployments
az ad app federated-credential create `
    --id $app.id `
    --parameters @"
{
    \"name\": \"GitHub-HCW-LZ-Main\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:saulpatinojr/HCW-Demo-LZDeployment:ref:refs/heads/main\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
}
"@

# For pull request plans
az ad app federated-credential create `
    --id $app.id `
    --parameters @"
{
    \"name\": \"GitHub-HCW-LZ-PR\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:saulpatinojr/HCW-Demo-LZDeployment:pull_request\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
}
"@
```

### 3.3 Configure GitHub Secrets

In GitHub repository settings, add these secrets:

| Secret Name | Value |
|---|---|
| `AZURE_CLIENT_ID` | `$app.appId` (from step 3.1) |
| `AZURE_TENANT_ID` | `$tenantId` (your tenant ID) |
| `AZURE_SUBSCRIPTION_ID` | Management subscription ID (for default context) |

---

## Phase 4: Deploy Landing Zone Layers

### 4.1 Global Layer (Management Groups + Policies)

```powershell
cd ../../terraform/live/global

# Copy and configure variables
cp terraform.tfvars.example terraform.tfvars
code terraform.tfvars
```

**Edit terraform.tfvars** with your subscription IDs and org prefix.

**Update backend.hcl**:
```hcl
resource_group_name  = "rg-tfstate-scus-prod-01"
storage_account_name = "<OUTPUT_FROM_PHASE2>"  # Replace with actual storage account name
container_name       = "global-mgmt-groups"
key                  = "terraform.tfstate"
```

**Deploy**:
```powershell
terraform init -backend-config=backend.hcl
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

**Verify**:
- Open Azure Portal > Management Groups
- Confirm hierarchy: mg-<org>-root → platform/landingzones/sandbox
- Confirm subscriptions moved into correct management groups

---

### 4.2 Platform Connectivity Layer (Dual-Region Hubs)

```powershell
cd ../platform-connectivity

cp terraform.tfvars.example terraform.tfvars
code terraform.tfvars
```

**Edit terraform.tfvars**:
```hcl
connectivity_subscription_id = "<YOUR_CONNECTIVITY_SUB_ID>"

# Network configuration
primary_hub_address_space = "10.0.0.0/16"
dr_hub_address_space      = "10.10.0.0/16"

# IMPORTANT: Choose your firewall type
firewall_type = "azfw"  # or "palo" or "fortinet"
azfw_tier     = "Standard"  # or "Premium"

# Placeholders
deploy_bastion = true
deploy_dns     = true

management_ip_ranges = "*"  # Change to specific IP range for production
```

**Update backend.hcl** with correct storage account name.

**Deploy**:
```powershell
terraform init -backend-config=backend.hcl
terraform validate
terraform plan -out=tfplan
# Review plan carefully - this creates expensive resources (firewall, hubs)
terraform apply tfplan
```

**Verify**:
- Portal > Virtual Networks - confirm hub VNets in both regions
- Portal > Firewalls - confirm firewalls deployed (if azfw)
- Portal > Virtual Networks > Peerings - confirm hub-to-hub peering

**Save outputs**:
```powershell
terraform output -json > connectivity-outputs.json
```

---

### 4.3 Platform Management Layer (Backup + Automation)

```powershell
cd ../platform-management

# Configure terraform.tfvars with Management and Sandbox subscription IDs
# Update backend.hcl
terraform init -backend-config=backend.hcl
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

**Post-deployment**:
1. Verify automation account created
2. Verify runbook exists: `Cleanup-ExpiredSandboxResources`
3. Verify schedule is active (check Jobs after 02:00 UTC tomorrow)
4. Assign Contributor role to automation identity on Sandbox subscription:

```powershell
$automationIdentity = terraform output -raw automation_identity_principal_id
az role assignment create `
    --role "Contributor" `
    --assignee-object-id $automationIdentity `
    --assignee-principal-type ServicePrincipal `
    --scope "/subscriptions/<SANDBOX_SUBSCRIPTION_ID>"
```

---

### 4.4 Workload Production Spokes

```powershell
cd ../workloads-prod

# Configure terraform.tfvars with:
# - workload_prod_subscription_id
# - state backend details (for reading connectivity outputs)
# - spoke address spaces

terraform init -backend-config=backend.hcl
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

**Verify**:
- Spokes created in both regions
- Peerings established to hubs
- UDRs configured with default route to firewall

---

### 4.5 Sandbox Isolated Network

```powershell
cd ../sandbox

terraform init -backend-config=backend.hcl
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

**Verify**:
- Sandbox VNet created
- NO peerings (air-gapped)
- Resources tagged with environment=sandbox and expiry_date

---

## Phase 5: Validation

### 5.1 Management Group Structure

```powershell
az account management-group list --query "[].{Name:name, DisplayName:displayName}" -o table
```

Expected:
```
Name                DisplayName
mg-<org>-root       mg-<org>-root
mg-<org>-platform   mg-<org>-platform
mg-<org>-landingzones mg-<org>-landingzones
mg-<org>-sandbox    mg-<org>-sandbox
```

### 5.2 Policy Compliance

```powershell
az policy state summarize --management-group "mg-<org>-root"
```

### 5.3 Network Connectivity

**Test hub-to-hub**:
```powershell
# Deploy test VM in each hub (or use Bastion)
# Ping across hubs to verify peering
Test-NetConnection -ComputerName <DR-Hub-Private-IP> -Port 443
```

**Test spoke-to-hub**:
```powershell
# From spoke VM, verify can reach internet through firewall
Test-NetConnection -ComputerName 8.8.8.8 -Port 443
```

### 5.4 Backup Health

```powershell
$vault = Get-AzRecoveryServicesVault -Name "rsv-platform-scus-prod-01"
Get-AzRecoveryServicesVault -Name $vault.Name | Select-Object Name, Location, ProvisioningState
```

### 5.5 Terraform State Backend

```powershell
$storageAccountName = "<YOUR_STATE_STORAGE_ACCOUNT>"
az storage container list --account-name $storageAccountName --auth-mode login --query "[].name" -o table
```

Expected containers:
- global-mgmt-groups
- platform-connectivity
- platform-management
- workloads-prod
- sandbox-isolation

---

## Phase 6: GitHub Actions Setup

### 6.1 Configure GitHub Environments

1. Go to repository **Settings** > **Environments**
2. Create environment: **production**
   - Add protection rule: Required reviewers (select team lead)
   - Add protection rule: Wait timer (0 minutes for now)
3. Create environment: **sandbox**
   - No protection rules needed

### 6.2 Test CI/CD Pipeline

```powershell
# Create a test branch
git checkout -b test-cicd

# Make a small change (e.g., add a comment to a .tf file)
echo "# Test comment" >> terraform/live/sandbox/main.tf

# Commit and push
git add .
git commit -m "Test: CI/CD pipeline validation"
git push origin test-cicd
```

3. Open PR in GitHub
4. Verify **terraform-plan.yml** workflow runs
5. Review plan output in PR comments
6. Merge PR
7. Verify **terraform-apply.yml** workflow runs and waits for approval
8. Approve deployment in GitHub UI
9. Verify successful apply

---

## Phase 7: Day 2 Handoff

### 7.1 Documentation Review

Ensure operations team has reviewed:
- [Day 2 README](./docs/day2/README.md)
- [Daily Operations](./docs/day2/01-daily-operations.md)
- [Sandbox Lifecycle](./docs/day2/07-sandbox-lifecycle.md)
- [Incident Triage](./docs/day2/04-incident-triage.md)
- [Change Management](./docs/day2/05-change-management.md)
- [Escalation Matrix](./docs/day2/10-escalation-matrix.md)

### 7.2 Access Provisioning

Assign RBAC roles:
- **Platform Admins**: Owner at Platform MG
- **Network Ops**: Network Contributor on Connectivity subscription
- **Security**: Security Reader at root MG
- **Workload Teams**: Contributor on their subscriptions
- **Junior Admins**: Reader at root + Contributor in sandbox

### 7.3 Monitoring Setup

1. Create dashboard in Azure Portal with:
   - Policy compliance widget
   - Backup job status
   - Firewall health metrics
   - Cost trends
2. Configure alerts (if not already automated):
   - Backup failures
   - Policy compliance < 95%
   - Firewall health < 90%

### 7.4 Communication

- [ ] Announce landing zone availability to stakeholders
- [ ] Share documentation links
- [ ] Schedule knowledge transfer sessions
- [ ] Establish on-call rotation
- [ ] Confirm escalation contacts

---

## Troubleshooting Deployment Issues

### Issue: Terraform Backend Authentication Fails

**Symptoms**: `Error: Retrieving state from backend: Access Denied`

**Resolution**:
```powershell
# Verify you're authenticated
az account show

# Ensure you have Storage Blob Data Contributor role
$storageAccountId = az storage account show --name "<STATE_STORAGE>" --resource-group "rg-tfstate-scus-prod-01" --query id -o tsv
az role assignment create --role "Storage Blob Data Contributor" --assignee $(az account show --query user.name -o tsv) --scope $storageAccountId
```

---

### Issue: Management Group Creation Fails

**Symptoms**: `Error: Insufficient privileges to perform management group operations`

**Resolution**:
- Verify you have Owner or User Access Administrator at tenant root
- May require manual elevation in Azure Portal > Management Groups > elevate access

---

### Issue: Firewall Deployment Slow

**Symptoms**: Terraform apply takes > 30 minutes on firewall creation

**Resolution**:
- This is normal - Azure Firewall can take 20-40 minutes to deploy
- Do not cancel the apply
- Monitor Azure Portal for provisioning status

---

## Next Steps

After successful deployment:

1. **Week 1**: Shadow operations team, perform daily checks
2. **Week 2**: Execute first standard change
3. **Month 1**: Complete first DR test
4. **Ongoing**: Continuous improvement based on lessons learned

## Support

For deployment assistance:
- Slack: #azure-platform-support
- Email: azure-platform-team@company.com
- Escalation: See [Escalation Matrix](./docs/day2/10-escalation-matrix.md)
