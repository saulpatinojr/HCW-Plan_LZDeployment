# Architecture Decision: Terraform + ALZ vs. PowerShell Scripts

**Date**: 2026-06-30  
**Decision**: Use Terraform + ALZ modules; minimize PowerShell to bootstrap only  
**Status**: ⚠️ Current state misaligned; correcting now

---

## The Problem

You raised a critical concern: **Why so many PowerShell scripts?**

This repository started with a **bootstrap-first mentality** (lots of PS1) instead of a **Terraform-first mentality** (IaC everywhere).

**Current Misalignment**:
```
What we HAVE:
├─ 000_LZ_Bootloader.ps1 (Phase 0 - OK)
├─ 010-terraform-init.yml (Phase 0.1 - OK)
├─ 020-rbac-validation.yml (Phase 1 - Workflow, OK)
├─ Cleanup-ExpiredSandboxResources.ps1 (⚠️ Should be Terraform)
└─ Other scattered scripts

What we SHOULD HAVE:
├─ 000_LZ_Bootloader.ps1 (Phase 0 - minimal, bootstrap only)
├─ 010-terraform-init.yml (Phase 0.1 - initialize TFC state)
├─ terraform/
│  ├─ modules/alz-*/                    (ALZ-verified modules)
│  ├─ live/
│  │  ├─ global/                        (Global infrastructure)
│  │  ├─ connectivity/                  (Network layer)
│  │  ├─ management/                    (Policies, logging, etc.)
│  │  └─ workloads/                     (Application layer)
│  └─ policies/                         (Drift detection via Terraform)
└─ .github/workflows/
   ├─ 010-terraform-init.yml
   ├─ 020-rbac-validation.yml
   ├─ 100-terraform-plan.yml            (Drift detection)
   ├─ 200-terraform-apply.yml           (Enforcement)
   └─ 300-compliance-scan.yml           (Continuous validation)
```

---

## The Right Architecture

### ✅ Terraform + ALZ is the Correct Approach

```
┌─────────────────────────────────────────────────────────────────┐
│                  TERRAFORM + ALZ MODULES                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  STRENGTHS:                                                      │
│  ✓ Infrastructure as Code (all in Terraform)                   │
│  ✓ Drift detection (terraform plan detects changes)            │
│  ✓ Idempotent (safe to re-run)                                │
│  ✓ ALZ-verified modules (security, best practices built-in)   │
│  ✓ State management (single source of truth in TFC)           │
│  ✓ Immutable deployments (Terraform enforces)                 │
│  ✓ Rollback capability (state versioning)                      │
│  ✓ No drift (terraform plan catches manual changes)            │
│                                                                  │
│  HOW IT WORKS:                                                   │
│  1. Developers commit Terraform code (IaC)                      │
│  2. Workflow 100 runs: terraform plan (detects drift)          │
│  3. Workflow 200 runs: terraform apply (enforces desired state) │
│  4. Workflow 300 runs: Compliance scanning (validates)          │
│  5. TFC tracks state changes (audit trail)                      │
│  6. Repeat: Drift is detected and corrected automatically      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

vs.

┌─────────────────────────────────────────────────────────────────┐
│              HEAVY POWERSHELL (WRONG APPROACH)                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  WEAKNESSES:                                                     │
│  ✗ Scripts are imperative (what to do, not desired state)      │
│  ✗ Drift detection is manual (run audit scripts)               │
│  ✗ Hard to version (scripts in git don't track state)          │
│  ✗ Not idempotent (may fail on re-run)                        │
│  ✗ No rollback (scripts are one-way)                          │
│  ✗ Security gaps (scripts do manual RBAC, hard to audit)      │
│  ✗ Maintenance burden (scripts rot, break with API changes)   │
│                                                                  │
│  WHY THIS IS WRONG:                                             │
│  - Scripts describe ACTIONS, not DESIRED STATE                 │
│  - Hard to detect/correct drift                                │
│  - No single source of truth                                   │
│  - Doesn't align with ALZ framework                            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## PowerShell Scripts: Bootstrap Only

PowerShell **IS** useful, but **ONLY for bootstrap**:

### ✅ Where PowerShell is Appropriate

```
BOOTSTRAP (One-time, Phase 0):
├─ 000_LZ_Bootloader.ps1
│  ├─ Validate CLI tools (az, gh, git, terraform)
│  ├─ Authenticate (Azure, GitHub, TFC)
│  ├─ Create OIDC service principals
│  ├─ Set GitHub secrets/variables
│  ├─ Initialize Terraform Cloud
│  └─ Generate audit report
│
└─ Purpose: Set up trust between systems (GitHub → Azure → TFC)
   Duration: 5-10 minutes
   Frequency: Once per landing zone
   Idempotency: Yes (safe to re-run)
