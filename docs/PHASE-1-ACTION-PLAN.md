# Phase 1 Implementation Action Plan

**Timeline:** Sequential execution required (1C fixes block 1A/1B completion, 1F validates all)  
**Dependency:** Phase 0 skeleton files (✅ complete)

---

## Overview

Phase 1 has four inter-dependent workstreams:

1. **Phase 1A** — Implement deployment form (MSAL auth, cost calculation, GitHub API integration)
2. **Phase 1B** — Implement GitHub Actions workflows (module composition, release creation, deployment)
3. **Phase 1C** — Fix Compose-TerraformPackage.ps1 (variable mapping, regional logic, variant handling)
4. **Phase 1F** — End-to-end testing (form → compose → release → deploy)

**Critical path:** 1C → 1B → 1A → 1F  
(Form and workflows depend on working Compose script)

---

## Phase 1C: Compose Script Implementation Fixes

**Current Status:** Skeleton complete, major gaps identified in Phase 1D audit  
**Effort:** 4-6 hours  
**Deliverable:** Production-ready Compose-TerraformPackage.ps1

### 1C.1: Region Code Mapping

**Issue:** Hub and spoke modules require `region_code` variable for naming. Currently missing.

**Implementation:**
```powershell
$regionCodeMap = @{
    "eastus"           = "scus"
    "westus"           = "scus"
    "northeurope"      = "neu"
    "westeurope"       = "weu"
    "southcentralus"   = "scus"
    "northcentralus"   = "ncus"
    "eastus2"          = "eus2"
    "westus2"          = "wcus"
    "southeastasia"    = "sea"
    "eastasia"         = "eas"
    "australiaeast"    = "aue"
    "australiasoutheast" = "ause"
    "canadacentral"    = "cac"
    "canadaeast"       = "cae"
    "uksouth"          = "uks"
    "ukwest"           = "ukw"
    "japaneast"        = "jpe"
    "japanwest"        = "jpw"
    "koreacentral"     = "kc"
    "koreasouth"       = "ks"
}

# Validate regions
if (-not $regionCodeMap.ContainsKey($PrimaryRegion)) {
    Write-Error "Primary region '$PrimaryRegion' not supported. Add to regionCodeMap first."
}
if (-not $regionCodeMap.ContainsKey($SecondaryRegion)) {
    Write-Error "Secondary region '$SecondaryRegion' not supported. Add to regionCodeMap first."
}

$primaryRegionCode = $regionCodeMap[$PrimaryRegion]
$secondaryRegionCode = $regionCodeMap[$SecondaryRegion]
```

**Test Cases:**
- [ ] eastus → scus ✓
- [ ] westus → scus ✓
- [ ] Invalid region → error ✓

---

### 1C.2: Hub-Network Variable Mapping

**Issue:** Compose script uses wrong variable names and missing firewall defaults.

**Current (Wrong):**
```powershell
module "hub_network" {
  source = "../../modules/hub-network"
  resource_group_name = "rg-${OrgPrefix}-hub-network"
  location            = var.primary_region          # ← WRONG: module expects "region"
  org_prefix          = var.org_prefix              # ← Module doesn't take this
  address_space       = var.hub_address_space       # ← WRONG: module expects "hub_address_space"
}
```

**Corrected:**
```powershell
module "hub_network" {
  source = "../../modules/hub-network"
  
  region                      = var.primary_region
  region_code                 = local.primary_region_code
  environment                 = var.environment
  hub_address_space           = var.hub_address_space
  firewall_type               = local.firewall_type_by_variant[var.compliance_variant]
  azfw_tier                   = local.azfw_tier_by_variant[var.compliance_variant]
  tags                        = var.tags
  log_analytics_workspace_id  = azurerm_log_analytics_workspace.central.id
  
  depends_on = [module.management_groups]
}
```

**Firewall Defaults by Compliance:**
```powershell
locals {
  firewall_type_by_variant = {
    "baseline"  = "azfw"
    "pci-dss"   = "azfw"
    "hipaa"     = "azfw"
    "fedramp"   = "azfw"
  }
  
  azfw_tier_by_variant = {
    "baseline"  = "Standard"  # Cost: ~$1,500/mo
    "pci-dss"   = "Standard"  # Cost: ~$1,500/mo
    "hipaa"     = "Premium"   # Cost: ~$4,000/mo (TLS inspection)
    "fedramp"   = "Premium"   # Cost: ~$4,000/mo (TLS inspection)
  }
}
```

