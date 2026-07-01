# Phase 2: Build Stage - Static Generator Rebuild

**Status**: Planning phase  
**Objective**: Rebuild the static .tfvars generator with ONLY official ALZ configuration options  
**Duration**: Estimated 4-6 hours  
**Deliverable**: Fully functional HTML/JS generator grounded in official ALZ architecture

---

## Overview

Phase 1 identified all actual configuration options in the official Azure Landing Zones. Phase 2 will rebuild the generator form to reflect ONLY these official options and generate valid `.tfvars` files for the official ALZ Terraform modules.

---

## Key Changes from Current Generator

### Form Fields to Remove (Guessed/Invented)
- ❌ "Networking Model" dropdown (hub-spoke, mesh, single-vnet) - Replace with official 2-option topology
- ❌ "Connectivity Type" dropdown (vnet-only, vpn, expressroute, vpn+expressroute) - Move to feature toggles
- ❌ "Azure Policy Enforcement" checkboxes (encryption, TLS, MFA, audit, locks) - Replace with 50+ official assignments
- ❌ "Tagging Strategy" (minimal, standard, comprehensive) - Replace with official CAF tags + optional enforcement
- ❌ "Naming Convention" dropdown (Microsoft, simplified, custom) - Replace with official CAF pattern
- ❌ "Compliance Variant" dropdown (Baseline, PCI-DSS, HIPAA, FedRAMP) - Remove (compliance via policy assignment)
- ❌ Cost estimation section - Remove (not part of official ALZ generator)

### Form Fields to Add (Official ALZ)
- ✅ **Starter Locations** - Multi-select list of Azure regions
- ✅ **Defender Email** - Security contact email for alerts
- ✅ **Network Topology** - Binary choice: `hub-spoke` OR `virtual-wan`
- ✅ **Policy Assignments** - 50+ official checkboxes (grouped by management group scope)
- ✅ **Feature Toggles** - DDoS, Bastion, Private DNS, Gateways, AMA, AMBA, Defender Plans
- ✅ **Firewall SKU** - Standard OR Premium
- ✅ **Management Group Overrides** - Custom names for intermediate root, platform, landing zones
- ✅ **Resource Naming Overrides** - Custom prefix for resource names
- ✅ **IP Address Ranges** - Hub CIDR, spoke CIDR blocks
- ✅ **Tagging** - Official CAF tags (environment, workload, owner, etc.)

---

## Architecture

### 1. Form Structure (Reorganized)

```
Frontend
├── Section 1: Organization & Location
│   ├── Organization Name (string, 3-20 chars)
│   ├── Starter Locations (multi-select: eastus2, westus, etc.)
│   └── Defender Email (email input)
│
├── Section 2: Network Architecture
│   ├── Network Topology (radio: hub-spoke | virtual-wan)
│   ├── Firewall SKU (radio: Standard | Premium)
│   └── Feature Toggles:
│       ├── Deploy DDoS Protection (toggle)
│       ├── Deploy Bastion Host (toggle)
│       ├── Deploy Private DNS Zones (toggle)
│       ├── Deploy Virtual Network Gateways (toggle)
│
├── Section 3: Monitoring & Security
│   ├── Deploy Azure Monitoring Agent (toggle)
│   ├── Deploy AMBA Baseline Alerts (toggle)
│   ├── Deploy Defender Plans (toggle)
│
├── Section 4: Policy Assignments (50+ Official Policies)
│   ├── Group by Management Scope:
│   │   ├── Intermediate Root (10 policies)
│   │   ├── Platform (15 policies)
│   │   ├── Landing Zones (15 policies)
│   │   ├── Landing Zones/Corp (8 policies)
│   │   └── Specialized (Sandbox, Decommissioned)
│   └── Per Policy:
│       ├── Name (from official list)
│       ├── Checkbox (enable/disable)
│       ├── Effect selector (Audit | Deny | DeployIfNotExists | etc)
│
├── Section 5: Customization Options
│   ├── Management Group Names
│   │   ├── Intermediate Root name
│   │   ├── Platform name
│   │   ├── Connectivity name
│   │   ├── Identity name
│   │   ├── Management name
│   │   └── Landing Zones name
│   │
│   ├── Resource Naming
│   │   ├── Resource name prefix
│   │   ├── Environment suffix
│   │   └── Instance counter start
│   │
│   ├── Network Configuration
│   │   ├── Hub VNet CIDR
│   │   ├── Spoke 1 CIDR
│   │   ├── Spoke 2 CIDR
│   │   └── Additional regions
│   │
│   └── Tagging
│       ├── Enable tag enforcement (toggle)
│       ├── Required tag keys (list)
│       └── Default tag values (key-value pairs)
│
└── Section 6: Review & Generate
    ├── Configuration preview
    ├── Download .tfvars button
    ├── Copy to clipboard button
    └── Back to form button
```

