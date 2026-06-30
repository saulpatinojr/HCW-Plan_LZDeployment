# Bootstrap Script Decisions

## Question
"Do we no longer need Start-Bootstrap.ps1 or Initialize-LandingZone.ps1?"

## Answer: YES, DELETE THEM

We now have a single, unified entry point: **000_LZ_Bootloader.ps1**

---

## Script Usage Going Forward

### ✅ KEEP & USE
- **`scripts/000_LZ_Bootloader.ps1`**
  - Purpose: Complete Phase 0 bootstrap (local)
  - Usage: `.\scripts\000_LZ_Bootloader.ps1`
  - Status: New, production-ready
  - Handles: CLI validation, auth, OIDC SPs, GitHub config, TFC setup

### ✅ KEEP FOR REFERENCE (Deprecated)
- **`scripts/deprecated/Initialize-CnaGitHubSecrets.ps1`**
  - Reason: Reference implementation of OIDC best practices
  - Status: No longer used (merged into 000_LZ_Bootloader.ps1)
  - Why keep: Useful for understanding OIDC patterns

### ❌ DELETE
- **`scripts/Start-Bootstrap.ps1`**
  - Status: Superseded by 000_LZ_Bootloader.ps1
  - Issues: Single monolithic SP, Azure Storage backend, security gaps
  - Recovery: Available in git history

- **`scripts/Initialize-LandingZone.ps1`** (if it exists)
  - Status: Superseded by 000_LZ_Bootloader.ps1
  - Recovery: Available in git history

---

## Migration Steps

### For Your Repository

```bash
# 1. Move deprecated scripts to deprecated folder (optional)
mkdir -p scripts/deprecated
mv scripts/Start-Bootstrap.ps1 scripts/deprecated/ 2>/dev/null || true
mv scripts/Initialize-CnaGitHubSecrets.ps1 scripts/deprecated/ 2>/dev/null || true
mv scripts/Initialize-LandingZone.ps1 scripts/deprecated/ 2>/dev/null || true

# 2. Verify 000_LZ_Bootloader.ps1 exists
ls -la scripts/000_LZ_Bootloader.ps1

# 3. Update documentation to reference only 000_LZ_Bootloader.ps1
# (Already done in docs/bootstrap/QUICKSTART.md and BOOTSTRAP-SCRIPT-CONSOLIDATION.md)

# 4. Commit
git add -A
git commit -m "chore: consolidate bootstrap to single 000_LZ_Bootloader.ps1 entry point

- Removed Start-Bootstrap.ps1 (security issues, Azure Storage backend)
- Removed Initialize-LandingZone.ps1 (superseded)
- Moved Initialize-CnaGitHubSecrets.ps1 to deprecated/ (reference only)
- Kept git history for future reference

All bootstrap functionality now in 000_LZ_Bootloader.ps1"
```

---

## Why This Change?

### Problems with Multiple Scripts

| Issue | Impact |
|-------|--------|
| Users confused which to run | High friction during bootstrap |
| Inconsistent approaches | Security vs. convenience trade-offs |
| Start-Bootstrap has RBAC gaps | Privilege escalation risk |
| Start-Bootstrap uses Azure Storage | Wrong backend for TFC preference |
| Maintenance burden | 3 scripts to test & update |

### Benefits of Single Entry Point

| Benefit | Impact |
|---------|--------|
| **Clarity** | Users know exactly what to run |
| **Security** | Best-practices built-in (3 SPs, OIDC, no Owner roles) |
| **Simplicity** | Single codebase to maintain |
| **Idempotency** | Safe to re-run without side effects |
| **Workflow Delegation** | Clear separation: local vs. CI/CD |

---

## Quick Reference: What Each Phase Does

### Phase 0 (Local)
```
Run: .\scripts\000_LZ_Bootloader.ps1

Does:
  ✓ Validate CLI tools
  ✓ Auth to Azure, GitHub, TFC
  ✓ Create OIDC service principals
  ✓ Set GitHub secrets/variables
  ✓ Generate audit report
```

### Phase 0.1 (Workflow 010)
```
Trigger: Push to main or workflow_dispatch

Does:
  ✓ Terraform init (TFC backend)
  ✓ Validate OIDC
  ✓ Terraform format check
  ✓ Terraform validate
  ✓ Terraform plan
```

