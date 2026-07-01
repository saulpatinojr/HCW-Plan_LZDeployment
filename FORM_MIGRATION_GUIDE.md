# Form Migration Guide: Current → Official ALZ

**Purpose**: Exact mapping of current form fields to official ALZ form structure  
**For**: Phase 2 implementation - shows what to remove, what to add, what to modify

---

## Current Form Structure (WRONG)

```
❌ Current Frontend Form
├── Organization Prefix (text input) ← KEEP (rename to "Organization ID")
├── Module Selection
│   ├── Hub Network (checkbox, always selected) ← REMOVE (not official)
│   ├── Spoke Networks (checkbox, always selected) ← REMOVE (not official)
│   ├── Policy Baseline (checkbox, always selected) ← REMOVE (not official)
│   ├── Backup & Recovery (checkbox) ← REMOVE (not official)
│   └── Defender for Cloud (checkbox) ← REMOVE (feature toggle instead)
├── Compliance Variant (dropdown)
│   ├── Baseline ← REMOVE (not official, compliance via policies)
│   ├── PCI-DSS ← REMOVE
│   ├── HIPAA ← REMOVE
│   └── FedRAMP ← REMOVE
├── Networking Configuration
│   ├── Networking Model (dropdown)
│   │   ├── Hub-Spoke (Recommended) ← KEEP (map to enable_virtual_wan=false)
│   │   ├── Full Mesh ← REMOVE (not in official ALZ)
│   │   └── Single VNet ← REMOVE (not in official ALZ)
│   └── Connectivity Type (dropdown)
│       ├── VNet Only ← REMOVE (not explicit in ALZ)
│       ├── VPN Gateway ← REMOVE (move to feature toggle)
│       ├── ExpressRoute ← REMOVE (move to feature toggle)
│       └── VPN + ExpressRoute ← REMOVE (move to feature toggle)
├── Azure Policy Enforcement (checkboxes) ← COMPLETELY REPLACE
│   ├── Encryption at Rest ← REMOVE (invent)
│   ├── TLS/HTTPS Enforcement ← REMOVE (invented)
│   ├── MFA Requirement ← REMOVE (invented)
│   ├── Audit & Logging ← REMOVE (invented)
│   └── Resource Locks ← REMOVE (invented)
├── Tagging Strategy (dropdown) ← REMOVE (not a selector)
│   ├── Minimal ← REMOVE
│   ├── Standard ← REMOVE
│   └── Comprehensive ← REMOVE
├── Resource Naming Convention (dropdown) ← REMOVE
│   ├── Microsoft Pattern ← REMOVE
│   ├── Simplified ← REMOVE
│   └── Custom ← REMOVE
├── Primary Region (text input) ← KEEP (rename to "Starter Locations")
├── Secondary Region (text input) ← MOVE (multi-select instead)
└── Cost Estimate Card ← REMOVE (not part of official generator)
```

---

## Official Form Structure (RIGHT)

