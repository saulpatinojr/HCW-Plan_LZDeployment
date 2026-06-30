# Plan: HCW Landing Zone Platform — Unified Roadmap

End-to-end plan covering the existing security/landing-zone TODO **plus** the new web app build. Security work is intentionally **last** so the final pass happens once everything (webapp, infra, modules) is in the repo and can be hardened together. Nothing from the current TODO is dropped — items previously claimed "complete" become **VALIDATE** tasks so we re-confirm them rather than trust the disputed prior status.

---

## Phase ordering (high level)

| Phase | Name | Reason for position |
|---|---|---|
| **0** | Audit & Reconcile | Get docs to ground truth before adding new work |
| **1** | Web App: Container & Local Docker | Pure-local, no Azure spend, fast feedback loop |
| **2** | Web App: Azure Architecture | Deploy proven container to Container Apps |
| **3** | Web App: Personalization & Publishing | Custom domain, branding, launch readiness |
| **4** | Landing Zone Toolkit consolidation | Tighten existing PowerShell + Terraform around the new webapp |
| **5** | Security — Final Hardening Pass | Last, because we want everything in the repo before validating + remediating across the entire surface |

---

## Phase 0: Audit & Reconcile Docs (no code, one commit)

The current `TODO.md` and `README.md` disagree:
- README: "Phase 1 ✅ COMPLETE", "Phase 2 Core ✅ COMPLETE", 28 controls live
- TODO Progress Tracker: 0/36 tasks, status "🟡 Not Started"

We re-establish ground truth before adding the webapp section.

### Steps

1. **Run Explore subagent (thorough)** — verify every existing TODO claim against the repo. Output table: `task_id | TODO checkbox | README claim | actual evidence (file:line / commit) | proposed status`. Status options: ✅ Confirmed Done, 🔁 VALIDATE (looks done but needs a re-check pass in Phase 5), ⚠️ Partial, ❌ Not Done, 🟦 Optional-Deferred
2. **Batch review** the table with user — single approval pass, not per-item
3. **Rewrite `TODO.md`**:
   - Update every checkbox to audit reality
   - For items previously claimed done: **mark as `🔁 VALIDATE` and keep the task** (not `[x]`). The final Phase 5 pass re-verifies and only then marks complete with `Completed: <date>` + commit SHA
   - Fix Progress Tracking numbers
   - Bump Last Updated to today (2026-05-29)
   - Renumber: existing Bootstrap = "Phase 0 (Security Bootstrap)" stays as-is for back-compat
   - Add new top-level sections in order: **Phase 5W (Web App Build)**, **Phase 6 (Toolkit Consolidation)**, **Phase 7 (Security Final Pass)** — short pointers, not full duplication
4. **Rewrite `README.md`** — claims match audited TODO; add Bootstrap **Option 3: Web App (in development)**; add `webapp/` to repo diagram with "(in development)" tag
5. **Create `docs/webapp/PLAN.md`** — the full detailed webapp build plan (Phases 1–3 from this doc) lives here so TODO stays scannable
6. **Single commit**: `docs: reconcile TODO/README to ground truth + add webapp/toolkit/security phases`

### Verification
- Every TODO checkbox defended by file evidence OR honestly open
- Progress Tracking numbers match counted checkboxes
- No claim in README absent from TODO and vice versa
- `git diff` touches only `TODO.md`, `README.md`, `docs/webapp/PLAN.md`

---

## Phase 1: Web App — Container & Local Docker Testing

Build the webapp under `webapp/`, ship it in a multi-stage Docker container, prove the entire flow end-to-end on your desktop. No Azure resources yet.

### Steps

1. **Scaffold** `webapp/{frontend,backend,docker}/` + `docker-compose.yml` + `.dockerignore` + `webapp/README.md`
2. **Backend** (Node.js + TypeScript + Express) — *parallel with step 3*
   - REST endpoints: `GET /api/health`, `POST /api/bootstrap`, `GET /api/jobs/:id`, `GET /api/auth/github/callback`
   - In-memory job store (Phase 1 only)
   - GitHub OAuth via Octokit
   - Bootstrap service: TypeScript port of `Initialize-LandingZone.ps1` logic (PS scripts remain as CLI fallback)
   - Azure setup stub returns mock OIDC config in Phase 1
