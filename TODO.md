# TODO - HCW Landing Zone Platform Development

**Created**: May 28, 2026  
**Last Updated**: June 30, 2026  
**Status**: 🟡 IN PROGRESS  
**Current Phase**: Phase 0 (Audit & Reconcile)  
**Completed Work**: See [CHANGELOG.md](CHANGELOG.md)

---

## 📋 Project Overview

Building the HCW Landing Zone Platform with three integrated components:
1. **Landing Zone Infrastructure** (Terraform modules + PowerShell scripts)
2. **Interactive Web App** (Node.js/React SPA for guided deployment)
3. **Security & Hardening** (Final audit before production launch)

**Phases** (from PLAN.md):
- Phase 0: Audit & Reconcile documentation to ground truth
- Phase 1: Web App Container & Local Docker testing
- Phase 2: Web App Azure Deployment (Container Apps)
- Phase 3: Web App Personalization & Launch
- Phase 4: Landing Zone Toolkit Consolidation
- Phase 5: Security Final Hardening Pass (last)

---

## 🟡 Phase 0: Audit & Reconcile Docs (NO CODE - Documentation Only)

**Status**: 🟡 NOT STARTED  
**Effort**: 4-6 hours  
**Priority**: 🔴 BLOCKING (must complete before Phase 1)  
**Dependencies**: None

**Objective**: Verify what's actually complete vs what's claimed in README/docs

### Tasks

- [ ] **Task 0.1**: Audit all existing TODO items against repo
  - [ ] Run Explore agent to verify every claimed completion
  - [ ] Build audit table: task_id | TODO status | README claim | actual evidence | proposed status
  - [ ] Status options: ✅ Confirmed Done, 🔁 VALIDATE (re-check in Phase 5), ⚠️ Partial, ❌ Not Done, 🟦 Deferred
  - [ ] Output: Audit table for review

- [ ] **Task 0.2**: Review audit table with user
  - [ ] Single batch review, not per-item
  - [ ] Update proposed statuses based on feedback
  - [ ] Approve final status assignments

- [ ] **Task 0.3**: Update documentation to ground truth
  - [ ] Rewrite TODO.md with audited status (done ✓)
  - [ ] Rewrite README.md claims to match audited TODO
  - [ ] Create `docs/webapp/PLAN.md` with full webapp build detail
  - [ ] Update Progress Tracking numbers to match actual counts
  - [ ] Add webapp section to repo diagram (marked "in development")

- [ ] **Task 0.4**: Verify Phase 0 Bootstrap status (GitHub + Azure integration)
  - [ ] Verify GitHub repo exists with branch protection ❓
  - [ ] Verify OIDC federation configured ❓
  - [ ] Verify Terraform Cloud workspace exists ❓
  - [ ] Verify CI/CD workflows deployed (terraform-validate.yml, terraform-apply.yml) ❓
  - [ ] Verify end-to-end deployment pipeline works ❓
  - [ ] Document findings

**Acceptance Criteria**:
- ✅ Every TODO checkbox defended by file evidence or honestly marked incomplete
- ✅ Progress Tracking numbers match actual completed checkboxes
- ✅ No claim in README absent from TODO and vice versa
- ✅ Documentation reflects audited reality, not aspirations

**Deliverables**:
- Audit table (markdown)
- Updated TODO.md
- Updated README.md
- `docs/webapp/PLAN.md`
- Phase 0 bootstrap verification report

---

## 🟦 Phase 1: Web App — Container & Local Docker Testing

**Status**: 🟦 NOT STARTED (blocked by Phase 0)  
**Effort**: 40-50 hours  
**Timeline**: Weeks 1-2 after Phase 0  
**Dependencies**: Phase 0 complete

**Objective**: Build webapp locally in Docker, prove end-to-end flow on desktop (no Azure spend)

### Subtasks

#### 1.1 Scaffold Project Structure

- [ ] Create `webapp/` directory with subdirectories:
  - [ ] `webapp/frontend/` (React + Vite + TypeScript + Tailwind)
  - [ ] `webapp/backend/` (Node.js + Express + TypeScript)
  - [ ] `webapp/docker/` (Dockerfile + compose)
  - [ ] `webapp/infrastructure/` (Bicep for Phase 2)

