# Azure Landing Zone Variable Configuration System
## Implementation Plan & Detailed Recommendations

**Document Version:** 1.0  
**Last Updated:** 2026-06-30  
**Status:** Ready for Implementation  
**Target Completion:** 3-4 weeks

---

## Executive Summary

This document provides a **complete implementation plan** for automating terraform.tfvars generation and creating a presentation-ready static HTML page. The system will:

1. ✅ Guide customers through configuration via **interactive PowerShell script**
2. ✅ Generate **5 layer-specific terraform.tfvars files** (AVM-compliant)
3. ✅ Create **static HTML presentation page** (no server required, fully offline)
4. ✅ Produce audit trail JSON for compliance
5. ✅ Support multi-customer reuse (clone-and-run model)

**Key differentiator:** Single PowerShell script outputs both infrastructure code AND presentation-ready HTML.

---

## Current State Assessment

### ✅ **COMPLETED / EXISTING**

| Component | Status | Location | Notes |
|-----------|--------|----------|-------|
| Bootstrap infrastructure | ✅ Complete | `scripts/000-030-*.ps1` | 3,700+ LOC, handles OIDC/GitHub/Azure setup |
| Frontend UI framework | ✅ Complete | `frontend/index.html` | Azure auth, form structure, cost calculator |
| Frontend styles | ✅ Complete | `frontend/styles.css` | Modern, responsive design |
| Frontend app logic | ✅ Complete | `frontend/app.js` | Form handling, Azure integration |
| Terraform modules | ✅ Complete | `terraform/modules/*` | 8 modules ready (hub, spoke, policy, etc.) |
| Example tfvars files | ✅ Complete | `terraform/live/*/terraform.tfvars.example` | 2 example files, others need generation |
| Documentation structure | ✅ Complete | `docs/`, `README.md` | Comprehensive, migrated to Wiki |
| Bootstrap state tracking | ✅ Complete | `.bootstrap-state.json` | Idempotent execution support |

### ❌ **MISSING / REQUIRED**

| Component | Status | Purpose | Effort |
|-----------|--------|---------|--------|
| PowerShell question engine | ❌ Missing | Interactive questionnaire orchestration | 12h |
| Question definitions (metadata) | ❌ Missing | AVM-compliant variable definitions | 8h |
| tfvars generator | ❌ Missing | Layer-specific Terraform variable output | 10h |
| Configuration schema | ❌ Missing | Validation & JSON structure for config | 4h |
| Static HTML generator | ❌ Missing | Convert config JSON → presentation HTML | 8h |
| Helper/lib functions | ❌ Missing | Validation, CIDR checks, cost calculations | 6h |
| Integration tests | ❌ Missing | End-to-end testing (CLI → tfvars → HTML) | 6h |
| Documentation (customer guide) | ❌ Missing | How-to guide for customers | 4h |
| **TOTAL NEW EFFORT** | - | - | **~58 hours** |

---

## Architecture Overview

### High-Level Flow

```
Customer clones repo
       ↓
./scripts/Configure-LandingZone.ps1
       ↓
┌──────────────────────────────────┐
│ PHASE 1: Organization Basics     │  (2 min)
│ • org_prefix                     │
│ • 6 subscription IDs             │
│ • Primary region                 │
└──────────────────────────────────┘
       ↓
┌──────────────────────────────────┐
│ PHASE 2: Architecture Choices    │  (3 min)
│ • Firewall type                  │
│ • DR enabled (yes/no)            │
│ • Optional features              │
└──────────────────────────────────┘
       ↓
┌──────────────────────────────────┐
│ PHASE 3: Advanced Options        │  (2 min)
│ • Management IP ranges           │
│ • Tagging & compliance           │
│ • Optional modules               │
└──────────────────────────────────┘
       ↓
   Validation
       ↓
  Generate:
  ├─ terraform/live/*/terraform.tfvars  (5 files)
  ├─ .configuration/alz-config.json      (source of truth)
  ├─ .configuration/presentation.html    (static page)
  ├─ .configuration/cost-estimate.txt    (budget summary)
  └─ .configuration/audit-log.json       (compliance trail)
       ↓
   Deploy!
```

### Directory Structure (Post-Implementation)

