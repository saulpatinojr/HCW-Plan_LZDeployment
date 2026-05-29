#Requires -Version 7.0
<#
.SYNOPSIS
    Interactive bootstrap orchestrator for the HCW Landing Zone Deployment.

.DESCRIPTION
    Single-click script that completes all Phase 0 bootstrap steps:
      Section 1  – Verify Azure login & identifiers
      Section 2  – Skip (requires GitHub Enterprise Cloud)
      Section 3  – Create .github/CODEOWNERS
      Section 4  – Guide branch-protection setup
      Section 5  – Create OIDC app, federated credential, RBAC, GitHub secrets
      Section 6  – Create azure-auth-test.yml and open PR
      Section 7  – Deploy Terraform remote-state backend
      Section 8  – Verify CI/CD workflow files exist

    Run it as many times as needed — every step is idempotent.
    State is saved in .bootstrap-state.json so interrupted runs resume.

.EXAMPLE
    .\scripts\Start-Bootstrap.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ─────────────────────────────────────────────────────────────────────────────
# CONSTANTS
# ─────────────────────────────────────────────────────────────────────────────
$REPO_ROOT      = Split-Path $PSScriptRoot -Parent
$STATE_FILE     = Join-Path $REPO_ROOT '.bootstrap-state.json'
$GITHUB_OWNER   = 'saulpatinojr'
$GITHUB_REPO    = 'HCW-Demo-LZDeployment'
$APP_NAME       = 'sp-github-oidc-lz-platform'
$TF_BOOTSTRAP   = Join-Path $REPO_ROOT 'terraform' 'backend-bootstrap'

# Minimum required CLI versions (warn-not-fail)
$MIN_VERSIONS = [ordered]@{
    az        = [version]'2.69.0'
    gh        = [version]'2.67.0'
    git       = [version]'2.43.0'
    terraform = [version]'1.9.0'
}

# ─────────────────────────────────────────────────────────────────────────────
# COLOUR HELPERS
# ─────────────────────────────────────────────────────────────────────────────
function Write-Header([string]$Title) {
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host ("=" * 70) -ForegroundColor Cyan
}
function Write-Step([string]$Msg)    { Write-Host "  ➤  $Msg" -ForegroundColor White }
function Write-OK([string]$Msg)      { Write-Host "  ✅  $Msg" -ForegroundColor Green }
function Write-Warn([string]$Msg)    { Write-Host "  ⚠️   $Msg" -ForegroundColor Yellow }
function Write-Info([string]$Msg)    { Write-Host "     $Msg" -ForegroundColor Gray }
function Write-Err([string]$Msg)     { Write-Host "  ❌  $Msg" -ForegroundColor Red }
function Write-Manual([string]$Msg)  { Write-Host "  📋  $Msg" -ForegroundColor Magenta }

function Wait-ForUser([string]$Prompt = "Press ENTER when done, or Ctrl+C to abort...") {
    Write-Host ""
    Read-Host $Prompt | Out-Null
}

# ─────────────────────────────────────────────────────────────────────────────
# STATE MANAGEMENT  (persist progress across re-runs)
# ─────────────────────────────────────────────────────────────────────────────
function Import-State {
    if (Test-Path $STATE_FILE) {
        return Get-Content $STATE_FILE -Raw | ConvertFrom-Json -AsHashtable
    }
    return @{}
}

function Save-State([hashtable]$State) {
    $State | ConvertTo-Json -Depth 5 | Set-Content $STATE_FILE -Encoding UTF8
}

function Test-StepDone([hashtable]$State, [string]$Key) {
    return $State.ContainsKey($Key) -and $State[$Key] -eq $true
}

function Set-StepDone([hashtable]$State, [string]$Key) {
    $State[$Key] = $true
    Save-State $State
}

function Reset-Config([hashtable]$State) {
    foreach ($key in @('tenantId','subscriptionId','subscriptionName','orgPrefix','githubOwner')) {
        $State.Remove($key) | Out-Null
    }
    Save-State $State
}