- [ ] Create root files:
  - [ ] `docker-compose.yml` (local dev)
  - [ ] `.dockerignore`
  - [ ] `webapp/README.md` (getting started)
  - [ ] `.env.example` (for GITHUB_CLIENT_ID, etc.)

#### 1.2 Backend (Node.js + TypeScript + Express) - Parallel with 1.3

- [ ] Setup:
  - [ ] Initialize Node.js project with package.json
  - [ ] Configure TypeScript (tsconfig.json)
  - [ ] Setup Express server on port 3001

- [ ] REST Endpoints:
  - [ ] `GET /api/health` - healthcheck (returns 200 + uptime)
  - [ ] `POST /api/bootstrap` - initiate landing zone setup
  - [ ] `GET /api/jobs/:id` - check job status/progress
  - [ ] `GET /api/auth/github/callback` - GitHub OAuth callback

- [ ] Services:
  - [ ] GitHub OAuth via Octokit (sign-in flow)
  - [ ] Bootstrap service - TypeScript port of `Initialize-LandingZone.ps1` logic
  - [ ] In-memory job store (Phase 1 only, replaced with Table Storage in Phase 2)
  - [ ] Azure setup stub (returns mock OIDC config)

- [ ] Quality:
  - [ ] Error handling for all endpoints
  - [ ] Request validation
  - [ ] Logging setup

#### 1.3 Frontend (React + Vite + TypeScript + Tailwind) - Parallel with 1.2

- [ ] Setup:
  - [ ] Initialize React project via Vite
  - [ ] Configure TypeScript
  - [ ] Setup Tailwind CSS

- [ ] Pages & Components:
  - [ ] Landing page with "Sign in with GitHub" button
  - [ ] 4-step wizard:
    - [ ] Step 1: Organization Config (name, prefix, region)
    - [ ] Step 2: Azure Config (subscription, tenant, resource group)
    - [ ] Step 3: Review & Confirm (summary of choices)
    - [ ] Step 4: Status & Progress (job polling, real-time updates)
  - [ ] Job status component (polling /api/jobs/:id)
  - [ ] Error/success screens

- [ ] Features:
  - [ ] GitHub OAuth integration
  - [ ] Session state management
  - [ ] Form validation
  - [ ] API client (fetch wrapper)

#### 1.4 Multi-Stage Dockerfile - Depends on 1.2 & 1.3

- [ ] Stage 1 (Frontend):
  - [ ] Build React app → static assets (dist/)

- [ ] Stage 2 (Backend):
  - [ ] Build TypeScript → JavaScript (dist/)

- [ ] Stage 3 (Runtime):
  - [ ] Base: Node.js Alpine (latest)
  - [ ] Non-root user (node)
  - [ ] Copy frontend assets + backend JS
  - [ ] Expose port 8080
  - [ ] Healthcheck: `curl /api/health`
  - [ ] Target: <300MB image, multi-arch (linux/amd64 + linux/arm64)

#### 1.5 Docker Compose for Local Dev - Depends on 1.4

- [ ] `docker-compose.yml`:
  - [ ] Single `webapp` service
  - [ ] Port mapping: `8080:8080`
  - [ ] Environment: GITHUB_CLIENT_ID, GITHUB_CLIENT_SECRET, SESSION_SECRET
  - [ ] Healthcheck on `/api/health`
  - [ ] Volume mounts for local development (optional)

- [ ] `.env.local` template:
  - [ ] Instructions for getting GitHub OAuth credentials
  - [ ] Callback URL: `http://localhost:8080/api/auth/github/callback`

#### 1.6 GitHub OAuth App Setup (Manual One-Time)

- [ ] Create GitHub OAuth App:
  - [ ] Name: "HCW Landing Zone (Local Dev)"
  - [ ] Authorization callback URL: `http://localhost:8080/api/auth/github/callback`
  - [ ] Note: Save Client ID and Client Secret for .env.local

#### 1.7 End-to-End Testing

- [ ] Local flow test:
  - [ ] `docker compose up --build` succeeds
  - [ ] Navigate to `localhost:8080` in browser
  - [ ] Click "Sign in with GitHub" → GitHub login flow works
  - [ ] Complete 4-step wizard
  - [ ] Create real test repo in GitHub account
  - [ ] Job status page shows progress
  - [ ] Cleanup: delete test repo

