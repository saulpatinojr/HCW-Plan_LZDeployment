# HCW Landing Zone — Deployment Flow Architecture

**Purpose**: Map the complete flow from user selection to deployed landing zone.

**Current Status**: 65% implemented (frontend UI + GitHub workflow exist, backend missing)

---

## End-to-End Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         USER INTERACTION FLOW                               │
└─────────────────────────────────────────────────────────────────────────────┘

1. USER OPENS BROWSER
   └─> frontend/index.html (✅ BUILT)
       ├─> MSAL Login (✅ CONFIGURED)
       │   └─> User authenticates with Azure AD
       └─> Form appears (✅ BUILT)

2. USER FILLS FORM (✅ HTML/CSS BUILT, ⚠️ JS LOGIC PARTIAL)
   ├─> Organization Prefix: "contoso" (3-8 lowercase)
   ├─> Modules: Hub Network ✓, Spoke Networks ✓, Policy ✓, Backup ✗, Defender ✗
   ├─> Compliance: "pci-dss"
   ├─> Primary Region: "eastus"
   ├─> Secondary Region: "westus"
   └─> Real-time Cost: $2,160/month displayed

3. USER CLICKS "DEPLOY TO AZURE" (❌ NOT WIRED)
   └─> frontend/app.js sends POST /api/bootstrap (❌ BACKEND MISSING)
       {
         orgPrefix: "contoso",
         modules: ["hub-network", "spoke-network", "policy-baseline"],
         compliance: "pci-dss",
         primaryRegion: "eastus",
         secondaryRegion: "westus"
       }

4. BACKEND PROCESSES REQUEST (❌ NOT BUILT)
   └─> Node.js Express server receives POST
       ├─> Validates inputs (✅ LOGIC EXISTS IN FORM)
       ├─> Generates terraform.tfvars (❌ GENERATOR MISSING)
       │   Contains:
       │   - org_prefix = "contoso"
       │   - deploy_hub_network = true
       │   - deploy_spoke_networks = true
       │   - deploy_policy_baseline = true
       │   - deploy_backup_baseline = false
       │   - deploy_defender_baseline = false
       │   - compliance_variant = "pci-dss"
       │   - primary_region = "eastus"
       │   - secondary_region = "westus"
       │   - [plus computed values based on compliance]
       │
       ├─> Creates GitHub Release (❌ GITHUB WRAPPER MISSING)
       │   Tag: deployment-{timestamp}
       │   Body: terraform.tfvars contents
       │
       ├─> Triggers GitHub Actions workflow (❌ DISPATCH MISSING)
       │   Workflow: generate-and-release.yml (✅ EXISTS)
       │   Inputs: org_prefix, modules, compliance_variant, regions
       │   ref: main
       │
       └─> Returns job ID to frontend
           {
             jobId: "gh-run-1234567890",
             status: "queued",
             message: "Deployment started"
           }

5. FRONTEND SHOWS STATUS PAGE (❌ UI MISSING)
   └─> Polls GET /api/jobs/{jobId} every 5 seconds (❌ ENDPOINT MISSING)
       └─> Displays progress:
           ✅ Repository configured
           ✅ OIDC federation set up
           ⏳ Creating hub network...
           ⭕ Configuring spoke networks (pending)
           ⭕ Applying compliance policies (pending)

6. GITHUB ACTIONS WORKFLOW RUNS (✅ WORKFLOW BUILT)
   └─> generate-and-release.yml (✅ EXISTS, ready to run)
       ├─> Checkout repo
       ├─> Validate inputs (✅ IMPLEMENTED)
       ├─> Generate terraform.tfvars (❓ UNCLEAR IF IMPLEMENTED)
       ├─> Create/Update release (✅ OR USES TERRAFORM CLOUD)
       ├─> Trigger Terraform deployment
       │   └─> Via TFC or: terraform init, plan, apply
       └─> Store artifacts (release assets)

