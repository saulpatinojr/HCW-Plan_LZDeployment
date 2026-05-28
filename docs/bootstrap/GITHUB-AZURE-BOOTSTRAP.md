# Azure Landing Zone — GitHub + Azure Bootstrap Guide

**Version:** 1.0  
**Phase:** Phase 0 (Bootstrap) - Must complete before Phase 1  
**Status:** Ready for implementation  
**Scope:** Manual-first implementation for engineer-to-GitHub authentication (Entra SSO) and GitHub Actions-to-Azure deployment authentication (OIDC federation)

---

## Overview

This runbook establishes the **foundational trust flows** required before any infrastructure deployment can begin. It configures:

1. **Human Trust Flow**: Engineers sign in to GitHub using Microsoft Entra ID corporate identity (SAML SSO)
2. **Pipeline Trust Flow**: GitHub Actions workflows authenticate to Azure using short-lived OIDC tokens (no secrets)

**⚠️ Critical**: Every step must be followed in order. Do not skip or reorder steps. All validation checkpoints are mandatory.

---

## Critical Notes Before Starting

- ❌ Do NOT skip steps or reorder steps. The trust flows are sequential and dependent.
- ❌ Do NOT use client secrets for pipeline authentication. This runbook uses OIDC only.
- ❌ Do NOT reuse human credentials for automation pipelines.
- ✅ Every validation checkpoint is mandatory. If a checkpoint fails, stop and resolve before continuing.
- ✅ Commands shown use Azure CLI and Git. All CLI commands are exactly as they should be entered.
- ✅ Replace all values shown in `<angle-brackets>` with your actual values before executing.
- ✅ Values shown in `"quotes"` are literal strings and must match exactly unless stated otherwise.

---

## Prerequisites

Confirm all of the following are true before beginning. If any are missing, stop and resolve first.

### Azure and Entra Prerequisites

- [ ] You have an active Microsoft Entra tenant
- [ ] You have an active Azure subscription
- [ ] Your account has one of the following Entra roles: **Application Administrator**, **Cloud Application Administrator**, or **Application Owner**
- [ ] Your account has **Owner** role on the Azure subscription you will use for bootstrap

### GitHub Prerequisites

- [ ] You have a GitHub account
- [ ] You have **GitHub Enterprise Cloud** licensing (required for Entra SSO integration)
- [ ] You are an **enterprise account owner** or **organization owner** in GitHub

> **⚠️ Important Note on GitHub Licensing**: Microsoft's enterprise account SSO tutorial explicitly requires a GitHub Enterprise Account and a GitHub user account that is an Enterprise Account owner. Entra-based SSO for human engineers is only available through GitHub Enterprise capabilities. If you do not yet have GitHub Enterprise Cloud, you can still complete Sections 3-5 of this runbook (repo creation, branch protection, OIDC), but Section 2 (Entra SSO for humans) cannot be completed until the enterprise license is in place.

### Local Tooling Prerequisites

- [ ] Azure CLI installed. Minimum version: 2.30
- [ ] Git installed
- [ ] Terraform installed. Minimum version: 1.6
- [ ] A terminal or PowerShell session available

**Verify tooling:**

```bash
az version
git --version
terraform version
```

All three commands must return version information without errors. If any command fails, install or update the tool before continuing.

---

## Section 1 — Sign In and Capture Your Azure Identifiers

These values will be used throughout the runbook. Capture them now and keep them available.

### Step 1.1 — Sign In to Azure

```bash
az login
```

This will open a browser window. Sign in with your Entra administrator account. After sign-in, the CLI will list your available subscriptions.

### Step 1.2 — Select the Correct Subscription

```bash
az account set --subscription "<your-subscription-name-or-id>"
```

Replace `<your-subscription-name-or-id>` with the exact name or ID of the Azure subscription you are using for the landing zone platform bootstrap.

### Step 1.3 — Capture and Record Your Identifiers

```bash
TENANT_ID=$(az account show --query tenantId -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "Tenant ID:       $TENANT_ID"
echo "Subscription ID: $SUBSCRIPTION_ID"
```

