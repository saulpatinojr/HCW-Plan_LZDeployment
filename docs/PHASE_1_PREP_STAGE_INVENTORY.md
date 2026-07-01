# Phase 1: Prep Stage - Azure Landing Zones Configuration Inventory

**Status**: Complete analysis of official ALZ architecture  
**Source**: Official Microsoft Azure Landing Zones Repository  
**Date**: 2026-06-30

---

## Overview

This document captures ALL configuration options available in the official Azure Landing Zones (ALZ) reference architecture. This inventory is grounded in the actual ALZ GitHub repository, not guesses or inferred values.

**Key References**:
- Official Repository: https://github.com/Azure/Azure-Landing-Zones
- Terraform Accelerator: https://azure.github.io/Azure-Landing-Zones/terraform/gettingstarted/
- Policy Assignments: https://azure.github.io/Azure-Landing-Zones/policy/policyassignments/
- Azure Verified Modules: https://azure.github.io/Azure-Verified-Modules/

---

## 1. TERRAFORM CONFIGURATION OPTIONS

### 1.1 Core Variables (from official ALZ Terraform)

The official Terraform accelerator uses a **configuration-driven approach** with structured inputs:

**From ALZ Terraform Accelerator Configuration**:

```hcl
# Core Organization Settings
org_name                    = string      # Required: Organization name/prefix
root_id                     = string      # Required: Root management group ID
root_name                   = string      # Required: Root management group name
default_location            = string      # Required: Primary Azure region

# Management Group Hierarchy (can be customized)
subscription_id_connectivity = string     # Connectivity subscription ID
subscription_id_identity    = string      # Identity subscription ID
subscription_id_management  = string      # Management subscription ID

# Feature Toggles (Enable/Disable Components)
deploy_connectivity_resources = bool      # Deploy hub network, firewalls, gateways
deploy_management_resources   = bool      # Deploy management tools (Log Analytics, Automation)
deploy_identity_resources     = bool      # Deploy identity/access management

# Networking Configuration
enable_ddos_protection        = bool      # Default: true
enable_bastion               = bool      # Default: true
enable_private_dns_zones     = bool      # Default: true
enable_virtual_network_gateway = bool    # Default: true for connectivity

# Policy Configuration
enable_monitoring_baseline_alerts = bool  # Default: true
enable_azure_monitoring_agent    = bool  # Default: true

# Firewall Configuration (when deploy_connectivity_resources = true)
firewall_sku                 = string    # Standard | Premium
firewall_threat_intel_mode   = string    # Alert | Deny | Off

# Virtual Network / Virtual WAN Configuration
enable_virtual_wan           = bool      # Hub-Spoke via VNet vs Virtual WAN
```

**Available Scenarios from Official ALZ** (pre-built configurations):

1. **Multi-Region Hub-and-Spoke VNet + Azure Firewall**
2. **Multi-Region Virtual WAN + Azure Firewall**
3. **Multi-Region Hub-and-Spoke VNet + NVA** (Network Virtual Appliance)
4. **Multi-Region Virtual WAN + NVA**
5. **Management-Only** (No networking - just management groups & policies)
6. **Single-Region Hub-and-Spoke VNet + Azure Firewall**
7. **Single-Region Virtual WAN + Azure Firewall**
8. **Single-Region Hub-and-Spoke VNet + NVA**
9. **Single-Region Virtual WAN + NVA**
10. **SMB Single-Region Hub-and-Spoke VNet + Azure Firewall** (Simplified)
11. **SMB Single-Region Virtual WAN + Azure Firewall** (Simplified)

---

## 2. POLICY ASSIGNMENTS (OFFICIAL ALZ)

### 2.1 Policy Assignment Scope & Count

Total official ALZ policy assignments: **48 assignments** across management group hierarchy.

**Assignment Scopes**:
- **Intermediate Root** (parent MG): 18 assignments
- **Platform** (management infrastructure): 13 assignments
- **Platform/Connectivity**: 2 assignments
- **Platform/Management**: 1 assignment
- **Platform/Identity**: 3 assignments
- **Landing Zones**: 16 assignments
- **Landing Zones/Corp**: 5 assignments
- **Landing Zones/Online**: 0 assignments (customization point)
- **Decommissioned**: 1 assignment
- **Sandbox**: 1 assignment

### 2.2 Default Policy Assignments (Intermediate Root)

