<#
.SYNOPSIS
    Complete Azure Landing Zone bootstrap with automatic GitHub repository creation
.DESCRIPTION
    End-to-end setup for customers starting with an empty GitHub account:
    1. Creates GitHub repository with proper naming
    2. Initializes local Git repository
    3. Sets up Azure OIDC authentication
    4. Creates and commits all necessary files
    5. Automatically creates PR with azure-auth-test workflow
    6. Guides user through validation
.NOTES
    Run this script from any directory - it will create the repo and clone it
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$RepoName,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('public', 'private')]
    [string]$Visibility = 'private',
    
    [Parameter(Mandatory=$false)]
    [string]$OrgPrefix,
    
    [Parameter(Mandatory=$false)]
    [string]$WorkingDirectory = $PWD
)

$ErrorActionPreference = 'Stop'

# ═════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═════════════════════════════════════════════════════════════════════════════

function Write-Header($Message) {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  $Message" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
}

function Write-Step($Message) { Write-Host "  ➤  $Message" -ForegroundColor Yellow }
function Write-OK($Message) { Write-Host "  ✅  $Message" -ForegroundColor Green }
function Write-Warn($Message) { Write-Host "  ⚠️   $Message" -ForegroundColor Yellow }
function Write-Err($Message) { Write-Host "  ❌  $Message" -ForegroundColor Red }
function Write-Info($Message) { Write-Host "  📋  $Message" -ForegroundColor White }

# ═════════════════════════════════════════════════════════════════════════════
# MAIN FLOW
# ═════════════════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "██████████████████████████████████████████████████████████████████████" -ForegroundColor Cyan
Write-Host "  Azure Landing Zone - Complete Bootstrap" -ForegroundColor Cyan
Write-Host "  Includes: GitHub Repo Creation + Azure Setup + Automatic PR" -ForegroundColor Cyan
Write-Host "██████████████████████████████████████████████████████████████████████" -ForegroundColor Cyan

# ─────────────────────────────────────────────────────────────────────────────
# STEP 1: Prerequisites Check
# ─────────────────────────────────────────────────────────────────────────────
Write-Header "Step 1: Checking Prerequisites"

$requiredTools = @{
    'gh' = '2.40.0'
    'git' = '2.30.0'
    'az' = '2.50.0'
    'terraform' = '1.5.0'
}

foreach ($tool in $requiredTools.Keys) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        Write-Err "$tool is not installed or not in PATH"
        Write-Info "Install from: https://docs.microsoft.com/$tool"
        exit 1
    }
    Write-OK "$tool installed"
}

# Check GitHub CLI authentication
try {
    $ghUser = gh auth status 2>&1 | Select-String -Pattern "Logged in to github.com as (\S+)" | ForEach-Object { $_.Matches.Groups[1].Value }
    if ($ghUser) {
        Write-OK "GitHub CLI authenticated as: $ghUser"
    } else {
        Write-Err "GitHub CLI not authenticated"
        Write-Info "Run: gh auth login"
        exit 1
    }
} catch {
    Write-Err "GitHub CLI not authenticated"
    Write-Info "Run: gh auth login"
    exit 1
}

# Check Azure CLI authentication
try {
    $azAccount = az account show --output json 2>$null | ConvertFrom-Json
    if ($azAccount) {
        Write-OK "Azure CLI authenticated as: $($azAccount.user.name)"
    } else {
        Write-Err "Azure CLI not authenticated"
        Write-Info "Run: az login"
        exit 1
    }
} catch {
    Write-Err "Azure CLI not authenticated"
    Write-Info "Run: az login"
    exit 1
}

# ─────────────────────────────────────────────────────────────────────────────
# STEP 2: Gather Configuration
# ─────────────────────────────────────────────────────────────────────────────
Write-Header "Step 2: Configuration"