```
HCW-Demo-LZDeployment/
├── scripts/
│   ├── 000-030-*.ps1                    (existing bootstrap)
│   ├── 040-CONFIGURE-LANDING-ZONE.ps1   (NEW - main entry point)
│   ├── 050-GENERATE-TFVARS.ps1          (NEW - output generation)
│   └── lib/
│       ├── ALZ-QuestionDefinitions.ps1  (NEW - variable metadata)
│       ├── ALZ-Validation.ps1           (NEW - input validation)
│       ├── ALZ-Generator.ps1            (NEW - tfvars output)
│       └── ALZ-Helpers.ps1              (NEW - utilities)
│
├── frontend/
│   ├── index.html                       (existing)
│   ├── app.js                           (existing)
│   ├── styles.css                       (existing)
│   └── presentation-generator.html      (NEW - static template)
│
├── terraform/
│   ├── live/
│   │   ├── global/
│   │   │   └── terraform.tfvars         (GENERATED)
│   │   ├── platform-connectivity/
│   │   │   └── terraform.tfvars         (GENERATED)
│   │   ├── platform-management/
│   │   │   └── terraform.tfvars         (GENERATED)
│   │   ├── workloads-prod/
│   │   │   └── terraform.tfvars         (GENERATED)
│   │   └── sandbox/
│   │       └── terraform.tfvars         (GENERATED)
│   │
│   └── .configuration/                  (NEW)
│       ├── alz-config.json              (GENERATED - single source of truth)
│       ├── alz-config.schema.json       (NEW - validation schema)
│       ├── presentation.html            (GENERATED - static page)
│       ├── cost-estimate.txt            (GENERATED)
│       └── audit-log.json               (GENERATED - compliance trail)
│
├── docs/
│   ├── CONFIGURATION-GUIDE.md           (NEW - customer reference)
│   └── ... (existing)
│
└── IMPLEMENTATION-PLAN.md               (NEW - this file)
```

---

## Detailed Component Specifications

### Component 1: PowerShell Question Engine
**File:** `scripts/040-CONFIGURE-LANDING-ZONE.ps1`  
**Effort:** 12 hours  
**Status:** ❌ Not Started

#### Purpose
Main entry point script that orchestrates the 3-phase questionnaire flow.

#### Responsibilities
- Validate prerequisites (PowerShell 7+, Terraform, Azure CLI)
- Load question definitions from `ALZ-QuestionDefinitions.ps1`
- Display welcome banner with topology diagram (ASCII)
- Execute Phase 1-3 question prompts
- Collect & validate user responses
- Calculate cost estimates
- Generate summary & confirmation
- Call `ALZ-Generator.ps1` to create terraform.tfvars
- Call static HTML generator for presentation page
- Display next steps

#### Key Features
```powershell
# Entry point with flags
./scripts/040-CONFIGURE-LANDING-ZONE.ps1 `
  -InteractiveMode                      # Default: interactive CLI
  -SkipValidation                       # Skip pre-flight checks
  -ProfileTemplate "Production"         # Use starter profile (Quick/Prod/Enterprise)
  -ConfigFile "previous-config.json"    # Re-use previous configuration
  -NonInteractive                       # For CI/CD (requires config file)

# Output artifacts
Generates:
  - alz-config.json (single source of truth)
  - All terraform.tfvars files (5 layers)
  - presentation.html (static page)
  - cost-estimate.txt
  - audit-log.json
```

#### Implementation Phases

**Phase 1: Welcome & Prerequisites (5 min)**
```
╔════════════════════════════════════════════════════════════════╗
║   Azure Landing Zone Configuration Wizard                      ║
║   Following CAF & Azure Verified Modules Standards             ║
╚════════════════════════════════════════════════════════════════╝

Checking prerequisites...
✓ PowerShell 7.2.9
✓ Terraform 1.9.3
✓ Git 2.43.0
⚠ Azure CLI not found (optional for validation)

Architecture Overview:
                Root MG
               /        \
          Platform      LZ
          /   |   \      |
      Mgmt Conn Ident Prod/NonProd
```

**Phase 2: Question Flow (7-10 min total)**
- Phase 1 questions (2 min): org_prefix, subscriptions, primary region
- Phase 2 questions (3 min): firewall, DR, features
- Phase 3 questions (2 min): access control, tagging, compliance

**Phase 3: Summary & Confirmation (2 min)**
- Display configuration summary
- Show cost estimate breakdown
- Prompt for confirmation
- Execute generation on success

#### Validation Points
- org_prefix: regex `^[a-z]{2,4}$`
- Subscription IDs: UUID format + existence check (via Azure CLI if available)
- Regions: check against valid Azure regions
- CIDR blocks: non-overlap validation
- Firewall type: enum check (azfw/palo/fortinet)

---

### Component 2: Question Definitions (Metadata)
**File:** `scripts/lib/ALZ-QuestionDefinitions.ps1`  
**Effort:** 8 hours  
**Status:** ❌ Not Started

#### Purpose
Centralized repository of all configuration questions, defaults, validation rules, and guidance. Enables reuse across PowerShell, HTML forms, and future tooling.

#### Structure
```powershell
<#
Each question has:
  - id: unique identifier
  - category: Tier 1-5 category
  - type: string/number/bool/enum
  - prompt: user-facing question
  - help: extended explanation
  - default: sensible default value
  - validation: regex pattern or script block
  - linked_docs: Microsoft Learn URLs
  - cost_impact: monthly cost delta
  - examples: concrete input examples
  - avm_compliant: AVM requirement references
#>