```

### ❌ Where PowerShell is NOT Appropriate

```
OPERATIONS (Ongoing):
├─ Cleanup-ExpiredSandboxResources.ps1 ❌ SHOULD BE TERRAFORM
├─ Manual RBAC management ❌ SHOULD BE TERRAFORM
├─ Resource group creation ❌ SHOULD BE TERRAFORM
├─ Policy enforcement ❌ SHOULD BE TERRAFORM
└─ Network configuration ❌ SHOULD BE TERRAFORM

Why not:
- Doesn't track state
- Hard to detect drift
- No rollback capability
- Not reproducible
- Security auditing is manual
```

---

## Corrected Architecture

### Phase 0: Bootstrap (PS1 OK, one-time)
```
000_LZ_Bootloader.ps1
├─ Validates prerequisites
├─ Creates OIDC federation
├─ Sets GitHub integration
└─ Initializes TFC
```

### Phase 0.1: Terraform Init (Workflow)
```
010-terraform-init.yml
├─ terraform init (connects to TFC)
├─ terraform validate
├─ terraform fmt check
└─ terraform plan (first deployment)
```

### Phase 1+: Infrastructure as Code (Terraform + ALZ)
```
terraform/
├─ modules/
│  ├─ alz-connectivity/          (Hub networking)
│  ├─ alz-management/            (Policies, logging)
│  ├─ alz-workloads/             (Application resources)
│  └─ custom-modules/            (Custom resources)
│
├─ live/
│  ├─ global/                    (Subscriptions, RBAC, tags)
│  │  ├─ main.tf
│  │  ├─ variables.tf
│  │  ├─ terraform.tfvars
│  │  └─ backend.hcl
│  │
│  ├─ connectivity/              (Hub VNet, Firewall, etc.)
│  │  ├─ main.tf
│  │  └─ ...
│  │
│  ├─ management/                (Policy, logging, etc.)
│  │  ├─ main.tf
│  │  └─ ...
│  │
│  └─ workloads/                 (Apps, data, etc.)
│     ├─ main.tf
│     └─ ...
│
└─ policies/                      (Drift detection, compliance)
   ├─ policy-baseline/
   └─ compliance-rules/
```

### Workflows
```
.github/workflows/
├─ 010-terraform-init.yml        (One-time, Phase 0.1)
├─ 020-rbac-validation.yml       (Weekly, Phase 1 Task 1.1)
├─ 100-terraform-plan.yml        (Every PR, drift detection)
├─ 200-terraform-apply.yml       (Every merge to main, enforcement)
└─ 300-compliance-scan.yml       (Continuous, policy validation)
```

---

## How This Solves Your Concerns

### Concern 1: Drift Protection

**With Terraform + ALZ**:
```
Scenario: Someone manually changes Azure policy in portal
          ↓
Developer runs: git pull && cd terraform && terraform plan
          ↓
Terraform detects: "Policy X is not in desired state"
          ↓
Terraform shows diff: "Portal change will be overwritten"
          ↓
Developer can:
├─ Revert manual change (discard drift)
└─ Update Terraform (accept drift as new desired state)

This is AUTOMATIC. No manual audits needed.
```

**With Scripts Only**:
```
Scenario: Someone manually changes Azure policy
          ↓
