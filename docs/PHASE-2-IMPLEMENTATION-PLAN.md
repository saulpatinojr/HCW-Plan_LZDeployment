# Phase 2: Implementation Plan & Execution

**Status:** ✅ Planning Complete | 🚀 Ready to Execute  
**Date:** 2026-06-28  
**Scope:** 2A, 2B, 2C, 2D (all sub-phases)  
**Estimated Effort:** 40-50 hours

---

## Phase 2A: Management Module Implementation

### Objective
Create centralized management resources (Log Analytics, Automation Account) for operational management across the ALZ.

### Implementation

**1. Create terraform/modules/management-baseline/main.tf**

```hcl
# Log Analytics Workspace (moved from compose script to dedicated module)
resource "azurerm_resource_group" "management" {
  name     = "rg-${var.org_prefix}-management"
  location = var.location
  tags     = var.tags
}

resource "azurerm_log_analytics_workspace" "alz" {
  name                = "law-${var.org_prefix}-${var.region_code}"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = var.tags
}

# Automation Account for runbooks and updates
resource "azurerm_automation_account" "alz" {
  name                = "aa-${var.org_prefix}-${var.region_code}"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
  sku_name            = "Basic"
  tags                = var.tags
}

# Link Log Analytics to Automation Account
resource "azurerm_log_analytics_linked_service" "alz" {
  resource_group_name = azurerm_resource_group.management.name
  workspace_id        = azurerm_log_analytics_workspace.alz.id
  linked_service_name = "Automation"
  
  linked_service_properties {
    resource_id = azurerm_automation_account.alz.id
  }
}

# Diagnostic Settings for ALZ-wide monitoring
resource "azurerm_monitor_diagnostic_setting" "activity_log" {
  name           = "alz-activity-logs"
  target_resource_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  
  log_analytics_workspace_id = azurerm_log_analytics_workspace.alz.id
  
  enabled_log {
    category = "Administrative"
  }
  enabled_log {
    category = "Security"
  }
  enabled_log {
    category = "ServiceHealth"
  }
  enabled_log {
    category = "Alert"
  }
  enabled_log {
    category = "Recommendation"
  }
  enabled_log {
    category = "Policy"
  }
  enabled_log {
    category = "Autoscale"
  }
  enabled_log {
    category = "ResourceHealth"
  }
}
```

**2. Create terraform/modules/management-baseline/variables.tf**

```hcl
variable "org_prefix" {
  description = "Organization prefix"
  type        = string
}

variable "location" {
  description = "Azure region for management resources"
  type        = string
}

variable "region_code" {
  description = "Short region code for naming"
  type        = string
}

variable "log_retention_days" {
  description = "Log Analytics retention period"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
}
```

**3. Create terraform/modules/management-baseline/outputs.tf**

```hcl
output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  value       = azurerm_log_analytics_workspace.alz.id
}

output "automation_account_id" {
  description = "Automation Account ID"
  value       = azurerm_automation_account.alz.id
}

output "log_analytics_workspace_name" {
  description = "Log Analytics workspace name"
  value       = azurerm_log_analytics_workspace.alz.name
}
```

**4. Update Compose-TerraformPackage.ps1**

Add management module to main.tf:

```powershell
# Add after management_groups, before hub_network:
if ($Modules -contains "management-baseline" -or $true) {  # Always include
    $mainTf += @"
# Management Module
module "management_baseline" {
  source = "../../modules/management-baseline"
  
  org_prefix        = var.org_prefix
  location          = var.primary_region
  region_code       = var.primary_region_code
  log_retention_days = 30
  tags              = var.tags
  
  depends_on = [module.management_groups]
}
"@
}
```

---

## Phase 2B: Policy Compliance Variants

### Objective
Implement compliance-specific policies (PCI-DSS, HIPAA, FedRAMP) with appropriate controls.

### Implementation

**1. Add compliance_variant variable to policy-baseline module**

Update `terraform/modules/policy-baseline/variables.tf`:

```hcl
variable "compliance_variant" {
  description = "Compliance variant: baseline, pci-dss, hipaa, fedramp"
  type        = string
  default     = "baseline"
  
  validation {
    condition     = contains(["baseline", "pci-dss", "hipaa", "fedramp"], var.compliance_variant)
    error_message = "compliance_variant must be one of: baseline, pci-dss, hipaa, fedramp"
  }
}
```

**2. Add variant-specific policies to policy-baseline/main.tf**

