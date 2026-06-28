# Phase 3: Operations & Monitoring Guide
**Status:** ✅ COMPLETE  
**Date:** 2026-06-28  
**Author:** ALZ Operations Team

---

## Overview

Phase 3 deliverables provide complete operational capabilities for managing ALZ deployments at scale:
- Configuration-as-code system
- Pre-flight validation and cost verification
- Automated runbooks (health checks, optimization, compliance remediation)
- Real-time dashboards (health, cost, compliance)
- REST API for programmatic access
- CLI for operations teams
- Bulk operations for multi-deployment management
- Slack notifications for alerts

---

## 📦 Phase 3 Deliverables

### Configuration Management
| Component | File | Purpose |
|-----------|------|---------|
| **Config System** | `scripts/alz-config.ps1` | Centralized configuration (regions, costs, compliance, modules) |
| **Bulk Operations** | `scripts/Invoke-BulkOperations.ps1` | Multi-deployment operations (5 operation types) |

### Validation & Verification
| Component | File | Purpose |
|-----------|------|---------|
| **Deployment Validation** | `scripts/Validate-ALZDeployment.ps1` | Pre-flight checks (Terraform, Azure, OIDC, GitHub, quotas) |
| **Cost Verification** | `scripts/Verify-CostAccuracy.ps1` | Compare actual vs estimated costs, accuracy auditing |

### Automation Runbooks (Azure Automation)
| Component | File | Purpose | Schedule |
|-----------|------|---------|----------|
| **Health Check** | `runbooks/Health-Check.ps1` | Monitor firewall, gateways, peering, Log Analytics | Hourly |
| **Cost Optimization** | `runbooks/Cost-Optimization.ps1` | Identify unused resources, oversized VMs, storage issues | Daily |
| **Compliance Remediation** | `runbooks/Compliance-Remediation.ps1` | Auto-remediate policy violations, escalate critical | Event-triggered |

### Dashboards (Azure Workbooks)
| Component | File | Purpose |
|-----------|------|---------|
| **Health Dashboard** | `dashboards/Health-Dashboard-Template.json` | Deployment status, compliance, network, alerts |
| **Cost Dashboard** | `dashboards/Cost-Dashboard-Template.json` | Monthly spend, trends, optimization opportunities |
| **Compliance Dashboard** | `dashboards/Compliance-Dashboard-Template.json` | Policy compliance, violations, remediation status |

### API & Integrations
| Component | File | Purpose |
|-----------|------|---------|
| **REST API** | `functions/run.ps1` | 6 HTTP endpoints for programmatic access |
| **Slack Notifications** | `functions/Slack-Notification.ps1` | Event-based alerts to Slack |

### Operations Tools
| Component | File | Purpose |
|-----------|------|---------|
| **CLI Module** | `cli/ALZ-Management.psm1` | 7 PowerShell functions for ops team |

---

## 🚀 Getting Started

### 1. Deploy Configuration System

```powershell
# Import config
. ./scripts/alz-config.ps1

# Get supported regions
[ALZConfig]::GetSupportedRegions()

# Calculate cost estimate
[ALZConfig]::CalculateMonthlyEstimate("eastus", "westus", "hipaa", @("hub-network", "spoke-network"))
```

### 2. Pre-Deployment Validation

```powershell
.\scripts\Validate-ALZDeployment.ps1 `
    -TerraformPath "./terraform/live/myorg" `
    -SubscriptionId "xxxx-xxxx" `
    -GitHubRepo "myorg/alz-deployment" `
    -OutputFormat json
```

**Expected Output:**
- ✅ Terraform syntax validation
- ✅ Azure authentication & quotas
- ✅ OIDC federation setup
- ✅ GitHub secrets configured
- ✅ Pre-flight report (JSON/text)

### 3. Post-Deployment Cost Verification

```powershell
.\scripts\Verify-CostAccuracy.ps1 `
    -SubscriptionId "xxxx-xxxx" `
    -EstimatedMonthlyCost 5000 `
    -Month "2026-06"
```

**Expected Output:**
- Actual costs from Cost Management API
- Component-by-component breakdown
- Variance analysis (±5% target)
- Optimization recommendations
- JSON report

### 4. Deploy Dashboards

Import workbook templates into Azure:

```bash
# Health Dashboard
az monitor workbooks create \
    --resource-group myalz-rg \
    --name "ALZ-Health" \
    --template-file dashboards/Health-Dashboard-Template.json

# Cost Dashboard
az monitor workbooks create \
    --resource-group myalz-rg \
    --name "ALZ-Cost" \
    --template-file dashboards/Cost-Dashboard-Template.json

# Compliance Dashboard
az monitor workbooks create \
    --resource-group myalz-rg \
    --name "ALZ-Compliance" \
    --template-file dashboards/Compliance-Dashboard-Template.json
