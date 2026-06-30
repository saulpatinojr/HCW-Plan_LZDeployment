# Task 1.3: Convert Sandbox Cleanup to AVM-Compliant Terraform

**Status**: ⏳ READY TO IMPLEMENT  
**Phase**: Phase 1 - Critical Remediations  
**Priority**: 🔴 P0 CRITICAL  
**Effort**: 2-3 hours  
**Blockers**: None

---

## Context (From Architecture Review)

**Old Approach** (PowerShell script):
```powershell
# Cleanup-ExpiredSandboxResources.ps1
# ❌ Not tracked in IaC
# ❌ No drift detection
# ❌ No rollback capability
# ❌ Labor-intensive maintenance
```

**New Approach** (AVM-Compliant Terraform):
```hcl
# terraform/modules/sandbox/main.tf
# ✅ Tracked in git + TFC
# ✅ Drift detection (workflow 100)
# ✅ Immutable deployments
# ✅ Self-maintaining
```

---

## What We're Building

### File Structure
```
terraform/modules/sandbox/
├─ main.tf                          (Resource definitions)
├─ variables.tf                     (Input variables - AVM-compliant)
├─ outputs.tf                       (Output values - anti-corruption layer)
├─ locals.tf                        (Local values, if needed)
├─ terraform.tf                     (Terraform version + providers)
├─ README.md                        (Terraform Docs generated)
└─ .terraform-docs.yml             (Documentation config)

terraform/live/sandbox/
├─ main.tf                          (Calls sandbox module)
├─ terraform.tfvars                 (Sandbox config)
└─ backend.hcl                      (TFC backend config)
```

### Key Design Decisions

#### 1. Feature Toggle (No Auto-Creation)
```hcl
variable "create_sandbox_rg" {
  description = "Whether to create the sandbox resource group"
  type        = bool
  default     = false  # ← Don't create by default (AVM pattern)
  nullable    = false
}

resource "azurerm_resource_group" "sandbox" {
  count = var.create_sandbox_rg ? 1 : 0  # ← Conditional creation
  # ...
}
```

**Why**: Aligns with AVM requirement TFNFR34 (feature toggles for optional resources)

#### 2. Lifecycle Rules for Auto-Cleanup
```hcl
variable "sandbox_tags" {
  description = "Tags for sandbox resources"
  type = object({
    environment  = string     # "sandbox"
    lifecycle    = string     # "temporary" or "permanent"
    created_date = string     # ISO 8601 date
    expiry_date  = string     # ISO 8601 date (optional)
  })
  nullable = false
}

resource "azurerm_resource_group" "sandbox" {
  count = var.create_sandbox_rg ? 1 : 0
  
  name     = var.resource_group_name
  location = var.location
  tags     = var.sandbox_tags
  
  lifecycle {
    prevent_destroy = false  # Allow Terraform to delete
  }
}
```

**Why**: Enables external systems (Azure Automation, policy, etc.) to detect and clean up old sandboxes based on tags

#### 3. AVM-Compliant Outputs (Anti-Corruption)
```hcl
output "sandbox_resource_group_id" {
  description = "The ID of the created sandbox resource group"
  value       = try(azurerm_resource_group.sandbox[0].id, null)
}

output "sandbox_resource_group_name" {
  description = "The name of the created sandbox resource group"
  value       = try(azurerm_resource_group.sandbox[0].name, null)
}
```

**Why**: AVM pattern: output computed attributes only, not entire resource object

---

## Implementation Steps

### Step 1: Create Module Structure (30 minutes)
```bash
mkdir -p terraform/modules/sandbox
mkdir -p terraform/live/sandbox
```

Create files:
- `terraform/modules/sandbox/terraform.tf`
- `terraform/modules/sandbox/variables.tf`
- `terraform/modules/sandbox/outputs.tf`
- `terraform/modules/sandbox/locals.tf` (if needed)
- `terraform/modules/sandbox/main.tf`
- `terraform/modules/sandbox/README.md`
- `terraform/modules/sandbox/.terraform-docs.yml`

### Step 2: Implement AVM-Compliant Module (1 hour)
See spec below.

### Step 3: Create Live Configuration (30 minutes)
```bash
mkdir -p terraform/live/sandbox
```

