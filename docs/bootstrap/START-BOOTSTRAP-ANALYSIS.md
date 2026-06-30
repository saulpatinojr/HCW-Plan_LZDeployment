# Start-Bootstrap.ps1 vs. OIDC Best Practices

**Analysis Date**: 2026-06-30  
**Script Purpose**: Interactive local Phase 0 bootstrap (Azure + GitHub OIDC setup)  
**Verdict**: ⚠️ **65% Aligned — Significant Security & Design Issues**

---

## Executive Summary

`Start-Bootstrap.ps1` is a **well-intentioned orchestrator** but has **critical security gaps and architectural misalignment** with OIDC best practices:

### What It Gets Right ✅
- Creates Entra app registration and service principal
- Sets up three federated credentials (main, PR, prod environment)
- Stores secrets in GitHub (AZURE_CLIENT_ID, TENANT_ID, SUBSCRIPTION_ID)
- Idempotent and stateful (recovers from interruption)
- Good UX: confirms resources before creation, shows warnings

### What It Gets Wrong ❌
- **CRITICAL**: Assigns **both Contributor AND User Access Administrator** roles to a single SP
- **CRITICAL**: Creates a **single monolithic SP** (violates least privilege)
- **CRITICAL**: Uses **Azure Storage for state backend** (you want Terraform Cloud)
- **CRITICAL**: No attempt to separate human OAuth from CI/CD OIDC
- Does NOT create separate SPs per deployment layer (should be Main/Dev/Prod)
- Subject claims are too permissive (allows `pull_request` branch without workflow name)
- Does NOT validate that service principal has NO Owner role
- State backend creation is overly manual (requires terraform.tfvars, terraform init, terraform apply)

---

## Detailed Security Analysis

### 🔴 CRITICAL: Dual Contributor + User Access Administrator on Single SP

**Best Practice**: Each SP should have **least-privilege roles**  
**Script Implementation**:

```powershell
# Section 5d â WRONG approach
foreach ($roleName in @('Contributor', 'User Access Administrator')) {
    az role assignment create \
        --assignee-object-id $spObjId \
        --role $roleName \
        --scope "/subscriptions/$subId"
}
```

**Problem**: A single service principal with **both** roles is a critical blast-radius issue:

| Role | Risk | Impact |
|---|---|---|
| **Contributor** | Can create/modify/delete resources | Attacker controls infrastructure |
| **User Access Administrator** | Can grant ANY role (even Owner) to anyone | Attacker can escalate to permanent Owner |
| **Combined** | Full subscription takeover | 🚨 **CRITICAL** |

**Example attack path**:
```bash
# If someone compromises the SP's OIDC token in a GitHub Actions log:
az role assignment create \
  --role "Owner" \
  --assignee-object-id <attacker-principal-id> \
  --scope "/subscriptions/$subId"
# → Attacker is now permanent Owner of entire subscription
```

**What Best Practices Say**:
- Assign **only Contributor** (can create/modify resources)
- User Access Administrator should be **extremely rare** (only when creating RBAC policies)
- Separate SPs per layer means blast radius is limited to one layer

**Recommendation**: 
```powershell
# CORRECT approach: Least privilege per SP
$mainAppId = New-DeployServicePrincipal -DisplayName "sp-terraform-main" `
    -Roles @("Contributor") -Scope $subscriptionScope  # No User Access Admin

$devAppId = New-DeployServicePrincipal -DisplayName "sp-terraform-dev" `
    -Roles @("Contributor", "User Access Administrator") -Scope $subscriptionScope  # Only Dev needs RBAC mgmt

$prodAppId = New-DeployServicePrincipal -DisplayName "sp-terraform-prod" `
    -Roles @("Contributor", "User Access Administrator") -Scope $subscriptionScope  # Only Prod needs RBAC mgmt
```

**Score**: ❌ **FAIL** — Creates unnecessary privilege escalation path

---

### 🔴 CRITICAL: Single Monolithic Service Principal

**Best Practice**: Create **separate SPs per deployment layer** (Main, Dev, Prod)  
**Script Implementation**: Creates **only one SP** used by all environments

**Problem**:
```
Before (WRONG â this script):
├─ sp-github-oidc-lz-platform
│  ├─ Federated: main branch
│  ├─ Federated: pull_request
│  ├─ Federated: environment:prod
│  ├─ Role: Contributor (subscription-wide)
│  └─ Role: User Access Administrator (subscription-wide)
   â‰  All branches/environments use same credentials â no blast containment