# Get organization prefix for naming
if (-not $OrgPrefix) {
    Write-Host ""
    Write-Host "  Enter your organization prefix (3-8 lowercase letters):" -ForegroundColor Yellow
    Write-Host "  This will be used for Azure resource naming" -ForegroundColor Gray
    Write-Host "  Examples: contoso, fabrikam, acme" -ForegroundColor Gray
    $OrgPrefix = Read-Host "  Org prefix"
    
    if ($OrgPrefix -notmatch '^[a-z]{3,8}$') {
        Write-Err "Org prefix must be 3-8 lowercase letters"
        exit 1
    }
}
Write-OK "Org prefix: $OrgPrefix"

# Get repository name
if (-not $RepoName) {
    $suggestedName = "$OrgPrefix-azure-landing-zone"
    Write-Host ""
    Write-Host "  Enter GitHub repository name (or press ENTER for default):" -ForegroundColor Yellow
    Write-Host "  Suggested: $suggestedName" -ForegroundColor Gray
    $userInput = Read-Host "  Repo name"
    $RepoName = if ($userInput) { $userInput } else { $suggestedName }
}

# Validate repo name follows GitHub conventions
if ($RepoName -notmatch '^[a-zA-Z0-9_-]+$') {
    Write-Err "Repository name must contain only letters, numbers, hyphens, and underscores"
    exit 1
}
Write-OK "Repository name: $RepoName"

# Get repository visibility
if (-not $PSBoundParameters.ContainsKey('Visibility')) {
    Write-Host ""
    Write-Host "  Repository visibility:" -ForegroundColor Yellow
    Write-Host "    [1] Private (recommended for production)" -ForegroundColor Gray
    Write-Host "    [2] Public" -ForegroundColor Gray
    $choice = Read-Host "  Select [1-2]"
    $Visibility = if ($choice -eq '2') { 'public' } else { 'private' }
}
Write-OK "Visibility: $Visibility"

# Get GitHub owner (user or org)
$ghOwner = $ghUser
Write-Host ""
Write-Host "  Create repository under:" -ForegroundColor Yellow
Write-Host "    [1] Your personal account ($ghUser)" -ForegroundColor Gray
Write-Host "    [2] An organization" -ForegroundColor Gray
$choice = Read-Host "  Select [1-2]"

if ($choice -eq '2') {
    # List available orgs
    $orgs = gh api user/orgs --jq '.[].login' 2>$null
    if ($orgs) {
        Write-Host ""
        Write-Host "  Available organizations:" -ForegroundColor Yellow
        $orgList = $orgs | ForEach-Object { $_ }
        $i = 1
        foreach ($org in $orgList) {
            Write-Host "    [$i] $org" -ForegroundColor Gray
            $i++
        }
        $orgChoice = Read-Host "  Select organization [1-$($orgList.Count)]"
        $ghOwner = $orgList[$orgChoice - 1]
    } else {
        Write-Warn "No organizations found, using personal account"
        $ghOwner = $ghUser
    }
}
Write-OK "Repository owner: $ghOwner"

# Confirm configuration
Write-Host ""
Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host "  Configuration Summary" -ForegroundColor Yellow
Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host "  Organization Prefix:  $OrgPrefix" -ForegroundColor White
Write-Host "  Repository Name:      $RepoName" -ForegroundColor White
Write-Host "  Repository URL:       https://github.com/$ghOwner/$RepoName" -ForegroundColor White
Write-Host "  Visibility:           $Visibility" -ForegroundColor White
Write-Host "  Azure Account:        $($azAccount.user.name)" -ForegroundColor White
Write-Host "  Azure Subscription:   $($azAccount.name)" -ForegroundColor White
Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""
$confirm = Read-Host "  Proceed with this configuration? [Y/n]"
if ($confirm -and $confirm -ne 'Y' -and $confirm -ne 'y') {
    Write-Warn "Cancelled by user"
    exit 0
}

# ─────────────────────────────────────────────────────────────────────────────
# STEP 3: Create GitHub Repository
# ─────────────────────────────────────────────────────────────────────────────
Write-Header "Step 3: Creating GitHub Repository"