- [ ] Validation:
  - [ ] `/api/health` returns 200
  - [ ] Wizard creates real test repo
  - [ ] Image <300MB, non-root, healthcheck defined
  - [ ] Builds on both amd64 + arm64

**Deliverables**:
- `webapp/` directory with frontend, backend, Docker
- Docker image <300MB, multi-arch, with healthcheck
- `docker-compose.yml` for local dev
- Working GitHub OAuth integration
- `.env.example` template
- `webapp/README.md` with setup instructions

---

## 🟦 Phase 2: Web App — Azure Architecture & Deployment

**Status**: 🟦 NOT STARTED (blocked by Phase 1)  
**Effort**: 30-40 hours  
**Timeline**: Week 3 after Phase 1  
**Dependencies**: Phase 1 complete, Phase 0 bootstrap verified

**Objective**: Deploy proven container to Azure Container Apps with supporting infrastructure

### Subtasks

#### 2.1 Bicep Infrastructure - Parallel with 2.3

- [ ] Create `webapp/infrastructure/` directory

- [ ] Modules:
  - [ ] `containerRegistry.bicep` - Azure Container Registry
  - [ ] `logAnalytics.bicep` - Log Analytics workspace
  - [ ] `containerAppsEnv.bicep` - Container Apps environment
  - [ ] `containerApp.bicep` - Container App (system-assigned MI, 0.5 vCPU/1Gi, scale 0→3)
  - [ ] `keyVault.bicep` - Key Vault for secrets
  - [ ] `appInsights.bicep` - Application Insights

- [ ] `main.bicep`:
  - [ ] Orchestrates module calls
  - [ ] Sets up dependencies

- [ ] `parameters.bicepparam`:
  - [ ] Environment-specific values
  - [ ] Region, naming conventions, resource names

#### 2.2 Identity & RBAC

- [ ] System-assigned MI on Container App
- [ ] Role assignments:
  - [ ] AcrPull on Container Registry
  - [ ] Key Vault Secrets User on Key Vault
- [ ] Secrets via `secretRef` syntax (no plaintext env vars)

#### 2.3 GitHub Actions Deploy Workflow - Parallel with 2.1

- [ ] Create `.github/workflows/webapp-deploy.yml`:
  - [ ] Trigger: push to `main` affecting `webapp/**`
  - [ ] OIDC auth to Azure (reuse existing repo setup)
  - [ ] Build multi-arch image (amd64 + arm64)
  - [ ] Push to ACR with `:sha` + `:latest` tags
  - [ ] Update Container App revision
  - [ ] Smoke test: `curl /api/health`

#### 2.4 Production OAuth Configuration

- [ ] Add production URL to GitHub OAuth app
- [ ] Keep localhost callback URL for dev
- [ ] Update environment variables in Container App

#### 2.5 Persistent Job Store

- [ ] Replace in-memory job store with Azure Table Storage
- [ ] Service interface: identical API (no app changes needed)
- [ ] Connection string from Key Vault secret

#### 2.6 Observability

- [ ] App Insights SDK integration
- [ ] Custom events:
  - [ ] `bootstrap.started`
  - [ ] `bootstrap.repo_created`
  - [ ] `bootstrap.oidc_configured`
  - [ ] `bootstrap.completed`
  - [ ] `bootstrap.failed`
- [ ] Workbook dashboard for monitoring

**Validation Criteria**:
- [ ] `az deployment group what-if` shows clean diff
- [ ] Container revision Healthy in Azure Portal
- [ ] `https://<fqdn>/api/health` returns 200
- [ ] Full wizard works against production URL
- [ ] Auto-scale to zero verified after idle period
- [ ] Cost ~$5-15/mo with Basic ACR + scale-to-zero

**Deliverables**:
- `webapp/infrastructure/` with Bicep modules
- `.github/workflows/webapp-deploy.yml`
- App Insights integration
- Table Storage persistence

---

## 🟦 Phase 3: Web App — Personalization & Launch

**Status**: 🟦 NOT STARTED (blocked by Phase 2)  
**Effort**: 20-25 hours  
**Timeline**: Week 4 after Phase 2  
**Dependencies**: Phase 2 complete

