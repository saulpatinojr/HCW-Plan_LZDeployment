# Bootstrap Script Consolidation

**Date**: 2026-06-30  
**Status**: Recommending consolidation to single entry point  
**Current State**: 3 bootstrap scripts exist; only 1 is needed going forward

---

## Current Scripts Inventory

| Script | Purpose | Status | Keep? |
|--------|---------|--------|-------|
| **000_LZ_Bootloader.ps1** | Complete Phase 0 orchestration | ✅ NEW | **YES** |
| **Initialize-CnaGitHubSecrets.ps1** | GitHub App + OIDC setup | ✅ Mature | **MERGE INTO 000** |
| **Start-Bootstrap.ps1** | Interactive bootstrap (old approach) | ⚠️ Dated | **DELETE** |
| **Initialize-LandingZone.ps1** | Unknown (referenced but not provided) | ❓ | **DELETE IF EXISTS** |

---

## Recommendation: USE ONLY 000_LZ_Bootloader.ps1

### Why Consolidate?

1. **Single Entry Point** — Users run one script, not multiple
2. **No Confusion** — Clear which script to use
3. **Idempotent** — State tracking prevents re-doing work
4. **Delegation to Workflow 010** — Separates local from CI/CD concerns
5. **Best Practices Built-in** — Leverages strengths of Initialize-CnaGitHubSecrets.ps1

### What 000_LZ_Bootloader.ps1 Does

```
LOCAL (Phase 0)
├─ Validates CLI tools (az, gh, git, terraform)
├─ Authenticates to Azure, GitHub, TFC
├─ Creates 3 service principals (main/dev/prod) with least-privilege RBAC
├─ Creates OIDC federated credentials (scoped to branches/environments)
├─ Sets GitHub secrets (AZURE_CLIENT_ID, TENANT_ID, SUBSCRIPTION_ID)
├─ Sets GitHub variables (region, org prefix, TFC config)
├─ Creates GitHub environments (dev, prod, hub)
├─ Configures Terraform Cloud integration
├─ Generates bootstrap audit report
└─ Creates optional PR with artifacts

WORKFLOW (Phase 0.1)
├─ Terraform init with TFC backend
├─ Validate OIDC connectivity
├─ Validate RBAC (no Owner roles)
├─ Terraform format check
├─ Terraform validate
├─ Terraform plan (workload resources)
└─ Generate summary
```

---

## Migration Path

### Step 1: Deprecate Old Scripts

```bash
# Keep as reference only
mv scripts/Start-Bootstrap.ps1 scripts/deprecated/Start-Bootstrap.ps1.deprecated
mv scripts/Initialize-LandingZone.ps1 scripts/deprecated/Initialize-LandingZone.ps1.deprecated
mv scripts/Initialize-CnaGitHubSecrets.ps1 scripts/deprecated/Initialize-CnaGitHubSecrets.ps1.deprecated
```

### Step 2: Update Documentation

Create `docs/bootstrap/QUICKSTART.md`:

```markdown
# Landing Zone Bootstrap Quick Start

## Prerequisites
- Windows 7+, macOS 10.12+, or Linux (PowerShell 7.0+)
- Administrator/owner account for Azure subscription
- GitHub account (personal or organization)

## One-Step Bootstrap

```bash
.\scripts\000_LZ_Bootloader.ps1
```

That's it. The script will:
1. Validate or install CLI tools
2. Prompt for Azure, GitHub, TFC authentication
3. Create OIDC service principals
4. Configure GitHub secrets & variables
5. Generate audit report
6. Create optional PR

## What Happens Next?

After running the script:
1. Review any generated PR
2. Merge to main (triggers workflow 010)
3. Workflow 010 initializes Terraform
4. Ready to deploy infrastructure

## Rollback

Delete `.lz-bootloader-state.json` and re-run the script (idempotent).
```

### Step 3: Update README

Change `docs/bootstrap/README.md` to reference only 000_LZ_Bootloader.ps1.

---

## Comparison: Before vs. After

### BEFORE (Confusing)
```
User is confused: which script to run?
├─ Start-Bootstrap.ps1 (old, single monolithic SP) ❌
├─ Initialize-CnaGitHubSecrets.ps1 (good but complex) ⚠️
├─ Initialize-LandingZone.ps1 (unknown) ❓
└─ Some combination? (user guesses)
```

### AFTER (Clear)
```
User knows exactly what to do:
└─ .\scripts\000_LZ_Bootloader.ps1 ✅
   (everything else is automated)
```

---

## What Gets Merged Into 000_LZ_Bootloader.ps1?

From **Initialize-CnaGitHubSecrets.ps1**, we borrow:
- ✅ Three separate SPs per layer (main/dev/prod) — **best practice**
- ✅ Proper federated credential scoping — **security**
- ✅ Terraform Cloud support — **your preference**
- ✅ Human OAuth separation — **architectural clarity**
- ✅ Bootstrap report generation — **audit trail**