3. **Frontend** (React + Vite + TypeScript + Tailwind) — *parallel with step 2*
   - Landing page → "Sign in with GitHub"
   - 4-step wizard: Org Config → Azure Config → Review → Status
   - Job polling with progress UI
4. **Multi-stage Dockerfile** — *depends on 2 & 3*
   - Stage 1: build frontend → static assets
   - Stage 2: build backend → JS
   - Stage 3: Node.js Alpine runtime, non-root, serves frontend as static via Express, port 8080
   - Target: <300MB final, multi-arch (linux/amd64 + linux/arm64)
5. **docker-compose.yml** for local dev — *depends on 4*
   - Single `webapp` service on localhost:8080
   - `.env` for `GITHUB_CLIENT_ID`, `GITHUB_CLIENT_SECRET`, `SESSION_SECRET`
   - Healthcheck on `/api/health`
6. **One-time GitHub OAuth App setup** (manual): callback `http://localhost:8080/api/auth/github/callback`
7. **Full local end-to-end test**: `docker compose up --build` → sign in → run wizard → create real test repo in your GitHub account → cleanup

### Verification
- `/api/health` returns 200
- Wizard creates real test repo
- Final image <300MB, non-root, healthcheck defined, builds on amd64 + arm64

---

## Phase 2: Web App — Azure Architecture & Deployment

Deploy the proven container to Azure Container Apps with supporting infra.

### Steps

1. **Bicep IaC** under `webapp/infrastructure/`:
   - `main.bicep` — top-level orchestration
   - Modules: `containerRegistry.bicep`, `logAnalytics.bicep`, `containerAppsEnv.bicep`, `containerApp.bicep` (system-assigned MI, 0.5 vCPU/1Gi, scale 0→3), `keyVault.bicep`, `appInsights.bicep`
   - `parameters.bicepparam`
2. **Identity & RBAC** — *depends on 1*
   - System-assigned MI on Container App
   - `AcrPull` on ACR, `Key Vault Secrets User` on Key Vault
   - Secrets via `secretRef` syntax (never plaintext env vars)
3. **GitHub Actions deploy workflow** `.github/workflows/webapp-deploy.yml` — *parallel with 1*
   - Trigger: push to `main` affecting `webapp/**`
   - OIDC auth to Azure (reuse existing repo OIDC setup)
   - Build, push to ACR (`:sha` + `:latest`), update Container App, smoke-test `/api/health`
4. **Production OAuth callback**: add prod URL to existing GitHub OAuth app (keep localhost too)
5. **Persistent job store**: swap in-memory → Azure Table Storage (cheapest persistent option; interface unchanged)
6. **Observability**: App Insights SDK + custom events (`bootstrap.started/repo_created/oidc_configured/completed/failed`) + Workbook dashboard

### Verification
- `az deployment group what-if` clean
- Container revision Healthy in portal
- `https://<fqdn>/api/health` 200
- Full wizard works against prod URL
- Scale-to-zero verified after idle
- Cost ~$5–15/mo with Basic ACR + scale-to-zero

---

## Phase 3: Web App — Personalization & Publishing

Production-grade launch.

### Steps

1. **Custom domain + managed TLS cert**; update OAuth callback to custom domain
2. **Branding** — *parallel with 1* — logo, favicon, palette, marketing landing page
3. **Hardening**:
   - Persistent sessions (Redis or signed cookies, not in-memory)
   - CSRF protection
   - Rate limit `/api/bootstrap` (5/hr per user)
   - Optional org allowlist
4. **Legal pages**: Terms, Privacy, Support
5. **Analytics + uptime monitoring + alerts**
6. **Optional multi-region** via Azure Front Door (skip unless required)
7. **Launch checklist**: security review, load test (k6 or Azure Load Testing), runbook, public README update