**Action Items:**
- [ ] Update module call with correct variable names
- [ ] Add firewall tier selection logic
- [ ] Create centralized Log Analytics workspace OR use hub-network's
- [ ] Test with all 4 compliance variants

---

### 1C.3: Spoke-Network Configuration

**Issue:** Spoke module hardcoded to single spoke. Need parameterization for future multi-spoke.

**Current (Limited):**
```powershell
module "spoke_network" {
  source = "../../modules/spoke-network"
  
  resource_group_name = "rg-${OrgPrefix}-spoke-network"  # ← Wrong variable names
  location            = var.primary_region              # ← Wrong variable name
  org_prefix          = var.org_prefix                  # ← Module doesn't expect
  hub_vnet_id         = module.hub_network.vnet_id      # ← Wrong output name
}
```

**Corrected (MVP: Single Spoke):**
```powershell
module "spoke_network" {
  source = "../../modules/spoke-network"
  
  spoke_name                = "workload-prod"
  region                    = var.primary_region
  region_code               = local.primary_region_code
  environment               = var.environment
  spoke_address_space       = "10.1.0.0/16"
  enable_hub_peering        = true
  hub_vnet_id               = module.hub_network.hub_vnet_id
  hub_vnet_name             = module.hub_network.hub_vnet_name
  hub_resource_group_name   = module.hub_network.resource_group_name
  firewall_private_ip       = module.hub_network.firewall_private_ip
  tags                      = var.tags
  
  depends_on = [module.hub_network]
}
```

**Future Multi-Spoke (Phase 2):**
```powershell
# Add to variables.tf:
variable "spoke_configs" {
  type = list(object({
    name          = string
    address_space = string
  }))
  default = []
}

# In main.tf:
module "spoke_networks" {
  for_each = { for s in var.spoke_configs : s.name => s }
  
  source = "../../modules/spoke-network"
  
  spoke_name                = each.value.name
  spoke_address_space       = each.value.address_space
  # ... rest of config
  
  depends_on = [module.hub_network]
}
```

**Action Items:**
- [ ] Fix variable names in module call
- [ ] Use correct output names (hub_vnet_id not vnet_id)
- [ ] Hardcode single spoke for MVP
- [ ] Document multi-spoke strategy for Phase 2

---

### 1C.4: Policy-Baseline Variant Handling

**Issue:** Compliance variant needs to be passed to policy module but interface unclear.

**Investigation Needed:**
- [ ] Check policy-baseline/main.tf for variant conditional logic
- [ ] Determine if module has internal `compliance_variant` variable
- [ ] Or if we need separate policy files per variant

**Likely Implementation:**
```powershell
module "policy_baseline" {
  source = "../../modules/policy-baseline"
  
  root_mg_id         = module.management_groups.root_mg_id
  platform_mg_id     = module.management_groups.platform_mg_id
  landingzones_mg_id = module.management_groups.landingzones_mg_id
  sandbox_mg_id      = module.management_groups.sandbox_mg_id
  location           = var.primary_region
  allowed_locations  = [var.primary_region, var.secondary_region]
  
  # Variant handling (TBD after checking module):
  compliance_variant = var.compliance_variant  # If module supports
  
  depends_on = [module.management_groups]
}
```

**Action Items:**
- [ ] Read policy-baseline/main.tf to confirm variant handling
- [ ] Update module call accordingly
- [ ] Test all 4 variants generate correct policies

---

### 1C.5: Add Outputs to main.tf

**Issue:** Generated main.tf has no outputs for reference.

**Implementation:**
```hcl
output "management_groups" {
  description = "Management group IDs"
  value       = module.management_groups.management_group_map
}

output "hub_network" {
  description = "Hub network details"
  value = {
    vnet_id             = module.hub_network.hub_vnet_id
    firewall_private_ip = module.hub_network.firewall_private_ip
    log_analytics_id    = module.hub_network.log_analytics_workspace_id
  }
}

output "deployment_summary" {
  description = "Deployment summary for manifest"
  value = {
    org_prefix          = var.org_prefix
    primary_region      = var.primary_region
    secondary_region    = var.secondary_region
    compliance_variant  = var.compliance_variant
    deployed_modules    = var.deployed_modules
  }
}
```

