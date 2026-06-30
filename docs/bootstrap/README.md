# Landing Zone Phase 0 Bootstrap Documentation

**Last Updated**: 2026-06-30  
**Status**: ✅ Phase 0 bootstrap complete  
**Next**: Run workflow 010 after Phase 0

---

## Quick Start (5 minutes)

### Single Command
```powershell
.\scripts\000_LZ_Bootloader.ps1
```

The script will:
1. ✓ Validate CLI tools (install if needed)
2. ✓ Prompt for Azure, GitHub, Terraform Cloud authentication
3. ✓ Create OIDC service principals (main/dev/prod)
4. ✓ Configure GitHub secrets, variables, environments
5. ✓ Set up Terraform Cloud integration
6. ✓ Generate audit report
7. ? Optional: Create PR with bootstrap artifacts

**Time**: ~5-10 minutes (depending on auth latency)

---

## What Gets Created

### Azure (Entra ID)
- 3 app registrations: `sp-terraform-main-prod`, `sp-terraform-dev-prod`, `sp-terraform-prod-prod`
- 3 service principals with Contributor role (Main) or Contributor + User Access Admin (Dev/Prod)
- 6+ federated OIDC credentials (scoped to branches/environments)
- RBAC role assignments at subscription level
- ✅ NO secrets created (OIDC only)
- ✅ NO Owner roles assigned

### GitHub
- Repository secrets: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`
- Repository variables: `AZURE_REGION`, `AZURE_REGION_CODE`, `ORG_PREFIX`, `TF_VERSION`, etc.
- GitHub environments: `dev`, `prod`, `hub` (hub is approval gate)
- `.lz-bootloader-state.json` (state tracking for idempotency)

### Terraform Cloud
- Organization & workspace configuration
- API token stored securely in GitHub secrets
- Ready for `terraform init` in workflow 010

---

## Architecture Overview

### Trust Chain
```
GitHub Actions Runner
    ↓ (OIDC Token)
Azure Entra ID
    ↓ (Token Exchange)
Service Principal (Main/Dev/Prod)
    ↓ (RBAC)
Azure Subscription Resources
```

### Layer Separation
```
├─ Main Layer (Continuous Deployment)
│  └─ SP: sp-terraform-main-prod
│     └─ Scoped to: main branch only
│     └─ Purpose: terraform apply on every push to main
│
├─ Dev Environment (Development)
│  └─ SP: sp-terraform-dev-prod
│     └─ Scoped to: environment:dev
│     └─ Purpose: Rapid iteration, full RBAC management
│
└─ Prod Environment (Production)
   └─ SP: sp-terraform-prod-prod
      └─ Scoped to: environment:prod + environment:hub (approval gate)
      └─ Purpose: Gated deployments with manual approval
```

---

## Phases

### Phase 0: Local Bootstrap (THIS)
**Script**: `000_LZ_Bootloader.ps1`  
**User Action**: Run once locally  
**Duration**: ~5-10 minutes

```
Validates CLIs
    ↓
Authenticates (Azure, GitHub, TFC)
    ↓
Creates OIDC service principals
    ↓
Configures GitHub secrets/variables/environments
    ↓
Sets up Terraform Cloud
    ↓
Generates audit report
    ↓
✓ Phase 0 Complete
```

### Phase 0.1: Workflow Initialization
**Workflow**: `.github/workflows/010-terraform-init.yml`  
**Trigger**: Push to main (automatic)  
**Duration**: ~2-3 minutes

```
Validates Azure OIDC
    ↓
Initializes Terraform (TFC backend)
    ↓
Validates Terraform code
    ↓
Plans global/workload resources
    ↓
✓ Phase 0.1 Complete
```

### Phase 1: Infrastructure Deployment
**Workflow**: `.github/workflows/020-terraform-apply.yml` (to be created)  
**Trigger**: Manual approval or push to main  
**Duration**: ~5-15 minutes

```
Applies Terraform plan
    ↓
Deploys workload resources
    ↓
Validates connectivity
    ↓