### Verification
- Custom domain + valid TLS
- Lighthouse ≥90 on landing page
- Rate limit returns 429 above threshold
- Security headers (CSP, HSTS, X-Frame-Options) present
- Privacy policy linked from every page

---

## Phase 4: Landing Zone Toolkit Consolidation

Once the webapp ships, tighten the existing PowerShell + Terraform toolkit so it stays in lockstep. Pulled from current TODO sections that aren't strictly "security".

### Steps

1. **PS / TS feature parity audit** — every step `Initialize-LandingZone.ps1` does must also exist in the webapp bootstrap service. Build a checklist; close gaps in whichever direction is missing
2. **Terraform module documentation completeness** — every module under `terraform/modules/` has a README, examples, and required-vs-optional variable table
3. **Cleanup-ExpiredSandboxResources.ps1 hardening** (Task 1.3 in current TODO) — keep all subtasks; mark Phase 5 VALIDATE
4. **Day-2 ops docs review** — `docs/day2/` files current with toolkit + webapp reality
5. **Bootstrap progress tracker** — fold paper-based tracker into webapp UI or retire it

### Verification
- All toolkit + webapp doc cross-links resolve
- `terraform fmt -check` and `terraform validate` clean on all modules
- PS `Invoke-ScriptAnalyzer` clean

---

## Phase 5: Security — Final Hardening Pass (LAST)

Done last so everything that exists in the repo (webapp container, Bicep infra, PS scripts, TF modules) is hardened together in one coherent pass. Pulls in **every** item from the existing TODO Phases 1–4 plus new webapp-specific security checks. Items previously claimed "complete" are revalidated, not blindly trusted.

### Group A: VALIDATE previously claimed-complete items
Re-verify each, then either mark complete with date + commit, or reopen.

- **🔁 Task 1.1** — Service Principal RBAC validation in CI/CD (CVSS 9.1)
- **🔁 Task 1.2** — Terraform state storage secured: `public_network_access_enabled = false`, private endpoint, lifecycle precondition warning (CVSS 8.2)
- **🔁 Task 1.3** — PowerShell input validation in `Cleanup-ExpiredSandboxResources.ps1`: GUID validation, sub existence check, sandbox tag check, dry-run requirement, RG prefix validation, max-deletion limit, Log Analytics audit (CVSS 7.5)
- **🔁 Task 5.5** — Defender baseline **module exists** (`terraform/modules/defender-baseline/`), deployment remains 🟦 deferred
- **🔁 Task SEC-1** — GitHub secret scanning: `secrets-scan.yml` workflow + Dependabot config + TruffleHog
- **🔁 Task 5.1** — GitHub Actions pinned to commit SHAs in `terraform-plan.yml` and `terraform-apply.yml`
- **🔁 Task 2.2** — TLS 1.2 enforcement policy in `terraform/modules/policy-baseline/policy-tls-minimum.tf` (storage, MySQL, PostgreSQL, App Service, Functions, APIM) at root MG, Deny mode
- **🔁 Task 5.3** — Azure Firewall threat intel in `terraform/modules/hub-network/firewall-threat-intel.tf`: Alert mode, DNS proxy, IDPS (Premium), diagnostic logs
- **🔁 Task 5.2** — NSG flow logs + Traffic Analytics in `terraform/modules/nsg-flow-logs/`: 90-day retention, alerts, dashboards

### Group B: Open items from current TODO Phases 2–4 (IMPLEMENT)

**Phase 2 (optional modules — create but keep deferred unless user opts in)**
- Task 2.1 — Customer-Managed Keys module `terraform/modules/keyvault-cmk/` (currently empty per audit) — create `main.tf, variables.tf, outputs.tf, README.md` with deployment guide. Cost $250/mo when enabled
- Task 9.2 — Sentinel SIEM module `terraform/modules/sentinel-siem/` (currently empty per audit) — create full module + data connectors + analytics rules + workbook templates. Cost $300/mo when enabled