**Action Items:**
- [ ] Add outputs section to generated main.tf template
- [ ] Ensure outputs match what customers might need
- [ ] Document in DEPLOYMENT-GUIDE.md

---

## Phase 1B: GitHub Actions Workflows

**Current Status:** Skeleton complete, needs testing and hardening  
**Effort:** 3-4 hours  
**Depends On:** 1C (Compose script working)

### 1B.1: generate-and-release.yml Hardening

**Current Gaps:**
1. Compose script invocation might fail if variables not set
2. No validation of generated Terraform syntax
3. Release tag naming needs verification
4. Artifacts upload might fail if Compose script is broken

**Implementation Tasks:**
```yaml
# Add to generate-and-release.yml after compose step:

- name: Validate Terraform Syntax
  run: |
    cd terraform/live/${{ inputs.org_prefix }}
    terraform validate
    
- name: Format Check
  run: |
    cd terraform/live/${{ inputs.org_prefix }}
    terraform fmt -check -recursive

- name: Plan (No Apply)
  run: |
    cd terraform/live/${{ inputs.org_prefix }}
    terraform plan -var-file=terraform.tfvars -out=tfplan
    terraform show tfplan -json > tfplan.json
    
- name: Upload Artifacts
  if: success()
  uses: actions/upload-artifact@v3
  with:
    name: terraform-package
    path: terraform/live/${{ inputs.org_prefix }}/
    
- name: Create Release
  if: success()
  uses: softprops/action-gh-release@v1
  with:
    tag_name: v1.0.0-${{ inputs.org_prefix }}-${{ inputs.compliance_variant }}-${{ github.run_number }}
    files: |
      terraform/live/${{ inputs.org_prefix }}/main.tf
      terraform/live/${{ inputs.org_prefix }}/variables.tf
      terraform/live/${{ inputs.org_prefix }}/terraform.tfvars
      terraform/live/${{ inputs.org_prefix }}/backend.hcl
      terraform/live/${{ inputs.org_prefix }}/deployment-manifest.yaml
```

**Action Items:**
- [ ] Add Terraform validation step
- [ ] Add format check
- [ ] Add terraform plan (dry-run) validation
- [ ] Implement artifact upload
- [ ] Test with real inputs

---

### 1B.2: deploy-from-release.yml Hardening

**Current Gaps:**
1. Release extraction logic unclear
2. No approval gate before apply
3. Missing error handling for state conflicts
4. No output of deployment status

**Implementation:**
```yaml
- name: Extract org_prefix from release tag
  id: extract
  run: |
    TAG="${{ github.event.release.tag_name }}"
    ORG_PREFIX=$(echo $TAG | sed 's/v1.0.0-\([^-]*\)-.*/\1/')
    echo "org_prefix=$ORG_PREFIX" >> $GITHUB_OUTPUT

- name: Terraform Init
  run: |
    cd terraform/live/${{ steps.extract.outputs.org_prefix }}
    terraform init -backend-config=backend.hcl

- name: Terraform Plan
  run: |
    cd terraform/live/${{ steps.extract.outputs.org_prefix }}
    terraform plan -var-file=terraform.tfvars -out=tfplan

- name: Approval Gate (Manual)
  uses: trstringer/manual-approval@v1
  with:
    secret: ${{ secrets.GITHUB_TOKEN }}
    approvers: platform-team
    minimum-approvals: 1
    issue-title: "Approve deployment of ${{ steps.extract.outputs.org_prefix }}"

- name: Terraform Apply
  if: success()
  run: |
    cd terraform/live/${{ steps.extract.outputs.org_prefix }}
    terraform apply -auto-approve tfplan
    terraform output -json > output.json

- name: Post Deployment Summary
  if: always()
  uses: actions/github-script@v6
  with:
    script: |
      const fs = require('fs');
      const output = JSON.parse(fs.readFileSync('terraform/live/${{ steps.extract.outputs.org_prefix }}/output.json'));
      github.rest.issues.createComment({
        issue_number: context.issue.number,
        owner: context.repo.owner,
        repo: context.repo.repo,
        body: `## Deployment Complete\n\n\`\`\`json\n${JSON.stringify(output, null, 2)}\n\`\`\``
      });
