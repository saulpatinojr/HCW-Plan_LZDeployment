# Build Critical Path & Timeline

**Document Purpose**: Track critical path dependencies, blockers, and decision gates before executing any build work.

**Current Date**: 2026-06-30  
**Target Launch**: End of Week 6 (estimated 2026-08-10)  
**Total Effort**: 155-195 hours across 6 people-weeks

---

## Critical Path Diagram

```
Phase 0 (Audit) [4-6h] ──┐
                         ├──> DECISION GATE: Proceed to Phase 1?
Standards Review [4-6h] ─┘

Phase 1 (Backend) [20h] ─┐
Phase 1 (Frontend) [20h] ├──> Docker Build & Test [5h] ──> DECISION GATE: Proceed to Phase 2?
Phase 1 (Docker) [5h] ───┘

Phase 2 (Bicep Infra) [20h] ──┐
Phase 2 (Deploy Workflow) [8h] ├──> Azure Deploy & Validation [5h] ──> DECISION GATE: Proceed to Phase 3?
Phase 2 (Integration) [7h] ────┘

Phase 3 (Domain + TLS) [5h] ────┐
Phase 3 (Branding) [5h] ────────┤
Phase 3 (Security) [8h] ────────├──> Load Test + Security Review [7h] ──> DECISION GATE: Prod Ready?
Phase 3 (Legal) [3h] ───────────┤
Phase 3 (Monitoring) [4h] ──────┘

Phase 4 (Terraform Audit) [12h] ──┐
Phase 4 (Module Docs) [8h] ────────┤──> Toolkit Consolidation [5h] ──> DECISION GATE: Launch Ready?
Phase 4 (Script Hardening) [5h] ──┘

Phase 5 (Group A Validation) [20h] ──┐
Phase 5 (Group B Implementation) [20h) ├──> Final Security & Compliance [10h] ──> LAUNCH ✅
Phase 5 (Group C Hardening) [10h] ───┘
```

---

## Weekly Timeline

### Week 1: Phase 0 (Audit & Standards)
**Effort**: 8-12 hours  
**Owner**: Platform Engineer + Code Review  
**Deliverables**: Audit table, Updated TODO.md, Phase 0 Report

**Monday-Tuesday**:
- [ ] Run Explore agent on all TODO claims (4h)
- [ ] Build audit table (task | status | evidence | proposed update) (2h)
- [ ] Get team sign-off on audit findings (1h)

**Wednesday-Thursday**:
- [ ] Audit Terraform modules against AVM standards (3h)
- [ ] Document standards gaps (issues/tickets) (1h)
- [ ] Create Bicep structure plan for Phase 2 webapp (2h)

**Friday**:
- [ ] DECISION GATE: Proceed to Phase 1? (1h)
- [ ] Kickoff Phase 1 team (1h)

**Go/No-Go Criteria**:
- ✅ All TODO items audited with evidence
- ✅ Audit table approved by stakeholders
- ✅ Standards gaps documented
- ✅ Team ready for Phase 1

---

### Week 2-3: Phase 1 (Web App Local - Backend)
**Effort**: 20-25 hours  
**Owner**: Backend Developer  
**Parallel**: Frontend team starts simultaneously

**Subtasks** (Backend):
- [ ] Scaffold Node.js project + TypeScript (2h)
  - Initialize `webapp/backend/` directory
  - Configure `tsconfig.json`, `package.json`
  - Setup Express server skeleton
  
- [ ] Implement REST endpoints (8h)
  - `/api/health` with uptime metrics
  - `/api/bootstrap` POST with validation
  - `/api/jobs/:id` status polling
  - `/api/auth/github/callback` OAuth handler
  
- [ ] GitHub OAuth integration (5h)
  - Octokit client setup
  - Token exchange flow
  - Session management (local storage for Phase 1)
  
- [ ] In-memory job store (3h)
  - Job object structure
  - Create, read, list operations
  - Status tracking
  
- [ ] Error handling + logging (2h)
  - Express error middleware
  - Request logging (console for Phase 1)
  - Input validation helpers

**Validation**:
- ✅ `npm run build` succeeds, no TypeScript errors
- ✅ `npm run dev` starts server on port 3001
- ✅ `curl http://localhost:3001/api/health` returns 200
- ✅ Endpoint responses match spec (request/response types)

---

### Week 2-3: Phase 1 (Web App Local - Frontend)
**Effort**: 20-25 hours  
**Owner**: Frontend Developer  
**Parallel**: Backend development above

