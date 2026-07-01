# Build Verification & Next Steps - HCW Landing Zone Platform

**Date**: 2026-06-30  
**Status**: Pre-Build Assessment  
**Scope**: Review TODO phases and verified module/infrastructure requirements

---

## Executive Summary

The HCW Landing Zone Platform is at **Phase 0 (Audit & Reconcile)** stage. The TODO.md outlines a 155-195 hour, 6-week initiative spanning 5 sequential phases plus a final security hardening pass. Before proceeding with any build work, all phases must follow **Azure Verified Modules (AVM) standards for Terraform** and **Microsoft Learn best practices for Bicep**.

### Current State
- ✅ **Terraform Infrastructure**: Partially scaffolded (modules exist but vary in completion)
- ✅ **Optional Modules**: CMK and Sentinel SIEM READMEs present (scaffold status, deferred implementation)
- ❌ **Web App (Phase 1-3)**: Not started (blocked on Phase 0 completion)
- ❌ **Phase 0 Audit**: Not started (critical blocker)

---

## Verified Modules & Standards Reference

### Azure Verified Modules (AVM) - Terraform Requirements

The repository uses Terraform modules that **should** conform to AVM standards. Key requirements:

#### ✅ **MUST Have** (Mandatory)
| Requirement | Status | Details |
|---|---|---|
| `terraform.tf` with version constraints | ⚠️ Check needed | Must specify `required_version ~> 1.6` and providers with `~> 4.0` for azurerm |
| `required_providers` block | ⚠️ Check needed | Must include azurerm `~> 4.0` and azapi `~> 2.0` if used |
| Lower snake_casing for all identifiers | ⚠️ Check needed | All variables, outputs, locals, resource names |
| Precise variable `type` declarations | ⚠️ Check needed | No `any` type; use concrete `object` instead of `map(any)` |
| No `enabled` or `module_depends_on` variables | ⚠️ Check needed | Boolean feature toggles only for specific resources |
| Sensitive outputs marked `sensitive = true` | ⚠️ Check needed | Credentials, keys, secrets must be protected |
| Deprecated items in separate files | ⚠️ Check needed | `deprecated_variables.tf`, `deprecated_outputs.tf` |
| All variables have descriptions | ⚠️ Check needed | Target module users, not developers |
| Module cross-references use registry sources | ⚠️ Check needed | Format: `source = "Azure/xxx/azurerm"` with `version = "1.2.3"` |
| No git-based module references | ⚠️ Check needed | No `git::https://` or `github.com/` references |

#### 🔄 **SHOULD Have** (Recommended)
| Requirement | Details |
|---|---|
| `.terraform-docs.yml` present | Auto-generate READMEs for each module |
| Resource/data ordering by dependency | Dependencies first, dependent resources nearby |
| `for_each` with `map()` or `set()` | Avoid dynamic keys; use static collection literals |
| Dynamic blocks for conditional nested objects | Prefer over complex conditionals |
| `coalesce()` or `try()` for defaults | Avoid verbose ternary operators |
| Alphabetical local arrangement | Keep `locals` organized |
| Collections with `nullable = false` | Avoid null in maps, lists, sets |

---

### Bicep Best Practices - Microsoft Learn Standards

For webapp infrastructure (Phase 2), Bicep modules must follow Microsoft patterns:

#### ✅ **Core Bicep Requirements**

| Requirement | Details |
|---|---|
| **camelCasing for identifiers** | Not snake_case like Terraform |
| **Parameters at top** | Make templates easy to read |
| **Clear parameter descriptions** | Help deployment operators understand requirements |
| **Precise parameter types** | Use `object` with schema, not generic `@allow()` |
| **Outputs as discrete attributes** | Anti-corruption layer pattern; don't export entire resources |
| **Sensitive outputs marked `@secure()`** | Protect secrets, keys, connection strings (Bicep 0.35.1+) |
| **Modules via registry references** | `br/public:avm/res/...` for public modules |
| **Conditional resources with `count`** | Avoid `enabled` flags; use count for existence |
| **No hardcoded values** | Always use parameters for configuration |