**Phase 3 (Medium — implement)**
- Task 9.3 — Security alerting (action group, activity log alerts for policy/role/deletion/NSG/firewall/MG changes, metric alerts) — 8h, $0
- Task AB-3 — Resource locks (CanNotDelete on hub VNet, firewall, LA workspace, Key Vault, RSV; ReadOnly on state storage) — 4h, $0
- Task 9.1 — Comprehensive diagnostic logging across all modules — 6h, $100/mo
- Task AB-2 — Backup testing automation: `terraform/scripts/Test-BackupRecovery.ps1` + `docs/day2/backup-recovery-procedures.md` — 12h, $0
- Task AB-1 — Private endpoints for LA workspace, RSV, Automation Account, Key Vault — 10h, $120/mo
- Task 2.3 — VM disk encryption policy + new `terraform/modules/compute-vm/` — 4h, $0
- Finding 3.1 — Enhanced PowerShell error handling (4h)
- Finding AB-4 — Policy remediation tasks (6h)
- Finding CIS-2 — Guest user review automation (4h)
- Finding CIS-5 — Subscription activity log export (2h)

**Phase 4 (Low — ongoing)**
- WCAG-4 — Text alternatives for Mermaid diagrams (2h)
- WCAG-3 — Improve link text descriptions (1h)
- WCAG-2 — Language identifiers on code blocks (1h)
- W3C-1 — markdownlint + fixes (2h)
- SEC-2 — Immutable infrastructure tags (4h)
- SEC-3 — Break-glass account docs (4h)
- SEC-4 — Tagging consistency improvements (4h)
- SEC-5 — State encryption validation script (2h)
- Finding 8.1 — State lock verification (2h)
- Finding 8.2 — Terraform plan integrity checks (2h)
- Finding CIS-1 — MFA enforcement documentation (4h)
- Finding CIS-6 — Network Watcher explicit creation (2h)
- Integration test suite for deployments (8h)
- Automated compliance scanning (4h)
- DR drill procedures (4h)

### Group C: Webapp-specific security items (NEW)
- Webapp container image vulnerability scan in CI (Trivy or Defender for Containers)
- Webapp Bicep `what-if` + RBAC review pass per `azure-validate` skill
- Webapp Key Vault: secrets rotation policy + access review
- Webapp Container Apps: ingress restricted (private if applicable), CORS locked down
- Webapp rate-limit + CSRF + session security validated (cross-link Phase 3 hardening)
- Webapp OAuth app: minimum scopes audit
- Webapp App Insights: PII scrubbing rules
- Run `azqr` (azure-compliance skill) against deployed webapp + landing zone resources together

### Verification (Phase 5 — gates)
- Every TODO security task marked done has `Completed: <date>` + commit SHA
- Progress Tracking shows real numbers, not aspirational
- `azqr` report clean (no CRITICAL, HIGH only on accepted-risk items)
- `trivy image` on webapp container: 0 HIGH/CRITICAL CVEs
- Compliance metrics in README match a real Azure Secure Score export

---

## Decisions

- **VALIDATE-not-trust default**: anything previously claimed complete without a verifiable commit becomes 🔁 VALIDATE — re-verified in Phase 5 before being marked done
- **Webapp plan detail lives in `docs/webapp/PLAN.md`**, TODO carries short pointer entries — keeps TODO scannable
- **Security goes last**: lets one cohesive hardening pass cover webapp + infra + scripts together, avoiding "harden the toolkit now, redo it after webapp lands"
- **Optional modules (Defender, CMK, Sentinel) stay 🟦 deferred** — Phase 5 ensures the *module code* exists and is documented; deployment remains explicit opt-in
- **Existing security Phase 0 (GitHub+Azure bootstrap) in TODO is unchanged** — that's the customer-facing setup, distinct from this audit

## Further Considerations

1. **Where does `Initialize-LandingZone.ps1` live long-term?** Two options: (A) keep as CLI fallback indefinitely, (B) deprecate once webapp ships. Recommend A — power users + air-gapped scenarios benefit from CLI
2. **Should Phase 5 run as one mega-PR or split per group?** Recommend split: one PR per group (A validate, B open, C webapp-specific) so reviews stay tractable
3. **Naming the platform** — still open; defer to Phase 3 branding work