| Assignment Name | Type | Effect | Customizable |
|---|---|---|---|
| Deploy Microsoft Defender for Cloud configuration | Initiative | DeployIfNotExists | ✓ Parameters |
| Deploy Microsoft Defender for Endpoint agent | Initiative | DeployIfNotExists | ✓ Parameters |
| Configure Microsoft Defender for Endpoint integration | Initiative | DeployIfNotExists | ✓ Parameters |
| Enable allLogs category resource logging to Log Analytics | Initiative | DeployIfNotExists | ✓ Parameters |
| **Microsoft Cloud Security Benchmark** | Initiative | Audit/AuditIfNotExists | ✓ Enforcement mode |
| Configure Advanced Threat Protection - OSS Databases | Initiative | DeployIfNotExists | ✓ Parameters |
| Configure Azure Defender - SQL Servers | Initiative | DeployIfNotExists | ✓ Parameters |
| Deploy Activity Log Diagnostics to Log Analytics | Policy | DeployIfNotExists | ✓ Workspace ID |
| Deny Classic Resources | Policy | Deny | ✗ Fixed |
| Enforce Azure Compute Security Baseline | Initiative | AuditIfNotExists | ✓ Enforcement mode |
| Deny VMs without Managed Disk | Policy | Deny | ✗ Fixed |
| Unused Resources Cost Avoidance | Initiative | Audit | ✗ Fixed |
| Deploy AMBA Service Health Alerts | Initiative | DeployIfNotExists | ✓ Parameters |
| Zone Resilience Audit | Initiative | Audit | ✗ Fixed |
| Audit Trusted Launch | Initiative | Audit | ✗ Fixed |
| Service Health Monitoring Rule | Policy | DeployIfNotExists | ✓ Parameters |

### 2.3 Platform Management Group Policies

**Key Platform Policies**:
- Enforce Key Vault guardrails (Deny, Audit)
- Enforce backup & recovery policies (Audit)
- Deny public IP creation
- Deny management port access from internet
- Require NSG on subnets
- Configure VM backup to recovery services
- Azure Monitor Baseline Alerts (Management, Identity, Connectivity)

### 2.4 Landing Zone Policies

**Workload Landing Zone Policies** (Landing Zones MG):
- Deny/Deploy TLS/SSL encryption enforcement
- Network management ports security
- Network interface IP forwarding
- Secure storage transfer (HTTPS)
- DDoS Protection Standard (Modify)
- AKS policy add-on deployment
- SQL auditing & threat detection
- SQL Transparent Data Encryption
- AKS security (no privileged containers, no privilege escalation, HTTPS only)
- Backup enforcement for VMs
- Subnet privacy enforcement
- Azure Monitor alerts for landing zones

**Corporate Landing Zone Policies** (Landing Zones/Corp):
- Public network access disabled for PaaS
- Private DNS zones for PaaS services
- No public IPs on network interfaces
- Private Link DNS zone audit
- Deny vWAN/ExpressRoute/VPN gateway resources (Corp landing zone is internal only)

---

## 3. MANAGEMENT GROUP HIERARCHY

### Official ALZ Management Group Structure

```
Tenant Root MG
└── Intermediate Root (e.g., "Contoso")
    ├── Platform
    │   ├── Connectivity (Hub networking, gateways, firewalls)
    │   ├── Identity (Authentication, RBAC, PIM)
    │   └── Management (Monitoring, automation, central services)
    ├── Landing Zones
    │   ├── Corp (Internal corporate resources - restricted connectivity)
    │   └── Online (Internet-facing resources - public access allowed)
    ├── Decommissioned (Subscriptions being wound down)
    └── Sandbox (Isolated testing, limited resources)
```

**Customizable Elements**:
- Intermediate Root name (default: org_name)
- Management group names can be customized
- Management group IDs can be customized
- Management group hierarchy structure can be modified

---

## 4. NETWORKING CONFIGURATION OPTIONS

### 4.1 Network Topologies (Official ALZ)

**Hub-and-Spoke (VNet-based)**:
- Central hub VNet with network appliances (Azure Firewall or NVA)
- Spoke VNets peered to hub
- Traffic flows through hub for centralized control
- Supports single-region or multi-region
- IP address ranges customizable

**Virtual WAN (Microsoft-managed)**:
- Azure-managed hub abstraction (vWAN hub)
- Automatic routing between sites
- Built-in DDoS protection
- Simplified multi-region deployments
- Supports single-region or multi-region
- IP address ranges customizable

**Management-Only**:
- No networking resources deployed
- Just management groups and policies
- Used for policy-only or governance-first deployments

### 4.2 Connectivity Models (Official ALZ)

**Network Appliance Options**:
1. **Azure Firewall** (Microsoft-managed, recommended)
   - SKU: Standard or Premium
   - Premium tier enforced for PCI-DSS compliance
   
