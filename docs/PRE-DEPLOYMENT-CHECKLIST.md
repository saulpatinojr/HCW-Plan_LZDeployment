# Pre-Deployment Checklist - Phase 1 Code Complete

**Purpose**: Comprehensive checklist ensuring ALL code, processes, and validations are complete before any infrastructure deployment.

**Status**: 🟡 IN PROGRESS - Phase 1 Code/Process Build-Out

**Deadline**: Before executing workflow 010 (Terraform Cloud initialization)

---

## I. Phase 0 (Bootstrap) - FOUNDATION

### ✅ Complete & Validated

- [x] GitHub repository created (private)
- [x] Branch protection on main (1+ approvals, no force push)
- [x] GitHub Actions OIDC federation to Azure configured
- [x] Entra SSO for GitHub Enterprise (if applicable)
- [x] CODEOWNERS file in place
- [x] .gitignore configured (Terraform, secrets)
- [x] Terraform .terraform.lock.hcl files committed
- [x] Bootstrap script: `scripts/000_LZ_Bootloader.ps1` (1,070 lines, production ready)

**Bootstrap Script Features**:
- ✅ CLI validation (az, gh, git, terraform)
- ✅ Azure authentication with OIDC
- ✅ Entra app creation (main/dev/prod SPs)
- ✅ Federated credential setup (OIDC branches/environments)
- ✅ GitHub secrets configuration (identifiers only, no long-lived secrets)
- ✅ Terraform Cloud integration
- ✅ Idempotent (state-tracking via .lz-bootloader-state.json)
- ✅ Comprehensive error handling
- ✅ Full audit trail generation

---

## II. Phase 0.1 (Terraform Initialization) - AWAITING COMPLETION

### 🔄 Workflow 010: Terraform Cloud Backend Initialization

**File**: `.github/workflows/010-terraform-init.yml`

**Purpose**: Initialize Terraform Cloud backend, validate OIDC, run terraform validate/fmt

**Responsibilities**:
1. Validate GitHub Actions → Azure OIDC federation
2. Configure Terraform Cloud workspaces
3. Run `terraform init` against TFC backend
4. Run `terraform validate` for syntax checks
5. Run `terraform fmt -check` for format compliance
6. Generate workflow summary with configuration details

**Pre-Requisites** (NOT YET COMPLETE):
- [ ] Terraform Cloud organization created
- [ ] Terraform Cloud API token generated
- [ ] GitHub secrets configured:
  - [ ] `TF_API_TOKEN` (Terraform Cloud API token)
  - [ ] `TF_CLOUD_ORGANIZATION` (organization name)
  - [ ] `AZURE_CLIENT_ID` (existing from Phase 0)
  - [ ] `AZURE_TENANT_ID` (existing from Phase 0)
  - [ ] `AZURE_SUBSCRIPTION_ID` (existing from Phase 0)
- [ ] Terraform Cloud workspaces defined:
  - [ ] `lz-global`
  - [ ] `lz-connectivity`
  - [ ] `lz-management`
  - [ ] `lz-sandbox`
  - [ ] `lz-workloads-prod`
  - [ ] `lz-workloads-nonprod`

**What This Validates**:
- ✅ OIDC federation works end-to-end
- ✅ Terraform Cloud credentials available in GitHub Actions
- ✅ Terraform configurations are syntactically valid
- ✅ Code formatting complies with standards
- ✅ All module dependencies resolvable

**Expected Output**:
- Workflow summary showing:
  - OIDC token acquired successfully
  - Terraform Cloud connection established
  - All workspaces accessible
  - terraform fmt check passed
  - terraform validate passed

---

## III. Phase 1 Code & Process Build-Out - IN PROGRESS

### Task 1.1: Service Principal RBAC Validation & Scoping

**Status**: ⏳ NOT STARTED

**Objective**: Create least-privilege service principals per deployment layer

**Deliverables**:

1. **RBAC Documentation** (`docs/RBAC-REQUIREMENTS.md`)
   - [ ] Completed: 3-layer SP architecture (global, connectivity, management, workloads, sandbox)
   - [ ] Completed: Role definitions per layer
   - [ ] Completed: Subscription scoping rules
   - [ ] Completed: Audit trail procedures
   - [ ] Completed: Troubleshooting guide
   - **Status**: ✅ COMPLETE

2. **Service Principal Creation Script** (new file needed)
   - [ ] PowerShell script: Create 5 service principals with least-privilege RBAC
   - [ ] Each SP gets Contributor (NOT Owner) on specific subscription
   - [ ] OIDC federated credentials per branch (main/develop)
   - [ ] GitHub secrets automation (SP IDs, NOT credentials)
   - **Subtask**: Create `scripts/001_Create_Service_Principals.ps1`
   - **Effort**: 3-4 hours