**Record both values now.** You will need them in Section 5. Do not continue without recording these.

**✅ Validation Checkpoint 1:**
- `echo` output shows two GUIDs
- Both GUIDs are non-empty
- The subscription name or ID matches the correct target subscription

---

## Section 2 — Configure Microsoft Entra SSO for Human Access to GitHub

This section configures the **human trust flow**. Engineers will sign in to GitHub using their Microsoft Entra ID corporate identity through SAML-based SSO.

> **Reference:** Microsoft Learn — *Configure GitHub Enterprise Cloud - Enterprise Account for Single sign-on with Microsoft Entra ID* (updated March 2025)

### Step 2.1 — Add the GitHub Enterprise Cloud Enterprise Application in Entra

1. Open the **Microsoft Entra admin center** at `https://entra.microsoft.com`
2. In the left navigation, select **Identity**
3. Select **Applications** > **Enterprise applications**
4. Select **New application**
5. In the search box, type exactly: `GitHub Enterprise Cloud - Enterprise Account`
6. Select **GitHub Enterprise Cloud - Enterprise Account** from the results
7. Select **Create** and wait for the app to be added to your tenant

> **⚠️ Critical Note**: The application name must be exactly **GitHub Enterprise Cloud - Enterprise Account**. This is a specific application in the Microsoft Entra gallery that supports SAML integration at the enterprise account level. Do not select the organization-level app unless you have confirmed your GitHub licensing model requires it.

### Step 2.2 — Configure Microsoft Entra SAML SSO

1. In the enterprise application you just added, select **Single sign-on** from the left menu
2. On the **Select a single sign-on method** page, select **SAML**
3. On the **Set up single sign-on with SAML** page, click the **pencil/edit icon** next to **Basic SAML Configuration**
4. In the **Identifier (Entity ID)** field, enter:
   ```
   https://github.com/enterprises/<ENTERPRISE-SLUG>
   ```
5. In the **Reply URL (Assertion Consumer Service URL)** field, enter:
   ```
   https://github.com/enterprises/<ENTERPRISE-SLUG>/saml/consume
   ```
6. In the **Sign on URL** field, enter:
   ```
   https://github.com/enterprises/<ENTERPRISE-SLUG>/sso
   ```

Replace `<ENTERPRISE-SLUG>` in all three fields with the exact name of your GitHub Enterprise Account. The enterprise slug is the short name that appears in your GitHub Enterprise URL.

7. Select **Save**

### Step 2.3 — Download the SAML Signing Certificate

1. On the **Set up single sign-on with SAML** page, find the **SAML Signing Certificate** section
2. Select **Download** next to **Certificate (Base64)**
3. Save the `.cer` file to your local machine. You will need it in Step 2.5

### Step 2.4 — Copy the Entra SAML URLs