#### 📋 **Bicep Composition Pattern** (for Container Apps)

```bicep
// Typical structure for webapp infrastructure
param location string
param environment string  // 'dev', 'test', 'prod'
param containerImage string
param resourceNamePrefix string

// Outputs from modules, not entire resources
module containerRegistry './modules/containerRegistry.bicep' = {
  name: 'acrDeploy'
  params: {
    location: location
    name: '${resourceNamePrefix}acr${environment}'
  }
}

module containerAppsEnv './modules/containerAppsEnv.bicep' = {
  name: 'caeEnvDeploy'
  params: {
    location: location
    name: '${resourceNamePrefix}cae-${environment}'
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
  }
}

// Discrete outputs only
output registryLoginServer string = containerRegistry.outputs.loginServer
output containerAppsEnvId string = containerAppsEnv.outputs.environmentId
```

---

## Build Phase Breakdown

### Phase 0: Audit & Reconcile (🔴 **BLOCKING** - Must Complete First)

**Effort**: 4-6 hours  
**Dependencies**: None  
**Status**: NOT STARTED

#### Tasks
- [ ] **Task 0.1**: Run Explore agent to verify every TODO claim
- [ ] **Task 0.2**: Build audit table (task | status | evidence | proposed update)
- [ ] **Task 0.3**: Update TODO.md with audited ground truth
- [ ] **Task 0.4**: Verify Phase 0 bootstrap (GitHub, OIDC, TFC, CI/CD)

**Deliverables**:
- Audit table (markdown)
- Updated TODO.md (ground truth)
- Updated README.md (claims match reality)
- Phase 0 bootstrap verification report

---

### Phase 1: Web App — Container & Local Docker (🟦 BLOCKED)

**Effort**: 40-50 hours  
**Timeline**: Weeks 1-2 after Phase 0  
**Dependencies**: Phase 0 complete  
**Key Standards**: Node.js/Express TypeScript + React/Vite + Docker multi-stage

#### Critical Build Points

1. **Backend (Node.js + Express + TypeScript)**
   - `webapp/backend/` directory structure
   - REST endpoints: `/api/health`, `/api/bootstrap`, `/api/jobs/:id`, `/api/auth/github/callback`
   - GitHub OAuth via Octokit
   - In-memory job store (local only, replaced Phase 2)
   - Input validation + error handling + logging

2. **Frontend (React + Vite + TypeScript + Tailwind)**
   - `webapp/frontend/` directory
   - 4-step wizard (org config → azure config → review → progress)
   - GitHub OAuth integration
   - Form validation + session state management

3. **Docker Multi-Stage Build**
   - Stage 1: Build React (Vite) → dist/
   - Stage 2: Build Node.js (TypeScript) → dist/
   - Stage 3: Runtime Node.js Alpine, non-root user
   - Target: <300MB, multi-arch (amd64 + arm64)
   - Healthcheck on `/api/health`

4. **Local Dev (Docker Compose)**
   - Single service definition
   - Port 8080 mapped
   - Environment variables: GITHUB_CLIENT_ID, GITHUB_CLIENT_SECRET, SESSION_SECRET
   - `.env.example` template provided

#### Validation
- ✅ `docker compose up --build` succeeds
- ✅ Browser: `localhost:8080` loads landing page
- ✅ GitHub OAuth flow works end-to-end
- ✅ Wizard creates real test repo
- ✅ Image <300MB, multi-arch, healthcheck present

**Deliverables**:
- `webapp/` directory (frontend + backend + docker)
- `docker-compose.yml`
- `.env.example` + `.dockerignore`
- `webapp/README.md` (getting started guide)

---

### Phase 2: Web App — Azure Architecture & Deployment (🟦 BLOCKED)