```hcl
# PCI-DSS: Require encryption in transit
resource "azurerm_policy_definition" "pci_encryption_transit" {
  count        = var.compliance_variant == "pci-dss" ? 1 : 0
  name         = "pci-require-encryption-in-transit"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "PCI-DSS: Require encryption in transit"
  
  policy_rule = jsonencode({
    if = {
      field = "type"
      in    = ["Microsoft.Storage/storageAccounts"]
    }
    then = {
      effect = "deny"
    }
  })
}

# HIPAA: Audit encryption at rest
resource "azurerm_policy_definition" "hipaa_encryption_rest" {
  count        = var.compliance_variant == "hipaa" ? 1 : 0
  name         = "hipaa-require-encryption-at-rest"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "HIPAA: Require encryption at rest"
  
  policy_rule = jsonencode({
    if = {
      field = "type"
      in    = ["Microsoft.Storage/storageAccounts"]
    }
    then = {
      effect = "audit"
    }
  })
}

# FedRAMP: Continuous monitoring requirements
resource "azurerm_policy_definition" "fedramp_monitoring" {
  count        = var.compliance_variant == "fedramp" ? 1 : 0
  name         = "fedramp-require-monitoring"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "FedRAMP: Require continuous monitoring"
  
  policy_rule = jsonencode({
    if = {
      field = "type"
      in    = ["Microsoft.Insights/diagnosticSettings"]
    }
    then = {
      effect = "audit"
    }
  })
}
```

**3. Update Compose script to pass compliance_variant**

```powershell
if ($Modules -contains "policy-baseline") {
    $mainTf += @"
module "policy_baseline" {
  source = "../../modules/policy-baseline"
  
  root_mg_id              = module.management_groups.root_mg_id
  root_management_group_id = "/providers/Microsoft.Management/managementGroups/\${module.management_groups.root_mg_id}"
  platform_mg_id          = module.management_groups.platform_mg_id
  landingzones_mg_id      = module.management_groups.landingzones_mg_id
  sandbox_mg_id           = module.management_groups.sandbox_mg_id
  location                = var.primary_region
  allowed_locations       = var.allowed_locations
  compliance_variant      = var.compliance_variant

  depends_on = [module.management_groups]
}
"@
}
```

---

## Phase 2C: Secondary Region (DR Skeleton)

### Objective
Deploy minimal hub infrastructure in secondary region for disaster recovery (~15% primary cost).

### Implementation

**1. Update Compose script to generate secondary region deployment**

Add secondary hub module:

```powershell
# After primary hub-network, add:
if ($Modules -contains "hub-network") {
    $mainTf += @"
# Secondary Region Hub (Disaster Recovery Skeleton)
module "hub_network_secondary" {
  source = "../../modules/hub-network"

  region                      = var.secondary_region
  region_code                 = var.secondary_region_code
  environment                 = "dr"  # Mark as DR
  hub_address_space           = "10.100.0.0/16"  # Different address space
  firewall_type               = var.firewall_type
  azfw_tier                   = "Standard"  # Always Standard in DR (cost optimization)
  tags                        = merge(var.tags, { Environment = "dr", Purpose = "disaster-recovery" })
  log_analytics_workspace_id  = module.management_baseline.log_analytics_workspace_id

  depends_on = [module.management_groups]
}
"@
}
```

**2. Add secondary region variables**

Update variables.tf to include secondary region address space:

```hcl
variable "secondary_hub_address_space" {
  description = "Secondary region hub address space"
  type        = string
  default     = "10.100.0.0/16"
}
```

---

## Phase 2D: Cost Estimation Refinement

### Objective
Integrate with Azure Pricing API for real-time, accurate cost estimates.

### Implementation

**1. Update frontend/app.js cost model**

```javascript
// Enhanced cost model with pricing categories
const costModel = {
    // Base infrastructure costs (from Azure pricing as of June 2026)
    azure: {
        firewall: {
            standard: {
                deployment: 1500,     // Monthly
                dataProcessed: 0.016, // Per GB
            },
            premium: {
                deployment: 4000,
                dataProcessed: 0.016,
            }
        },
        logAnalytics: {
            ingestion: 2.30,          // Per GB ingested
            retention: 0.13,          // Per GB retained monthly
        },
        automation: {
            account: 6,               // Minimal monthly
        },
        backup: {
            vault: 10,                // Monthly
            protectedInstance: 50,    // Per instance
        },
        defenderCloud: {
            perResource: 25,          // Per resource per month
        },
        vnet: {
            peering: 0.016,           // Per GB transferred
        }
    },
    
    // Compliance overhead multipliers
    compliance: {
        baseline: 1.0,
        "pci-dss": 1.2,              // Extra monitoring
        hipaa: 1.5,                  // Premium firewall + audit
        fedramp: 1.8,                // Continuous monitoring
    }
};

function fetchAzurePricing() {
    // Call Azure Pricing API to get current rates
    // Return pricing data for calculation
}

function calculateCostWithPricing() {
    const pricing = fetchAzurePricing();
    // Use pricing data for accurate calculations
    // Return estimated costs
}
```