7. TERRAFORM DEPLOYS (✅ TERRAFORM CODE EXISTS)
   └─> terraform/modules/* (✅ BUILT)
       ├─> hub-network (✅)
       ├─> spoke-network (✅)
       ├─> policy-baseline (✅)
       ├─> management-groups (✅)
       └─> [others as selected]
   
   Creates in Azure:
   ├─> Resource Groups
   ├─> Virtual Networks
   ├─> Azure Firewall
   ├─> VPN/ExpressRoute Gateway
   ├─> Peering
   ├─> Azure Policies
   └─> Management Groups

8. BACKEND TRACKS STATUS (❌ JOB STORE MISSING)
   └─> Polls GitHub Actions API for workflow_run status
       Returns: { status: "in_progress", progress: 45%, ... }

9. FRONTEND UPDATES IN REAL-TIME (❌ STATUS DISPLAY MISSING)
   └─> Progress bar moves from 0% → 100%
   └─> Steps change from pending to in_progress to completed

10. DEPLOYMENT COMPLETES (✅ TERRAFORM COMPLETE)
    └─> GitHub release published with artifacts:
        ├─> terraform.tfvars.json
        ├─> deployment-manifest.json
        ├─> terraform-state-summary.json
        └─> [logs]

11. FRONTEND SHOWS SUCCESS (❌ SUCCESS PAGE LOGIC MISSING)
    └─> "✅ Deployment Complete!"
    └─> Links to:
        ├─> Azure Portal (resource groups)
        ├─> GitHub Release (download .tfvars)
        ├─> Terraform output (FQDN, passwords, etc.)
        └─> Next Steps (configure DNS, onboard workloads, etc.)

12. USER CAN DOWNLOAD CONFIGURATION (⚠️ PARTIALLY BUILT)
    └─> GitHub Release provides:
        ├─> terraform.tfvars (full configuration)
        ├─> terraform-state backup (if needed for disaster recovery)
        └─> Deployment logs

└─> END (User now has deployed landing zone!)
```

---

## Component Checklist: What Exists Where

### Frontend (Static HTML + JavaScript)
| Component | File | Status | Notes |
|-----------|------|--------|-------|
| **Header** | index.html | ✅ | Login button, user display |
| **Login Form** | index.html | ✅ | MSAL configured, connects to Azure AD |
| **Deployment Form** | index.html | ✅ | All fields defined, validation rules in place |
| **Module Selector** | index.html | ✅ | Checkboxes (hub, spoke, policy, backup, defender) |
| **Compliance Dropdown** | index.html | ✅ | Options: baseline, pci-dss, hipaa, fedramp |
| **Region Selectors** | index.html | ✅ | Primary + secondary region inputs |
| **Cost Estimator** | index.html | ✅ | Card showing monthly/annual cost |
| **Styling** | styles.css | ✅ | Azure Fluent Design, responsive, complete |
| **MSAL Setup** | app.js | ✅ | Config, token acquisition, account detection |
| **Form State** | app.js | ⚠️ | References exist, but logic incomplete |
| **Cost Calculation** | app.js | ⚠️ | Model defined, not wired to UI |
| **Cost Display Update** | app.js | ❌ | Real-time updates missing |
| **Form Submission** | app.js | ❌ | POST to `/api/bootstrap` not implemented |
| **Status Display** | index.html | ⚠️ | HTML exists (`#statusSection`), JS logic missing |
| **Progress Polling** | app.js | ❌ | GET `/api/jobs/:id` polling not implemented |
| **Success Page** | index.html | ⚠️ | HTML exists, population logic missing |
| **Error Handling** | app.js | ⚠️ | Error elements exist, handlers incomplete |

**Summary**: Frontend is 85% structurally complete, but 40% of JavaScript logic is missing.

---

### Backend (Node.js / Express) — DOES NOT EXIST
| Component | File | Status | Notes |
|-----------|------|--------|-------|
| **Express Server** | backend/src/server.ts | ❌ | Not created |
| **Bootstrap Endpoint** | backend/src/routes/bootstrap.ts | ❌ | Not created |
| **Jobs Endpoint** | backend/src/routes/jobs.ts | ❌ | Not created |
| **Health Endpoint** | backend/src/routes/health.ts | ❌ | Not created |
| **Terraform Generator** | backend/src/services/terraform.ts | ❌ | Not created |
| **GitHub API Wrapper** | backend/src/services/github.ts | ❌ | Not created |
| **Job Store** | backend/src/services/jobs.ts | ❌ | Not created |
| **Input Validation** | backend/src/services/validation.ts | ❌ | Not created |
| **Error Handling** | backend/src/middleware/errors.ts | ❌ | Not created |
| **TypeScript Config** | backend/tsconfig.json | ❌ | Not created |
| **package.json** | backend/package.json | ❌ | Not created |

**Summary**: Backend does not exist. Must be built from scratch.

---

### GitHub Actions Workflow
| Component | File | Status | Notes |
|-----------|------|--------|-------|
| **Workflow Definition** | .github/workflows/generate-and-release.yml | ✅ | Built and ready |
| **Trigger** | workflow_dispatch | ✅ | Can be manually triggered or via API |
| **Input Parameters** | org_prefix, modules, compliance, regions | ✅ | All defined |
| **Input Validation** | Bash regex check | ✅ | org_prefix validation present |
| **Checkout** | actions/checkout | ✅ | Uses SHA-pinned version |
| **Terraform Init** | terraform init | ⚠️ | Likely in workflow, need to verify |
| **Terraform Plan** | terraform plan | ⚠️ | Likely in workflow, need to verify |
| **Terraform Apply** | terraform apply | ⚠️ | Likely in workflow, need to verify |
| **Release Creation** | gh release create | ⚠️ | Likely in workflow, need to verify |
| **Artifact Upload** | actions/upload-artifact | ⚠️ | Likely in workflow, need to verify |

**Summary**: Workflow is 80% built, some steps may be incomplete or missing detail.

---

### Terraform Code
| Component | Location | Status | Notes |
|-----------|----------|--------|-------|
| **Hub Network** | terraform/modules/hub-network/ | ✅ | Azure Firewall, VPN/ER Gateway, Bastion |
| **Spoke Networks** | terraform/modules/spoke-network/ | ✅ | VNets, peering, NSGs |
| **Management Groups** | terraform/modules/management-groups/ | ✅ | Subscription organization |
| **Policy Baseline** | terraform/modules/policy-baseline/ | ✅ | Azure Policies (TLS, encryption, tagging) |
| **Backup Baseline** | terraform/modules/backup-baseline/ | ✅ | Recovery Services Vault, backup policies |
| **Defender Baseline** | terraform/modules/defender-baseline/ | ✅ | Defender for Cloud, security scores |
| **Live Configurations** | terraform/live/*/main.tf | ✅ | Global, platform-connectivity, platform-management, workloads |
| **Backend Bootstrap** | terraform/backend-bootstrap/ | ✅ | Terraform Cloud workspace, state storage setup |