```

**Action Items:**
- [ ] Implement org_prefix extraction from tag
- [ ] Add approval gate (manual or automatic)
- [ ] Add error handling and rollback strategy
- [ ] Post deployment summary to PR/issue
- [ ] Test deployment flow

---

## Phase 1A: Deployment Form Implementation

**Current Status:** Skeleton HTML/CSS/JS complete, MSAL/API/cost calc TODO  
**Effort:** 4-5 hours  
**Depends On:** 1C (Compose script stable), 1B (workflows deployed)

### 1A.1: MSAL Authentication

**Current:** All TODO  
**Implementation:**

```javascript
// Update msalConfig with Azure AD app details
const msalConfig = {
    auth: {
        clientId: process.env.REACT_APP_CLIENT_ID || "YOUR_CLIENT_ID",
        authority: `https://login.microsoftonline.com/${process.env.REACT_APP_TENANT_ID || "YOUR_TENANT_ID"}`,
        redirectUri: window.location.origin + "/frontend/",
    },
    cache: { cacheLocation: "localStorage" }
};

// Test login flow
async function testLogin() {
    try {
        const response = await msalInstance.loginPopup(loginRequest);
        console.log("✅ Login successful:", response.account.name);
        authToken = response.accessToken;
    } catch (error) {
        console.error("❌ Login failed:", error);
    }
}
```

**Setup Steps:**
1. Create Azure AD app registration
2. Add redirect URI: `https://your-domain/frontend/`
3. Grant API permissions: (TBD—check if form needs Graph API)
4. Generate client secret (or use PKCE flow)
5. Set environment variables in deployment (GitHub Actions secrets or Static Web Apps config)

**Action Items:**
- [ ] Create Azure AD app registration
- [ ] Configure redirect URIs
- [ ] Set up environment variables
- [ ] Test login locally
- [ ] Implement token refresh logic

---

### 1A.2: GitHub API Integration (workflow_dispatch)

**Current:** TODO  
**Implementation:**

```javascript
// Form submission triggers GitHub workflow
document.getElementById("deploymentForm").addEventListener("submit", async (e) => {
    e.preventDefault();
    
    const formData = {
        org_prefix:        document.getElementById("orgPrefix").value,
        modules:           getSelectedModules(),
        compliance_variant: document.getElementById("compliance").value,
        primary_region:    document.getElementById("primaryRegion").value,
        secondary_region:  document.getElementById("secondaryRegion").value,
    };
    
    showLoading();
    
    try {
        const response = await fetch(
            `https://api.github.com/repos/${GITHUB_ORG}/${GITHUB_REPO}/actions/workflows/generate-and-release.yml/dispatches`,
            {
                method: "POST",
                headers: {
                    "Authorization": `token ${GITHUB_TOKEN}`,
                    "Content-Type": "application/json",
                    "Accept": "application/vnd.github.v3+json"
                },
                body: JSON.stringify({
                    ref: "main",
                    inputs: formData
                })
            }
        );
        
        if (!response.ok) {
            throw new Error(`GitHub API error: ${response.statusText}`);
        }
        
        // Poll for workflow completion
        const workflowRun = await pollForWorkflowCompletion();
        const releaseUrl = `https://github.com/${GITHUB_ORG}/${GITHUB_REPO}/releases/tag/${workflowRun.tag}`;
        
        showSuccess(releaseUrl, formData.org_prefix);
    } catch (error) {
        showError(error.message);
    }
});
```

**Setup Steps:**
1. Create GitHub Personal Access Token (or use GitHub App)
2. Grant `repo` + `actions:read` permissions
3. Store token in environment/secrets
4. Get GITHUB_ORG, GITHUB_REPO from environment

**Action Items:**
- [ ] Create GitHub PAT or GitHub App
- [ ] Implement workflow dispatch API call
- [ ] Implement workflow completion polling (10-30 min timeout)
- [ ] Extract release URL from workflow output
- [ ] Handle API errors gracefully

---

### 1A.3: Cost Estimation

**Current:** Hardcoded placeholder  
**Implementation:**

```javascript
const costModel = {
    base: {
        "management-groups": 0,        // No cost
        "hub-network": 1500,            // Azure Firewall ~$1,500/mo
        "spoke-network": 300,           // VNet peering, routing
        "policy-baseline": 0,           // No direct cost
    },
    optional: {
        "backup-baseline": 500,         // Backup vault, replication
        "defender-baseline": 2000,      // Defender for Cloud
    },
    compliance_multiplier: {
        "baseline": 1.0,
        "pci-dss": 1.2,                 // Extra monitoring
        "hipaa": 1.5,                   // TLS inspection, encryption audit
        "fedramp": 1.8,                 // Continuous compliance monitoring
    },
    secondary_region_factor: 0.15,      // 15% of primary region cost (skeleton)
};