---

## Implementation Details

### 2. Data Structure (Official ALZ Terraform Variables)

The generator will map form inputs to official `.tfvars` structure:

```hcl
# ═══════════════════════════════════════════════════════════════
# Azure Landing Zones Platform Configuration
# Generated: 2026-06-30
# ═══════════════════════════════════════════════════════════════

# Organization Configuration
root_id   = "contoso"
root_name = "Contoso"

# Starter Locations
starter_locations = ["eastus2", "westus"]

# Security Configuration
defender_email_security_contact = "security@contoso.com"

# Feature Toggles
enable_ddos_protection          = true
enable_bastion_deployment       = true
enable_private_dns_zones        = true
enable_virtual_network_gateway  = true

# Monitoring Configuration
enable_azure_monitoring_agent   = true
enable_amba_deployment          = true
enable_defender_plans           = true

# Network Configuration
enable_virtual_wan              = false  # true = vWAN, false = hub-spoke

# Firewall Configuration
firewall_sku                    = "Premium"

# Management Group Configuration (overrides)
custom_management_groups = {
  root = {
    display_name = "Contoso"
  }
  platform = {
    display_name = "Platform"
  }
  # ... etc
}

# Resource Naming Configuration
custom_resource_names = {
  prefix                = "cto"
  environment_naming    = "prod"
  instance_start_number = 1
}

# Network Address Space
hub_vnet_cidr     = "10.0.0.0/16"
spoke_vnet_cidr   = ["10.1.0.0/16"]

# Policy Configuration (from official assignments)
policy_assignments = {
  "Deploy-MDFC" = {
    enabled = true
    effect  = "DeployIfNotExists"
  }
  "Deploy-MDEndpoints" = {
    enabled = true
    effect  = "DeployIfNotExists"
  }
  # ... 48+ more assignments
}

# Tags
tags = {
  Environment  = "prod"
  Owner        = "platform-team"
  CostCenter   = "cc-12345"
  Application  = "landing-zone"
}
```

### 3. Policy Assignment Mapping

Form will present all 50+ official policy assignments grouped by scope:

```javascript
const officialPolicies = {
  "Intermediate Root": [
    {
      id: "Deploy-MDFC",
      name: "Deploy Microsoft Defender for Cloud configuration",
      type: "Initiative",
      effect: ["DeployIfNotExists"],
      description: "Configures MDFC settings per service..."
    },
    // ... 9 more
  ],
  "Platform": [
    // ... 15 policies
  ],
  "Landing Zones": [
    // ... 15 policies
  ],
  "Landing Zones/Corp": [
    // ... 8 policies
  ],
  "Specialized": [
    // Sandbox, Decommissioned
  ]
}
```

### 4. JavaScript Generator Class (Rewrite)

Replace current `ConfigurationGenerator` with `OfficialALZGenerator`:

```javascript
class OfficialALZGenerator {
  // Read official form inputs
  getFormData() {
    return {
      organization: this.readOrganization(),
      locations: this.readStarterLocations(),
      networking: this.readNetworkTopology(),
      policies: this.readPolicyAssignments(),
      features: this.readFeatureToggles(),
      customizations: this.readCustomizations(),
      tagging: this.readTagging()
    };
  }

  // Map form inputs to official .tfvars structure
  generateTfvars() {
    const formData = this.getFormData();
    
    // Build official .tfvars file
    return `
# Generated from official ALZ configuration generator
root_id = "${formData.organization.prefix}"
root_name = "${formData.organization.name}"
starter_locations = ${JSON.stringify(formData.locations)}
defender_email_security_contact = "${formData.organization.defenderEmail}"
enable_ddos_protection = ${formData.features.ddos}
enable_bastion_deployment = ${formData.features.bastion}
# ... etc, mapping each form field to official variable
    `;
  }

  // Validate against official ALZ requirements
  validate() {
    // Check all required fields present
    // Check values match official options
    // Check policy assignments valid
    // Return validation results
  }

  // Download as .tfvars file
  download() {
    const tfvars = this.generateTfvars();
    const filename = `${this.getOrganizationPrefix()}-alz-terraform.tfvars`;
    this.downloadFile(tfvars, filename);
  }
}
```

---

## Detailed Implementation Steps

### Step 1: Update HTML Form Structure

