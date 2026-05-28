# Change Management Process

## Purpose
Ensure all infrastructure changes are planned, approved, tested, and safely deployed.

## Change Categories

| Type | Approval Required | Testing Required | Deployment Window | Examples |
|---|---|---|---|---|
| **Emergency** | Post-approval | No (document why) | Immediate | Security patch, outage remediation |
| **Standard** | Team Lead | Nonprod first | Change window | Firewall rules, policy updates, spoke deployment |
| **Major** | CAB + Team Lead | Full DR test | Scheduled maintenance | Hub changes, management group restructure, DR failover |
| **Minor** | Self-service | Optional | Anytime | Sandbox changes, documentation updates, tags |

---

## Change Request Template

Use this template for all Standard and Major changes:

```markdown
## Change Request: [Brief Title]

**Requested by**: [Your Name]  
**Date**: YYYY-MM-DD  
**Category**: Emergency / Standard / Major / Minor  
**Priority**: P1 / P2 / P3 / P4

### 1. Change Description
[What are you changing? Be specific about resources, configurations, code files]

### 2. Business Justification
[Why is this change needed? What problem does it solve?]

### 3. Affected Resources
- Subscriptions: [List]
- Resource Groups: [List]
- Specific Resources: [List]
- Blast Radius: [Production / NonProd / Sandbox]

### 4. Risk Assessment
**Risk Level**: Low / Medium / High / Critical  
**Potential Impact**:
- [Impact on availability]
- [Impact on security]
- [Impact on compliance]
- [Impact on cost]

### 5. Testing Plan
- [ ] Validated in nonprod environment
- [ ] Terraform plan reviewed
- [ ] Dry-run completed
- [ ] Security reviewed (if applicable)
- [ ] Backup verified (if applicable)

### 6. Rollback Plan
[Step-by-step instructions to revert this change]
[Estimated rollback time: X minutes]

### 7. Deployment Steps
1. [Step 1]
2. [Step 2]
3. [Step 3]
...

### 8. Validation Steps
[How will you verify the change was successful?]

### 9. Communication Plan
- [ ] Stakeholders notified
- [ ] Maintenance window scheduled
- [ ] Status page updated (if applicable)

### 10. Approvals
- [ ] Team Lead: [Name] - [Date]
- [ ] CAB (if major): [Name] - [Date]
- [ ] Security (if required): [Name] - [Date]
```

---

## Standard Change Workflow

### 1. Preparation (Before Opening PR)

**Test locally first**:
```powershell
cd terraform/live/<layer>
terraform init -backend-config=backend.hcl
terraform validate
terraform plan -out=tfplan
# Review plan carefully!
```

**Check for**:
- Resources being destroyed (especially in production)
- Unexpected changes to existing resources
- Compliance with naming standards
- Tag requirements met

**Required artifacts**:
- [ ] Terraform plan output saved
- [ ] Change request document completed
- [ ] Backup verified (if changing existing resources)
- [ ] Rollback plan documented

---

### 2. Open Pull Request

**PR Title Format**: `[LAYER] Brief description of change`

**Examples**:
- `[platform-connectivity] Add new firewall rule for app XYZ`
- `[workloads-prod] Deploy new spoke for Project Alpha`
- `[global] Update allowed locations policy`

**PR Description**:
```markdown
## Change Summary
[Brief description]

## Affected Layer
- [ ] global
- [ ] platform-connectivity
- [ ] platform-management
- [ ] workloads-prod
- [ ] sandbox

## Risk Level
- [ ] Low (tags, minor config)
- [ ] Medium (new resources, non-critical config)
- [ ] High (firewall, hub, production impact)

## Terraform Plan
<details>
<summary>Show Plan</summary>

```
[Paste terraform plan output]
```
</details>

## Testing Completed
- [ ] Validated locally
- [ ] Reviewed for unintended changes
- [ ] Backup verified (if applicable)
- [ ] Rollback plan documented

## Rollback Plan
[Steps to revert this change]

## Deployment Window
- [ ] Anytime (low risk)
- [ ] Change window required: [Date/Time]
- [ ] Maintenance notification sent

cc @platform-team-lead
```

---

### 3. PR Review Process

**Required reviewers**:
- **Minor changes**: 1 peer reviewer
- **Standard changes**: Team lead
- **Major changes**: Team lead + CAB member

**Reviewer checklist**:
- [ ] Terraform plan reviewed
- [ ] No unexpected resource deletion
- [ ] Naming conventions followed
- [ ] Tags applied correctly
- [ ] Backup exists (if modifying production resources)
- [ ] Rollback plan is viable
- [ ] Security implications reviewed
- [ ] Cost implications reviewed

**Approval criteria**:
- Plan shows expected changes only
- Testing completed
- Documentation updated
- No outstanding comments

---

### 4. Deployment

**GitHub Actions will automatically**:
1. Run `terraform plan` on PR open
2. Post plan summary to PR
3. Wait for approval (GitHub Environment protection)
4. Run `terraform apply` on merge to main

**Manual deployment** (if needed):
```powershell
# 1. Ensure you're on main branch
git checkout main
git pull origin main

# 2. Navigate to layer
cd terraform/live/<layer>

# 3. Initialize
terraform init -backend-config=backend.hcl

# 4. Plan (final review)
terraform plan -out=tfplan

# 5. Apply
terraform apply tfplan

# 6. Verify outputs
terraform output
```

**During deployment**:
- Monitor Azure Portal for any errors
- Check GitHub Actions logs
- Be ready to rollback if issues detected