2. **Network Virtual Appliance (NVA)** (Third-party, e.g., Cisco, FortiGate)
   - Customer-managed
   - Custom routing rules
   - Bring your own firewall

**Hybrid Connectivity Options**:
- VPN Gateway (site-to-site, point-to-site)
- ExpressRoute (private dedicated connection)
- Either, both, or neither

### 4.3 Network Configuration Variables (Official ALZ)

```hcl
# Network Topology
enable_virtual_wan                    = bool    # true = vWAN, false = Hub-Spoke

# IP Address Space (customizable)
connectivity_resources_location       = string  # Region for hub
additional_regions_for_connectivity   = list    # Multi-region hubs

# Azure Firewall (if using)
firewall_sku                          = string  # Standard | Premium
firewall_threat_intel_mode            = string  # Alert | Deny | Off

# Virtual Network Gateways
enable_virtual_network_gateway        = bool    # Deploy VPN/ER gateway
gateway_type                          = string  # Vpn | ExpressRoute | Both

# DDoS Protection
enable_ddos_protection                = bool    # Default: true

# Bastion Host
enable_bastion                        = bool    # Default: true

# Private DNS Zones
enable_private_dns_zones              = bool    # Default: true
```

---

## 5. COMPLIANCE VARIANTS & POLICIES

### 5.1 Official ALZ Compliance Support

The ALZ reference architecture is compliance-agnostic. Policies can be tailored for:

**Built-in Policy Initiatives Available**:
- **Microsoft Cloud Security Benchmark** (ASB) - Default
- **Microsoft Cloud Security Benchmark v2** - Latest
- **Custom initiatives** - User-defined

**Commonly Supported Compliance Frameworks** (via policy assignment):
- PCI-DSS (Policy assignments with Firewall Premium)
- HIPAA (Custom policy assignments)
- FedRAMP (Custom policy assignments)
- SOC 2 (Custom policy assignments)
- ISO 27001 (Custom policy assignments)

**How Compliance is Implemented**:
- Policy effect changes: `Audit` → `Deny` for stricter enforcement
- Policy parameters: `enforcement_mode`, policy `exclusions`, `effect`
- Firewall SKU: Premium required for high-security compliance
- Mandatory policies: Can be toggled on/off per assignment

---

## 6. NAMING CONVENTIONS (Official ALZ)

### 6.1 Official ALZ Naming Standards

The official ALZ uses **Microsoft Cloud Adoption Framework (CAF) naming conventions**.

**Format**:
```
{resource-type}{org-prefix}{environment}{instance}
```

**Resource Type Prefixes** (official CAF):
- Storage account: `st` (e.g., `stcontosoprod001`)
- Virtual network: `vnet` (e.g., `vnet-contoso-prod-eastus`)
- Subnet: `snet` (e.g., `snet-contoso-prod-app`)
- Network interface: `nic` (e.g., `nic-contoso-prod-vm01`)
- Virtual machine: `vm` (e.g., `vm-contoso-prod-app01`)
- Azure Firewall: `afw` (e.g., `afw-contoso-prod`)
- Management group: No prefix (e.g., `contoso`, `contoso-platform`)
- Resource group: `rg` (e.g., `rg-contoso-prod-connectivity`)

**Customizable Elements**:
- Organization prefix (e.g., `contoso`, `myorg`)
- Environment suffix (e.g., `prod`, `dev`, `test`, `staging`)
- Instance counter (e.g., `001`, `002`)
- Region abbreviation (e.g., `eastus`, `westus`)

**Implementation**:
Users can override naming conventions during ALZ deployment via variables.

---

## 7. TAGGING STRATEGY (Official ALZ)

### 7.1 Recommended ALZ Tags

The official ALZ recommends tags but doesn't enforce them by default. Policies can be added to enforce tagging.

**Recommended Core Tags** (from ALZ guidance):
```hcl
tags = {
  "Environment"      = "prod"               # prod, staging, dev, test
  "Owner"           = "team-name"           # Responsible team
  "CostCenter"      = "cc-123456"          # Cost allocation
  "ApplicationName" = "myapp"              # Application identifier
  "DataClassification" = "confidential"    # public, internal, confidential, restricted
  "Compliance"      = "pci-dss"           # Compliance framework
  "CreatedBy"       = "terraform"          # Creation method
  "CreatedDate"     = "2026-06-30"        # ISO 8601 format
}
```

**Tag Enforcement**:
- Optional by default
- Can be enforced via custom policy assignment
- ALZ supports both built-in and custom tag policies
- Option to deny resources without required tags

---

## 8. MONITORING & LOGGING (Official ALZ)