```
✅ Official ALZ Form

Section 1: Organization & Location
├── Organization Name (text: "Contoso", 3-20 chars) ← NEW
├── Organization ID (text: "contoso", 3-20 chars) ← RENAME from "Organization Prefix"
├── Starter Locations (multi-select)
│   ├── eastus2 (checkbox)
│   ├── westus (checkbox)
│   ├── uksouth (checkbox)
│   └── ... (all Azure regions)
└── Defender Email (email input) ← NEW

Section 2: Network Architecture
├── Network Topology (radio buttons) ← REPLACE dropdown
│   ├── Hub-and-Spoke VNet ← Keep (rename from "Hub-Spoke (Recommended)")
│   └── Virtual WAN ← NEW (was missing)
├── Firewall SKU (radio buttons) ← NEW
│   ├── Standard (default)
│   └── Premium (required for PCI-DSS)
└── Network Feature Toggles:
    ├── Deploy DDoS Protection (toggle, default: true) ← NEW
    ├── Deploy Bastion Host (toggle, default: true) ← NEW
    ├── Deploy Private DNS Zones (toggle, default: true) ← NEW
    └── Deploy Virtual Network Gateways (toggle, default: true) ← NEW

Section 3: Monitoring & Security
├── Deploy Azure Monitoring Agent (toggle, default: true) ← NEW
├── Deploy AMBA Baseline Alerts (toggle, default: true) ← NEW
└── Deploy Defender Plans (toggle, default: true) ← NEW

Section 4: Policy Assignments (MAJOR CHANGE)
├── Grouped by Management Scope:
│   ├── Intermediate Root (10 policies) ← NEW SECTION
│   │   ├── ☑ Deploy Microsoft Defender for Cloud configuration
│   │   ├── ☑ Deploy Microsoft Defender for Endpoint agent
│   │   ├── ☑ Enable allLogs category resource logging to Log Analytics
│   │   ├── ☑ Microsoft Cloud Security Benchmark
│   │   ├── ☑ Configure Advanced Threat Protection - OSS DB
│   │   ├── ☑ Configure Azure Defender - SQL Servers
│   │   ├── ☑ Deploy Activity Log Diagnostics
│   │   ├── ☑ Deny Classic Resources
│   │   ├── ☑ Enforce Azure Compute Security Baseline
│   │   ├── ☑ Unused Resources Cost Avoidance
│   │   └── [Effect selector per policy]
│   │
│   ├── Platform (15 policies) ← NEW SECTION
│   │   ├── ☑ Enforce Key Vault guardrails
│   │   ├── ☑ Enforce backup & recovery policies
│   │   ├── ☑ Subnets should be private
│   │   ├── ☑ Virtual networks protected by DDoS
│   │   ├── ☑ Deploy AMBA alerts for Connectivity
│   │   ├── ☑ Deploy AMBA alerts for Management
│   │   ├── ☑ Deploy AMBA alerts for Identity
│   │   ├── ☑ Deny public IP creation
│   │   ├── ☑ Management ports blocked from internet
│   │   ├── ☑ Subnets require NSG
│   │   ├── ☑ Configure VM backup
│   │   └── ... (5 more)
│   │   └── [Effect selector per policy]
│   │
│   ├── Landing Zones (15 policies) ← NEW SECTION
│   │   ├── ☑ Deny/Deploy TLS enforcement
│   │   ├── ☑ Management ports security
│   │   ├── ☑ Network interface IP forwarding
│   │   ├── ☑ Secure storage transfer (HTTPS)
│   │   ├── ☑ DDoS Protection Standard
│   │   ├── ☑ Deploy AKS Policy add-on
│   │   ├── ☑ Configure SQL auditing
│   │   ├── ☑ Deploy SQL threat detection
│   │   ├── ☑ Deploy SQL TDE
│   │   ├── ☑ Virtual networks DDoS protected
│   │   ├── ☑ AKS no privileged containers
│   │   ├── ☑ AKS no privilege escalation
│   │   ├── ☑ AKS HTTPS only
│   │   ├── ☑ Enforce Key Vault guardrails
│   │   └── [Effect selector per policy]
│   │
│   ├── Landing Zones/Corp (8 policies) ← NEW SECTION
│   │   ├── ☑ Public network access disabled for PaaS
│   │   ├── ☑ Azure PaaS private DNS zones
│   │   ├── ☑ No public IPs on network interfaces
│   │   ├── ☑ Private Link DNS zone audit
│   │   ├── ☑ Deny vWAN/ER/VPN gateway resources
│   │   └── [Effect selector per policy]
│   │
│   └── Specialized (2 policies) ← NEW SECTION
│       ├── ☑ Sandbox guardrails
│       └── ☑ Decommissioned guardrails

Section 5: Management Group Customization
├── Intermediate Root Name (text) ← NEW
├── Platform Name (text) ← NEW
├── Connectivity Name (text) ← NEW
├── Identity Name (text) ← NEW
├── Management Name (text) ← NEW
└── Landing Zones Name (text) ← NEW

Section 6: Resource Naming Configuration
├── Resource Name Prefix (text, default: org ID) ← NEW
├── Environment Suffix (text, default: "prod") ← NEW
└── Instance Counter Start (number, default: 1) ← NEW

Section 7: Network Configuration
├── Hub VNet CIDR (text, e.g., "10.0.0.0/16") ← NEW
├── Spoke 1 CIDR (text, e.g., "10.1.0.0/16") ← NEW
├── Spoke 2 CIDR (text, e.g., "10.2.0.0/16") ← NEW
└── Additional Regions (multi-select) ← MOVED (was secondary region)

Section 8: Tagging Configuration
├── Enable Tag Enforcement (toggle) ← NEW
├── Required Tags (if enforcement enabled):
│   ├── Environment (text) ← NEW
│   ├── Owner (text) ← NEW
│   ├── CostCenter (text) ← NEW
│   ├── Application (text) ← NEW
│   └── DataClassification (dropdown) ← NEW
└── Default Tag Values (key-value pairs) ← NEW

Section 9: Review & Generate
├── Configuration Preview (code block) ← KEEP
├── Download .tfvars button ← KEEP
├── Copy to Clipboard button ← KEEP
└── Back to Form button ← KEEP
```