**Summary**: Terraform code is complete and production-ready.

---

## The Missing Pieces (What Blocks Deployment)

### Critical (Blocking Deployment)

1. **Backend API Server** (16-20 hours)
   - Express server on port 3001
   - POST /api/bootstrap endpoint
   - GET /api/jobs/:id endpoint
   - Terraform variable generator
   - GitHub API integration
   - Job store (in-memory or Table Storage)

2. **Form Submission Handler** (4-6 hours)
   - Wire frontend form to POST /api/bootstrap
   - Collect all form inputs
   - Show loading state
   - Handle errors
   - Display success

3. **Job Status Polling** (4-6 hours)
   - Poll GET /api/jobs/:id every 5 seconds
   - Update progress bar
   - Show step-by-step status
   - Handle timeouts

### Important (Needed for Full UX)

4. **Cost Real-Time Updates** (2-3 hours)
   - Update cost display as modules change
   - Update firewall tier based on compliance
   - Show cost breakdown

5. **GitHub Workflow Verification** (2-3 hours)
   - Verify workflow generates .tfvars correctly
   - Test workflow dispatch trigger
   - Verify artifact creation

6. **End-to-End Test** (4-6 hours)
   - Test full flow locally (docker-compose)
   - Test in Azure (if possible)
   - Document test results

### Total Effort: 32-44 hours

---

## How to Build This (Recommended Order)