$ALZQuestions = @{
  'org_prefix' = @{
    id = 'org_prefix'
    category = 'Tier1'
    type = 'string'
    prompt = 'Organization prefix for resource naming (2-4 lowercase letters)?'
    help = 'Used in all Azure resource names. Example: contoso → rg-contoso-scus-prod-01'
    default = ''
    validation = { param([string]$v) $v -match '^[a-z]{2,4}$' }
    linked_docs = @(
      'https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming',
      'https://azure.github.io/Azure-Verified-Modules/'
    )
    cost_impact = 0
    examples = @('contoso', 'acme', 'fab')
    avm_compliant = $true
  }
  
  'firewall_type' = @{
    id = 'firewall_type'
    category = 'Tier2'
    type = 'enum'
    prompt = 'Firewall type?'
    help = @"
Choose network security architecture:

[1] Azure Firewall (azfw) - RECOMMENDED
    • Fully managed PaaS service
    • Standard: Basic threat intel (~$1.5K/mo)
    • Premium: IDPS + SSL inspection (~$2.5K/mo)
    • Best for: Most workloads

[2] Palo Alto Networks (palo) - Advanced
    • Enterprise firewall platform
    • Requires marketplace image deployment
    • IDPS, advanced threat prevention
    • Cost: ~$3-5K/mo depending on SKU

[3] Fortinet FortiGate (fortinet) - Alternative
    • Next-gen firewall
    • Unified threat management
    • Cost: ~$2-3K/mo
"@
    default = 'azfw'
    validation = { param([string]$v) $v -in @('azfw', 'palo', 'fortinet') }
    linked_docs = @(
      'https://learn.microsoft.com/azure/firewall/overview',
      'https://learn.microsoft.com/azure/firewall/firewall-faq'
    )
    cost_impact = 1500  # azfw Standard baseline
    examples = @('azfw', 'palo', 'fortinet')
    avm_compliant = $true
  }
  
  # ... 40+ more questions following this pattern
}
```

#### Questions by Tier

**Tier 1: Essential (Blocking)**
- org_prefix
- management_subscription_id
- connectivity_subscription_id
- workload_prod_subscription_id
- workload_nonprod_subscription_id (optional, warns if skipped)
- sandbox_subscription_id
- primary_region
- firewall_type

**Tier 2: Recommended**
- dr_region (optional, asks if customer wants DR)
- azfw_tier (if firewall_type == azfw)
- primary_hub_address_space
- dr_hub_address_space
- primary_spoke_address_space
- sandbox_address_space

**Tier 3: Optional Features**
- deploy_bastion (bool, cost estimate: +$600/mo)
- deploy_private_dns (bool, cost estimate: +$5/mo)
- deploy_ddos_protection (bool, cost estimate: +$2500/mo)

**Tier 4: Advanced (Hidden by default)**
- management_ip_ranges
- custom_tags (owner, application, environment, cost_center)
- availability_zones
- policy_enforcement_mode (audit vs deny)

**Tier 5: Optional Modules**
- deploy_cmk (bool, cost: +$250/mo)
- deploy_sentinel (bool, cost: +$300/mo)
- deploy_defender (bool, cost: +$1500-3000/mo)

#### Starter Profiles
Three pre-defined profiles that auto-fill sensible defaults:

```powershell
$StarterProfiles = @{
  'Quick Start' = @{
    description = 'Small org, single region, minimal cost'
    firewall_type = 'azfw'
    azfw_tier = 'Standard'
    dr_enabled = $false
    deploy_bastion = $true
    deploy_private_dns = $false
    deploy_defender = $false
    cost_estimate = '$1,500/month'
  }
  
  'Production' = @{
    description = 'Medium org, dual-region, enterprise features'
    firewall_type = 'azfw'
    azfw_tier = 'Premium'
    dr_enabled = $true
    deploy_bastion = $true
    deploy_private_dns = $true
    deploy_defender = $false  # Optional, costs extra
    cost_estimate = '$4,635/month'
  }
  
  'Enterprise' = @{
    description = 'Large org, all security & compliance features'
    firewall_type = 'palo'
    dr_enabled = $true
    deploy_bastion = $true
    deploy_private_dns = $true
    deploy_defender = $true
    deploy_cmk = $true
    deploy_sentinel = $true
    cost_estimate = '$8,500+/month'
  }
}
```

---

### Component 3: Terraform Variable Generator
**File:** `scripts/lib/ALZ-Generator.ps1`  
**Effort:** 10 hours  
**Status:** ❌ Not Started

#### Purpose
Convert `alz-config.json` → properly formatted `terraform.tfvars` for each of the 5 deployment layers.

#### Key Responsibilities

1. **Layer Distribution**
   - Global layer: org_prefix, all subscription IDs, allowed_locations, default_tags
   - Platform-Connectivity: regions, firewall config, hub CIDRs, AZs
   - Platform-Management: regions, backup settings, tags
   - Workloads-Prod: regions, spoke CIDRs, tags
   - Sandbox: expiry policy, tags, isolation settings

2. **AVM Compliance**
   - Output snake_case variable names
   - Include rich descriptions (TFNFR17 requirement)
   - Use precise types (no `any`)
   - Add validation rules for enum/pattern types

3. **Variable Name Mapping**
   ```
   alz-config.json field → terraform.tfvars variable name
   
   config.org_prefix → org_prefix
   config.subscriptions.management → management_subscription_id
   config.network.firewall.type → firewall_type
   config.features.deploy_bastion → deploy_bastion_placeholder
   ```

#### Output Format

Each `.tfvars` file follows Terraform conventions:

```hcl
# terraform/live/global/terraform.tfvars