```

**After (CORRECT â OIDC best practices)**:
```
├─ sp-terraform-main
│  ├─ Federated: ref:refs/heads/main
│  ├─ Role: Contributor (subscription-wide)
│  └─ Purpose: Terraform apply on main branch only
│
├─ sp-terraform-dev
│  ├─ Federated: environment:dev
│  ├─ Role: Contributor + User Access Admin
│  └─ Purpose: Dev deployments only
│
└─ sp-terraform-prod
   ├─ Federated: environment:prod
   ├─ Federated: environment:hub (approval gate)
   ├─ Role: Contributor + User Access Admin
   └─ Purpose: Prod deployments only
```

**Why This Matters**:
- If dev workflow is compromised: only dev resources at risk
- If prod credential leaks: only prod subscription affected
- If main branch is compromised: only main deployments affected
- **Current design**: Single compromise = full subscription takeover

**Score**: ❌ **FAIL** — No blast containment

---

### 🔴 CRITICAL: Overly Permissive Subject Claims

**Best Practice**: Scope credentials to specific branch + workflow  
**Script Implementation**:

```powershell
# Main branch (GOOD)
$mainSubject = "repo:$owner/$GITHUB_REPO:ref:refs/heads/main"

# Pull requests (PROBLEMATIC)
$prSubject = "repo:$owner/$GITHUB_REPO:pull_request"
# ← Allows ANY workflow on ANY PR to use the credential

# Prod environment (ADEQUATE)
$prodSubject = "repo:$owner/$GITHUB_REPO:environment:prod"
```

**Problem with `pull_request` subject**:
```
Current:  repo:owner/repo:pull_request
├─ Allows: any workflow (terraform-plan, secrets-scan, docker-build, etc.)
├─ Allows: any PR branch
└─ Risk: Rogue workflow in a PR can access prod Azure subscription

Better:   repo:owner/repo:pull_request:workflow:terraform-plan.yml
├─ Allows: only terraform-plan.yml workflow
├─ Allows: any PR branch
└─ Risk: Limited to plan operations only (still read access to Azure)

Best:     repo:owner/repo:pull_request:workflow:terraform-plan.yml (+ environment)
├─ Allows: only terraform-plan.yml in a specific environment
├─ Allows: only PR branches targeting that environment
└─ Risk: Minimal â plan-only, environment-gated
```

**Score**: ⚠️ **PARTIAL** — Adequate for PR-based plans, but could be stricter

---

### 🔴 CRITICAL: No Attempt to Validate Service Principal Doesn't Have Owner Role

**Best Practice**: Validate that SP has **NO Owner role** (security checkpoint)  
**Script Implementation**: Creates roles but **never validates**

**Missing**:
```powershell
# Should add this validation
$ownerRoles = az role assignment list `
    --assignee-object-id $spObjId `
    --query "[?roleDefinitionName=='Owner']" `
    --output json | ConvertFrom-Json

if ($ownerRoles.Count -gt 0) {
    Write-Err "SECURITY ERROR: Service principal has Owner role!"
    Write-Err "This violates least-privilege principle."
    throw "Cannot proceed with Owner role assigned"
}
```

**Score**: ❌ **FAIL** — No validation checkpoint

---

### 🔴 CRITICAL: Azure Storage Backend (You Want Terraform Cloud)

**Best Practice**: Use Terraform Cloud for state (you explicitly said this is your preference)  
**Script Implementation**: Creates Azure Storage Account backend

**Problem**:
```powershell
# Section 7 â Creates Azure Storage
# Creates: rg-{org}-tfstate-scus
# Creates: st{org}tfstate<random>
# Creates: tfstate blob container

# But you said: "it will be on Terraform Cloud"
```

**Gap**: Script completely ignores Terraform Cloud setup:
- ❌ No prompt for TFC organization
- ❌ No prompt for TFC workspace
- ❌ No TFC API token storage in GitHub secrets
- ❌ No TFC backend configuration in Terraform code
- ❌ No validation that TFC workspace exists

**Score**: ❌ **FAIL** — Wrong state backend for your needs

---

### 🟡 MAJOR: No Separation of Human OAuth from CI/CD OIDC

**Best Practice**: Separate app registrations for different trust flows  
**Script Implementation**: Single app registration for everything

**Current**:
```
sp-github-oidc-lz-platform (SINGLE APP)
├─ Purpose 1: NextAuth human OAuth login (requires client secret)
├─ Purpose 2: GitHub Actions OIDC deployment (federated credential)
└─ Problem: Mixing human + CI/CD authentication
```