✓ Phase 1 Complete
```

### Phase 2+: Advanced Deployments
**Workflows**: 030-connectivity, 040-management, 050-workloads (to be created)

---

## State Management

### Bootloader State File
**Location**: `.lz-bootloader-state.json`

```json
{
  "timestamp": "2026-06-30 14:30:00",
  "completed": [
    "cli-validation",
    "azure-auth",
    "github-auth",
    "tfc-auth",
    "config-gathered",
    "azure-oidc-setup",
    "github-secrets",
    "github-environments",
    "tfc-setup",
    "report-generated"
  ],
  "org_prefix": "lz",
  "environments": ["dev", "prod"],
  "region": "eastus",
  "region_code": "eus",
  "azure_sps": { ... },
  "tfc_organization": "my-company",
  "tfc_token_set": true
}
```

**Purpose**: Tracks completed steps for idempotency  
**Safe to Delete**: Yes, anytime (resets bootstrap)

### Bootstrap Report
**Location**: `.reports/bootstrap/YYYYMMDD-HHMMSS-bootstrap-report.md`

Contains:
- Configuration summary
- Service principal IDs and roles
- Federated credential subjects
- GitHub secrets/variables
- Terraform Cloud configuration
- Next steps

**Purpose**: Audit trail, verification, recovery  
**Keep**: Yes, for compliance

### Terraform State
**Location**: Terraform Cloud (configured by bootstrap)  
**Access**: https://app.terraform.io (after merging bootstrap PR)

---

## Security Checklist

✅ All prerequisites met:
- [ ] CLI tools installed (az, gh, git, terraform)
- [ ] Azure account with subscription Owner role
- [ ] GitHub account with repository access
- [ ] Terraform Cloud free account

✅ During bootstrap:
- [ ] No plaintext secrets in terminal
- [ ] OIDC tokens are ephemeral (1-hour TTL)
- [ ] Service principals have Contributor only (no Owner)
- [ ] Federated credentials are scoped to specific branches/environments
- [ ] GitHub secrets are encrypted and never exposed in logs

✅ After bootstrap:
- [ ] Review bootstrap report for unexpected resources
- [ ] Verify GitHub secrets are set correctly
- [ ] Test workflow 010 on a PR (should pass terraform plan)
- [ ] Verify Terraform Cloud state is populated

---

## Troubleshooting

### CLI Tool Not Found
**Problem**: Script says "az not found in PATH"  
**Solution**: Script will prompt to install. Follow the instructions or:
```powershell
# Windows (choco)
choco install azure-cli
choco install github-cli
choco install terraform
choco install git

# macOS (brew)
brew install azure-cli
brew install gh
brew install terraform
brew install git
```

### Azure Login Failed
**Problem**: "Azure login failed"  
**Solution**: 
1. Make sure you're using an account with Owner role on target subscription
2. If multi-tenant, specify tenant: `az login --tenant contoso.onmicrosoft.com`
3. Check browser popup for authentication prompt

### GitHub Auth Failed
**Problem**: "GitHub login failed"  
**Solution**:
1. Ensure you have repo write access
2. Generate a personal access token: https://github.com/settings/tokens
3. Run: `gh auth login --with-token` (paste token)

### Terraform Cloud Token Issues
**Problem**: "Could not store TFC token"  
**Solution**:
1. Verify you generated token at https://app.terraform.io/settings/tokens
2. Copy the full token (not truncated)
3. Script will prompt again; paste it directly

### Bootstrap Already Completed
**Problem**: "Skipping, already created"  
**Solution**: This is normal. The script is idempotent and tracking state.
- To reset: `rm .lz-bootloader-state.json`
- Then re-run the script

### Workflow 010 Failed
**Problem**: "Terraform init failed" in workflow logs  
**Solution**:
1. Check GitHub Actions logs (Actions tab in GitHub)
2. Verify `.github/workflows/010-terraform-init.yml` exists
3. Ensure TFC workspace is created (script should have done this)
4. Check Terraform Cloud organization/workspace settings

---

## What's Different from Old Approaches

### vs. Start-Bootstrap.ps1
- ✅ Three separate SPs per layer (instead of single monolithic SP)
- ✅ No User Access Administrator on Main SP (least privilege)
- ✅ Terraform Cloud support built-in (instead of Azure Storage)
- ✅ Better OIDC subject scoping
- ✅ Validation that no SP has Owner role

### vs. Manual Setup
- ✅ Automated (no manual Azure portal clicks)
- ✅ Idempotent (safe to rerun)
- ✅ Auditable (generates report)
- ✅ Consistent (follows best practices)
- ✅ Workflow-aware (prepares for CI/CD)

---

## Files & Directories

```
scripts/
└─ 000_LZ_Bootloader.ps1              # Main entry point