No automatic detection (would need separate audit script)
          ↓
Drift silently exists until someone runs audit
          ↓
Manual investigation to understand what drifted
          ↓
Manual decision on how to correct

This is LABOR-INTENSIVE and ERROR-PRONE.
```

### Concern 2: Idempotency

**Terraform is inherently idempotent**:
```
terraform plan          → "No changes needed" (if state matches)
terraform apply         → "No changes needed" (if state matches)
terraform apply again   → "No changes needed" (safe to re-run)

This is built-in. No special logic needed.
```

**Scripts require explicit idempotency**:
```
script.ps1
├─ Check if resource exists?
├─ If exists: Update or skip?
├─ If not: Create
└─ Log what happened?

This requires YOU to implement in every script.
```

### Concern 3: ALZ Modules

**ALZ (Azure Landing Zone) Modules**:
```
These are TERRAFORM modules from Microsoft that:
✓ Implement best practices
✓ Validated by Azure team
✓ Used in production at scale
✓ Handle complex scenarios
✓ Have built-in drift detection
✓ Provide compliance guardrails

Example:
module "alz_connectivity" {
  source = "git::https://github.com/Azure/terraform-azurerm-landing-zone.git//modules/connectivity"
  
  # Terraform ensures this is always deployed correctly
  # If someone manually changes it, terraform plan detects it
  # If values change, terraform apply enforces desired state
}
```

---

## Corrected Cleanup Script Task

### Current (Wrong): PowerShell Script
```powershell
# Cleanup-ExpiredSandboxResources.ps1
# Manually deletes sandbox resources
# No idempotency guarantee
# Drift detection is manual
# No audit trail in IaC

Remove-AzResourceGroup -Name $rg
```

### Correct (Right): Terraform
```hcl
# terraform/live/sandbox/main.tf
# Declare: "Sandbox should exist with these resources"
# Terraform handles:
# ✓ Creation
# ✓ Updates
# ✓ Deletion (when removed from code)
# ✓ Drift detection

resource "azurerm_resource_group" "sandbox" {
  name     = "rg-sandbox-${var.environment}"
  location = var.region
  
  lifecycle {
    prevent_destroy = false  # Allows Terraform to delete when removed
  }
  
  tags = {
    environment = "sandbox"
    lifecycle   = "temporary"  # Auto-cleanup tag
  }
}

# If this resource is removed from terraform code:
# Next: terraform plan detects the deletion
# Next: terraform apply actually deletes the sandbox
# Result: AUTOMATED, TRACKED IN GIT, AUDITABLE
```

---

## Migration Plan: Fix This Now

### Phase 0 (Bootstrap) - Keep PS1
```
✓ 000_LZ_Bootloader.ps1
  └─ One-time setup script (OK to keep)
```

### Phase 1 (Infrastructure) - Convert to Terraform
```
MIGRATE FROM PS1 TO TERRAFORM:

1. Cleanup-ExpiredSandboxResources.ps1
   → Convert to: terraform/live/sandbox/main.tf
   → Add: lifecycle rules, tags for auto-cleanup
   → Result: Drift detection, idempotent, tracked in git

2. Manual RBAC scripts
   → Convert to: terraform/modules/rbac/main.tf
   → Result: All RBAC in IaC, drift detection via workflow 100

3. Resource group creation
   → Convert to: terraform/live/global/main.tf
   → Result: All resources in IaC

4. Policy enforcement
   → Convert to: terraform/modules/policy-baseline/main.tf
   → Result: Policies as code, drift detection, compliance checked
```

### Phase 2+ (Operations) - Terraform Only
```
All infrastructure defined in Terraform:
├─ terraform/live/global/
├─ terraform/live/connectivity/
├─ terraform/live/management/
└─ terraform/live/workloads/

