# Azure Verified Modules Implementation Strategy

**Date**: June 30, 2026  
**Owner**: Platform Engineering  
**Status**: IN PROGRESS  
**Target Completion**: July 15, 2026

## Executive Summary

This document outlines the strategy to achieve full Azure Verified Modules (AVM) compliance across all Terraform modules in the HCW-Demo-LZDeployment project. Compliance with AVM standards ensures:

- ✅ Consistency across modules
- ✅ Maintainability and quality
- ✅ Certification readiness
- ✅ Community contribution eligibility
- ✅ Supply chain security

---

## Current State Assessment

### ✅ Compliant Modules

| Module | Status | Notes |
|--------|--------|-------|
| `sandbox` | 🟢 FIXED | Removed provider block (TFNFR27 violation); now AVM-ready |

### 🔄 Partially Compliant (Missing terraform.tf)

| Module | Missing Files | Priority |
|--------|---------------|----------|
| `backup-baseline` | `terraform.tf` | HIGH |
| `defender-baseline` | `terraform.tf` | HIGH |
| `hub-network` | `terraform.tf` | HIGH |
| `keyvault-cmk` | `terraform.tf` | HIGH |
| `management-baseline` | `terraform.tf` | HIGH |
| `management-groups` | `terraform.tf` | HIGH |
| `nsg-flow-logs` | `terraform.tf` | HIGH |
| `policy-baseline` | `terraform.tf` | HIGH |
| `sentinel-siem` | `terraform.tf` | HIGH |
| `spoke-network` | `terraform.tf` | HIGH |

### Additional Compliance Checks Needed

All modules require verification against:

- [ ] **TFNFR4**: Lower snake_casing
- [ ] **TFNFR6-9**: Resource/module ordering
- [ ] **TFNFR15-24**: Variable requirements
- [ ] **TFFR2, TFNFR29-30**: Output requirements
- [ ] **TFNFR31-33**: Local value standards
- [ ] **TFNFR34-35**: Breaking changes handling
- [ ] **TFNFR2**: `.terraform-docs.yml` present

---

## Phase 1: Critical Foundation (Week 1)

### Task 1.1: Create terraform.tf for All Modules

**Objective**: Establish required version constraints across all modules (TFNFR25, TFNFR26)

**Template for terraform.tf**:

```hcl
terraform {
  required_version = "~> 1.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}
```

**Optional** (only if module uses Azapi):

```hcl
terraform {
  required_version = "~> 1.6"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}
```

**Modules to Update**:
- [ ] `backup-baseline`
- [ ] `defender-baseline`
- [ ] `hub-network`
- [ ] `keyvault-cmk`
- [ ] `management-baseline`
- [ ] `management-groups`
- [ ] `nsg-flow-logs`
- [ ] `policy-baseline`
- [ ] `sentinel-siem`
- [ ] `spoke-network`

**Validation**:
```bash
terraform validate
terraform fmt -recursive .
```

---

### Task 1.2: Remove Provider Declarations from Modules (TFNFR27)

**Objective**: Ensure no `provider` blocks in modules (except `configuration_aliases`)

**What to Fix**:

1. Search for `provider "azurerm"` blocks in each module
2. Remove entire provider blocks (except in terraform.tf)
3. Verify module calls at root level have provider configuration

**Command to Find Violations**:

```bash
grep -r "^provider \"azurerm\"" terraform/modules/
```

**Expected Result**: No output (no violations)

**Modules to Check**:
- [x] sandbox (already fixed)
- [ ] All other modules

---

### Task 1.3: Create .terraform-docs.yml in All Modules (TFNFR2)

**Objective**: Enable automatic documentation generation

**Template `.terraform-docs.yml`**:

```yaml
---
formatter: markdown table

header-from: main.tf
footer-from: ""

sections:
  inputs: true
  outputs: true
  modules: false
  resources: true
  providers: true
  requirements: true

sort:
  by: required
  
output:
  file: README.md
  mode: overwrite
```

**Modules to Create**:
- [ ] `backup-baseline`
- [ ] `defender-baseline`
- [ ] `hub-network`
- [ ] `keyvault-cmk`
- [ ] `management-baseline`
- [ ] `management-groups`
- [ ] `nsg-flow-logs`
- [ ] `policy-baseline`
- [ ] `sentinel-siem`
- [ ] `spoke-network`

**Generate Documentation**:

```bash
terraform-docs .
```

---

## Phase 2: Variables & Outputs Compliance (Week 2)

### Task 2.1: Audit All Variables (TFNFR15-24)

**Checklist for Each Variable**:

- [ ] Uses lower snake_casing (TFNFR4)
- [ ] Has precise `type` definition (TFNFR18)
- [ ] No `any` type unless justified (TFNFR18)
- [ ] Has descriptive `description` (TFNFR17)
- [ ] Collections have `nullable = false` (TFNFR20)
- [ ] No `nullable = true` unless semantic need (TFNFR21)
- [ ] No `sensitive = false` declarations (TFNFR22)
- [ ] Feature toggles use positive naming: `xxx_enabled` (TFNFR16)
- [ ] Variables ordered: required then optional, both alphabetical (TFNFR15)

**Common Issues to Fix**:

1. **Missing nullable declarations on collections**:
   ```hcl
   # BAD
   variable "tags" {
     type = map(string)
   }

   # GOOD
   variable "tags" {
     type     = map(string)
     nullable = false
     default  = {}
   }
   ```

2. **Imprecise types**:
   ```hcl
   # BAD
   variable "enabled" {
     type = string  # "true" / "false"
   }

   # GOOD
   variable "enabled" {
     type = bool
   }
   ```

3. **Missing descriptions**:
   ```hcl
   # BAD
   variable "name" {
     type = string
   }

   # GOOD
   variable "name" {
     description = "The name of the resource"
     type        = string
   }
   ```

**Modules to Audit**: All 10 modules

---

### Task 2.2: Audit All Outputs (TFFR2, TFNFR29-30)

**Checklist for Each Output**:

- [ ] Uses anti-corruption layer pattern (TFFR2)
  - Outputs *computed* attributes, not raw resource objects
- [ ] Sensitive data marked with `sensitive = true` (TFNFR29)
- [ ] Does not output input values (except `name`) (TFFR2)
- [ ] For `for_each` resources, outputs are maps (TFFR2)

**Common Patterns**:

```hcl
# GOOD: Discrete attribute output
output "resource_id" {
  description = "The ID of the created resource"
  value       = azurerm_xxx.this.id
}

# GOOD: for_each resources as map
output "resource_ids" {
  description = "Map of resource IDs keyed by name"
  value = {
    for key, res in azurerm_xxx.this : key => res.id
  }
}

# BAD: Entire resource (might contain sensitive data)
output "resource" {
  value = azurerm_xxx.this
}
```

**Modules to Audit**: All 10 modules

---

## Phase 3: Code Style & Ordering (Week 2-3)

### Task 3.1: Verify Resource/Module Ordering (TFNFR6-9)

**Checklist**:

- [ ] Resources with dependencies appear after their dependencies (TFNFR6)
- [ ] Resources ordered: depended-on first, then dependents (TFNFR6)
- [ ] Within each resource block: meta-args (top), args (middle, alphabetical), meta-args (bottom) (TFNFR8)
- [ ] For dynamic blocks: use `for_each = condition ? [item] : []` pattern (TFNFR12)

**Example Resource Ordering**:

```hcl
# 1. First: dependencies
resource "azurerm_resource_group" "this" {
  # ...
}

# 2. Then: resources that depend on the RG
resource "azurerm_storage_account" "this" {
  resource_group_name  = azurerm_resource_group.this.name
  # ...
}
```

---

### Task 3.2: Verify Local Values (TFNFR31-33)

**Checklist**:

- [ ] `locals` in separate `locals.tf` or adjacent to resources (TFNFR31)
- [ ] Expressions alphabetically arranged (TFNFR32)
- [ ] Precise types where applicable (TFNFR33)

**Good Example**:

```hcl
locals {
  common_tags = merge(var.tags, {
    managed_by = "terraform"
    module     = "hub-network"
  })
  
  firewall_enabled = var.create_firewall ? 1 : 0
  
  vnet_config = {
    address_space = var.address_space
    location      = var.location
  }
}
```

---

## Phase 4: Breaking Changes & Feature Toggles (Week 3)

### Task 4.1: Document Feature Toggles (TFNFR34)

**Objective**: New resources added in future versions must have toggles

**Pattern**:

```hcl
variable "create_route_table" {
  description = "Whether to create the route table"
  type        = bool
  default     = false
  nullable    = false
}

resource "azurerm_route_table" "this" {
  count = var.create_route_table ? 1 : 0
  # ...
}
```

**Review Existing Optional Resources**:

- [ ] Are new resources behind toggles?
- [ ] Do toggles have clear descriptions?
- [ ] Are defaults safe (false/empty)?

---

### Task 4.2: Review Potential Breaking Changes (TFNFR35)

**Potential Breaking Changes to Document**:

1. **Resource blocks**:
   - Adding new resource without conditional creation
   - Adding arguments with non-default values
   - Renaming resources without `moved` blocks
   - Changing `count` to `for_each`

2. **Variable/Output blocks**:
   - Deleting/renaming variables
   - Changing variable type or default
   - Changing `nullable` from true to false
   - Changing `sensitive` from false to true

**Create CHANGELOG**:

For each module, create `CHANGELOG.md`:

```markdown
# Changelog

## [1.0.0] - 2026-06-30

### Added
- Initial module release
- Feature toggles for optional resources

### Changed
- None

### Removed
- None

### Security
- All provider versions pinned
```

---

## Phase 5: Testing & Validation (Week 3-4)

### Task 5.1: Validate All Modules

**Terraform Validation**:

```bash
terraform -chdir=terraform/modules/sandbox validate
terraform -chdir=terraform/modules/backup-baseline validate
# ... repeat for all modules
```

**Formatting**:

```bash
terraform fmt -recursive terraform/modules/
```

**tflint**:

```bash
# Install: tflint
tflint --init
tflint --recursive terraform/modules/
```

**Checkov** (security scanning):

```bash
checkov -d terraform/modules/ --framework terraform
```

---

### Task 5.2: Documentation Generation

```bash
# Generate docs for all modules
for dir in terraform/modules/*/; do
  terraform-docs "$dir"
done
```

**Verify**:
- [ ] README.md generated in each module
- [ ] All variables documented
- [ ] All outputs documented
- [ ] All providers listed

---

## Implementation Checklist

### Week 1
- [ ] Create terraform.tf for all 10 modules
- [ ] Remove any provider blocks from modules
- [ ] Create .terraform-docs.yml in all modules
- [ ] Run terraform validate on all modules
- [ ] Run terraform fmt on all modules

### Week 2
- [ ] Audit and fix all variables (TFNFR15-24)
- [ ] Audit and fix all outputs (TFFR2, TFNFR29-30)
- [ ] Run tflint on all modules
- [ ] Generate terraform-docs for all modules

### Week 3
- [ ] Verify resource/module ordering (TFNFR6-9)
- [ ] Verify local values (TFNFR31-33)
- [ ] Document feature toggles (TFNFR34)
- [ ] Document breaking changes (TFNFR35)
- [ ] Create CHANGELOG for each module

### Week 4
- [ ] Final validation (terraform validate)
- [ ] Security scan (checkov)
- [ ] Documentation review
- [ ] Update TODO.md with completion status

---

## Compliance Verification

Use this script to verify AVM compliance:

```bash
#!/bin/bash

echo "=== AVM Compliance Check ==="

for module_dir in terraform/modules/*/; do
  module_name=$(basename "$module_dir")
  echo ""
  echo "Checking $module_name..."
  
  # Check terraform.tf exists
  if [ ! -f "$module_dir/terraform.tf" ]; then
    echo "  ❌ Missing terraform.tf"
  else
    echo "  ✅ terraform.tf present"
  fi
  
  # Check .terraform-docs.yml exists
  if [ ! -f "$module_dir/.terraform-docs.yml" ]; then
    echo "  ❌ Missing .terraform-docs.yml"
  else
    echo "  ✅ .terraform-docs.yml present"
  fi
  
  # Check no provider blocks in modules
  if grep -q "^provider \"" "$module_dir"/*.tf 2>/dev/null; then
    echo "  ❌ Found provider block (violates TFNFR27)"
  else
    echo "  ✅ No provider blocks"
  fi
  
  # Check for terraform fmt compliance
  if terraform fmt -check "$module_dir" &>/dev/null; then
    echo "  ✅ terraform fmt compliant"
  else
    echo "  ❌ terraform fmt issues found"
  fi
  
  # Check for validation
  if terraform -chdir="$module_dir" validate &>/dev/null; then
    echo "  ✅ terraform validate passed"
  else
    echo "  ❌ terraform validate failed"
  fi
done
```

---

## Related Documentation

- [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/)
- [AVM Terraform Requirements](https://azure.github.io/Azure-Verified-Modules/specs/terraform/)
- [Project TODO.md](../TODO.md)
- [Task 1.3 Completion Report](../TASK-1.3-COMPLETION-REPORT.md)

---

## Next Steps

1. **Immediate (Today)**: Create terraform.tf for all remaining modules
2. **This Week**: Run full AVM compliance audit
3. **Next Week**: Fix all identified compliance issues
4. **End of Month**: Full validation and documentation generation

---

**Last Updated**: June 30, 2026  
**Next Review**: July 7, 2026  
**Owner**: Platform Engineering Team
