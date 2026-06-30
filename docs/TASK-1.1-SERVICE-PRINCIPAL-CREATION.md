# Task 1.1: Service Principal RBAC Validation & Scoping

**Status**: ⏳ NOT STARTED (Ready for Implementation)  
**Priority**: 🔴 P0 - CRITICAL  
**CVSS Score**: 9.1  
**Effort Estimate**: 8 hours total  
**Cost**: $0

---

## Overview

Replace generic/shared service principals with least-privilege, role-scoped service principals for each deployment layer. This ensures:

1. **Principle of Least Privilege**: Each SP has minimum required permissions
2. **Blast Radius Limitation**: Compromise of one SP affects only one layer
3. **Audit Trail**: Actions traceable to specific deployment context
4. **Compliance**: Meets security standards (no Owner roles, scoped access)

---

## Current State (Pre-Implementation)

**Issue**: Likely using a single shared service principal with broad permissions
- Probably has Owner or Contributor at subscription level
- No layer/environment isolation
- Difficult to audit which deployment did what
- High blast radius if credentials compromised

---

## Target Architecture

### 5-Layer Service Principal Model

```
Layer 1: Global (state, encryption, backups)
  └─ SP: sp-terraform-global-prod
     Role: Contributor
     Scope: Management subscription or dedicated global subscription
     Purpose: Global infrastructure (Key Vault, storage, etc.)

Layer 2: Connectivity (hub network, firewall, gateways)
  └─ SP: sp-terraform-connectivity-prod
     Role: Contributor
     Scope: Connectivity subscription ONLY
     Purpose: Network infrastructure

Layer 3: Management (logging, monitoring, policies)
  └─ SP: sp-terraform-management-prod
     Role: Contributor
     Scope: Management subscription ONLY
     Purpose: Platform management & compliance

Layer 4: Workloads Production
  └─ SP: sp-terraform-workloads-prod
     Role: Contributor
     Scope: Production subscription ONLY
     Purpose: Production workloads

Layer 5: Workloads Non-Production (Dev/Test/Sandbox)
  ├─ SP: sp-terraform-workloads-nonprod
  │  Role: Contributor
  │  Scope: Non-production subscription ONLY
  │  Purpose: Staging/testing
  └─ SP: sp-terraform-sandbox-dev (alias for nonprod or separate)
     Role: Contributor
     Scope: Sandbox subscription (if separate) or nonprod
     Purpose: Sandbox experimentation
```

### OIDC Federated Credentials Per Layer

Each SP has **federated credentials** scoped to branches (NOT long-lived secrets):

```
sp-terraform-global-prod:
  ├─ Credential: GitHub repo:branch repo:ref:refs/heads/main
  │  Purpose: Deployments from main branch (production)
  └─ Credential: GitHub repo:branch repo:ref:refs/heads/develop
     Purpose: Deployments from develop branch (staging)

sp-terraform-connectivity-prod:
  ├─ Credential: GitHub repo:branch repo:ref:refs/heads/main
  └─ Credential: GitHub repo:branch repo:ref:refs/heads/develop

[Repeat for other SPs...]
```

**Benefit**: No stored secrets; OIDC token is ephemeral and branch-scoped

---

## Implementation Plan

### Phase 1: Audit Current State (1-2 hours)

**Goal**: Understand existing SP permissions and identify security gaps

#### Step 1.1: List Current Service Principals

```bash
# Get current service principal client ID
$ClientId = (az ad app list --display-name "GitHub" --query "[0].appId" -o tsv)
echo "Current GitHub SP Client ID: $ClientId"

# List all role assignments for this SP
az role assignment list \
  --assignee $ClientId \
  --all \
  --output table
```

**Expected Output Analysis**:
- Identify current roles (should NOT see "Owner")
- Identify current scope (subscription, management group, resource group)
- Document any unexpected permissions

#### Step 1.2: Check for Owner Role Assignments

```bash
# Critical: No SP should have Owner role
az role assignment list \
  --all \
  --query "?principalType=='ServicePrincipal' && roleDefinitionName=='Owner'" \
  --output table
```

**Action**: If any SPs have Owner role, immediately remove:
```bash
az role assignment delete \
  --assignee $ClientId \
  --role "Owner" \
  --scope "/subscriptions/$SubscriptionId"
```