3. **RBAC Validation Workflow** (020 already exists)
   - [ ] File: `.github/workflows/020-rbac-validation.yml`
   - [ ] Runs on: push, PR, weekly schedule, manual trigger
   - [ ] Validates: No Owner roles, federated credentials scoped properly
   - [ ] Generates: RBAC audit report
   - **Status**: ✅ COMPLETE (in PR #6)

4. **Testing & Validation** (new effort)
   - [ ] Audit current SP permissions
   - [ ] Create 5 new SPs with proper scoping
   - [ ] Remove any Owner role assignments
   - [ ] Update GitHub Actions secrets with new SP IDs
   - [ ] Test deployment with least-privilege SPs
   - [ ] Verify workflow 020 detects issues
   - **Effort**: 4-5 hours

**Acceptance Criteria**:
- ✅ No service principal has Owner role
- ✅ Each SP scoped to single subscription (global SPs may span multiple)
- ✅ RBAC validation workflow (020) passes
- ✅ Deployment succeeds with least-privilege SPs
- ✅ Audit trail captures all changes

**Files to Create/Update**:
- [ ] `scripts/001_Create_Service_Principals.ps1` (NEW)
- [x] `docs/RBAC-REQUIREMENTS.md` (EXISTS in PR #6)
- [x] `.github/workflows/020-rbac-validation.yml` (EXISTS in PR #6)

---

### Task 1.2: Terraform State Security Documentation

**Status**: ⏳ AWAITING TERRAFORM CLOUD SETUP

**Objective**: Document Terraform Cloud state security configuration

**Context**: Terraform Cloud provides enterprise-grade state management out of box:
- ✅ Encrypted at rest (TLS 1.3)
- ✅ Encrypted in transit (TLS 1.3)
- ✅ No public internet access
- ✅ Audit logging
- ✅ Automatic backups

**Deliverables**:

1. **TFC Security Documentation** (`docs/TERRAFORM-CLOUD-SECURITY.md`)
   - [ ] State encryption details (at rest, in transit)
   - [ ] Network isolation approach
   - [ ] Access control mechanisms
   - [ ] Audit logging configuration
   - [ ] Backup & recovery procedures
   - [ ] Team token management best practices
   - **Effort**: 2 hours

2. **Deployment Guide Update** (`docs/DEPLOYMENT-GUIDE.md`)
   - [ ] Reference TFC state management (instead of Azure Storage)
   - [ ] Document workspace initialization steps
   - [ ] Backend configuration requirements
   - [ ] State access procedures
   - **Effort**: 1-2 hours

3. **Testing & Validation** (new effort)
   - [ ] Verify state files encrypted in TFC
   - [ ] Verify access logs available
   - [ ] Test state locking mechanism
   - [ ] Document state recovery procedures
   - **Effort**: 2 hours

**Acceptance Criteria**:
- ✅ TFC workspace created and accessible
- ✅ State operations authenticated via OIDC
- ✅ Access logging enabled in TFC
- ✅ Documentation complete and current
- ✅ Team/API token security practices documented

**Files to Create/Update**:
- [ ] `docs/TERRAFORM-CLOUD-SECURITY.md` (NEW)
- [ ] `docs/DEPLOYMENT-GUIDE.md` (UPDATE)

**Estimated Effort**: 5-6 hours

---

### Task SEC-1: GitHub Secret Scanning & Protection

**Status**: ⏳ NOT STARTED

**Objective**: Enable automated secret detection and prevent credential commits

**Deliverables**:

1. **Repository Settings Configuration** (manual)
   - [ ] Enable Dependency graph
   - [ ] Enable Dependabot alerts
   - [ ] Enable Secret scanning
   - [ ] Enable Push protection (blocks commits with secrets)
   - **Effort**: 30 minutes

2. **Secret Scanning Workflow** (new file)
   - [ ] File: `.github/workflows/secrets-scan.yml`
   - [ ] Tool: TruffleHog (scans for secrets in commits)
   - [ ] Runs on: every push, PR
   - [ ] Blocks merge if secrets found
   - [ ] Effort**: 1.5 hours
   - **File**: `.github/workflows/secrets-scan.yml` (NEW)

3. **Dependabot Configuration** (new file)
   - [ ] File: `.github/dependabot.yml`
   - [ ] Scans: GitHub Actions, Terraform dependencies
   - [ ] Creates: Weekly PRs with updates
   - [ ] Effort**: 1 hour
   - **File**: `.github/dependabot.yml` (NEW)

4. **Testing & Validation** (new effort)
   - [ ] Test with dummy AWS credential (should block)
   - [ ] Test with dummy Azure secret (should block)
   - [ ] Verify TruffleHog scan catches secrets
   - [ ] Review first Dependabot PRs
   - [ ] Document secret rotation procedures
   - **Effort**: 1.5 hours

**Acceptance Criteria**:
- ✅ Secret scanning active and blocking commits
- ✅ Push protection prevents credential commits
- ✅ Dependabot creating weekly update PRs
- ✅ TruffleHog scan integrated into CI/CD
- ✅ Security documentation updated

**Files to Create/Update**:
- [ ] `.github/workflows/secrets-scan.yml` (NEW)
- [ ] `.github/dependabot.yml` (NEW)
- [ ] `docs/SECURITY-GUIDE.md` (UPDATE - add secret handling)

**Estimated Effort**: 4-5 hours

---

## IV. Terraform Module Code - Code Complete Status

### ✅ Phase 1 Modules - COMPLETE

**Sandbox Module** (`terraform/modules/sandbox/`)
- [x] terraform.tf (version & provider constraints)
- [x] variables.tf (4 typed inputs with validation)
- [x] main.tf (resource group + feature toggle)
- [x] outputs.tf (anti-corruption layer)
- [x] .terraform-docs.yml (auto-documentation)
- [x] README.md (comprehensive guide)
- [x] Validation: terraform fmt & terraform validate passed
- [x] AVM Compliance: 11/11 requirements verified

**Live Configuration** (`terraform/live/sandbox/`)
- [x] main.tf (module call)
- [x] variables.tf (local variables)
- [x] outputs.tf (pass-through)
- [x] terraform.tfvars (example config)
- [x] backend.hcl (TFC backend)
- [x] Validation: terraform fmt & terraform validate passed

**Documentation** (Task 1.3)
- [x] docs/TASK-1.3-COMPLETION-REPORT.md (1,200+ lines)
- [x] docs/SESSION-SUMMARY-2026-06-30.md (progress tracking)
- [x] terraform/modules/sandbox/README.md (250+ lines)

### ⏳ Phase 1+ Modules - NOT STARTED

**Global Module** (`terraform/modules/global/` or similar)
- [ ] Resource group(s) for global state
- [ ] Key Vault for encryption keys
- [ ] Storage account for Terraform state backups
- [ ] Networking prerequisites
- **Status**: Specification needed
- **Effort**: 8-10 hours

**Connectivity Module** (`terraform/modules/hub-network/` or similar)
- [ ] Hub VNet
- [ ] Azure Firewall
- [ ] VPN/ExpressRoute Gateway
- [ ] Network Watcher
- [ ] NSG with flow logs
- [ ] Private DNS zones
- **Status**: Specification needed
- **Effort**: 10-12 hours

**Management Module** (`terraform/modules/platform-management/` or similar)
- [ ] Log Analytics Workspace
- [ ] Recovery Services Vault
- [ ] Automation Account
- [ ] Policy assignments
- [ ] Role-based access control
- [ ] Monitoring & alerting
- **Status**: Specification needed
- **Effort**: 8-10 hours

---

## V. CI/CD Workflows - Status

### ✅ Phase 0 Workflows - COMPLETE

- [x] `.github/workflows/010-terraform-init.yml` (TFC initialization)
- [x] `.github/workflows/020-rbac-validation.yml` (RBAC audit)

### ⏳ Phase 1 Workflows - NOT STARTED

**100: Terraform Plan (Drift Detection)**
- [ ] File: `.github/workflows/100-terraform-plan.yml`
- [ ] Trigger: On PR
- [ ] Actions:
  - [ ] Checkout code
  - [ ] Azure OIDC login
  - [ ] Terraform init with TFC backend
  - [ ] Terraform plan per layer
  - [ ] Post plan results to PR comment
  - [ ] Detect drift (manual changes)
  - [ ] Require approval for changes
- **Effort**: 3-4 hours
- **Status**: Specification exists in docs

**200: Terraform Apply (State Enforcement)**
- [ ] File: `.github/workflows/200-terraform-apply.yml`
- [ ] Trigger: On main merge
- [ ] Actions:
  - [ ] Checkout code
  - [ ] Azure OIDC login
  - [ ] Terraform init with TFC backend
  - [ ] Terraform apply per layer (with TFC state lock)
  - [ ] Generate apply summary
  - [ ] Tag release with deployment ID
  - [ ] Notify stakeholders
- **Effort**: 3-4 hours
- **Status**: Specification exists in docs

**300: Compliance Scan (Policy Validation)**
- [ ] File: `.github/workflows/300-compliance-scan.yml`
- [ ] Trigger: On PR, weekly schedule
- [ ] Actions:
  - [ ] Checkov scan (IaC compliance)
  - [ ] Terralint (style & best practices)
  - [ ] Policy validation against Azure Policies
  - [ ] Report results in PR comment
- **Effort**: 2-3 hours
- **Status**: Specification needed

---

## VI. Bootstrap & Setup Scripts - Status

### ✅ Complete

- [x] `scripts/000_LZ_Bootloader.ps1` (Phase 0 bootstrap, 1,070 lines)

### ⏳ Not Yet Created

- [ ] `scripts/001_Create_Service_Principals.ps1` (Task 1.1)
  - Create 5 SPs with least-privilege RBAC
  - Configure OIDC federated credentials
  - Update GitHub secrets
  - Generate audit report
  - **Effort**: 3-4 hours

- [ ] `scripts/002_Validate_RBAC.ps1` (Task 1.1)
  - Audit current SP permissions
  - Verify no Owner roles
  - Check federated credential scoping
  - Report any issues
  - **Effort**: 2-3 hours

- [ ] `scripts/010_Initialize_Terraform_Cloud.ps1` (Phase 0.1)
  - Create TFC organization (if needed)
  - Create TFC workspaces
  - Configure workspace variables
  - Generate API tokens
  - Configure GitHub secrets
  - **Effort**: 2-3 hours

---

## VII. Documentation Completeness

### ✅ Complete

- [x] docs/TASK-1.3-COMPLETION-REPORT.md
- [x] docs/SESSION-SUMMARY-2026-06-30.md
- [x] docs/RBAC-REQUIREMENTS.md
- [x] docs/ARCHITECTURE-DECISION.md
- [x] docs/ARCHITECTURE-SUMMARY.md
- [x] docs/BOOTSTRAP-SCRIPT-REVIEW.md
- [x] terraform/modules/sandbox/README.md
- [x] docs/bootstrap/ (8 documentation files)

### ⏳ Not Yet Created

- [ ] docs/TERRAFORM-CLOUD-SECURITY.md (Task 1.2)
- [ ] docs/DEPLOYMENT-GUIDE.md (update for TFC)
- [ ] docs/SECURITY-GUIDE.md (secret handling, rotation)
- [ ] docs/SERVICE-PRINCIPAL-GUIDE.md (SP management)
- [ ] docs/RBAC-AUDIT-PROCEDURES.md (audit trail, troubleshooting)
- [ ] docs/CI-CD-PIPELINE-GUIDE.md (workflow documentation)
- [ ] docs/DISASTER-RECOVERY.md (state recovery, rollback procedures)

---

## VIII. Testing & Validation - Status

### ✅ Complete

- [x] Terraform format check (module & live sandbox config)
- [x] Terraform validation (module & live sandbox config)
- [x] AVM compliance verification (11/11 requirements)
- [x] Module output validation (anti-corruption pattern)
- [x] Feature toggle pattern tested

### ⏳ Not Yet Completed

- [ ] OIDC federation end-to-end test
  - [ ] Run workflow 010 successfully
  - [ ] Terraform Cloud connects via OIDC
  - [ ] No static credentials needed
  - **Effort**: 1 hour (via workflow execution)

- [ ] RBAC least-privilege test
  - [ ] Create 5 SPs with specific permissions
  - [ ] Verify no Owner roles
  - [ ] Test deployment with restricted SP
  - [ ] Verify workflow 020 audit passes
  - **Effort**: 2 hours

- [ ] State security test
  - [ ] Verify state encrypted in TFC
  - [ ] Verify access logs available
  - [ ] Test state locking
  - [ ] Test state recovery
  - **Effort**: 2 hours

- [ ] Secret scanning test
  - [ ] Test with dummy AWS credential
  - [ ] Test with dummy Azure secret
  - [ ] Verify push protection blocks
  - [ ] Verify TruffleHog detects
  - **Effort**: 1.5 hours

- [ ] Drift detection test
  - [ ] Make manual change (via portal/CLI)
  - [ ] Run workflow 100 (terraform plan)
  - [ ] Verify drift detected
  - [ ] Verify PR comment shows changes
  - **Effort**: 1 hour

- [ ] State enforcement test
  - [ ] Approve and merge drift correction
  - [ ] Run workflow 200 (terraform apply)
  - [ ] Verify drift corrected
  - [ ] Verify TFC state updated
  - **Effort**: 1 hour

---

## IX. Pre-Deployment Validation Gate

**Critical checklist before executing ANY workflows:**

### Phase 0 Foundation
- [x] GitHub repository with branch protection
- [x] GitHub Actions OIDC federation configured
- [x] Bootstrap script complete & tested
- [x] Entra apps & SPs created (via bootstrap)

### Phase 0.1 Setup
- [ ] Terraform Cloud organization created
- [ ] Terraform Cloud workspaces defined (6 workspaces)
- [ ] GitHub secrets configured (TF_API_TOKEN, TF_CLOUD_ORGANIZATION)
- [ ] Workflow 010 code complete and tested
- **BLOCKER**: Cannot proceed without TFC setup

### Phase 1 Code Complete
- [ ] Task 1.1 code complete (SP creation script + testing)
- [ ] Task 1.2 documentation complete (TFC security guide)
- [ ] Task SEC-1 code complete (secrets scanning + Dependabot)
- [ ] Workflows 100, 200, 300 code complete
- [ ] All bootstrap scripts created and tested
- [ ] All documentation finalized

### Phase 1 Validation Complete
- [ ] OIDC federation end-to-end test passed
- [ ] RBAC least-privilege test passed
- [ ] State security test passed
- [ ] Secret scanning test passed
- [ ] Drift detection test passed
- [ ] State enforcement test passed

### Sign-Off
- [ ] Security team review complete
- [ ] Infrastructure team review complete
- [ ] Compliance sign-off obtained
- [ ] Deployment schedule established

---

## X. Deployment Sequence (NOT YET)

Once all code & validation complete:

1. **Manually execute**: workflow 010 (terraform init + TFC setup)
2. **Manually execute**: Task 1.1 scripts (create & validate SPs)
3. **Manually execute**: Task 1.2 procedures (TFC security validation)
4. **Enable**: Secret scanning in GitHub repository settings
5. **Merge & execute**: Workflows 100, 200, 300

---

## Summary

| Phase | Component | Status | Effort Remaining | Blocker |
|-------|-----------|--------|-----------------|---------|
| Phase 0 | Bootstrap | ✅ 100% | 0h | None |
| Phase 0.1 | TFC Setup | ⏳ 0% | 2h | Manual (create TFC org) |
| Phase 0.1 | Workflow 010 | ✅ 100% | 0h | Needs TFC setup |
| Phase 1.1 | RBAC Docs | ✅ 100% | 0h | None |
| Phase 1.1 | SP Script | ⏳ 0% | 3-4h | Needs coding |
| Phase 1.1 | Validation | ⏳ 0% | 4-5h | Needs SP creation |
| Phase 1.2 | TFC Docs | ⏳ 0% | 3-4h | Needs coding |
| Phase 1.2 | Validation | ⏳ 0% | 2h | Needs documentation |
| Phase 1 SEC-1 | Scanning | ⏳ 0% | 4-5h | Needs coding |
| Phase 1 SEC-1 | Validation | ⏳ 0% | 1.5h | Needs scanning setup |
| Workflows 100-300 | Code | ⏳ 0% | 8-11h | Needs coding |
| Workflows 100-300 | Validation | ⏳ 0% | 6-8h | Needs code complete |
| **TOTAL** | **All Items** | **~42% Done** | **~37-45h** | **TFC Setup** |

---

## Next Actions (No Deployments)

### Immediately (Next 2-3 hours):
1. **Create Terraform Cloud organization** (manual, 30 min)
2. **Create 6 TFC workspaces** (manual, 30 min)
3. **Generate TFC API token** (manual, 15 min)
4. **Configure GitHub secrets** for TFC (manual, 15 min)
5. **Test workflow 010** (execution, 30 min)

### Short Term (Next 8-10 hours):
1. **Create SP creation script** (`001_Create_Service_Principals.ps1`, 3-4h)
2. **Create SP validation script** (`002_Validate_RBAC.ps1`, 2-3h)
3. **Create TFC security documentation** (2-3h)

### Medium Term (Next 10-12 hours):
1. **Create secret scanning workflow** (1.5h)
2. **Create Dependabot configuration** (1h)
3. **Create workflows 100, 200, 300** (8-10h)
4. **Testing & validation** (6-8h)

### Long Term:
1. **Create Phase 2 modules** (Global, Connectivity, Management)
2. **Advanced documentation** (disaster recovery, troubleshooting)
3. **Compliance automation** (Checkov, Terralint, policy validation)

---

**Status**: Phase 1 code/process build-out IN PROGRESS  
**Blocker**: Terraform Cloud organization setup (manual step required)  
**Next Step**: Create Terraform Cloud organization and workspaces
