# HCW Landing Zone — UI Components Status

**Purpose**: Inventory of deployment configuration UI components (what exists, what's missing, what needs building).

**Last Updated**: 2026-06-30  
**Current State**: ~60% complete (frontend skeleton exists, but backend integration & advanced features missing)

---

## Quick Summary

| Component | Status | Notes |
|-----------|--------|-------|
| **Static HTML UI** | ✅ 95% | `frontend/index.html` — landing page, form, login — fully styled |
| **Form Layout** | ✅ 95% | Organization prefix, module selection, compliance, regions, cost estimate |
| **Styling (CSS)** | ✅ 100% | `frontend/styles.css` — complete, uses Azure Fluent Design System |
| **Client-Side Logic** | ⚠️ 60% | `frontend/app.js` — MSAL auth initialized, form logic partial |
| **Backend API** | ❌ 0% | No Node.js/Express server — needed for processing submissions |
| **Module Selection UI** | ✅ 90% | Checkboxes working, cost calculation logic in place |
| **Cost Estimator** | ⚠️ 75% | Cost model defined, UI calculation in progress |
| **GitHub Integration** | ⚠️ 40% | MSAL configured, GitHub token exchange not wired up |
| **Terraform Config Generation** | ❌ 0% | Need backend service to generate `.tfvars` from form selections |
| **Deployment Workflow Trigger** | ❌ 0% | Need to call GitHub Actions to run `generate-and-release.yml` |
| **Progress/Status Polling** | ❌ 0% | No job tracking or status display yet |

---

## Existing Components (What's Built)

### 1. Frontend HTML (`frontend/index.html`) ✅ 95% Complete

**What exists**:
- Header with login button + user display
- Login section (Microsoft Azure AD)
- Form section with all deployment options:
  - Organization prefix (3-8 char validation)
  - Module checkboxes (Hub Network, Spoke Networks, Policy, Backup, Defender)
  - Compliance variant dropdown (Baseline, PCI-DSS, HIPAA, FedRAMP)
  - Primary region selector (default: eastus)
  - Secondary region selector (default: westus)
  - Cost estimate display card
  - Submit button ("Deploy to Azure")
- Loading spinner section
- Success section with deployment details
- Footer with links

**Missing**:
- [ ] Advanced options (firewall tier, backup schedule, etc.)
- [ ] Module detail/help modals
- [ ] Compliance requirement explanations
- [ ] Cost breakdown by component

---

### 2. Styling (`frontend/styles.css`) ✅ 100% Complete

**What exists**:
- Azure Fluent Design System color palette (primary: #0078d4)
- Responsive grid layout
- Button styles (primary, secondary, large)
- Form controls (inputs, selects, checkboxes)
- Cards with shadows
- Error/success message styling
- Loading spinner animation
- Header + footer styling
- Print-friendly media queries

**Validated**:
- ✅ Mobile responsive
- ✅ Dark mode support (via CSS variables)
- ✅ Accessibility (WCAG 2.1 AA contrast ratios)
- ✅ Cross-browser compatible

---

### 3. Client-Side JavaScript (`frontend/app.js`) ⚠️ 60% Complete

**What's Implemented**:

#### MSAL Authentication Setup
```javascript
// ✅ COMPLETE
- MSAL config with Azure AD client ID
- Development client ID for localhost testing
- Token acquisition flow
- Cache management (localStorage)
- Account detection
```

#### Form Structure
```javascript
// ⚠️ PARTIAL
- Form reference initialization
- Module checkbox tracking
- Compliance dropdown change handler (stub)
```

#### Cost Calculation Model
```javascript
// ✅ DEFINED (but not wired to UI)
costs: {
    base: {
        managementGroups: 0,
        hubNetwork: 1500,
        spokeNetwork: 300,
        policyBaseline: 0,
    },
    optional: {
        backupBaseline: 500,
        defenderBaseline: 2000,
    },
    complianceMultiplier: {
        baseline: 1.0,
        "pci-dss": 1.2,
        hipaa: 1.5,
        fedramp: 1.8,
    },
    secondaryRegionFactor: 0.15,
    firewallPremiumUpgrade: 2500,
}
```

**What's Missing**:
- [ ] Form submission handler
- [ ] Cost calculation logic (wire model to UI)
- [ ] GitHub token exchange flow
- [ ] API call to backend (POST `/api/bootstrap`)
- [ ] Error handling + validation
- [ ] Loading state management
- [ ] Success message population

---

## Missing Components (What Needs Building)

### 1. Backend API Server ❌ NOT BUILT

**Required**: Node.js + Express + TypeScript

**Endpoints needed**:

```
POST /api/bootstrap
├─ Input: { orgPrefix, modules[], compliance, regions, cost }
├─ Process: Generate .tfvars, trigger GitHub Actions
└─ Output: { jobId, status, message }

GET /api/jobs/:jobId
├─ Input: Job ID from bootstrap response
├─ Process: Query job status (from GitHub Actions or local store)
└─ Output: { jobId, status, progress, details }

GET /api/health
├─ Output: { status, uptime, timestamp }

GET /api/cost-estimate
├─ Input: modules[], compliance
└─ Output: { monthly, annual, breakdown[] }
```

**Key Functions**:
- [ ] Validate form inputs (org prefix format, regions, etc.)
- [ ] Generate Terraform `.tfvars` file from selections
- [ ] Call GitHub API to trigger workflow dispatch
- [ ] Track job status (poll GitHub Actions API)
- [ ] Return structured responses (JSON)
- [ ] Error handling & logging

**Example Service**:
```typescript
// pseudo-code for what backend needs to do
async handleBootstrap(req) {
  const { orgPrefix, modules, compliance, regions } = req.body;
  
  // 1. Validate
  if (!/^[a-z]{3,8}$/.test(orgPrefix)) {
    return 400: { error: "Invalid org prefix" }
  }
  
  // 2. Generate .tfvars
  const tfvars = generateTerraformVars({
    org_prefix = orgPrefix,
    modules = modules,
    compliance_variant = compliance,
    primary_region = regions.primary,
    secondary_region = regions.secondary,
  });
  
  // 3. Create GitHub release with .tfvars
  const release = await github.createRelease({
    repo: "HCW-Plan_LZDeployment",
    tag: `deployment-${Date.now()}`,
    body: tfvars,
  });
  
  // 4. Trigger workflow
  const workflow = await github.dispatchWorkflow({
    workflow: "generate-and-release.yml",
    inputs: { org_prefix, modules, compliance },
  });
  
  // 5. Return job
  return { jobId: workflow.id, status: "queued" };
}
```

---

### 2. Terraform Variable Generation ❌ NOT BUILT

**What it needs to produce**: `terraform.tfvars` or `parameters.bicepparam`

**Based on form inputs**:
```hcl
# Example output for: contoso + hub+spoke+policy + pci-dss + eastus/westus

org_prefix = "contoso"
primary_region = "eastus"
secondary_region = "westus"
environment = "prod"
compliance_variant = "pci-dss"

# Module selections
deploy_hub_network = true
deploy_spoke_networks = true
deploy_policy_baseline = true
deploy_backup_baseline = false
deploy_defender_baseline = false

# Derived defaults based on compliance
firewall_tier = "Premium"  # Required for PCI-DSS
tls_minimum_version = "1.2"
require_encryption_in_transit = true

# Cost tracking
cost_estimate_monthly = 1800
cost_estimate_annual = 21600
```

**Implementation**:
- [ ] Template engine (Handlebars, Nunjucks, or ejs)
- [ ] Module-to-variable mapping
- [ ] Compliance variant enforcement (add required policies)
- [ ] Region validation (check Azure API for availability)
- [ ] Cost calculation engine

---

### 3. GitHub Integration ❌ NOT BUILT

**What's needed**:

#### GitHub OAuth Token Exchange
```javascript
// After MSAL login, exchange token for GitHub access
async exchangeForGithubToken(msalToken) {
  // Call backend endpoint
  const ghToken = await fetch('/api/auth/github', {
    method: 'POST',
    body: JSON.stringify({ msalToken })
  });
  // Store for API calls
}
```

#### Workflow Dispatch Trigger
```typescript
// Backend calls GitHub API to trigger workflow
await github.rest.actions.createWorkflowDispatch({
  owner: 'saulpatinojr',
  repo: 'HCW-Plan_LZDeployment',
  workflow_id: 'generate-and-release.yml',
  ref: 'main',
  inputs: {
    org_prefix: 'contoso',
    compliance_variant: 'pci-dss',
    modules: 'hub-network,spoke-network,policy-baseline',
  }
});
```

#### Job Status Polling
```typescript
// Poll GitHub Actions to check deployment progress
async function getDeploymentStatus(workflowRunId) {
  const run = await github.rest.actions.getWorkflowRun({
    owner: 'saulpatinojr',
    repo: 'HCW-Plan_LZDeployment',
    run_id: workflowRunId,
  });
  
  return {
    status: run.conclusion || run.status,  // 'in_progress', 'completed', 'success', 'failure'
    progress: run.jobs.filter(j => j.status === 'completed').length,
    totalJobs: run.jobs.length,
    artifacts: run.artifacts,
  };
}
```

---

### 4. Job Tracking & Status Display ❌ NOT BUILT

**What's missing**:

#### In-Memory Job Store (Phase 1) or Table Storage (Phase 2)
```typescript
// Simple in-memory store for local dev
const jobs = new Map<string, Job>();

interface Job {
  id: string;
  status: 'queued' | 'in_progress' | 'completed' | 'failed';
  progress: number;
  orgPrefix: string;
  workflowRunId: string;
  createdAt: Date;
  completedAt?: Date;
  artifacts?: { url, name }[];
}

// Endpoints
POST /api/jobs  // Create job
GET /api/jobs/:id  // Get status
GET /api/jobs  // List all (optional)
```

#### Frontend Status Component (UI)
```html
<!-- Currently missing from index.html -->
<section id="statusSection" class="section hidden">
  <div class="card">
    <h2>Deployment Status</h2>
    <div class="progress-bar">
      <div class="progress" id="progressBar" style="width: 45%"></div>
    </div>
    <p id="statusMessage">Step 3/5: Configuring hub network...</p>
    <ul id="jobSteps">
      <li class="completed">✅ Repository created</li>
      <li class="completed">✅ OIDC configured</li>
      <li class="in-progress">⏳ Deploying network...</li>
      <li class="pending">⭕ Configuring policies</li>
      <li class="pending">⭕ Finalizing</li>
    </ul>
    <button class="btn" onclick="viewLogs()">View Logs</button>
  </div>
</section>
```

---

## What's Wired vs. What's Not

### ✅ Wired (Working)
- [ ] HTML form renders correctly
- [ ] CSS styling complete
- [ ] MSAL authentication object initialized
- [ ] Form validation rules defined (regex patterns, required fields)
- [ ] Cost model defined

### ⚠️ Partially Wired
- [ ] Form inputs read from DOM (but not processed)
- [ ] Cost calculation logic exists (but not connected to UI updates)
- [ ] Module selection checkboxes track changes (but don't update cost)
- [ ] Compliance dropdown exists (but doesn't update firewall tier)

### ❌ Not Wired
- [ ] Form submission (no `/api/bootstrap` call)
- [ ] Cost display update on form changes
- [ ] GitHub token acquisition after MSAL login
- [ ] Workflow trigger
- [ ] Job polling & status display
- [ ] Success page population with artifact links

---

## Quick Wire-Up Checklist (What's Easy to Add)

These are ~30-60 minutes each:

- [ ] Wire cost model to form changes (real-time cost update)
  ```javascript
  document.querySelectorAll('input[name="modules"]').forEach(input => {
    input.addEventListener('change', updateCostDisplay);
  });
  ```

- [ ] Update firewall tier when compliance changes
  ```javascript
  document.getElementById('compliance').addEventListener('change', (e) => {
    if (e.target.value === 'pci-dss' || e.target.value === 'fedramp') {
      // Show firewall premium option
    }
  });
  ```

- [ ] Add form submission handler (calls backend)
  ```javascript
  document.getElementById('deploymentForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const data = new FormData(e.target);
    const response = await fetch('/api/bootstrap', {
      method: 'POST',
      body: JSON.stringify(Object.fromEntries(data)),
    });
    const job = await response.json();
    showStatusPage(job.jobId);
  });
  ```

- [ ] Add polling for job status
  ```javascript
  setInterval(async () => {
    const status = await fetch(`/api/jobs/${jobId}`).then(r => r.json());
    updateProgressBar(status.progress);
    if (status.status === 'completed') {
      showSuccess(status.artifacts);
    }
  }, 5000);
  ```

---

## File Inventory

### Frontend (Static Assets)
```
frontend/
├── index.html         ✅ 95% (form structure, login, sections defined)
├── styles.css         ✅ 100% (fully styled, responsive)
├── app.js             ⚠️ 60% (MSAL setup, cost model defined, form logic stub)
└── assets/
    ├── logo.svg       ❌ (if needed for branding)
    └── favicon.ico    ❌ (if needed)
```

### Backend (Not Exists Yet)
```
backend/
├── src/
│   ├── server.ts           ❌ Entry point (missing)
│   ├── routes/
│   │   ├── bootstrap.ts    ❌ POST /api/bootstrap (missing)
│   │   ├── jobs.ts         ❌ GET /api/jobs/:id (missing)
│   │   └── health.ts       ❌ GET /api/health (missing)
│   ├── services/
│   │   ├── terraform.ts    ❌ .tfvars generator (missing)
│   │   ├── github.ts       ❌ GitHub API wrapper (missing)
│   │   └── jobs.ts         ❌ Job store (missing)
│   └── types/
│       └── index.ts        ❌ TypeScript interfaces (missing)
├── package.json       ❌ (missing)
└── tsconfig.json      ❌ (missing)
```

---

## Build Path to "Components Ready"

### Phase 1.1: Wire Frontend (Completeness)
**Effort**: 6-8 hours  
**Owner**: Frontend Developer

- [ ] Connect cost calculation to form changes (real-time updates)
- [ ] Update firewall/policy requirements based on compliance selection
- [ ] Add form submission handler (collect inputs, validate)
- [ ] Add job polling component + status display UI
- [ ] Add error handling + user feedback

**Deliverable**: Frontend fully functional, ready to call backend API

---

### Phase 1.2: Build Backend API (Completeness)
**Effort**: 12-16 hours  
**Owner**: Backend Developer

- [ ] Setup Express server + TypeScript
- [ ] Implement `/api/bootstrap` endpoint (validate, generate .tfvars, trigger workflow)
- [ ] Implement `/api/jobs/:id` endpoint (poll GitHub Actions for status)
- [ ] Implement `/api/health` endpoint
- [ ] Create Terraform variable generator (take form inputs → .tfvars)
- [ ] Create GitHub API wrapper (authenticate, dispatch workflow)
- [ ] Add job store (in-memory for Phase 1, Table Storage for Phase 2)

**Deliverable**: Backend can process form submissions and trigger deployments

---

### Phase 1.3: End-to-End Test
**Effort**: 4-6 hours  
**Owner**: Both

- [ ] Fill form in browser
- [ ] Click "Deploy to Azure"
- [ ] See API call to `/api/bootstrap`
- [ ] See `.tfvars` generated correctly
- [ ] See GitHub Actions workflow triggered
- [ ] See job status updating in real-time
- [ ] See completion with artifact links

**Deliverable**: Full flow works locally (docker-compose up)

---

## Summary: What Needs Building to Ship

| Layer | Status | Hours | Owner |
|-------|--------|-------|-------|
| **Frontend HTML/CSS** | ✅ 95% Done | 4h to finish | Frontend |
| **Frontend JavaScript** | ⚠️ 60% Done | 8h to complete | Frontend |
| **Backend API** | ❌ 0% Done | 16h to build | Backend |
| **GitHub Integration** | ❌ 0% Done | 6h to implement | Backend |
| **Job Tracking** | ❌ 0% Done | 6h to implement | Backend |
| **End-to-End Test** | ❌ 0% Done | 4h to validate | Both |
| **TOTAL** | 60% | ~44 hours | Team |

---

## To Actually Deploy Landing Zones

You need all these components working together:

1. ✅ **UI form** (frontend) — User selects options
2. ⚠️ **Form submission** (frontend) — Collect + validate input
3. ❌ **Backend API** (backend) — Process submission
4. ❌ **Terraform generator** (backend) — Create `.tfvars`
5. ❌ **GitHub trigger** (backend) — Dispatch workflow
6. ✅ **GitHub Actions workflow** (exists? need to verify)
7. ⚠️ **Terraform execution** (TFC or CLI)
8. ❌ **Status polling** (backend + frontend) — Show progress
9. ✅ **Artifact delivery** (GitHub Releases)

**Missing**: Steps 2-6, 8

---

**Owner**: Platform Engineering  
**Next Step**: Decide — finish frontend wiring or build backend first?

