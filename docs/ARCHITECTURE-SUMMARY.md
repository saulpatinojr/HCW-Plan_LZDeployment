# Landing Zone Architecture: Corrected

**Status**: Transitioning from PS1-heavy to Terraform + ALZ  
**Goal**: Immutable, drift-detected, auditable infrastructure  
**Timeline**: Phase 0 (bootstrap) → Phase 1+ (IaC everywhere)

---

## The Stack

### ✅ YES - Use Terraform + ALZ Verified Modules

```
Terraform Cloud (State Management)
    ↓
terraform/
├─ modules/
│  ├─ alz-connectivity/       (Azure Landing Zone - verified)
│  ├─ alz-management/         (Azure Landing Zone - verified)
│  ├─ alz-identity/           (Azure Landing Zone - verified)
│  └─ custom/                 (Your custom modules)
│
└─ live/
   ├─ global/                 (Subscriptions, RBAC, global)
   ├─ connectivity/           (Hub VNet, Azure Firewall)
   ├─ management/             (Policy, Logging, Monitoring)
   └─ workloads/              (Applications, data, etc.)
```

### ✅ YES - Use GitHub Actions Workflows

```
.github/workflows/
├─ 010-terraform-init.yml     (Initialize TFC state)
├─ 020-rbac-validation.yml    (Validate RBAC config)
├─ 100-terraform-plan.yml     (Drift detection on every PR)
├─ 200-terraform-apply.yml    (Enforce desired state on merge)
└─ 300-compliance-scan.yml    (Policy compliance continuous)
```

### ✅ YES - Use PowerShell for Bootstrap ONLY

```
scripts/
└─ 000_LZ_Bootloader.ps1
   ├─ Validates CLI tools
   ├─ Creates OIDC federation
   ├─ Sets GitHub integration
   └─ Runs ONCE per landing zone
```

### ❌ NO - Don't Use PowerShell for Operations

```
DON'T create:
├─ Cleanup-ExpiredSandboxResources.ps1  ← Use Terraform lifecycle
├─ Create-ResourceGroups.ps1            ← Use Terraform modules
├─ Set-RbacRoles.ps1                    ← Use Terraform RBAC module
└─ Other operational scripts             ← Use Terraform
```

---

## How Drift Detection Works

### Scenario: Manual Change in Portal

```
1. Admin manually changes Azure policy in portal
   ↓
2. Developer commits Terraform code (unchanged)
   ↓
3. Developer opens PR
   ↓
4. Workflow 100 runs: terraform plan
   └─ Output: "Policy X is not in desired state. Plan will revert change."
   ↓
5. PR shows drift detection in comments
   ↓
6. Developer reviews:
   Option A: Discard drift (terraform apply reverts manual change)
   Option B: Accept drift (update Terraform code, re-run plan)
   ↓
7. PR merged → Workflow 200 runs terraform apply
   └─ Manual change is corrected to match code
   ↓
8. State is now consistent (no drift)
```

**Key**: Drift detection is AUTOMATIC, not manual. Every PR catches it.

---

## How Idempotency Works

### First Deploy
```
terraform plan
└─ "Will create: azurerm_resource_group, azurerm_virtual_network, ..."

terraform apply
└─ Creates all resources
```

### Second Deploy (No Changes)
```
terraform plan
└─ "No changes needed. All resources match desired state."

terraform apply
└─ "No changes needed."
```

### Third Deploy (Code Changed)
```
terraform plan
└─ "Will update: azurerm_virtual_network (cidr_block changes)"

terraform apply
└─ Updates only what changed
```

**Key**: Safe to run terraform apply multiple times. Always ends in desired state.

---

## How Immutability Works

```
┌────────────────────────────────────────────────────────────────┐
│                  TERRAFORM + ALZ IMMUTABILITY                   │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│ State Desired:           Resource As Deployed:                 │
│ ├─ VNet: 10.0.0.0/8      ├─ VNet: 10.0.0.0/8    ✓ Match       │
│ ├─ Policy: Deny-Owner    ├─ Policy: Deny-Owner  ✓ Match       │
│ └─ Role: Contributor     └─ Role: Contributor   ✓ Match       │
│                                                                 │
│ If someone manually changes:                                    │
│ $ az network vnet update ... --address-prefix 10.1.0.0/8      │
│                                                                 │
│ Next terraform plan detects:                                   │
│ "azurerm_virtual_network: VNet CIDR is 10.1.0.0/8 but desired  │
│  state is 10.0.0.0/8. Will revert on next apply."             │
│                                                                 │
│ This enforcement is GUARANTEED by Terraform.                   │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

---

## Workflows Explained

### Workflow 100: terraform plan (Drift Detection)

```
Trigger: Every PR to main, every push to main