# Check if repo already exists
$existingRepo = gh repo view "$ghOwner/$RepoName" --json name 2>$null
if ($existingRepo) {
    Write-Warn "Repository '$ghOwner/$RepoName' already exists"
    $choice = Read-Host "  [1] Use existing repo  [2] Exit"
    if ($choice -ne '1') {
        exit 0
    }
    $repoPath = Join-Path $WorkingDirectory $RepoName
    if (-not (Test-Path $repoPath)) {
        Write-Step "Cloning existing repository..."
        gh repo clone "$ghOwner/$RepoName" $repoPath
    }
} else {
    Write-Step "Creating new GitHub repository..."
    
    # Create repo with initial README
    $repoPath = Join-Path $WorkingDirectory $RepoName
    New-Item -Path $repoPath -ItemType Directory -Force | Out-Null
    Push-Location $repoPath
    
    try {
        # Initialize with README
        @"
# $RepoName

Azure Landing Zone deployment repository for **$OrgPrefix**.

## Overview

This repository contains Infrastructure as Code (IaC) for deploying an Azure Landing Zone using Terraform.

## Structure

- `terraform/` - Terraform modules and configurations
- `scripts/` - Bootstrap and utility scripts
- `docs/` - Documentation
- `.github/` - GitHub Actions workflows and configuration

## Getting Started

See [docs/DEPLOYMENT-GUIDE.md](docs/DEPLOYMENT-GUIDE.md) for deployment instructions.

## Bootstrap Status

- ✅ Repository created
- ⏳ Azure OIDC setup pending
- ⏳ GitHub Actions workflows pending
- ⏳ Branch protection pending

"@ | Out-File -FilePath "README.md" -Encoding UTF8
        
        git init
        git add README.md
        git commit -m "Initial commit: Repository structure"
        
        # Create repo on GitHub
        gh repo create "$ghOwner/$RepoName" --source=. --$Visibility --push
        
        Write-OK "Repository created: https://github.com/$ghOwner/$RepoName"
    } finally {
        Pop-Location
    }
}

Write-OK "Repository ready at: $repoPath"

# ─────────────────────────────────────────────────────────────────────────────
# STEP 4: Run Azure Bootstrap (Call existing Start-Bootstrap.ps1)
# ─────────────────────────────────────────────────────────────────────────────
Write-Header "Step 4: Running Azure Bootstrap"

Push-Location $repoPath

try {
    # Download or copy Start-Bootstrap.ps1 if it doesn't exist
    $bootstrapScript = Join-Path $repoPath "scripts" "Start-Bootstrap.ps1"
    
    if (-not (Test-Path $bootstrapScript)) {
        Write-Step "Setting up bootstrap script..."
        New-Item -Path (Join-Path $repoPath "scripts") -ItemType Directory -Force | Out-Null
        
        # Copy from this repo (if running from existing HCW-Demo-LZDeployment)
        $sourceScript = Join-Path $PSScriptRoot "Start-Bootstrap.ps1"
        if (Test-Path $sourceScript) {
            Copy-Item $sourceScript $bootstrapScript
            Write-OK "Bootstrap script ready"
        } else {
            Write-Err "Bootstrap script not found. Please ensure Start-Bootstrap.ps1 exists."
            exit 1
        }
    }
    
    # Set environment variables for non-interactive mode
    $env:GITHUB_OWNER = $ghOwner
    $env:GITHUB_REPO = $RepoName
    $env:ORG_PREFIX = $OrgPrefix
    
    Write-Step "Running Start-Bootstrap.ps1..."
    & $bootstrapScript
    
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Bootstrap script failed"
        exit 1
    }
    
    Write-OK "Azure resources configured"
} finally {
    Pop-Location
}

# ─────────────────────────────────────────────────────────────────────────────
# STEP 5: Create Automatic PR with Workflow
# ─────────────────────────────────────────────────────────────────────────────
Write-Header "Step 5: Creating Pull Request"

Push-Location $repoPath