### Phase 1+ (Future Workflows)
```
020: Terraform apply
030: Deploy connectivity
040: Deploy management
050: Deploy workloads
```

---

## Files Created

### New Files
- ✅ `scripts/000_LZ_Bootloader.ps1` — Main bootstrap orchestrator
- ✅ `.github/workflows/010-terraform-init.yml` — Phase 0.1 workflow

### Updated Documentation
- ✅ `docs/bootstrap/BOOTSTRAP-SCRIPT-CONSOLIDATION.md` — Detailed rationale
- ✅ `docs/bootstrap/BOOTSTRAP-DECISIONS.md` — This file
- ✅ `docs/bootstrap/OIDC-BEST-PRACTICES.md` — Reference (unchanged)
- ✅ `docs/bootstrap/OIDC-SCRIPT-ANALYSIS.md` — Reference (unchanged)
- ✅ `docs/bootstrap/START-BOOTSTRAP-ANALYSIS.md` — Reference (unchanged)

### Deprecated (Move to `scripts/deprecated/`)
- ⚠️ `scripts/Start-Bootstrap.ps1`
- ⚠️ `scripts/Initialize-CnaGitHubSecrets.ps1`
- ⚠️ `scripts/Initialize-LandingZone.ps1` (if exists)

---

## State Management

### State File
- **Location**: `.lz-bootloader-state.json` (root of repo)
- **Purpose**: Track which bootstrap steps have completed
- **Idempotency**: Script checks this before re-running steps
- **Reset**: Delete to start over (safe to delete anytime)

### Secrets & Variables
- **Location**: GitHub repository Settings → Secrets and Variables
- **Created by**: 000_LZ_Bootloader.ps1 (Phase 0)
- **Used by**: Workflow 010+ (Phase 0.1+)

### Bootstrap Report
- **Location**: `.reports/bootstrap/YYYYMMDD-HHMMSS-bootstrap-report.md`
- **Purpose**: Audit trail of what was created
- **Review**: Important for understanding deployed resources

---

## Frequently Asked Questions

### Q: What if I already ran Start-Bootstrap.ps1?

**A**: You have two options:

1. **Keep it** — It works. No need to re-bootstrap unless you want to upgrade OIDC setup.
2. **Upgrade** — Delete `.bootstrap-state.json` and run `000_LZ_Bootloader.ps1` (idempotent, safe).

The scripts don't conflict. Choose one, stick with it.

### Q: Can I run 000_LZ_Bootloader.ps1 multiple times?

**A**: Yes. It's fully idempotent. It will:
- Skip any steps already completed
- Resume from where it left off
- Validate existing resources
- Update secrets/variables only if needed

### Q: What if bootstrap fails halfway?

**A**: The script saves state to `.lz-bootloader-state.json`. Just fix the issue and re-run. It will:
1. Load the state file
2. Skip completed steps
3. Retry the failed step
4. Continue

### Q: Do I need to keep Initialize-CnaGitHubSecrets.ps1?

**A**: No, it's merged into 000_LZ_Bootloader.ps1. Keep it only as a reference if you want to understand OIDC patterns.

### Q: Can I customize the bootstrap?

**A**: The script has parameters:

```powershell
# Skip tool validation (if you already installed everything)
.\scripts\000_LZ_Bootloader.ps1 -SkipToolValidation

# Skip Azure setup (bring your own SP)
.\scripts\000_LZ_Bootloader.ps1 -SkipAzureSetup

# Custom state file location
.\scripts\000_LZ_Bootloader.ps1 -StateFile "my-state.json"

# Custom report directory
.\scripts\000_LZ_Bootloader.ps1 -ReportDirectory "my-reports"
```

---

## Next Steps

1. ✅ Run 000_LZ_Bootloader.ps1 (creates OIDC, secrets, TFC config)
2. ✅ Review generated bootstrap report
3. ✅ Merge any created PR
4. ✅ Workflow 010 runs automatically (terraform init, validate)
5. ⏭ Create workflow 020+ for terraform apply, deployments

---

## Support

For questions about:
- **OIDC best practices**: See `docs/bootstrap/OIDC-BEST-PRACTICES.md`
- **Script analysis**: See `docs/bootstrap/START-BOOTSTRAP-ANALYSIS.md`
- **Terraform Cloud**: See `docs/bootstrap/` and `terraform/` README
- **GitHub Actions**: Check `.github/workflows/010-terraform-init.yml`

