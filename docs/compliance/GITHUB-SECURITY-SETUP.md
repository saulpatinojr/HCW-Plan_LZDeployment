# GitHub Repository Security Configuration

## Enable Secret Scanning & Push Protection

**Required Actions**: These settings must be enabled manually in the GitHub repository.

### 1. Enable GitHub Advanced Security Features

Navigate to: `Settings` → `Security` → `Code security and analysis`

Enable the following features:

#### ✅ Dependency Graph
- **Status**: Enable
- **Purpose**: Track project dependencies for vulnerability detection

#### ✅ Dependabot Alerts
- **Status**: Enable
- **Purpose**: Receive alerts for vulnerabilities in dependencies
- **Auto-remediation**: Create automatic pull requests for vulnerable dependencies

#### ✅ Dependabot Security Updates
- **Status**: Enable
- **Purpose**: Automatically create pull requests to update vulnerable dependencies

#### ✅ Secret Scanning
- **Status**: Enable
- **Purpose**: Detect secrets accidentally committed to the repository
- **Coverage**: Scans entire git history and new commits

#### ✅ Push Protection
- **Status**: Enable (CRITICAL for Phase 1)
- **Purpose**: **Blocks commits containing secrets from being pushed**
- **Recommendation**: Do NOT bypass push protection warnings

### 2. Configure Secret Scanning Settings

Navigate to: `Settings` → `Security` → `Code security and analysis` → `Secret scanning`

Configure:
- ✅ **Enable secret scanning** for the repository
- ✅ **Enable push protection** - Blocks pushes containing secrets
- ✅ **Enable non-provider patterns** - Detects generic secrets (API keys, tokens)
- ✅ **Send alerts to** - Configure email notifications for secret detections

### 3. Review Secret Scanning Alerts

Navigate to: `Security` → `Secret scanning`

- Review any existing alerts
- Validate detected secrets
- Revoke and rotate compromised secrets
- Close false positives

### 4. Configure Branch Protection Rules

Navigate to: `Settings` → `Branches` → `main` → `Add rule`

Recommended settings:
- ✅ **Require pull request reviews** (1 approval minimum)
- ✅ **Require status checks** before merging:
  - `trufflehog-scan`
  - `gitleaks-scan`
  - `terraform-security-scan`
- ✅ **Require branches to be up to date** before merging
- ✅ **Do not allow bypassing** the above settings

### 5. Verify Workflow Permissions

Navigate to: `Settings` → `Actions` → `General` → `Workflow permissions`

Set:
- ✅ **Read and write permissions** (required for secret scanning to comment on PRs)
- ✅ **Allow GitHub Actions to create and approve pull requests** (for Dependabot)

## Verification Steps

After enabling all settings:

1. **Test Push Protection**:
   ```bash
   # Try to commit a test secret (will be blocked)
   echo "password=SuperSecret123!" > test-secret.txt
   git add test-secret.txt
   git commit -m "test: verify push protection"
   git push origin main
   # Expected: Push blocked with secret detection warning
   ```

2. **Verify Dependabot**:
   - Check `Insights` → `Dependency graph` → `Dependabot`
   - Confirm weekly schedule is active
   - Wait for first Dependabot PR (Mondays at 02:00 UTC)

3. **Verify Secret Scanning Workflow**:
   - Create a test PR
   - Confirm `secrets-scan.yml` workflow runs
   - Check workflow run logs for TruffleHog, Gitleaks, tfsec results

## Expected Security Posture After Configuration

| Feature | Status | Impact |
|---|---|---|
| **Push Protection** | ✅ Enabled | Blocks commits with secrets |
| **Secret Scanning** | ✅ Enabled | Historical + new commit scanning |
| **Dependabot** | ✅ Enabled | Weekly dependency updates |
| **TruffleHog** | ✅ Automated | OSS secret detection in CI |
| **Gitleaks** | ✅ Automated | Git history secret scanning |
| **tfsec** | ✅ Automated | Terraform security analysis |

## Post-Configuration Checklist

- [ ] Repository settings: Dependency graph enabled
- [ ] Repository settings: Dependabot alerts enabled
- [ ] Repository settings: Dependabot security updates enabled
- [ ] Repository settings: Secret scanning enabled
- [ ] Repository settings: Push protection enabled
- [ ] Branch protection: Status checks required for merge
- [ ] Workflow permissions: Read/write access configured
- [ ] Test: Push protection blocks test secret
- [ ] Test: Secret scanning workflow runs on PR
- [ ] Verify: Dependabot scheduled for Mondays

## Troubleshooting

### Issue: Workflow Fails with "Permission Denied"
**Solution**: Enable read/write workflow permissions in repository settings

### Issue: Dependabot PRs Not Created
**Solution**: 
1. Check `Insights` → `Dependency graph` → `Dependabot` for errors
2. Verify `dependabot.yml` syntax
3. Ensure Dependabot has access to the repository

### Issue: Push Protection Not Blocking Secrets
**Solution**:
1. Verify push protection is enabled in repository settings
2. Ensure you're pushing to a protected branch (main)
3. Check if secret pattern is recognized by GitHub

## Additional Resources

- [GitHub Secret Scanning Documentation](https://docs.github.com/en/code-security/secret-scanning)
- [GitHub Push Protection](https://docs.github.com/en/code-security/secret-scanning/push-protection-for-repositories-and-organizations)
- [Dependabot Configuration](https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file)
- [TruffleHog Documentation](https://github.com/trufflesecurity/trufflehog)
- [Gitleaks Documentation](https://github.com/gitleaks/gitleaks)

---

**Document Version**: 1.0  
**Last Updated**: May 28, 2026  
**Phase 1 Task**: SEC-1 - GitHub Secret Scanning
