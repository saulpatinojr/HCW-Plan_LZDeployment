# Escalation Matrix

## Purpose
Know who to contact, when to escalate, and what information to provide.

## General Escalation Guidelines

### When to Escalate

**Escalate immediately (P1)**:
- Complete production outage
- Security breach or suspected compromise
- Data loss or corruption
- Widespread service degradation
- Regulatory compliance violation

**Escalate same day (P2)**:
- Significant service degradation
- Failed DR test
- Critical backup failures
- Policy compliance < 80%
- Major change requiring approval

**Escalate next business day (P3)**:
- Minor service issues
- Non-critical alerts
- Documentation gaps
- Process improvements needed

**Escalate when needed (P4)**:
- Questions about procedures
- Training needs
- Tool requests
- Optimization opportunities

---

## Escalation Tiers

### Tier 1: Self-Service / Peer Support

**Who**: You and your team peers  
**When**: First line of support, routine operations  
**Resources**:
- Day 2 documentation (this folder)
- Team Slack channel: `#azure-platform-support`
- Internal wiki/KB
- Azure documentation

**Handle at this tier**:
- Daily/weekly/monthly operational tasks
- Routine troubleshooting (following runbooks)
- Documentation clarification
- Sandbox user requests

**Escalate if**:
- Issue not resolved in 2 hours (P3/P4)
- Issue not resolved in 30 minutes (P2)
- Issue requires approval
- Issue outside your knowledge/authority

---

### Tier 2: Platform Team Lead

**Who**: [Platform Team Lead Name]  
**Contact**:
- Email: platform-lead@company.com
- Slack: @platform-lead
- Phone: [Number]

**When to escalate**:
- Change approvals (standard and major)
- P2 incidents
- Backup failures persisting > 24 hours
- Policy changes needed
- Resource quota increases
- Budget concerns
- Sandbox cleanup failures > 2 days
- Terraform state issues

**Information to provide**:
```markdown
**Issue Summary**: [One sentence]
**Severity**: P1 / P2 / P3 / P4
**Started**: [Timestamp]
**Affected Resources**: [List]
**Actions Taken**: [What you've tried]
**Current Status**: [Where things stand now]
**Business Impact**: [What users are experiencing]
**Urgency**: [Why this needs escalation]
```

**Response time**:
- P1: 15 minutes
- P2: 1 hour
- P3: 4 hours
- P4: Next business day

---

### Tier 3: Specialty Teams

#### Network Operations Team

**Who**: Network Operations  
**Contact**:
- Email: netops@company.com
- Slack: `#network-operations`
- Phone: [Number]

**Escalate for**:
- Hub network failures
- VNet peering issues
- Firewall configuration (complex rules)
- Gateway connectivity issues
- Cross-region connectivity problems
- DR network failover
- BGP routing issues
- IP address planning

**Response time**: 2 hours (during business hours)

---

#### Security Team

**Who**: Information Security  
**Contact**:
- Email: infosec@company.com
- Slack: `#security-team`
- Phone: [Number]
- Emergency: [24/7 number]

**Escalate for**:
- Security alerts (Medium or higher)
- Suspected security incidents
- Policy violations requiring exemption
- Compliance concerns
- Access provisioning (privileged roles)
- Security configuration changes
- Vulnerability findings

**Response time**:
- Critical security: Immediate
- High: 1 hour
- Medium: 4 hours
- Low: Next business day

---

#### Backup & DR Team

**Who**: Backup/DR Operations  
**Contact**:
- Email: backup-team@company.com
- Slack: `#backup-dr`

**Escalate for**:
- Multiple backup failures
- Recovery Services Vault issues
- DR failover execution
- Backup policy changes
- Retention policy changes
- Restore requests (production data)

**Response time**: 4 hours (during business hours)

---

#### Azure Support (Microsoft)

**Who**: Microsoft Azure Support  
**How to engage**:
1. Portal > Help + Support > New Support Request
2. Or: https://aka.ms/azuresupport

**Escalate for**:
- Azure platform issues (not resolved via Service Health)
- Quota increase requests
- Billing disputes
- Service-specific technical issues
- Azure product bugs

**Support tiers**:
- **Developer**: Business hours, general guidance
- **Standard**: 24/7, critical response < 8h
- **Professional Direct**: 24/7, critical response < 1h
- **Premier**: 24/7, critical response < 15min

**Information Microsoft will ask for**:
- Subscription ID
- Resource IDs
- Error messages (exact text)
- Correlation IDs (from logs)
- Screenshots
- Timeline of issue

---

### Tier 4: Leadership / CAB

#### Platform Engineering Manager

**Who**: [Manager Name]  
**Contact**:
- Email: platform-manager@company.com
- Slack: @platform-manager
- Phone: [Number]

**Escalate for**:
- P1 incidents lasting > 2 hours
- Major changes requiring CAB approval
- Budget overruns
- Resource constraints (team capacity)
- Process changes
- Strategic decisions
- Vendor escalations (Microsoft)

---

#### Change Advisory Board (CAB)

**Who**: CAB Members (cross-functional team)  
**Meeting Schedule**: Every Wednesday 2:00 PM  
**Contact**: Submit via [Change Request System]