**File**: `frontend/index.html`

1. **Remove sections**:
   - Login section (keep hidden)
   - Cost estimate card
   - Old form groups (networking model, connectivity type, compliance variant, tagging strategy, naming convention)

2. **Add new sections**:
   - Organization & Location (organization name, starter locations multi-select, defender email)
   - Network Architecture (topology radio buttons, firewall SKU, feature toggles)
   - Monitoring & Security (AMA, AMBA, Defender toggles)
   - Policy Assignments (50+ grouped checkboxes with effect selector per policy)
   - Management Group Customization (name overrides)
   - Resource Naming (prefix, environment, instance counter)
   - Network Configuration (CIDR blocks)
   - Tagging (official CAF tags)
   - Review & Generate (preview, download, copy buttons)

3. **Form validation**:
   - Required fields must be filled
   - Organization prefix: 3-20 characters, alphanumeric
   - CIDR blocks: valid IPv4 CIDR notation
   - Email: valid email format
   - No special characters in names

### Step 2: Rebuild JavaScript Generator

**File**: `frontend/app.js`

1. **Remove**:
   - Current `ConfigurationGenerator` class
   - Cost calculation logic
   - GitHub API integration
   - MSAL authentication (keep minimal, optional)
   - Invented configuration logic

2. **Add**:
   - `OfficialALZGenerator` class
   - Official policy assignment list (50+ items)
   - Official Terraform variable mapping
   - Form-to-tfvars conversion logic
   - Validation against official ALZ requirements
   - Handling for all 16 customization options

3. **Key methods**:
   ```javascript
   // Read form inputs
   readOrganization()
   readStarterLocations()
   readNetworkTopology()
   readPolicyAssignments()
   readFeatureToggles()
   readCustomizations()
   readTagging()
   
   // Generate .tfvars
   generateTfvars()
   mapFormToVariables()
   buildPolicyAssignmentConfig()
   buildManagementGroupConfig()
   buildResourceNamingConfig()
   buildNetworkConfig()
   buildTaggingConfig()
   
   // Validation
   validate()
   validateOrgPrefix()
   validateCIDRBlocks()
   validatePolicies()
   
   // File operations
   download()
   copyToClipboard()
   preview()
   ```

### Step 3: Update CSS Styling

**File**: `frontend/styles.css`

1. **Add styles for**:
   - Policy assignment grouped checkboxes (indented, labeled by scope)
   - Effect selector dropdowns (per policy)
   - Multi-select locations widget
   - Feature toggle switches
   - Radio button groups (topology, SKU)
   - Configuration preview (code block with syntax highlighting)
   - Form sections with collapsible headers

2. **Keep existing**:
   - Header styling
   - Button styling
   - General layout
   - Preview card styling

---

## Testing Plan

### Unit Tests (JavaScript)

1. **Form Input Reading**:
   - [ ] Organization prefix validation
   - [ ] Starter locations multi-select
   - [ ] Network topology selection
   - [ ] Feature toggle reading
   - [ ] Policy assignment reading
   - [ ] CIDR block reading

2. **Terraform Variable Mapping**:
   - [ ] Organization config maps correctly
   - [ ] Locations map to starter_locations variable
   - [ ] Network topology maps to enable_virtual_wan flag
   - [ ] Feature toggles map to correct variables
   - [ ] Policy assignments generate correct HCL structure
   - [ ] Custom management groups override defaults
   - [ ] Resource naming overrides apply

3. **Validation**:
   - [ ] Required fields detected
   - [ ] Invalid organization prefix rejected
   - [ ] Invalid CIDR blocks rejected
   - [ ] Invalid email rejected
   - [ ] Policy selections validated

4. **File Generation**:
   - [ ] Generated .tfvars is valid HCL syntax
   - [ ] All required variables present
   - [ ] Variable values match form inputs
   - [ ] Policy assignments structure correct
   - [ ] Management group config correct
   - [ ] Resource naming config correct

### Integration Tests (Browser)

1. **Form Interaction**:
   - [ ] All form sections render correctly
   - [ ] Form validation works on submit
   - [ ] Error messages display for invalid inputs
   - [ ] Success message on valid form

2. **Generation**:
   - [ ] Generate button produces preview
   - [ ] Preview shows valid .tfvars content
   - [ ] Download button saves file with correct name
   - [ ] Copy to clipboard copies preview content
   - [ ] Back button returns to form

3. **Cross-browser**:
   - [ ] Chrome/Edge (latest)
   - [ ] Firefox (latest)
   - [ ] Safari (latest)

### End-to-End Tests (Terraform)