**Subtasks** (Frontend):
- [ ] Scaffold React + Vite project (2h)
  - Initialize `webapp/frontend/` directory
  - Configure `vite.config.ts`, `tsconfig.json`
  - Setup Tailwind CSS
  
- [ ] Landing page with GitHub Sign-In (4h)
  - Hero section with CTA
  - GitHub OAuth button (redirects to GitHub authorize)
  - Callback handler for OAuth code
  - Session token storage (localStorage)
  
- [ ] 4-Step Wizard (10h)
  - Step 1: Organization config (name, prefix, region)
  - Step 2: Azure config (subscription, tenant, resource group)
  - Step 3: Review & Confirm (summary of choices)
  - Step 4: Status & Progress (job polling, real-time updates)
  - Form validation per step
  - Navigation between steps
  
- [ ] Job Status Component (3h)
  - Polling `/api/jobs/:id` every 5 seconds
  - Progress bar
  - Status messages
  - Completion/error screens
  
- [ ] Error handling + styling (2h)
  - Error page with retry
  - Success page with next steps
  - Responsive design (mobile-first)
  - Tailwind utility classes

**Validation**:
- ✅ `npm run dev` starts dev server on port 3000
- ✅ Vite proxy redirects `/api/*` to backend (port 3001)
- ✅ Landing page loads, "Sign in with GitHub" button visible
- ✅ OAuth flow works end-to-end (redirect to GitHub, callback)
- ✅ Wizard renders all 4 steps
- ✅ Form validation prevents empty submissions
- ✅ Job polling updates progress in real-time

---

### Week 3: Phase 1 (Docker & Local Testing)
**Effort**: 10-15 hours  
**Owner**: DevOps + Backend Developer  
**Prerequisites**: Backend + Frontend from weeks 2-3 complete

**Subtasks**:
- [ ] Write multi-stage Dockerfile (3h)
  - Stage 1: Build frontend (Vite)
  - Stage 2: Build backend (TypeScript)
  - Stage 3: Runtime Node.js Alpine, non-root user
  - Target <300MB image size
  
- [ ] Docker Compose setup (2h)
  - Single `webapp` service
  - Port 8080 mapped to container 8080
  - Environment variables: GITHUB_CLIENT_ID, GITHUB_CLIENT_SECRET, SESSION_SECRET
  - Healthcheck on `/api/health`
  - Volume mounts for local dev (optional hot-reload)
  
- [ ] `.env.example` + documentation (1h)
  - Instructions for GitHub OAuth app creation
  - Callback URL: `http://localhost:8080/api/auth/github/callback`
  - Session secret generation guidance
  
- [ ] Build multi-arch image (2h)
  - Use `buildx` for linux/amd64 + linux/arm64
  - Tag with `:latest` + `:local-dev`
  - Verify size <300MB
  
- [ ] End-to-end local testing (5h)
  - `docker compose up --build` succeeds
  - Navigate to `localhost:8080` in browser
  - GitHub OAuth flow works
  - Complete full wizard
  - Create real test repo in GitHub account
  - Job status polls successfully
  - Cleanup: delete test repo
  - Test on both amd64 + arm64 (if available)
  
- [ ] Documentation (2h)
  - `webapp/README.md` with getting started
  - Build instructions
  - Environment setup
  - Known issues & troubleshooting

**DECISION GATE: Phase 1 Complete?**

**Go/No-Go Criteria**:
- ✅ Image <300MB
- ✅ Multi-arch builds succeed (amd64 + arm64)
- ✅ Healthcheck defined and working
- ✅ Non-root user enforced
- ✅ Full local flow works (OAuth → Wizard → Status)
- ✅ GitHub integration creates real repo
- ✅ Documentation complete

**If Go**: Proceed to Phase 2 (Week 4)  
**If No-Go**: Fix blockers (likely image size, Docker issues, or OAuth flow)

---

### Week 4: Phase 2 (Bicep Infrastructure)
**Effort**: 30-40 hours  
**Owner**: Infrastructure Engineer  
**Prerequisites**: Phase 1 complete, Phase 0 audit complete

**Subtasks**:
- [ ] Create Bicep module structure (4h)
  - `webapp/infrastructure/` directory
  - `containerRegistry.bicep` (ACR with geo-replication)
  - `logAnalytics.bicep` (Log Analytics workspace)
  - `containerAppsEnv.bicep` (Container Apps environment)
  - `containerApp.bicep` (The app itself)
  - `keyVault.bicep` (Secrets storage)
  - `appInsights.bicep` (Application Insights)
  - `main.bicep` (Orchestration)
  - `parameters.bicepparam` (Environment values)
  