#### Step 1.3: Document Current OIDC Credentials

```bash
# List federated credentials for current SP
az ad app federated-credential list \
  --id $ClientId \
  --query "[].{name:name, audiences:audiences, issuer:issuer, subject:subject}" \
  --output table
```

**Expected Findings**:
- List existing federated credentials
- Note which branches are configured
- Identify any static credentials that should be removed

#### Step 1.4: Audit Report

**Create file**: `docs/RBAC-AUDIT-BASELINE.md`

Document:
```markdown
# RBAC Audit Baseline (Current State)

## Service Principals
- Current SP: [name]
- Client ID: [guid]
- Current Roles: [list]
- Current Scope: [subscription/MG/RG]

## Issues Found
- [ ] Owner role assignments (CRITICAL)
- [ ] Overly broad scope (e.g., Management Group)
- [ ] Multiple SPs when one should exist
- [ ] Static credentials instead of OIDC

## Findings
- [List all security gaps]

## Recommendation
- Replace with 5-layer SP model
- Scope each to single subscription
- Use OIDC federated credentials
```

---

### Phase 2: Create 5-Layer Service Principal Structure (3-4 hours)

**Goal**: Create new service principals with least-privilege RBAC

#### Step 2.1: Create PowerShell Script

**File**: `scripts/001_Create_Service_Principals.ps1`

**Responsibilities**:
1. Create 5 Entra applications (one per layer)
2. Create service principals from applications
3. Assign Contributor role (scoped to specific subscriptions)
4. Remove any Owner role assignments
5. Create OIDC federated credentials (main + develop branches)
6. Generate output report with SP IDs

**Script Structure**:

```powershell
# Configuration
$ServicePrincipals = @(
    @{
        Name       = "sp-terraform-global-prod"
        DisplayName = "Terraform Global Infrastructure"
        SubscriptionId = $GlobalSubscriptionId
    },
    @{
        Name       = "sp-terraform-connectivity-prod"
        DisplayName = "Terraform Connectivity Infrastructure"
        SubscriptionId = $ConnectivitySubscriptionId
    },
    @{
        Name       = "sp-terraform-management-prod"
        DisplayName = "Terraform Management Infrastructure"
        SubscriptionId = $ManagementSubscriptionId
    },
    @{
        Name       = "sp-terraform-workloads-prod"
        DisplayName = "Terraform Workloads Production"
        SubscriptionId = $WorkloadsProdSubscriptionId
    },
    @{
        Name       = "sp-terraform-workloads-nonprod"
        DisplayName = "Terraform Workloads Non-Production"
        SubscriptionId = $WorkloadsNonProdSubscriptionId
    }
)

# For each SP:
foreach ($sp in $ServicePrincipals) {
    # 1. Create Entra app registration
    # 2. Create service principal
    # 3. Assign Contributor role (scoped to subscription)
    # 4. Create OIDC federated credentials (main + develop)
    # 5. Output SP details
}
```

**Key Functions**:

```powershell
function New-ServicePrincipal {
    param(
        [string]$Name,
        [string]$DisplayName,
        [string]$SubscriptionId
    )
    
    # Create Entra app registration
    $app = az ad app create --display-name $DisplayName --json | ConvertFrom-Json
    $appId = $app.appId
    
    # Create service principal
    $sp = az ad sp create --id $appId --json | ConvertFrom-Json
    $spId = $sp.id
    
    # Assign Contributor role (scoped to subscription)
    az role assignment create `
        --assignee $spId `
        --role "Contributor" `
        --scope "/subscriptions/$SubscriptionId"
    
    # Create OIDC federated credentials
    foreach ($branch in @("main", "develop")) {
        az ad app federated-credential create `
            --id $appId `
            --parameters @{
                name = "gh-$Name-$branch"
                issuer = "https://token.actions.githubusercontent.com"
                subject = "repo:saulpatinojr/HCW-Plan_LZDeployment:ref:refs/heads/$branch"
                audiences = @("api://AzureADTokenExchange")
            }
    }
    
    return @{
        Name       = $Name
        AppId      = $appId
        SpId       = $spId
        SubscriptionId = $SubscriptionId
    }
}
```

**Output**: 
- Console log with all created SPs
- File: `rbac-audit-output.json` with SP IDs and credentials
- File: `rbac-implementation-report.md` with audit trail

---

#### Step 2.2: Configure GitHub Secrets

After SPs created, update GitHub secrets with SP identifiers (NOT credentials):

```bash
# Set GitHub secrets for each SP
# Format: AZURE_CLIENT_ID_[LAYER] and AZURE_SUBSCRIPTION_ID_[LAYER]