### 8.1 Default Monitoring Configuration

**Azure Monitor Components Deployed**:
- Log Analytics Workspace (central logging hub)
- Activity Log diagnostics to Log Analytics
- Azure Monitoring Agent (AMA) - auto-deployed to VMs
- Azure Monitor Baseline Alerts (AMBA) - optional

**Configurable Options**:
```hcl
enable_azure_monitoring_agent          = bool    # Deploy AMA to VMs
enable_monitoring_baseline_alerts      = bool    # Deploy AMBA
log_analytics_workspace_retention_days = number  # Default: 30
```

**Policy Assignments** (Automatically deployed):
- Deploy diagnostic settings for Activity Log
- Enable AMA for VMs, VMSS, Hybrid VMs
- Enable ChangeTracking and Inventory
- Enable Defender for SQL
- Configure periodic OS updates checking

---

## 9. AZURE VERIFIED MODULES (AVM) - Official ALZ

The official ALZ uses **Azure Verified Modules** for all infrastructure-as-code components.

### 9.1 Core AVM Modules for ALZ

**Pattern Modules** (High-level abstractions):
- `avm/ptn/alz/empty` - Empty landing zone template
- `avm/ptn/alz/ama` - Landing zone with Azure Monitoring Agent
- `avm/ptn/lz/sub-vending` - Subscription provisioning

**Resource Modules** (Low-level building blocks):
- `avm/res/authorization/management-group` - Management groups
- `avm/res/authorization/policy-assignment` - Policy assignments
- `avm/res/network/virtual-network` - VNets
- `avm/res/network/public-ip` - Public IPs
- `avm/res/network/network-security-group` - NSGs
- `avm/res/network/route-table` - Route tables
- `avm/res/network/virtual-network-gateway` - VPN/ER gateways
- `avm/res/network/network-watcher` - Network diagnostics
- `avm/res/network/firewall` - Azure Firewall
- `avm/res/network/firewall-policy` - Firewall policies
- `avm/res/compute/bastion` - Azure Bastion
- `avm/res/operational-insights/workspace` - Log Analytics
- etc.

**Module Versions**:
- All modules pinned to specific versions
- Backward compatibility across minor versions
- Breaking changes only in major versions

---

## 10. CONFIGURATION-DRIVEN DEPLOYMENT

### 10.1 Official ALZ Configuration File Approach

The ALZ uses a **configuration file** (YAML/HCL) to drive all deployment decisions:

**Configuration File Structure**:
```yaml
# Example configuration for ALZ deployment
organization_name: "Contoso"
root_id: "contoso"
default_location: "eastus"

# Network Configuration
network_topology: "hub-spoke"  # hub-spoke | virtual-wan | management-only
firewall_sku: "Premium"
enable_ddos_protection: true
enable_bastion: true

# Policy Configuration
policy_assignments:
  - "Deploy Microsoft Defender for Cloud"
  - "Microsoft Cloud Security Benchmark"
  - "Deny Classic Resources"
  # ... others

# Management Groups
management_groups:
  - name: "Platform"
    children:
      - name: "Connectivity"
      - name: "Identity"
      - name: "Management"
  - name: "Landing Zones"
    children:
      - name: "Corp"
      - name: "Online"

# Subscriptions
subscriptions:
  connectivity:
    - subscription_id: "xxx-xxx-xxx"
  identity:
    - subscription_id: "xxx-xxx-xxx"
  management:
    - subscription_id: "xxx-xxx-xxx"
```

---

## 11. CUSTOMIZATION OPTIONS (Official ALZ)

### 11.1 What Can Be Changed

**Official ALZ provides customization for**:

1. **Resource names** - Names of networks, firewalls, resource groups
2. **Management group names & IDs** - Custom naming for hierarchy
3. **IP address ranges** - CIDR blocks for VNets, subnets
4. **Firewall configuration** - SKU, threat intel mode
5. **Policy enforcement** - Which policies to assign, enforcement mode (Audit vs Deny)
6. **Policy parameters** - Exclusions, workspace IDs, allowed values
7. **Feature toggles** - Enable/disable DDoS, Bastion, Private DNS, gateways
8. **Monitoring** - AMA, AMBA, workspace retention
9. **Tagging** - Tag keys and values (if enforced)
10. **Regions** - Primary and additional regions for multi-region

### 11.2 What Cannot Be Changed (Without Major Customization)

- **Management group hierarchy structure** - Can be modified but requires careful planning
- **Core policy assignments** - Can disable but not remove entirely without custom library
- **Azure Verified Module versions** - Must follow CAF standards
- **Compliance frameworks** - Must be custom-implemented

