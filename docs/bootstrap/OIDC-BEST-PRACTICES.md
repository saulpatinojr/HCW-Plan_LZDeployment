# OIDC Handshake Best Practices
## GitHub → Azure → Terraform Cloud Trust Chain

**Version:** 1.0  
**Purpose:** Define security and operational best practices for the initial OIDC federation setup  
**Audience:** Platform engineers, DevOps leads, security teams  

---

## 1. Overview: Trust Flows

You have **two distinct trust flows** that must be configured separately:

### Flow 1: Human Authentication (Optional - GitHub Enterprise only)
```
Engineer → Entra ID SAML SSO → GitHub Enterprise
```
Purpose: Centralize engineer identity; no API keys needed for GitHub access

### Flow 2: CI/CD Authentication (Mandatory - GitHub Actions → Azure)
```
GitHub Actions → OIDC Token → Azure AD (Federated Credential) → Azure Resource Manager
```
Purpose: Authenticate deployments without storing secrets; supported by Terraform Cloud

### Flow 3: State Management (Mandatory - Terraform → Terraform Cloud)
```
GitHub Actions → TFC API Token → Terraform Cloud → Remote State
```
Purpose: Centralize Terraform state; optional but recommended

---

## 2. OIDC Security Principles

### 2.1 Never Use Client Secrets for CI/CD
❌ **Anti-pattern**: Store `AZURE_CLIENT_SECRET` in GitHub Secrets  
✅ **Best practice**: Use OIDC federated credentials (short-lived, self-renewing)

**Why**:
- Secrets are static; OIDC tokens are ephemeral (1-hour default)
- Secrets must be rotated manually; OIDC tokens auto-renew
- Secrets are broader attack surface; OIDC is scoped to GitHub Actions runners
- Secrets can leak; OIDC is never stored at rest

### 2.2 Principle of Least Privilege (PoLP)
Create separate service principals (SPs) per deployment layer:

```
Global Layer → sp-terraform-global-prod (global resources)
├─ Connectivity Layer → sp-terraform-connectivity-prod (VNets, Firewall)
├─ Management Layer → sp-terraform-management-prod (Policy, RBAC)
├─ Workloads Layer → sp-terraform-workloads-prod (App deployments)
└─ Sandbox Layer → sp-terraform-sandbox-dev (temporary dev resources)
```

Each SP:
- Has **Contributor role** on **only one subscription**
- Has **no Owner role** (highest sensitivity)
- Has **no Global Reader role** (minimal data exposure)
- Is **scoped to resource group** if possible (network isolation)

### 2.3 Token Scope & Subject Constraints
When creating OIDC federated credentials, always scope to specific branches/workflows:

```json
{
  "name": "terraform-apply-main",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:ORG/REPO:ref:refs/heads/main:workflow:terraform-apply.yml",
  "description": "Allow terraform-apply.yml on main branch only"
}
```

**Never use**:
```json
"subject": "repo:ORG/REPO:*"  // ❌ Too broad - any branch, any workflow
```

---

## 3. Azure Setup Sequence

### Step 1: Create Service Principal with OIDC Scope
```bash
# Create app registration (service principal identity)
az ad app create \
  --display-name "sp-terraform-global-prod" \
  --description "Terraform OIDC federation for global layer"

# Capture app ID
APP_ID=$(az ad app list --display-name "sp-terraform-global-prod" --query "[0].appId" -o tsv)
echo "App ID: $APP_ID"

# Create service principal from app registration
az ad sp create --id $APP_ID

# Get object ID for role assignment
SP_OBJECT_ID=$(az ad sp show --id $APP_ID --query "id" -o tsv)
echo "Service Principal Object ID: $SP_OBJECT_ID"
```

### Step 2: Create Federated Credential (NOT Client Secret)
```bash
# Create federated credential for main branch terraform-apply workflow
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "terraform-apply-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:YOUR-ORG/YOUR-REPO:ref:refs/heads/main:workflow:terraform-apply.yml",
    "description": "Allow terraform-apply.yml on main branch only",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

### Step 3: Assign Minimal RBAC
```bash
# Get subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Assign Contributor role at subscription level (NOT Owner)
az role assignment create \
  --role "Contributor" \
  --assignee-object-id $SP_OBJECT_ID \
  --assignee-principal-type "ServicePrincipal" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"