**Escalate for**:
- Major changes (hub, management group, DR failover)
- High-risk changes
- Changes affecting multiple teams
- Changes during blackout periods

**CAB approval timeline**: 5-10 business days

---

## Incident-Specific Escalation

### P1 - Critical Production Outage

**Immediate actions (first 5 minutes)**:
1. Post to incident channel: `#incidents`
2. Page on-call engineer:
   ```
   Subject: P1 - [Brief Description]
   Body: 
   - What's broken: [Description]
   - Impact: [Who is affected]
   - Started: [Time]
   - Your contact: [Your info]
   ```
3. Notify Platform Team Lead (call if no response in 5 min)
4. Start incident bridge: [Conference line]

**Escalation path**:
- **0-15 min**: You + On-call Engineer + Platform Lead
- **15-30 min**: Add Network Ops (if network issue) or relevant specialty team
- **30-60 min**: Platform Engineering Manager joins
- **60+ min**: Executive sponsor notified

**Communication cadence**:
- Update `#incidents` channel every 15 minutes
- Update status page every 30 minutes
- Email stakeholders at resolution

---

### P2 - Significant Degradation

**Immediate actions (first 30 minutes)**:
1. Post to `#azure-platform-support`
2. Notify Platform Team Lead (Slack or email)
3. Begin troubleshooting following runbooks

**Escalation path**:
- **0-1 hour**: You + Platform Team Lead
- **1-2 hours**: Add relevant specialty team
- **2+ hours**: Platform Engineering Manager

**Communication cadence**:
- Update `#azure-platform-support` every 30 minutes
- Email stakeholders at resolution

---

## On-Call Rotation

### Current On-Call Engineer

**Schedule**: [Link to PagerDuty/schedule]  
**Phone**: [On-call number]  
**Slack**: Use `/whois on-call` in Slack

### When to Page On-Call

**Page for**:
- P1 incidents
- P2 incidents after hours
- Security incidents (any severity)
- Any issue requiring immediate attention after hours

**Don't page for**:
- P3/P4 during business hours (use Slack)
- Questions (use async communication)
- Non-urgent issues
- Issues you haven't attempted to troubleshoot

---

## Escalation Communication Template

Use this template when escalating:

```markdown
**TO**: [Contact]
**SUBJECT**: [P1/P2/P3/P4] - [Brief Issue Description]

**Issue Summary**:
[1-2 sentence description of the problem]

**Severity**: P1 / P2 / P3 / P4
**Started**: [Date/Time]
**Current Status**: [Ongoing / Partially resolved / Contained]

**Affected Resources**:
- Subscription: [Name]
- Resources: [List]
- Users Impacted: [Estimated number or "All production users"]

**Business Impact**:
[What can't users do? What functionality is broken?]

**Actions Taken**:
1. [Action 1 and result]
2. [Action 2 and result]
3. [Action 3 and result]

**Current Theory**:
[What do you think is causing this?]

**Why I'm Escalating**:
[e.g., "Issue outside my expertise", "Requires approval", "Not resolving after 2 hours"]

**Request**:
[What do you need from the escalation contact?]

**Logs/Evidence**:
[Links to logs, screenshots, error messages]

**Contact Info**:
- Name: [Your name]
- Slack: [Your handle]
- Phone: [Your number]
```

---

## Partner Teams Contact List

| Team | Purpose | Contact | Hours |
|---|---|---|---|
| **Database Team** | SQL/Cosmos issues | db-team@company.com | Business hours |
| **App Dev Teams** | Application-level issues | [Varies by app] | Business hours |
| **Identity Team** | Entra ID, RBAC, auth | identity@company.com | Business hours |
| **Compliance** | Policy, audit, regulatory | compliance@company.com | Business hours |
| **Finance** | Billing, cost management | finance@company.com | Business hours |
| **Procurement** | Vendor, licensing | procurement@company.com | Business hours |

---

## Escalation Anti-Patterns

**Don't**:
- ❌ Escalate without attempting troubleshooting first
- ❌ Escalate P3/P4 to on-call after hours
- ❌ Bypass tiers (escalate to manager before team lead)
- ❌ Escalate without providing context/evidence
- ❌ Escalate via multiple channels simultaneously ("blast escalation")
- ❌ Escalate for issues you can self-service

**Do**:
- ✅ Follow runbooks before escalating
- ✅ Gather evidence before escalating
- ✅ Use appropriate severity
- ✅ Provide clear, concise summary
- ✅ Respect on-call boundaries
- ✅ Follow up after resolution

---

## After-Hours Support

**Coverage**: 24/7 for P1/P2 incidents only

**Primary**: On-call engineer (pager)  
**Backup**: Platform Team Lead (phone)  
**Executive Escalation**: [Executive contact for true emergencies]

**After-hours process**:
1. Attempt self-resolution (30 min max for P1, 1 hour for P2)
2. Page on-call
3. If no response in 15 min, call Platform Team Lead
4. If no response in 30 min, call backup listed in on-call schedule
5. Document everything (you'll debrief in the morning)

**Remember**: After hours is for emergencies only. If it can wait until morning, it's not an emergency.