---

## Field-by-Field Migration

### Organization & Location

| Current | New | Action |
|---------|-----|--------|
| "Organization Prefix" input | "Organization ID" input | ✅ Keep, rename, constraints (3-20 chars, alphanumeric only) |
| None | "Organization Name" input | ✅ Add (display name like "Contoso") |
| "Primary Region" text input | "Starter Locations" multi-select | 🔄 Replace with official list of Azure regions |
| "Secondary Region" text input | Moved to "Additional Regions" | 🔄 Restructure (now multi-select after network config) |
| None | "Defender Email" email input | ✅ Add (required: valid email for MDFC alerts) |

### Network Configuration

| Current | New | Action |
|---------|-----|--------|
| "Networking Model" dropdown (hub-spoke, mesh, single) | "Network Topology" radio buttons (hub-spoke, vwan) | 🔄 Replace: 2 official options only (radio, not dropdown) |
| "Connectivity Type" dropdown (vnet-only, vpn, expressroute, both) | "Deploy Virtual Network Gateways" toggle | ✅ Remove dropdown, add feature toggle |
| None | "Firewall SKU" radio buttons (Standard, Premium) | ✅ Add (maps to firewall_sku variable) |
| None | "DDoS Protection" toggle | ✅ Add (maps to enable_ddos_protection) |
| None | "Bastion Host" toggle | ✅ Add (maps to enable_bastion_deployment) |
| None | "Private DNS Zones" toggle | ✅ Add (maps to enable_private_dns_zones) |

### Policy Configuration

| Current | New | Action |
|---------|-----|--------|
| "Azure Policy Enforcement" checkboxes (encryption, TLS, MFA, audit, locks) | "Policy Assignments" (50+ official checkboxes grouped by scope) | ❌ COMPLETELY REMOVE AND REPLACE |
| None | Effect selector per policy (Audit, Deny, DeployIfNotExists, etc) | ✅ Add (allow effect override per assignment) |
| "Compliance Variant" dropdown (Baseline, PCI-DSS, HIPAA, FedRAMP) | None (removed, compliance via policy effect) | ❌ REMOVE (compliance via policy enforcement mode, not variant) |

### Monitoring & Logging

| Current | New | Action |
|---------|-----|--------|
| None | "Azure Monitoring Agent" toggle | ✅ Add (maps to enable_azure_monitoring_agent) |
| None | "AMBA Baseline Alerts" toggle | ✅ Add (maps to enable_amba_deployment) |
| None | "Defender Plans" toggle | ✅ Add (maps to enable_defender_plans) |

### Customization Options