All changes:
1. Made in Terraform code
2. Tested in PR via workflow 100 (terraform plan)
3. Applied via workflow 200 (terraform apply)
4. Detected via workflow 300 (compliance scan)
5. Tracked in git + TFC state
6. Auditable forever
```

---

## Updated Task 1.3 (PowerShell Validation)

### WRONG APPROACH (Current TODO)
```
Task 1.3: PowerShell Script Input Validation
├─ Add GUID validation to cleanup script
├─ Add subscription checks
├─ Add dry-run confirmation
├─ Add audit logging
└─ Result: More sophisticated script, but still not ideal
```

### RIGHT APPROACH (New)
```
Task 1.3: Convert Sandbox Cleanup to Terraform
├─ Remove: Cleanup-ExpiredSandboxResources.ps1
├─ Create: terraform/live/sandbox/main.tf
├─ Add: Lifecycle rules for resource expiration
├─ Add: Tags for auto-cleanup scheduling
├─ Add: Drift detection via workflow 100
└─ Result: Fully tracked, auditable, immutable, idempotent
```

---

## Why Terraform + ALZ is Better

| Aspect | PowerShell Scripts | Terraform + ALZ |
|--------|-------------------|-----------------|
| **Drift Detection** | Manual audits | Automatic (terraform plan) |
| **Idempotency** | Must implement per script | Built-in |
| **State Tracking** | None (scripts don't track) | TFC tracks all changes |
| **Rollback** | Manual | Automatic (state versioning) |
| **Audit Trail** | Git commits | Git + TFC versions |
| **Security** | No enforcement | ALZ provides guardrails |
| **Compliance** | Manual verification | Automated policy scanning |
| **Reproducibility** | Script-dependent | Fully reproducible |
| **Scalability** | Breaks at scale | Designed for scale |
| **Maintenance** | High (script rot) | Low (standard patterns) |

---

## Action Items

### Immediate (Update TODO)
1. ❌ Remove Task 1.3 (PowerShell validation) from TODO
2. ✅ Add new Task 1.3: Convert cleanup script to Terraform
3. ✅ Add new Phase 2 tasks: Implement ALZ modules

### Short Term (This Week)
1. Document architecture decision (this file - DONE)
2. Create terraform/live/sandbox/main.tf
3. Create terraform/modules/rbac/main.tf
4. Remove or deprecate cleanup PS1 scripts

### Medium Term (This Sprint)
1. Build out terraform/live/global/ (subscriptions, RBAC, tags)
2. Build out terraform/live/connectivity/ (hub network)
3. Build out terraform/live/management/ (policies, logging)
4. Implement workflow 100 (terraform plan - drift detection)
5. Implement workflow 200 (terraform apply - enforcement)

### Long Term (Production)
1. All infrastructure in Terraform + ALZ
2. Drift detection automated via workflow 100
3. Compliance validation via workflow 300
4. Zero manual infrastructure changes
5. Fully auditable and immutable

---

## Summary

You were RIGHT to question all the PS1 files. The correct architecture is:

✅ **Terraform + ALZ** (for all infrastructure)
- Drift detection built-in
- Idempotent by nature
- Immutable deployments
- Full audit trail
- ALZ provides security guardrails

⚠️ **PowerShell Only for Bootstrap** (one-time, Phase 0)
- Initialize trust between systems
- Set up secrets, OIDC, TFC
- Then hand off to Terraform

❌ **NOT PowerShell for Operations** (ongoing)
- Doesn't scale
- Hard to detect drift
- No single source of truth
- Labor-intensive maintenance

This repository is currently misaligned. Let's fix it by focusing on Terraform + ALZ as the primary deployment mechanism.

---

## Next Steps

1. ✅ Acknowledge architecture decision (DONE - this document)
2. ⏳ Update TODO to reflect Terraform-first approach
3. ⏳ Create terraform/live/ structure (global, connectivity, management, workloads)
4. ⏳ Implement ALZ modules
5. ⏳ Create workflow 100 (terraform plan - drift detection)
6. ⏳ Create workflow 200 (terraform apply - enforcement)

Should we proceed with this architecture?