org_prefix = "contoso"

# Subscription IDs
management_subscription_id       = "12345678-1234-1234-1234-123456789012"
identity_subscription_id         = "87654321-4321-4321-4321-210987654321"
connectivity_subscription_id     = "11111111-2222-3333-4444-555555555555"
workload_prod_subscription_id    = "99999999-8888-7777-6666-555555555544"
workload_nonprod_subscription_id = "44444444-5555-6666-7777-888888888899"
sandbox_subscription_id          = "33333333-2222-1111-0000-999999999999"

# Allowed locations
allowed_locations = ["southcentralus", "northcentralus"]

# Default tags (mandatory on all resources)
default_tags = {
  owner       = "Platform Team"
  application = "Landing Zone Platform"
  environment = "prod"
  cost_center = "IT-Platform"
  managed_by  = "Terraform"
}
```

#### Layer-Specific Generation Logic

```powershell
function New-TerraformVars {
  param(
    [hashtable]$Config,           # from alz-config.json
    [ValidateSet('global', 'platform-connectivity', 'platform-management', 'workloads-prod', 'sandbox')]
    [string]$Layer,
    [string]$OutputPath
  )
  
  switch ($Layer) {
    'global' {
      # Output subscription IDs, org_prefix, allowed_locations, tags
    }
    'platform-connectivity' {
      # Output regions, firewall config, hub address spaces, AZs
    }
    'platform-management' {
      # Output regions, backup settings, monitoring config
    }
    'workloads-prod' {
      # Output regions, spoke CIDR blocks
    }
    'sandbox' {
      # Output sandbox-specific settings (expiry, isolation)
    }
  }
}
```

---

### Component 4: Validation & Helper Functions
**File:** `scripts/lib/ALZ-Validation.ps1` and `scripts/lib/ALZ-Helpers.ps1`  
**Effort:** 6 hours  
**Status:** ❌ Not Started

#### Validation Functions

```powershell
function Test-OrgPrefix {
  param([string]$Prefix)
  # Validate 2-4 lowercase letters
  # Check uniqueness across Azure? (optional)
}

function Test-SubscriptionId {
  param([string]$SubId)
  # Validate UUID format
  # Check if subscription exists? (requires Azure CLI + auth)
}

function Test-CIDRBlock {
  param([string]$CIDR)
  # Validate CIDR notation (e.g., 10.0.0.0/16)
  # Return parsed network info
}

function Test-CIDRNoOverlap {
  param([string[]]$CIDRBlocks)
  # Check all CIDR blocks are non-overlapping
  # Return conflicts if any
}

function Test-AzureRegion {
  param([string]$Region)
  # Validate against known Azure regions
  # Check if region supports required resources (AZs, firewall SKUs)
}

function Test-FirewallType {
  param([string]$Type)
  # Validate enum: azfw | palo | fortinet
}
```

#### Helper Functions

```powershell
function Get-CostEstimate {
  param([hashtable]$Config)
  # Calculate monthly cost based on selections
  # Return breakdown by service
}

function New-ConfigurationAudit {
  param([hashtable]$Config)
  # Create JSON audit trail
  # Log: who, when, what config selected
}

function ConvertTo-HCLObject {
  param($PSObject)
  # Convert PowerShell object → HCL syntax for tfvars
  # Handle nested objects, arrays, strings properly
}
```

---

### Component 5: Configuration Schema
**File:** `terraform/.configuration/alz-config.schema.json`  
**Effort:** 4 hours  
**Status:** ❌ Not Started

#### Purpose
JSON Schema (IETF) that validates generated `alz-config.json` files. Reusable for:
- PowerShell validation
- HTML form validation
- GitHub Actions validation
- Future tooling integration

#### Structure
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Azure Landing Zone Configuration",
  "description": "Valid configuration for HCW Azure Landing Zone deployment",
  
  "type": "object",
  "required": ["metadata", "organization", "network"],
  
  "properties": {
    "metadata": {
      "type": "object",
      "required": ["generated_at", "customer_org"],
      "properties": {
        "generated_at": { "type": "string", "format": "date-time" },
        "customer_org": { "type": "string", "pattern": "^[a-z]{2,4}$" },
        "configuration_id": { "type": "string" }
      }
    },
    
    "organization": {
      "type": "object",
      "required": ["org_prefix"],
      "properties": {
        "org_prefix": { "type": "string", "pattern": "^[a-z]{2,4}$" },
        "owner_email": { "type": "string", "format": "email" },
        "cost_center": { "type": "string" }
      }
    },
    
    "subscriptions": {
      "type": "object",
      "required": ["management", "connectivity"],
      "properties": {
        "management": { "type": "string", "pattern": "^[0-9a-f-]{36}$" },
        "connectivity": { "type": "string", "pattern": "^[0-9a-f-]{36}$" }
        # ... etc
      }
    },
    
    "network": {
      "type": "object",
      "required": ["primary_region"],
      "properties": {
        "primary_region": { "type": "string" },
        "firewall": {
          "type": "object",
          "properties": {
            "type": { "enum": ["azfw", "palo", "fortinet"] },
            "tier": { "enum": ["Standard", "Premium"] }
          }
        }
      }
    }
    
    # ... more properties
  }
}
```