| Current | New | Action |
|---------|-----|--------|
| None | Management Group Name Overrides (6 fields) | ✅ Add (intermediate root, platform, connectivity, identity, management, landing zones) |
| None | Resource Naming Config (3 fields) | ✅ Add (prefix, environment suffix, instance counter) |
| "Tagging Strategy" dropdown (minimal, standard, comprehensive) | "Tagging Configuration" section with official CAF tags | 🔄 Replace: Add specific tag fields + enforcement toggle |
| "Naming Convention" dropdown (Microsoft, simplified, custom) | Removed (always use CAF standard) | ❌ REMOVE |

### Network Details

| Current | New | Action |
|---------|-----|--------|
| None | "Hub VNet CIDR" text input | ✅ Add (CIDR block validation) |
| None | "Spoke VNet CIDR" text inputs (multiple) | ✅ Add (CIDR block validation) |
| None | "Additional Regions" multi-select | ✅ Add (moved from secondary region) |

### Removed Sections

| Current | Reason | Replacement |
|---------|--------|-------------|
| Cost Estimate Card | Not part of official ALZ generator | None |
| "Modules to Deploy" checkboxes | Not official (all modules always deployed based on topology) | None (implicit in topology choice) |
| "Compliance Variant" | Compliance via policy effect, not variant selection | Policy assignment effect selector |
| "Tagging Strategy" levels | Tagging levels don't exist in official ALZ | Specific CAF tag fields |
| "Naming Convention" dropdown | Always use CAF standard, with optional override | Resource naming overrides |

---

## Data Flow: Current vs. Official

### Current Form Data Flow (WRONG)
```
Form Input
├── org_prefix
├── modules (selected) → Guessed module deployment logic
├── compliance_variant → Invented effect mapping
├── networking_model → Guessed networking configuration
├── connectivity_type → Invented gateway configuration
├── policies (selected) → Invented policy assignment logic
├── tagging_strategy → Invented tag structure
├── naming_convention → Invented naming logic
└── regions → Guessed region mapping
        ↓
ConfigurationGenerator class → Guess computation
        ↓
Generated .tfvars (valid HCL, but wrong structure)
```

### Official Form Data Flow (RIGHT)
```
Form Input
├── organization (name + id)
├── starter_locations → starter_locations variable
├── defender_email → defender_email_security_contact variable
├── network_topology → enable_virtual_wan flag
├── firewall_sku → firewall_sku variable
├── feature_toggles → enable_ddos_protection, enable_bastion_deployment, etc
├── policy_assignments → policy_assignments structure (50+ entries)
├── management_groups → custom_management_groups overrides
├── resource_naming → custom_resource_names config
├── network_cidr → hub_vnet_cidr, spoke_vnet_cidr variables
└── tagging → tags structure with required keys
        ↓
OfficialALZGenerator class → Map to official Terraform variables
        ↓
Generated .tfvars (valid HCL + valid official ALZ structure)
        ↓
terraform validate ✓ (passes because structure matches official ALZ)
```

---

## Implementation Checklist

### HTML Changes (frontend/index.html)

**Remove**:
- [ ] "Modules to Deploy" section (all 5 checkboxes)
- [ ] "Compliance Variant" dropdown
- [ ] "Networking Model" dropdown (replace with radio buttons)
- [ ] "Connectivity Type" dropdown
- [ ] "Azure Policy Enforcement" checkboxes
- [ ] "Tagging Strategy" dropdown
- [ ] "Naming Convention" dropdown
- [ ] "Cost Estimate Card"
- [ ] "Secondary Region" input

**Rename**:
- [ ] "Organization Prefix" → "Organization ID"
- [ ] "Primary Region" → "Starter Locations" (change to multi-select)