function updateCostEstimate() {
    const selectedModules = getSelectedModules();
    const compliance = document.getElementById("compliance").value;
    const hasSecondaryRegion = document.getElementById("secondaryRegion").value !== "";
    
    let monthlyCost = Object.values(costModel.base).reduce((a, b) => a + b, 0);
    
    // Add optional modules
    if (selectedModules.includes("backup-baseline")) {
        monthlyCost += costModel.optional["backup-baseline"];
    }
    if (selectedModules.includes("defender-baseline")) {
        monthlyCost += costModel.optional["defender-baseline"];
    }
    
    // Apply compliance multiplier
    monthlyCost *= costModel.compliance_multiplier[compliance];
    
    // Add secondary region
    if (hasSecondaryRegion) {
        monthlyCost += monthlyCost * costModel.secondary_region_factor;
    }
    
    const breakdown = `
        <div class="cost-item">
            <span>Hub Network (Firewall ${getFirewallTier(compliance)})</span>
            <strong>$${Math.round(costModel.base["hub-network"] * costModel.compliance_multiplier[compliance])}/month</strong>
        </div>
        <div class="cost-item">
            <span>Spoke Network</span>
            <strong>$${costModel.base["spoke-network"]}/month</strong>
        </div>
        ${selectedModules.includes("backup-baseline") ? `
        <div class="cost-item">
            <span>Backup & Recovery</span>
            <strong>$${costModel.optional["backup-baseline"]}/month</strong>
        </div>
        ` : ""}
        ${selectedModules.includes("defender-baseline") ? `
        <div class="cost-item">
            <span>Defender for Cloud</span>
            <strong>$${costModel.optional["defender-baseline"]}/month</strong>
        </div>
        ` : ""}
        ${hasSecondaryRegion ? `
        <div class="cost-item">
            <span>Secondary Region (DR Skeleton)</span>
            <strong>$${Math.round(monthlyCost * costModel.secondary_region_factor)}/month</strong>
        </div>
        ` : ""}
        <div class="cost-total">
            <span>Estimated Total</span>
            <strong>$${Math.round(monthlyCost)}/month</strong>
        </div>
    `;
    
    document.getElementById("costBreakdown").innerHTML = breakdown;
}

function getFirewallTier(compliance) {
    return ["hipaa", "fedramp"].includes(compliance) ? "Premium" : "Standard";
}
```

**Accuracy Notes:**
- Estimates are ±20% (actual costs vary by region, data usage)
- Secondary region is skeletal deployment (no workloads, ~15% primary cost)
- Defender costs vary by resource count
- Should include disclaimer in UI

**Action Items:**
- [ ] Implement cost model object
- [ ] Create updateCostEstimate() function
- [ ] Hook cost calculation to module/compliance changes
- [ ] Add disclaimer about estimate accuracy
- [ ] Test with various scenarios

---

## Phase 1F: End-to-End Testing

**Current Status:** Not started  
**Effort:** 6-8 hours  
**Depends On:** 1A, 1B, 1C all complete

### 1F.1: Test Scenarios

**Scenario 1: Baseline Single Region**
- Org prefix: "test1"
- Modules: hub-network, spoke-network, policy-baseline (always)
- Compliance: baseline
- Regions: eastus, westus
- Expected: Hub + spoke + baseline policies in eastus, DR skeleton in westus

**Scenario 2: HIPAA Multi-Region**
- Org prefix: "hipaa"
- Modules: all (including backup, defender)
- Compliance: hipaa
- Regions: eastus, westus
- Expected: Premium firewall (TLS inspection), HIPAA policies, backup, defender, DR in westus

**Scenario 3: FedRAMP**
- Org prefix: "fed"
- Modules: all
- Compliance: fedramp
- Regions: govcloud (if supported)
- Expected: FedRAMP policies, continuous monitoring

### 1F.2: Test Checklist

```markdown
## Form → Release → Deploy Test