**Objective**: Production-grade launch with security hardening

### Subtasks

#### 3.1 Custom Domain & TLS

- [ ] Register custom domain (or use existing)
- [ ] Configure managed TLS certificate
- [ ] Update OAuth callback URL to custom domain
- [ ] DNS records configured
- [ ] HTTPS working

#### 3.2 Branding - Parallel with 3.1

- [ ] Logo upload (HCW logo or customer logo)
- [ ] Favicon
- [ ] Color palette (primary, secondary, accent)
- [ ] Marketing landing page
- [ ] Email templates (if needed)

#### 3.3 Security Hardening

- [ ] Persistent sessions (Redis or signed cookies)
- [ ] CSRF protection on all POST endpoints
- [ ] Rate limiting on `/api/bootstrap` (5/hour per user, return 429 above)
- [ ] Optional organization allowlist
- [ ] Security headers:
  - [ ] Content-Security-Policy
  - [ ] Strict-Transport-Security (HSTS)
  - [ ] X-Frame-Options

#### 3.4 Legal Pages

- [ ] Terms of Service
- [ ] Privacy Policy
- [ ] Support page / Contact form
- [ ] Link from every page

#### 3.5 Analytics & Monitoring

- [ ] Uptime monitoring (pingdom, healthchecks.io, or Azure Monitor)
- [ ] Alert on errors or downtime
- [ ] Page analytics (optional)

#### 3.6 Load Testing

- [ ] Use k6 or Azure Load Testing
- [ ] Test burst scenarios (100+ concurrent users)
- [ ] Verify Container Apps auto-scale
- [ ] Check cost during load test

#### 3.7 Launch Checklist

- [ ] Security review pass (dependency: Phase 5 security items)
- [ ] Load test results verified
- [ ] Runbook created for on-call
- [ ] Public README updated
- [ ] Internal documentation complete

**Validation Criteria**:
- [ ] Custom domain working with valid TLS cert
- [ ] Lighthouse score ≥90 on landing page
- [ ] Rate limit returns 429 above threshold
- [ ] Security headers present (CSP, HSTS, X-Frame-Options)
- [ ] Privacy policy linked from every page
- [ ] Load test shows auto-scale working

**Deliverables**:
- Custom domain with TLS
- Branding assets (logo, favicon, colors)
- Security hardening (CSRF, rate limit, headers)
- Legal pages
- Load test results
- Launch runbook

---

## 🟦 Phase 4: Landing Zone Toolkit Consolidation

**Status**: 🟦 NOT STARTED (blocked by Phase 3)  
**Effort**: 20-25 hours  
**Timeline**: Week 5 after Phase 3  
**Dependencies**: Phase 3 complete

**Objective**: Sync PowerShell + Terraform + Webapp as unified toolkit

### Subtasks

#### 4.1 Feature Parity Audit

- [ ] Compare `Initialize-LandingZone.ps1` vs webapp bootstrap service
- [ ] For each step in PS script:
  - [ ] Does webapp service have equivalent?
  - [ ] If missing in webapp, add it
  - [ ] If missing in PS, document why (or add it)
- [ ] Build checklist of differences
- [ ] Close all gaps

#### 4.2 Terraform Module Documentation

- [ ] For each module under `terraform/modules/`:
  - [ ] README.md exists with:
    - [ ] Module description
    - [ ] Usage example
    - [ ] Variable table (required vs optional)
    - [ ] Outputs described
    - [ ] Cost estimate
  - [ ] `.terraform-docs.yml` configured (auto-gen README)
  - [ ] `terraform-docs .` generates current README

#### 4.3 PowerShell Script Hardening

- [ ] `Initialize-LandingZone.ps1`:
  - [ ] Input validation for all parameters
  - [ ] Error handling (try/catch)
  - [ ] Logging to file and console

- [ ] `Cleanup-ExpiredSandboxResources.ps1` (Phase 5 VALIDATE tasks):
  - [ ] Input validation (GUID format, subscription exists)
  - [ ] Sandbox tag validation
  - [ ] Max deletion limit (safety check)
  - [ ] Dry-run log to file before actual deletion
  - [ ] Log Analytics audit trail

#### 4.4 Day-2 Operations Documentation

