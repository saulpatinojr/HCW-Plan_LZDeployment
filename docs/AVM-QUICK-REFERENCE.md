# AVM Quick Reference Guide

**For**: Terraform developers working on HCW-Demo-LZDeployment modules  
**Status**: June 30, 2026 - Phase 1 Complete  
**Scope**: Azure Verified Modules (AVM) compliance checklist

---

## Compliance At-A-Glance

### ✅ Phase 1: Foundation (COMPLETE)
```
[████████████████████] 100%

✅ TFNFR25/26: terraform.tf with version constraints
✅ TFNFR27: No provider blocks in modules
✅ TFNFR2: .terraform-docs.yml for documentation
```

### 🔄 Phase 2: Variables & Outputs (NEXT)
```
[                    ] 0%

⏳ TFNFR15-24: Variable compliance audit
⏳ TFFR2, TFNFR29-30: Output compliance audit
```

### ⚪ Phase 3: Code Style (FUTURE)
### ⚪ Phase 4: Breaking Changes (FUTURE)

---

## Module Structure Template

```
terraform/modules/my-module/
├── terraform.tf          # ✅ Required (AVM)
├── .terraform-docs.yml   # ✅ Required (AVM)
├── main.tf               # Resource definitions
├── variables.tf          # Input variables
├── outputs.tf            # Output values
├── locals.tf             # (Optional) Local values
├── README.md             # ✅ Auto-generated
└── CHANGELOG.md          # (Recommended)
```

---

## terraform.tf - Standard Template

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

**Key Points**:
- ✅ Always in dedicated `terraform.tf` (not main.tf)
- ✅ First line: `required_version = "~> 1.6"`
- ✅ Only required providers listed
- ✅ Use pessimistic operator: `~>` for version constraints
- ❌ NO provider blocks (that's root module's job)
- ❌ NO provider aliases (unless for configuration_aliases)

---

## variables.tf - Best Practices

### Correct Ordering
```hcl
# 1. Required variables (alphabetical)
variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

# 2. Optional variables (alphabetical)
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
  nullable    = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  nullable    = false
  default     = {}
}
```

### Common Mistakes

❌ **WRONG**: Missing nullable declaration on collections
```hcl
variable "tags" {
  type = map(string)
  # Missing: nullable = false, default = {}
}
```

✅ **RIGHT**: Explicit nullable on collections
```hcl
variable "tags" {
  type     = map(string)
  nullable = false
  default  = {}
}
```

❌ **WRONG**: Using string for boolean
```hcl
variable "enabled" {
  type    = string  # "true" / "false"?
  default = "true"
}
```

✅ **RIGHT**: Use bool type
```hcl
variable "enabled" {
  type    = bool
  default = false
  nullable = false
}
```

❌ **WRONG**: Imprecise types
```hcl
variable "config" {
  type = any  # Too vague!
}
```

✅ **RIGHT**: Precise object types
```hcl
variable "config" {
  type = object({
    enabled     = bool
    environment = string
    retry_count = number
  })
}
```

### Feature Toggle Pattern (TFNFR34)
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

---

## outputs.tf - Best Practices

### Anti-Corruption Layer Pattern (TFFR2)

❌ **WRONG**: Export entire resource
```hcl
output "storage_account" {
  value = azurerm_storage_account.this  # Exposes internals
}
```

✅ **RIGHT**: Export computed attributes only
```hcl
output "storage_account_id" {
  description = "The ID of the created storage account"
  value       = azurerm_storage_account.this.id
}

output "storage_account_name" {
  description = "The name of the created storage account"
  value       = azurerm_storage_account.this.name
}
```

### for_each Outputs

✅ **RIGHT**: Map of resources
```hcl
output "resource_ids" {
  description = "Map of resource IDs keyed by name"
  value = {
    for key, res in azurerm_xxx.this : key => res.id
  }
}
```

### Sensitive Data

✅ **RIGHT**: Mark sensitive outputs
```hcl
output "storage_account_primary_key" {
  description = "The primary access key"
  value       = azurerm_storage_account.this.primary_access_key
  sensitive   = true
}
```

---

## .terraform-docs.yml - Configuration

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

### Generate Documentation
```bash
# Single module
cd terraform/modules/my-module
terraform-docs .

# All modules
for dir in terraform/modules/*/; do
  terraform-docs "$dir"
done
```

---

## Code Style Guidelines (TFNFR4-13)

### Lower snake_casing
```hcl
✅ variable "my_variable_name"
✅ resource "azurerm_xxx" "my_resource"
❌ variable "myVariableName"
❌ variable "MY_VARIABLE_NAME"
```

### Resource Block Ordering
```hcl
resource "azurerm_storage_account" "this" {
  # Meta-arguments (top)
  count = var.create_storage ? 1 : 0

  # Arguments (middle, alphabetical)
  account_replication_type = "GRS"
  account_tier             = "Standard"
  location                 = var.location
  name                     = var.name
  resource_group_name      = azurerm_resource_group.this.name

  # Arguments with blocks (alphabetical)
  identity {
    type = "SystemAssigned"
  }

  # Meta-arguments (bottom)
  depends_on = [azurerm_resource_group.this]

  lifecycle {
    ignore_changes = [tags]
  }
}
```

### Dynamic Blocks (TFNFR12)
```hcl
# For conditional nested blocks
dynamic "identity" {
  for_each = var.enable_managed_identity ? [1] : []

  content {
    type = "SystemAssigned"
  }
}
```

### Defaults with coalesce/try (TFNFR13)
```hcl
# Good
name = coalesce(var.custom_name, "${var.prefix}-resource")

# Avoid ternary
# name = var.custom_name != null ? var.custom_name : "${var.prefix}-resource"
```