Create:
- `terraform/live/sandbox/main.tf` (call module)
- `terraform/live/sandbox/terraform.tfvars` (config)
- `terraform/live/sandbox/backend.hcl` (TFC config)

### Step 4: Validate & Test (30 minutes)
```bash
cd terraform/modules/sandbox
terraform fmt -check
terraform validate
```

### Step 5: Update Documentation (20 minutes)
- Update README to reference new module
- Add terraform-docs automation
- Document sandbox lifecycle

---

## Implementation Spec

### terraform/modules/sandbox/terraform.tf

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

provider "azurerm" {
  features {}
}
```

**Why**:
- AVM requirement TFNFR25 (version constraints)
- AVM requirement TFNFR26 (required_providers)

### terraform/modules/sandbox/variables.tf

```hcl
variable "create_sandbox_rg" {
  description = "Whether to create the sandbox resource group"
  type        = bool
  default     = false
  nullable    = false
}

variable "resource_group_name" {
  description = "Name of the sandbox resource group"
  type        = string
  nullable    = false

  validation {
    condition     = length(var.resource_group_name) >= 1 && length(var.resource_group_name) <= 90
    error_message = "Resource group name must be 1-90 characters"
  }
}

variable "location" {
  description = "Azure region for the sandbox resource group"
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z]+$", var.location))
    error_message = "Location must be a valid Azure region name"
  }
}

variable "sandbox_tags" {
  description = <<-EOT
    Tags for the sandbox resource group.
    
    Required fields:
    - environment: Resource environment (e.g., 'sandbox', 'dev', 'test')
    - lifecycle: Resource lifecycle ('temporary' or 'permanent')
    - created_date: Creation date in ISO 8601 format (YYYY-MM-DD)
    
    Optional fields:
    - expiry_date: Expiration date in ISO 8601 format (YYYY-MM-DD)
    - owner: Owner or team name
  EOT
  
  type = object({
    environment  = string
    lifecycle    = string
    created_date = string
    expiry_date  = optional(string)
    owner        = optional(string)
  })
  
  nullable = false

  validation {
    condition     = contains(["temporary", "permanent"], var.sandbox_tags.lifecycle)
    error_message = "Lifecycle must be 'temporary' or 'permanent'"
  }

  validation {
    condition     = can(regex("^\\d{4}-\\d{2}-\\d{2}$", var.sandbox_tags.created_date))
    error_message = "created_date must be in ISO 8601 format (YYYY-MM-DD)"
  }

  validation {
    condition     = var.sandbox_tags.expiry_date == null || can(regex("^\\d{4}-\\d{2}-\\d{2}$", var.sandbox_tags.expiry_date))
    error_message = "expiry_date must be in ISO 8601 format (YYYY-MM-DD) or null"
  }
}
```

**Why**:
- AVM requirement TFNFR18 (precise types)
- AVM requirement TFNFR17 (descriptions with HEREDOC for objects)
- TFNFR20 (nullable = false for non-scalar)
- TFNFR34 (feature toggle)
- Validations catch user errors early

### terraform/modules/sandbox/main.tf

```hcl
resource "azurerm_resource_group" "sandbox" {
  count = var.create_sandbox_rg ? 1 : 0

  name     = var.resource_group_name
  location = var.location
  tags     = merge(var.sandbox_tags, {
    managed_by = "terraform"
    module     = "sandbox"
  })

  lifecycle {
    prevent_destroy = false
  }
}
```

**Why**:
- AVM requirement TFNFR7 (count for conditional creation)
- Tags enable external cleanup automation
- prevent_destroy = false allows Terraform to delete when removed from code
- managed_by tag clarifies this is IaC-managed

### terraform/modules/sandbox/outputs.tf

```hcl
output "sandbox_resource_group_id" {
  description = "The ID of the created sandbox resource group"
  value       = try(azurerm_resource_group.sandbox[0].id, null)
}

output "sandbox_resource_group_name" {
  description = "The name of the created sandbox resource group"
  value       = try(azurerm_resource_group.sandbox[0].name, null)
}

