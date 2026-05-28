# Day 2 Operations Guide
# Azure Landing Zone - Operations Manual

Welcome to the Azure Landing Zone operations guide. This documentation provides step-by-step procedures for Day 2 support and maintenance.

## Documentation Structure

- [Daily Operations](./01-daily-operations.md) - Daily health checks and monitoring
- [Weekly Operations](./02-weekly-operations.md) - Weekly maintenance tasks
- [Monthly Operations](./03-monthly-operations.md) - Monthly reviews and audits
- [Incident Triage](./04-incident-triage.md) - How to respond to alerts and incidents
- [Change Management](./05-change-management.md) - Process for making infrastructure changes
- [DR Testing](./06-dr-testing.md) - Disaster recovery test procedures
- [Sandbox Lifecycle](./07-sandbox-lifecycle.md) - Managing sandbox resources and cleanup
- [Access Requests](./08-access-requests.md) - RBAC and permission management
- [Troubleshooting](./09-troubleshooting.md) - Common issues and solutions
- [Escalation Matrix](./10-escalation-matrix.md) - When and who to escalate to

## Quick Reference

### Emergency Contacts
- **Platform Team Lead**: [Contact info]
- **Network Operations**: [Contact info]
- **Security Team**: [Contact info]
- **On-Call Rotation**: [Link to PagerDuty/on-call schedule]

### Key Resources
- Azure Portal: https://portal.azure.com
- GitHub Repository: https://github.com/saulpatinojr/HCW-Demo-LZDeployment
- Log Analytics Workspace: [Link]
- Terraform State Storage: `st<org>tfstate<suffix>` in Management subscription

### Subscription Overview
| Subscription | Purpose | Management Group |
|---|---|---|
| Identity | Identity-related services | Platform |
| Connectivity | Hubs, firewalls, gateways | Platform |
| Management | Backup, monitoring, automation | Platform |
| Prod Workload | Production applications | Landing Zones |
| NonProd Workload | Non-production applications | Landing Zones |
| Sandbox | Experimentation (air-gapped) | Sandbox |

### Network Overview
| VNet | Region | Address Space | Purpose |
|---|---|---|---|
| vnet-hub-scus-prod-01 | South Central US | 10.0.0.0/16 | Primary hub |
| vnet-hub-ncus-prod-01 | North Central US | 10.10.0.0/16 | DR hub |
| vnet-prod-app-scus-prod-01 | South Central US | 10.1.0.0/16 | Prod spoke |
| vnet-prod-app-ncus-prod-01 | North Central US | 10.11.0.0/16 | Prod spoke DR |
| vnet-sandbox-scus-sandbox-01 | South Central US | 10.99.0.0/16 | Sandbox (isolated) |

### Firewall Configuration
- **Type**: [Azure Firewall / Palo Alto / Fortinet]
- **Primary Hub IP**: [From Terraform outputs]
- **DR Hub IP**: [From Terraform outputs]

## General Principles

1. **Always check monitoring first** - Review dashboards and alerts before taking action
2. **Document everything** - Log all changes and observations
3. **Test in nonprod first** - Never test changes directly in production
4. **Follow change management** - All infrastructure changes require approval
5. **Know your limits** - Escalate when uncertain
6. **Backup before changes** - Verify backups exist before making changes
7. **Communicate proactively** - Notify stakeholders of planned maintenance

## Getting Started

If you're new to this landing zone, start with:
1. Read this overview
2. Review [Daily Operations](./01-daily-operations.md)
3. Walk through [Sandbox Lifecycle](./07-sandbox-lifecycle.md) to understand resource expiry
4. Familiarize yourself with [Incident Triage](./04-incident-triage.md)
5. Review [Escalation Matrix](./10-escalation-matrix.md) so you know when to ask for help

## Support Channels

- **Slack**: #azure-platform-support
- **Email**: azure-platform-team@company.com
- **Tickets**: [ServiceNow/Jira link]
- **Emergency**: [On-call phone number]