---

## Common AVM Violations & Fixes

### Violation 1: Provider Block in Module
```hcl
❌ terraform/modules/my-module/main.tf
provider "azurerm" {
  features {}
}

✅ Remove it. Provider configured by root module at:
terraform/
├── main.tf (contains provider block)
├── modules/my-module/ (no provider blocks)
```

### Violation 2: any Type for Variables
```hcl
❌ variable "config" {
  type = any
}

✅ variable "config" {
  type = object({
    name     = string
    location = string
  })
}
```

### Violation 3: sensitive = false
```hcl
❌ variable "password" {
  type      = string
  sensitive = false  # This is the default, don't write it
}

✅ variable "password" {
  type      = string
  # sensitive = true if actually sensitive
}
```

### Violation 4: Default Value for Sensitive Input
```hcl
❌ variable "api_key" {
  type      = string
  sensitive = true
  default   = "my-key-123"  # ❌ Never set defaults for secrets
}

✅ variable "api_key" {
  type      = string
  sensitive = true
  # No default
}
```

### Violation 5: Nullable = true Without Reason
```hcl
❌ variable "tags" {
  type     = map(string)
  nullable = true
  default  = null
}

✅ variable "tags" {
  type     = map(string)
  nullable = false
  default  = {}
}
```

---

## Validation Commands

### Before Committing
```bash
# Format check
terraform fmt -recursive terraform/modules/

# Validate syntax
terraform -chdir=terraform/modules/my-module validate

# Lint with tflint
tflint --recursive terraform/modules/

# Security scan with Checkov
checkov -d terraform/modules/ --framework terraform

# Generate documentation
terraform-docs terraform/modules/my-module

# Check git status
git status
```

### Full Compliance Check
```bash
#!/bin/bash
for dir in terraform/modules/*/; do
  mod=$(basename "$dir")
  echo "Checking $mod..."
  
  # terraform.tf exists
  [ -f "$dir/terraform.tf" ] && echo "  ✅ terraform.tf" || echo "  ❌ terraform.tf"
  
  # .terraform-docs.yml exists
  [ -f "$dir/.terraform-docs.yml" ] && echo "  ✅ .terraform-docs.yml" || echo "  ❌ .terraform-docs.yml"
  
  # No provider blocks
  if grep -q "^provider \"" "$dir"/*.tf 2>/dev/null; then
    echo "  ❌ provider block found"
  else
    echo "  ✅ no provider blocks"
  fi
  
  # Validate
  if terraform -chdir="$dir" validate >/dev/null 2>&1; then
    echo "  ✅ terraform validate"
  else
    echo "  ❌ terraform validate failed"
  fi
done
```

---

## Documentation References

| Resource | Link |
|----------|------|
| **AVM Official** | https://azure.github.io/Azure-Verified-Modules/ |
| **AVM Terraform Spec** | https://azure.github.io/Azure-Verified-Modules/specs/terraform/ |
| **Project Strategy** | [AVM-IMPLEMENTATION-STRATEGY.md](./AVM-IMPLEMENTATION-STRATEGY.md) |
| **Phase 1 Report** | [AVM-COMPLIANCE-PHASE-1-COMPLETE.md](./AVM-COMPLIANCE-PHASE-1-COMPLETE.md) |
| **Session Summary** | [SESSION-SUMMARY-AVM-PHASE1.md](./SESSION-SUMMARY-AVM-PHASE1.md) |

---

## Checklist: Before Committing a Module

- [ ] `terraform.tf` exists with version constraints
- [ ] No `provider` blocks in any .tf file
- [ ] `.terraform-docs.yml` present and configured
- [ ] All variables have precise `type` (no `any`)
- [ ] All variables have `description`
- [ ] Collections have `nullable = false` with `default = {}`
- [ ] No `nullable = true` without semantic reason
- [ ] No `sensitive = false` declarations
- [ ] Variables ordered: required (alpha) then optional (alpha)
- [ ] Outputs use anti-corruption layer pattern
- [ ] Sensitive outputs marked with `sensitive = true`
- [ ] `terraform fmt` passes
- [ ] `terraform validate` passes
- [ ] `terraform-docs .` generates README.md
- [ ] All new resources have feature toggles (TFNFR34)
- [ ] No breaking changes undocumented (TFNFR35)

---

## Helpful Commands

```bash
# Initialize a new module with template
mkdir -p terraform/modules/my-module
cd terraform/modules/my-module
cat > terraform.tf << 'EOF'
terraform {
  required_version = "~> 1.6"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.0" }
  }
}
EOF

# Generate documentation
terraform-docs .

# Check formatting
terraform fmt .

# Validate
terraform validate

# Quick lint
tflint

# Security scan
checkov -d . --framework terraform

# View compliance
git status
```

---

## FAQ

**Q: Can I use Azapi provider?**  
A: Yes, add to terraform.tf: `azapi = { source = "Azure/azapi", version = "~> 2.0" }`

**Q: What if I need provider_aliases?**  
A: Only use `configuration_aliases` in required_providers block, not a provider block.

**Q: How do I handle Terraform state?**  
A: Use Terraform Cloud or Azure backend (not in modules - at root level).

**Q: Can I add computed outputs?**  
A: Yes, that's the anti-corruption layer pattern. Output what users need, not internals.

**Q: What about deprecated variables?**  
A: Move to `deprecated_variables.tf`, keep with description noting replacement.

---

**Last Updated**: June 30, 2026  
**Quick Reference Version**: 1.0  
**Scope**: AVM Phase 1-4 guidance