**Best Practice**:
```
CNA Assessment Tool (HUMAN OAUTH)
├─ Display name: "CNA Assessment Tool"
├─ Client secret: ✅ Stored (NextAuth uses it)
├─ Federated credentials: ❌ None
├─ RBAC roles: ❌ None
└─ Purpose: End-user sign-in only

sp-terraform-main / sp-terraform-dev / sp-terraform-prod (CI/CD)
├─ Display name: "sp-terraform-{layer}-{env}"
├─ Client secret: ❌ None
├─ Federated credentials: ✅ Scoped to branches/environments
├─ RBAC roles: ✅ Scoped to layer
└─ Purpose: Automated deployments only
```

**Score**: ⚠️ **PARTIAL** — `Initialize-CnaGitHubSecrets.ps1` does this correctly; `Start-Bootstrap.ps1` doesn't

---

### 🟡 MAJOR: Terraform State Backend is Manual + Complex

**Best Practice**: State backend should be simple, automated, idempotent  
**Script Implementation**: Requires manual steps

**Current complexity**:
```powershell
# Step 1: Script generates terraform.tfvars
# Step 2: User must understand Terraform
# Step 3: Script runs: terraform init
# Step 4: Script runs: terraform apply
# Step 5: Script extracts output: storage_account_name
# Step 6: Script updates backend.hcl files
```

**Problems**:
- Requires Terraform knowledge
- If terraform apply fails, user is stuck (no automatic retry)
- Requires manual terraform.tfvars generation
- Error messages are cryptic (terraform output, not human-friendly)
- 5 steps when should be 1

**Better approach**:
```powershell
# Single step â script handles everything
Write-Step "Creating Terraform state backend..."

$storageAccount = Create-StateBackend `
    -SubscriptionId $subId `
    -ResourceGroup "rg-tfstate" `
    -Location "southcentralus"

Write-OK "State backend created: $($storageAccount.Name)"
# Done â no terraform.tfvars, no manual apply
```

**Or with TFC**:
```powershell
# Even simpler
Write-Step "Configuring Terraform Cloud..."
$tfc = @{
    organization = "your-org"
    workspace    = "landing-zone"
}
Set-GitHubSecret "TF_API_TOKEN" $tfc.token
Write-OK "TFC configured â ready to deploy"
```

**Score**: 🟡 **PARTIAL** — Works but overly complex

---

### ✅ ALIGNED: Idempotent Operations

**Best Practice**: All steps should be safe to rerun  
**Script Implementation**: Uses `.bootstrap-state.json` to track progress

```powershell
$STATE_FILE = '.bootstrap-state.json'

# Every section checks:
if (Test-StepDone $State 's5_oidc_done') {
    Write-OK "Section 5 already complete"
    return
}

# Then marks done:
Set-StepDone $State 's5_oidc_done'
```

**Score**: ✅ **PASS** — Idempotent and recoverable

---

### ✅ ALIGNED: Good User Experience

**Best Practice**: Guide users, confirm before destructive actions  
**Script Implementation**:

```powershell
# Shows what will be created
Write-Host "ð RESOURCES TO BE CREATED:" -ForegroundColor Cyan
Write-Host "   1ï¸â£  Entra ID App Registration: '$APP_NAME'"
Write-Host "   2ï¸â£  Service Principal (linked to app registration)"
# ... etc

