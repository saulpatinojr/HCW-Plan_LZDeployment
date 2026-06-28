# Azure Landing Zone - Customer Setup Guide

**Time estimate:** 30 minutes  
**Difficulty:** Intermediate (requires Azure + GitHub account)

This guide walks you through deploying an Azure Landing Zone using this self-service orchestration system.

---

## Prerequisites

You need:
- ✅ Azure subscription (or multiple for multi-environment setup)
- ✅ GitHub organization account
- ✅ Terraform Cloud account (free tier is fine)
- ✅ Azure CLI or PowerShell installed

---

## Step 1: Clone This Repository

This is your **template repository**. When you clone it, you get all the Terraform modules, deployment form, and automation workflows.

```bash
# Option A: Clone to your computer
git clone https://github.com/YOUR-ORG/alz-landing-zone.git
cd alz-landing-zone

# Option B: Use as template in GitHub
# Visit: https://github.com/YOUR-ORG/alz-landing-zone/
# Click "Use this template" → Create new repository
```

---

## Step 2: Create GitHub App (OIDC Federation)

Your landing zone deployment uses GitHub OIDC tokens to authenticate to Azure (no secrets stored in the repo).

### 2.1: Create the GitHub App

1. In GitHub, go to **Settings → Developer settings → GitHub Apps**
2. Click **"New GitHub App"**
3. Fill in:
   - **App name:** `ALZ-Deployment-{YourOrgPrefix}` (e.g., `ALZ-Deployment-contoso`)
   - **Homepage URL:** `https://github.com/YOUR-ORG/alz-landing-zone`
   - **Webhook URL:** `https://github.com/` (can leave as-is)
   - **Webhook Active:** Unchecked
4. **Permissions:**
   - Repository: Read/Write (code, workflows, releases)
   - Organization: Read (for public repos)
5. Click **"Create GitHub App"**

### 2.2: Generate Private Key

