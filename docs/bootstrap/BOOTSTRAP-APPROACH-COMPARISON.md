# Bootstrap Approach Comparison

This document compares two approaches for bootstrapping Azure Landing Zone deployments: the **Traditional Approach** (existing repo) vs. the **Automated Approach** (new user-friendly flow).

## Overview

| Aspect | Traditional Approach | Automated Approach |
|--------|---------------------|-------------------|
| **Script** | `Start-Bootstrap.ps1` | `Initialize-LandingZone.ps1` |
| **Target User** | Existing repo owner | New customer with empty GitHub account |
| **Repository** | Pre-existing | Created automatically |
| **Naming** | Azure-style (`hcw-cf0bb74d4672`) | User-friendly (`contoso-azure-landing-zone`) |
| **PR Creation** | Manual | Automatic |
| **Workflow Trigger** | Manual (requires merge first) | Automatic (optional, after merge) |
| **Time to Complete** | 15-20 minutes | 5-7 minutes |
| **User Touch Points** | 5+ manual steps | 2-3 (config + merge + optional) |

---

## Traditional Approach: `Start-Bootstrap.ps1`

### Use Case
- You already have a GitHub repository
- You want to add Azure Landing Zone deployment to an existing codebase
- You're comfortable with Git operations

### Workflow

```
┌────────────────────────────────────────────────────────────┐
│ 1. PREREQUISITE: GitHub Repository Already Exists         │
├────────────────────────────────────────────────────────────┤
│ • User creates GitHub repo manually                        │
│ • Clones repo locally                                      │
│ • Repo can have any name                                   │
└────────────────────────────────────────────────────────────┘
                          ↓
┌────────────────────────────────────────────────────────────┐
│ 2. RUN: .\scripts\Start-Bootstrap.ps1                     │
├────────────────────────────────────────────────────────────┤
│ • Checks prerequisites (az, gh, git, terraform)            │
│ • Gathers configuration (org prefix, GitHub owner)         │
│ • Creates deployment folder: deployments/hcw-<tenant>      │
│ • Creates CODEOWNERS file                                  │
│ • Creates azure-auth-test.yml workflow                     │
│ • Sets up Azure OIDC (app, SP, RBAC, secrets)              │
└────────────────────────────────────────────────────────────┘
                          ↓
┌────────────────────────────────────────────────────────────┐
│ 3. MANUAL: Create and Push Branch                         │
├────────────────────────────────────────────────────────────┤
│ • git checkout -b bootstrap/initial-setup                  │
│ • git add deployments/                                     │
│ • git commit -m "Add GitHub config"                        │
│ • git push origin bootstrap/initial-setup                  │
└────────────────────────────────────────────────────────────┘
                          ↓
┌────────────────────────────────────────────────────────────┐
│ 4. MANUAL: Create Pull Request                            │
├────────────────────────────────────────────────────────────┤
│ • Go to GitHub web UI                                      │
│ • Create PR manually                                       │
│ • Add description and reviewers                            │
└────────────────────────────────────────────────────────────┘
                          ↓
┌────────────────────────────────────────────────────────────┐
│ 5. MANUAL: Merge PR                                       │
├────────────────────────────────────────────────────────────┤
│ • Review changes                                           │
│ • Merge PR to main branch                                  │
└────────────────────────────────────────────────────────────┘
                          ↓
┌────────────────────────────────────────────────────────────┐
│ 6. MANUAL: Trigger Workflow                               │
├────────────────────────────────────────────────────────────┤
│ • Go to Actions tab                                        │
│ • Find azure-auth-test workflow                            │
│ • Click "Run workflow" → "Run workflow"                    │
│ • Monitor for success                                      │
└────────────────────────────────────────────────────────────┘
```

### Pros ✅
- Works with existing repositories
- More control over each step
- Can customize before committing
- Good for teams with existing Git workflows

### Cons ❌
- Requires GitHub repo to already exist
- Multiple manual Git operations
- Manual PR creation
- Cannot auto-trigger workflow (not on main yet)
- More opportunities for user error
- Longer time to completion

---

## Automated Approach: `Initialize-LandingZone.ps1`

### Use Case
- You're starting fresh with an empty GitHub account
- You want the fastest path to a working deployment
- You prefer automation over manual control
- You're a new customer trying Azure Landing Zone for the first time

### Workflow

```
┌────────────────────────────────────────────────────────────┐
│ 1. RUN: .\scripts\Initialize-LandingZone.ps1              │
├────────────────────────────────────────────────────────────┤
│ Script prompts for:                                        │
│ • Org prefix: "contoso"                                    │
│ • Repo name: "contoso-azure-landing-zone"                  │
│ • Visibility: private/public                               │
│ • Owner: personal account or organization                  │
└────────────────────────────────────────────────────────────┘
                          ↓
┌────────────────────────────────────────────────────────────┐
│ 2. AUTO: GitHub Repository Created                        │
├────────────────────────────────────────────────────────────┤
│ • Creates repo on GitHub                                   │
│ • Initializes with README.md                               │
│ • Pushes main branch                                       │
│ • Clones to local directory                                │
│ • Uses user-friendly naming                                │
└────────────────────────────────────────────────────────────┘
                          ↓
┌────────────────────────────────────────────────────────────┐
│ 3. AUTO: Azure Bootstrap Runs                             │
├────────────────────────────────────────────────────────────┤
│ • Internally calls Start-Bootstrap.ps1                     │
│ • Creates deployment folder                                │
│ • Sets up Azure OIDC                                       │
│ • Creates CODEOWNERS and workflow files                    │
└────────────────────────────────────────────────────────────┘
                          ↓
┌────────────────────────────────────────────────────────────┐
│ 4. AUTO: Pull Request Created                             │
├────────────────────────────────────────────────────────────┤
│ • Creates branch: bootstrap/initial-setup                  │
│ • Commits all files                                        │
│ • Pushes branch                                            │
│ • Creates PR with comprehensive description                │
│ • Returns PR URL to user                                   │
└────────────────────────────────────────────────────────────┘
                          ↓
┌────────────────────────────────────────────────────────────┐
│ 5. MANUAL: Review and Merge PR                            │
├────────────────────────────────────────────────────────────┤
│ • User clicks PR URL                                       │
│ • Reviews changes (optional)                               │
│ • Clicks "Merge pull request"                              │
└────────────────────────────────────────────────────────────┘
                          ↓
┌────────────────────────────────────────────────────────────┐
│ 6. AUTO: Workflow Triggered (Optional)                    │
├────────────────────────────────────────────────────────────┤
│ • Script monitors for PR merge                             │
│ • Automatically triggers azure-auth-test workflow          │
│ • Monitors workflow completion                             │
│ • Reports success/failure                                  │
└────────────────────────────────────────────────────────────┘
```

