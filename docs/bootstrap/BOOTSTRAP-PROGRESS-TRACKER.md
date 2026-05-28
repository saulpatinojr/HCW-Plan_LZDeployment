# Phase 0 (Bootstrap) — Progress Tracker

**Status**: ⏳ **NOT STARTED**  
**Priority**: 🔴 **MANDATORY** - Must complete before any Phase 1-4 work  
**Effort**: 4-6 hours (manual setup)  
**Cost**: $0  
**Risk Reduction**: Establishes foundation for all future work

---

## Overview

Phase 0 establishes the GitHub + Azure integration required before any infrastructure deployment can begin. This includes:
- Human trust flow (Entra SSO for engineers)
- Pipeline trust flow (GitHub Actions OIDC to Azure)
- Terraform remote state backend
- Branch protection and CI/CD workflows

**⚠️ All steps must be completed in order. Do not proceed to Phase 1 until all validation checkpoints pass.**

---

## Prerequisites Checklist

### Azure and Entra

- [ ] Active Microsoft Entra tenant
- [ ] Active Azure subscription
- [ ] Account has Entra Application Administrator/Cloud Application Administrator role
- [ ] Account has Azure subscription Owner role

### GitHub

- [ ] GitHub account exists
- [ ] GitHub Enterprise Cloud licensing (for Entra SSO)
- [ ] Enterprise account owner or organization owner permissions

### Local Tooling

- [ ] Azure CLI installed (version 2.30+)
- [ ] Git installed
- [ ] Terraform installed (version 1.6+)
- [ ] Tooling verification commands passed

---

## Section 1: Azure Identifiers

**Status**: [ ] Not Started | [ ] In Progress | [ ] Complete

- [ ] Step 1.1: Signed in to Azure CLI
- [ ] Step 1.2: Selected correct subscription
- [ ] Step 1.3: Captured Tenant ID and Subscription ID
- [ ] **Validation Checkpoint 1 PASSED**: Both GUIDs recorded

**Tenant ID**: `_______________________________________`  
**Subscription ID**: `_______________________________________`

---

## Section 2: Microsoft Entra SSO for GitHub

**Status**: [ ] Not Started | [ ] In Progress | [ ] Complete | [ ] Skipped (No Enterprise Cloud)

- [ ] Step 2.1: Added GitHub Enterprise Cloud app in Entra
- [ ] Step 2.2: Configured SAML SSO (Entity ID, Reply URL, Sign-on URL)
- [ ] Step 2.3: Downloaded SAML signing certificate (.cer)
- [ ] Step 2.4: Copied Login URL and Azure AD Identifier
- [ ] Step 2.5: Configured GitHub Enterprise SAML settings
  - [ ] **Validation Checkpoint 2a PASSED**: SAML test successful
- [ ] Step 2.6: Assigned engineers to GitHub enterprise app
- [ ] Step 2.7: Validated pilot engineer sign-in
  - [ ] **Validation Checkpoint 2b PASSED**: Pilot engineer can sign in via Entra SSO

**Notes**:
- If GitHub Enterprise Cloud is not available yet, this section can be skipped temporarily
- All other sections (3-9) can still be completed

---

## Section 3: GitHub Repository Creation

**Status**: [ ] Not Started | [ ] In Progress | [ ] Complete

- [ ] Step 3.1: Created repository `HCW-Demo-LZDeployment` (Private)
- [ ] Step 3.2: Cloned repository locally
- [ ] Step 3.3: Created folder structure (workflows, terraform, docs, scripts)
- [ ] Step 3.4: Added Terraform .gitignore
- [ ] Step 3.5: Added CODEOWNERS file
- [ ] Step 3.6: Committed and pushed initial structure
- [ ] **Validation Checkpoint 3 PASSED**: Repository structure visible in GitHub

**Repository URL**: `https://github.com/___________/HCW-Demo-LZDeployment`

---

## Section 4: Branch Protection on Main

**Status**: [ ] Not Started | [ ] In Progress | [ ] Complete

- [ ] Step 4.1: Navigated to branch protection settings
- [ ] Step 4.2: Configured protection rule for `main` branch
  - [ ] Require PR before merging
  - [ ] Require status checks to pass
  - [ ] Require conversation resolution
  - [ ] Do not allow bypassing settings
  - [ ] Restrict who can push
  - [ ] Do not allow force pushes
  - [ ] Do not allow deletions
- [ ] **Validation Checkpoint 4 PASSED**: Direct push to main rejected

---

## Section 5: GitHub Actions OIDC to Azure

**Status**: [ ] Not Started | [ ] In Progress | [ ] Complete

- [ ] Step 5.1: Created Entra app registration
  - **App ID (AZURE_CLIENT_ID)**: `_______________________________________`
