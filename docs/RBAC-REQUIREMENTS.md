# RBAC Requirements & Service Principal Configuration

**Last Updated**: 2026-06-30  
**Phase**: Phase 1 - Task 1.1 Critical Remediations  
**Status**: 🟡 In Progress (automated by Workflow 020)

---

## Overview

This document defines the Role-Based Access Control (RBAC) requirements for the Landing Zone deployment. All service principals follow the principle of least privilege: **Contributor role only** (with limited User Access Administrator for specific layers).

---

## Service Principal Architecture

### Layer-Based Design

The Landing Zone uses **three separate service principals** per environment, each with blast-contained permissions:

```
├─ sp-terraform-main-prod (Main Branch Deployments)
│  ├─ Scope: Single subscription (production)
│  ├─ Roles: Contributor
│  ├─ Triggered by: Push to main branch
│  ├─ Purpose: Continuous deployment on commits
│  └─ Risk Level: High (auto-deploy)
│
├─ sp-terraform-dev-prod (Development Environment)
│  ├─ Scope: Single subscription (development)
│  ├─ Roles: Contributor, User Access Administrator
│  ├─ Triggered by: environment:dev
│  ├─ Purpose: Dev/staging deployments
│  └─ Risk Level: Medium (gated by GitHub environment)
│
└─ sp-terraform-prod-prod (Production Environment)
   ├─ Scope: Single subscription (production)
   ├─ Roles: Contributor, User Access Administrator
   ├─ Triggered by: environment:prod + environment:hub (approval gate)
   ├─ Purpose: Production deployments with manual approval
   └─ Risk Level: High (requires human approval)
```

---

## Role Definitions

### Contributor Role

**What It Does**:
- Create, read, update, delete resources
- Manage resource group contents
- Assign roles within resource group scope
- Restart virtual machines, scale app services, etc.

**What It CANNOT Do**:
- ❌ Create or modify subscriptions
- ❌ Change subscription-level policies
- ❌ Grant roles outside resource group scope
- ❌ Delete resource groups
- ❌ Access beyond assigned scope

**Security Posture**: ✅ Acceptable for infrastructure deployment

**Used By**: Main, Dev, Prod layers

---

### User Access Administrator Role

**What It Does**:
- Assign any role (including Owner) to any principal
- Modify RBAC at assigned scope
- Delegate permissions

**What It CANNOT Do**:
- Create resources (needs Contributor)
- Access resources (read/write)
- Delete resources

**Security Posture**: ⚠️ HIGH RISK if combined with Contributor

**Used By**: Dev, Prod layers ONLY (not Main)

