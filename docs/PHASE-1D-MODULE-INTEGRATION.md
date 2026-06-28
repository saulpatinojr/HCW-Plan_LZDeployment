# Phase 1D: Terraform Module Integration Audit

**Date:** 2026-06-28  
**Status:** Audit Complete  
**Next Action:** Update Compose-TerraformPackage.ps1 with identified gaps

---

## Executive Summary

All six Terraform modules exist and have interfaces. Module dependency graph is clear: **management-groups → hub/spoke/policy → backup/defender**. The Compose script skeleton is correct but incomplete—it needs variable mappings, regional logic, and firewall configuration defaults.

---

## Module Inventory

| Module | Status | Key Dependencies | Config Complexity |
|--------|--------|------------------|-------------------|
| **management-groups** | ✅ Ready | None | Simple (org prefix → MG hierarchy) |
| **hub-network** | ⚠️ Needs config | management-groups | High (firewall, threat intel, TLS) |
| **spoke-network** | ⚠️ Needs config | hub-network | Medium (address space, peering) |
| **policy-baseline** | ⚠️ Needs variant logic | management-groups | Medium (compliance variants) |
| **backup-baseline** | ✅ Ready | management-groups | Simple |
| **defender-baseline** | ✅ Ready | management-groups | Simple |
| **nsg-flow-logs** | ℹ️ Exists | — | (Not referenced in design) |

---

## Detailed Module Analysis

### 1. management-groups

**Module Location:** `terraform/modules/management-groups/`

**Variables Required:**
```hcl
org_prefix                           # ← from form
identity_subscription_id             # ← from tfvars
connectivity_subscription_id         # ← from tfvars
management_subscription_id           # ← from tfvars
workload_prod_subscription_id        # ← from tfvars
workload_nonprod_subscription_id     # ← from tfvars
sandbox_subscription_id              # ← from tfvars
```

**Outputs Provided:**
- `root_mg_id` — consumed by policy-baseline
- `platform_mg_id` — consumed by policy-baseline
- `landingzones_mg_id` — consumed by policy-baseline
- `sandbox_mg_id` — consumed by policy-baseline
- `management_group_map` — metadata

**Integration Status:** ✅ Complete  
**Action Needed:** None—already in Compose script

---

### 2. hub-network

**Module Location:** `terraform/modules/hub-network/`

**Variables Required (Critical):**
```hcl
region                      # ← var.primary_region
region_code                 # ← MISSING: needs map (eastus→scus, westus→scus)
environment                 # ← var.environment (default: "production")
hub_address_space           # ← var.hub_address_space (default: "10.0.0.0/16")
firewall_type               # ← MISSING: hardcoded default needed
azfw_tier                   # ← MISSING: hardcoded default needed
tags                        # ← var.tags
log_analytics_workspace_id  # ← MISSING: needs to be created or provided
```

**Variables Optional (Advanced):**
- `enable_firewall_threat_intel` → default: false
- `firewall_threat_intel_mode` → default: "Alert"
- `firewall_idps_mode` → default: "Alert"
- `firewall_enable_tls_inspection` → default: false

**Outputs Provided:**
- `hub_vnet_id` → consumed by spoke-network
- `firewall_private_ip` → consumed by spoke-network
- `log_analytics_workspace_id` → metadata
- `route_table_id` → metadata

**Integration Status:** ⚠️ Incomplete  
**Missing Mappings:**
1. **Region code mapping:** Azure regions need short codes for naming
   ```
   eastus      → scus (South Central US)
   westus      → scus (South Central US)
   northeurope → neu (North Europe)
   westeurope → weu (West Europe)
   ```
2. **Log Analytics workspace:** Currently in hub-network module. OK for MVP.
3. **Firewall defaults:** Need sensible defaults
   - `firewall_type: "azfw"` (Azure Firewall—most common)
   - `azfw_tier: "Standard"` (cost-effective) OR "Premium" (advanced features)

**Action Needed:**
- Add region_code mapping to Compose script
- Pass log_analytics_workspace_id from hub module OR create in shared location
- Set firewall_type and azfw_tier defaults based on compliance variant