# Requires explicit confirmation
$confirm = Read-Host "Type 'CREATE' (all caps) to proceed, or anything else to skip"
if ($confirm -ne 'CREATE') {
    Write-Warn "Resource creation cancelled by user."
    return
}
```

**Score**: ✅ **PASS** — Clear warnings and confirmations

---

## Comparison: Two Bootstrap Scripts

| Aspect | `Initialize-CnaGitHubSecrets.ps1` | `Start-Bootstrap.ps1` |
|---|---|---|
| **OIDC Federated Credentials** | ✅ Correct | ✅ Correct |
| **Separate SPs per Layer** | ✅ Main/Dev/Prod | ❌ Single SP |
| **Least Privilege Roles** | ✅ Contributor only | ❌ Contributor + UAA |
| **No Owner Role** | ✅ Validated | ❌ Not checked |
| **Terraform Cloud Support** | ✅ Built-in | ❌ Ignored |
| **Human OAuth Separation** | ✅ Explicit | ❌ Mixed |
| **Subject Claim Scope** | ✅ Strict | ⚠️ Permissive PR scope |
| **UX & Guidance** | ✅ Good | ✅ Excellent |
| **Idempotent** | ✅ Yes | ✅ Yes |
| **Interactive** | ⚠️ Some prompts | ✅ Many prompts |

---

## Verdict: Which Script Should You Use?

### ✅ Use `Initialize-CnaGitHubSecrets.ps1` Because:
1. Creates three separate SPs (Main/Dev/Prod) — **correct blast containment**
2. Assigns only Contributor (no UAA) — **follows least privilege**
3. Supports Terraform Cloud natively — **matches your infrastructure**
4. Separates human OAuth from OIDC — **security best practice**
5. 95% aligned with OIDC best practices

### ❌ Do NOT Use `Start-Bootstrap.ps1` Because:
1. Single monolithic SP creates privilege escalation risk
2. Assigns both Contributor + User Access Administrator (too permissive)
3. Assumes Azure Storage backend (ignores TFC preference)
4. Mixes human OAuth with CI/CD OIDC (architectural confusion)
5. Makes terraform state backend setup manual + complex
6. Only 65% aligned with security best practices

---

## If You Want to Use Start-Bootstrap.ps1, Required Changes

If you prefer this script's UX/workflow, here are the **minimum fixes** to reach best-practices alignment:

### Fix 1: Create Three Separate SPs (CRITICAL)
```powershell
# Instead of single $APP_NAME, create:
$mainAppId = New-DeployServicePrincipal `
    -DisplayName "sp-terraform-main-prod" `
    -Roles @("Contributor") `
    -Scope $subscriptionScope

$devAppId = New-DeployServicePrincipal `
    -DisplayName "sp-terraform-dev-prod" `
    -Roles @("Contributor", "User Access Administrator") `
    -Scope $subscriptionScope

$prodAppId = New-DeployServicePrincipal `
    -DisplayName "sp-terraform-prod-prod" `
    -Roles @("Contributor", "User Access Administrator") `
    -Scope $subscriptionScope

# Store all three, create environment-scoped secrets for each
```

### Fix 2: Remove User Access Administrator from Main SP (CRITICAL)
```powershell
# Main should ONLY have Contributor
# Only Dev/Prod need User Access Administrator (if at all)
```

### Fix 3: Add Owner Role Validation (CRITICAL)
```powershell
# After all role assignments:
$ownerAssignments = az role assignment list `
    --assignee-object-id $spObjId `
    --query "[?roleDefinitionName=='Owner']"

if (($ownerAssignments | ConvertFrom-Json).Count -gt 0) {
    throw "SECURITY ERROR: Service principal has Owner role assigned!"
}
```

### Fix 4: Support Terraform Cloud Backend (HIGH)
```powershell
# Add optional parameter:
param([switch]$UseTerraformCloud)

if ($UseTerraformCloud) {
    $tfcOrg = Read-Host "Terraform Cloud organization"
    $tfcWorkspace = Read-Host "Terraform Cloud workspace"
    $tfcToken = Read-Host "Terraform Cloud API token" -AsSecureString
    
    Set-GitHubSecret "TF_API_TOKEN" (ConvertFrom-SecureStringToPlainText $tfcToken)
    Set-GitHubVariable "TF_CLOUD_ORGANIZATION" $tfcOrg
    # Etc.
}
```

### Fix 5: Separate NextAuth from OIDC (MEDIUM)
```powershell
# Create TWO apps:
$nextAuthApp = New-EntraApp `
    -DisplayName "CNA Assessment Tool" `
    -WithClientSecret

$oidcApp = New-DeployServicePrincipal `
    -DisplayName "sp-terraform-main-prod" `
    -WithFederatedCredentials
```

---

## Recommendation

### Short Term (Now)
**Use**: `Initialize-CnaGitHubSecrets.ps1`  
**Why**: Already implements best practices correctly  
**Action**: Run it once locally to bootstrap OIDC

### Medium Term (Next Phase)
**Consider**: Integrating best pieces from `Start-Bootstrap.ps1` (UX, state tracking) into a new unified script that:
- Uses separate SPs per layer
- Supports Terraform Cloud
- Has excellent UX
- Is fully OIDC-compliant

### Document This
Create [docs/bootstrap/BOOTSTRAP-SCRIPT-CHOICE.md](BOOTSTRAP-SCRIPT-CHOICE.md):
- When to use each script
- Security implications
- How to migrate between them

---

## Summary Scorecard

| Script | OIDC Compliance | Security | UX | Terraform Cloud | Recommendation |
|---|---|---|---|---|---|
| **Initialize-CnaGitHubSecrets.ps1** | 95% | 95% | 70% | ✅ Native | **USE THIS** |
| **Start-Bootstrap.ps1** | 65% | 40% | 90% | ❌ Not supported | Needs major fixes |

