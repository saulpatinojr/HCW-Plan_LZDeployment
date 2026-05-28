# Daily Operations Checklist

## Purpose
Perform these checks every business day to ensure landing zone health and identify issues early.

## Prerequisites
- Access to Azure Portal
- Reader role on all subscriptions
- Access to Log Analytics workspace

## Duration
**Estimated time**: 15-20 minutes

---

## Morning Health Check (9:00 AM)

### 1. Check Azure Service Health

**Why**: Identify any Azure platform issues affecting your regions

**Steps**:
1. Open Azure Portal
2. Navigate to **Service Health**
3. Review **Service Issues** tab
4. Check for issues in:
   - South Central US
   - North Central US
5. Review **Planned Maintenance** tab
6. Note any upcoming maintenance windows

**Action if issues found**:
- Review impact on landing zone resources
- Notify affected teams
- Document in daily log

---

### 2. Review Backup Job Status

**Why**: Ensure all backup jobs completed successfully

**Steps**:
1. Navigate to **Recovery Services Vaults**
2. Open `rsv-platform-scus-prod-01`
3. Go to **Monitoring** > **Backup Jobs**
4. Filter to last 24 hours
5. Verify all jobs show "Completed"
6. Repeat for `rsv-platform-ncus-prod-01`

**Action if failures found**:
- Check error message
- Verify VM is running
- Review backup policy configuration
- See [Troubleshooting](./09-troubleshooting.md#backup-failures)

---

### 3. Check Azure Firewall Health

**Why**: Verify firewall is processing traffic normally

**Steps**:
1. Navigate to **Firewalls**
2. Open `azfw-hub-scus-prod-01`
3. Go to **Metrics**
4. Review last 24 hours:
   - **Throughput** (should show normal patterns)
   - **Health state** (should be 100%)
   - **SNAT port utilization** (should be < 80%)
5. Repeat for DR firewall `azfw-hub-ncus-prod-01`

**Action if issues found**:
- High SNAT utilization: Review firewall rules, consider scaling
- Low health state: Check for failed backend probes
- Zero throughput: Check network connectivity
- Escalate if persists > 30 minutes

---

### 4. Review Policy Compliance

**Why**: Ensure resources comply with governance policies

**Steps**:
1. Navigate to **Policy**
2. Click **Compliance**
3. Review compliance percentage by management group:
   - Root: Should be > 95%
   - Platform: Should be > 98%
   - Landing Zones: Should be > 90%
   - Sandbox: Should be > 85%
4. Click on any non-compliant resources
5. Review reason for non-compliance

**Action if non-compliant**:
- New resources: May not be evaluated yet (wait 24h)
- Missing tags: Contact resource owner
- Policy exemptions: Verify exemption is documented
- Policy conflicts: Review with platform team

---

### 5. Check Sandbox Expiry Report

**Why**: Identify resources approaching expiry (for proactive notification)

**Steps**:
1. Navigate to **Automation Accounts**
2. Open `aa-platform-scus-prod-01`
3. Go to **Runbooks** > `Cleanup-ExpiredSandboxResources`
4. Review **Recent Jobs**
5. Check last run status and output
6. Note any resources deleted in last run

**Query expired resources** (Azure Resource Graph):
```kql
Resources
| where subscriptionId == "<SANDBOX_SUBSCRIPTION_ID>"
| where tags['expiry_date'] != ""
| extend expiryDate = todatetime(tags['expiry_date'])
| extend daysUntilExpiry = datetime_diff('day', expiryDate, now())
| where daysUntilExpiry between (-30 .. 7)
| project name, resourceGroup, type, expiryDate, daysUntilExpiry, tags['owner']
| order by daysUntilExpiry asc
```

**Action**:
- Resources expiring in < 7 days: Email owner
- Resources < 0 days (past expiry): Verify cleanup ran
- Resources with no owner tag: Escalate to platform team

---

### 6. Review Security Alerts

**Why**: Identify potential security issues

**Steps**:
1. Navigate to **Microsoft Defender for Cloud**
2. Click **Security alerts**
3. Filter to last 24 hours
4. Review any Medium or High severity alerts
5. Check **Recommendations** tab
6. Note any new recommendations

**Action if alerts found**:
- High severity: Escalate immediately to security team
- Medium severity: Investigate and document
- Recommendations: Add to backlog for monthly review

---

### 7. Check Terraform State Backend Health

**Why**: Ensure state backend is accessible and healthy

**Steps**:
1. Navigate to **Storage Accounts**
2. Open `st<org>tfstate<suffix>`
3. Go to **Monitoring** > **Metrics**
4. Review **Availability** (should be 100%)
5. Check **Blob Storage** > **Containers**
6. Verify all expected containers exist:
   - global-mgmt-groups
   - global-policies
   - platform-connectivity
   - platform-management
   - workloads-prod
   - workloads-nonprod
   - sandbox-isolation

**Action if issues**:
- Availability < 100%: Check Azure Service Health
- Missing containers: Escalate to platform team
- Access errors: Verify RBAC and private endpoint

---

## Daily Log Template

Document your daily checks:

```
Date: YYYY-MM-DD
Operator: [Your name]

[ ] Service Health - Status: OK / ISSUE
    Notes:

[ ] Backups - Status: OK / ISSUE
    Notes:

[ ] Firewall Health - Status: OK / ISSUE
    Notes:

[ ] Policy Compliance - Status: OK / ISSUE
    Non-compliant resources:

[ ] Sandbox Expiry - Status: OK / ISSUE
    Resources expiring soon:

[ ] Security Alerts - Status: OK / ISSUE
    Alerts:

[ ] State Backend - Status: OK / ISSUE
    Notes:

Issues escalated:
- None / [List issues]

Follow-up needed:
- None / [List tasks]
```

---

## End of Day (5:00 PM)

### Quick Re-check
- Any new critical alerts?
- Any changes deployed today?
- Any follow-up tasks for tomorrow?

---

## Next Steps
- **Weekly**: See [Weekly Operations](./02-weekly-operations.md)
- **Issues found**: See [Incident Triage](./04-incident-triage.md)
- **Changes needed**: See [Change Management](./05-change-management.md)