- [ ] **Form Submission**
  - [ ] MSAL login works
  - [ ] Form validation catches invalid org prefix
  - [ ] Module selection correctly reflects always-on vs optional
  - [ ] Cost estimate updates on module/compliance change
  - [ ] Submit triggers workflow_dispatch

- [ ] **Compose Script Execution**
  - [ ] Workflow receives inputs correctly
  - [ ] Compose script generates all files
  - [ ] main.tf uses correct module paths
  - [ ] variables.tf has all required variables
  - [ ] terraform.tfvars has TODOs for subscription IDs
  - [ ] backend.hcl has TFC placeholder
  - [ ] deployment-manifest.yaml is valid YAML

- [ ] **Terraform Validation**
  - [ ] terraform validate passes
  - [ ] terraform plan succeeds (will fail due to missing subscription IDs, expected)
  - [ ] Dependency graph is correct (management-groups → hub/policy → spoke)

- [ ] **Release Creation**
  - [ ] Release tag is correct format
  - [ ] All artifacts uploaded
  - [ ] Release is downloadable

- [ ] **Customer Deployment** (Manual)
  - [ ] Customer follows setup guide
  - [ ] Updates terraform.tfvars with actual subscription IDs
  - [ ] Updates backend.hcl with TFC org
  - [ ] terraform init succeeds
  - [ ] terraform plan shows expected resources
  - [ ] terraform apply succeeds (or fails gracefully)

- [ ] **Validation**
  - [ ] Hub VNet created in primary region
  - [ ] Spoke VNet created and peered to hub
  - [ ] Management groups created
  - [ ] Policies assigned
  - [ ] (If backup) Backup vault created
  - [ ] (If defender) Defender workspace created
```

### 1F.3: Test Environment Setup

```bash
# Prerequisites
- Azure subscription (test account acceptable)
- GitHub organization (can be personal org)
- Terraform Cloud account (free tier)
- Azure CLI installed
- PowerShell 7+ installed

# Setup
1. Fork this repo to test org
2. Create test Azure AD app for form auth
3. Create test GitHub PAT for workflow dispatch
4. Set up Terraform Cloud workspace
5. Create test subscription IDs (can use multiple dev subscriptions)

# Run tests
./tests/run-e2e-tests.sh \
  --org-prefix "test1" \
  --compliance "baseline" \
  --primary-region "eastus" \
  --secondary-region "westus"
```

**Action Items:**
- [ ] Create test Azure subscription(s)
- [ ] Create test GitHub org or use existing
- [ ] Create test Terraform Cloud workspace
- [ ] Write test scripts (bash/PowerShell)
- [ ] Run through all 3 scenarios
- [ ] Document issues and fixes
- [ ] Sign-off from platform team

---

## Summary of Deliverables

| Phase | Deliverable | Status | Tests |
|-------|-------------|--------|-------|
| 1A | Deployment form (MSAL + cost + API) | Pending | 10+ user scenarios |
| 1B | GitHub Actions workflows | Pending | Workflow dispatch, release creation, deployment |
| 1C | Compose-TerraformPackage.ps1 fixes | In Progress | Syntax validation, all variants |
| 1F | End-to-end test suite | Pending | 3 scenarios, customer flow |

---

## Critical Path & Timeline

```
Week 1:
  Day 1-2: Phase 1C (Compose script fixes) — BLOCKING
  Day 3-4: Phase 1B (Workflow hardening) — PARALLEL
  Day 5: Phase 1A (Form implementation) — SEQUENTIAL

Week 2:
  Day 1-2: Phase 1F (E2E testing) — PARALLEL
  Day 3-5: Bug fixes, polish, documentation
```

**Target Phase 1 Completion:** 2 weeks from start

---

## Phase 2 Prerequisites

Before moving to Phase 2, ensure:
- ✅ All Phase 1 tests pass
- ✅ Form validated with at least 2 customers (internal)
- ✅ Compose script tested with all 4 compliance variants
- ✅ GitHub Actions workflows stable (no random failures)
- ✅ CUSTOMER-SETUP.md validated by customer
- ✅ Cost estimates ±20% accuracy

Phase 2 adds: management module, policy variants, DR secondary region, cost estimation refinement.

---

**Document ID:** ALZ-PHASE1-PLAN-20260628  
**Owner:** Implementation Team  
**Last Updated:** 2026-06-28