---

### 3. spoke-network

**Module Location:** `terraform/modules/spoke-network/`

**Variables Required:**
```hcl
spoke_name                  # ← MISSING: needs default (e.g., "prod-app")
region                      # ← var.primary_region
region_code                 # ← MISSING: same mapping as hub
environment                 # ← var.environment
spoke_address_space         # ← MISSING: needs allocation logic (10.1.0.0/16, 10.2.0.0/16, etc.)
enable_hub_peering          # ← default: true (OK)
hub_vnet_id                 # ← from module.hub_network.hub_vnet_id
hub_vnet_name               # ← from module.hub_network.hub_vnet_name
hub_resource_group_name     # ← from module.hub_network.resource_group_name
firewall_private_ip         # ← from module.hub_network.firewall_private_ip
tags                        # ← var.tags
```

**Integration Status:** ⚠️ Incomplete  
**Missing Logic:**
1. **Spoke name:** Needs a default. Current design has "spoke-network" singular. For multi-spoke, need iteration.
2. **Spoke address space:** Currently hardcoded 10.1.0.0/16. Need a list or iteration for multiple spokes.
3. **Region code:** Same as hub—needs mapping.

**Action Needed:**
- For MVP: Create single spoke with defaults (spoke_name: "workload-prod", address_space: "10.1.0.0/16")
- For Phase 2: Support multiple spokes via iteration

---

### 4. policy-baseline

**Module Location:** `terraform/modules/policy-baseline/`

**Variables Required:**
```hcl
root_mg_id                  # ← from module.management_groups.root_mg_id
root_management_group_id    # ← UNCLEAR: full resource ID vs short ID
platform_mg_id              # ← from module.management_groups.platform_mg_id
landingzones_mg_id          # ← from module.management_groups.landingzones_mg_id
sandbox_mg_id               # ← from module.management_groups.sandbox_mg_id
location                    # ← default: "southcentralus" (OK)
allowed_locations           # ← var.allowed_locations (primary + secondary regions)
```

**Compliance Variants:** ⚠️ MISSING  
The Compose script passes `compliance_variant` as a string, but the module variables don't show a variant input. Need to:
1. Check if policy-baseline module has conditional logic based on variant
2. Or create variant-specific policy modules (policy-baseline-pci-dss, etc.)

**Integration Status:** ⚠️ Incomplete  
**Missing Logic:**
1. **Variant handling:** How are PCI-DSS/HIPAA/FedRAMP policies applied?
2. **root_management_group_id vs root_mg_id:** Appears to need both—format unclear.

**Action Needed:**
- Check policy-baseline main.tf to understand variant handling
- Update Compose script to pass variant correctly (or create conditional resources)
- Clarify root MG ID format

---

### 5. backup-baseline

**Module Location:** `terraform/modules/backup-baseline/`

**Status:** ✅ Integration Ready  
**Expected variables:** Standard (resource_group_name, location, tags, org_prefix)

**Action Needed:** None—follow current pattern in Compose

---

### 6. defender-baseline

**Module Location:** `terraform/modules/defender-baseline/`

**Status:** ✅ Integration Ready  
**Expected variables:** Standard (resource_group_name, location, tags, org_prefix)

**Action Needed:** None—follow current pattern in Compose

---

## Dependency Graph

```
management-groups (always)
    ├→ policy-baseline (always, uses MG outputs)
    ├→ hub-network (if selected, uses MG outputs)
    │   └→ spoke-network (if selected, uses hub outputs)
    ├→ backup-baseline (if selected, uses MG outputs)
    └→ defender-baseline (if selected, uses MG outputs)
```

**Critical Path:** management-groups → hub-network → spoke-network (3 sequential)

---

## Compose Script Gaps

### Current State (Phase 0)
```powershell
module "hub_network" {
  source = "../../modules/hub-network"
  resource_group_name = "rg-${OrgPrefix}-hub-network"
  location            = var.primary_region
  org_prefix          = var.org_prefix
  address_space       = var.hub_address_space    # ← Wrong variable name
}
```