gh secret set AZURE_CLIENT_ID_GLOBAL --body $spIdGlobal
gh secret set AZURE_SUBSCRIPTION_ID_GLOBAL --body $subscriptionIdGlobal

gh secret set AZURE_CLIENT_ID_CONNECTIVITY --body $spIdConnectivity
gh secret set AZURE_SUBSCRIPTION_ID_CONNECTIVITY --body $subscriptionIdConnectivity

# ... repeat for other layers
```

**Note**: These are just identifiers. Actual authentication happens via OIDC token.

---

### Phase 3: Validation & Testing (2-3 hours)

**Goal**: Ensure new SPs work and have proper permissions

#### Step 3.1: Verify SP Permissions

```bash
# For each SP, verify:
# 1. Has Contributor role (NOT Owner)
# 2. Scoped to correct subscription only
# 3. Has OIDC credentials (main + develop branches)

foreach ($sp in $ServicePrincipals) {
    Write-Host "Validating $($sp.Name)..."
    
    # Check for Owner role (should return 0)
    $ownerRoles = az role assignment list `
        --assignee $sp.ClientId `
        --query "?roleDefinitionName=='Owner'" | ConvertFrom-Json
    
    if ($ownerRoles.Count -gt 0) {
        Write-Error "FAIL: $($sp.Name) has Owner role!"
        exit 1
    }
    
    # Check subscription scope
    $roles = az role assignment list --assignee $sp.ClientId
    Write-Host "  Roles: $($roles)"
    
    # Check OIDC credentials
    $creds = az ad app federated-credential list --id $sp.AppId
    Write-Host "  OIDC Credentials: $($creds.Count)"
}
```

#### Step 3.2: Test OIDC Authentication

```bash
# Simulate GitHub Actions workflow OIDC token
# This requires GitHub Actions to run, so test in CI/CD context

# In workflow (100-terraform-plan.yml):
- name: Login to Azure with OIDC
  uses: azure/login@v2
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

# Should succeed without any secrets stored
```

#### Step 3.3: Create Validation Report

**File**: `rbac-implementation-report.md`

Document:
```markdown
# RBAC Implementation Report

## Service Principals Created
| Name | AppId | Subscription | Role | Scope |
|------|-------|-------------|------|-------|
| sp-terraform-global-prod | [appid] | [sub] | Contributor | Subscription |
| ... | ... | ... | ... | ... |

## Security Validation
- [x] No Owner roles assigned
- [x] Each SP scoped to single subscription (except global)
- [x] OIDC federated credentials created
- [x] GitHub secrets configured (identifiers only)
- [x] No static credentials stored

## Audit Trail
- Created: [timestamp]
- Created by: [user]
- Script: scripts/001_Create_Service_Principals.ps1
- Validation: scripts/002_Validate_RBAC.ps1
```

---

### Phase 4: Integration with CI/CD (1-2 hours)

**Goal**: Update workflows to use new layer-specific SPs

#### Step 4.1: Update Workflow 010 (Terraform Init)

**File**: `.github/workflows/010-terraform-init.yml`

```yaml
name: 'Terraform Cloud Initialization (Phase 0.1)'

on:
  workflow_dispatch:  # Manual trigger only
  push:
    branches: [main]
    paths:
      - 'terraform/**'
      - '.github/workflows/010-*'

