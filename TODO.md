# TODO - Security Remediation Plan
## Azure Landing Zone Infrastructure - Compliance Tasks

**Created**: May 28, 2026  
**Last Updated**: June 30, 2026  
**Status**: 🟡 IN PROGRESS (Phase 1 Partial + NEW: AVM Phase 1 Complete)  
**Baseline Report**: [Pre-Remediation Status](docs/compliance/PRE-REMEDIATION-STATUS-2026-05-28.md)  
**Full Audit**: [Security Audit Report](docs/compliance/SECURITY-AUDIT-REPORT-2026-05-28.md)

---

## ⚠️ CRITICAL: BLOCKING ITEMS - MUST COMPLETE BEFORE ANY DEPLOYMENT

**Phase 0 is MANDATORY before deployment and must be completed first:**

### Phase 0 Status: 🟡 **PARTIALLY IMPLEMENTED** (Requires Verification)
- ⏸️ **BLOCKED**: Phase 1, Phase 2-4, and AVM Phase 2-4 cannot begin until Phase 0 is complete
- ⚠️ **CRITICAL**: All infrastructure deployment depends on Phase 0 bootstrap

**Phase 0 Completion Checklist** (MUST complete in order):
1. **Section 1**: Azure Identifiers ✅ (if completed previously)
2. **Section 2**: Entra SSO for GitHub (optional if no Enterprise Cloud)
3. **Section 3**: GitHub Repository Creation ✅ (appears done - HCW-Demo-LZDeployment exists)
4. **Section 4**: Branch Protection ❓ (need to verify)
5. **Section 5**: GitHub Actions OIDC to Azure ❓ (need to verify)
6. **Section 6**: First GitHub Actions Workflow ❓ (need to verify)
7. **Section 7**: Terraform Remote State Backend ❓ (need to verify)
8. **Section 8**: Terraform CI/CD Workflows ❓ (need to verify)
9. **Section 9**: End-to-End Validation ❓ (need to verify)

**⚠️ ACTION REQUIRED**: 
- Review Phase 0 section below
- Complete any missing sections
- Validate all checkpoints pass before proceeding to Phase 1
- Once Phase 0 is complete, Phase 1 tasks 1.1 and 1.2 can begin

---
## 🟢 AVM Phase: Azure Verified Modules Compliance (Foundation) - NEW!

**Status**: 🟢 **PHASE 1 COMPLETE** (June 30, 2026)  
**Priority**: 🔴 **CRITICAL** - Foundation for all module development  
**Total Effort**: ~2 hours (Phase 1 actual)  
**Cost**: ``  
**Risk Reduction**: Infrastructure-as-Code quality & maintainability

> **SIGNIFICANCE**: Establishes Azure Verified Modules standards across all 11 Terraform modules. Enables production-ready, certifiable, and community-contribution-eligible infrastructure code.

### ✅ AVM Phase 1: Foundation (COMPLETE - June 30, 2026)

**Status**: 🟢 **COMPLETE**  
**What This Delivers**:
- ✅ terraform.tf with version constraints in all 11 modules
- ✅ .terraform-docs.yml for auto-documentation in all 11 modules  
- ✅ No provider blocks in modules (TFNFR27 compliance)
- ✅ All modules pass terraform validate & fmt
- ✅ 6 comprehensive documentation guides

**Completed Deliverables**:
- [x] terraform.tf files: 10 created + 1 fixed (all 11 modules)
- [x] .terraform-docs.yml files: 11 created (all modules)
- [x] Documentation: [AVM-INDEX.md](docs/AVM-INDEX.md), [IMPLEMENTATION-COMPLETE-SUMMARY.md](docs/IMPLEMENTATION-COMPLETE-SUMMARY.md), [AVM-QUICK-REFERENCE.md](docs/AVM-QUICK-REFERENCE.md), [AVM-COMPLIANCE-PHASE-1-COMPLETE.md](docs/AVM-COMPLIANCE-PHASE-1-COMPLETE.md), [SESSION-SUMMARY-AVM-PHASE1.md](docs/SESSION-SUMMARY-AVM-PHASE1.md), [AVM-IMPLEMENTATION-STRATEGY.md](docs/AVM-IMPLEMENTATION-STRATEGY.md)

**Git Commits**:
- 90c2956 docs: add AVM documentation index and navigation guide
- a6cb0e1 docs: add implementation complete summary and checklist
- d71c3bf docs: add AVM session summary and quick reference guide
- 400a662 chore: complete AVM Phase 1 compliance - terraform.tf & .terraform-docs.yml

**Modules Compliant**: All 11/11 (100%)
- backup-baseline, defender-baseline, hub-network, keyvault-cmk
- management-baseline, management-groups, nsg-flow-logs
- policy-baseline, sandbox, sentinel-siem, spoke-network

**Acceptance Criteria Met**: ✅ All
- ✅ TFNFR25: terraform.tf exists in all modules
- ✅ TFNFR26: required_providers block with azurerm ~> 4.0
- ✅ TFNFR27: No provider blocks in modules
- ✅ TFNFR2: .terraform-docs.yml in all modules
- ✅ terraform validate passes
- ✅ terraform fmt compliant