# ─────────────────────────────────────────────────────────────────────────────
# PREREQUISITES
# ─────────────────────────────────────────────────────────────────────────────
function Test-Prerequisites {
    Write-Header "Checking Prerequisites"
    $ok = $true

    foreach ($tool in $MIN_VERSIONS.Keys) {
        if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
            Write-Err "$tool is not installed or not in PATH"
            $ok = $false
            continue
        }

        # Parse installed version
        $installed = $null
        try {
            switch ($tool) {
                'az' {
                    $j = az version --output json 2>$null | ConvertFrom-Json
                    $installed = [version]($j.'azure-cli')
                }
                'terraform' {
                    $j = terraform version -json 2>$null | ConvertFrom-Json
                    $installed = [version]($j.terraform_version -replace '\+.*$','')
                }
                default {
                    # Use regex to grab first X.Y.Z group — avoids platform suffixes like 'windows.1'
                    $raw = & $tool --version 2>&1 | Select-Object -First 1
                    if ($raw -match '(\d+\.\d+\.\d+)') {
                        $installed = [version]$Matches[1]
                    }
                }
            }
        } catch { $installed = $null }

        $minVer = $MIN_VERSIONS[$tool]
        if ($null -eq $installed) {
            Write-Warn "$tool  →  installed (version unreadable; minimum $minVer recommended)"
        } elseif ($installed -lt $minVer) {
            Write-Warn "$tool  →  $installed  ⚠️  minimum recommended: $minVer"
        } else {
            Write-OK  "$tool  →  $installed"
        }
    }

    if (-not $ok) {
        throw "Install the missing tools and re-run this script."
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# INPUT COLLECTION  (ask once, store in state)
# ─────────────────────────────────────────────────────────────────────────────
function Read-BootstrapConfig([hashtable]$State) {
    Write-Header "Gathering Configuration"

    # ── GitHub authentication ─────────────────────────────────────────────────
    gh auth status 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Warn "GitHub CLI is not authenticated."
        Write-Step "Logging you in to GitHub CLI..."
        gh auth login --hostname github.com --git-protocol https `
            --scopes 'repo,workflow,read:org' --web
    } else {
        Write-OK "GitHub CLI authenticated"
    }

    # ── Azure authentication — detect current context, offer to switch ─────────
    $me = az account show --output json --only-show-errors 2>$null | ConvertFrom-Json

    if ($null -eq $me) {
        Write-Warn "Azure CLI is not signed in. Starting browser login..."
        az login --only-show-errors | Out-Null
        $me = az account show --output json --only-show-errors | ConvertFrom-Json
    }

    # Loop until user confirms the account/tenant with 'Y'
    :azureAuthLoop while ($true) {
        # Show detected context and ask if it is correct for this client
        Write-Host ""
        Write-Host "  Detected Azure context:" -ForegroundColor Cyan
        Write-Host ("  {0,-22} {1}" -f "Account:",      $me.user.name)  -ForegroundColor White
        Write-Host ("  {0,-22} {1}" -f "Tenant ID:",    $me.tenantId)   -ForegroundColor Gray
        Write-Host ("  {0,-22} {1}" -f "Subscription:", "$($me.name) ($($me.id))") -ForegroundColor Gray
        Write-Host ""

        $ctxAns = (Read-Host "  Use this account/tenant? [Y/n/switch]  (Y=confirm, n=exit, switch=login different account)").Trim().ToLower()

        switch ($ctxAns) {
            { $_ -in '', 'y', 'yes' } {
                Write-OK "Azure account confirmed: $($me.user.name)"
                break azureAuthLoop
            }
            { $_ -in 'n', 'no' } {
                Write-Warn "Bootstrap cancelled by user."
                exit 0
            }
            { $_ -in 'switch', 's' } {
                Write-Host ""
                Write-Host "  Login options:" -ForegroundColor Cyan
                Write-Host "  [1]  Interactive browser login (any tenant — Azure picks based on your browser session)"
                Write-Host "  [2]  Login to a specific tenant (enter tenant ID or domain)"
                $loginOpt = (Read-Host "  Select [1-2]").Trim()

                if ($loginOpt -eq '2') {
                    $tenantInput = (Read-Host "  Tenant ID or domain (e.g. contoso.onmicrosoft.com)").Trim()
                    az login --tenant $tenantInput --only-show-errors | Out-Null
                } else {
                    az login --only-show-errors | Out-Null
                }
                $me = az account show --output json --only-show-errors | ConvertFrom-Json
                Write-OK "Signed in as: $($me.user.name)  (tenant: $($me.tenantId))"
                # Loop continues to ask again
            }
            default {
                Write-Warn "Invalid option. Please enter Y (confirm), n (exit), or switch (change account)."
            }
        }
    }

    # ── Subscription picker ───────────────────────────────────────────────────
    # Helper closure so we can call it from both here and the edit-menu
    $pickSubscription = {
        # Get current tenant ID to filter subscriptions
        $currentAccount = az account show --output json --only-show-errors | ConvertFrom-Json
        $currentTenant = $currentAccount.tenantId

        # List all subscriptions and filter to only the current tenant
        $allSubs = az account list --output json --only-show-errors | ConvertFrom-Json |
                       Where-Object { $_.state -eq 'Enabled' -and $_.tenantId -eq $currentTenant } |
                       Sort-Object name

        if ($allSubs.Count -eq 0) {
            throw "No enabled subscriptions found in tenant $currentTenant."
        }

        Write-Host ""
        Write-Host "  Available subscriptions in tenant $currentTenant`:" -ForegroundColor Cyan
        for ($i = 0; $i -lt $allSubs.Count; $i++) {
            $marker = if ($allSubs[$i].isDefault) { ' (current)' } else { '' }
            Write-Host "  [$($i+1)]  $($allSubs[$i].name)$marker" -ForegroundColor White
            Write-Host "       $($allSubs[$i].id)" -ForegroundColor Gray
        }
        Write-Host ""
        $sel = (Read-Host "  Select subscription [1-$($allSubs.Count)] (ENTER = keep current)").Trim()
        if ($sel -match '^\d+$' -and [int]$sel -ge 1 -and [int]$sel -le $allSubs.Count) {
            $chosen = $allSubs[[int]$sel - 1]
            az account set --subscription $chosen.id --only-show-errors | Out-Null
        }
        return (az account show --output json --only-show-errors | ConvertFrom-Json)
    }

    $me = & $pickSubscription

    Write-OK "Subscription : $($me.name)"
    Write-Info "Tenant       : $($me.tenantId)"
    Write-Info "Account      : $($me.user.name)"
    Write-Info "Sub ID       : $($me.id)"

    $State['tenantId']         = $me.tenantId
    $State['subscriptionId']   = $me.id
    $State['subscriptionName'] = $me.name
    $State['accountName']      = $me.user.name
    Save-State $State

    # ── Org prefix ────────────────────────────────────────────────────────────
    if (-not $State.ContainsKey('orgPrefix')) {
        $prefix = (Read-Host "  Enter organisation prefix for resource naming (default: hcw)").Trim()
        if ([string]::IsNullOrEmpty($prefix)) { $prefix = 'hcw' }
        $State['orgPrefix'] = $prefix.ToLower() -replace '[^a-z0-9]', ''
        Save-State $State
    }
    Write-OK "Org prefix: $($State['orgPrefix'])"

    # ── GitHub owner alias ────────────────────────────────────────────────────
    if (-not $State.ContainsKey('githubOwner')) {
        $owner = (Read-Host "  GitHub account/org that owns the repo (default: $GITHUB_OWNER)").Trim()
        if ([string]::IsNullOrEmpty($owner)) { $owner = $GITHUB_OWNER }
        $State['githubOwner'] = $owner
        Save-State $State
    }
    Write-OK "GitHub owner: $($State['githubOwner'])"

    # ── Config confirmation loop ──────────────────────────────────────────────
    :confirmLoop while ($true) {
        Write-Host ""
        Write-Host ("─" * 70) -ForegroundColor DarkCyan
        Write-Host "  Configuration Summary" -ForegroundColor Cyan
        Write-Host ("─" * 70) -ForegroundColor DarkCyan
        $acct = if ($State.ContainsKey('accountName')) { $State['accountName'] } else { '(unknown)' }
        Write-Host ("  {0,-26} {1}" -f "Azure Account:",   $acct)                      -ForegroundColor Cyan
        Write-Host ("  {0,-26} {1}" -f "Tenant ID:",       $State['tenantId'])          -ForegroundColor Gray
        Write-Host ("  {0,-26} {1}" -f "Subscription:",    $State['subscriptionName'])  -ForegroundColor White
        Write-Host ("  {0,-26} {1}" -f "Subscription ID:", $State['subscriptionId'])    -ForegroundColor Gray
        Write-Host ("  {0,-26} {1}" -f "Org Prefix:",      $State['orgPrefix'])         -ForegroundColor White
        Write-Host ("  {0,-26} {1}" -f "GitHub Owner:",    $State['githubOwner'])       -ForegroundColor White
        Write-Host ("─" * 70) -ForegroundColor DarkCyan
        Write-Host ""

        $ans = (Read-Host "  Is this correct? [Y/n/reset]  (Y=proceed, n=edit, reset=start over)").Trim().ToLower()

        switch ($ans) {
            { $_ -in '', 'y', 'yes' } {
                break confirmLoop
            }
            { $_ -in 'n', 'no' } {
                Write-Host ""
                Write-Host "  What would you like to change?" -ForegroundColor Cyan
                Write-Host "  [1] Subscription  (stay in same tenant)"
                Write-Host "  [2] Org Prefix"
                Write-Host "  [3] GitHub Owner"
                Write-Host "  [4] Re-authenticate / switch to a different Azure account or tenant"
                $edit = (Read-Host "  Enter 1-4").Trim()
                switch ($edit) {
                    '1' {
                        $State.Remove('subscriptionId')  | Out-Null
                        $State.Remove('subscriptionName')| Out-Null
                        $State.Remove('tenantId')        | Out-Null
                        $State.Remove('accountName')     | Out-Null
                        Save-State $State
                        $me2 = & $pickSubscription
                        $State['tenantId']         = $me2.tenantId
                        $State['subscriptionId']   = $me2.id
                        $State['subscriptionName'] = $me2.name
                        $State['accountName']      = $me2.user.name
                        Save-State $State
                    }
                    '2' {
                        $State.Remove('orgPrefix') | Out-Null
                        $prefix = (Read-Host "  New org prefix").Trim()
                        if ([string]::IsNullOrEmpty($prefix)) { $prefix = 'hcw' }
                        $State['orgPrefix'] = $prefix.ToLower() -replace '[^a-z0-9]', ''
                        Save-State $State
                    }
                    '3' {
                        $State.Remove('githubOwner') | Out-Null
                        $owner = (Read-Host "  New GitHub owner").Trim()
                        if ([string]::IsNullOrEmpty($owner)) { $owner = $GITHUB_OWNER }
                        $State['githubOwner'] = $owner
                        Save-State $State
                    }
                    '4' {
                        # Switch Azure account / tenant entirely
                        Write-Host ""
                        Write-Host "  Login options:" -ForegroundColor Cyan
                        Write-Host "  [1]  Interactive browser login"
                        Write-Host "  [2]  Login to a specific tenant (enter tenant ID or domain)"
                        $loginOpt2 = (Read-Host "  Select [1-2]").Trim()
                        if ($loginOpt2 -eq '2') {
                            $tenantInput2 = (Read-Host "  Tenant ID or domain (e.g. contoso.onmicrosoft.com)").Trim()
                            az login --tenant $tenantInput2 --only-show-errors | Out-Null
                        } else {
                            az login --only-show-errors | Out-Null
                        }
                        $me2 = & $pickSubscription
                        $State['tenantId']         = $me2.tenantId
                        $State['subscriptionId']   = $me2.id
                        $State['subscriptionName'] = $me2.name
                        $State['accountName']      = $me2.user.name
                        Save-State $State
                        Write-OK "Switched to: $($me2.user.name)  /  $($me2.name)"
                    }
                }
            }
            'reset' {
                Write-Warn "Resetting all configuration..."
                Reset-Config $State
                # Recurse to restart collection
                Read-BootstrapConfig $State
                return
            }
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# ─────────────────────────────────────────────────────────────────────────────
# DEPLOYMENT FOLDER SETUP
# ─────────────────────────────────────────────────────────────────────────────
function Initialize-DeploymentFolder([hashtable]$State) {
    $orgPrefix = $State['orgPrefix']
    $tenantId = $State['tenantId']
    $tenantSuffix = $tenantId.Substring($tenantId.Length - 12)
    
    $deploymentName = "$orgPrefix-$tenantSuffix"
    $deploymentPath = Join-Path $REPO_ROOT 'deployments' $deploymentName
    
    if (-not (Test-Path $deploymentPath)) {
        Write-Step "Creating deployment folder: deployments/$deploymentName"
        New-Item -Path $deploymentPath -ItemType Directory -Force | Out-Null
        
        # Create subdirectories for organization
        New-Item -Path (Join-Path $deploymentPath '.github' 'workflows') -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path $deploymentPath 'scripts') -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path $deploymentPath 'outputs') -ItemType Directory -Force | Out-Null
        
        Write-OK "Deployment folder created: deployments/$deploymentName"
    } else {
        Write-OK "Deployment folder exists: deployments/$deploymentName"
    }
    
    $State['deploymentFolder'] = $deploymentPath
    $State['deploymentName'] = $deploymentName
    Save-State $State
}

# SECTION 3 — CODEOWNERS
# ─────────────────────────────────────────────────────────────────────────────
function Step-CodeOwners([hashtable]$State) {
    Write-Header "Section 3 — CODEOWNERS"

    $deploymentFolder = $State['deploymentFolder']
    $destFile = Join-Path $deploymentFolder '.github' 'CODEOWNERS'

    if (Test-StepDone $State 's3_codeowners') {
        Write-OK "CODEOWNERS already created (from previous run)"
        return
    }

    if (Test-Path $destFile) {
        Write-OK "CODEOWNERS already exists"
        Set-StepDone $State 's3_codeowners'
        return
    }

    $owner  = $State['githubOwner']
    $deploymentName = $State['deploymentName']
    $content = "# All files — require review from repo owner`n* @$owner`n"

    New-Item -Path (Split-Path $destFile) -ItemType Directory -Force | Out-Null
    Set-Content -Path $destFile -Value $content -Encoding UTF8
    Write-OK "Created deployments/$deploymentName/.github/CODEOWNERS  (owner: @$owner)"
    Set-StepDone $State 's3_codeowners'
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 6 — AUTH TEST WORKFLOW FILE
# ─────────────────────────────────────────────────────────────────────────────
function Step-AuthTestWorkflow([hashtable]$State) {
    Write-Header "Section 6 — azure-auth-test.yml workflow"

    $deploymentFolder = $State['deploymentFolder']
    $destFile = Join-Path $deploymentFolder '.github' 'workflows' 'azure-auth-test.yml'

    if (Test-Path $destFile) {
        Write-OK "azure-auth-test.yml already exists"
        Set-StepDone $State 's6_auth_workflow'
        return
    }

    $yml = @'
# ─────────────────────────────────────────────────────────────────────────────
# azure-auth-test.yml  – validates OIDC federated identity to Azure
# Run manually once after setting AZURE_CLIENT_ID / TENANT_ID / SUBSCRIPTION_ID
# ─────────────────────────────────────────────────────────────────────────────
name: Azure Auth Test

on:
  workflow_dispatch:

permissions:
  id-token: write   # required for OIDC
  contents: read

jobs:
  auth-test:
    name: OIDC Login Test
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Azure Login (OIDC)
        uses: azure/login@v2
        with:
          client-id:       ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id:       ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Verify identity
        run: |
          echo "=== Logged-in identity ==="
          az account show --query '{account:id, tenant:tenantId, user:user.name}' -o json

      - name: Show RBAC assignments
        run: |
          echo "=== Role assignments for this SP ==="
          az role assignment list --assignee "$(az account show --query user.name -o tsv)" \
            --query '[].{role:roleDefinitionName, scope:scope}' -o table

      - name: Azure Logout
        if: always()
        run: az logout || true
'@

    $deploymentName = $State['deploymentName']
    New-Item -Path (Split-Path $destFile) -ItemType Directory -Force | Out-Null
    Set-Content -Path $destFile -Value $yml -Encoding UTF8
    Write-OK "Created deployments/$deploymentName/.github/workflows/azure-auth-test.yml"
    Set-StepDone $State 's6_auth_workflow'
}

# ─────────────────────────────────────────────────────────────────────────────
# COMMIT & PUSH FILE CHANGES VIA PR
# ─────────────────────────────────────────────────────────────────────────────
function Step-CommitAndPR([hashtable]$State) {
    Write-Header "Committing file changes (CODEOWNERS + auth-test workflow)"

    if (Test-StepDone $State 's3s6_pr_merged') {
        Write-OK "File-changes PR already merged (from previous run)"
        return
    }

    Push-Location $REPO_ROOT

    try {
        # Check for uncommitted changes to our new files (in deployment folder)
        $changed = git status --porcelain 2>&1
        $hasChanges = $changed | Where-Object { $_ -match 'deployments/' }

        if (-not $hasChanges) {
            Write-OK "No new file changes to commit"
            Set-StepDone $State 's3s6_pr_merged'
            return
        }

        $branchName = 'bootstrap/add-codeowners-and-auth-workflow'

        # Check if branch already exists
        $existingBranch = git branch --list $branchName
        if ($existingBranch) {
            Write-Warn "Branch '$branchName' already exists, switching to it"
            git checkout $branchName 2>&1 | Out-Null
        } else {
            Write-Step "Creating branch: $branchName"
            git checkout -b $branchName 2>&1 | Out-Null
        }

        $deploymentFolder = $State['deploymentFolder']
        $deploymentName = $State['deploymentName']
        $relDeploymentPath = "deployments/$deploymentName"
        
        git add "$relDeploymentPath/.github/CODEOWNERS" "$relDeploymentPath/.github/workflows/azure-auth-test.yml" 2>&1 | Out-Null
        git commit -m "bootstrap: add CODEOWNERS and azure-auth-test workflow

- $relDeploymentPath/.github/CODEOWNERS: require PR review from repo owner
- $relDeploymentPath/.github/workflows/azure-auth-test.yml: manual OIDC validation workflow
" 2>&1 | Out-Null

        Write-Step "Pushing branch to origin..."
        git push --set-upstream origin $branchName 2>&1 | Out-Null

        # Check if PR already exists for this branch
        $existingPR = gh pr list --head $branchName --json number --jq '.[0].number' 2>&1
        if ($existingPR -match '^\d+$') {
            Write-OK "PR #$existingPR already exists for this branch"
            $prUrl = gh pr view $existingPR --json url --jq '.url' 2>&1
        } else {
            Write-Step "Creating Pull Request..."
            $prUrl = gh pr create `
                --title "bootstrap: add CODEOWNERS and azure-auth-test workflow" `
                --body "## Bootstrap Phase 0 — File Setup

### Changes
- **\`.github/CODEOWNERS\`** — requires PR review from \`@$($State['githubOwner'])\`
- **\`.github/workflows/azure-auth-test.yml\`** — manual workflow to validate OIDC authentication

### Checklist
- [ ] OIDC secrets have been set in GitHub (Section 5 must complete first)
- [ ] Approve and merge this PR to continue bootstrap" `
                --base main `
                --head $branchName
        }

        Write-OK "Pull Request ready: $prUrl"
        Write-Host ""
        Write-Manual "ACTION REQUIRED: Review and merge the PR above."
        Write-Info   "  The PR adds CODEOWNERS and the auth-test workflow."
        Write-Info   "  If branch protection requires a review — use GitHub UI to approve."
        Write-Info   "  If you are the only admin, you may be able to merge without a separate reviewer."
        Write-Host ""

        Wait-ForUser "Press ENTER once you have merged the PR..."

        # Switch back to main and pull
        git checkout main 2>&1 | Out-Null
        git pull origin main --ff-only 2>&1 | Out-Null

        Set-StepDone $State 's3s6_pr_merged'
        Write-OK "Files merged to main"

    } finally {
        # Make sure we always return to main
        $currentBranch = git branch --show-current 2>&1
        if ($currentBranch -ne 'main') {
            git checkout main 2>&1 | Out-Null
        }
        Pop-Location
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 4 — BRANCH PROTECTION (GitHub Rulesets)
# ─────────────────────────────────────────────────────────────────────────────
function Step-BranchProtection([hashtable]$State) {
    Write-Header "Section 4 — Branch Protection (GitHub Rulesets)"

    # Check current state via gh
    $protection = gh api "repos/$GITHUB_OWNER/$GITHUB_REPO/branches/main/protection" 2>&1
    $isProtected = $LASTEXITCODE -eq 0 -and $protection -notmatch 'Branch not protected'

    if ($isProtected) {
        Write-OK "Branch protection is already enabled on 'main'"
        Set-StepDone $State 's4_branch_protection'
        return
    }

    if (Test-StepDone $State 's4_branch_protection') {
        Write-OK "Branch protection marked complete (from previous run)"
        return
    }

    Write-Manual "Branch protection must be set manually in the GitHub UI."
    Write-Host ""
    Write-Host "  📌 GitHub now uses 'Rulesets' instead of old branch protection rules." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Open this URL in your browser:" -ForegroundColor White
    Write-Host "  https://github.com/$GITHUB_OWNER/$GITHUB_REPO/settings/rules" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Click 'New branch ruleset' and configure:" -ForegroundColor White
    Write-Host ""
    Write-Host "  ══════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
    Write-Host "  STEP 1: BASIC SETTINGS" -ForegroundColor Yellow
    Write-Host "  ══════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
    Write-Host "   • Ruleset Name: " -NoNewline -ForegroundColor White
    Write-Host "main" -ForegroundColor Cyan
    Write-Host "   • Enforcement status: " -NoNewline -ForegroundColor White
    Write-Host "Active" -ForegroundColor Green
    Write-Host ""
    Write-Host "  ══════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
    Write-Host "  STEP 2: TARGET BRANCHES ⚠️ CRITICAL - DO NOT SKIP" -ForegroundColor Yellow
    Write-Host "  ══════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
    Write-Host "   1. Scroll to 'Target branches' section" -ForegroundColor White
    Write-Host "   2. Click the " -NoNewline -ForegroundColor White
    Write-Host "'Add target'" -NoNewline -ForegroundColor Cyan
    Write-Host " button" -ForegroundColor White
    Write-Host "   3. Select " -NoNewline -ForegroundColor White
    Write-Host "'Include default branch'" -ForegroundColor Green
    Write-Host "      (This targets your 'main' branch)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   ⚠️  If you skip this, the ruleset will show:" -ForegroundColor Red
    Write-Host "      'This ruleset does not target any resources and will not be applied'" -ForegroundColor Red
    Write-Host ""
    Write-Host "  ══════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
    Write-Host "  STEP 3: BYPASS LIST (Optional - for solo developers)" -ForegroundColor Yellow
    Write-Host "  ══════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
    Write-Host "   Option A (Strictest): Leave bypass list empty" -ForegroundColor White
    Write-Host "                         └─ No one can bypass rules" -ForegroundColor Gray
    Write-Host "   Option B (Flexible):  Click 'Add bypass' → Add yourself" -ForegroundColor White
    Write-Host "                         └─ You can bypass when needed" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  ══════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
    Write-Host "  STEP 4: BRANCH RULES (Scroll down to find these)" -ForegroundColor Yellow
    Write-Host "  ══════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
    Write-Host "   ✓ Restrict deletions" -ForegroundColor Green
    Write-Host "       └─ Prevents accidental deletion of main branch" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   ✓ Require a pull request before merging" -ForegroundColor Green
    Write-Host "       └─ Required approvals: " -NoNewline -ForegroundColor Gray
    Write-Host "0" -NoNewline -ForegroundColor Cyan
    Write-Host " (for solo dev) or " -NoNewline -ForegroundColor Gray
    Write-Host "1+" -NoNewline -ForegroundColor Cyan
    Write-Host " (for team)" -ForegroundColor Gray
    Write-Host "       └─ ✓ Dismiss stale PR approvals when new commits are pushed" -ForegroundColor Gray
    Write-Host "       └─ ✓ Require review from Code Owners" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   ⏸️  Require status checks to pass before merging" -ForegroundColor Yellow
    Write-Host "       └─ SKIP THIS FOR NOW (enable after first workflow run)" -ForegroundColor Red
    Write-Host "       └─ You'll add 'RBAC Security Validation' check later" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   ✓ Block force pushes" -ForegroundColor Green
    Write-Host "       └─ Protects commit history integrity" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  ══════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
    Write-Host "  STEP 5: SAVE" -ForegroundColor Yellow
    Write-Host "  ══════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
    Write-Host "   • Scroll to bottom" -ForegroundColor White
    Write-Host "   • Click " -NoNewline -ForegroundColor White
    Write-Host "'Create'" -ForegroundColor Green
    Write-Host "   • Verify the yellow warning is gone" -ForegroundColor White
    Write-Host "   • Should show 'Applies to 1 target'" -ForegroundColor Gray
    Write-Host ""
    Write-Warn "REMINDER: Set 'Required approvals: 0' if you're the only developer"
    Write-Warn "          to avoid being locked out. Increase it when adding team members."
    Write-Host ""

    Wait-ForUser "Press ENTER once the branch ruleset is configured and active..."
    Set-StepDone $State 's4_branch_protection'
    Write-OK "Branch protection step marked complete"
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 5 — OIDC APP REGISTRATION + SECRETS
# ─────────────────────────────────────────────────────────────────────────────
function Step-OIDCSetup([hashtable]$State) {
    Write-Header "Section 5 — OIDC App Registration & GitHub Secrets"

    $tenantId  = $State['tenantId']
    $subId     = $State['subscriptionId']
    $owner     = $State['githubOwner']

    # ── RESOURCE CREATION WARNING ─────────────────────────────────────────────
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Red
    Write-Host "  " -NoNewline
    Write-Host "🚨 WARNING: AZURE RESOURCES WILL BE CREATED" -ForegroundColor Red
    Write-Host "  " -NoNewline
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Red
    Write-Host ""
    Write-Host "  This section will create the following REAL Azure resources:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  📋 RESOURCES TO BE CREATED:" -ForegroundColor Cyan
    Write-Host "     1️⃣  Entra ID App Registration: '$APP_NAME'" -ForegroundColor White
    Write-Host "     2️⃣  Service Principal (linked to app registration)" -ForegroundColor White
    Write-Host "     3️⃣  Federated Credentials (3x):" -ForegroundColor White
    Write-Host "         - Main branch (for terraform apply)" -ForegroundColor Gray
    Write-Host "         - Pull requests (for terraform plan)" -ForegroundColor Gray
    Write-Host "         - Environment: prod (for gated deployments)" -ForegroundColor Gray
    Write-Host "     4️⃣  RBAC Role Assignments (subscription-wide):" -ForegroundColor White
    Write-Host "         - Contributor " -NoNewline -ForegroundColor Gray
    Write-Host "(can create/modify/delete most resources)" -ForegroundColor Red
    Write-Host "         - User Access Administrator " -NoNewline -ForegroundColor Gray
    Write-Host "(can grant ANY role)" -ForegroundColor Red
    Write-Host "     5️⃣  GitHub Repository Secrets (3x):" -ForegroundColor White
    Write-Host "         - AZURE_CLIENT_ID" -ForegroundColor Gray
    Write-Host "         - AZURE_TENANT_ID" -ForegroundColor Gray
    Write-Host "         - AZURE_SUBSCRIPTION_ID" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  ⚠️  TARGET SUBSCRIPTION:" -ForegroundColor Yellow
    Write-Host "     Subscription: $($State['subscriptionName'])" -ForegroundColor White
    Write-Host "     ID:           $subId" -ForegroundColor Gray
    Write-Host "     Tenant:       $tenantId" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  🔴 RISK LEVEL: HIGH" -ForegroundColor Red
    Write-Host "     The service principal will have elevated permissions that can:" -ForegroundColor Red
    Write-Host "     - Create, modify, delete most Azure resources in the subscription" -ForegroundColor Red
    Write-Host "     - Grant additional permissions to other identities" -ForegroundColor Red
    Write-Host "     - Effectively escalate to subscription Owner" -ForegroundColor Red
    Write-Host ""
    Write-Host "  💰 COST IMPACT: None (these resources are free)" -ForegroundColor Green
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Red
    Write-Host ""
    $confirm = Read-Host "  Type 'CREATE' (all caps) to proceed, or anything else to skip"
    if ($confirm -ne 'CREATE') {
        Write-Warn "Resource creation cancelled by user."
        Write-Info "You can re-run this script to continue from this point."
        return
    }
    Write-Host ""
    Write-OK "User confirmed - proceeding with resource creation..."
    Write-Host ""

    # ── 5a: App Registration ──────────────────────────────────────────────────
    $existingApp = $null
    if ($State.ContainsKey('clientId')) {
        Write-OK "App registration already recorded (Client ID: $($State['clientId']))"
        $existingApp = az ad app show --id $State['clientId'] --output json 2>&1 | ConvertFrom-Json
    } else {
        Write-Step "Checking for existing app registration '$APP_NAME'..."
        $apps = az ad app list --display-name $APP_NAME --output json 2>&1 | ConvertFrom-Json
        # Handle both single object and array returns
        if ($null -ne $apps) {
            $appList = @($apps)  # Force to array
            if ($appList.Count -gt 0) {
                $existingApp = $appList[0]
                Write-OK "Found existing app (App ID: $($existingApp.appId))"
            }
        }
    }

    if ($null -eq $existingApp) {
        Write-Host ""
        Write-Host "  🔨 CREATING AZURE RESOURCE: Entra ID App Registration" -ForegroundColor Yellow
        Write-Step "Creating Entra ID app registration: $APP_NAME"
        $newApp = az ad app create --display-name $APP_NAME --output json --only-show-errors | ConvertFrom-Json
        $existingApp = $newApp
        Write-OK "✅ NEW RESOURCE CREATED: App registration (App ID: $($existingApp.appId))"
    }

    $clientId = $existingApp.appId
    $State['clientId'] = $clientId
    Save-State $State

    # ── 5b: Service Principal ─────────────────────────────────────────────────
    Write-Step "Checking service principal..."
    $sp = az ad sp list --filter "appId eq '$clientId'" --output json --only-show-errors 2>$null | ConvertFrom-Json
    $spList = @($sp)  # Force to array
    if ($spList.Count -eq 0) {
        Write-Host ""
        Write-Host "  🔨 CREATING AZURE RESOURCE: Service Principal" -ForegroundColor Yellow
        Write-Step "Creating service principal..."
        az ad sp create --id $clientId --output none --only-show-errors
        Write-OK "✅ NEW RESOURCE CREATED: Service principal"
        Write-Info "   Waiting 10 seconds for Entra ID replication..."
        # Wait for Entra ID replication
        Start-Sleep -Seconds 10
    } else {
        Write-OK "Service principal already exists"
    }

    # ── 5c: Federated Credentials ─────────────────────────────────────────────
    $fedCreds = az ad app federated-credential list --id $clientId --output json --only-show-errors 2>$null | ConvertFrom-Json

    # Helper: create federated cred via temp file to avoid Windows quoting issues
    function New-FederatedCred([string]$AppClientId, [hashtable]$CredParams) {
        $tmpFile = [System.IO.Path]::GetTempFileName()
        try {
            $CredParams | ConvertTo-Json -Compress | Set-Content -Path $tmpFile -Encoding UTF8
            az ad app federated-credential create --id $AppClientId --parameters "@$tmpFile" --only-show-errors | Out-Null
        } finally {
            Remove-Item -Path $tmpFile -ErrorAction SilentlyContinue
        }
    }

    # Credential 1: main branch (for terraform apply on push to main)
    $mainSubject = "repo:$owner/$GITHUB_REPO:ref:refs/heads/main"
    if (-not ($fedCreds | Where-Object { $_.subject -eq $mainSubject })) {
        Write-Host ""
        Write-Host "  🔨 CREATING AZURE RESOURCE: Federated Credential (main branch)" -ForegroundColor Yellow
        Write-Step "Creating federated credential for 'main' branch..."
        New-FederatedCred $clientId @{
            name        = 'github-main-branch'
            issuer      = 'https://token.actions.githubusercontent.com'
            subject     = $mainSubject
            description = 'GitHub Actions OIDC – push to main (terraform apply)'
            audiences   = @('api://AzureADTokenExchange')
        }
        Write-OK "✅ NEW RESOURCE CREATED: Federated credential (main branch)"
    } else {
        Write-OK "Federated credential already exists: main branch"
    }

    # Credential 2: pull_request (for terraform plan on PRs)
    $prSubject = "repo:$owner/$GITHUB_REPO:pull_request"
    if (-not ($fedCreds | Where-Object { $_.subject -eq $prSubject })) {
        Write-Host ""
        Write-Host "  🔨 CREATING AZURE RESOURCE: Federated Credential (pull requests)" -ForegroundColor Yellow
        Write-Step "Creating federated credential for pull requests..."
        New-FederatedCred $clientId @{
            name        = 'github-pull-requests'
            issuer      = 'https://token.actions.githubusercontent.com'
            subject     = $prSubject
            description = 'GitHub Actions OIDC – pull requests (terraform plan)'
            audiences   = @('api://AzureADTokenExchange')
        }
        Write-OK "✅ NEW RESOURCE CREATED: Federated credential (pull requests)"
    } else {
        Write-OK "Federated credential already exists: pull_request"
    }

    # Credential 3: environment:prod (for environment-gated deployments)
    $prodSubject = "repo:$owner/$GITHUB_REPO:environment:prod"
    if (-not ($fedCreds | Where-Object { $_.subject -eq $prodSubject })) {
        Write-Host ""
        Write-Host "  🔨 CREATING AZURE RESOURCE: Federated Credential (prod environment)" -ForegroundColor Yellow
        Write-Step "Creating federated credential for 'prod' environment..."
        New-FederatedCred $clientId @{
            name        = 'github-environment-prod'
            issuer      = 'https://token.actions.githubusercontent.com'
            subject     = $prodSubject
            description = 'GitHub Actions OIDC – environment: prod (deployment protection)'
            audiences   = @('api://AzureADTokenExchange')
        }
        Write-OK "✅ NEW RESOURCE CREATED: Federated credential (prod environment)"
    } else {
        Write-OK "Federated credential already exists: environment:prod"
    }

    # ── 5d: RBAC Role Assignment ──────────────────────────────────────────────
    Write-Step "Checking role assignments at subscription scope..."
    $scope   = "/subscriptions/$subId"
    $spObjId = (az ad sp show --id $clientId --query id --output tsv --only-show-errors 2>$null).Trim()

    foreach ($roleName in @('Contributor', 'User Access Administrator')) {
        $existingRA = az role assignment list --assignee $spObjId --role $roleName --scope $scope `
            --output json --only-show-errors 2>$null | ConvertFrom-Json
        $raList = @($existingRA)  # Force to array
        if ($raList.Count -eq 0) {
            Write-Host ""
            Write-Host "  🔨 CREATING AZURE RESOURCE: RBAC Role Assignment" -ForegroundColor Yellow
            Write-Host "     Role:  $roleName" -ForegroundColor White
            Write-Host "     Scope: Subscription-wide" -ForegroundColor Red
            Write-Step "Assigning '$roleName' role..."
            az role assignment create `
                --assignee-object-id $spObjId `
                --assignee-principal-type ServicePrincipal `
                --role $roleName `
                --scope $scope `
                --output none `
                --only-show-errors
            Write-OK "✅ NEW RESOURCE CREATED: '$roleName' role assigned at subscription scope"
        } else {
            Write-OK "'$roleName' role already assigned"
        }
    }

    # ── 5e: GitHub Secrets ────────────────────────────────────────────────────
    Write-Step "Setting GitHub repository secrets..."

    # Get full path to gh command to avoid PATH resolution issues
    $ghCommand = Get-Command gh -ErrorAction SilentlyContinue
    if (-not $ghCommand) {
        Write-Warn "GitHub CLI (gh) not found in PATH - cannot set secrets automatically"
        Write-Manual "Set these secrets manually at:"
        Write-Info   "  https://github.com/$owner/$GITHUB_REPO/settings/secrets/actions"
        foreach ($secret in @(
            @{ Name = 'AZURE_CLIENT_ID';       Value = $clientId },
            @{ Name = 'AZURE_TENANT_ID';       Value = $tenantId },
            @{ Name = 'AZURE_SUBSCRIPTION_ID'; Value = $subId }
        )) {
            Write-Info "  $($secret.Name) = $($secret.Value)"
        }
    } else {
        $ghPath = $ghCommand.Source

        foreach ($secret in @(
            @{ Name = 'AZURE_CLIENT_ID';       Value = $clientId },
            @{ Name = 'AZURE_TENANT_ID';       Value = $tenantId },
            @{ Name = 'AZURE_SUBSCRIPTION_ID'; Value = $subId }
        )) {
            $secretValue = $secret.Value
            Write-Step "Setting secret: $($secret.Name)"
            
            # Use full path and stdin redirection to avoid PATH issues
            try {
                $secretValue | & $ghPath secret set $secret.Name --repo "$owner/$GITHUB_REPO" 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Write-OK "Secret set: $($secret.Name)"
                } else {
                    Write-Warn "Could not set secret '$($secret.Name)' via gh CLI."
                    Write-Manual "Set it manually in:"
                    Write-Info   "  https://github.com/$owner/$GITHUB_REPO/settings/secrets/actions"
                    Write-Info   "  Name:  $($secret.Name)"
                    Write-Info   "  Value: $secretValue"
                }
            } catch {
                Write-Warn "Error setting secret '$($secret.Name)': $_"
                Write-Manual "Set it manually in:"
                Write-Info   "  https://github.com/$owner/$GITHUB_REPO/settings/secrets/actions"
                Write-Info   "  Name:  $($secret.Name)"
                Write-Info   "  Value: $secretValue"
            }
        }
    }

    $State['s5_oidc_done'] = $true
    Save-State $State
    Write-OK "Section 5 complete"
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 7 — TERRAFORM REMOTE STATE BACKEND
# ─────────────────────────────────────────────────────────────────────────────
function Step-TerraformState([hashtable]$State) {
    Write-Header "Section 7 — Terraform Remote State Backend"

    $subId      = $State['subscriptionId']
    $orgPrefix  = $State['orgPrefix']
    $regionCode = 'scus'
    $region     = 'southcentralus'

    # ── RESOURCE CREATION WARNING ─────────────────────────────────────────────
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Red
    Write-Host "  " -NoNewline
    Write-Host "🚨 WARNING: AZURE RESOURCES WILL BE CREATED" -ForegroundColor Red
    Write-Host "  " -NoNewline
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Red
    Write-Host ""
    Write-Host "  This section will create the following REAL Azure resources:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  📋 RESOURCES TO BE CREATED:" -ForegroundColor Cyan
    Write-Host "     1️⃣  Resource Group: rg-$orgPrefix-tfstate-$regionCode" -ForegroundColor White
    Write-Host "     2️⃣  Storage Account: st$($orgPrefix)tfstate<random>" -ForegroundColor White
    Write-Host "     3️⃣  Blob Container: tfstate" -ForegroundColor White
    Write-Host "     4️⃣  Resource Locks: Delete protection" -ForegroundColor White
    Write-Host ""
    Write-Host "  📍 LOCATION: $region" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  💰 COST IMPACT: Low" -ForegroundColor Yellow
    Write-Host "     - Storage account: ~`$1-5/month (depends on usage)" -ForegroundColor Gray
    Write-Host "     - Terraform state files are typically < 1 MB" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  🎯 PURPOSE:" -ForegroundColor Cyan
    Write-Host "     Stores Terraform state files for infrastructure management" -ForegroundColor Gray
    Write-Host "     Required for team collaboration and CI/CD deployments" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  ⚠️  TARGET SUBSCRIPTION:" -ForegroundColor Yellow
    Write-Host "     $($State['subscriptionName']) ($subId)" -ForegroundColor White
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Red
    Write-Host ""
    $confirm = Read-Host "  Type 'CREATE' (all caps) to proceed, or anything else to skip"
    if ($confirm -ne 'CREATE') {
        Write-Warn "Resource creation cancelled by user."
        Write-Info "You can re-run this script to continue from this point."
        return
    }
    Write-Host ""
    Write-OK "User confirmed - proceeding with resource creation..."
    Write-Host ""

    # ── 7a: Check if storage account already exists ───────────────────────────
    if ($State.ContainsKey('stateStorageAccount')) {
        $saName = $State['stateStorageAccount']
        $exists = az storage account show --name $saName --output json 2>&1 | ConvertFrom-Json
        if ($exists.name) {
            Write-OK "State storage account already exists: $saName"
            # still update backend.hcl if needed
            Step-UpdateBackendHCL $State $saName
            return
        }
    }

    # ── 7b: Create a terraform.tfvars for the bootstrap run ──────────────────
    $tfvarsPath = Join-Path $TF_BOOTSTRAP 'terraform.tfvars'
    if (-not (Test-Path $tfvarsPath)) {
        Write-Step "Generating terraform.tfvars for backend-bootstrap..."
        $tfvars = @"
management_subscription_id      = "$subId"
org_prefix                       = "$orgPrefix"
primary_region                   = "$region"
primary_region_code              = "$regionCode"

# Initial bootstrap: public access ON, no private endpoint
# (flip these after the management VNet is deployed in Phase 1)
allow_public_access_during_setup = true
enable_private_endpoint          = false

default_tags = {
  owner       = "Platform Team"
  application = "Landing Zone Infrastructure"
  environment = "prod"
  cost_center = "IT-Platform"
  managed_by  = "Terraform"
}
"@
        Set-Content -Path $tfvarsPath -Value $tfvars -Encoding UTF8
        Write-OK "Created terraform.tfvars (bootstrap mode: public access enabled)"
    } else {
        Write-OK "terraform.tfvars already exists — using as-is"
    }

    # ── 7c: terraform init ────────────────────────────────────────────────────
    Write-Step "Running terraform init in backend-bootstrap..."
    Push-Location $TF_BOOTSTRAP
    try {
        $env:TF_CLI_ARGS_init = '-input=false'
        $initOut = terraform init -upgrade 2>&1
        Remove-Item Env:\TF_CLI_ARGS_init -ErrorAction SilentlyContinue
        if ($LASTEXITCODE -ne 0) {
            Write-Err "terraform init failed:"
            $initOut | ForEach-Object { Write-Info $_ }
            throw "terraform init failed"
        }
        Write-OK "terraform init succeeded"

        # ── 7d: terraform apply ───────────────────────────────────────────────
        Write-Step "Running terraform apply (this creates the storage account)..."
        Write-Warn "Review the plan carefully. Type 'yes' when prompted."
        Write-Host ""
        terraform apply -input=false -var-file="terraform.tfvars"

        if ($LASTEXITCODE -ne 0) {
            throw "terraform apply failed — check output above"
        }

        # ── 7e: Capture storage account name from output ───────────────────
        $saName = (terraform output -raw storage_account_name 2>&1).Trim()
        if ([string]::IsNullOrEmpty($saName)) {
            throw "Could not read storage_account_name from terraform output"
        }
        Write-OK "Storage account deployed: $saName"
        $State['stateStorageAccount'] = $saName
        Save-State $State

    } finally {
        Pop-Location
    }

    Step-UpdateBackendHCL $State $saName
    $State['s7_tfstate_done'] = $true
    Save-State $State
}

function Step-UpdateBackendHCL([hashtable]$State, [string]$StorageAccountName) {
    Write-Header "Updating backend.hcl files with storage account name"

    $hclFiles = Get-ChildItem -Path (Join-Path $REPO_ROOT 'terraform' 'live') -Recurse -Filter 'backend.hcl'
    foreach ($f in $hclFiles) {
        $content = Get-Content $f.FullName -Raw
        if ($content -match '<REPLACE_WITH_OUTPUT_FROM_BOOTSTRAP>') {
            $updated = $content -replace '<REPLACE_WITH_OUTPUT_FROM_BOOTSTRAP>', $StorageAccountName
            Set-Content -Path $f.FullName -Value $updated -Encoding UTF8
            Write-OK "Updated: $($f.FullName.Replace($REPO_ROOT,'').TrimStart('\/'))"
        } else {
            # Check if it still has wrong name (different from what we deployed)
            $currentLine = ($content -split "`n") | Where-Object { $_ -match 'storage_account_name' } | Select-Object -First 1
            if ($currentLine -notmatch $StorageAccountName) {
                $updated = $content -replace '(storage_account_name\s*=\s*")[^"]*(")', "`${1}$StorageAccountName`${2}"
                Set-Content -Path $f.FullName -Value $updated -Encoding UTF8
                Write-OK "Updated: $($f.FullName.Replace($REPO_ROOT,'').TrimStart('\/'))"
            } else {
                Write-OK "Already correct: $($f.FullName.Replace($REPO_ROOT,'').TrimStart('\/'))"
            }
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 8 — VERIFY CI/CD WORKFLOWS
# ─────────────────────────────────────────────────────────────────────────────
function Step-VerifyWorkflows([hashtable]$State) {
    Write-Header "Section 8 — CI/CD Workflow Verification"

    $expectedFiles = @(
        '.github/workflows/terraform-plan.yml',
        '.github/workflows/terraform-apply.yml',
        '.github/workflows/secrets-scan.yml'
    )

    $allOk = $true
    foreach ($rel in $expectedFiles) {
        $full = Join-Path $REPO_ROOT $rel
        if (Test-Path $full) {
            Write-OK $rel
        } else {
            Write-Err "Missing: $rel"
            $allOk = $false
        }
    }

    if ($allOk) {
        Set-StepDone $State 's8_workflows'
    } else {
        Write-Warn "Some workflow files are missing — check the repository structure."
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# TRIGGER AUTH TEST
# ─────────────────────────────────────────────────────────────────────────────
function Step-TriggerAuthTest([hashtable]$State) {
    Write-Header "Section 6 — Trigger OIDC Auth Test"

    if (-not (Test-StepDone $State 's3s6_pr_merged')) {
        Write-Warn "Auth-test workflow PR not yet merged — skipping trigger."
        Write-Info "Merge the PR from Section 3/6, then re-run this script."
        return
    }

    if (-not ($State.ContainsKey('s5_oidc_done'))) {
        Write-Warn "OIDC setup not complete — skipping auth test trigger."
        return
    }

    Write-Step "Triggering azure-auth-test workflow manually..."
    gh workflow run azure-auth-test.yml --repo "$GITHUB_OWNER/$GITHUB_REPO" --ref main 2>&1 | Out-Null

    if ($LASTEXITCODE -eq 0) {
        Write-OK "Workflow triggered."
        Write-Info "Watch results at: https://github.com/$GITHUB_OWNER/$GITHUB_REPO/actions"
        Write-Info "Confirm it shows green before proceeding."
        Write-Host ""
        Wait-ForUser "Press ENTER once the auth test workflow shows green..."
        Set-StepDone $State 's6_auth_test_passed'
    } else {
        Write-Warn "Could not trigger workflow via CLI (it may not be on main yet)."
        Write-Manual "Trigger it manually at:"
        Write-Info   "  https://github.com/$GITHUB_OWNER/$GITHUB_REPO/actions/workflows/azure-auth-test.yml"
        Write-Info   "  Click 'Run workflow' → 'Run workflow'"
        Wait-ForUser "Press ENTER once the workflow shows green..."
        Set-StepDone $State 's6_auth_test_passed'
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# FINAL SUMMARY
# ─────────────────────────────────────────────────────────────────────────────
function Write-FinalSummary([hashtable]$State) {
    Write-Header "Bootstrap Summary"

    $checks = @(
        @{ Key = 's1_done';           Label = 'Section 1 — Azure Identifiers';     Override = $true },
        @{ Key = 's2_skip';           Label = 'Section 2 — Entra SSO';             Override = $true; Skip = $true },
        @{ Key = 's3_codeowners';     Label = 'Section 3 — CODEOWNERS';            Override = $false },
        @{ Key = 's4_branch_protection'; Label = 'Section 4 — Branch Protection';  Override = $false },
        @{ Key = 's5_oidc_done';      Label = 'Section 5 — OIDC App & Secrets';    Override = $false },
        @{ Key = 's6_auth_test_passed'; Label = 'Section 6 — Auth Test Passed';    Override = $false },
        @{ Key = 's7_tfstate_done';   Label = 'Section 7 — Terraform State Backend'; Override = $false },
        @{ Key = 's8_workflows';      Label = 'Section 8 — CI/CD Workflows';       Override = $false }
    )

    foreach ($c in $checks) {
        $done = $c.Override -or (Test-StepDone $State $c.Key)
        if ($c.ContainsKey('Skip') -and $c.Skip) {
            Write-Host "  ⏭️   $($c.Label)  [SKIPPED — requires GitHub Enterprise]" -ForegroundColor DarkYellow
        } elseif ($done) {
            Write-OK $c.Label
        } else {
            Write-Warn "$($c.Label)  [INCOMPLETE — re-run this script]"
        }
    }

    Write-Host ""
    if ($State.ContainsKey('stateStorageAccount')) {
        Write-Info "State storage account : $($State['stateStorageAccount'])"
    }
    if ($State.ContainsKey('clientId')) {
        Write-Info "OIDC App Client ID    : $($State['clientId'])"
    }
    Write-Info "State saved to        : .bootstrap-state.json"
    Write-Host ""
    Write-Host ("─" * 70) -ForegroundColor DarkGray
    Write-Host "  Bootstrap complete! You can now open a PR to trigger terraform plan." -ForegroundColor Cyan
    Write-Host ("─" * 70) -ForegroundColor DarkGray
    Write-Host ""
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────
function Main {
    Clear-Host
    Write-Host ""
    Write-Host ("█" * 70) -ForegroundColor DarkCyan
    Write-Host "  HCW Landing Zone — Phase 0 Bootstrap Orchestrator" -ForegroundColor Cyan
    Write-Host "  Re-run at any time — all steps are idempotent." -ForegroundColor Gray
    Write-Host ("█" * 70) -ForegroundColor DarkCyan

    $state = Import-State

    # Section 1 always verified
    $state['s1_done'] = $true
    Save-State $state

    try {
        Test-Prerequisites
        Read-BootstrapConfig      $state
        
        # Initialize deployment-specific folder structure
        Initialize-DeploymentFolder $state

        # ── Execute sections in dependency order ──────────────────────────────
        # Files first (no Azure dependency)
        Step-CodeOwners         $state
        Step-AuthTestWorkflow   $state

        # Azure OIDC (before PR so secrets exist when workflow runs)
        Step-OIDCSetup          $state

        # Commit files + open PR (user merges)
        Step-CommitAndPR        $state

        # Branch protection (guidance; user does it in GitHub UI)
        Step-BranchProtection   $state

        # Trigger auth test
        Step-TriggerAuthTest    $state

        # Terraform state backend
        Step-TerraformState     $state

        # Verify CI/CD workflows
        Step-VerifyWorkflows    $state

    } catch {
        Write-Host ""
        Write-Err "Bootstrap halted: $_"
        Write-Info "Fix the issue above and re-run this script — it will pick up where it left off."
        Write-Host ""
        exit 1
    }

    Write-FinalSummary $state
}

Main