Steps:
1. Checkout code
2. terraform init (connect to TFC)
3. terraform plan -out=tfplan (generate plan)
4. Comment on PR with changes
5. Show any drift from desired state

Result: 
- ✓ Plan is shown in PR comments
- ✓ Drift is detected and displayed
- ✓ Developer can review before merge
```

### Workflow 200: terraform apply (Enforcement)

```
Trigger: Push to main (after PR merge)

Steps:
1. Checkout code
2. terraform init
3. terraform apply (enforce desired state)
4. Push any state changes to TFC

Result:
- ✓ All resources match desired state
- ✓ Drift is corrected
- ✓ State versioned in TFC
- ✓ Audit trail in git + TFC
```

### Workflow 300: compliance-scan (Validation)

```
Trigger: Every push to main, scheduled daily

Steps:
1. Validate against Azure policies
2. Check CIS benchmarks
3. Scan for security issues
4. Report compliance status

Result:
- ✓ Continuous compliance validation
- ✓ Policies are enforced by ALZ
- ✓ Violations are detected early
```

---

## File Structure (After Migration)

```
HCW-Demo-LZDeployment/
├─ scripts/
│  └─ 000_LZ_Bootloader.ps1          (Bootstrap only)
│
├─ terraform/
│  ├─ modules/
│  │  ├─ alz-connectivity/           (Microsoft ALZ module)
│  │  ├─ alz-management/             (Microsoft ALZ module)
│  │  ├─ rbac/                       (Your RBAC module)
│  │  ├─ policy/                     (Your policy module)
│  │  └─ tagging/                    (Your tagging module)
│  │
│  └─ live/
│     ├─ global/
│     │  ├─ main.tf                  (Subscriptions, RBAC, global tags)
│     │  ├─ variables.tf
│     │  ├─ outputs.tf
│     │  ├─ terraform.tfvars
│     │  └─ backend.hcl
│     │
│     ├─ connectivity/
│     │  ├─ main.tf                  (Hub VNet, Firewall, DDoS)
│     │  ├─ variables.tf
│     │  ├─ outputs.tf
│     │  ├─ terraform.tfvars
│     │  └─ backend.hcl
│     │
│     ├─ management/
│     │  ├─ main.tf                  (Policy, logging, monitoring)
│     │  ├─ variables.tf
│     │  ├─ outputs.tf
│     │  ├─ terraform.tfvars
│     │  └─ backend.hcl
│     │
│     └─ workloads/
│        ├─ main.tf                  (Application resources)
│        ├─ variables.tf
│        ├─ outputs.tf
│        ├─ terraform.tfvars
│        └─ backend.hcl
│
├─ .github/workflows/
│  ├─ 010-terraform-init.yml         (Phase 0.1)
│  ├─ 020-rbac-validation.yml        (Phase 1)
│  ├─ 100-terraform-plan.yml         (Every PR - drift detection)
│  ├─ 200-terraform-apply.yml        (Every merge - enforcement)
│  └─ 300-compliance-scan.yml        (Continuous validation)
│
├─ docs/
│  ├─ ARCHITECTURE-DECISION.md       (Why Terraform + ALZ)
│  ├─ ARCHITECTURE-SUMMARY.md        (This file)
│  ├─ RBAC-REQUIREMENTS.md           (RBAC in Terraform)
│  ├─ DEPLOYMENT-GUIDE.md            (How to deploy)
│  └─ bootstrap/                     (Bootstrap docs)
│
├─ .lz-bootloader-state.json         (Bootstrap state - gitignore)
├─ .reports/
│  └─ bootstrap/                     (Audit reports - gitignore)
│
└─ terraform.tfvars                  (Root-level config - gitignore)
```

---

## Migration: Task 1.3 Reframed

### Old (Wrong): Add Safety Checks to PowerShell Script
```
❌ Task 1.3: PowerShell Script Input Validation
├─ Add GUID validation
├─ Add subscription checks
├─ Add dry-run confirmation
└─ Result: More sophisticated script (but still not ideal)
```

### New (Right): Convert to Terraform
```
✅ Task 1.3: Convert Sandbox Cleanup to Terraform
├─ Remove: Cleanup-ExpiredSandboxResources.ps1
├─ Create: terraform/live/sandbox/main.tf
│  └─ resource "azurerm_resource_group" "sandbox" { }
├─ Add: Lifecycle rules for resource expiration
│  └─ tags = { lifecycle = "temporary", created_date = "..." }
├─ Add: Drift detection (workflow 100 detects changes)
└─ Result: Fully tracked, auditable, immutable, safe
```

**Conversion Benefits**:
- ✓ State tracked in TFC (audit trail)
- ✓ Drift detection automatic
- ✓ Immutable deployments
- ✓ Idempotent (safe to re-run)
- ✓ No PS1 maintenance burden
- ✓ Follows ALZ patterns

---

## Phase Timeline (Corrected)

### Phase 0: Bootstrap (PS1 OK here)
```
✅ 000_LZ_Bootloader.ps1
   └─ One-time setup, OIDC, GitHub integration