- [ ] Bicep modules per Microsoft Learn standards (20h)
  - Follow camelCasing convention
  - Implement @description() decorators
  - Output discrete attributes only (no full resources)
  - Use @secure() for sensitive outputs
  - Conditional resources with count
  - No hardcoded values
  
- [ ] Azure Resource Manager validation (3h)
  - `az bicep build webapp/infrastructure/main.bicep`
  - Validate parameter files
  - Check for syntax errors
  
- [ ] GitHub Actions deploy workflow (5h)
  - `.github/workflows/webapp-deploy.yml`
  - Trigger on push to `main` affecting `webapp/**`
  - OIDC auth to Azure (reuse existing TFC setup)
  - Build multi-arch image
  - Push to ACR
  - Update Container App revision
  - Smoke test: `curl /api/health`
  
- [ ] Identity & RBAC setup (2h)
  - System-assigned MI on Container App
  - AcrPull role on Container Registry
  - Key Vault Secrets User role
  
- [ ] Application Insights integration (2h)
  - SDK in Node.js backend
  - Custom events (bootstrap.started, etc.)
  - Workbook dashboard
  
- [ ] Persistent job store (2h)
  - Migrate from in-memory to Azure Table Storage
  - Service interface stays same (no app code changes)
  - Connection string from Key Vault

**Validation**:
- ✅ `az deployment group what-if` shows clean diff
- ✅ Container revision Healthy in Azure Portal
- ✅ `https://<fqdn>/api/health` returns 200
- ✅ Full wizard works end-to-end against Azure
- ✅ Auto-scale to zero verified after idle
- ✅ Cost estimate ~$5-15/mo

**DECISION GATE: Phase 2 Complete?**

**Go/No-Go Criteria**:
- ✅ Bicep modules follow Microsoft Learn standards
- ✅ Deployment succeeds (no errors)
- ✅ Container Apps environment healthy
- ✅ GitHub Actions workflow passes
- ✅ Full wizard flow works end-to-end
- ✅ Table Storage persists job data
- ✅ Cost within budget

---

### Week 5: Phase 3 (Production Hardening)
**Effort**: 20-25 hours  
**Owner**: Infrastructure + Security Engineers

**Subtasks**:
- [ ] Custom domain + TLS (4h)
  - Register domain (or use existing)
  - Managed TLS certificate
  - DNS records configured
  - OAuth callback URL updated
  
- [ ] Branding (4h)
  - Logo upload (HCW or customer)
  - Favicon
  - Color palette (Tailwind config)
  - Marketing landing page
  
- [ ] Security hardening (6h)
  - Persistent sessions (signed cookies)
  - CSRF protection on POST endpoints
  - Rate limiting (5/hour per user, return 429)
  - Security headers (CSP, HSTS, X-Frame-Options)
  
- [ ] Legal pages (2h)
  - Terms of Service
  - Privacy Policy
  - Support page
  
- [ ] Monitoring setup (2h)
  - Uptime monitoring (Azure Monitor)
  - Alert on errors/downtime
  
- [ ] Load testing (3h)
  - k6 or Azure Load Testing
  - 100+ concurrent users
  - Verify auto-scale behavior
  - Check cost during load test
  
- [ ] Launch documentation (2h)
  - Runbook for on-call
  - Release notes
  - Known issues & workarounds

**DECISION GATE: Ready for Production?**

**Go/No-Go Criteria**:
- ✅ Custom domain working with valid TLS cert
- ✅ Lighthouse score ≥90 on landing page
- ✅ Rate limit returns 429 above threshold
- ✅ Security headers present
- ✅ Privacy policy linked from every page
- ✅ Load test shows auto-scale working
- ✅ Runbook documented

---

### Week 6: Phase 4 (Toolkit Consolidation)
**Effort**: 20-25 hours  
**Owner**: Infrastructure + Documentation

**Subtasks**:
- [ ] Feature parity audit (6h)
  - Compare PowerShell script vs webapp
  - Document differences
  - Close gaps (add to webapp or PowerShell as needed)
  
- [ ] Terraform module documentation (8h)
  - Add `.terraform-docs.yml` to each module
  - Generate READMEs for all modules
  - Document variable table + outputs
  - Add usage examples
  - Add cost estimates
  