### Pros ✅
- Fully automated from start to finish
- User-friendly repository naming
- No manual Git operations required
- Automatic PR creation with rich description
- Optional automatic workflow trigger
- Shortest time to completion (5-7 minutes)
- Fewer opportunities for user error
- Perfect for new customers

### Cons ❌
- Less control over individual steps
- Creates new repository (not suitable for existing repos)
- Requires script to complete before customization
- May feel "magical" for users who want to understand each step

---

## Decision Matrix

### Use **Start-Bootstrap.ps1** (Traditional) When:
- ✅ You already have a GitHub repository
- ✅ You want to add Landing Zone to an existing codebase
- ✅ You need full control over each Git operation
- ✅ You're comfortable with Git workflows
- ✅ You're working with a team and need custom PR descriptions
- ✅ You have existing DevOps processes to follow

### Use **Initialize-LandingZone.ps1** (Automated) When:
- ✅ You're starting fresh (empty GitHub account)
- ✅ You want the fastest setup experience
- ✅ You prefer automation over manual control
- ✅ You're a new customer evaluating Azure Landing Zone
- ✅ You want user-friendly repository naming
- ✅ You want automatic workflow triggering
- ✅ Time is critical (demo, POC, workshop)

---

## Feature Comparison Table

| Feature | Traditional | Automated |
|---------|------------|-----------|
| **Repository Creation** | ✋ Manual | ✅ Automatic |
| **Repository Naming** | 🤷 Any name | ✅ User-friendly pattern |
| **Azure OIDC Setup** | ✅ Yes | ✅ Yes |
| **CODEOWNERS Creation** | ✅ Yes | ✅ Yes |
| **Workflow File Creation** | ✅ Yes | ✅ Yes |
| **Git Branch Creation** | ✋ Manual | ✅ Automatic |
| **Git Commit** | ✋ Manual | ✅ Automatic |
| **Git Push** | ✋ Manual | ✅ Automatic |
| **PR Creation** | ✋ Manual | ✅ Automatic |
| **PR Description** | ✋ User writes | ✅ Comprehensive template |
| **Workflow Trigger** | ✋ Manual (after merge) | ✅ Optional automatic |
| **Workflow Monitoring** | ✋ Manual | ✅ Optional automatic |
| **Works with Existing Repo** | ✅ Yes | ❌ No (creates new) |
| **Time to Complete** | 15-20 min | 5-7 min |
| **User Touch Points** | 5+ | 2-3 |
| **Error Recovery** | Manual | Automatic |
| **Idempotent** | ✅ Yes | ✅ Yes |

---

## Migration Path

### Switching from Traditional to Automated (Not Recommended)
If you've already started with `Start-Bootstrap.ps1`, **continue with it**. The automated approach is for greenfield scenarios only.

### Switching from Automated to Traditional (Not Common)
The automated approach creates everything the traditional approach would have created, so there's no need to switch back. Both result in the same Azure resources and GitHub configuration.

---

## Examples

### Example 1: New Customer, Empty GitHub Account
**Recommendation:** Use `Initialize-LandingZone.ps1`

```powershell
# Run once, get everything
.\scripts\Initialize-LandingZone.ps1 -OrgPrefix "contoso" -RepoName "contoso-azure-lz"

# Follow prompts, merge PR, done!
```

**Result:** Repository created, Azure configured, PR ready, workflow triggered - all in ~7 minutes.

---

### Example 2: Existing Repository with Code
**Recommendation:** Use `Start-Bootstrap.ps1`

```powershell
# Your repo: https://github.com/contoso/my-existing-app
cd my-existing-app
.\scripts\Start-Bootstrap.ps1

# Create PR manually, merge, trigger workflow
```

**Result:** Landing Zone added to existing repo without disrupting current structure.

---

### Example 3: Workshop or Demo
**Recommendation:** Use `Initialize-LandingZone.ps1`

```powershell
# Fastest path for demos
.\scripts\Initialize-LandingZone.ps1 -OrgPrefix "demo" -RepoName "azure-lz-demo"

# Wait for auto-trigger, show green workflow
```

**Result:** Impressive automated setup, minimal manual steps, great for live demos.

---

## Conclusion

Both approaches lead to the same outcome: a fully configured Azure Landing Zone deployment ready for production use. Choose the approach that matches your scenario:

- **Traditional** = Existing repo + Full control
- **Automated** = New repo + Maximum speed

For most **new customers**, the automated approach (`Initialize-LandingZone.ps1`) provides the best experience with the shortest time to value.