---

### 5. Validation

**Verify deployment success**:

1. **Check Terraform output**:
   - No errors in apply
   - All resources created/updated successfully

2. **Verify in Azure Portal**:
   - Resources exist with correct configuration
   - Tags applied correctly
   - Resource health shows healthy

3. **Run validation tests**:
   ```powershell
   # For connectivity changes
   Test-NetConnection -ComputerName <resource-ip> -Port 443
   
   # For policy changes
   Get-AzPolicyState -ManagementGroupName "<mg-name>" | Where-Object {$_.ComplianceState -eq "NonCompliant"}
   
   # For backup changes
   Get-AzRecoveryServicesBackupJob -VaultId "<vault-id>" -Status InProgress
   ```

4. **Document validation results** in change ticket

---

### 6. Post-Deployment

**Complete these steps**:
- [ ] Update change ticket status to "Deployed"
- [ ] Notify stakeholders of completion
- [ ] Remove maintenance banner (if used)
- [ ] Schedule post-deployment review (for major changes)
- [ ] Archive terraform plan artifact
- [ ] Update documentation if needed

---

## Emergency Change Process

### When to Use Emergency Process

Use ONLY for:
- Security incidents requiring immediate remediation
- Production outages requiring urgent fix
- Critical vulnerability patches
- Regulatory compliance urgent fix

**Do NOT use for**:
- Convenience ("I need this deployed now")
- Lack of planning
- User request ("they need it urgently")

---

### Emergency Change Steps

1. **Immediate notification**:
   - Post to incident channel
   - Notify team lead (or on-call if after hours)
   - Document reason for emergency

2. **Document intent**:
   ```markdown
   EMERGENCY CHANGE
   Initiated by: [Your Name]
   Time: [Timestamp]
   Reason: [Brief explanation]
   Resources affected: [List]
   Expected impact: [Describe]
   Rollback plan: [Steps]
   ```

3. **Deploy with care**:
   - Test in nonprod if possible (even 5 minutes of testing is better than none)
   - Document every step
   - Have rollback plan ready

4. **Monitor closely**:
   - Watch for errors
   - Verify fix is working
   - Be ready to rollback immediately

5. **Post-approval required**:
   - Within 24 hours, create proper change request
   - Document what was done and why
   - Review in next team meeting
   - Identify how to prevent need for emergency change in future

---

## Rollback Procedures

### Terraform Rollback

**Method 1: Revert to previous state** (safest)
```powershell
# 1. Find previous good state version
$ctx = (Get-AzStorageAccount -ResourceGroupName "rg-tfstate-scus-prod-01" -Name "<storage-account>").Context
Get-AzStorageBlob -Container "<container>" -Blob "terraform.tfstate" -Context $ctx | Get-AzStorageBlobVersion

# 2. Promote previous version
# (This requires manual portal action or Azure CLI)

# 3. Re-run terraform apply
terraform apply
```

**Method 2: Git revert** (for code changes)
```bash
# 1. Revert the merge commit
git revert <merge-commit-sha> -m 1

# 2. Push revert
git push origin main

# 3. GitHub Actions will automatically deploy the revert
```

**Method 3: Manual resource deletion** (last resort)
```powershell
# Only if Terraform state is corrupted
Remove-AzResource -ResourceId "<resource-id>" -Force
```

---

### Rollback Decision Tree

```
Has deployment completed?
├─ No → Cancel GitHub Actions workflow
└─ Yes → Are resources broken?
    ├─ No → Monitor, document, no rollback needed
    └─ Yes → Can you fix forward quickly? (< 15 min)
        ├─ Yes → Apply fix
        └─ No → Rollback
            └─ Method depends on change type:
                ├─ Config change → Git revert
                ├─ New resources → Delete resources
                └─ Modified resources → Restore previous state
```

---

## Change Windows

### Standard Change Windows

| Window | Day | Time (UTC) | Duration | Purpose |
|---|---|---|---|---|
| **Standard** | Tuesday/Thursday | 18:00-22:00 | 4 hours | Most changes |
| **Extended** | Saturday | 22:00-06:00 | 8 hours | Major changes |
| **Emergency** | Any time | Any time | As needed | Critical fixes only |

### Blackout Periods

**No changes allowed during**:
- Month-end (last 2 business days)
- Year-end (December 15 - January 5)
- Major business events (as communicated)

---

## Approval Matrix

| Change Type | Approval Required | Typical Duration |
|---|---|---|
| Documentation update | Self-service | Immediate |
| Sandbox resource | Self-service | Immediate |
| Tag update | Self-service | Immediate |
| New spoke deployment | Team Lead | 1 business day |
| Firewall rule change | Team Lead | 1 business day |
| Policy update | Team Lead + Security | 2 business days |
| Hub network change | Team Lead + CAB | 5 business days |
| DR failover | CAB + Exec Sponsor | 10 business days (unless emergency) |

---

## Best Practices

**Do**:
- ✅ Test in nonprod first
- ✅ Make small, incremental changes
- ✅ Deploy during change windows
- ✅ Have rollback plan ready
- ✅ Document everything
- ✅ Communicate with stakeholders

**Don't**:
- ❌ Deploy on Fridays (unless emergency)
- ❌ Make multiple unrelated changes in one PR
- ❌ Skip testing "because it's small"
- ❌ Deploy without reviewing Terraform plan
- ❌ Deploy during blackout periods
- ❌ Combine production + nonprod changes in one deployment