---

### Component 6: Static HTML Presentation Generator
**File:** `scripts/lib/ALZ-PresentationGenerator.ps1`  
**Effort:** 8 hours  
**Status:** ❌ Not Started

#### Purpose
Convert `alz-config.json` → self-contained, presentation-ready static HTML page. No server required, fully offline, can be emailed or shared.

#### Features
- **Self-contained**: Single HTML file with embedded CSS/JavaScript
- **Read-only**: Cannot be edited (presentation-only)
- **Professional**: Executive summary, cost breakdown, architecture diagram
- **Portable**: No external dependencies, works offline
- **Print-friendly**: Can be printed to PDF
- **Shareable**: Email-safe, no sensitive data exposure

#### Output Structure

```html
<!DOCTYPE html>
<html>
<head>
  <title>ALZ Configuration - Contoso Production</title>
  <style>/* Embedded CSS */</style>
</head>
<body>
  <header>
    <h1>Azure Landing Zone Configuration</h1>
    <p>Organization: Contoso | Generated: 2026-06-30</p>
  </header>
  
  <section id="executive-summary">
    <h2>Executive Summary</h2>
    <ul>
      <li>Deployment Profile: Production (Dual-Region)</li>
      <li>Estimated Monthly Cost: $4,635</li>
      <li>Regions: South Central US + North Central US</li>
      <li>Firewall: Azure Firewall Premium</li>
    </ul>
  </section>
  
  <section id="architecture">
    <h2>Architecture Overview</h2>
    <!-- SVG diagram of landing zone topology -->
  </section>
  
  <section id="cost-breakdown">
    <h2>Cost Estimate</h2>
    <table>
      <tr><td>Azure Firewall (x2)</td><td>$3,000/mo</td></tr>
      <tr><td>Hub VNets</td><td>$500/mo</td></tr>
      <!-- ... more cost items -->
    </table>
  </section>
  
  <section id="configuration-details">
    <h2>Configuration Details</h2>
    <dl>
      <dt>Organization Prefix</dt><dd>contoso</dd>
      <dt>Management Subscription</dt><dd>12345678-...</dd>
      <!-- ... more details -->
    </dl>
  </section>
  
  <section id="next-steps">
    <h2>Next Steps</h2>
    <ol>
      <li>Review this configuration</li>
      <li>Approve budget allocation ($4,635/month)</li>
      <li>Run terraform apply</li>
    </ol>
  </section>
  
  <script>/* Embedded JavaScript */</script>
</body>
</html>
```

#### Generation Algorithm

```powershell
function New-PresentationHTML {
  param(
    [hashtable]$Config,        # alz-config.json
    [string]$OutputPath
  )
  
  $html = @"
<!DOCTYPE html>
<html>
<head>
  <title>ALZ Configuration - $($Config.organization.org_prefix)</title>
  <style>
    body { font-family: 'Segoe UI', sans-serif; margin: 40px; }
    .summary { background: #f0f8ff; padding: 20px; border-radius: 8px; }
    .cost-warning { background: #fff3cd; padding: 10px; border-left: 4px solid #ff9800; }
  </style>
</head>
<body>
  <h1>Azure Landing Zone Configuration</h1>
  <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
  
  <div class="summary">
    <h2>Executive Summary</h2>
    <ul>
      <li>Organization: $($Config.organization.org_prefix.ToUpper())</li>
      <li>Profile: $($Config.scenario)</li>
      <li>Firewall: $($Config.network.firewall.type)</li>
      <li>DR Enabled: $($Config.network.dr_enabled)</li>
      <li><strong>Estimated Monthly Cost: $($Config.cost_estimate)</strong></li>
    </ul>
  </div>
  
  <section id="architecture">
    <h2>Architecture</h2>
    $(Get-ArchitectureDiagram $Config)
  </section>
  
  <!-- ... more sections ... -->
</body>
</html>
"@
  
  $html | Out-File -Path $OutputPath -Encoding UTF8
}
```

---

### Component 7: Configuration Schema Validation
**File:** `terraform/.configuration/alz-config.schema.json`  
**Effort:** 4 hours  
**Status:** ❌ Not Started

Schema validates:
- All required fields present
- UUID format for subscription IDs
- Regex patterns for org_prefix, regions
- Enum values for firewall type, compliance framework
- CIDR block validity and non-overlap
- Cost estimates within reasonable bounds

---

## Implementation Roadmap

### Phase 1: Core PowerShell (Weeks 1-2, 20 hours)

**Week 1:**