**Add**:
- [ ] Organization Name input
- [ ] Defender Email input
- [ ] Network Topology radio buttons (2 options)
- [ ] Firewall SKU radio buttons
- [ ] DDoS Protection toggle
- [ ] Bastion Host toggle
- [ ] Private DNS Zones toggle
- [ ] Virtual Network Gateways toggle
- [ ] Azure Monitoring Agent toggle
- [ ] AMBA Baseline Alerts toggle
- [ ] Defender Plans toggle
- [ ] Policy Assignments section (50+ checkboxes grouped by scope + effect selector per policy)
- [ ] Management Group Name Overrides (6 fields)
- [ ] Resource Naming Config (3 fields)
- [ ] Network Configuration section (CIDR blocks)
- [ ] Tagging Configuration section (tag fields + enforcement)
- [ ] Additional Regions multi-select

**Reorder Sections**:
- [ ] Group into 9 logical sections (organization, network, monitoring, policies, customization, naming, network details, tagging, review)

### JavaScript Changes (frontend/app.js)

**Remove**:
- [ ] `ConfigurationGenerator` class (entire class)
- [ ] Cost calculation logic
- [ ] Invented networking logic
- [ ] Invented policy logic
- [ ] Invented tagging logic
- [ ] Invented naming logic
- [ ] GitHub API integration
- [ ] GitHub job tracking

**Add**:
- [ ] `OfficialALZGenerator` class
- [ ] Official policy assignment list (50+ items with metadata)
- [ ] Form input readers for all new sections
- [ ] Terraform variable mapping logic
- [ ] `.tfvars` generation following official structure
- [ ] Validation logic (organization ID, CIDR blocks, email, etc.)
- [ ] Form data to Terraform variable conversion

**Methods to Implement**:
- [ ] `readOrganization()` - Get name, ID, email
- [ ] `readStarterLocations()` - Get selected regions
- [ ] `readNetworkTopology()` - Get hub-spoke or vwan
- [ ] `readFeatureToggles()` - Get all toggle states
- [ ] `readPolicyAssignments()` - Get selected policies + effects
- [ ] `readManagementGroupOverrides()` - Get custom MG names
- [ ] `readResourceNaming()` - Get naming prefix, env, instance
- [ ] `readNetworkConfiguration()` - Get CIDR blocks
- [ ] `readTagging()` - Get tag configuration
- [ ] `generateTfvars()` - Main generation function
- [ ] `mapFormToVariables()` - Convert form to Terraform variables
- [ ] `validate()` - Validate all inputs
- [ ] `download()` - Download as .tfvars file
- [ ] `copyToClipboard()` - Copy preview to clipboard

### CSS Changes (frontend/styles.css)

**Add**:
- [ ] Policy grouping styles (indented sections)
- [ ] Effect selector styles (dropdown for each policy)
- [ ] Accordion/collapsible section styles
- [ ] Multi-select widget styles
- [ ] Radio button group styles
- [ ] Toggle switch styles
- [ ] CIDR input validation styles
- [ ] Form section header styles

**Keep**:
- [ ] Existing header, button, and layout styles
- [ ] Preview card styling
- [ ] General color scheme and typography

---

## Validation Rules (Official ALZ)

Add to JavaScript validation:

```javascript
const validationRules = {
  organizationId: {
    required: true,
    pattern: /^[a-z0-9]{3,20}$/, // 3-20 alphanumeric, lowercase
    message: "Organization ID must be 3-20 lowercase alphanumeric characters"
  },
  organizationName: {
    required: true,
    pattern: /^[a-zA-Z0-9\s-]{3,50}$/,
    message: "Organization name must be 3-50 characters"
  },
  defenderEmail: {
    required: true,
    pattern: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
    message: "Must be a valid email address"
  },
  starterLocations: {
    required: true,
    minItems: 1,
    message: "Select at least one location"
  },
  networkTopology: {
    required: true,
    allowedValues: ["hub-spoke", "virtual-wan"],
    message: "Network topology is required"
  },
  firewallSku: {
    required: true,
    allowedValues: ["Standard", "Premium"],
    message: "Firewall SKU is required"
  },
  hubVnetCidr: {
    required: true,
    pattern: /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}\/[0-9]{1,2}$/,
    message: "Must be a valid CIDR block (e.g., 10.0.0.0/16)"
  },
  spokeVnetCidr: {
    required: false,
    pattern: /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}\/[0-9]{1,2}$/,
    message: "Must be valid CIDR blocks"
  },
  policyAssignments: {
    required: false, // At least one policy optional
    validNames: officialPolicyNames
  }
}
```