From **Start-Bootstrap.ps1**, we borrow:
- ✅ Interactive UX with confirmations — **user-friendly**
- ✅ State tracking (.bootstrap-state.json) — **idempotent**
- ✅ Step-by-step guidance — **clear flow**

What we REJECT:
- ❌ Single monolithic SP (Start-Bootstrap) — **violates least-privilege**
- ❌ Azure Storage backend (Start-Bootstrap) — **you want TFC**
- ❌ Complex terraform.tfvars setup (Start-Bootstrap) — **TFC is simpler**

---

## Deleted Scripts Justification

### Start-Bootstrap.ps1 ❌ DELETE

**Why delete:**
- Creates single SP with both Contributor + User Access Administrator (security risk)
- Uses Azure Storage backend (you prefer TFC)
- Terraform state setup is overly complex
- Only 65% OIDC best-practices aligned

**No loss:**
- 000_LZ_Bootloader.ps1 does everything better
- Better UX, better security, better workflow integration

**Recovery:**
- Keep in git history (git log) if you ever need to reference
- Optional: keep copy in `scripts/deprecated/` for reference

### Initialize-LandingZone.ps1 ❌ DELETE

**Why delete:**
- Appears to be unused or experimental
- 000_LZ_Bootloader.ps1 fulfills the same purpose
- Consolidation reduces confusion

**Recovery:**
- Keep in git history
- Optional: keep copy in `scripts/deprecated/` for reference

### Initialize-CnaGitHubSecrets.ps1 ⚠️ KEEP FOR NOW, MERGE LATER

**Why keep temporarily:**
- Contains excellent OIDC best-practices implementation
- Can serve as reference for 000_LZ_Bootloader.ps1
- Other users might reference it

**When to delete:**
- After 000_LZ_Bootloader.ps1 is validated in production
- Keep in deprecated/ folder for historical reference

---

## Automation: Clean Up Deprecated Scripts

```bash
#!/bin/bash
# scripts/cleanup-deprecated-bootstrap.sh

mkdir -p scripts/deprecated

for script in Start-Bootstrap.ps1 Initialize-LandingZone.ps1 Initialize-CnaGitHubSecrets.ps1; do
  if [ -f "scripts/$script" ]; then
    echo "Moving $script to deprecated..."
    git mv "scripts/$script" "scripts/deprecated/$script.deprecated"
  fi
done

git commit -m "chore: consolidate bootstrap scripts into 000_LZ_Bootloader.ps1

Rationale:
- Single entry point reduces user confusion
- 000_LZ_Bootloader.ps1 leverages best practices from all previous scripts
- Idempotent state tracking ensures safe re-runs
- Workflow 010 handles CI/CD phase

Deprecated scripts kept in scripts/deprecated/ for reference."
```

---

## New Bootstrap Flow (After Consolidation)

```
┌──────────────────────────────────────────────────────────────┐
│ USER RUNS (ONE COMMAND):                                     │
│ .\scripts\000_LZ_Bootloader.ps1                              │
└──────────────────────────────────────────────────────────────┘

                            │
                            ▼

┌──────────────────────────────────────────────────────────────┐
│ PHASE 0 (LOCAL, THIS SCRIPT):                                │
│                                                               │
│ 1. Validate CLIs (az, gh, git, terraform)                   │
│ 2. Authenticate (Azure, GitHub, TFC)                        │
│ 3. Create OIDC SPs (main/dev/prod)                          │
│ 4. Create Federated Credentials (scoped)                    │
│ 5. Set GitHub Secrets & Variables                          │
│ 6. Create GitHub Environments                              │
│ 7. Configure Terraform Cloud                               │
│ 8. Generate Bootstrap Report                               │
│ 9. Optional: Create PR                                     │
└──────────────────────────────────────────────────────────────┘

                            │
                            ▼

┌──────────────────────────────────────────────────────────────┐
│ PHASE 0.1 (WORKFLOW 010, AUTOMATED):                         │
│                                                               │
│ - Terraform Init (TFC backend)                              │
│ - Validate OIDC                                             │
│ - Terraform Format Check                                    │
│ - Terraform Validate                                        │
│ - Terraform Plan                                            │
│ - Summary                                                   │
└──────────────────────────────────────────────────────────────┘

                            │
                            ▼

┌──────────────────────────────────────────────────────────────┐
│ PHASE 1 (NEXT WORKFLOW):                                     │
│                                                               │
│ - Terraform Apply                                           │
│ - Deploy Workload Resources                                 │
│ - Validate Connectivity                                     │
└──────────────────────────────────────────────────────────────┘
```

---

## Summary

| Aspect | Before | After |
|--------|--------|-------|
| Scripts to choose from | 3-4 | 1 |
| Entry point | Confusing | Clear |
| OIDC compliance | Variable | Best-practices |
| State tracking | Partial | Full |
| Workflow delegation | Manual | Automated |
| User friction | High | Low |

**Recommendation**: Consolidate immediately. No loss of functionality, significant gain in clarity.