| Day | Task | Effort | Owner | Notes |
|-----|------|--------|-------|-------|
| Mon | Create ALZ-QuestionDefinitions.ps1 | 8h | Dev | Metadata-driven questions, AVM-compliant |
| Tue-Wed | Create ALZ-Validation.ps1 | 4h | Dev | CIDR, UUID, pattern validation functions |
| Wed-Thu | Create ALZ-Generator.ps1 | 5h | Dev | tfvars generation per layer |
| Thu-Fri | Create 040-CONFIGURE-LandingZone.ps1 skeleton | 3h | Dev | Question flow, Phase 1-3 orchestration |

**Week 2:**

| Day | Task | Effort | Owner | Notes |
|-----|------|--------|-------|-------|
| Mon-Tue | Complete 040-CONFIGURE-LandingZone.ps1 | 5h | Dev | Full questionnaire, cost calc, confirmation |
| Wed | Test end-to-end (CLI → tfvars) | 3h | QA | Use sample profiles, verify output |
| Thu | Create ALZ-Helpers.ps1 (utilities) | 3h | Dev | Cost estimation, audit logging, HCL conversion |
| Fri | Documentation: CONFIGURATION-GUIDE.md | 2h | Doc | Customer quick start guide |

**Deliverable:** Functional PowerShell CLI that generates terraform.tfvars for all 5 layers

---

### Phase 2: Static HTML Generator (Week 3, 12 hours)

| Day | Task | Effort | Owner | Notes |
|-----|------|--------|-------|-------|
| Mon-Tue | Create ALZ-PresentationGenerator.ps1 | 6h | Dev | Convert JSON → HTML, embed CSS/JS |
| Wed | Design presentation template | 3h | Dev | Executive summary, cost, architecture diagram |
| Thu | Create alz-config.schema.json | 3h | Dev | JSON Schema for validation |
| Fri | Test HTML generation + styling | 1h | QA | Verify offline functionality, print-to-PDF |

**Deliverable:** Static HTML presentation page + JSON schema validation

---

### Phase 3: Integration & Testing (Week 4, 10 hours)

| Day | Task | Effort | Owner | Notes |
|-----|------|--------|-------|-------|
| Mon-Tue | End-to-end testing | 4h | QA | CLI → tfvars → HTML, all 3 profiles |
| Wed | Create test scenarios | 2h | QA | Quick Start, Production, Enterprise profiles |
| Thu | Integrate with existing bootstrap | 2h | Dev | Ensure compatibility with 000-030 scripts |
| Fri | Customer documentation + examples | 2h | Doc | How-to guide, troubleshooting |

**Deliverable:** Fully integrated, tested system ready for customer use

---

## Phase 1 Implementation Details

### 1.1: ALZ-QuestionDefinitions.ps1 (8 hours)

**Scope:** Define all 40+ configuration questions following AVM standards

**Outline:**
```powershell
# Define tier-by-tier questions
$Tier1Questions = @{
  org_prefix = @{...}
  management_subscription_id = @{...}
  # ... 6 more questions
}

$Tier2Questions = @{...}
$Tier3Questions = @{...}
$Tier4Questions = @{...}
$Tier5Questions = @{...}

# Define starter profiles
$StarterProfiles = @{
  'Quick Start' = @{...}
  'Production' = @{...}
  'Enterprise' = @{...}
}

# Export functions
function Get-Question { ... }
function Get-Profile { ... }
function Get-AllQuestions { ... }
```

**Testing:**
- Verify all questions have required fields
- Verify AVM compliance fields
- Verify cost estimates reasonable

---

### 1.2: ALZ-Validation.ps1 (4 hours)

**Scope:** Input validation for all question types

**Functions:**
- `Test-OrgPrefix` — regex `^[a-z]{2,4}$`
- `Test-SubscriptionId` — UUID format, optionally check existence
- `Test-CIDRBlock` — valid CIDR notation
- `Test-CIDRNoOverlap` — all blocks non-overlapping
- `Test-AzureRegion` — valid Azure region, AZ support
- `Test-FirewallType` — enum validation
- `Test-Tags` — no empty values

**Testing:**
- Valid inputs pass
- Invalid inputs fail with helpful error
- Overlap detection works (10.0.0.0/16 + 10.0.0.0/17 conflict)

---

### 1.3: ALZ-Generator.ps1 (5 hours)

**Scope:** Convert `alz-config.json` → 5 layer-specific terraform.tfvars

**Functions:**
- `New-GlobalLayerVars` — org_prefix, all subscriptions, tags
- `New-ConnectivityLayerVars` — regions, firewall, hub CIDRs
- `New-ManagementLayerVars` — regions, backup settings
- `New-WorkloadsLayerVars` — regions, spoke CIDRs
- `New-SandboxLayerVars` — expiry policy, isolation tags

**Testing:**
- Output is valid HCL syntax
- Variables match layer requirements
- Cost estimates propagated correctly

---

### 1.4: 040-CONFIGURE-LandingZone.ps1 (8 hours)

**Scope:** Main orchestration script