# Verify the role was assigned
az role assignment list --assignee-object-id $SP_OBJECT_ID --scope "/subscriptions/$SUBSCRIPTION_ID"
```

### Step 4: Validate NO Owner Role
```bash
# This query should return EMPTY for security
az role assignment list \
  --assignee-object-id $SP_OBJECT_ID \
  --query "[?roleDefinitionName=='Owner']"

# If any results appear, remove them immediately
az role assignment delete \
  --assignee-object-id $SP_OBJECT_ID \
  --role "Owner" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"
```

---

## 4. GitHub Configuration

### Step 1: Add Repository Secrets (Not Credentials)
Store **Azure identifiers only** (not secrets):

```bash
# In GitHub Settings → Secrets and Variables → Actions → New Repository Secret

AZURE_TENANT_ID      = "00000000-0000-0000-0000-000000000000"  # Your Entra tenant
AZURE_SUBSCRIPTION_ID = "11111111-1111-1111-1111-111111111111" # Your Azure subscription
AZURE_CLIENT_ID      = "22222222-2222-2222-2222-222222222222" # The app registration ID
```

**Do NOT add**:
- ❌ `AZURE_CLIENT_SECRET` — Never, ever, ever
- ❌ `AZURE_CREDENTIAL` — Violates OIDC model
- ❌ API keys or personal tokens with long expiry

### Step 2: Create GitHub Actions Workflow
```yaml
name: Deploy Infrastructure

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  terraform:
    runs-on: ubuntu-latest
    
    permissions:
      id-token: write     # ← CRITICAL: Required for OIDC token issuance
      contents: read
    
    steps:
      - uses: actions/checkout@v4

      - name: Azure Login via OIDC
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Verify Azure Context
        run: |
          az account show
          az role assignment list --assignee ${{ secrets.AZURE_CLIENT_ID }}
```

### Step 3: Verify OIDC Token Generation
```bash
# After running the workflow, check the workflow logs for:
# - "OIDC token received" (Azure CLI login)
# - "Authenticated as service principal" (no secrets shown)

# Do NOT see:
# - Client secrets in logs
# - Plaintext credentials
# - API keys
```

---

## 5. Terraform Cloud Integration

### Step 1: Create Terraform Cloud Account & API Token
```bash
# 1. Sign up at https://app.terraform.io
# 2. Create organization (e.g., "your-company")
# 3. Create workspace (e.g., "azure-landing-zone")
# 4. Generate API token at https://app.terraform.io/app/settings/tokens
```

### Step 2: Add TFC API Token to GitHub Secrets
```bash
# In GitHub Settings → Secrets and Variables → Actions → New Repository Secret

TF_API_TOKEN = "Bearer eyJ0eXAiOiJKV1QiL..."  # Full TFC API token
TF_CLOUD_ORGANIZATION = "your-company"         # TFC organization name
```

### Step 3: Configure Terraform Backend
```hcl
# terraform/main.tf

terraform {
  cloud {
    organization = "your-company"
    
    workspaces {
      name = "azure-landing-zone"
    }
  }

  required_version = ">= 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  
  # Authentication handled by GitHub Actions OIDC
  skip_provider_registration = false
}
```

### Step 4: Add TFC Configuration to Workflow
```yaml
- name: Setup Terraform
  uses: hashicorp/setup-terraform@v3
  with:
    terraform_version: 1.6.0
    cli_config_credentials_token: ${{ secrets.TF_API_TOKEN }}

- name: Terraform Init
  run: terraform init

- name: Terraform Plan
  run: terraform plan -out=tfplan

- name: Terraform Apply
  if: github.ref == 'refs/heads/main'
  run: terraform apply -auto-approve tfplan
```

---

## 6. End-to-End Validation Sequence

### Validation Checkpoint 1: OIDC Token Flow
```bash
# In GitHub Actions workflow logs, you should see:
# ✅ "OIDC token received"
# ✅ "Authenticated as service principal <APP_ID>"
# ✅ "Role assignments: Contributor on subscription <SUB_ID>"

# You should NOT see:
# ❌ Any client secret or password
# ❌ API key or long-lived token
```

### Validation Checkpoint 2: Service Principal Scope
```bash
# Run this locally to verify SP has no Owner role:
az role assignment list \
  --assignee $AZURE_CLIENT_ID \
  --all \
  --output table