1. **Generated File Validity**:
   - [ ] `terraform validate` succeeds on generated .tfvars
   - [ ] `terraform plan` executes without errors
   - [ ] All variables resolved correctly
   - [ ] No unknown variable errors

2. **Configuration Scenarios**:
   - [ ] Hub-spoke topology generates correct config
   - [ ] Virtual WAN topology generates correct config
   - [ ] All feature combinations tested
   - [ ] All policy assignment combinations tested

---

## Phase 2 Deliverables

### Code Changes

1. **frontend/index.html** (Complete rewrite)
   - Official form structure
   - 50+ policy assignment checkboxes
   - 16 customization options
   - Feature toggles
   - Validation

2. **frontend/app.js** (Complete rewrite)
   - `OfficialALZGenerator` class
   - Official policy list
   - Terraform variable mapping
   - Validation logic

3. **frontend/styles.css** (Updated)
   - New form section styles
   - Policy grouping styles
   - Effect selector styles
   - Preview styling

### Documentation

1. **GENERATOR_USAGE_GUIDE.md**
   - Step-by-step user guide
   - Form field descriptions
   - Policy assignment explanations
   - Customization options guide
   - Examples for common scenarios

2. **GENERATOR_TECHNICAL_REFERENCE.md**
   - Form-to-tfvars mapping
   - Official variable names
   - JavaScript class reference
   - Validation rules
   - File format specification

3. **GENERATOR_TESTING_REPORT.md**
   - Test results
   - Coverage metrics
   - Known limitations
   - Browser compatibility

---

## Timeline & Milestones

### Day 1: HTML Form Rebuild (2 hours)
- [ ] Remove old form sections
- [ ] Add new official form sections
- [ ] Implement form validation
- [ ] Test form rendering

### Day 2: JavaScript Generator Rebuild (3 hours)
- [ ] Write OfficialALZGenerator class
- [ ] Implement form-to-tfvars mapping
- [ ] Add all 50+ policy assignments
- [ ] Add customization options support
- [ ] Implement validation

### Day 3: Styling & UI Polish (1 hour)
- [ ] Update CSS for new form sections
- [ ] Add policy grouping styles
- [ ] Improve preview styling
- [ ] Responsive design testing

### Day 4: Testing & Documentation (2 hours)
- [ ] Unit tests for JavaScript
- [ ] Integration tests for form
- [ ] End-to-end Terraform validation
- [ ] Generate usage guide
- [ ] Generate technical reference

---

## Success Criteria

✅ **Functional**:
- Form reads all official ALZ configuration options
- Generator produces valid .tfvars for official ALZ Terraform
- All 50+ policy assignments supported
- All 16 customization options supported
- Generated file passes `terraform validate`

✅ **Accurate**:
- Uses ONLY official variable names from ALZ
- Uses ONLY official policy names from ALZ
- Follows official .tfvars structure
- No invented or guessed configuration options

✅ **Usable**:
- Form is intuitive and self-documenting
- Error messages clear and helpful
- Preview shows exactly what will be generated
- Download/copy functionality works

✅ **Documented**:
- User guide explains all form fields
- Technical reference explains all mappings
- Examples provided for common scenarios
- Test report confirms functionality

---

## Risks & Mitigations

| Risk | Probability | Impact | Mitigation |
|------|---|---|---|
| 50+ policies too complex in UI | Medium | High | Organize by management group scope, add collapse/expand, search filter |
| Form becomes too long | High | Medium | Use tabs or accordion sections, lazy load non-essential fields |
| CIDR block validation complex | Low | Medium | Use regex pattern, provide examples, auto-suggest common ranges |
| Terraform variable names wrong | Low | Critical | Verify against official accelerator repo before finalizing |
| Generated tfvars doesn't validate | Low | Critical | Extensive testing with actual Terraform, include validation in generator |

---

## Phase 2 Completion Definition

Phase 2 is COMPLETE when:

1. ✅ Form reflects ONLY official ALZ configuration options (no invented fields)
2. ✅ Generator produces valid `.tfvars` that pass `terraform validate`
3. ✅ All 50+ policy assignments can be configured
4. ✅ All 16 customization options supported
5. ✅ Usage guide and technical reference complete
6. ✅ Testing report confirms functionality across browsers
7. ✅ No invented configuration logic remains

---

## Next Phase: Phase 3 (Deploy)

Once Phase 2 is complete, Phase 3 will:
- Connect generated .tfvars to official ALZ Terraform modules
- Automate deployment via GitHub Actions
- Provide deployment status tracking
- Validate deployments succeeded