**Effort**: 30-40 hours  
**Timeline**: Week 3 after Phase 1  
**Dependencies**: Phase 1 complete  
**Key Standards**: **Bicep modules following Microsoft Learn patterns**

#### Critical Build Points

1. **Bicep Infrastructure Modules** (follow AVM patterns adapted for Bicep)
   - `webapp/infrastructure/containerRegistry.bicep` — ACR with geo-replication
   - `webapp/infrastructure/logAnalytics.bicep` — Log Analytics workspace
   - `webapp/infrastructure/containerAppsEnv.bicep` — Container Apps environment + network
   - `webapp/infrastructure/containerApp.bicep` — The app itself (system-assigned MI, 0.5 vCPU/1Gi, scale 0→3)
   - `webapp/infrastructure/keyVault.bicep` — Secrets storage (GitHub OAuth creds, session secret)
   - `webapp/infrastructure/appInsights.bicep` — Application Insights for observability
   - `webapp/infrastructure/main.bicep` — Orchestrates all modules
   - `webapp/infrastructure/parameters.bicepparam` — Environment-specific values

2. **Bicep Patterns** (per Microsoft standards)
   - All parameters at file top with descriptions
   - camelCasing (not snake_case)
   - Outputs as discrete attributes only (not entire resources)
   - Sensitive outputs marked `@secure()`
   - Use `count` for conditional resources
   - Module references via `br/public:avm/res/...` syntax
   - No hardcoded values

3. **Identity & RBAC**
   - System-assigned managed identity on Container App
   - AcrPull role on Container Registry
   - Key Vault Secrets User role
   - Secrets via `secretRef` (no plaintext env vars)

4. **GitHub Actions Deploy Workflow** (`.github/workflows/webapp-deploy.yml`)
   - Trigger: push to `main` affecting `webapp/**`
   - OIDC auth to Azure (reuse existing TFC setup)
   - Build multi-arch image (amd64 + arm64) via buildx
   - Push to ACR with `:sha` + `:latest` tags
   - Update Container App revision
   - Smoke test: `curl /api/health`

5. **Persistent Job Store**
   - Replace in-memory store with Azure Table Storage
   - Service interface stays same (no app code changes)
   - Connection string from Key Vault secret

6. **Observability**
   - Application Insights SDK integrated
   - Custom events: bootstrap.started, bootstrap.repo_created, bootstrap.oidc_configured, bootstrap.completed, bootstrap.failed
   - Workbook dashboard for monitoring

#### Validation Criteria
- ✅ `az deployment group what-if` shows clean diff
- ✅ Container revision Healthy in Azure Portal
- ✅ `https://<fqdn>/api/health` returns 200
- ✅ Full wizard works end-to-end
- ✅ Auto-scale to zero verified after idle
- ✅ Cost ~$5-15/mo (Basic ACR + scale-to-zero)

**Deliverables**:
- `webapp/infrastructure/` with 6 Bicep modules + main.bicep
- `.github/workflows/webapp-deploy.yml`
- App Insights integration
- Table Storage implementation

---

### Phase 3: Web App — Personalization & Launch (🟦 BLOCKED)

**Effort**: 20-25 hours  
**Timeline**: Week 4  
**Dependencies**: Phase 2 complete

#### Key Items
- Custom domain + TLS certificate
- Branding (logo, favicon, colors)
- Security hardening (CSRF, rate limiting 5/hour, security headers)
- Legal pages (ToS, Privacy, Support)
- Load testing (k6 or Azure Load Testing)
- Launch checklist

---

### Phase 4: Landing Zone Toolkit Consolidation (🟦 BLOCKED)

**Effort**: 20-25 hours  
**Timeline**: Week 5  
**Dependencies**: Phase 3 complete

#### Key Items
- Feature parity audit (PS script vs webapp)
- Terraform module documentation (READMEs + `.terraform-docs.yml`)
- PowerShell script hardening
- Day-2 operations docs review
- Bootstrap progress tracker decision

---

### Phase 5: Security — Final Hardening Pass (🟦 BLOCKED)