1. Go to your newly created GitHub App (Settings → Apps and integrations)
2. Scroll down to **"Private keys"**
3. Click **"Generate a private key"**
4. Save the `.pem` file somewhere secure (you'll need it next)

### 2.3: Get Your App ID

1. On the GitHub App page, note the **App ID** (at the top)
2. You'll use this in the next step

---

## Step 3: Set Up Azure OIDC Federation

Your GitHub Actions workflows will use OIDC tokens to authenticate to Azure.

### 3.1: Create Azure Service Principal

```bash
# Login to Azure
az login

# Get your tenant ID
TENANT_ID=$(az account show --query tenantId -o tsv)

# Create service principal
SP=$(az ad app create --display-name "alz-deployment" --output json)
APP_ID=$(echo $SP | jq -r '.appId')
OBJECT_ID=$(az ad sp create --id $APP_ID --output json | jq -r '.id')

# Save these for later
echo "APP_ID: $APP_ID"
echo "OBJECT_ID: $OBJECT_ID"
echo "TENANT_ID: $TENANT_ID"
```

### 3.2: Create Federated Credential

```bash
# Create federated credential for GitHub
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-alz-deployment",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:YOUR-ORG/alz-landing-zone:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

### 3.3: Grant Azure RBAC Role

```bash
# Get your subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Grant Contributor role
az role assignment create \
  --assignee-object-id $OBJECT_ID \
  --assignee-principal-type ServicePrincipal \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"
```

---

## Step 4: Store Secrets in GitHub

1. Go to your repo **Settings → Secrets and variables → Actions**
2. Create these secrets:
   - **GITHUB_APP_ID:** (from step 2.3)
   - **GITHUB_APP_PRIVATE_KEY:** (contents of the .pem file from step 2.2)
   - **AZURE_CLIENT_ID:** `$APP_ID` (from step 3.1)
   - **AZURE_TENANT_ID:** `$TENANT_ID` (from step 3.1)
   - **AZURE_SUBSCRIPTION_ID:** `$SUBSCRIPTION_ID` (from step 3.3)

---

## Step 5: Set Up Terraform Cloud

Your Terraform state will be stored remotely in Terraform Cloud.

### 5.1: Create Terraform Cloud Account

1. Go to https://app.terraform.io/
2. Sign up or login
3. Create an organization (or note your existing org name)

### 5.2: Create API Token

1. Go to **Account settings → Tokens**
2. Click **"Create an API token"**
3. Copy the token
4. Add to GitHub secrets:
   - **TF_CLOUD_TOKEN:** (paste the token)

### 5.3: Update backend.hcl

Edit `terraform/compose-package/Compose-TerraformPackage.ps1` and update the default organization:

```hcl
hostname     = "app.terraform.io"
organization = "YOUR-ORG-NAME"  # ← Update this
```

Or let the script ask you during first run.

---

## Step 6: Deploy Your Landing Zone

### 6.1: Open the Deployment Form

The form is in `frontend/index.html`. You can:

**Option A: Run locally**
```bash
# Python 3
python -m http.server 8000
# Open http://localhost:8000/frontend/
```

**Option B: Deploy to Azure Static Web Apps** (recommended)
```bash
# Follow Azure docs to deploy the frontend/ folder
# https://docs.microsoft.com/en-us/azure/static-web-apps/
```

### 6.2: Fill Out the Form

1. **Organization Prefix:** (3-8 lowercase letters, e.g., "contoso")
2. **Modules to Deploy:** Select what you want (always includes hub-network, spoke-network, policies)
3. **Compliance Variant:** baseline, pci-dss, hipaa, or fedramp
4. **Primary Region:** eastus, westus, etc.
5. **Secondary Region:** (for disaster recovery skeleton)
6. Click **"Deploy to Azure"**

### 6.3: Configure terraform.tfvars

After the workflow creates a release:

1. Go to the repo → **Releases**
2. Find your latest release
3. Download the generated `terraform.tfvars`
4. Update subscription IDs:
   ```hcl
   management_subscription_id      = "00000000-0000-0000-0000-000000000000"
   connectivity_subscription_id    = "00000000-0000-0000-0000-000000000000"
   # ... etc
   ```

### 6.4: Trigger Deployment

```bash
# Navigate to the generated directory
cd terraform/live/{org_prefix}/

# Initialize Terraform
terraform init -backend-config=backend.hcl

# Review plan
terraform plan

# Deploy
terraform apply
```

Deployment takes ~15-20 minutes.

---

## Troubleshooting

### "OIDC token exchange failed"
- Verify federated credential subject matches your repo path exactly
- Check AZURE_CLIENT_ID, AZURE_TENANT_ID in GitHub secrets

### "Terraform Cloud workspace not found"
- Verify TF_CLOUD_TOKEN is set in GitHub secrets
- Check organization name in backend.hcl

### "Module not found: ../../modules/hub-network"
- Ensure modules/ directory exists in the repo root
- Check relative paths in generated main.tf

### "Deployment timed out"
- Landing zone creation typically takes 15-20 minutes
- Check Terraform Cloud run logs for details

---

## What's Being Deployed

Your landing zone includes:

**Always:**
- Management groups (hierarchical governance)
- Policy baseline (tagging, encryption, compliance)
- Hub VNet (firewall, VPN/ER gateway, bastion)
- Spoke VNets (workload networks, peered to hub)
- Disaster recovery skeleton (secondary region)

**Optional (if selected):**
- Backup & recovery resources
- Defender for Cloud security monitoring

---

## Next Steps

1. **Monitor deployment** in Terraform Cloud UI
2. **Review Azure resources** in Azure Portal
3. **Configure workload spokes** for your applications
4. **Set up branch protection** in your repo to enforce approval for infrastructure changes

---

## Support

- See `docs/DEPLOYMENT-GUIDE.md` for operational details
- Check `.github/workflows/` for deployment automation details
- Review generated `terraform/live/{org_prefix}/deployment-manifest.yaml` for deployment metadata

---

**Questions?** Open an issue or contact the platform team.