From the **Set up GitHub Enterprise Cloud - Enterprise Account** section, copy and record:
- **Login URL** (also called Sign-on URL or SSO URL)
- **Azure AD Identifier** (also called the Issuer URI or Entity ID from Entra's side)

You will paste both of these into GitHub in Step 2.5.

### Step 2.5 — Configure GitHub Enterprise Account SAML Settings

1. Open `https://github.com/enterprises/<ENTERPRISE-SLUG>` and sign in as an Enterprise Account Owner
2. Select **Settings** > **Authentication security**
3. Under **SAML single sign-on**, select **Require SAML authentication** (or enable it if not already on)
4. In the **Sign on URL** field, paste the **Login URL** you copied from Entra in Step 2.4
5. In the **Issuer** field, paste the **Azure AD Identifier** you copied from Entra in Step 2.4
6. In the **Public certificate** field, open the `.cer` file you downloaded in Step 2.3 with a text editor, copy all content including the `-----BEGIN CERTIFICATE-----` and `-----END CERTIFICATE-----` lines, and paste the full content here
7. Select **Test SAML configuration** before saving

**✅ Validation Checkpoint 2a:**
- The SAML test completes successfully
- GitHub confirms it can authenticate to Microsoft Entra ID
- If the test fails, stop here. Recheck the entity ID, reply URL, sign-on URL, and certificate pasted values. Common issues are trailing spaces, wrong ENTERPRISE-SLUG, or certificate format errors

8. If the test passes, select **Save**

### Step 2.6 — Assign Engineers to the GitHub Enterprise App in Entra

1. Return to the **Microsoft Entra admin center**
2. Navigate to **Enterprise applications** > **GitHub Enterprise Cloud - Enterprise Account**
3. Select **Users and groups**
4. Select **Add user/group**
5. Select the engineers who need GitHub access, or select the Entra groups you created for GitHub access
6. Select **Assign**

> **💡 Best Practice**: Use Entra groups rather than individual users for assignment so that access is managed at the group level.

### Step 2.7 — Validate Pilot Engineer Sign-In

1. Choose one pilot engineer account
2. Have that engineer sign in to GitHub at `https://github.com/enterprises/<ENTERPRISE-SLUG>/sso`
3. Confirm the sign-in redirects to Microsoft Entra login
4. Confirm successful authentication and GitHub access
5. Confirm MFA is enforced as expected through Entra Conditional Access

**✅ Validation Checkpoint 2b:**
- Pilot engineer can sign in via Entra SSO
- MFA challenge appears during sign-in
- Engineer lands in the GitHub organization with correct access
- Sign-in does not work without the Entra credential (confirm by attempting a non-Entra login path if applicable)

---

## Section 3 — Create the GitHub Repository

### Step 3.1 — Create the Repository

1. Sign in to GitHub as the org/enterprise admin
2. Select **New repository**
3. Set:
   - **Owner:** your GitHub organization
   - **Repository name:** `HCW-Demo-LZDeployment` (or your naming convention)
   - **Visibility:** Private
   - **Initialize this repository with a README:** checked
4. Select **Create repository**

### Step 3.2 — Clone the Repository Locally

```bash
git clone https://github.com/<your-org>/HCW-Demo-LZDeployment.git
cd HCW-Demo-LZDeployment
```

Replace `<your-org>` with your actual GitHub organization name.

### Step 3.3 — Create the Initial Folder Structure

```bash
mkdir -p .github/workflows
mkdir -p terraform/backend-bootstrap
mkdir -p terraform/modules
mkdir -p terraform/live
mkdir -p docs/bootstrap
mkdir -p scripts
```

### Step 3.4 — Add a Terraform .gitignore

Create a file named `.gitignore` in the root of the repository:

```
# Terraform
.terraform/
.terraform.lock.hcl
*.tfstate
*.tfstate.*
*.tfvars
crash.log
crash.*.log
*.tfplan
override.tf
override.tf.json
*_override.tf
*_override.tf.json
.terraformrc
terraform.rc

# Azure deployment options (user-specific)
.azure/deployment-options.yaml

# OS files
.DS_Store
Thumbs.db
```

> **⚠️ Critical Note**: Never commit `.terraform/`, `*.tfstate`, or `*.tfvars` files. State files contain sensitive resource identifiers and must never be stored in source control. The `.tfvars` files often contain sensitive variable values and must also be excluded.

### Step 3.5 — Add a CODEOWNERS File

Create `.github/CODEOWNERS`:

```
# All platform code requires approval from platform engineers
*       @<your-org>/<platform-team-name>
```

Replace `<your-org>` and `<platform-team-name>` with your GitHub org and team name.

### Step 3.6 — Commit and Push the Initial Structure

```bash
git add .
git commit -m "Initial repo structure: terraform, docs, scripts, workflows"
git push origin main
```

**✅ Validation Checkpoint 3:**
- Repository exists in GitHub
- Folder structure is visible in the repo
- `.gitignore` is present
- `CODEOWNERS` is present
- No `.terraform/` directories or state files were committed

---

## Section 4 — Configure Branch Protection on Main

Branch protection ensures that no code reaches `main` without review and validation. This is mandatory for all platform repositories.

### Step 4.1 — Navigate to Branch Protection Settings

1. Open the repository in GitHub
2. Select **Settings**
3. In the left menu, select **Branches**
4. Under **Branch protection rules**, select **Add rule**

### Step 4.2 — Configure the Protection Rule for Main

Set the **Branch name pattern** to exactly: `main`

Enable the following settings:

- [x] **Require a pull request before merging**
  - Set **Required number of approvals** to at least `1`
  - [x] **Dismiss stale pull request approvals when new commits are pushed**
- [x] **Require status checks to pass before merging**
  - [x] **Require branches to be up to date before merging**
  - After workflows exist, add required check names here
- [x] **Require conversation resolution before merging**
- [x] **Do not allow bypassing the above settings**
- [x] **Restrict who can push to matching branches**
- [x] **Do not allow force pushes**
- [x] **Do not allow deletions**

Select **Create** to save the rule.

**✅ Validation Checkpoint 4:**
- Attempt to push directly to `main` from your local machine:
  ```bash
  git push origin main
  ```
- This push should be **rejected** by GitHub
- If the push succeeds, the branch protection rule is not correctly configured. Stop and correct before continuing

---

## Section 5 — Configure GitHub Actions OIDC Authentication to Azure

This section configures the **pipeline trust flow**. GitHub Actions workflows will authenticate to Azure using short-lived OIDC tokens. No long-lived secrets will be stored.

### Step 5.1 — Create the Entra App Registration

```bash
APP_NAME="sp-github-oidc-lz-platform"
APP_ID=$(az ad app create --display-name "$APP_NAME" --query appId -o tsv)
echo "App ID (Client ID): $APP_ID"
```

Record the `App ID` value. This is your **AZURE_CLIENT_ID**.

### Step 5.2 — Create the Service Principal

```bash
az ad sp create --id "$APP_ID"
SP_OBJECT_ID=$(az ad sp show --id "$APP_ID" --query id -o tsv)
echo "Service Principal Object ID: $SP_OBJECT_ID"
```

Record the `Service Principal Object ID`.

### Step 5.3 — Create the Federated Credential

Create a file named `federated-credential.json` in your working directory (not inside the repo):

```json
{
  "name": "github-main-branch",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:<your-org>/<your-repo>:ref:refs/heads/main",
  "description": "GitHub Actions OIDC trust for main branch deployments",
  "audiences": [
    "api://AzureADTokenExchange"
  ]
}
```

Replace `<your-org>` with your GitHub organization name and `<your-repo>` with `HCW-Demo-LZDeployment` (or your repository name).

> **⚠️ Critical Note**: The `subject` field must exactly match the repo and branch path. Any mismatch, including incorrect case, will cause OIDC authentication to fail silently. The format must be: `repo:ORG/REPO:ref:refs/heads/BRANCH`

Apply the federated credential:

```bash
az ad app federated-credential create \
  --id "$APP_ID" \
  --parameters @federated-credential.json
```

**✅ Validation Checkpoint 5a:**
- The command completes without error
- Verify the credential was created:
  ```bash
  az ad app federated-credential list --id "$APP_ID" --output table
  ```
- The output shows one row with name `github-main-branch`

### Step 5.4 — Assign Azure RBAC for Bootstrap

For the initial bootstrap, assign the **Contributor** role at the subscription level. This will be narrowed down for each pipeline identity in later phases.

```bash
az role assignment create \
  --assignee "$APP_ID" \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"
```

> **📝 Note**: Contributor at subscription scope is the minimum needed for bootstrap. After state backend and initial resources are created, review whether scope can be reduced. Do not assign Owner unless absolutely required.

**✅ Validation Checkpoint 5b:**
- The role assignment command completes without error
- Verify:
  ```bash
  az role assignment list \
    --assignee "$APP_ID" \
    --scope "/subscriptions/$SUBSCRIPTION_ID" \
    --output table
  ```
- The output shows the Contributor role assigned to the app registration

### Step 5.5 — Add GitHub Secrets

1. Open the repository in GitHub
2. Select **Settings**
3. Select **Secrets and variables** > **Actions**
4. Select **New repository secret** for each of the following:

| Secret Name | Value |
|---|---|
| `AZURE_CLIENT_ID` | The App ID from Step 5.1 |
| `AZURE_TENANT_ID` | The Tenant ID from Step 1.3 |
| `AZURE_SUBSCRIPTION_ID` | The Subscription ID from Step 1.3 |

> **📝 Note**: These are **not** sensitive secrets in the traditional sense because they are identifiers, not credentials. However, they must still be stored as GitHub secrets so they do not appear in plain text in workflow files. Never paste client IDs or tenant IDs directly into YAML files.

**✅ Validation Checkpoint 5c:**
- All three secrets appear in GitHub under **Actions secrets**
- None of the three values are visible in the repo code

---

## Section 6 — Create and Validate the First GitHub Actions Workflow

### Step 6.1 — Create the Auth Test Workflow

Create the file `.github/workflows/azure-auth-test.yml` inside the repository:

```yaml
name: Azure Auth Test

on:
  workflow_dispatch:

permissions:
  id-token: write
  contents: read

jobs:
  auth-test:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Azure login via OIDC
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Verify Azure context
        uses: azure/cli@v2
        with:
          inlineScript: |
            az account show
```

> **Line-by-Line Notes:**
> - `on: workflow_dispatch` means this workflow runs only when you manually trigger it. This is correct for a first validation test. Do not set `push: main` until authentication is confirmed working.
> - `permissions: id-token: write` is mandatory. Without this, GitHub will not issue an OIDC token and the login step will fail.
> - `permissions: contents: read` is required for `actions/checkout`.
> - `uses: azure/login@v2` is the current correct action version as of 2026.
> - `client-id`, `tenant-id`, and `subscription-id` must reference the exact secret names you created in Step 5.5.
> - `uses: azure/cli@v2` executes an inline Azure CLI command after successful login.

### Step 6.2 — Push via Pull Request

Create a feature branch, add the workflow file, and open a pull request:

```bash
git checkout -b feature/auth-test-workflow
git add .github/workflows/azure-auth-test.yml
git commit -m "Add OIDC auth test workflow"
git push origin feature/auth-test-workflow
```

Open a pull request from `feature/auth-test-workflow` to `main` in GitHub. Have the required reviewer approve and merge it.

### Step 6.3 — Run the Workflow Manually

1. Open the **Actions** tab in GitHub
2. Select **Azure Auth Test** from the left workflow list
3. Select **Run workflow**
4. Select **Run workflow** on the branch `main`

**✅ Validation Checkpoint 6:**
- The workflow run completes with a green check
- The **Verify Azure context** step shows output that includes the correct subscription name and tenant ID
- No credentials or secrets appear in the logs
- If the workflow fails at the login step, the most common causes are:
  - `subject` mismatch in the federated credential (check the repo name, org name, and branch name exactly)
  - Missing `id-token: write` permission
  - Incorrect secret names referenced in the YAML

---

## Section 7 — Bootstrap Terraform Remote State

Terraform state must live in a dedicated remote backend, separated from the workload resources it manages. This section creates that backend manually.

### Step 7.1 — Set Naming Variables

```bash
RG_NAME="rg-tfstate-platform-scus-001"
LOCATION="southcentralus"
STG_SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
STG_NAME="sttfstate${STG_SUFFIX}"
CONTAINER_NAME="tfstate"
echo "Storage Account Name: $STG_NAME"
```

Record the storage account name. You will need it for the Terraform backend configuration.

> **📝 Naming Note**: Azure storage account names must be between 3 and 24 characters, globally unique, and contain only lowercase letters and numbers. The `sttfstate` prefix plus 8 random characters satisfies all requirements.

### Step 7.2 — Create the Resource Group

```bash
az group create \
  --name "$RG_NAME" \
  --location "$LOCATION" \
  --tags owner="<your-name>" application="landing-zone" environment="platform" purpose="terraform-state"
```

Replace `<your-name>` with actual value. All four mandatory tags must be present.

### Step 7.3 — Create the Storage Account

```bash
az storage account create \
  --name "$STG_NAME" \
  --resource-group "$RG_NAME" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --tags owner="<your-name>" application="landing-zone" environment="platform" purpose="terraform-state"
```

> **Line-by-Line Notes:**
> - `--sku Standard_LRS` is correct for Terraform state. Geo-redundancy is not needed for state because the code in GitHub is the source of truth.
> - `--kind StorageV2` is required. Do not use `BlobStorage` or `Storage`.
> - `--min-tls-version TLS1_2` enforces minimum TLS. This is a security baseline requirement.
> - `--allow-blob-public-access false` prevents public read access to state files. This is mandatory.

### Step 7.4 — Create the Blob Container

```bash
az storage container create \
  --name "$CONTAINER_NAME" \
  --account-name "$STG_NAME" \
  --auth-mode login
```

> **📝 Note**: `--auth-mode login` uses your current Entra credential to create the container. This avoids the need for a storage account key during setup.

**✅ Validation Checkpoint 7:**
- The resource group exists
- The storage account exists with the correct settings
- Public blob access is disabled
- The container `tfstate` exists

Verify:
```bash
az storage account show \
  --name "$STG_NAME" \
  --resource-group "$RG_NAME" \
  --query "{name:name, tlsVersion:minimumTlsVersion, publicAccess:allowBlobPublicAccess}" \
  --output table
```

Both `tlsVersion` should show `TLS1_2` and `publicAccess` should show `False`.

### Step 7.5 — Configure Terraform Backend

In your `terraform/backend-bootstrap/` directory, create `main.tf`:

```hcl
terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.2"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-tfstate-platform-scus-001"
    storage_account_name = "<your-storage-account-name>"
    container_name       = "tfstate"
    key                  = "bootstrap/terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}
```

Replace `<your-storage-account-name>` with the value captured in Step 7.1.

> **⚠️ Critical Note**: The `key` value is the path and filename of the state file within the container. Use a structured path like `bootstrap/terraform.tfstate` so state files are organized by layer. Never use a flat filename like `terraform.tfstate` at the root when you have multiple layers.

**✅ Validation Checkpoint 7b:**

```bash
cd terraform/backend-bootstrap
terraform init
```

Output must include: `Successfully configured the backend "azurerm"!` and `Terraform has been successfully initialized!`

If initialization fails, the most common cause is incorrect storage account name, container name, or insufficient RBAC on the storage account for the identity running the CLI session.

---

## Section 8 — Add Terraform CI/CD Workflows

### Step 8.1 — Create the Terraform Validation Workflow

Create `.github/workflows/terraform-validate.yml`:

```yaml
name: Terraform Validate

on:
  pull_request:
    branches:
      - main

permissions:
  id-token: write
  contents: read
  pull-requests: write

jobs:
  validate:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Azure login via OIDC
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.9.0

      - name: Terraform Init
        run: terraform init
        working-directory: ./terraform/backend-bootstrap

      - name: Terraform Format Check
        run: terraform fmt -check -recursive
        working-directory: ./terraform

      - name: Terraform Validate
        run: terraform validate
        working-directory: ./terraform/backend-bootstrap

      - name: Terraform Plan
        run: terraform plan -out=tfplan
        working-directory: ./terraform/backend-bootstrap
```

### Step 8.2 — Create the Terraform Apply Workflow

Create `.github/workflows/terraform-apply.yml`:

```yaml
name: Terraform Apply

on:
  push:
    branches:
      - main

permissions:
  id-token: write
  contents: read

jobs:
  apply:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Azure login via OIDC
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.9.0

      - name: Terraform Init
        run: terraform init
        working-directory: ./terraform/backend-bootstrap

      - name: Terraform Plan
        run: terraform plan -out=tfplan
        working-directory: ./terraform/backend-bootstrap

      - name: Terraform Apply
        run: terraform apply -auto-approve tfplan
        working-directory: ./terraform/backend-bootstrap
```

> **Line-by-Line Notes:**
> - `terraform plan -out=tfplan` saves the plan to a file. This ensures the apply uses exactly what was planned and prevents drift between plan and apply.
> - `terraform apply -auto-approve tfplan` applies the saved plan. `-auto-approve` is acceptable here because the plan was already reviewed in the PR step and the apply trigger is a protected branch merge.
> - `working-directory: ./terraform/backend-bootstrap` scopes each step to the bootstrap directory. Adjust this path for each Terraform layer as you add them.

---

## Section 9 — End-to-End Validation

Run this full-path test before declaring the manual implementation complete.

### Bootstrap Validation Workflow

1. ✅ An engineer signs in to GitHub using Microsoft Entra ID SSO credentials
2. ✅ The engineer creates a feature branch locally and makes a small change
3. ✅ The engineer pushes the branch and opens a pull request to `main`
4. ✅ Branch protection prevents direct merge
5. ✅ The Terraform Validate workflow runs on the PR and passes all checks
6. ✅ A reviewer approves the PR
7. ✅ The PR is merged to `main`
8. ✅ The Terraform Apply workflow triggers
9. ✅ GitHub Actions authenticates to Azure using OIDC
10. ✅ Terraform initializes with the remote backend
11. ✅ Terraform plan and apply complete successfully

### Final Validation Checkpoints

- [ ] Engineer sign-in used Entra SSO (no GitHub username/password login)
- [ ] Direct push to `main` was rejected
- [ ] PR required at least one review
- [ ] Terraform Validate ran on PR and passed
- [ ] Apply ran only after merge to `main`
- [ ] No Azure secrets or credentials were visible in logs
- [ ] Terraform state exists in the remote backend storage account

---

## Section 10 — What Comes Next

The manual implementation is now complete. You can proceed with **Phase 1** security implementations:

1. ✅ **Phase 0 (Bootstrap)**: GitHub + Azure integration - COMPLETE
2. 🎯 **Phase 1**: Critical security remediations (16 hours, $40/month)
3. 🎯 **Phase 2**: High priority enhancements (15 hours, $200/month)
4. 📋 **Phase 3**: Medium priority compliance (60 hours, $350/month)
5. 📋 **Phase 4**: Operational excellence (40 hours, $0)

---

## Known Failure Points and Troubleshooting

| Failure | Cause | Resolution |
|---|---|---|
| OIDC login fails in workflow | `subject` mismatch in federated credential | Verify exact repo name, org name, and branch match the credential JSON |
| OIDC login fails in workflow | Missing `id-token: write` permission | Add `permissions: id-token: write` to the job or workflow |
| Terraform init fails | Wrong storage account name | Recheck `STG_NAME` value used in the backend block |
| Terraform init fails | Insufficient RBAC on storage | Ensure the pipeline identity has `Storage Blob Data Contributor` on the state storage account |
| Branch push succeeds to main | Branch protection not saved | Re-confirm the protection rule is saved and covers `main` |
| Entra SSO test fails | Wrong entity ID or reply URL | Recheck the `ENTERPRISE-SLUG` in all three URLs |
| Entra SSO test fails | Certificate format error | Ensure the full certificate was copied including header and footer lines |

---

## Appendix: Additional Improvements for Later Phases

The following items should be addressed in subsequent phases:

1. Add GitHub Environments for `bootstrap`, `platform`, `connectivity`, `sandbox`, and `prod` with approval gates
2. Add a separate federated credential per environment if using environment-based OIDC trust
3. Add separate pipeline identities per deployment scope: bootstrap, platform, connectivity, and workload
4. Narrow RBAC assignments per identity
5. Deploy landing zone management groups, policy, and connectivity through separate Terraform layers

---

**✅ Phase 0 (Bootstrap) Complete**: Once all validation checkpoints pass, you are ready to proceed with Phase 1 security implementations!