- [ ] PowerShell script hardening (4h)
  - Input validation
  - Error handling (try/catch)
  - Logging setup
  - Code analysis (Invoke-ScriptAnalyzer)
  
- [ ] Day-2 operations docs review (2h)
  - Update broken links
  - Verify procedures match current toolkit
  - Add missing runbooks
  
- [ ] Bootstrap progress tracker (2h)
  - Decision: Keep or retire?
  - If retiring: Archive
  - If moving: Integrate into webapp UI

---

### Week 6: Phase 5 (Security Hardening) — Part 1
**Effort**: 20-25 hours (over week 6)  
**Owner**: Security Engineer

**Group A: Validation (20h)**
- [ ] Service Principal RBAC validation (3h)
- [ ] Terraform state storage security (2h)
- [ ] PowerShell cleanup hardening (4h)
- [ ] Defender baseline module (2h)
- [ ] GitHub secret scanning (2h)
- [ ] TLS 1.2 enforcement (2h)
- [ ] Firewall threat intelligence (2h)
- [ ] NSG flow logs + Traffic Analytics (3h)

---

### Week 7+: Phase 5 (Security Hardening) — Part 2
**Effort**: 25-30 hours (ongoing)  
**Owner**: Security + Infrastructure

**Group B: New Implementations (20h)**
- [ ] CMK module (optional, 8h)
- [ ] Sentinel SIEM module (optional, 8h)
- [ ] Security alerting (4h)

**Group C: Webapp Security (10h)**
- [ ] Container image vulnerability scanning (3h)
- [ ] Bicep infrastructure review (2h)
- [ ] Key Vault security (2h)
- [ ] Container Apps CORS lockdown (1h)
- [ ] Application Insights PII scrubbing (2h)

**FINAL DECISION GATE: Launch Approved?**

**Go/No-Go Criteria**:
- ✅ All security validations passed
- ✅ Compliance scan (`azqr`) clean or accepted-risk only
- ✅ Container image: 0 HIGH/CRITICAL CVEs (Trivy)
- ✅ Azure Secure Score >80/100
- ✅ All compliance metrics in README current

---

## Resource Allocation

### Recommended Team Structure

| Role | Hours | Phase | Notes |
|---|---|---|---|
| **Platform Engineer (Lead)** | 30-40h | 0, 1, 4, 5 | Phase 0 audit, Phase 1 docker, Phase 4 consolidation, Phase 5 validation |
| **Backend Developer** | 25-30h | 1, 2 | Express API, job store, OAuth integration |
| **Frontend Developer** | 25-30h | 1, 3 | React wizard, UI/UX, branding |
| **Infrastructure Engineer** | 40-50h | 2, 4, 5 | Bicep modules, GitHub Actions, Terraform hardening |
| **Security Engineer** | 30-40h | 5 | Security review, compliance, hardening |
| **DevOps / Automation** | 10-15h | 2, 3 | Docker multi-arch, CI/CD setup, load testing |

**Total**: 160-190 hours (aligns with TODO estimate of 155-195h)

---

## Decision Gates & Escalation

### Gate 1: Phase 0 Complete (End of Week 1)
**Question**: Is our audit accurate and complete?

**Approval**: Platform Team + Stakeholder Sign-Off

**If No-Go**:
- Audit more items or re-verify claims
- Delay Phase 1 start by 3-5 days
- Notify team of blockers

---

### Gate 2: Phase 1 Complete (End of Week 3)
**Question**: Is the local docker build working end-to-end?

**Validation Checklist**:
- [ ] Image <300MB
- [ ] Multi-arch (amd64 + arm64) builds
- [ ] OAuth flow works
- [ ] Wizard creates real repo
- [ ] Status polling works
- [ ] Documentation complete

**If No-Go**:
- Fix identified issues (usually Docker size or OAuth)
- Extend Phase 1 by 3-5 days
- Do not proceed to Phase 2 until working

---

### Gate 3: Phase 2 Complete (End of Week 4)
**Question**: Is the Azure deployment working end-to-end?

**Validation Checklist**:
- [ ] Bicep modules deploy without error
- [ ] Container Apps environment healthy
- [ ] GitHub Actions workflow passes
- [ ] Full wizard flow works against Azure
- [ ] Auto-scale behavior verified
- [ ] Cost within budget estimate

**If No-Go**:
- Debug Bicep/ARM errors
- Fix RBAC or identity issues
- Extend Phase 2 by 3-5 days
- Do not proceed to Phase 3 until working