.github/workflows/
└─ 010-terraform-init.yml             # Phase 0.1 (auto-runs after Phase 0)

docs/bootstrap/
├─ README.md                          # This file
├─ BOOTSTRAP-DECISIONS.md             # Script consolidation rationale
├─ BOOTSTRAP-SCRIPT-CONSOLIDATION.md  # Migration guide
├─ OIDC-BEST-PRACTICES.md            # Reference implementation
├─ OIDC-SCRIPT-ANALYSIS.md           # Detailed analysis
└─ START-BOOTSTRAP-ANALYSIS.md       # Old approach comparison

terraform/
├─ live/                              # Live infrastructure configs
├─ modules/                           # Reusable modules
└─ backend-bootstrap/                 # Initial backend setup (manual, if using Azure Storage)

.lz-bootloader-state.json             # Bootstrap state (gitignore'd)
.reports/bootstrap/                   # Bootstrap audit reports
```

---

## FAQ

### Q: Do I need to run this script every time?
**A**: No. Run it once to bootstrap. After that, use GitHub Actions (workflows 010+) for deployments.

### Q: What if I want to add a new environment?
**A**: Edit `.lz-bootloader-state.json`, add the environment to the `environments` list, and re-run. The script will create a new SP and configure GitHub.

### Q: Can I use this with an existing Azure subscription?
**A**: Yes. The script checks for existing resources (app registrations, SPs, role assignments) and reuses them (idempotent).

### Q: Where are my OIDC credentials stored?
**A**: 
- Azure: Federated credentials in Entra app registrations (not downloadable, tokens are short-lived)
- GitHub: Repository secrets (encrypted, never exposed)
- Local terminal: Nowhere (script doesn't persist them)

### Q: What if I mess up the GitHub setup?
**A**: Delete the GitHub secrets and re-run the script. It will recreate them.

### Q: Can I use this for multiple environments/subscriptions?
**A**: Currently optimized for single subscription. For multi-subscription, you can:
1. Run the script once per subscription (it will create separate SPs and state)
2. Or manually manage additional subscriptions

### Q: How do I remove this bootstrap?
**A**: You have two options:
1. **Keep it** (recommended) — It's harmless, enables automation
2. **Delete** — Delete Azure app registrations, GitHub secrets, state file

---

## Next Steps

1. ✅ **Run Phase 0**: `.\scripts\000_LZ_Bootloader.ps1`
2. ✅ **Review Report**: Check `.reports/bootstrap/*.md`
3. ✅ **Merge PR** (if created): Approve and merge bootstrap artifacts
4. ✅ **Wait for Workflow 010**: Should run automatically after merge
5. ✅ **Review Plan**: Check workflow logs for terraform plan output
6. ⏭ **Phase 1**: Create workflow 020 for `terraform apply`

---

## Support & Resources

- **Terraform Cloud Docs**: https://www.terraform.io/cloud-docs
- **GitHub Actions OIDC**: https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect
- **Azure OIDC**: https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-with-oidc
- **Script Help**: Add `-Help` flag to 000_LZ_Bootloader.ps1

---

## Version History

| Date | Version | Changes |
|------|---------|---------|
| 2026-06-30 | 1.0 | Initial release (000_LZ_Bootloader.ps1 + 010-terraform-init.yml) |
| TBD | 1.1 | Multi-subscription support |
| TBD | 2.0 | Azure Vault integration |

---

**Questions?** Check the detailed docs in `docs/bootstrap/` or GitHub Issues.