- [ ] Step 5.2: Created service principal
  - **SP Object ID**: `_______________________________________`
- [ ] Step 5.3: Created federated credential for main branch
  - [ ] **Validation Checkpoint 5a PASSED**: Credential listed in output
- [ ] Step 5.4: Assigned Contributor role at subscription level
  - [ ] **Validation Checkpoint 5b PASSED**: Role assignment verified
- [ ] Step 5.5: Added GitHub secrets
  - [ ] AZURE_CLIENT_ID
  - [ ] AZURE_TENANT_ID
  - [ ] AZURE_SUBSCRIPTION_ID
  - [ ] **Validation Checkpoint 5c PASSED**: All secrets visible in GitHub

---

## Section 6: First GitHub Actions Workflow

**Status**: [ ] Not Started | [ ] In Progress | [ ] Complete

- [ ] Step 6.1: Created auth test workflow (azure-auth-test.yml)
- [ ] Step 6.2: Pushed via pull request (feature branch)
  - [ ] PR approved by reviewer
  - [ ] PR merged to main
- [ ] Step 6.3: Ran workflow manually
- [ ] **Validation Checkpoint 6 PASSED**: Workflow completed successfully, Azure context verified

---

## Section 7: Terraform Remote State Backend

**Status**: [ ] Not Started | [ ] In Progress | [ ] Complete

- [ ] Step 7.1: Set naming variables
  - **Storage Account Name**: `sttfstate________` (record this!)
  - **Resource Group**: `rg-tfstate-platform-scus-001`
  - **Container**: `tfstate`
- [ ] Step 7.2: Created resource group
- [ ] Step 7.3: Created storage account (TLS 1.2, public access disabled)
- [ ] Step 7.4: Created blob container
- [ ] **Validation Checkpoint 7 PASSED**: Storage account verified (TLS1_2, publicAccess=False)
- [ ] Step 7.5: Configured Terraform backend in main.tf
- [ ] **Validation Checkpoint 7b PASSED**: `terraform init` successful

**Storage Account Name (CRITICAL - record this!)**: `_______________________________`

---

## Section 8: Terraform CI/CD Workflows

**Status**: [ ] Not Started | [ ] In Progress | [ ] Complete

- [ ] Step 8.1: Created terraform-validate.yml (runs on PR)
- [ ] Step 8.2: Created terraform-apply.yml (runs on merge to main)
- [ ] Committed workflows via PR
- [ ] Workflows visible in Actions tab

---

## Section 9: End-to-End Validation

**Status**: [ ] Not Started | [ ] In Progress | [ ] Complete

### Bootstrap Validation Workflow

1. [ ] Engineer signed in to GitHub using Entra SSO (if available)
2. [ ] Engineer created feature branch and made test change
3. [ ] Engineer pushed branch and opened PR
4. [ ] Branch protection prevented direct merge
5. [ ] Terraform Validate workflow ran on PR and passed
6. [ ] Reviewer approved PR
7. [ ] PR merged to main
8. [ ] Terraform Apply workflow triggered
9. [ ] GitHub Actions authenticated to Azure via OIDC
10. [ ] Terraform initialized with remote backend
11. [ ] Terraform plan and apply completed successfully

### Final Validation Checkpoints

- [ ] Engineer sign-in used Entra SSO (or GitHub account if SSO not yet available)
- [ ] Direct push to main was rejected
- [ ] PR required at least one review
- [ ] Terraform Validate ran on PR and passed
- [ ] Apply ran only after merge to main
- [ ] No Azure secrets visible in logs
- [ ] Terraform state exists in remote backend storage

---

## Section 10: Bootstrap Complete!

**Status**: [ ] Not Started | [ ] **✅ COMPLETE**

Once all validation checkpoints pass:

- [x] Phase 0 (Bootstrap) complete
- [ ] Ready to proceed with Phase 1 security implementations

**Completion Date**: `___________________`  
**Completed By**: `___________________`

---

## Troubleshooting Notes

Use this space to record any issues encountered and their resolutions:

```
Issue 1:
- Problem: 
- Root Cause:
- Resolution:

Issue 2:
- Problem:
- Root Cause:
- Resolution:
```

---

## Next Steps After Bootstrap

Once Phase 0 is complete, proceed with:

1. **Phase 1** (16 hours, $40/month) - Critical security remediations
   - Service Principal RBAC validation
   - Terraform state storage security
   - PowerShell input validation
   - GitHub secret scanning

2. **Phase 2** (15 hours core, $200/month) - High priority enhancements
   - TLS 1.2 enforcement
   - Azure Firewall Threat Intelligence
   - NSG Flow Logs + Traffic Analytics

**[View full roadmap →](../../TODO.md)**