**Effort**: 40-50 hours  
**Timeline**: Week 6  
**Dependencies**: Phase 4 complete

#### Three Groups
- **Group A**: Re-verify previously claimed-complete items
  - Service Principal RBAC
  - Terraform state storage security
  - PowerShell cleanup hardening
  - Defender baseline module
  - GitHub secret scanning
  - TLS 1.2 enforcement
  - Firewall threat intelligence
  - NSG flow logs + Traffic Analytics

- **Group B**: New implementations (optional modules)
  - Customer-Managed Keys (CMK) — $250/mo, explicit opt-in
  - Sentinel SIEM — $300+/mo, requires SOC team
  - Security alerting (action groups + alerts)
  - Resource locks (CanNotDelete on critical resources)
  - Comprehensive diagnostic logging
  - Backup testing automation
  - Private endpoints for platform services
  - VM disk encryption policy

- **Group C**: Webapp-specific security
  - Container image vulnerability scanning (Trivy)
  - Bicep infrastructure review (`azure-validate`)
  - Key Vault security (rotation, access review)
  - Container Apps security (ingress, CORS)
  - Webapp hardening validation (rate limit, CSRF, session)
  - Application Insights security (PII scrubbing)
  - Compliance scan (`azqr`)

---

## Terraform Module Audit Checklist

Before building Phase 1+, verify all existing Terraform modules against AVM standards:

### Per-Module Checklist

```
Module: _______________

Structure:
- [ ] main.tf exists with resources
- [ ] variables.tf exists with all inputs
- [ ] outputs.tf exists with computed attributes
- [ ] locals.tf exists (if using locals)
- [ ] terraform.tf exists with version constraints
- [ ] README.md documents module
- [ ] .terraform-docs.yml present

Code Style:
- [ ] All identifiers use lower snake_casing
- [ ] Resources ordered: dependencies first
- [ ] for_each uses map() or set() with static keys
- [ ] Nested blocks: meta-args (top) → arguments (alpha) → meta-args (bottom)
- [ ] ignore_changes not quoted
- [ ] Dynamic blocks used for conditional nested objects
- [ ] coalesce() or try() for default values

Variables:
- [ ] No "enabled" or "module_depends_on" variables
- [ ] Variables ordered: required (alpha) → optional (alpha)
- [ ] All variables have precise types (not any)
- [ ] All variables have descriptions
- [ ] Collections have nullable = false
- [ ] No sensitive = false declarations
- [ ] No defaults for sensitive inputs

Outputs:
- [ ] Outputs use discrete attributes (not entire resources)
- [ ] Sensitive outputs marked sensitive = true
- [ ] Each output has description

Terraform Config:
- [ ] terraform block has required_version ~> 1.6
- [ ] required_providers block present
- [ ] azurerm >= 4.0, < 5.0
- [ ] azapi >= 2.0, < 3.0 (if used)
- [ ] No provider declarations in module (except aliases)

Testing:
- [ ] terraform fmt -check passes
- [ ] terraform validate passes
- [ ] tflint passes
- [ ] New resources have feature toggles
- [ ] Breaking changes documented
```

---

## Bicep Module Audit Checklist (for Phase 2 webapp)

```
Module: _______________

Structure:
- [ ] parameters at top with clear descriptions
- [ ] variables in middle (if any)
- [ ] resources deployed with conditions (count)
- [ ] outputs at bottom (discrete attributes only)
- [ ] README.md with usage examples

Code Style:
- [ ] All identifiers use camelCasing
- [ ] Parameters have @description() decorators
- [ ] Sensitive outputs marked @secure()
- [ ] Conditional resources use count (not enabled flag)
- [ ] No hardcoded values in resources

Parameters:
- [ ] All required parameters documented
- [ ] Default values sensible for test environments
- [ ] Type validation via decorators (@minLength, @maxLength, etc.)
- [ ] Object parameters use typed schemas

Outputs:
- [ ] Only computed attributes exported
- [ ] Sensitive data marked @secure()
- [ ] Never export entire resource objects

Module References:
- [ ] Use br/public:avm/res/... for public modules
- [ ] Reference by version (not latest)
- [ ] Pass parameters explicitly

Validation:
- [ ] bicep build succeeds
- [ ] bicep lint passes
- [ ] No decompile warnings (if from JSON)
```