**Justification**:
- **Dev**: Need to test RBAC delegation and role assignment
- **Prod**: Need to manage service accounts and identities
- **Main**: Not needed (auto-deploy shouldn't change RBAC)

---

## Scope Levels

### Subscription Scope
```
/subscriptions/<subscription-id>
```
- Applies to all resources within the subscription
- Allows management of any resource in the subscription
- **Risk**: Broad, but necessary for Terraform deployments
- **Mitigation**: Single scope per SP, no multi-subscription

### Resource Group Scope
```
/subscriptions/<subscription-id>/resourceGroups/<rg-name>
```
- Applies only to resources within the RG
- More restrictive than subscription scope
- **Not used currently** (deployments need subscription-level to manage RGs)
- **Future**: Move to RG scope after infrastructure stabilizes

### No Tenant/Global Scope
```
/
```
- **FORBIDDEN**: No service principal should have this
- Would allow global permission changes
- Violates least-privilege principle

---

## RBAC Assignment Validation

### Workflow 020 Checks

Automated workflow checks run:
- **On every push to main**
- **On every PR to main**
- **Weekly** (Monday 9 AM UTC)
- **On-demand** via workflow dispatch

### Validation Steps

| Step | Purpose | Failure = |
|------|---------|----------|
| Owner Role Check | Ensure no SP has Owner role | 🔴 CRITICAL |
| Contributor Verification | Verify Contributor role exists | ⚠️ WARNING |
| Scope Validation | Ensure subscription-only scope | 🔴 CRITICAL |
| Federated Credential Audit | Verify OIDC subjects are scoped | 🔴 CRITICAL |
| Global Permission Check | Detect tenant-level assignments | ⚠️ WARNING |

---

## Current RBAC State

### Main Service Principal (sp-terraform-main-prod)

| Attribute | Value |
|-----------|-------|
| Client ID | Stored in `AZURE_CLIENT_ID` secret |
| Display Name | sp-terraform-main-prod-{org-prefix} |
| Scope | Subscription: {subscription-id} |
| Roles | Contributor |
| OIDC Subjects | repo:owner/repo:ref:refs/heads/main |
| Status | ✅ Created by 000_LZ_Bootloader.ps1 |
| Last Validated | Via Workflow 020 |

**Validation**: ✅ PASS
- ✓ No Owner role
- ✓ Single Contributor role
- ✓ Subscription scope
- ✓ Proper OIDC scoping

---

### Dev Service Principal (sp-terraform-dev-prod)

| Attribute | Value |
|-----------|-------|
| Client ID | Set in env:dev GitHub secret |
| Display Name | sp-terraform-dev-prod-{org-prefix} |
| Scope | Subscription: {subscription-id} |
| Roles | Contributor, User Access Administrator |
| OIDC Subjects | repo:owner/repo:environment:dev |
| Status | ✅ Created by 000_LZ_Bootloader.ps1 |
| Last Validated | Via Workflow 020 |

**Validation**: ✅ PASS
- ✓ No Owner role
- ✓ Appropriate for dev environment
- ✓ User Access Admin justified (RBAC testing)
- ✓ Proper OIDC scoping

---

### Prod Service Principal (sp-terraform-prod-prod)

| Attribute | Value |
|-----------|-------|
| Client ID | Set in env:prod GitHub secret |
| Display Name | sp-terraform-prod-prod-{org-prefix} |
| Scope | Subscription: {subscription-id} |
| Roles | Contributor, User Access Administrator |
| OIDC Subjects | repo:owner/repo:environment:prod, repo:owner/repo:environment:hub |
| Status | ✅ Created by 000_LZ_Bootloader.ps1 |
| Last Validated | Via Workflow 020 |

**Validation**: ✅ PASS
- ✓ No Owner role
- ✓ Appropriate for prod environment
- ✓ User Access Admin justified (identity/service account management)
- ✓ Dual OIDC subjects (prod + hub approval gate)
- ✓ Hub environment requires manual approval

---

## RBAC Enforcement Policies

### Policy 1: No Owner Roles
- **Enforcement**: Automated (Workflow 020)
- **Action on Violation**: CRITICAL ALERT + BLOCK
- **Remediation**: Immediately remove Owner role
- **Justification**: Owner role bypasses all permission controls

### Policy 2: Subscriber Scope Only
- **Enforcement**: Automated (Workflow 020)
- **Action on Violation**: CRITICAL ALERT
- **Remediation**: Move to single subscription or re-create SP
- **Justification**: Multi-subscription SPs create cross-boundary risks

### Policy 3: OIDC Subject Scoping
- **Enforcement**: Automated (Workflow 020)
- **Action on Violation**: CRITICAL ALERT
- **Remediation**: Update federated credential subjects
- **Justification**: Overly broad OIDC allows unauthorized workflows

### Policy 4: Least-Privilege Role Assignment
- **Enforcement**: Automated (Workflow 020)
- **Action on Violation**: WARNING + RECOMMENDATION
- **Remediation**: Remove unnecessary roles
- **Justification**: Extra roles increase attack surface

---

## Audit Trail

### Change Log

| Date | Change | Who | Reason |
|------|--------|-----|--------|
| 2026-06-30 | Initial RBAC design | Phase 0 Bootstrap | Created 3 SPs per layer |
| TBD | Compliance audit | Phase 1.1 | Annual review |

### Monitoring

- **Workflow 020**: Runs every Monday at 9 AM UTC
- **Alert Channel**: GitHub Actions notifications
- **Review Period**: Monthly
- **Compliance Report**: Quarterly

---

## Troubleshooting

### Issue: Workflow 020 Reports "Owner Role Assigned"

**Diagnosis**:
```bash
az ad sp show --id <CLIENT_ID> --query id -o tsv | \
  xargs -I {} az role assignment list --assignee-object-id {} \
  --query "[?roleDefinitionName=='Owner']" -o table
```

**Resolution**:
```bash
# Remove Owner role immediately
az role assignment delete \
  --assignee-object-id <SP_OBJECT_ID> \
  --role "Owner" \
  --scope "/subscriptions/<SUBSCRIPTION_ID>"

# Re-run workflow 020 to verify
```

### Issue: Workflow 020 Reports "No Contributor Role"

**Diagnosis**:
```bash
az role assignment list --assignee <CLIENT_ID> \
  --scope "/subscriptions/<SUBSCRIPTION_ID>" -o table
```

**Resolution**:
```bash
# Assign Contributor role
az role assignment create \
  --role "Contributor" \
  --assignee-object-id <SP_OBJECT_ID> \
  --scope "/subscriptions/<SUBSCRIPTION_ID>"

# Re-run workflow 020 to verify
```

### Issue: Workflow 020 Reports "Multiple Subscriptions"

**Diagnosis**:
```bash
az role assignment list --assignee <CLIENT_ID> \
  --query "[].scope" | sort | uniq -c
```

**Resolution**:
- Remove roles from non-target subscriptions
- Ensure SP is scoped to single subscription only
- Use separate SPs for multi-subscription deployments

---

## Best Practices Reference

### ✅ DO's
- ✓ Run Workflow 020 on every push to main
- ✓ Review audit reports monthly
- ✓ Document any manual RBAC changes
- ✓ Keep federated credentials scoped to specific branches
- ✓ Use separate SPs for different environments
- ✓ Assign Contributor-only by default
- ✓ Assign User Access Admin only when necessary (Dev/Prod)
- ✓ Audit role assignments quarterly

### ❌ DON'Ts
- ✗ Don't assign Owner role to service principals
- ✗ Don't use single SP for multiple subscriptions
- ✗ Don't create overly broad OIDC subjects (repo:*)
- ✗ Don't store RBAC configurations in code (use automation)
- ✗ Don't skip Workflow 020 validation
- ✗ Don't manually modify service principal roles without updating docs
- ✗ Don't assign Global Reader or other unnecessary roles

---

## Future Enhancements

### Planned Improvements
- [ ] Move to resource-group-level scope (Phase 2)
- [ ] Implement conditional access for SP authentication
- [ ] Add certificate-based authentication (Phase 3)
- [ ] Integrate with Azure AD Privileged Identity Management (PIM)
- [ ] Implement time-based role assignments

### Monitoring Enhancements
- [ ] Real-time alerts for RBAC changes
- [ ] Monthly compliance dashboards
- [ ] Integration with Azure Sentinel
- [ ] Automated remediation for policy violations

---

## Compliance & Audit

### Regulatory Alignment
- ✅ CIS Benchmarks: PoLP enforcement
- ✅ Azure Security Best Practices: Least-privilege scoping
- ✅ OWASP: Separation of duties via layered SPs
- ✅ SOC 2: Audit trail via Workflow 020

### Audit Reports
- **Generated by**: Workflow 020
- **Retention**: 90 days in GitHub Artifacts
- **Review**: Monthly by platform team
- **Archive**: Quarterly to compliance storage

---

## Support & Escalation

### For RBAC Questions
- 📧 Check: `docs/RBAC-REQUIREMENTS.md` (this file)
- 🔄 Run: Workflow 020 to audit current state
- 📊 Review: `.github/workflows/020-rbac-validation.yml`

### For RBAC Issues
1. **Check Workflow 020 logs** — Gives specific error
2. **Run audit locally** — Verify with `az role assignment list`
3. **Review this doc** — Find remediation steps
4. **Create GitHub Issue** — If not resolved

### Escalation
- **Security CRITICAL**: Immediately remove problematic roles
- **Compliance Finding**: Document in RBAC-REQUIREMENTS.md and create remediation task
- **Incident**: Trigger incident response procedure

---

## Related Documentation

- 📋 [OIDC Best Practices](docs/bootstrap/OIDC-BEST-PRACTICES.md)
- 🔐 [Security Audit Report](docs/compliance/SECURITY-AUDIT-REPORT.md)
- 🚀 [Deployment Guide](docs/DEPLOYMENT-GUIDE.md)
- 📊 [Workflow 020 Automation](`.github/workflows/020-rbac-validation.yml`)

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-06-30 | Initial RBAC requirements from Phase 0 bootstrap |
| 1.1 | TBD | Add resource-group scoping guidance |
| 2.0 | TBD | PIM integration and conditional access |

---

**Last Updated**: 2026-06-30  
**Next Review**: 2026-07-31  
**Approver**: Platform Engineering Team
