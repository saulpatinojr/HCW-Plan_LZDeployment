# 🔥 Security Audit - Quick Action Checklist

**Repository**: HCW-Demo-LZDeployment  
**Priority**: Items you should fix THIS WEEK

---

## ⚡ Critical Fixes (Do Today)

### 1. Verify Service Principal Permissions (30 min)
```bash
# Check what roles your GitHub Actions SP has
az role assignment list \
  --assignee <YOUR_CLIENT_ID> \
  --all \
  --query "[].{Role:roleDefinitionName, Scope:scope}" \
  --output table

# ❌ If you see "Owner" anywhere -> FIX IMMEDIATELY
# ✅ Should only see "Contributor" on specific subscriptions
```

**Action if Owner found**:
```bash
# Remove Owner role
az role assignment delete \
  --assignee <CLIENT_ID> \
  --role Owner \
  --scope /subscriptions/<SUBSCRIPTION_ID>

# Add Contributor instead
az role assignment create \
  --assignee <CLIENT_ID> \
  --role Contributor \
  --scope /subscriptions/<SUBSCRIPTION_ID>
```

---

### 2. Secure Terraform State Storage (15 min)
```bash
# Check current public access status
az storage account show \
  --name <YOUR_STATE_STORAGE_ACCOUNT> \
  --query publicNetworkAccess \
  --output tsv

# If it returns "Enabled" -> FIX IMMEDIATELY
```

**Action**:
```bash
# Disable public access
az storage account update \
  --name <YOUR_STATE_STORAGE_ACCOUNT> \
  --resource-group <RG_NAME> \
  --public-network-access Disabled

# Add firewall rule for GitHub Actions if needed
az storage account network-rule add \
  --account-name <YOUR_STATE_STORAGE_ACCOUNT> \
  --ip-address <GITHUB_RUNNER_IP>
```

**Alternative (Terraform)**:
Edit `terraform/backend-bootstrap/variables.tf`:
```hcl
variable "allow_public_access_during_setup" {
  default = false  # Change this from true
}
```

---

### 3. Enable GitHub Secret Scanning (5 min)
1. Go to your repo: https://github.com/saulpatinojr/HCW-Demo-LZDeployment
2. Click **Settings** → **Code security and analysis**
3. Enable:
   - ✅ **Dependency graph**
   - ✅ **Dependabot alerts**
   - ✅ **Secret scanning**
   - ✅ **Push protection** (prevents commits with secrets)

**No code changes needed - just enable in GitHub UI**

---

### 4. Add PowerShell Input Validation (10 min)
Edit `terraform/scripts/Cleanup-ExpiredSandboxResources.ps1`:

**Replace lines 5-9**:
```powershell
# OLD (INSECURE)
param(
    [Parameter(Mandatory = $true)]
    [string]$SandboxSubscriptionId,
)
```

**With**:
```powershell
# NEW (SECURE)
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$')]
    [string]$SandboxSubscriptionId,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("true", "false")]
    [string]$DryRun = "false"
)

# Validate subscription is actually sandbox
$sub = Get-AzSubscription -SubscriptionId $SandboxSubscriptionId -ErrorAction Stop
if ($sub.Tags['purpose'] -ne 'sandbox') {
    Write-Error "ERROR: Subscription is not tagged as sandbox. Aborting."
    exit 1
}
```

---

## 🔨 High Priority Fixes (Do This Week)