- [ ] Review `docs/day2/` directory:
  - [ ] Ensure guides match current toolkit reality
  - [ ] Update broken links or outdated procedures
  - [ ] Add any missing runbooks (scaling, troubleshooting, etc.)

#### 4.5 Bootstrap Progress Tracker

- [ ] Decision: Keep paper tracker or fold into webapp UI?
- [ ] If retiring: Archive old tracker
- [ ] If moving to webapp: Add progress tracking to Phase 2 webapp

**Validation Criteria**:
- [ ] Feature parity checklist complete with no open gaps
- [ ] All modules have README + examples + variable table
- [ ] `terraform fmt -check` and `terraform validate` clean
- [ ] PowerShell `Invoke-ScriptAnalyzer` clean
- [ ] All toolkit + webapp links resolve
- [ ] Day-2 docs match current toolkit

**Deliverables**:
- Feature parity checklist
- Updated READMEs for all modules
- Hardened PowerShell scripts
- Updated day-2 operations docs

---

## 🔴 Phase 5: Security — Final Hardening Pass (LAST)

**Status**: 🔴 NOT STARTED (blocked by Phase 4)  
**Effort**: 40-50 hours  
**Timeline**: Week 6 after Phase 4  
**Dependencies**: Phase 4 complete, everything in repo

**Objective**: Cohesive security hardening pass on webapp + infra + scripts together

### Group A: VALIDATE Previously Claimed-Complete Items

Re-verify each, then mark complete with date + commit SHA or reopen if issues found.

- [ ] **Task 1.1**: Service Principal RBAC validation in CI/CD
  - [ ] Verify SP scoped per deployment layer
  - [ ] Verify least-privilege roles assigned
  - [ ] Verify RBAC validation step in workflows
  - [ ] Test deployment with restricted permissions

- [ ] **Task 1.2**: Terraform state storage secured
  - [ ] Verify TFC workspace encryption at rest/transit
  - [ ] Verify public_network_access_enabled = false
  - [ ] Verify access logging enabled
  - [ ] Verify no local state in repo

- [ ] **Task 1.3**: PowerShell Cleanup script hardening
  - [ ] Verify GUID validation on inputs
  - [ ] Verify subscription existence check
  - [ ] Verify sandbox tag validation
  - [ ] Verify dry-run capability
  - [ ] Verify Log Analytics audit trail
  - [ ] Test full cleanup flow

- [ ] **Task 5.5**: Defender baseline module
  - [ ] Verify module exists at `terraform/modules/defender-baseline/`
  - [ ] Verify README + deployment guide
  - [ ] Verify cost documentation
  - [ ] Verify not auto-deployed (explicit opt-in only)

- [ ] **Task SEC-1**: GitHub secret scanning
  - [ ] Verify secret scanning enabled in repo settings
  - [ ] Verify Dependabot configured (`.github/dependabot.yml`)
  - [ ] Verify TruffleHog workflow exists
  - [ ] Test with dummy secret (should block)

- [ ] **Task 5.1**: GitHub Actions SHA pinning
  - [ ] Verify all actions pinned to commit SHAs
  - [ ] Verify Dependabot configured for updates
  - [ ] Verify workflows still passing

- [ ] **Task 2.2**: TLS 1.2 enforcement policy
  - [ ] Verify policy exists at `terraform/modules/policy-baseline/policy-tls-minimum.tf`
  - [ ] Verify policy covers: Storage, MySQL, PostgreSQL, App Service, Functions, APIM
  - [ ] Verify assigned at root management group
  - [ ] Verify Deny mode (not Audit)

- [ ] **Task 5.3**: Azure Firewall threat intelligence
  - [ ] Verify firewall policy exists at `terraform/modules/hub-network/firewall-threat-intel.tf`
  - [ ] Verify threat intel mode: Alert (or Deny)
  - [ ] Verify DNS proxy enabled
  - [ ] Verify IDPS enabled (Premium tier)
  - [ ] Verify diagnostic logs configured

- [ ] **Task 5.2**: NSG flow logs + Traffic Analytics
  - [ ] Verify flow logs enabled on all NSGs
  - [ ] Verify 90-day retention policy
  - [ ] Verify Traffic Analytics linked to Log Analytics
  - [ ] Verify alerts configured (anomalies, denied spikes, lateral movement)