# Expected output:
# RoleDefinitionName  Scope
# Contributor         /subscriptions/00000000-0000...
```

### Validation Checkpoint 3: Terraform Cloud State
```bash
# After first terraform apply, verify state in TFC:
# 1. Log in to https://app.terraform.io
# 2. Navigate to workspace
# 3. Confirm "State versions" tab shows your state
# 4. Verify state is encrypted at rest (blue lock icon)
```

### Validation Checkpoint 4: Multi-Deployment Scenario
```bash
# If running multiple deployments with different SPs:
# 1. Verify each SP is assigned to only ONE subscription
# 2. Verify no SP has Owner role
# 3. Verify each workflow uses correct AZURE_CLIENT_ID secret
# 4. Run workflows for different layers (global, connectivity, etc.)
# 5. Confirm each deployment uses correct SP
```

---

## 7. Common Mistakes & How to Avoid Them

### Mistake 1: Using Client Secrets Instead of OIDC
```yaml
# ❌ BAD - Never do this
- uses: azure/login@v2
  with:
    creds: '{"clientId":"...","clientSecret":"..."}' # ← SECURITY RISK

# ✅ GOOD - Always do this
- uses: azure/login@v2
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

### Mistake 2: Overly Broad Federated Credential Subject
```bash
# ❌ BAD - Works from any branch, any workflow
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "subject": "repo:YOUR-ORG/YOUR-REPO:*"
  }'

# ✅ GOOD - Scoped to main branch terraform-apply only
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "subject": "repo:YOUR-ORG/YOUR-REPO:ref:refs/heads/main:workflow:terraform-apply.yml"
  }'
```

### Mistake 3: Single Monolithic Service Principal
```bash
# ❌ BAD - One SP for everything (no blast containment)
az role assignment create \
  --role "Contributor" \
  --assignee $GLOBAL_SP_ID \
  --scope "/subscriptions/$GLOBAL_SUB,/subscriptions/$CONNECTIVITY_SUB,/subscriptions/$WORKLOADS_SUB"

# ✅ GOOD - Separate SP per layer
az role assignment create --role "Contributor" --assignee $GLOBAL_SP_ID --scope "/subscriptions/$GLOBAL_SUB"
az role assignment create --role "Contributor" --assignee $CONNECTIVITY_SP_ID --scope "/subscriptions/$CONNECTIVITY_SUB"
az role assignment create --role "Contributor" --assignee $WORKLOADS_SP_ID --scope "/subscriptions/$WORKLOADS_SUB"
```

### Mistake 4: Forgetting `id-token: write` Permission
```yaml
# ❌ BAD - No id-token permission = OIDC token won't be issued
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: azure/login@v2  # This will fail silently

# ✅ GOOD - id-token permission required for OIDC
jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write  # ← CRITICAL
      contents: read
    steps:
      - uses: azure/login@v2  # Now it works
```

### Mistake 5: Storing Terraform Cloud Token in Secrets Insecurely
```bash
# ❌ BAD - Plain token without Bearer prefix
TF_API_TOKEN = "eyJ0eXAiOiJKV1QiL..."

# ✅ GOOD - Proper Bearer token format in environment
export TERRAFORM_CLOUD_TOKEN="..."
# Or in GitHub Actions:
TF_API_TOKEN: ${{ secrets.TF_API_TOKEN }}
```

---

## 8. Access Control & Audit

### Service Principal Naming Convention
```
sp-terraform-<layer>-<environment>-<org>

Examples:
- sp-terraform-global-prod-acme
- sp-terraform-connectivity-prod-acme
- sp-terraform-management-prod-acme
- sp-terraform-workloads-prod-acme
- sp-terraform-sandbox-dev-acme
```

### Role Assignment Audit
```bash
# Monthly audit script
#!/bin/bash
echo "=== Service Principal Security Audit ==="

# List all SPs and their roles
for SP_NAME in sp-terraform-*; do
  SP_ID=$(az ad sp list --display-name "$SP_NAME" --query "[0].appId" -o tsv)
  
  echo "Service Principal: $SP_NAME"
  az role assignment list \
    --assignee-object-id "$(az ad sp show --id $SP_ID --query 'id' -o tsv)" \
    --all \
    --output table
  
  # Fail if Owner role found
  OWNER_COUNT=$(az role assignment list \
    --assignee-object-id "$(az ad sp show --id $SP_ID --query 'id' -o tsv)" \
    --query "[?roleDefinitionName=='Owner'] | length(@)")
  
  if [ "$OWNER_COUNT" -gt 0 ]; then
    echo "⚠️  WARNING: $SP_NAME has Owner role (should only be Contributor)"
  fi
done
```