### 5. Enable Microsoft Defender for Cloud (1 hour)
**Via Portal** (fastest):
1. Go to [Microsoft Defender for Cloud](https://portal.azure.com/#view/Microsoft_Azure_Security/SecurityMenuBlade/~/GettingStarted)
2. Click **Environment settings**
3. Select your **Platform Management** subscription
4. Click **Enable all Microsoft Defender plans**
5. Configure **Security contacts** → Add your email

**Cost**: ~$50/month per subscription to start

---

### 6. Pin GitHub Actions to Commit SHAs (30 min)
Edit `.github/workflows/terraform-plan.yml` and `.github/workflows/terraform-apply.yml`:

**Find and replace**:
```yaml
# BEFORE (vulnerable to supply chain attacks)
- uses: actions/checkout@v4
- uses: hashicorp/setup-terraform@v3
- uses: azure/login@v2
```

**AFTER (pinned and secure)**:
```yaml
- uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11  # v4.1.1
- uses: hashicorp/setup-terraform@651471c36a6092792c552e8b1bef71e592b462d8  # v3.1.1
- uses: azure/login@92a5484dfaf04ca78a94597f4f19fea633851fa2  # v2.0.0
```

**How to find commit SHAs**:
1. Go to https://github.com/actions/checkout/releases
2. Find v4.1.1 → Click "..." → Copy SHA
3. Repeat for other actions

---

### 7. Configure Azure Firewall Threat Intelligence (20 min)
If you're using Azure Firewall (not Palo/Fortinet):

Edit `terraform/modules/hub-network/main.tf`, add after line 185:
```hcl
resource "azurerm_firewall_policy" "hub" {
  count               = var.firewall_type == "azfw" ? 1 : 0
  name                = "afwp-hub-${var.region_code}-${var.environment}-01"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  sku                 = var.azfw_tier
  
  threat_intelligence_mode = "Alert"  # Or "Deny" for production
  
  dns {
    proxy_enabled = true
  }
}

# Update firewall resource to reference policy
resource "azurerm_firewall" "hub" {
  # ... existing config ...
  firewall_policy_id = azurerm_firewall_policy.hub[0].id  # ADD THIS LINE
}
```

---

## 📊 Verification Commands

### Check Current Security Posture
```bash
# 1. Check storage account security
az storage account show \
  --name <STATE_ACCOUNT> \
  --query "{HTTPS:enableHttpsTrafficOnly, TLS:minimumTlsVersion, PublicAccess:publicNetworkAccess}" \
  --output table

# 2. Check service principal roles
az role assignment list \
  --assignee <GITHUB_SP_CLIENT_ID> \
  --query "[].{Role:roleDefinitionName, Scope:scope}" \
  --output table

# 3. Check Defender status
az security pricing list --output table

# 4. Verify no secrets in git history
git log --all --pretty=format: --name-only --diff-filter=A | sort -u | xargs git log -S "password\|secret\|key" --source --all
```

---

## 💡 Quick Wins (Low Effort, High Impact)

| Action | Time | Cost | Risk Reduction |
|---|---|---|---|
| Enable GitHub secret scanning | 5 min | $0 | 15% |
| Fix PowerShell validation | 10 min | $0 | 10% |
| Verify SP has only Contributor | 30 min | $0 | 30% |
| Disable public state access | 15 min | $0 | 20% |
| Pin GitHub Actions versions | 30 min | $0 | 5% |
| Enable Defender (1 sub) | 1 hour | $50/mo | 20% |

**Total: ~2.5 hours, $50/month, ~60% risk reduction**

---

## 🚨 Red Flags to Check NOW

Run these commands and check for problems:

```bash
# 1. Is state storage public?
az storage account show --name <STATE_ACCOUNT> \
  --query "publicNetworkAccess" \
  --output tsv
# ❌ If "Enabled" -> CRITICAL ISSUE

# 2. Does SP have Owner role?
az role assignment list --assignee <CLIENT_ID> \
  --query "[?roleDefinitionName=='Owner']" \
  --output table
# ❌ If ANY results -> CRITICAL ISSUE

# 3. Are secrets exposed in .tfvars?
git ls-files | grep ".tfvars$"
# ❌ If ANY results -> HIGH ISSUE (should be in .gitignore)

# 4. Is TLS 1.2 enforced?
az storage account show --name <STATE_ACCOUNT> \
  --query "minimumTlsVersion" \
  --output tsv
# ❌ If NOT "TLS1_2" -> HIGH ISSUE

# 5. Is HTTPS enforced?
az storage account show --name <STATE_ACCOUNT> \
  --query "enableHttpsTrafficOnly" \
  --output tsv
# ❌ If NOT "true" -> HIGH ISSUE
```

---

## 📞 Who to Contact

| Issue | Contact | Urgency |
|---|---|---|
| Service Principal has Owner role | **Cloud Security Team** | **IMMEDIATE** |
| State storage is public | **Platform Engineering** | **TODAY** |
| GitHub secrets found | **DevSecOps Team** | **TODAY** |
| Budget approval needed | **Engineering Manager** | This week |
| Compliance questions | **Compliance Officer** | This week |

---

## 📚 Full Documentation

- **Detailed audit**: See `SECURITY-AUDIT-REPORT.md` (56 findings with code examples)
- **Executive summary**: See `SECURITY-AUDIT-EXECUTIVE-SUMMARY.md` (leadership overview)
- **This checklist**: Quick actions you can do now

---

## ✅ Completion Checklist

Print this and check off as you go:

- [ ] Verified service principal has only Contributor role (not Owner)
- [ ] Disabled public access on Terraform state storage account
- [ ] Enabled GitHub secret scanning with push protection
- [ ] Added input validation to PowerShell cleanup script
- [ ] Enabled Microsoft Defender for Cloud on at least 1 subscription
- [ ] Pinned GitHub Actions to commit SHAs
- [ ] Configured Azure Firewall threat intelligence (if using Azure FW)
- [ ] Ran verification commands and documented results
- [ ] Scheduled meeting with security team to review full audit
- [ ] Created GitHub issues for remaining findings

---

**Goal**: Get to ✅ 5/10 items complete by end of this week (Friday)

**Time Required**: ~4 hours total  
**Cost**: $50/month (Defender for 1 subscription)  
**Risk Reduction**: ~60%

---

*Questions? See full audit report (`SECURITY-AUDIT-REPORT.md`) or contact your security team.*