### Group B: Open Items from TODO Phases 2-4 (IMPLEMENT)

**Phase 2 Optional Modules** (create + document, not auto-deployed):

- [ ] **Task 2.1**: Customer-Managed Keys module
  - [ ] Create `terraform/modules/keyvault-cmk/main.tf`
  - [ ] Create `terraform/modules/keyvault-cmk/variables.tf`
  - [ ] Create `terraform/modules/keyvault-cmk/outputs.tf`
  - [ ] Create `terraform/modules/keyvault-cmk/README.md` (deployment guide)
  - [ ] Document cost ($250/mo) and use cases
  - [ ] Add to module index, but not auto-deployed

- [ ] **Task 9.2**: Sentinel SIEM module
  - [ ] Create `terraform/modules/sentinel-siem/main.tf`
  - [ ] Create `terraform/modules/sentinel-siem/variables.tf`
  - [ ] Create `terraform/modules/sentinel-siem/outputs.tf`
  - [ ] Create `terraform/modules/sentinel-siem/README.md` (deployment guide)
  - [ ] Document data connectors (Activity, Security Center, Firewall, Storage)
  - [ ] Document analytics rules (10+ built-in + custom templates)
  - [ ] Document incident automation with Logic Apps
  - [ ] Document cost ($300/mo) and use cases

**Phase 3 Medium Priority** (implement):

- [ ] **Task 9.3**: Security alerting
  - [ ] Create action group in `terraform/modules/platform-management/`
  - [ ] Activity log alerts: policy changes, role assignments, deletions, NSG/firewall/MG changes
  - [ ] Metric alerts: Firewall threats blocked, NSG anomalies, storage access failures, Key Vault access denied
  - [ ] Configure alert recipients
  - [ ] Test alert delivery

- [ ] **Task AB-3**: Resource locks
  - [ ] Add CanNotDelete locks: hub VNet, firewall, LA workspace, Key Vault, RSV
  - [ ] Add ReadOnly lock on state storage
  - [ ] Document lock removal procedures
  - [ ] Test deployment with locks in place

- [ ] **Task 9.1**: Comprehensive diagnostic logging
  - [ ] Add diagnostic settings for all NSGs, firewall, VNets, public IPs, route tables, RSVs, automation accounts, Key Vaults
  - [ ] Configure retention policies
  - [ ] Create queries for common scenarios
  - [ ] Document log retention costs

- [ ] **Task AB-2**: Backup testing automation
  - [ ] Create `terraform/scripts/Test-BackupRecovery.ps1`
  - [ ] Automated restore test: TF state, LA config, Key Vault recovery
  - [ ] Monthly schedule
  - [ ] Validation checks
  - [ ] Create `docs/day2/backup-recovery-procedures.md`

- [ ] **Task AB-1**: Private endpoints for platform services
  - [ ] Add private endpoints: LA workspace, RSV, automation account, Key Vault
  - [ ] Configure private DNS zones
  - [ ] Update firewall rules (deny public access)
  - [ ] Test connectivity via private endpoints

- [ ] **Task 2.3**: VM disk encryption policy
  - [ ] Create policy: `require-vm-disk-encryption`
  - [ ] Assign at platform management group
  - [ ] Create `terraform/modules/compute-vm/` with encryption built-in
  - [ ] Document encryption requirements

**Phase 4 Low Priority** (ongoing):

- [ ] **Finding 3.1**: Enhanced PowerShell error handling (4h)
- [ ] **Finding AB-4**: Policy remediation tasks (6h)
- [ ] **Finding CIS-2**: Guest user review automation (4h)
- [ ] **Finding CIS-5**: Subscription activity log export (2h)
- [ ] **WCAG-4**: Text alternatives for Mermaid diagrams (2h)
- [ ] **WCAG-3**: Improve link text descriptions (1h)
- [ ] **WCAG-2**: Language identifiers on code blocks (1h)
- [ ] **W3C-1**: markdownlint + fixes (2h)
- [ ] **SEC-2**: Immutable infrastructure tags (4h)
- [ ] **SEC-3**: Break-glass account documentation (4h)
- [ ] **SEC-4**: Tagging consistency improvements (4h)
- [ ] **SEC-5**: State encryption validation script (2h)
- [ ] **Finding 8.1**: State lock verification (2h)
- [ ] **Finding 8.2**: Terraform plan integrity checks (2h)
- [ ] **Finding CIS-1**: MFA enforcement documentation (4h)
- [ ] **Finding CIS-6**: Network Watcher explicit creation (2h)
- [ ] Create integration test suite for deployments (8h)
- [ ] Create automated compliance scanning (4h)
- [ ] Create disaster recovery drill procedures (4h)