---

## Example Output Comparison

### Current Form Output (WRONG)
```hcl
# Generated by ConfigurationGenerator
org_prefix = "contoso"
primary_region = "eastus"
secondary_region = "westus"
compliance_variant = "pci-dss"

deploy_hub_network = true
deploy_spoke_networks = true
deploy_policy_baseline = true
deploy_backup_baseline = false

enable_encryption_policy = true
enable_tls_enforcement = true
firewall_tier = "Premium"

tagging_strategy = "comprehensive"
naming_convention = "microsoft"

cost_estimate_monthly = 2160
```
**Problems**:
- Variable names don't match official ALZ
- No official policy assignments
- Compliance as "variant" (not official)
- Tagging strategy doesn't map to official tags
- Cost estimation invented

### Official Form Output (RIGHT)
```hcl
# ═════════════════════════════════════════════════════════════════
# Azure Landing Zones Platform Configuration
# Generated: 2026-06-30
# ═════════════════════════════════════════════════════════════════

root_id   = "contoso"
root_name = "Contoso"

starter_locations = ["eastus2", "westus"]
defender_email_security_contact = "security@contoso.com"

enable_virtual_wan = false
firewall_sku = "Premium"

enable_ddos_protection = true
enable_bastion_deployment = true
enable_private_dns_zones = true
enable_virtual_network_gateway = true

enable_azure_monitoring_agent = true
enable_amba_deployment = true
enable_defender_plans = true

policy_assignments = {
  "Deploy-MDFC" = {
    enabled = true
    effect  = "DeployIfNotExists"
  }
  "Deploy-MDEndpoints" = {
    enabled = true
    effect  = "DeployIfNotExists"
  }
  # ... 48+ more official assignments
}

custom_management_groups = {
  root = { display_name = "Contoso" }
  platform = { display_name = "Platform" }
  connectivity = { display_name = "Connectivity" }
  identity = { display_name = "Identity" }
  management = { display_name = "Management" }
  landing_zones = { display_name = "Landing Zones" }
}

custom_resource_names = {
  prefix = "cto"
  environment_naming = "prod"
  instance_start_number = 1
}

hub_vnet_cidr = "10.0.0.0/16"
spoke_vnet_cidr = ["10.1.0.0/16"]

tags = {
  Environment = "prod"
  Owner = "platform-team"
  CostCenter = "cc-12345"
  Application = "landing-zone"
}
```
**Correct**:
- ✅ Official variable names
- ✅ 50+ official policy assignments
- ✅ Official compliance via policy effect
- ✅ Official tagging with CAF tags
- ✅ No invented configuration

---

## Summary Table

| Aspect | Current (Wrong) | Official (Right) |
|--------|---|---|
| **Sections** | 9 (many mixed) | 9 (well-organized) |
| **Organization** | 1 field (prefix) | 3 fields (name, ID, email) |
| **Network Topology** | 3 options (dropdown) | 2 options (radio buttons) |
| **Policy Options** | 5 invented | 50+ official |
| **Feature Toggles** | 0 | 8+ official |
| **Customization Options** | 0 | 16 official |
| **Naming Configuration** | Dropdown (3 options) | Structured override fields |
| **Tagging** | Dropdown (3 levels) | Specific CAF tag fields |
| **Network CIDR Config** | None | Explicit CIDR block inputs |
| **Management Group Names** | Hard-coded | Customizable (6 fields) |
| **Output Structure** | Invalid for official ALZ | Valid official ALZ .tfvars |
| **Terraform Validation** | May fail | Passes `terraform validate` |