**Reference**: 
- **Start here**: [AVM-INDEX.md](docs/AVM-INDEX.md) - Navigation hub for all docs
- Full completion: [AVM-COMPLIANCE-PHASE-1-COMPLETE.md](docs/AVM-COMPLIANCE-PHASE-1-COMPLETE.md)
- Implementation strategy: [AVM-IMPLEMENTATION-STRATEGY.md](docs/AVM-IMPLEMENTATION-STRATEGY.md)
- Quick reference for developers: [AVM-QUICK-REFERENCE.md](docs/AVM-QUICK-REFERENCE.md)

---

### ⏳ AVM Phase 2: Variables & Outputs (NEXT - July 1-7, 2026)

**Status**: ⚪ **READY (Phase 1 complete)**  
**Effort**: ~8 hours  
**Deadline**: July 7, 2026

**Subtasks**:
- [ ] Audit all variables for TFNFR15-24 compliance
- [ ] Audit all outputs for TFFR2, TFNFR29-30 compliance
- [ ] Fix any identified non-compliances
- [ ] Generate documentation for all modules (terraform-docs)
- [ ] Validate with checklist

**See**: [AVM-IMPLEMENTATION-STRATEGY.md](docs/AVM-IMPLEMENTATION-STRATEGY.md#phase-2-variables--outputs-compliance-week-2)

---

### ⏳ AVM Phase 3: Code Style & Ordering (FUTURE - July 8-14, 2026)

**Status**: ⚪ **PLANNED**  
**Effort**: ~6 hours  
**Focuses on**: Resource ordering, local value standards, null patterns

---

### ⏳ AVM Phase 4: Breaking Changes & Testing (FUTURE - July 15-21, 2026)

**Status**: ⚪ **PLANNED**  
**Effort**: ~4 hours  
**Focuses on**: Feature toggles, breaking change documentation, certification readiness

---


## � Phase 0: Bootstrap - GitHub + Azure Integration (Day 1) - MANDATORY

**Status**: 🔁 **REQUIRES VERIFICATION (PARTIALLY IMPLEMENTED IN REPO)**  
**Priority**: 🔴 **MUST COMPLETE BEFORE PHASE 1**  
**Effort**: 4-6 hours (manual setup)  
**Cost**: $0  
**Deadline**: Before any Phase 1-4 work begins

> **⚠️ CRITICAL**: Phase 0 must be completed in full before any infrastructure deployment or security remediation work can begin. This establishes the foundational GitHub + Azure integration required for all subsequent phases.

**What This Phase Delivers**:
- ✅ GitHub repository with branch protection
- ✅ Entra SSO for engineer access (requires GitHub Enterprise Cloud)
- ✅ GitHub Actions OIDC federation to Azure (no long-lived secrets)
- ✅ Terraform remote state backend (Azure Storage with TLS 1.2)
- ✅ CI/CD workflows (terraform-validate, terraform-apply)
- ✅ End-to-end validated deployment pipeline

**Comprehensive Guides**:
- **[Bootstrap Runbook →](docs/bootstrap/GITHUB-AZURE-BOOTSTRAP.md)** - Step-by-step implementation guide
- **[Progress Tracker →](docs/bootstrap/BOOTSTRAP-PROGRESS-TRACKER.md)** - Checklist with validation checkpoints

### Phase 0 Tasks Overview

#### Section 1: Azure Identifiers (10 minutes)
- [ ] Sign in to Azure CLI
- [ ] Select correct subscription
- [ ] Capture and record Tenant ID and Subscription ID
- [ ] **Validation Checkpoint 1 PASSED**: Both GUIDs recorded

#### Section 2: Entra SSO for GitHub (60-90 minutes)
- [ ] Add GitHub Enterprise Cloud app in Entra
- [ ] Configure SAML SSO (Entity ID, Reply URL, Sign-on URL)
- [ ] Download SAML signing certificate
- [ ] Configure GitHub Enterprise SAML settings
- [ ] **Validation Checkpoint 2a PASSED**: SAML test successful
- [ ] Assign engineers to GitHub enterprise app
- [ ] **Validation Checkpoint 2b PASSED**: Pilot engineer sign-in successful

> **Note**: This section requires GitHub Enterprise Cloud licensing. Can be skipped temporarily if not available yet.

#### Section 3: GitHub Repository Creation (15 minutes)
- [ ] Create repository `HCW-Demo-LZDeployment` (Private)
- [ ] Clone repository locally
- [ ] Create folder structure
- [ ] Add Terraform .gitignore
- [ ] Add CODEOWNERS file
- [ ] **Validation Checkpoint 3 PASSED**: Repository structure visible

#### Section 4: Branch Protection (15 minutes)
- [ ] Configure branch protection for `main`
  - [ ] Require PR before merging (1+ approvals)
  - [ ] Require status checks to pass
  - [ ] Require conversation resolution
  - [ ] Do not allow bypassing settings
  - [ ] Restrict who can push
  - [ ] Do not allow force pushes
  - [ ] Do not allow deletions
- [ ] **Validation Checkpoint 4 PASSED**: Direct push to main rejected

#### Section 5: GitHub Actions OIDC to Azure (30 minutes)
- [ ] Create Entra app registration
- [ ] Create service principal
- [ ] Create federated credential for main branch
- [ ] **Validation Checkpoint 5a PASSED**: Credential listed
- [ ] Assign Contributor role at subscription level
- [ ] **Validation Checkpoint 5b PASSED**: Role assignment verified
- [ ] Add GitHub secrets (AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID)
- [ ] **Validation Checkpoint 5c PASSED**: All secrets visible

#### Section 6: First GitHub Actions Workflow (20 minutes)
- [ ] Create auth test workflow (azure-auth-test.yml)
- [ ] Push via pull request
- [ ] Run workflow manually
- [ ] **Validation Checkpoint 6 PASSED**: Workflow successful, Azure context verified

#### Section 7: Terraform Remote State Backend (20 minutes)
- [ ] Create Terraform Cloud account (if not already done)
- [ ] Create organization and workspace
- [ ] Generate API token for CI/CD
- [ ] Configure Terraform backend cloud block in main.tf
- [ ] **Validation Checkpoint 7 PASSED**: Terraform Cloud workspace created
- [ ] **Validation Checkpoint 7b PASSED**: `terraform init` successful and synced to TFC

**🔐 CRITICAL**: Record Terraform Cloud organization name and workspace name - you'll need them for all future Terraform operations!

#### Section 8: Terraform CI/CD Workflows (20 minutes)
- [ ] Create terraform-validate.yml (runs on PR)
- [ ] Create terraform-apply.yml (runs on merge to main)
- [ ] Commit workflows via PR
- [ ] Workflows visible in Actions tab

#### Section 9: End-to-End Validation (30 minutes)
- [ ] Engineer creates feature branch with test change
- [ ] Engineer opens PR
- [ ] Branch protection prevents direct merge
- [ ] Terraform Validate workflow runs and passes
- [ ] Reviewer approves PR
- [ ] PR merged to main
- [ ] Terraform Apply workflow triggers
- [ ] GitHub Actions authenticates via OIDC
- [ ] Terraform initializes with remote backend
- [ ] Terraform plan and apply succeed
- [ ] **ALL FINAL VALIDATION CHECKPOINTS PASSED**

### Phase 0 Completion Checklist

**Before declaring Phase 0 complete, confirm:**
- [ ] All 10 sections completed
- [ ] All validation checkpoints passed
- [ ] End-to-end deployment workflow tested successfully
- [ ] No Azure secrets or credentials visible in logs
- [ ] Terraform state exists in remote backend
- [ ] Documentation updated with actual values (storage account name, App ID, etc.)

**Phase 0 Complete!** ✅  
**Completion Date**: `___________________`  
**Completed By**: `___________________`

---

## �🚨 Phase 1: Critical Remediations (0-30 days) - MANDATORY FOR PRODUCTION

**Deadline**: June 27, 2026 (⚠️ EXTENDED - Dependencies on Phase 0)  
**Core Tasks**: 4 mandatory + 1 optional  
**Core Effort**: 16 hours (2 days)  
**Core Monthly Cost**: $40  
**Risk Reduction**: 60%
**Status**: 🟡 **BLOCKED PENDING PHASE 0 COMPLETION** - Task 1.3 Complete (25% done)

**Completed**:
- ✅ Task 1.3: Terraform Sandbox Module (June 30, 2026)

**Blocked - Cannot Start Until Phase 0 Complete**:
- ⏸️ Task 1.1: Service Principal RBAC Validation (⚠️ Requires Phase 0: Entra app + service principal creation)
- ⏸️ Task 1.2: Secure Terraform State Storage (⚠️ Requires Phase 0: Terraform Cloud workspace setup)
- ⏸️ Task SEC-1: GitHub Secret Scanning (⚠️ Requires Phase 0: GitHub repo + CI/CD workflows)


**Optional Task** (Task 5.5 - Microsoft Defender): +6 hours, +$1,500-$3,000/month - Module ready, deployment deferred

### Task 1.1: Service Principal RBAC Validation & Scoping
**Priority**: 🔴 P0 - CRITICAL  
**CVSS**: 9.1  
**Effort**: 8 hours  
**Cost**: $0  
**Assignee**: [TBD]

**Subtasks**:
- [ ] Audit current service principal permissions
  ```bash
  az role assignment list --assignee <GITHUB_SP_CLIENT_ID> --all --output table
  ```
- [ ] Verify SP has only Contributor role (not Owner)
- [ ] Remove any Owner role assignments
- [ ] Create separate service principals per deployment layer:
  - [ ] `sp-terraform-global-prod`
  - [ ] `sp-terraform-connectivity-prod`
  - [ ] `sp-terraform-management-prod`
  - [ ] `sp-terraform-workloads-prod`
  - [ ] `sp-terraform-sandbox-dev`
- [ ] Assign least-privilege roles per subscription:
  - Connectivity: Contributor on connectivity subscription only
  - Management: Contributor on management subscription only
  - Workloads: Contributor on prod/nonprod subscriptions only
  - Sandbox: Contributor on sandbox subscription only
- [ ] Update GitHub Actions secrets with new SP IDs
- [ ] Add RBAC validation step to workflows (see Finding 1.1)
- [ ] Document required permissions in `docs/RBAC-REQUIREMENTS.md`
- [ ] Test deployment with restricted permissions

**Acceptance Criteria**:
- ✅ No service principal has Owner role
- ✅ Each SP scoped to single subscription
- ✅ RBAC validation passes in CI/CD
- ✅ Deployment succeeds with least-privilege

---

### Task 1.2: Secure Terraform State Storage
**Priority**: 🟢 P0 - SATISFIED BY TERRAFORM CLOUD  
**CVSS**: 8.2  
**Effort**: 0 hours (built-in)  
**Cost**: $0 (covered by TFC)  
**Assignee**: N/A - TFC handles this

**Status**: ✅ **AUTOMATICALLY SATISFIED**

Terraform Cloud provides enterprise-grade state management out of the box:
- ✅ Encrypted at rest (TLS 1.3)
- ✅ Encrypted in transit (TLS 1.3)
- ✅ No public internet access to state
- ✅ Private endpoints via Business tier (if needed)
- ✅ Audit logging via Terraform Cloud workspace
- ✅ Automatic backups and versioning

**Remaining Considerations**:
- [ ] Review Terraform Cloud security settings (state access logs, VCS integration)
- [ ] Configure team token management
- [ ] Document TFC workspace access control

**Acceptance Criteria**:
- ✅ Terraform Cloud workspace created
- ✅ State operations via TFC (no local state)
- ✅ Access logging enabled in TFC
- ✅ Team/API token security documented

**Files to Update**:
- `docs/DEPLOYMENT-GUIDE.md` (reference TFC setup instead of Azure backend)

---

### Task 1.3: Terraform Sandbox Module
**Priority**: 🔴 P0 - CRITICAL  
**CVSS**: 7.5  
**Effort**: 3 hours (actual)  
**Cost**: $0  
**Status**: ✅ **COMPLETE** (June 30, 2026)
**Assignee**: Completed

**What Changed**:
- Replaced PowerShell script approach with AVM-compliant Terraform module
- Enables full drift detection, immutability, and audit trail
- Feature toggle pattern for safe defaults
- Lifecycle tag-based cleanup strategy

**Completed Deliverables**:
- [x] Module: `terraform/modules/sandbox/` - AVM-compliant
  - [x] terraform.tf (version constraints per AVM TFNFR25/26)
  - [x] variables.tf (4 inputs with validation per AVM TFNFR18/17/20)
  - [x] main.tf (resource group + feature toggle via count)
  - [x] outputs.tf (anti-corruption layer per AVM TFFR2)
  - [x] .terraform-docs.yml (auto-documentation)
  - [x] README.md (comprehensive usage guide)
- [x] Live config: `terraform/live/sandbox/`
  - [x] main.tf (module call)
  - [x] variables.tf (local definitions)
  - [x] outputs.tf (pass-through)
  - [x] terraform.tfvars (example config)
  - [x] backend.hcl (TFC configuration)
- [x] Validation: terraform fmt & validate passed
- [x] Documentation: Task 1.3 Completion Report
- [x] AVM Compliance: All 11 requirements verified ✅

**Acceptance Criteria Met**:
- ✅ Module follows Azure Verified Modules standards
- ✅ Feature toggle prevents accidental creation
- ✅ Lifecycle management via tags
- ✅ Drift detection automatic via workflow 100
- ✅ Immutable desired state via Terraform
- ✅ Full audit trail in git + TFC
- ✅ Safe rollback via terraform destroy

**Key Achievement**:
Replaced ad-hoc PowerShell cleanup with production-ready IaC module that integrates with Phase 0.1 (Terraform Cloud backend) and workflows 100/200.

**Reference**:
- Full completion report: `docs/TASK-1.3-COMPLETION-REPORT.md`

---

### Task 5.5: Enable Microsoft Defender for Cloud ⚠️ OPTIONAL - DEFERRED
**Priority**: 🟡 OPTIONAL (High cost - requires explicit opt-in)  
**Effort**: 6 hours  
**Cost**: $1,500-$3,000/month  
**Status**: ✅ MODULE READY - Not deployed by default  
**Assignee**: [TBD]

**Decision**: Module created but NOT integrated into automatic deployments due to:
- ❗ Significant recurring cost ($1,500-$3,000/month)
- ⏳ More valuable after production workloads are deployed
- 🎯 Should be explicit opt-in decision, not default
- 📖 Full deployment guide available in module README

**When to Enable**:
- Production workloads running with sensitive data
- Compliance requirements (SOC 2, ISO 27001, HIPAA)
- Need vulnerability assessments and threat detection
- Budget approved for security tooling

**Module Location**: `terraform/modules/defender-baseline/`  
**Deployment Guide**: `terraform/modules/defender-baseline/README.md`

**Subtasks**:
- [x] Create Defender baseline module: `terraform/modules/defender-baseline/`
- [x] Define variables for all Defender plans
- [x] Configure security contact settings
- [x] Auto-provisioning configuration
- [x] Workspace connection support
- [x] Documentation with cost optimization tips
- [ ] **USER ACTION REQUIRED**: Review README and decide when to enable
- [ ] **USER ACTION REQUIRED**: Create `defender.tfvars` if enabling
- [ ] **USER ACTION REQUIRED**: Integrate module into global layer
- [ ] **USER ACTION REQUIRED**: Deploy and verify

**Acceptance Criteria** (if deployed):
- ✅ Defender enabled on chosen subscriptions
- ✅ Security score visible in portal
- ✅ Alerts configured
- ✅ Security contact receiving notifications

**Created Files**:
- ✅ `terraform/modules/defender-baseline/main.tf`
- ✅ `terraform/modules/defender-baseline/variables.tf`
- ✅ `terraform/modules/defender-baseline/outputs.tf`
- ✅ `terraform/modules/defender-baseline/README.md` (deployment guide)

---

### Task SEC-1: Enable GitHub Secret Scanning
**Priority**: 🔴 P0 - CRITICAL  
**Effort**: 2 hours  
**Cost**: $0  
**Assignee**: [TBD]

**Subtasks**:
- [ ] Enable in GitHub repository settings:
  - [ ] Dependency graph
  - [ ] Dependabot alerts
  - [ ] Secret scanning
  - [ ] Push protection
- [ ] Create `.github/workflows/secrets-scan.yml` workflow
- [ ] Add TruffleHog scan job
- [ ] Configure scan to run on PR and push
- [ ] Test with dummy secret (should block)
- [ ] Add Dependabot configuration `.github/dependabot.yml`
- [ ] Configure Dependabot for:
  - [ ] GitHub Actions
  - [ ] Terraform (if supported)
- [ ] Review and merge first Dependabot PRs
- [ ] Document secret scanning in security guide

**Acceptance Criteria**:
- ✅ Secret scanning active
- ✅ Push protection blocks commits with secrets
- ✅ Dependabot creates weekly PRs
- ✅ TruffleHog scan passes

**New Files**:
- `.github/workflows/secrets-scan.yml`
- `.github/dependabot.yml`

---

## 🟠 Phase 2: High Priority (30-90 days) - STRONGLY RECOMMENDED

**Deadline**: August 26, 2026  
**Core Tasks**: 3 mandatory + 2 optional modules  
**Core Effort**: 15 hours (2 days)  
**Core Monthly Cost**: $200 (NSG Flow Logs + Traffic Analytics)  
**Risk Reduction**: 25%

**Core Tasks Summary**:
1. Task 2.2: Enforce TLS 1.2 via Azure Policy (4h, $0)
2. Task 5.3: Azure Firewall Threat Intelligence (3h, $0)
3. Task 5.2: NSG Flow Logs + Traffic Analytics (8h, $200/mo)

**Optional Modules** (create but don't auto-deploy):
- Task 2.1 (CMK): +16 hours, +$250/month - Key Vault encryption module
- Task 9.2 (Sentinel): +12 hours, +$300/month - SIEM module

**Note**: Task 5.1 (GitHub Actions SHA pinning) was completed in Phase 1 ahead of schedule!

---

### Task 2.1: Customer-Managed Keys (CMK) ⚠️ OPTIONAL - DEFERRED
**Priority**: 🟡 OPTIONAL (Additional cost - requires explicit opt-in)  
**Effort**: 16 hours  
**Cost**: $250/month  
**Status**: ⏳ READY TO CREATE - Not deployed by default  
**Assignee**: [TBD]

**Decision**: Module will be created but NOT integrated into automatic deployments due to:
- ❗ Additional cost ($250/month for Premium Key Vault)
- 🎯 Should be explicit opt-in for enhanced encryption
- ⚖️ Basic Azure encryption-at-rest is enabled by default
- 📖 Full deployment guide will be provided in module README

**When to Enable**:
- Compliance requirements mandate customer-managed keys (HIPAA, PCI-DSS, FedRAMP)
- Need audit trail for key usage
- Require key rotation controls
- Multi-tenant scenarios requiring key isolation

**Module Location**: `terraform/modules/keyvault-cmk/`  
**Deployment Guide**: TBD - will be created with module

**Subtasks**:
- [x] Module structure planned
- [ ] **USER ACTION REQUIRED**: Review benefits and decide when to enable
- [ ] **USER ACTION REQUIRED**: Create Key Vault Premium
- [ ] **USER ACTION REQUIRED**: Generate encryption keys
- [ ] **USER ACTION REQUIRED**: Configure CMK for storage accounts
- [ ] **USER ACTION REQUIRED**: Test backup/restore with CMK

**Acceptance Criteria** (if deployed):
- ✅ Key Vault Premium deployed
- ✅ CMK configured for critical resources
- ✅ Key rotation policy active
- ✅ Recovery procedures documented

**Will Create**:
- `terraform/modules/keyvault-cmk/main.tf`
- `terraform/modules/keyvault-cmk/variables.tf`
- `terraform/modules/keyvault-cmk/outputs.tf`
- `terraform/modules/keyvault-cmk/README.md` (deployment guide)

---

### Task 9.2: Azure Sentinel SIEM ⚠️ OPTIONAL - DEFERRED
**Priority**: 🟡 OPTIONAL (Additional cost - requires explicit opt-in)  
**Effort**: 12 hours  
**Cost**: $300/month (~5GB/day)  
**Status**: ⏳ READY TO CREATE - Not deployed by default  
**Assignee**: [TBD]

**Decision**: Module will be created but NOT integrated into automatic deployments due to:
- ❗ Additional cost ($300/month for log ingestion)
- 🎯 Should be explicit opt-in for SIEM capabilities
- ⚖️ Basic Azure Activity Logs already enabled
- 📖 Full deployment guide will be provided in module README

**When to Enable**:
- Need centralized security event correlation
- Compliance requires SIEM (SOC 2, ISO 27001)
- Building Security Operations Center (SOC)
- Need automated incident response
- Want ML-based threat detection

**Module Location**: `terraform/modules/sentinel-siem/`  
**Deployment Guide**: TBD - will be created with module

**Subtasks**:
- [x] Module structure planned
- [ ] **USER ACTION REQUIRED**: Review benefits and decide when to enable
- [ ] **USER ACTION REQUIRED**: Enable SecurityInsights solution
- [ ] **USER ACTION REQUIRED**: Configure data connectors (Activity, Security Center, Firewall, Storage)
- [ ] **USER ACTION REQUIRED**: Enable analytics rules (10+ built-in + custom)
- [ ] **USER ACTION REQUIRED**: Configure incident automation with Logic Apps
- [ ] **USER ACTION REQUIRED**: Create workbooks (SOC overview, compliance, trends)
- [ ] **USER ACTION REQUIRED**: Document incident response playbooks

**Acceptance Criteria** (if deployed):
- ✅ Sentinel operational
- ✅ Data connectors flowing
- ✅ 10+ analytics rules active
- ✅ Incident automation working
- ✅ Playbooks documented

**Will Create**:
- `terraform/modules/sentinel-siem/main.tf`
- `terraform/modules/sentinel-siem/variables.tf`
- `terraform/modules/sentinel-siem/outputs.tf`
- `terraform/modules/sentinel-siem/README.md` (deployment guide with connectors & rules)

---

### Task 2.2: Enforce TLS 1.2 Globally via Azure Policy
**Priority**: 🟠 P1 - HIGH  
**Effort**: 4 hours  
**Cost**: $0  
**Assignee**: [TBD]

**Subtasks**:
- [ ] Create custom policy definition: `enforce-tls-12-minimum`
- [ ] Add policy for resource types:
  - [ ] Storage Accounts
  - [ ] Azure Database for MySQL/PostgreSQL
  - [ ] App Services
  - [ ] Function Apps
  - [ ] API Management
- [ ] Assign policy at root management group
- [ ] Set enforcement mode to Deny (not Audit)
- [ ] Test by attempting to create resource with TLS 1.0
- [ ] Audit existing resources for compliance
- [ ] Document exceptions process (if needed)

**Acceptance Criteria**:
- ✅ Policy assigned at root MG
- ✅ New resources require TLS 1.2+
- ✅ All existing resources compliant
- ✅ Policy blocks TLS 1.0/1.1

**File to Update**:
- `terraform/modules/policy-baseline/main.tf`

---

### Task 5.3: Configure Azure Firewall Threat Intelligence
**Priority**: 🟠 P1 - HIGH  
**Effort**: 3 hours  
**Cost**: $0 (included with Azure Firewall)  
**Assignee**: [TBD]

**Subtasks**:
- [ ] Create Firewall Policy resource
- [ ] Enable threat intelligence mode: Alert
- [ ] Configure threat intelligence allowlist (if needed)
- [ ] Enable DNS proxy
- [ ] For Premium tier:
  - [ ] Enable IDPS (Intrusion Detection)
  - [ ] Configure signature overrides
  - [ ] Enable TLS inspection
  - [ ] Enable URL filtering
- [ ] Link firewall policy to firewall
- [ ] Enable diagnostic logs for threat intel hits
- [ ] Configure alerts for blocked threats
- [ ] Test with known malicious IP
- [ ] Document threat response procedures

**Acceptance Criteria**:
- ✅ Threat intelligence mode: Alert or Deny
- ✅ Diagnostic logs enabled
- ✅ Alerts configured
- ✅ Test threat blocked successfully

**File to Update**:
- `terraform/modules/hub-network/main.tf`

---

### Task 5.2: Enable NSG Flow Logs + Traffic Analytics
**Priority**: 🟠 P1 - HIGH  
**Effort**: 8 hours  
**Cost**: $200/month  
**Assignee**: [TBD]

**Subtasks**:
- [ ] Create Network Watcher (explicit creation)
- [ ] Create flow log storage account (separate from state)
- [ ] Enable NSG flow logs for all NSGs:
  - [ ] Gateway subnet NSG
  - [ ] Firewall management NSG
  - [ ] App subnet NSGs
  - [ ] Management subnet NSGs
- [ ] Configure flow log retention: 90 days
- [ ] Enable Traffic Analytics:
  - [ ] Link to Log Analytics workspace
  - [ ] Interval: 10 minutes
- [ ] Create flow log analysis queries
- [ ] Configure alerts:
  - [ ] Anomalous traffic patterns
  - [ ] Denied flow spikes
  - [ ] Lateral movement detection
- [ ] Create Traffic Analytics dashboards
- [ ] Document flow log analysis procedures

**Acceptance Criteria**:
- ✅ Flow logs enabled on all NSGs
- ✅ Traffic Analytics operational
- ✅ Alerts configured
- ✅ Dashboards available

**Files to Update**:
- `terraform/modules/hub-network/main.tf`
- `terraform/modules/spoke-network/main.tf`

---

### Task 5.1: Pin GitHub Actions to Commit SHAs ✅ COMPLETE
**Priority**: ✅ COMPLETED IN PHASE 1  
**Effort**: 2 hours (actual)  
**Cost**: $0  
**Status**: ✅ **COMPLETE** (May 28, 2026 - Phase 1)  
**Assignee**: Completed ahead of schedule

**Note**: This task was completed during Phase 1 security remediation as part of Task 1.1 (Service Principal RBAC Validation). All GitHub Actions in terraform-plan.yml and terraform-apply.yml were pinned to commit SHAs for supply chain security.

**Completed Actions**:
- [x] Pin `actions/checkout@v4` to SHA `b4ffde65f46336ab88eb53be808477a3936bae11`
- [x] Pin `hashicorp/setup-terraform@v3` to SHA `b9cd54a3c349d3f38e8881555d616ced269862dd`
- [x] Pin `azure/login@v2` to SHA `6c251865b4e6290e7b78be643ea2d005bc51f69a`
- [x] Add comments with version tags for reference
- [x] Configure Dependabot for GitHub Actions
- [x] Test workflows with pinned versions

**Acceptance Criteria Met**:
- ✅ All actions pinned to commit SHAs
- ✅ Dependabot tracking updates via `.github/dependabot.yml`
- ✅ Workflows passing

**Files Updated** (Phase 1):
- `.github/workflows/terraform-plan.yml`
- `.github/workflows/terraform-apply.yml`

---

## 🟡 Phase 3: Medium Priority (90-180 days) - COMPLIANCE & BEST PRACTICES

**Deadline**: November 24, 2026  
**Total Effort**: 60 hours (8 days)  
**Monthly Cost**: $350  
**Risk Reduction**: 10%

### Task 9.3: Configure Security Alerting
**Priority**: 🟡 P2 - MEDIUM  
**Effort**: 8 hours  
**Cost**: $0

**Subtasks**:
- [ ] Create Security action group
- [ ] Configure activity log alerts:
  - [ ] Policy assignment changes
  - [ ] Role assignment changes (privileged)
  - [ ] Resource deletions (production)
  - [ ] NSG rule modifications
  - [ ] Firewall rule changes
  - [ ] Management group changes
- [ ] Configure metric alerts:
  - [ ] Azure Firewall threats blocked
  - [ ] NSG flow anomalies
  - [ ] Storage account access failures
  - [ ] Key Vault access denied
- [ ] Test alert delivery
- [ ] Document alert response procedures

**Files to Update**:
- `terraform/modules/platform-management/main.tf`

---

### Task AB-3: Add Resource Locks
**Priority**: 🟡 P2 - MEDIUM  
**Effort**: 4 hours  
**Cost**: $0

**Subtasks**:
- [ ] Add CanNotDelete locks on:
  - [ ] Hub VNets
  - [ ] Azure Firewall
  - [ ] Log Analytics workspace
  - [ ] Key Vault
  - [ ] Recovery Services Vault
- [ ] Add ReadOnly lock on state storage (conditional)
- [ ] Document lock removal procedures
- [ ] Test deployment with locks in place

**Files to Update**:
- `terraform/modules/hub-network/main.tf`
- `terraform/modules/platform-management/main.tf`
- `terraform/backend-bootstrap/main.tf`

---

### Task 9.1: Comprehensive Diagnostic Logging
**Priority**: 🟡 P2 - MEDIUM  
**Effort**: 6 hours  
**Cost**: $100/month (Log Analytics ingestion)

**Subtasks**:
- [ ] Add diagnostic settings for:
  - [ ] All NSGs (events + rule counters)
  - [ ] Azure Firewall (app, network, DNS logs)
  - [ ] VNets (activity logs)
  - [ ] Public IPs (connection logs)
  - [ ] Route tables (changes)
  - [ ] Recovery Services Vaults (backup events)
  - [ ] Automation Account (runbook execution)
  - [ ] Key Vault (access logs)
- [ ] Configure subscription-level activity log export
- [ ] Test log queries for each resource type

**Files to Update**:
- All module `main.tf` files

---

### Task AB-2: Backup Testing Automation
**Priority**: 🟡 P2 - MEDIUM  
**Effort**: 12 hours  
**Cost**: $0

**Subtasks**:
- [ ] Create backup test runbook
- [ ] Implement automated restore tests:
  - [ ] Terraform state recovery
  - [ ] Log Analytics configuration backup
  - [ ] Key Vault key recovery
- [ ] Configure test schedule (monthly)
- [ ] Create test validation checks
- [ ] Document manual recovery procedures
- [ ] Store backup verification reports

**New Files**:
- `terraform/scripts/Test-BackupRecovery.ps1`
- `docs/day2/backup-recovery-procedures.md`

---

### Task AB-1: Private Endpoints for Platform Services
**Priority**: 🟡 P2 - MEDIUM  
**Effort**: 10 hours  
**Cost**: $120/month (3 additional endpoints)

**Subtasks**:
- [ ] Add private endpoints for:
  - [ ] Log Analytics workspace
  - [ ] Recovery Services Vault
  - [ ] Automation Account
  - [ ] Key Vault (if not already done)
- [ ] Configure private DNS zones
- [ ] Update firewall rules to deny public access
- [ ] Test connectivity via private endpoints
- [ ] Update documentation

**Files to Update**:
- `terraform/modules/platform-management/main.tf`

---

### Task 2.3: VM Disk Encryption Policy
**Priority**: 🟡 P2 - MEDIUM  
**Effort**: 4 hours  
**Cost**: $0

**Subtasks**:
- [ ] Create policy: require-vm-disk-encryption
- [ ] Assign at Platform management group
- [ ] Create VM deployment module with encryption built-in
- [ ] Document encryption requirements
- [ ] Create Azure Disk Encryption Sets with CMK

**Files**:
- `terraform/modules/policy-baseline/main.tf`
- `terraform/modules/compute-vm/` (new module)

---

### Remaining Medium Priority Tasks
- [ ] **Finding 3.1**: Enhanced error handling in PowerShell (4h)
- [ ] **Finding AB-4**: Policy remediation tasks (6h)
- [ ] **Finding CIS-2**: Guest user review automation (4h)
- [ ] **Finding CIS-5**: Subscription activity log export (2h)

---

## 🟢 Phase 4: Low Priority (Ongoing) - OPTIMIZATION

**Timeline**: Continuous improvement  
**Total Effort**: 40 hours (5 days)  
**Monthly Cost**: $0  
**Risk Reduction**: 5%

### Documentation & Accessibility
- [ ] **WCAG-4**: Add text alternatives for Mermaid diagrams (2h)
- [ ] **WCAG-3**: Improve link text descriptions (1h)
- [ ] **WCAG-2**: Add language identifiers to code blocks (1h)
- [ ] **W3C-1**: Run markdownlint and fix issues (2h)

### Infrastructure Hardening
- [ ] **SEC-2**: Immutable infrastructure tags (4h)
- [ ] **SEC-3**: Break-glass account documentation (4h)
- [ ] **SEC-4**: Tagging consistency improvements (4h)
- [ ] **SEC-5**: State encryption validation script (2h)

### Operational Excellence
- [ ] **Finding 8.1**: State lock verification (2h)
- [ ] **Finding 8.2**: Terraform plan integrity checks (2h)
- [ ] **Finding CIS-1**: MFA enforcement documentation (4h)
- [ ] **Finding CIS-6**: Network Watcher explicit creation (2h)

### Testing & Validation
- [ ] Create integration test suite for deployments (8h)
- [ ] Implement automated compliance scanning (4h)
- [ ] Create disaster recovery drill procedures (4h)

---

## 📊 Progress Tracking

### Overall Status

| Phase | Status | Complete | Total | % Done | Deadline |
|---|---|---|---|---|---|
| Phase 1 | 🟡 Not Started | 0 | 5 | 0% | June 27, 2026 |
| Phase 2 | ⚪ Blocked | 0 | 6 | 0% | August 26, 2026 |
| Phase 3 | ⚪ Blocked | 0 | 10 | 0% | November 24, 2026 |
| Phase 4 | ⚪ Blocked | 0 | 15 | 0% | Ongoing |
| **TOTAL** | 🟡 **0%** | **0** | **36** | **0%** | - |

### Critical Path (Must Complete First)
1. Task 1.1 (RBAC) → Blocks all deployment tasks
2. Task 1.2 (State storage) → Blocks Terraform operations
3. Task 1.3 (PowerShell) → Blocks sandbox automation
4. Task 5.5 (Defender) → Blocks security visibility
5. Task SEC-1 (Secret scanning) → Blocks secure commits

### Dependencies
- Phase 2 requires Phase 1 completion
- Phase 3 requires Phase 1-2 completion
- CMK (Task 2.1) required before private endpoints (Task AB-1)
- Sentinel (Task 9.2) requires Defender (Task 5.5)

---

## 📈 Key Performance Indicators (KPIs)

Track these metrics to measure remediation progress:

| KPI | Baseline | Phase 1 Target | Phase 2 Target | Phase 3 Target |
|---|---|---|---|---|
| Critical Findings Open | 3 | 0 | 0 | 0 |
| High Findings Open | 12 | 3 | 0 | 0 |
| Azure Secure Score | Unknown | 70% | 80% | 85% |
| OWASP Compliance | 30% | 75% | 85% | 90% |
| CIS Compliance | 40% | 60% | 75% | 85% |
| Private Endpoint Coverage | 0% | 25% | 50% | 100% |
| Monthly Security Cost | $30 | $1,570 | $2,320 | $2,670 |

---

## 🔄 Review Schedule

- **Daily**: Phase 1 standups (during Phase 1)
- **Weekly**: Security working group meeting
- **Bi-weekly**: Executive status update
- **Monthly**: Compliance posture review
- **Quarterly**: External security assessment

---

## 📚 Reference Documentation

- [Pre-Remediation Baseline](docs/compliance/PRE-REMEDIATION-STATUS-2026-05-28.md)
- [Full Security Audit](docs/compliance/SECURITY-AUDIT-REPORT-2026-05-28.md)
- [Executive Summary](docs/compliance/EXECUTIVE-SUMMARY-2026-05-28.md)
- [Quick Action Checklist](docs/compliance/QUICK-ACTION-CHECKLIST.md)
- [Deployment Guide](docs/DEPLOYMENT-GUIDE.md)
- [Project Summary](docs/PROJECT-SUMMARY.md)

---

## 📝 Notes

**Last Updated**: May 28, 2026  
**Owner**: Platform Engineering Team  
**Approvers**: Security Team, Compliance Officer, CISO  
**Next Review**: June 1, 2026 (Kick-off meeting)

---

## ✅ Task Completion Template

When completing a task, update with:

```markdown
- [x] Task X.X: Task Name
  - Completed: YYYY-MM-DD
  - Completed by: [Name]
  - PR/Commit: [link]
  - Verification: [test results]
  - Notes: [any issues or learnings]
```

---

**Document Version**: 1.0  
**Status**: APPROVED ✅  
**Next Action**: Schedule Phase 1 kick-off meeting