**Flow:**
1. Welcome banner + ASCII diagram (1 min)
2. Load question definitions (ALZ-QuestionDefinitions.ps1)
3. Offer starter profiles or custom (30 sec)
4. Phase 1: Tier 1 questions (2 min)
5. Phase 2: Tier 2-3 questions (3 min)
6. Phase 3: Tier 4-5 questions (2 min, optional)
7. Validation & cost estimate (1 min)
8. Confirmation prompt
9. Call ALZ-Generator.ps1 to create terraform.tfvars
10. Display next steps

**Testing:**
- All 3 profiles generate valid output
- Questions validate inputs correctly
- terraform.tfvars files created in correct locations
- Cost estimate calculations accurate

---

## Completed Deliverable Checklist

### Phase 1: Complete

- [ ] ALZ-QuestionDefinitions.ps1 created and tested
- [ ] ALZ-Validation.ps1 created and tested
- [ ] ALZ-Helpers.ps1 created (cost calc, audit, HCL conversion)
- [ ] ALZ-Generator.ps1 created and tested
- [ ] 040-CONFIGURE-LandingZone.ps1 orchestration script complete
- [ ] CONFIGURATION-GUIDE.md documentation written
- [ ] End-to-end test passed (all 3 profiles)
- [ ] terraform.tfvars files verify with `terraform validate`

### Phase 2: Complete

- [ ] ALZ-PresentationGenerator.ps1 created
- [ ] alz-config.schema.json created
- [ ] presentation.html template designed and tested
- [ ] HTML generation tested (offline functionality)
- [ ] Print-to-PDF verified

### Phase 3: Complete

- [ ] Integrated with existing bootstrap scripts (000-030)
- [ ] Full end-to-end test: CLI → tfvars → HTML
- [ ] Test all 3 starter profiles
- [ ] Test custom configuration override
- [ ] Customer documentation complete
- [ ] Troubleshooting guide created
- [ ] Example configurations documented

### Documentation

- [ ] IMPLEMENTATION-PLAN.md (this file) completed
- [ ] CONFIGURATION-GUIDE.md for customers
- [ ] Inline code comments & docstrings
- [ ] Example alz-config.json files (3 profiles)
- [ ] README update explaining new Configure script

---

## Success Criteria

### Functional Requirements

✅ **CLI Questionnaire**
- [ ] 3-phase interactive flow completes in <10 minutes
- [ ] All user inputs validated before proceeding
- [ ] Cost estimate shown before confirmation
- [ ] Supports 3 starter profiles (Quick/Prod/Enterprise)
- [ ] Can re-run to update configuration

✅ **Terraform Variable Generation**
- [ ] All 5 layers get proper terraform.tfvars files
- [ ] Variables are AVM-compliant (snake_case, precise types)
- [ ] `terraform validate` passes on all generated files
- [ ] Correct variable distribution per layer