### Group C: Webapp-Specific Security (NEW)

- [ ] Container image vulnerability scanning
  - [ ] Add Trivy scan to CI/CD pipeline
  - [ ] Verify 0 HIGH/CRITICAL CVEs before deploy
  - [ ] Optional: Enable Defender for Containers

- [ ] Bicep infrastructure review
  - [ ] Run `azure-validate` skill on Bicep templates
  - [ ] Security review pass
  - [ ] RBAC review pass
  - [ ] Network isolation review

- [ ] Key Vault security
  - [ ] Secrets rotation policy configured
  - [ ] Access review process documented
  - [ ] Soft-delete + purge protection enabled

- [ ] Container Apps security
  - [ ] Ingress restricted (private if applicable)
  - [ ] CORS locked down (specific origins only)
  - [ ] No debug endpoints exposed

- [ ] Webapp security hardening (cross-link Phase 3)
  - [ ] Rate limiting validated
  - [ ] CSRF protection validated
  - [ ] Session security validated (no plaintext tokens)
  - [ ] OAuth scopes minimal

- [ ] Application Insights security
  - [ ] PII scrubbing rules configured
  - [ ] Sensitive fields masked in logs
  - [ ] Access restricted

- [ ] Compliance scan
  - [ ] Run `azqr` (azure-compliance) against deployed resources
  - [ ] Verify no CRITICAL findings
  - [ ] Document accepted-risk HIGH findings

### Phase 5 Final Validation

- [ ] Every security task has `Completed: <date>` + commit SHA
- [ ] Progress Tracking shows real numbers (not aspirational)
- [ ] `azqr` report clean (no CRITICAL, HIGH only on accepted-risk)
- [ ] `trivy image` on webapp: 0 HIGH/CRITICAL CVEs
- [ ] Azure Secure Score matches documentation
- [ ] Compliance metrics in README are current

**Deliverables**:
- All Group A items verified/completed
- All Group B items implemented
- All Group C items completed
- Phase 5 validation report
- Updated README with real compliance numbers

---

## 📊 Progress Tracking

| Phase | Name | Status | Effort | Estimated Completion |
|-------|------|--------|--------|----------------------|
| **0** | Audit & Reconcile | 🟡 NOT STARTED | 4-6h | TBD |
| **1** | Web App Container | 🟦 BLOCKED | 40-50h | TBD |
| **2** | Web App Azure | 🟦 BLOCKED | 30-40h | TBD |
| **3** | Web App Launch | 🟦 BLOCKED | 20-25h | TBD |
| **4** | Toolkit Consolidation | 🟦 BLOCKED | 20-25h | TBD |
| **5** | Security Hardening | 🟦 BLOCKED | 40-50h | TBD |
| **TOTAL** | | 🟡 5% | ~155-195h | ~6 weeks |

---

## 🚀 Next Actions

1. **Start Phase 0** (Audit & Reconcile)
   - Run Explore agent to verify all claimed completions
   - Build audit table
   - Review with team
   - Update this TODO.md with audited reality

2. **Once Phase 0 complete**, proceed to Phase 1 (Web App Container)

---

## 📚 Key Documents

- **[CHANGELOG.md](CHANGELOG.md)** - All completed work (moved from TODO)
- **[PLAN.md](PLAN.md)** - Strategic overview + decisions
- **[QUICK-START-IMPLEMENTATION.md](QUICK-START-IMPLEMENTATION.md)** - PowerShell config system spec
- **[docs/webapp/PLAN.md](docs/webapp/PLAN.md)** - Detailed webapp build plan (create in Phase 0)

---

**Owner**: Platform Engineering  
**Status**: Ready for Phase 0 - Audit & Reconcile