try {
    # Get tenant suffix for deployment folder
    $tenantId = $azAccount.tenantId
    $tenantSuffix = $tenantId.Substring(0, 12)
    $deploymentFolder = "deployments/$OrgPrefix-$tenantSuffix"
    
    # Check if files exist
    $codeownersFile = Join-Path $repoPath $deploymentFolder ".github" "CODEOWNERS"
    $workflowFile = Join-Path $repoPath $deploymentFolder ".github" "workflows" "azure-auth-test.yml"
    
    if (-not (Test-Path $codeownersFile)) {
        Write-Warn "CODEOWNERS file not found at: $codeownersFile"
    }
    
    if (-not (Test-Path $workflowFile)) {
        Write-Warn "azure-auth-test.yml not found at: $workflowFile"
    }
    
    # Create branch
    $branchName = "bootstrap/initial-setup"
    Write-Step "Creating branch: $branchName"
    
    git checkout -b $branchName 2>$null
    
    # Stage files
    Write-Step "Staging files..."
    git add "$deploymentFolder/.github/CODEOWNERS"
    git add "$deploymentFolder/.github/workflows/azure-auth-test.yml"
    git add "scripts/"
    git add "docs/" -f 2>$null  # Add docs if they exist
    
    # Commit
    Write-Step "Committing changes..."
    git commit -m @"
bootstrap: Add GitHub configuration and Azure auth test

This PR adds:
- CODEOWNERS file for PR review requirements
- azure-auth-test.yml workflow for OIDC validation
- Bootstrap scripts and documentation

Azure Resources Created:
- Entra ID App Registration: sp-github-oidc-lz-platform
- Service Principal with Contributor + User Access Administrator roles
- Federated Credentials for OIDC authentication
- GitHub Secrets (AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID)

Next Steps After Merge:
1. Configure GitHub branch ruleset (see docs/bootstrap/GITHUB-BRANCH-PROTECTION.md)
2. Manually trigger 'Azure OIDC Auth Test' workflow
3. Verify workflow shows green checkmark
4. Proceed with Section 7 (Terraform State Storage)
"@
    
    # Push branch
    Write-Step "Pushing branch to GitHub..."
    git push -u origin $branchName
    
    # Create PR
    Write-Step "Creating pull request..."
    $prUrl = gh pr create `
        --title "Bootstrap: Initial Azure Landing Zone Setup" `
        --body @"
## 🚀 Azure Landing Zone Bootstrap Complete

This PR contains the initial configuration for Azure Landing Zone deployment.

### ✅ What's Included

- **CODEOWNERS**: Requires PR review from repository owner
- **azure-auth-test.yml**: GitHub Actions workflow to validate Azure OIDC authentication
- **Bootstrap scripts**: Automation for Azure resource setup
- **Documentation**: Deployment guides and decision logs

### 🔐 Azure Resources Created

The bootstrap script has already created these Azure resources:

| Resource Type | Name/Role | Scope | Risk Level |
|--------------|-----------|-------|------------|
| App Registration | `sp-github-oidc-lz-platform` | Tenant | Medium |
| Service Principal | Linked to app above | Tenant | Medium |
| RBAC Role | Contributor | Subscription | **HIGH** |
| RBAC Role | User Access Administrator | Subscription | **HIGH** |
| Federated Credentials | main, pull_request, environment:prod | App | Medium |
| GitHub Secrets | AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID | Repository | Low |

> ⚠️ **Security Note**: The service principal has elevated permissions (Contributor + User Access Administrator) which allow it to deploy infrastructure and manage RBAC. This is required for Landing Zone deployment but should be monitored.

### 📋 Next Steps After Merging

1. **Configure Branch Protection**
   - Go to: https://github.com/$ghOwner/$RepoName/settings/rules
   - Follow instructions in \`docs/bootstrap/GITHUB-BRANCH-PROTECTION.md\`

2. **Test Azure Authentication**
   - Go to: https://github.com/$ghOwner/$RepoName/actions/workflows/azure-auth-test.yml
   - Click "Run workflow" → "Run workflow"
   - Verify the workflow succeeds (green checkmark)

3. **Deploy Terraform State Storage**
   - Run: \`.\scripts\Start-Bootstrap.ps1\` and complete Section 7

### ✅ Pre-Merge Checklist

- [x] Azure OIDC app registration created
- [x] Service principal configured with required roles
- [x] GitHub secrets set
- [x] CODEOWNERS file added
- [x] Auth test workflow added
- [x] Documentation updated

### 🔍 Validation

To validate the setup locally before merging:

\`\`\`powershell
# Check Azure service principal
az ad sp show --id \$env:AZURE_CLIENT_ID

# Check RBAC roles
az role assignment list --assignee \$env:AZURE_CLIENT_ID --output table

# Check GitHub secrets
gh secret list
\`\`\`

---

**Safe to merge**: ✅ This PR does NOT trigger any deployments. The workflow is `workflow_dispatch` (manual trigger only).
"@ `
        --base main `
        --head $branchName
    
    Write-OK "Pull request created: $prUrl"
    
    # Return to main branch
    git checkout main
    
} catch {
    Write-Err "Failed to create PR: $_"
    exit 1
} finally {
    Pop-Location
}

# ─────────────────────────────────────────────────────────────────────────────
# STEP 6: Wait for PR Merge and Trigger Workflow (Optional)
# ─────────────────────────────────────────────────────────────────────────────
Write-Header "Step 6: Automatic Workflow Trigger (Optional)"

Write-Host ""
Write-Host "  The PR is ready for review and merge." -ForegroundColor Yellow
Write-Host "  Would you like to automatically trigger the auth test workflow after merge?" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Options:" -ForegroundColor White
Write-Host "    [1] Wait for merge and auto-trigger workflow (recommended)" -ForegroundColor Gray
Write-Host "    [2] Exit now and manually trigger later" -ForegroundColor Gray
Write-Host ""
$autoTrigger = Read-Host "  Select [1-2]"

if ($autoTrigger -eq '1') {
    Write-Step "Monitoring PR status..."
    Write-Info "Please merge the PR in your browser: $prUrl"
    Write-Info "Checking every 10 seconds... (Press Ctrl+C to cancel)"
    
    $merged = $false
    $maxWaitTime = 600  # 10 minutes
    $elapsedTime = 0
    $checkInterval = 10
    
    while (-not $merged -and $elapsedTime -lt $maxWaitTime) {
        Start-Sleep -Seconds $checkInterval
        $elapsedTime += $checkInterval
        
        try {
            $prStatus = gh pr view $prUrl --json state,merged --jq '{state:.state,merged:.merged}' | ConvertFrom-Json
            
            if ($prStatus.merged -eq $true) {
                $merged = $true
                Write-OK "PR merged successfully!"
                break
            } elseif ($prStatus.state -eq "CLOSED") {
                Write-Warn "PR was closed without merging"
                break
            } else {
                Write-Host "  ⏳ Still waiting for merge... ($elapsedTime/$maxWaitTime seconds)" -ForegroundColor Gray
            }
        } catch {
            Write-Warn "Error checking PR status: $_"
        }
    }
    
    if ($merged) {
        Write-Step "Waiting 5 seconds for GitHub to process the merge..."
        Start-Sleep -Seconds 5
        
        Write-Step "Triggering azure-auth-test workflow..."
        try {
            gh workflow run azure-auth-test.yml --repo "$ghOwner/$RepoName"
            Write-OK "Workflow triggered successfully!"
            
            $workflowUrl = "https://github.com/$ghOwner/$RepoName/actions/workflows/azure-auth-test.yml"
            Write-Info "View workflow run at: $workflowUrl"
            
            Write-Host ""
            Write-Host "  ⏳ Waiting 10 seconds for workflow to start..." -ForegroundColor Gray
            Start-Sleep -Seconds 10
            
            # Try to get the latest run
            Write-Step "Checking workflow status..."
            $latestRun = gh run list --repo "$ghOwner/$RepoName" --workflow azure-auth-test.yml --limit 1 --json databaseId,status,conclusion,url | ConvertFrom-Json
            
            if ($latestRun) {
                $runUrl = $latestRun[0].url
                Write-OK "Workflow started: $runUrl"
                
                # Optional: Wait for completion
                Write-Host ""
                Write-Host "  Monitor workflow completion? [Y/n]" -ForegroundColor Yellow
                $monitor = Read-Host "  "
                
                if (-not $monitor -or $monitor -eq 'Y' -or $monitor -eq 'y') {
                    Write-Step "Monitoring workflow... (Press Ctrl+C to stop monitoring)"
                    
                    $completed = $false
                    while (-not $completed) {
                        Start-Sleep -Seconds 10
                        $runStatus = gh run view $latestRun[0].databaseId --repo "$ghOwner/$RepoName" --json status,conclusion | ConvertFrom-Json
                        
                        if ($runStatus.status -eq 'completed') {
                            $completed = $true
                            if ($runStatus.conclusion -eq 'success') {
                                Write-OK "Workflow completed successfully! ✅"
                                Write-Host ""
                                Write-Host "  🎉 Azure OIDC authentication is validated and working!" -ForegroundColor Green
                            } else {
                                Write-Err "Workflow completed with status: $($runStatus.conclusion)"
                                Write-Info "Check the workflow run for details: $runUrl"
                            }
                        } else {
                            Write-Host "  ⏳ Workflow status: $($runStatus.status)..." -ForegroundColor Gray
                        }
                    }
                }
            }
        } catch {
            Write-Warn "Could not trigger workflow automatically: $_"
            Write-Info "Manually trigger at: https://github.com/$ghOwner/$RepoName/actions/workflows/azure-auth-test.yml"
        }
    } elseif ($elapsedTime -ge $maxWaitTime) {
        Write-Warn "Timeout waiting for PR merge"
        Write-Info "Please merge the PR and manually trigger the workflow later"
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# STEP 7: Branch Protection Setup (Optional)
# ─────────────────────────────────────────────────────────────────────────────
Write-Header "Step 7: Configure Branch Protection (Optional)"

Write-Host ""
Write-Host "  Branch protection (GitHub Rulesets) helps prevent accidental changes to main branch." -ForegroundColor Yellow
Write-Host "  Would you like to configure it now?" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Options:" -ForegroundColor White
Write-Host "    [1] Yes - Open browser and guide me through setup" -ForegroundColor Gray
Write-Host "    [2] No - Skip for now (can configure later)" -ForegroundColor Gray
Write-Host ""
$branchProtection = Read-Host "  Select [1-2]"

if ($branchProtection -eq '1') {
    $rulesetUrl = "https://github.com/$ghOwner/$RepoName/settings/rules"
    
    Write-Step "Opening GitHub Rulesets page in browser..."
    Start-Process $rulesetUrl
    
    Write-Host ""
    Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Branch Protection Configuration Guide" -ForegroundColor Cyan
    Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Follow these steps in the browser:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  STEP 1: BASIC SETTINGS" -ForegroundColor White
    Write-Host "    • Click 'New branch ruleset'" -ForegroundColor Gray
    Write-Host "    • Ruleset Name: main" -ForegroundColor Gray
    Write-Host "    • Enforcement status: Active" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  STEP 2: TARGET BRANCHES ⚠️ CRITICAL" -ForegroundColor White
    Write-Host "    • Scroll to 'Target branches' section" -ForegroundColor Gray
    Write-Host "    • Click 'Add target'" -ForegroundColor Gray
    Write-Host "    • Select 'Include default branch'" -ForegroundColor Gray
    Write-Host "    • ⚠️  If you skip this, the ruleset won't work!" -ForegroundColor Red
    Write-Host ""
    Write-Host "  STEP 3: BYPASS LIST (Optional)" -ForegroundColor White
    if ($ghOwner -eq $ghUser) {
        Write-Host "    • Recommended: Add yourself to bypass list" -ForegroundColor Gray
        Write-Host "      (Solo developer - allows flexibility)" -ForegroundColor Gray
    } else {
        Write-Host "    • Recommended: Leave empty or add only admins" -ForegroundColor Gray
        Write-Host "      (Organization - enforce for everyone)" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "  STEP 4: BRANCH RULES" -ForegroundColor White
    Write-Host "    ✓ Restrict deletions" -ForegroundColor Gray
    Write-Host "    ✓ Require a pull request before merging" -ForegroundColor Gray
    if ($ghOwner -eq $ghUser) {
        Write-Host "      └─ Required approvals: 0 (solo developer)" -ForegroundColor Gray
    } else {
        Write-Host "      └─ Required approvals: 1+ (team)" -ForegroundColor Gray
    }
    Write-Host "      └─ Dismiss stale PR approvals when new commits pushed" -ForegroundColor Gray
    Write-Host "      └─ Require review from Code Owners" -ForegroundColor Gray
    Write-Host "    ⏸️  Require status checks (SKIP FOR NOW)" -ForegroundColor Gray
    Write-Host "        └─ Enable after first workflow run" -ForegroundColor Gray
    Write-Host "    ✓ Block force pushes" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  STEP 5: SAVE" -ForegroundColor White
    Write-Host "    • Scroll to bottom" -ForegroundColor Gray
    Write-Host "    • Click 'Create'" -ForegroundColor Gray
    Write-Host "    • Verify 'Applies to 1 target' appears" -ForegroundColor Gray
    Write-Host ""
    Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    [void](Read-Host "  Press ENTER once branch protection is configured...")
    Write-OK "Branch protection configuration acknowledged"
    
    # Verify ruleset was created
    Write-Step "Verifying branch protection..."
    try {
        $rulesets = gh api "repos/$ghOwner/$RepoName/rulesets" | ConvertFrom-Json
        if ($rulesets.Count -gt 0) {
            Write-OK "Found $($rulesets.Count) ruleset(s) configured"
            foreach ($ruleset in $rulesets) {
                Write-Info "  • $($ruleset.name) (ID: $($ruleset.id))"
            }
        } else {
            Write-Warn "No rulesets found - verification may be delayed"
            Write-Info "Check manually at: $rulesetUrl"
        }
    } catch {
        Write-Warn "Could not verify rulesets via API"
        Write-Info "Check manually at: $rulesetUrl"
    }
} else {
    Write-Info "Branch protection skipped - you can configure it later at:"
    Write-Info "  $rulesetUrl"
}

# ─────────────────────────────────────────────────────────────────────────────
# COMPLETION SUMMARY
# ─────────────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "██████████████████████████████████████████████████████████████████████" -ForegroundColor Green
Write-Host "  ✅ Bootstrap Complete!" -ForegroundColor Green
Write-Host "██████████████████████████████████████████████████████████████████████" -ForegroundColor Green
Write-Host ""
Write-Host "  Repository:      https://github.com/$ghOwner/$RepoName" -ForegroundColor White
Write-Host "  Pull Request:    $prUrl" -ForegroundColor White
Write-Host "  Local Path:      $repoPath" -ForegroundColor White
Write-Host ""
Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Next Steps" -ForegroundColor Cyan
Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1️⃣  Review and merge the PR:" -ForegroundColor Yellow
Write-Host "     $prUrl" -ForegroundColor White
Write-Host ""
Write-Host "  2️⃣  Verify the auth test workflow:" -ForegroundColor Yellow
Write-Host "     https://github.com/$ghOwner/$RepoName/actions/workflows/azure-auth-test.yml" -ForegroundColor White
if ($autoTrigger -ne '1') {
    Write-Host "     (Click 'Run workflow' → 'Run workflow' after merging)" -ForegroundColor Gray
}
Write-Host ""
Write-Host "  3️⃣  Configure GitHub branch protection:" -ForegroundColor Yellow
Write-Host "     https://github.com/$ghOwner/$RepoName/settings/rules" -ForegroundColor White
Write-Host "     Follow: docs/bootstrap/GITHUB-BRANCH-PROTECTION.md" -ForegroundColor White
Write-Host ""
Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "  📚 Documentation: $repoPath/docs/" -ForegroundColor Gray
Write-Host "  🔍 Audit Trail:   $repoPath/docs/bootstrap/BOOTSTRAP-DECISION-LOG.md" -ForegroundColor Gray
Write-Host ""