✅ **Static HTML Presentation**
- [ ] Single self-contained HTML file (no external dependencies)
- [ ] Fully functional offline (file:// protocol)
- [ ] Professional appearance (executive summary, cost, diagram)
- [ ] Print-friendly, can save to PDF
- [ ] Shareable via email without security concerns

✅ **Multi-Customer Reuse**
- [ ] Script works in customer-cloned repos
- [ ] Single entry point: `./scripts/040-CONFIGURE-LandingZone.ps1`
- [ ] Configuration saved as JSON (version-controllable)
- [ ] Can re-run to regenerate terraform.tfvars

✅ **Audit & Compliance**
- [ ] Configuration decisions logged to JSON
- [ ] Timestamp and user tracking in audit trail
- [ ] alz-config.schema.json validates generated configs
- [ ] Cost estimates tracked for approval workflows

### Quality Requirements

✅ **Code Quality**
- [ ] All functions have proper error handling
- [ ] Validation messages are helpful (not cryptic)
- [ ] Code follows PowerShell best practices
- [ ] Docstrings on all public functions

✅ **Documentation**
- [ ] Customer can complete setup with no assistance
- [ ] Troubleshooting guide covers common issues
- [ ] All variables explained with examples
- [ ] AVM compliance documented

✅ **Testing**
- [ ] 3 full end-to-end runs (one per profile)
- [ ] All validation rules tested (pass + fail cases)
- [ ] Edge cases handled (2-char org prefix, max subscriptions)
- [ ] Cross-platform tested (Windows PowerShell + pwsh)

---

## Risk Assessment & Mitigation

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| Customer skips required questions | Medium | High | Make Tier 1 blocking, warn on Tier 2 skip |
| Invalid CIDR blocks overlap | Low | High | Implement CIDR overlap detection in validation |
| Cost estimates inaccurate | Medium | Medium | Document assumptions, link to Azure pricing |
| HTML presentation breaks offline | Low | High | Test with file:// protocol, embed all assets |
| PowerShell version incompatibility | Low | Medium | Require PS 7+, document version requirements |
| Azure CLI not available | Medium | Low | Make optional (validation becomes best-effort) |

---

## Timeline Summary

| Phase | Duration | Start | End | Deliverable |
|-------|----------|-------|-----|-------------|
| **Phase 1** | 2 weeks | Week 1 | Week 2 | Functional PowerShell CLI + tfvars generation |
| **Phase 2** | 1 week | Week 3 | Week 3 | Static HTML presenter + schema validation |
| **Phase 3** | 1 week | Week 4 | Week 4 | Integrated, tested, documented system |
| **Total** | **4 weeks** | **Today** | **+28 days** | **Customer-ready multi-tenant configuration system** |

---

## Customer Workflow (Post-Implementation)

```bash
# 1. Clone the repo
git clone https://github.com/your-org/azure-landing-zone.git
cd azure-landing-zone

# 2. Run configuration wizard
./scripts/040-CONFIGURE-LandingZone.ps1

# 3. Answer guided questions (3 phases, ~7-10 minutes)
# Wizard generates:
#   ✓ terraform/live/*/terraform.tfvars (5 files)
#   ✓ terraform/.configuration/alz-config.json (single source of truth)
#   ✓ terraform/.configuration/presentation.html (executive review)
#   ✓ terraform/.configuration/cost-estimate.txt (budget tracking)
#   ✓ terraform/.configuration/audit-log.json (compliance trail)

# 4. Review presentation (email to stakeholders)
cat terraform/.configuration/presentation.html
# Open in browser: file:///path/to/presentation.html
# Print to PDF for approval process

# 5. Deploy landing zone
cd terraform/live/global
terraform init
terraform apply

# ... (deploy each layer in order)
```

---

## Notes for Implementation Team

### AVM Compliance Points
- TFNFR4: All variables use lower_snake_casing
- TFNFR17: Rich descriptions (user-focused, not developer-focused)
- TFNFR18: Precise types (no `any`)
- TFNFR21: Avoid `nullable = true` unless necessary
- TFNFR25: `required_version` constraint in terraform.tf
- TFNFR26: `required_providers` with version constraints

### PowerShell Best Practices
- Use `#Requires -Version 7.0` for cross-platform support
- Implement proper error handling (`try/catch`)
- Use `Write-Verbose` for debugging info
- Use `Test-*` functions for validation
- Follow Microsoft naming conventions (Verb-Noun)

### JSON Schema Best Practices
- Use `$schema: "http://json-schema.org/draft-07/schema#"`
- Provide `title` and `description` for clarity
- Use `pattern` for regex validation (UUIDs, org_prefix)
- Use `enum` for constrained choices
- Provide `examples` for complex objects

### Testing Strategy
1. **Unit tests:** Each validation function with pass/fail cases
2. **Integration tests:** Full CLI → tfvars → HTML flow
3. **Regression tests:** Against known good configurations
4. **Edge cases:** Min/max values, boundary conditions

---

## Sign-Off & Approval

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Technical Lead | — | — | — |
| Product Owner | — | — | — |
| Security Review | — | — | — |

---

## Appendix: Sample alz-config.json

```json
{
  "metadata": {
    "generated_at": "2026-06-30T13:00:00Z",
    "customer_org": "contoso",
    "configuration_id": "contoso-prod-v1"
  },
  "scenario": "hub-spoke-multi",
  "organization": {
    "org_prefix": "contoso",
    "owner_email": "platform-team@contoso.com",
    "cost_center": "IT-Platform"
  },
  "subscriptions": {
    "management": "12345678-1234-1234-1234-123456789012",
    "identity": "87654321-4321-4321-4321-210987654321",
    "connectivity": "11111111-2222-3333-4444-555555555555",
    "workload_prod": "99999999-8888-7777-6666-555555555544",
    "workload_nonprod": "44444444-5555-6666-7777-888888888899",
    "sandbox": "33333333-2222-1111-0000-999999999999"
  },
  "network": {
    "primary_region": "southcentralus",
    "primary_region_code": "scus",
    "dr_region": "northcentralus",
    "dr_region_code": "ncus",
    "dr_enabled": true,
    "firewall": {
      "type": "azfw",
      "tier": "Premium"
    },
    "address_spaces": {
      "primary_hub": "10.0.0.0/16",
      "dr_hub": "10.10.0.0/16",
      "primary_spoke": "10.1.0.0/16",
      "dr_spoke": "10.11.0.0/16",
      "sandbox": "10.99.0.0/16"
    }
  },
  "features": {
    "deploy_bastion": true,
    "deploy_private_dns": true,
    "deploy_vpn_gateway": false,
    "deploy_ddos_protection": false,
    "deploy_defender": false,
    "deploy_sentinel": false,
    "deploy_cmk": false
  },
  "governance": {
    "mandatory_tags": {
      "owner": "Platform Team",
      "application": "Landing Zone Platform",
      "environment": "prod",
      "cost_center": "IT-Platform",
      "managed_by": "Terraform"
    },
    "sandbox_expiry_days": 30,
    "allowed_locations": ["southcentralus", "northcentralus"]
  },
  "security": {
    "management_ip_ranges": "*",
    "tls_version_minimum": "TLS 1.2"
  },
  "cost_estimate": "$4,635/month"
}
```

---

**Document prepared by:** Claude AI  
**Review Status:** Ready for Technical Review  
**Next Steps:** Schedule kickoff meeting with dev team  