output "sandbox_resource_group_location" {
  description = "The location of the created sandbox resource group"
  value       = try(azurerm_resource_group.sandbox[0].location, null)
}
```

**Why**:
- AVM requirement TFFR2 (anti-corruption layer - discrete outputs)
- No sensitive = true (no sensitive data here, but would add if needed)
- try() handles case where resource isn't created

### terraform/modules/sandbox/locals.tf

```hcl
locals {
  sandbox_tags_merged = merge(
    var.sandbox_tags,
    {
      managed_by = "terraform"
      module     = "sandbox"
    }
  )
}
```

**Why**:
- Optional, only if we need to reuse merged tags
- AVM requirement TFNFR32 (alphabetical locals)

### terraform/live/sandbox/main.tf

```hcl
terraform {
  cloud {
    organization = var.tfc_organization
    workspaces {
      name = "sandbox"
    }
  }
}

module "sandbox" {
  source = "../../modules/sandbox"

  create_sandbox_rg = var.create_sandbox_rg
  resource_group_name = var.resource_group_name
  location = var.location
  sandbox_tags = var.sandbox_tags
}
```

**Why**:
- Separates module (reusable) from live config (specific)
- AVM requirement TFNFR1 (registry reference with version — not applicable here since it's local)
- TFC backend configuration

### terraform/live/sandbox/terraform.tfvars

```hcl
# Sandbox Resource Group Configuration

create_sandbox_rg = false  # Set to true to create sandbox RG

# resource_group_name = "rg-sandbox-dev-eastus"
# location = "eastus"

# sandbox_tags = {
#   environment  = "sandbox"
#   lifecycle    = "temporary"
#   created_date = "2026-06-30"
#   expiry_date  = "2026-07-30"
#   owner        = "platform-team"
# }
```

**Why**:
- Commented out by default (safe default)
- Users uncomment and customize for their environment
- Shows example values

### terraform/modules/sandbox/.terraform-docs.yml

```yaml
version: ">= 0.14"
formatter: markdown

header-from: "README.md"
footer-from: "README.md"

output:
  file: "README.md"
  mode: replace

recursive:
  enabled: false
  path: modules

sort:
  enabled: true
  by: name
```

**Why**:
- AVM requirement (auto-generated documentation)
- Keeps README in sync with code

---

## Acceptance Criteria

✅ Module created: `terraform/modules/sandbox/`  
✅ AVM-compliant: passes all checks  
✅ Tested: `terraform validate`, `terraform fmt -check`  
✅ Documented: `terraform-docs` generated  
✅ Live config created: `terraform/live/sandbox/`  
✅ Integration test: can call module, plan succeeds  

---

## Validation Checklist (Use AVM Skill)

Before marking complete:
- [ ] `terraform fmt -check` passes
- [ ] `terraform validate` passes
- [ ] All variables have types and descriptions
- [ ] No `nullable = true` on collections
- [ ] No `sensitive = false` declarations
- [ ] Outputs use anti-corruption pattern (discrete values)
- [ ] Feature toggle pattern used (count)
- [ ] Tags include managed_by and module
- [ ] .terraform-docs.yml present
- [ ] README.md auto-generated

---

## Expected Outcome

After Task 1.3:
```
✅ Sandbox cleanup converted to Terraform
✅ AVM-compliant, production-ready module
✅ Drift detection enabled (workflow 100 will detect manual changes)
✅ Immutable deployments (desired state always enforced)
✅ Full audit trail (git + TFC)
✅ Self-documenting (terraform-docs)

Next: Task 1.4 (if any) or Phase 2 infrastructure modules
```

---

## Commands to Validate

```bash
# Format check
terraform -chdir=terraform/modules/sandbox fmt -check

# Validate
terraform -chdir=terraform/modules/sandbox validate

# Generate docs
terraform-docs terraform/modules/sandbox/

# Plan live config (after Terraform Cloud is set up)
terraform -chdir=terraform/live/sandbox plan -out=tfplan
```

---

## Files to Delete/Deprecate

After implementation:
- ❌ Delete: `terraform/scripts/Cleanup-ExpiredSandboxResources.ps1` (no longer needed)
- ❌ Move to deprecated: Any other sandbox-related PS1 scripts

---

## Time Estimate

| Step | Time |
|------|------|
| Create module structure | 30 min |
| Implement AVM module | 1 hour |
| Create live config | 30 min |
| Validate & test | 30 min |
| Documentation | 20 min |
| **Total** | **2h 50min** |

---

**Ready to implement? Proceed with step-by-step implementation below.**