```

### Phase 0.1: Terraform Init (Workflow)
```
✅ 010-terraform-init.yml
   └─ Initialize TFC state, validate code
```

### Phase 1: RBAC & Security (Terraform)
```
Task 1.1: RBAC Validation (Automated)
├─ Workflow 020: Audit RBAC
└─ terraform/modules/rbac/: Define RBAC as code

Task 1.2: Terraform State (Satisfied by TFC)
└─ No changes needed (TFC handles it)

Task 1.3: Convert Cleanup to Terraform (NEW)
├─ Remove: Cleanup-ExpiredSandboxResources.ps1
└─ Add: terraform/live/sandbox/main.tf
```

### Phase 2: Infrastructure (Terraform + ALZ)
```
Global Layer:
├─ terraform/live/global/main.tf
└─ Subscriptions, RBAC, tagging

Connectivity Layer:
├─ terraform/live/connectivity/main.tf
├─ module "alz_connectivity" { }
└─ Hub VNet, Firewall, ExpressRoute

Management Layer:
├─ terraform/live/management/main.tf
├─ module "alz_management" { }
└─ Policy, Logging, Monitoring

Workloads Layer:
├─ terraform/live/workloads/main.tf
└─ Application resources
```

### Phase 3+: Operations (Terraform Only)
```
All changes made via:
1. Terraform code in git
2. PR with workflow 100 (terraform plan)
3. Review & merge
4. Workflow 200 (terraform apply)
5. Drift detected by workflow 100 on next PR
```

---

## Decision Made

✅ **Terraform + ALZ is the foundation**
- Infrastructure as Code everywhere
- Drift detection built-in
- Idempotent by design
- Immutable deployments
- Full audit trail

⚠️ **PowerShell is bootstrap only**
- Set up trust between systems
- One-time execution
- Then hand off to Terraform

❌ **PowerShell is NOT for operations**
- Don't create operational scripts
- Convert existing scripts to Terraform
- Focus on IaC maintainability

---

## Next Actions

1. ✅ Document architecture decision (DONE)
2. ⏳ Update TODO.md to reflect Terraform-first approach
3. ⏳ Create terraform/live/global/ (Phase 2)
4. ⏳ Create terraform/live/connectivity/ (Phase 2)
5. ⏳ Convert sandbox cleanup to Terraform (Task 1.3)
6. ⏳ Implement workflow 100 (terraform plan)
7. ⏳ Implement workflow 200 (terraform apply)
8. ⏳ Implement workflow 300 (compliance scan)

---

## Questions & Answers

**Q: But what about the cleanup script in Task 1.3?**  
A: Convert it to Terraform. Use `terraform destroy` or remove from code.

**Q: How do we handle one-time operations?**  
A: Use Terraform `local-exec` or `azurerm_resource_group_template_deployment` for template-based operations.

**Q: What if we need custom logic?**  
A: Write Terraform modules, not scripts. Modules are reusable, testable, versionable.

**Q: Isn't Terraform slower than PowerShell?**  
A: Terraform is optimized for cloud, has parallelization, and provides immutability. Worth the trade-off.

**Q: Can we mix PowerShell with Terraform?**  
A: Yes, for bootstrap only. Use `local-exec` for custom provisioning, but prefer native Terraform.

---

**Decision Date**: 2026-06-30  
**Status**: Approved - Terraform + ALZ + Workflows is the architecture