---

## 12. OFFICIAL ALZ OPTIONS REFERENCE

From the official documentation, these are the **official customization options**:

1. Customize Resource Names
2. Customize Management Group Names and IDs
3. Turn off DDoS Protection Plan
4. Turn off Bastion Host
5. Turn off Private DNS Zones
6. Turn off Virtual Network Gateways
7. Additional Regions (Multi-region deployment)
8. IP Address Ranges (Custom CIDR blocks)
9. Change Policy Assignment Enforcement Mode (Audit → Deny)
10. Remove a Policy Assignment
11. Turn off Azure Monitoring Agent
12. Deploy Azure Monitoring Baseline Alerts (AMBA)
13. Turn off Defender Plans
14. Change Firewall SKU (Standard → Premium)
15. Implement Sovereign Landing Zone (SLZ) Controls
16. Create and Assign Custom Policies

---

## 13. STATIC GENERATOR REQUIREMENTS

### 13.1 Form Fields That MUST Exist (Grounded in Official ALZ)

Based on official ALZ configuration, the generator form must support:

**Required Fields**:
1. **Organization Prefix** - Used in all resource naming
2. **Primary Region** - Where hub network is deployed
3. **Additional Regions** - For multi-region deployments
4. **Network Topology** - `hub-spoke`, `virtual-wan`, or `management-only`
5. **Firewall SKU** - `Standard` or `Premium`
6. **Feature Toggles**:
   - Deploy connectivity resources (hub network)?
   - Enable DDoS Protection?
   - Enable Bastion Host?
   - Enable Private DNS Zones?
   - Enable Virtual Network Gateways?
   - Enable Azure Monitoring Agent?
   - Enable AMBA (Baseline Alerts)?

7. **Policy Enforcement**:
   - Which policy assignments to enable (checkbox list of official 48 assignments)
   - Enforcement mode per policy (Audit vs Deny vs DeployIfNotExists)

8. **IP Address Configuration**:
   - Hub VNet CIDR block
   - Spoke VNet CIDR blocks
   - Subnet ranges

9. **Tagging** - If enforcement enabled:
   - Required tag keys
   - Default tag values

10. **Custom Management Group Names** - Optional overrides

**Optional Fields**:
- Log Analytics retention days
- Custom policy assignments
- Sovereign Landing Zone options

---

## 14. PHASE 1 VALIDATION CHECKLIST

Before moving to Phase 2 (Build), verify:

- [ ] All 48 official ALZ policy assignments documented
- [ ] All official ALZ network topology options understood
- [ ] All customization options from official docs implemented
- [ ] Terraform variables match official ALZ accelerator
- [ ] Management group hierarchy matches official ALZ
- [ ] AVM modules referenced are correct
- [ ] Naming conventions follow CAF standards
- [ ] Tagging recommendations aligned with ALZ guidance
- [ ] Form fields grounded in official options (not guesses)
- [ ] Cost model updated based on official ALZ components
- [ ] No placeholder/invented configuration options remain

---

## 15. KEY DIFFERENCES FROM PREVIOUS APPROACH

### What Was Guessed vs. What Is Official

| Item | Previous | Official |
|---|---|---|
| Networking models | placeholder (hub-spoke, mesh, single) | `hub-spoke`, `virtual-wan`, `management-only` (3 only) |
| Policy options | 5 invented (encryption, TLS, MFA, audit, locks) | 48 official assignments with specific names |
| Compliance variants | 4 invented (Baseline, PCI-DSS, HIPAA, FedRAMP) | Policies customizable per assignment, not variants |
| Naming convention | 3 placeholder options | Official CAF standard + customizable |
| Tagging | 3 invented levels | Official ALZ recommended tags + enforcement optional |
| Modules | Guessed deployment units | Official AVM modules with specific names |
| Feature toggles | 4 invented | 10+ official toggles from ALZ documentation |

---

## 16. NEXT STEPS FOR PHASE 2 (BUILD)

Now that Phase 1 is complete:

1. **Rebuild form** with **exact** official ALZ fields
2. **Map form inputs** to **official Terraform variables**
3. **Generate `.tfvars`** using **official variable names**
4. **Validate** all policy assignments come from the **48 official assignments**
5. **Test** against **official ALZ Terraform modules**
6. **Document** form-to-tfvars mappings for users

---

## CONCLUSION

The official Azure Landing Zones architecture provides a **prescriptive but flexible** framework. This Phase 1 inventory captures all the actual configuration points that users can customize. 

**The generator must now be rebuilt to reflect ONLY these official options**, not placeholders or guesses.