jobs:
  terraform-init:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        layer: [global, connectivity, management, workloads-prod, workloads-nonprod]
    
    steps:
    - uses: actions/checkout@v4
      with:
        fetch-depth: 0
    
    # OIDC login using layer-specific SP
    - name: Login to Azure (OIDC)
      uses: azure/login@v2
      with:
        client-id: ${{ secrets[format('AZURE_CLIENT_ID_{0}', matrix.layer)] }}
        tenant-id: ${{ secrets.AZURE_TENANT_ID }}
        subscription-id: ${{ secrets[format('AZURE_SUBSCRIPTION_ID_{0}', matrix.layer)] }}
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: ~> 1.6
    
    - name: Terraform Init (TFC Backend)
      env:
        TF_API_TOKEN: ${{ secrets.TF_API_TOKEN }}
        TF_CLOUD_ORGANIZATION: ${{ vars.TF_CLOUD_ORGANIZATION }}
      run: |
        cd terraform/live/${{ matrix.layer }}
        terraform init -upgrade
    
    - name: Terraform Format Check
      run: |
        cd terraform/live/${{ matrix.layer }}
        terraform fmt -check -recursive
    
    - name: Terraform Validate
      run: |
        cd terraform/live/${{ matrix.layer }}
        terraform validate
```

---

#### Step 4.2: Update Workflow 020 (RBAC Validation)

**File**: `.github/workflows/020-rbac-validation.yml`

```yaml
name: 'RBAC Validation & Audit (Phase 1.1)'

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 9 * * MON'  # Weekly on Mondays
  workflow_dispatch:

jobs:
  rbac-audit:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    # Use management SP for audit (read-only)
    - name: Login to Azure (Audit SP)
      uses: azure/login@v2
      with:
        client-id: ${{ secrets.AZURE_CLIENT_ID_MANAGEMENT }}
        tenant-id: ${{ secrets.AZURE_TENANT_ID }}
        subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID_MANAGEMENT }}
    
    - name: Run RBAC Validation Script
      run: |
        pwsh -File scripts/002_Validate_RBAC.ps1 `
          -CheckOwnerRoles $true `
          -CheckFederatedCredentials $true `
          -GenerateReport $true
    
    - name: Upload Audit Report
      if: always()
      uses: actions/upload-artifact@v4
      with:
        name: rbac-audit-report-${{ github.run_id }}
        path: rbac-audit-*.md
        retention-days: 90
    
    - name: Comment on PR
      if: github.event_name == 'pull_request'
      uses: actions/github-script@v7
      with:
        script: |
          const fs = require('fs');
          const report = fs.readFileSync('rbac-audit-report.md', 'utf8');
          github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: `## RBAC Validation Results\n\n${report}`
          });
```

---

### Phase 5: Documentation & Handoff (1-2 hours)

**Goal**: Document the implementation for operations team

#### Step 5.1: Create Service Principal Guide

**File**: `docs/SERVICE-PRINCIPAL-GUIDE.md`

```markdown
# Service Principal Management Guide

## Overview
Five-layer least-privilege SP model for secure Terraform deployments.

## Service Principals

| Layer | SP Name | Subscription | Role | Purpose |
|-------|---------|-------------|------|---------|
| Global | sp-terraform-global-prod | global | Contributor | Global infrastructure |
| Connectivity | sp-terraform-connectivity-prod | connectivity | Contributor | Network layer |
| Management | sp-terraform-management-prod | management | Contributor | Management/monitoring |
| Workloads Prod | sp-terraform-workloads-prod | workloads-prod | Contributor | Production workloads |
| Workloads Non-Prod | sp-terraform-workloads-nonprod | workloads-nonprod | Contributor | Dev/test/sandbox |

## OIDC Federated Credentials

Each SP has branch-scoped OIDC credentials:
- `main` branch → Production deployment
- `develop` branch → Staging deployment

No static credentials stored.

## Adding New Service Principals

```bash
pwsh scripts/001_Create_Service_Principals.ps1 `
  -ServicePrincipalName "sp-terraform-new-layer" `
  -SubscriptionId "12345678-1234-1234-1234-123456789012"
```

## Validating Permissions

```bash
pwsh scripts/002_Validate_RBAC.ps1 -CheckOwnerRoles $true
```

## Revoking Access

```bash
az ad sp delete --id $SpId
az ad app delete --id $AppId
```

## Troubleshooting

### OIDC Authentication Failed
- Verify federated credential exists
- Check subject format: `repo:owner/repo:ref:refs/heads/branch`
- Ensure GitHub environment variables match

