# Bootstrap Decision Log

**Repository**: HCW-Demo-LZDeployment  
**Purpose**: Document every decision, question, and Azure resource creation during bootstrap  
**Created**: 2026-05-28

---

## ⚠️ IMPORTANT: TESTING MODE ONLY

**THIS IS A TEST DEPLOYMENT SKELETON**  
- Do NOT commit or deploy to production until 110% confident
- All Azure resources created are REAL and will incur costs
- This log tracks all decisions and resource creation

---

## Session: 2026-05-28

### Configuration Gathered

| Item | Value | Status |
|------|-------|--------|
| Azure Account | (to be recorded) | Pending |
| Tenant ID | (to be recorded) | Pending |
| Subscription ID | (to be recorded) | Pending |
| Subscription Name | (to be recorded) | Pending |
| Org Prefix | (to be recorded) | Pending |
| GitHub Owner | saulpatinojr | Confirmed |
| GitHub Repo | HCW-Demo-LZDeployment | Confirmed |

### Decisions Made

#### Decision 1: [Date/Time]
- **Question**: [What was asked]
- **Answer**: [What was decided]
- **Rationale**: [Why this choice]
- **Impact**: [What this affects]

---

## 🚨 Azure Resources Created

### Entra ID App Registration

| Resource | Details | Status | Created Date |
|----------|---------|--------|--------------|
| **App Name** | sp-github-oidc-lz-platform | ✅ Created | 2026-05-28 |
| **App ID** | dc18e3f0-0cb5-4442-867e-c0ddc250e5fc | ✅ Exists | 2026-05-28 |
| **Service Principal** | Yes | ✅ Created | 2026-05-28 |

**⚠️ WARNING**: This creates a service principal with elevated permissions

### Federated Credentials Created

| Credential Name | Subject | Purpose | Status |
|----------------|---------|---------|--------|
| github-main-branch | repo:saulpatinojr/HCW-Demo-LZDeployment:ref:refs/heads/main | Terraform apply on push to main | ✅ Created |
| github-pull-requests | repo:saulpatinojr/HCW-Demo-LZDeployment:pull_request | Terraform plan on PRs | ✅ Created |
| github-environment-prod | repo:saulpatinojr/ (ERROR - incomplete subject) | Production deployments | ⚠️ Error |

**⚠️ ERROR NOTED**: Environment:prod credential creation failed with:
```
ERROR: The combination of issuer and subject must be unique for the application. 
Issuer https://token.actions.githubusercontent.com and Subject: repo:saulpatinojr/ already exist.
```

### RBAC Role Assignments

| Role | Scope | Assignee | Status | Risk Level |
|------|-------|----------|--------|------------|
| **Contributor** | Subscription-wide | sp-github-oidc-lz-platform | ✅ Assigned | 🔴 HIGH |
| **User Access Administrator** | Subscription-wide | sp-github-oidc-lz-platform | ✅ Assigned | 🔴 CRITICAL |

**⚠️ CRITICAL WARNING**: These roles grant:
- **Contributor**: Can create/modify/delete most Azure resources
- **User Access Administrator**: Can grant ANY role to ANY identity
- **Combined**: Effectively subscription Owner privileges via escalation

### GitHub Secrets Set

| Secret Name | Purpose | Status |
|-------------|---------|--------|
| AZURE_CLIENT_ID | Service principal app ID | ✅ Set |
| AZURE_TENANT_ID | Azure tenant identifier | ✅ Set |
| AZURE_SUBSCRIPTION_ID | Target subscription | ✅ Set |

### Storage Account (Section 7 - Pending)

| Resource | Details | Status |
|----------|---------|--------|
| **Storage Account** | (to be created) | ⏸️ Not created yet |
| **Resource Group** | (to be created) | ⏸️ Not created yet |
| **Purpose** | Terraform remote state backend | Pending |

---

## Pull Requests Created

### PR #1: Bootstrap - Add CODEOWNERS and azure-auth-test workflow
- **URL**: https://github.com/saulpatinojr/HCW-Demo-LZDeployment/pull/1
- **Branch**: bootstrap/add-codeowners-and-auth-workflow
- **Status**: Open - Awaiting review
- **Files Added**:
  - `.github/CODEOWNERS`
  - `.github/workflows/azure-auth-test.yml`
- **Will Trigger Deployments**: NO (workflow is manual-only)
- **Safe to Merge**: YES - adds documentation files only

---

## Questions & Answers

### Q1: What happens if I merge PR #1?
**A**: Merging adds 2 files to the repository:
- `CODEOWNERS` - requires PR review from @saulpatinojr
- `azure-auth-test.yml` - manual workflow (does NOT auto-run)

**Will NOT trigger**: Any deployments or resource creation
**Will NOT modify**: Existing Azure resources

### Q2: What Azure resources already exist?
**A**: The bootstrap script ALREADY CREATED:
1. Entra ID App Registration (sp-github-oidc-lz-platform)
2. Service Principal with Contributor + User Access Administrator roles
3. Federated credentials for GitHub OIDC
4. GitHub secrets pointing to your subscription

**⚠️ These exist NOW**, regardless of whether you merge the PR.

### Q3: How do I clean up if I want to start over?
**A**: Delete the Entra ID app registration:
```powershell
az ad app delete --id dc18e3f0-0cb5-4442-867e-c0ddc250e5fc
```
This removes: app registration, service principal, federated credentials, and role assignments.

---

## Risk Assessment

| Item | Risk Level | Mitigation |
|------|-----------|------------|
| Service Principal Permissions | 🔴 CRITICAL | Limit to test subscription only |
| Subscription-wide Contributor | 🔴 HIGH | Consider resource group scope instead |
| User Access Administrator role | 🔴 CRITICAL | Can escalate to Owner; review needed |
| GitHub secrets exposure | 🟡 MEDIUM | Secrets never logged; stored encrypted |
| PR merge triggers deployment | 🟢 LOW | Current PR is file-only, no triggers |

---

## Next Steps

### Before Proceeding
- [ ] Review all Azure resources created above
- [ ] Confirm subscription is for TESTING only
- [ ] Verify no production workloads in subscription
- [ ] Document approval for resource creation

### Decision Required
- [ ] **Continue**: Merge PR #1 and test authentication
- [ ] **Pause**: Create separate test repository first
- [ ] **Abort**: Delete Azure resources and start over

---

## Timeline

| Date/Time | Action | Result |
|-----------|--------|--------|
| 2026-05-28 | Bootstrap script started | Configuration gathered |
| 2026-05-28 | Section 5 (OIDC) executed | App registration created |
| 2026-05-28 | RBAC roles assigned | Contributor + UAA at subscription scope |
| 2026-05-28 | PR #1 created | Awaiting review |
| 2026-05-28 | User requested warnings | Documentation created |

---

## Notes

### User Request (2026-05-28)
> "I want to be very clear, this is for TESTING only. This repo is for the deployment skeleton. 
> I DO NOT want to commit anything... only when I am 110% this will work will I commit."

**Action Taken**: 
- Created this decision log
- Adding warning messages to bootstrap script
- Highlighting all Azure resource creation points

### Bootstrap Script Enhancement Request
- Add warnings BEFORE creating new Azure resources
- Show what will be created before creating it
- Detect existing resources and show "already created"
- Allow user to review and confirm before proceeding

---

## Audit Trail

All actions performed by bootstrap script should be recorded here with:
- Timestamp
- Resource type
- Resource identifier
- Action taken (create/update/skip)
- Result (success/error/already exists)

---

*This log should be updated after every bootstrap run and before any production deployment.*