### Terraform Cloud Audit Logging
```bash
# Enable TFC team token audit logs
# 1. Log in to https://app.terraform.io
# 2. Organization → Settings → Authentication
# 3. Enable "Team token audit logging"
# 4. Review logs at https://app.terraform.io/app/organizations/YOUR-ORG/settings/authentication

# Expected log entries:
# - Token created: [date] by [user]
# - Token used by GitHub Actions: [workflow name]
# - Token rotated: [date] (if using automation)
```

---

## 9. Troubleshooting OIDC Issues

### Issue: "OIDC token not received"
**Cause**: Missing `id-token: write` permission in workflow  
**Fix**: Add to job permissions:
```yaml
permissions:
  id-token: write
  contents: read
```

### Issue: "Federated credential not found"
**Cause**: Subject claim doesn't match workflow context  
**Fix**: Debug the subject claim:
```bash
# In GitHub Actions, print the token claims
- name: Debug OIDC Token
  run: |
    curl -s -H "Authorization: Bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" \
      "$ACTIONS_ID_TOKEN_REQUEST_URL" | jq .token -r | jq -R 'split(".") | .[1] | @base64d | fromjson'
```

### Issue: "Service principal has no role assignments"
**Cause**: Role assignment failed silently  
**Fix**: Verify SP object ID is correct:
```bash
# Get correct object ID (not app ID)
az ad sp show --id $APP_ID --query "id" -o tsv

# Assign role with correct object ID
az role assignment create \
  --role "Contributor" \
  --assignee-object-id $SP_OBJECT_ID  # ← Use this, not app ID
  --scope "/subscriptions/$SUBSCRIPTION_ID"
```

### Issue: "Terraform Cloud token expired"
**Cause**: TFC token has lifetime limit or was manually revoked  
**Fix**: Regenerate and update secrets:
```bash
# At https://app.terraform.io/app/settings/tokens
# 1. Create new token
# 2. Copy full token including "Bearer " prefix
# 3. Update GitHub secret: Settings → Secrets → TF_API_TOKEN
```

---

## 10. Checklist: Ready for Production

Before declaring bootstrap complete:

### Azure OIDC Setup
- [ ] Service principal created (no client secret)
- [ ] Federated credential created (subject scoped to workflow)
- [ ] Role assignment verified (Contributor only, scoped to 1 subscription)
- [ ] No Owner role assignments on service principal
- [ ] RBAC audit log shows least-privilege assignment

### GitHub Configuration
- [ ] Repository secrets contain only identifiers (TENANT_ID, SUBSCRIPTION_ID, CLIENT_ID)
- [ ] No client secrets stored in GitHub
- [ ] Workflow has `permissions.id-token: write`
- [ ] Branch protection enabled on main (1+ approval required)
- [ ] Deployment workflow tested and passing

### Terraform Cloud Setup
- [ ] Organization created
- [ ] Workspace created
- [ ] API token generated (never logged or stored in code)
- [ ] Token rotation schedule established (annually)
- [ ] Audit logging enabled

### Validation
- [ ] End-to-end test: PR → validate → approve → apply
- [ ] OIDC token verified in workflow logs (no secrets visible)
- [ ] Azure resources created via Terraform
- [ ] Terraform state stored in TFC (verified in UI)
- [ ] No hardcoded credentials in any files

### Documentation
- [ ] Service principal naming documented
- [ ] OIDC flow diagram added to runbooks
- [ ] Emergency SP rotation procedure documented
- [ ] Token expiry alerts configured

---

## References

- [Azure OIDC Federated Credentials](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-with-oidc)
- [GitHub Actions OpenID Connect](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [Terraform Cloud API](https://www.terraform.io/cloud-docs/api-docs)
- [Azure CLI Role Assignment](https://learn.microsoft.com/en-us/cli/azure/role/assignment)