---

## Critical Next Actions (Priority Order)

### 🔴 **MUST DO FIRST: Phase 0 Audit**
1. Run Explore agent to verify every claimed completion in TODO.md
2. Build audit table (task | status | evidence | proposed update)
3. Update TODO.md with audited reality
4. Get team sign-off on Phase 0 status

**Blocker**: Nothing else starts until Phase 0 complete.

### 🟡 **BEFORE ANY BUILD: Terraform/Bicep Standards Review**
1. Audit all `terraform/modules/*` against AVM requirements above
2. Create tickets for any standards gaps (separate files, version constraints, etc.)
3. Plan Bicep structure for Phase 2 webapp infrastructure

### 🟢 **PHASE 1 BUILD: Web App Local (40-50h)**
Start only after Phase 0 audit complete.

1. Scaffold `webapp/` directory structure
2. Build Node.js backend (Express + TypeScript)
3. Build React frontend (Vite + TypeScript + Tailwind)
4. Create multi-stage Dockerfile
5. Create `docker-compose.yml` for local dev
6. Test end-to-end locally (GitHub OAuth flow)

### 🟢 **PHASE 2 BUILD: Web App Azure (30-40h)**
Start only after Phase 1 complete.

1. Create Bicep modules per standards (container registry, log analytics, container apps env, container app, key vault, app insights, main)
2. Create GitHub Actions deploy workflow (OIDC auth, multi-arch build, ACR push)
3. Integrate Application Insights into Node.js app
4. Migrate in-memory job store to Azure Table Storage
5. Test full deployment pipeline

---

## Key Resources & References

### Verified Modules Standards
- **Terraform AVM**: https://azure.github.io/Azure-Verified-Modules/specs/terraform/
- **TFFR3 (Providers)**: Azurerm ~> 4.0, azapi ~> 2.0
- **TFNFR4 (Casing)**: Lower snake_casing required
- **TFNFR18 (Types)**: Precise types, no `any`
- **TFFR2 (Outputs)**: Discrete attributes, anti-corruption layer

### Bicep Best Practices
- **Microsoft Learn**: https://learn.microsoft.com/azure/azure-resource-manager/bicep/best-practices
- **Bicep Composition**: camelCasing, @secure() decorators, discrete outputs
- **Container Apps**: https://learn.microsoft.com/azure/container-apps/code-to-cloud-options
- **AVM Bicep**: https://azure.github.io/Azure-Verified-Modules/specs/bicep/

---

## Summary

| Phase | Status | Effort | Blocker | Key Deliverable |
|-------|--------|--------|---------|-----------------|
| **0** | 🔴 NOT STARTED | 4-6h | None (must do first) | Audit table + updated TODO |
| **1** | 🟦 BLOCKED | 40-50h | Phase 0 | Docker image <300MB, multi-arch |
| **2** | 🟦 BLOCKED | 30-40h | Phase 1 | Bicep modules + deploy workflow |
| **3** | 🟦 BLOCKED | 20-25h | Phase 2 | Domain + TLS + security headers |
| **4** | 🟦 BLOCKED | 20-25h | Phase 3 | Toolkit consolidation + docs |
| **5** | 🟦 BLOCKED | 40-50h | Phase 4 | Security hardening + compliance |

**Total**: ~155-195 hours over 6 weeks, following **AVM Terraform standards** and **Microsoft Bicep best practices**.

No build scripts execute until Phase 0 audit complete and standards checklist passed.

---

**Owner**: Platform Engineering  
**Last Updated**: 2026-06-30  
**Status**: Ready for Phase 0 - Audit & Reconcile