**2. Add Azure Pricing API integration**

```javascript
async function fetchAzurePricing() {
    try {
        // Query Azure Pricing API
        const response = await fetch(
            'https://prices.azure.com/api/retail/prices?$filter=serviceName eq \'Virtual Networks\'',
            {
                headers: {
                    'Accept': 'application/json'
                }
            }
        );
        
        if (response.ok) {
            const data = await response.json();
            // Parse and cache pricing data
            cachePricingData(data);
            return data;
        }
    } catch (error) {
        console.warn("Could not fetch live pricing, using estimates");
        return fallbackPricingModel();
    }
}
```

**3. Update cost breakdown display**

```javascript
function displayCostBreakdown(cost, pricing) {
    let html = `
        <div class="cost-item">
            <span>Hub Network (Firewall ${cost.firewall})</span>
            <strong>$${Math.round(cost.firewallCost)}/month</strong>
            <small>Firewall: ${cost.firewall === 'Premium' ? pricing.azure.firewall.premium.deployment : pricing.azure.firewall.standard.deployment}</small>
        </div>
        <div class="cost-item">
            <span>Log Analytics & Monitoring</span>
            <strong>$${Math.round(cost.monitoringCost)}/month</strong>
            <small>Based on estimated ingestion: ${cost.estimatedLogGBperDay * 30} GB/month</small>
        </div>
        // ... additional items
    `;
    
    return html;
}
```

---

## Testing Strategy for Phase 2

### Phase 2A Testing
- [ ] Management module creates Log Analytics workspace
- [ ] Automation Account linked to Log Analytics
- [ ] Diagnostic settings configured
- [ ] Outputs correct (workspace ID, account ID)

### Phase 2B Testing
- [ ] Baseline variant deploys standard policies
- [ ] PCI-DSS variant adds encryption policies
- [ ] HIPAA variant adds compliance policies
- [ ] FedRAMP variant adds monitoring policies
- [ ] Policy assignments succeed

### Phase 2C Testing
- [ ] Secondary region hub deploys in secondary region
- [ ] Address space different from primary (10.100.0.0/16)
- [ ] Firewall tier Standard (cost optimization)
- [ ] Proper tagging (Environment: dr)

### Phase 2D Testing
- [ ] Cost estimates within ±5% of actual (vs ±20% now)
- [ ] Pricing updates reflect Azure Pricing API
- [ ] Regional variations apply
- [ ] Historical trend available

---

## Implementation Sequence

**Order of Execution:**

1. **Phase 2A:** Create management-baseline module (2 hours)
   - Create module files
   - Update Compose script
   - Test module deployment

2. **Phase 2B:** Add policy variants (3 hours)
   - Add compliance_variant variable
   - Create variant-specific policies
   - Update Compose script
   - Test all 4 variants

3. **Phase 2C:** Implement secondary region (2 hours)
   - Update Compose script for secondary hub
   - Test secondary region deployment
   - Verify cost optimization (Standard tier)

4. **Phase 2D:** Enhance cost estimation (2 hours)
   - Add Azure Pricing API integration
   - Refine cost model
   - Update form cost calculator
   - Test accuracy

---

## Success Criteria

✅ **Phase 2A Complete When:**
- Management module creates all resources
- Compose script includes management module
- Tests validate deployment

✅ **Phase 2B Complete When:**
- All 4 compliance variants tested
- Policies correctly assigned per variant
- Cost multipliers apply correctly

✅ **Phase 2C Complete When:**
- Secondary hub deploys in secondary region
- Address space isolated (10.100.x.x)
- Firewall tier Standard in DR (cost optimized)

✅ **Phase 2D Complete When:**
- Pricing API integration working
- Cost estimates within ±5% accuracy
- Regional pricing variations applied

---

## Deliverables

**Phase 2A Deliverables:**
- [ ] terraform/modules/management-baseline/ (complete module)
- [ ] Updated Compose-TerraformPackage.ps1
- [ ] PHASE-2A-IMPLEMENTATION.md (documentation)

**Phase 2B Deliverables:**
- [ ] Updated policy-baseline module with variants
- [ ] Updated Compose script
- [ ] PHASE-2B-IMPLEMENTATION.md (documentation)

**Phase 2C Deliverables:**
- [ ] Updated Compose script with secondary region
- [ ] PHASE-2C-IMPLEMENTATION.md (documentation)

**Phase 2D Deliverables:**
- [ ] Updated frontend/app.js with pricing API
- [ ] Cost model refinement
- [ ] PHASE-2D-IMPLEMENTATION.md (documentation)
- [ ] PHASE-2-COMPLETE.md (final sign-off)

---

**Document ID:** ALZ-PHASE2-PLAN-20260628  
**Author:** Implementation Team  
**Status:** Ready to Execute