### Permission Denied Errors
- Verify SP has Contributor role
- Verify role is scoped to correct subscription
- Check role assignment propagation (can take minutes)
```

#### Step 5.2: Create RBAC Audit Procedures

**File**: `docs/RBAC-AUDIT-PROCEDURES.md`

```markdown
# RBAC Audit Procedures

## Weekly Audit
Automatically runs Monday mornings via workflow 020.

## Manual Audit

```bash
pwsh scripts/002_Validate_RBAC.ps1 `
  -CheckOwnerRoles $true `
  -CheckFederatedCredentials $true `
  -GenerateReport $true
```

## Audit Checklist

- [ ] No SPs have Owner role
- [ ] Each SP scoped to single subscription (except global)
- [ ] OIDC federated credentials valid for main + develop
- [ ] No static credentials stored
- [ ] GitHub secrets match SP IDs
- [ ] Recent deployments traceable to correct SP

## Responding to Audit Failures

### Owner Role Detected
1. Immediately remove Owner role
2. Report to security team
3. Review recent actions by that SP
4. Update workflow 020 alert threshold

### Federated Credential Missing
1. Recreate federated credential
2. Update GitHub secrets
3. Verify branch access

### Static Credential Found
1. Remove static credential immediately
2. Rotate SP password
3. Check audit logs for usage
4. Enable OIDC authentication
```

---

## Acceptance Criteria

✅ All acceptance criteria from Task 1.1 in TODO.md:

- [ ] No service principal has Owner role
- [ ] Each SP scoped to single subscription
- [ ] RBAC validation passes in CI/CD (workflow 020)
- [ ] Deployment succeeds with least-privilege SPs

**Plus additional**:

- [ ] 5 service principals created with unique names
- [ ] OIDC federated credentials configured (main + develop per SP)
- [ ] GitHub secrets updated with SP IDs
- [ ] Audit scripts created and tested
- [ ] Workflows 010 & 020 updated for layer-specific SPs
- [ ] Documentation complete (guides, procedures, troubleshooting)
- [ ] Baseline audit report created
- [ ] Implementation audit report created
- [ ] No breaking changes to existing deployments

---

## Files to Create/Update

### New Files
- [ ] `scripts/001_Create_Service_Principals.ps1` (3-4h coding)
- [ ] `scripts/002_Validate_RBAC.ps1` (2-3h coding)
- [ ] `docs/SERVICE-PRINCIPAL-GUIDE.md` (1h)
- [ ] `docs/RBAC-AUDIT-PROCEDURES.md` (1h)
- [ ] `docs/RBAC-AUDIT-BASELINE.md` (audit output)
- [ ] `rbac-implementation-report.md` (script output)

### Update Existing
- [x] `.github/workflows/010-terraform-init.yml` (already in PR #6)
- [x] `.github/workflows/020-rbac-validation.yml` (already in PR #6)
- [x] `docs/RBAC-REQUIREMENTS.md` (already in PR #6)

---

## Timeline

| Phase | Activity | Duration | Blocker |
|-------|----------|----------|---------|
| 1 | Audit current state | 1-2h | None |
| 2 | Create SP creation script | 3-4h | Phase 1 complete |
| 2 | Create SP validation script | 2-3h | Phase 1 complete |
| 3 | Test SPs & OIDC | 1-2h | Phase 2 complete |
| 4 | Update workflows | 1-2h | Phase 3 complete |
| 5 | Document procedures | 1-2h | Phase 4 complete |
| **TOTAL** | | **8-15h** | |

---

## Risk Mitigation

**Risk**: New SPs don't have correct permissions
- **Mitigation**: Comprehensive validation script (002) checks all conditions
- **Fallback**: Keep old SP active during transition period

**Risk**: OIDC authentication fails in CI/CD
- **Mitigation**: Test OIDC end-to-end before removing static credentials
- **Fallback**: Temporary static credential for emergency access only

**Risk**: Workflow 020 audit fails after implementation
- **Mitigation**: Run validation script locally before committing
- **Fallback**: Temporarily disable workflow 020 while troubleshooting

---

## Success Criteria

**Deployment passes workflow 100 (terraform plan) using new SPs** ← This is the final validation that everything works.

No manual deployments until this succeeds.