```

### 5. Deploy Runbooks

Create in Azure Automation Account:

```powershell
# Health Check (hourly)
New-AzAutomationRunbook -Path runbooks/Health-Check.ps1 `
    -ResourceGroupName "myalz-rg" `
    -AutomationAccountName "myalz-aa" `
    -Type PowerShell

# Cost Optimization (daily)
New-AzAutomationRunbook -Path runbooks/Cost-Optimization.ps1 `
    -ResourceGroupName "myalz-rg" `
    -AutomationAccountName "myalz-aa" `
    -Type PowerShell

# Compliance Remediation (event-triggered)
New-AzAutomationRunbook -Path runbooks/Compliance-Remediation.ps1 `
    -ResourceGroupName "myalz-rg" `
    -AutomationAccountName "myalz-aa" `
    -Type PowerShell
```

### 6. Deploy API Functions

```bash
# Deploy REST API
func azure functionapp publish alz-api-function

# Deploy Slack Notifications
func azure functionapp publish alz-slack-function
```

### 7. Import CLI Module

```powershell
Import-Module ./cli/ALZ-Management.psm1

# List all deployments
Get-ALZDeployments

# Get costs for specific deployment
Get-ALZCost -DeploymentId "alz-deploy-001" -Month "2026-06"

# Check compliance status
Get-ALZCompliance -DeploymentId "alz-deploy-001" -Variant "hipaa"

# Trigger compliance audit
Trigger-ALZAudit -Variant "fedramp"
```

---

## 📊 Daily Operations Workflow

### Morning Standup
```powershell
# Check overall status
Get-ALZStatus

# Review cost trends
Get-ALZCost -DeploymentId "alz-deploy-001"

# Check compliance status
Get-ALZCompliance -DeploymentId "alz-deploy-001" -Variant "hipaa"
```

### Weekly Reviews
```powershell
# Export comprehensive cost report
Export-ALZCostReport -OutputPath "./reports/weekly-costs.csv" -Month "2026-06"

# Run full compliance audit
Trigger-ALZAudit -Variant "fedramp"

# Bulk compliance check across all deployments
.\scripts\Invoke-BulkOperations.ps1 `
    -Operation "run-compliance-audit" `
    -InputFile "./deployments.csv"
```

### Monthly Optimization
```powershell
# Export all costs with variance analysis
.\scripts\Verify-CostAccuracy.ps1 `
    -SubscriptionId "xxxx-xxxx" `
    -EstimatedMonthlyCost 5000 `
    -Month (Get-Date -Format "yyyy-MM")

# Bulk cost export
.\scripts\Invoke-BulkOperations.ps1 `
    -Operation "export-costs" `
    -InputFile "./deployments.csv"

# Review optimization recommendations in Cost Dashboard
```

---

## 🔌 Slack Integration Setup

### 1. Create Slack Webhook

In Slack:
1. Go to Workspace Settings → Manage Apps
2. Search for "Incoming Webhooks"
3. Create New Webhook → Select channel
4. Copy Webhook URL

### 2. Configure Azure Function

```bash
# Set Slack webhook as function environment variable
az functionapp config appsettings set \
    --name alz-slack-function \
    --resource-group myalz-rg \
    --settings SLACK_WEBHOOK_URL="https://hooks.slack.com/..."