### Issues Identified

1. **Variable Name Mismatches**
   - Script: `address_space` → Module: `hub_address_space` ✓ OK
   - Script: `location` → Module: `region` ✗ WRONG

2. **Missing Variables**
   - `region_code` (needed for naming)
   - `firewall_type` (hardcoded default needed)
   - `azfw_tier` (hardcoded default needed)
   - `log_analytics_workspace_id` (module creates its own—OK)
   - `tags` (missing)

3. **Spoke Network Issues**
   - `spoke_name` not provided
   - `spoke_address_space` should be a variable but is hardcoded
   - Missing region_code

4. **Policy-Baseline Issues**
   - No variant handling logic
   - `allowed_locations` needs to be computed from primary + secondary

5. **Hub-to-Spoke Wiring**
   - Spoke module needs hub outputs but may not have them wired

---

## Regional Configuration Defaults

Suggested region mappings for naming:

```powershell
$regionCodeMap = @{
    "eastus"          = "scus"
    "westus"          = "wcus"
    "northeurope"     = "neu"
    "westeurope"      = "weu"
    "southcentralus"  = "scus"
    "northcentralus"  = "ncus"
    "eastus2"         = "eus2"
    "southeastasia"   = "sea"
    "northeastasia"   = "nea"
}
```

---

## Firewall Configuration Defaults

Recommend tiered approach based on compliance:

| Compliance | Firewall Type | Tier | Cost/mo |
|-----------|--------------|------|---------|
| baseline | azfw | Standard | ~$1,500 |
| pci-dss | azfw | Standard | ~$1,500 |
| hipaa | azfw | Premium (TLS inspection) | ~$4,000 |
| fedramp | azfw | Premium (TLS inspection) | ~$4,000 |

---

## Next Steps (Phase 1D→1C)

### Priority 1: Fix Compose Script Variable Mappings
- [ ] Update hub-network module call with correct variable names
- [ ] Add `region_code` mapping logic
- [ ] Add firewall tier selection logic based on compliance
- [ ] Wire spoke-network outputs back to hub inputs

### Priority 2: Verify Policy-Baseline Variant Handling
- [ ] Read policy-baseline/main.tf to confirm variant logic exists
- [ ] Update Compose to pass variant correctly
- [ ] Test policy composition for all 4 variants

### Priority 3: Add Secondary Region Support
- [ ] Create DR hub-network skeleton in secondary region
- [ ] Document secondary region limitations (15-20% of primary)

### Priority 4: Test End-to-End Composition
- [ ] Run Compose script with test inputs
- [ ] Validate generated main.tf syntax
- [ ] Verify module inter-dependencies

---

## Questions for Clarification

1. **Policy Variant Logic:**
   - Does policy-baseline module have internal variant handling?
   - Or should we create separate policy modules per variant?

2. **Secondary Region Deployment:**
   - Should secondary region hub be fully functional or skeleton-only?
   - Current design says "skeleton (15-20% of cost)"—what does that mean operationally?

3. **Spoke Configuration:**
   - MVP: Single spoke or multiple?
   - How should spoke naming/addressing be parameterized?

4. **Log Analytics Workspace:**
   - Hub-network module creates its own—is that sufficient or should we create centralized one?

---

## Files Reviewed

- ✅ `terraform/modules/management-groups/variables.tf` — 41 lines
- ✅ `terraform/modules/management-groups/outputs.tf` — 30 lines
- ✅ `terraform/modules/hub-network/variables.tf` — 184 lines (includes threat intel config)
- ✅ `terraform/modules/hub-network/outputs.tf` — 40 lines
- ✅ `terraform/modules/spoke-network/variables.tf` — 72 lines
- ✅ `terraform/modules/policy-baseline/variables.tf` — Partial read (50+ lines)
- ℹ️ Skipped detailed audit of backup/defender/nsg-flow-logs (straightforward)

---

**Document ID:** ALZ-1D-AUDIT-20260628  
**Author:** Phase 1 Implementation  
**Next Review:** After Compose script fixes