---

### Gate 4: Phase 3 Complete (End of Week 5)
**Question**: Is the app production-ready?

**Validation Checklist**:
- [ ] Custom domain + TLS working
- [ ] Security headers present
- [ ] Rate limiting enforced
- [ ] Load test results acceptable
- [ ] Runbook documented

**If No-Go**:
- Address security findings
- Fix load test failures
- Extend Phase 3 by 3-5 days
- Schedule security review before launch

---

### Final Gate: Phase 5 Complete (End of Week 7)
**Question**: Is everything secure and compliant?

**Validation Checklist**:
- [ ] All Group A validations passed
- [ ] Compliance scan clean (no CRITICAL)
- [ ] Container image: 0 HIGH/CRITICAL CVEs
- [ ] Azure Secure Score >80
- [ ] Security review approved

**If No-Go**:
- Address critical findings before launch
- Schedule risk acceptance meeting if needed
- Extend security hardening by 1-2 weeks

---

## Timeline Summary

| Phase | Week | Status | Deliverable | Owner |
|-------|------|--------|-------------|-------|
| **0** | 1 | Audit | Audit table, updated TODO | Platform |
| **1** | 2-3 | Build | Docker image <300MB | Backend + Frontend + DevOps |
| **2** | 4 | Deploy | Bicep modules, GitHub Actions | Infrastructure |
| **3** | 5 | Harden | Domain, TLS, security headers | Infrastructure + Security |
| **4** | 6 | Consolidate | Module docs, feature parity | Infrastructure + Platform |
| **5** | 6-7 | Validate | Security review, compliance | Security |
| **LAUNCH** | 7+ | 🚀 | Production release | All |

---

## Risk Mitigation

### High-Risk Areas

| Risk | Mitigation | Owner |
|------|-----------|-------|
| **Docker image oversized** | Build early, iterate on size (aim <250MB for buffer) | DevOps |
| **OAuth flow complexity** | Spike GitHub OAuth in week 2, test with real GitHub App | Backend |
| **Bicep syntax errors** | Use VS Code Bicep extension, validate early and often | Infrastructure |
| **RBAC misconfiguration** | Document all role assignments, test with minimal permissions | Infrastructure |
| **Load test failures** | Run smoke test load in week 5, iterate scaling config | DevOps |
| **Security findings late** | Shift-left: security review at Gate 3 (Phase 3), not Phase 5 | Security |

### Contingency Plans

**If Phase runs 2+ weeks over**:
- Reduce Phase 3 (domain + branding) to MVP (core TLS only)
- Defer Phase 4 (toolkit consolidation) to post-launch
- Focus Phase 5 on critical security items only

**If major blocker in Phase 2 (Bicep)**:
- Option A: Use Azure Resource Manager JSON templates instead of Bicep
- Option B: Reduce scope (remove Table Storage, use in-memory longer)
- Option C: Skip Bicep entirely, use Azure CLI script for deployment

---

## Success Metrics

At end of each phase:

**Phase 0**: ✅ Audit complete, 100% TODO items verified, team aligned on standards  
**Phase 1**: ✅ Docker image <300MB, multi-arch, OAuth works, wizard complete  
**Phase 2**: ✅ Azure deploy succeeds, Container Apps healthy, full flow end-to-end  
**Phase 3**: ✅ Custom domain, TLS valid, security headers, load test passed  
**Phase 4**: ✅ All modules documented, feature parity achieved  
**Phase 5**: ✅ Security review approved, compliance scan clean, 0 HIGH/CRITICAL CVEs  
**LAUNCH**: ✅ Platform live, users can deploy landing zones via web UI

---

## Next Immediate Actions

**This Week (by 2026-07-06)**:

1. ✅ **Review BUILD_VERIFICATION_REPORT.md** (this document)
2. ✅ **Assign team roles** (Backend, Frontend, Infrastructure, Security)
3. ✅ **Create GitHub project board** with Phase 0-5 tasks
4. ✅ **Schedule Phase 0 kickoff** (Monday, Week 1)
5. ✅ **Prepare audit checklist** (use in Phase 0)
6. ✅ **Brief team on standards** (AVM Terraform, Bicep)

**Do NOT start any build work** until Phase 0 audit is signed off.

---

**Document Owner**: Platform Engineering  
**Last Updated**: 2026-06-30  
**Status**: Ready for Phase 0 Kickoff