### Week 1: Foundation (8-10 hours)
- [ ] Build Express backend skeleton
- [ ] Create `/api/bootstrap` endpoint (validate, return job ID)
- [ ] Create `/api/jobs/:id` endpoint (stub, return dummy status)
- [ ] Create `/api/health` endpoint
- [ ] Wire frontend form submission to `/api/bootstrap`

**Deliverable**: Form can submit to backend without crashing

---

### Week 2: Integration (12-16 hours)
- [ ] Build Terraform variable generator (inputs → .tfvars)
- [ ] Integrate GitHub API (dispatch workflow, poll status)
- [ ] Build job store (in-memory)
- [ ] Wire status polling to frontend
- [ ] Add progress display UI

**Deliverable**: Can trigger GitHub Actions workflow and track progress

---

### Week 3: Polish (8-12 hours)
- [ ] Add cost real-time updates
- [ ] Verify GitHub workflow works end-to-end
- [ ] Add error handling + user feedback
- [ ] Test full flow (docker-compose)
- [ ] Document deployment flow

**Deliverable**: Full flow works, ready for production

---

## Success Criteria

✅ **Form Submission**: User clicks "Deploy" → GET job ID → See status page  
✅ **Status Tracking**: Job status updates every 5 seconds from "queued" → "in_progress" → "completed"  
✅ **GitHub Integration**: Workflow is triggered, runs terraform, creates release  
✅ **Artifact Delivery**: User can download .tfvars and deployment logs  
✅ **Error Handling**: Validation errors shown to user, workflow errors logged  
✅ **Cost Accuracy**: Real-time cost display matches actual deployment cost  

---

## Files to Create/Modify

### Create (New Backend)
```
backend/
├── src/
│   ├── server.ts                    (new)
│   ├── routes/
│   │   ├── bootstrap.ts             (new)
│   │   ├── jobs.ts                  (new)
│   │   └── health.ts                (new)
│   ├── services/
│   │   ├── terraform.ts             (new)
│   │   ├── github.ts                (new)
│   │   └── jobs.ts                  (new)
│   ├── types/
│   │   └── index.ts                 (new)
│   └── middleware/
│       └── errors.ts                (new)
├── package.json                     (new)
├── tsconfig.json                    (new)
└── Dockerfile                       (new, for Phase 2)
```

### Modify (Existing Frontend)
```
frontend/
├── index.html                       (add status section — mostly done)
├── app.js                           (add form submission, polling, updates)
└── styles.css                       (complete, no changes needed)
```

### Verify (Existing GitHub Workflow)
```
.github/
└── workflows/
    └── generate-and-release.yml     (check implementation completeness)
```

---

## Summary Table

| Layer | Component | Status | Hours to Complete | Owner |
|-------|-----------|--------|-------------------|-------|
| **Frontend** | HTML Structure | ✅ 95% | 2 | Frontend |
| **Frontend** | CSS Styling | ✅ 100% | 0 | Frontend |
| **Frontend** | Cost Calculator Wiring | ⚠️ 50% | 3 | Frontend |
| **Frontend** | Form Submission | ❌ 0% | 4 | Frontend |
| **Frontend** | Status Polling | ❌ 0% | 4 | Frontend |
| **Frontend** | Error Handling | ⚠️ 30% | 3 | Frontend |
| **Backend** | Express Server | ❌ 0% | 3 | Backend |
| **Backend** | Bootstrap Endpoint | ❌ 0% | 4 | Backend |
| **Backend** | Jobs Endpoint | ❌ 0% | 3 | Backend |
| **Backend** | Terraform Generator | ❌ 0% | 5 | Backend |
| **Backend** | GitHub Integration | ❌ 0% | 4 | Backend |
| **Backend** | Job Store | ❌ 0% | 2 | Backend |
| **Workflow** | Verify Complete | ⚠️ 80% | 2 | DevOps |
| **Testing** | End-to-End | ❌ 0% | 5 | Both |
| **TOTAL** | | **~65%** | **44 hours** | Team |

---

**Owner**: Platform Engineering  
**Next Step**: Decide — build backend first or finish frontend wiring?  
**Recommendation**: Frontend wiring (easier, unblocks design review) → Backend build (core feature) → Integration & testing