```

### 3. Send Test Alert

```powershell
$body = @{
    eventType     = "deployment_completed"
    title         = "ALZ Deployment Complete"
    description   = "Contoso ALZ successfully deployed"
    organization  = "contoso"
    duration      = "18 minutes"
    resourceCount = 45
    severity      = "success"
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://alz-slack-function.azurewebsites.net/api/slack-notification" `
    -Method POST `
    -Body $body `
    -ContentType "application/json"
```

---

## 🛠️ Bulk Operations Examples

### Update Firewall Rules Across All Deployments

```powershell
# Create deployments.csv with headers: DeploymentId,Organization,Region
# Create firewall-rules.json with rules array

.\scripts\Invoke-BulkOperations.ps1 `
    -Operation "update-firewall-rules" `
    -InputFile "./deployments.csv" `
    -FirewallRules "./firewall-rules.json" `
    -OutputPath "./bulk-results"
```

### Run Compliance Audit on All Deployments

```powershell
.\scripts\Invoke-BulkOperations.ps1 `
    -Operation "run-compliance-audit" `
    -InputFile "./deployments.csv" `
    -OutputPath "./bulk-results"
```

### Export Costs for All Deployments

```powershell
.\scripts\Invoke-BulkOperations.ps1 `
    -Operation "export-costs" `
    -InputFile "./deployments.csv" `
    -OutputPath "./bulk-results"
```

---

## 📈 Monitoring & Alerting

### Health Dashboard Metrics
- **Deployment Status:** Resource provisioning state
- **Compliance:** Policy compliance percentage
- **Network Health:** Firewall throughput, gateway connectivity
- **Alerts:** Recent violations and incidents

### Cost Dashboard Metrics
- **Current Month:** Month-to-date spending
- **Trends:** 90-day cost history
- **Top Services:** Cost breakdown by service
- **Budget Status:** Budget vs actual comparison
- **Optimization:** High-impact recommendations

### Compliance Dashboard Metrics
- **Overall Compliance:** Compliance percentage
- **By Policy:** Violations per policy
- **Trend:** 30-day compliance trend
- **Violations:** Non-compliant resources
- **Remediation:** Auto-remediation success rate

---

## 🔐 API Endpoints

### GET /api/status
Returns operational status and health summary.

```bash
curl https://alz-api.azurewebsites.net/api/status
```

**Response:**
```json
{
  "status": "operational",
  "details": {
    "deployment": "healthy",
    "firewalls": 1,
    "networks": 2,
    "lastHealthCheck": "2026-06-28T10:30:00Z"
  }
}
```

### GET /api/costs?month=2026-06
Returns cost data for specified month.

```bash
curl "https://alz-api.azurewebsites.net/api/costs?month=2026-06"
```

### GET /api/compliance?variant=hipaa
Returns compliance status for specified variant.

```bash
curl "https://alz-api.azurewebsites.net/api/compliance?variant=hipaa"
```

### GET /api/deployments
List all deployments.

```bash
curl https://alz-api.azurewebsites.net/api/deployments
```

### POST /api/audit
Trigger compliance audit.

```bash
curl -X POST https://alz-api.azurewebsites.net/api/audit \
  -H "Content-Type: application/json" \
  -d '{"variant": "fedramp"}'
```

### POST /api/redeploy
Trigger redeployment.

```bash
curl -X POST https://alz-api.azurewebsites.net/api/redeploy \
  -H "Content-Type: application/json" \
  -d '{"deploymentId": "alz-deploy-001"}'
```

---

## 📋 Configuration Reference

### Supported Regions (20+)
```powershell
[ALZConfig]::GetSupportedRegions()
# eastus, westus, westus2, centralus, southcentralus, northcentralus,
# westeurope, northeurope, uksouth, germanywestcentral, francecentral,
# southeastasia, eastasia, japaneast, australiaeast, koreacentral, ...
```

### Compliance Variants
- **baseline:** Standard policies (1.0x cost)
- **pci-dss:** Payment card compliance (1.2x cost)
- **hipaa:** Healthcare compliance (1.5x cost)
- **fedramp:** Government compliance (1.8x cost)

### Firewall Tier Selection
- **Standard:** Baseline protections, lower cost (~$1,500/month)
- **Premium:** Advanced features, TLS inspection (~$4,000/month)

### Cost Accuracy Target
- **Estimated vs Actual:** ±5% variance
- **Grade A+:** ≤5% variance
- **Grade A:** ≤10% variance
- **Grade B-:** >10% (requires review)

---

## 🐛 Troubleshooting

### Validation Script Fails
```powershell
# Check Terraform
terraform version
terraform fmt -check

# Check Azure auth
az login
az account show

# Check GitHub
gh auth status
gh secret list --repo myorg/alz-deployment
```

### Cost Verification Accuracy Issues
```powershell
# Verify Cost Management API access
az costmanagement query --help

# Check resource tagging
az resource list --query "[].tags" --output table

# Run manual cost audit
.\scripts\Verify-CostAccuracy.ps1 -EstimatedMonthlyCost 5000 -ReportPath "./manual-audit.json"
```

### Runbook Failures
```powershell
# Check Automation Account variables
Get-AzAutomationVariable -ResourceGroupName "myalz-rg" -AutomationAccountName "myalz-aa"

# View runbook output
Get-AzAutomationJob -ResourceGroupName "myalz-rg" | Select-Object -Last 5 | Format-List
```

---

## 📞 Support & Next Steps

### Phase 3 Complete
✅ Configuration management  
✅ Validation & verification  
✅ Automated runbooks  
✅ Real-time dashboards  
✅ REST API  
✅ CLI tools  
✅ Bulk operations  
✅ Slack notifications  

### Ready for Production
- Deploy to staging environment (24 hours)
- Validate with 1 pilot customer (1 week)
- General availability rollout (Week 2)

### Future Enhancements (Phase 4)
- Multi-spoke network support
- Advanced policy management
- Cost optimization automation
- Disaster recovery automation
- Integration with additional tools (Teams, PagerDuty, etc.)

---

**Document ID:** ALZ-PHASE3-OPS-20260628  
**Status:** PRODUCTION READY ✅
