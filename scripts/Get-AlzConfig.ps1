<#
.SYNOPSIS
Azure Landing Zone Configuration-as-Code System
.DESCRIPTION
Centralized configuration management for ALZ deployments. Extracted from Compose script for reusability and consistency.
.NOTES
Version: 1.0
Author: ALZ Operations Team
Date: 2026-06-28
#>

class ALZConfig {
    # ============================================================================
    # REGION CONFIGURATION
    # ============================================================================
    static [hashtable] $RegionMapping = @{
        # Primary Regions
        "eastus"           = @{ code = "eus"; costMultiplier = 1.0; name = "East US" }
        "westus"           = @{ code = "wus"; costMultiplier = 0.95; name = "West US" }
        "westus2"          = @{ code = "wu2"; costMultiplier = 0.95; name = "West US 2" }
        "westus3"          = @{ code = "wu3"; costMultiplier = 0.95; name = "West US 3" }
        "centralus"        = @{ code = "cus"; costMultiplier = 0.95; name = "Central US" }
        "southcentralus"   = @{ code = "scu"; costMultiplier = 0.95; name = "South Central US" }
        "northcentralus"   = @{ code = "ncu"; costMultiplier = 0.95; name = "North Central US" }

        # Europe
        "westeurope"       = @{ code = "weu"; costMultiplier = 1.05; name = "West Europe" }
        "northeurope"      = @{ code = "neu"; costMultiplier = 1.05; name = "North Europe" }
        "uksouth"          = @{ code = "uks"; costMultiplier = 1.1; name = "UK South" }
        "ukwest"           = @{ code = "ukw"; costMultiplier = 1.1; name = "UK West" }
        "germanywestcentral" = @{ code = "gwc"; costMultiplier = 1.15; name = "Germany West Central" }
        "francecentral"    = @{ code = "frc"; costMultiplier = 1.08; name = "France Central" }
        "switzerlandnorth" = @{ code = "szn"; costMultiplier = 1.20; name = "Switzerland North" }

        # Asia Pacific
        "southeastasia"    = @{ code = "sea"; costMultiplier = 1.1; name = "Southeast Asia" }
        "eastasia"         = @{ code = "eas"; costMultiplier = 1.1; name = "East Asia" }
        "japaneast"        = @{ code = "jpe"; costMultiplier = 1.15; name = "Japan East" }
        "japanwest"        = @{ code = "jpw"; costMultiplier = 1.15; name = "Japan West" }
        "australiaeast"    = @{ code = "aue"; costMultiplier = 1.20; name = "Australia East" }
        "koreacentral"     = @{ code = "krc"; costMultiplier = 1.12; name = "Korea Central" }
    }

    # ============================================================================
    # FIREWALL CONFIGURATION (Monthly Cost in USD)
    # ============================================================================
    static [hashtable] $FirewallCosts = @{
        "Standard" = @{
            "eastus"           = 1500
            "westus"           = 1400
            "westus2"          = 1400
            "westus3"          = 1400
            "centralus"        = 1400
            "southcentralus"   = 1400
            "northcentralus"   = 1400
            "westeurope"       = 1600
            "northeurope"      = 1600
            "uksouth"          = 1700
            "ukwest"           = 1700
            "germanywestcentral" = 1800
            "francecentral"    = 1650
            "switzerlandnorth" = 1900
            "southeastasia"    = 1700
            "eastasia"         = 1700
            "japaneast"        = 1800
            "japanwest"        = 1800
            "australiaeast"    = 1900
            "koreacentral"     = 1750
        }
        "Premium" = @{
            "eastus"           = 4000
            "westus"           = 3800
            "westus2"          = 3800
            "westus3"          = 3800
            "centralus"        = 3800
            "southcentralus"   = 3800
            "northcentralus"   = 3800
            "westeurope"       = 4200
            "northeurope"      = 4200
            "uksouth"          = 4500
            "ukwest"           = 4500
            "germanywestcentral" = 4800
            "francecentral"    = 4400
            "switzerlandnorth" = 5000
            "southeastasia"    = 4500
            "eastasia"         = 4500
            "japaneast"        = 4800
            "japanwest"        = 4800
            "australiaeast"    = 5000
            "koreacentral"     = 4600
        }
    }

    # ============================================================================
    # COMPLIANCE CONFIGURATION
    # ============================================================================
    static [hashtable] $ComplianceVariants = @{
        "baseline" = @{
            name           = "Baseline (Standard Policies)"
            costMultiplier = 1.0
            firewallTier   = "Standard"
            description    = "Standard tagging and location policies"
            policies       = @("location-allowed", "naming-convention", "tagging-required")
        }
        "pci-dss" = @{
            name           = "PCI-DSS (Payment Card Industry)"
            costMultiplier = 1.2
            firewallTier   = "Standard"
            description    = "Encryption in transit policies"
            policies       = @("location-allowed", "naming-convention", "tagging-required", "encryption-transit", "tls-https-only")
        }
        "hipaa" = @{
            name           = "HIPAA (Healthcare)"
            costMultiplier = 1.5
            firewallTier   = "Premium"
            description    = "Encryption at rest + audit logging"
            policies       = @("location-allowed", "naming-convention", "tagging-required", "encryption-rest", "audit-enabled", "data-retention-30days")
        }
        "fedramp" = @{
            name           = "FedRAMP (Government)"
            costMultiplier = 1.8
            firewallTier   = "Premium"
            description    = "Continuous monitoring + advanced auditing"
            policies       = @("location-allowed", "naming-convention", "tagging-required", "encryption-rest", "encryption-transit", "continuous-monitoring", "advanced-audit", "data-retention-90days")
        }
    }

    # ============================================================================
    # MODULE CONFIGURATION & DEPENDENCIES
    # ============================================================================
    static [hashtable] $Modules = @{
        "management-groups" = @{
            enabled       = $true
            dependencies  = @()
            description   = "Azure Management Groups hierarchy"
            cost          = 0  # No direct cost
        }
        "management-baseline" = @{
            enabled       = $true
            dependencies  = @("management-groups")
            description   = "Log Analytics, Automation Account, App Insights"
            cost          = 350  # Approximate monthly
        }
        "hub-network" = @{
            enabled       = $true
            dependencies  = @("management-groups", "management-baseline")
            description   = "Hub VNet with Firewall, Gateway, Bastion"
            cost          = "variable"  # Depends on firewall tier
        }
        "spoke-network" = @{
            enabled       = $true
            dependencies  = @("management-groups", "hub-network")
            description   = "Spoke VNet with workload subnets"
            cost          = 300
        }
        "policy-baseline" = @{
            enabled       = $true
            dependencies  = @("management-groups")
            description   = "Azure Policy assignments (compliance variant)"
            cost          = 0
        }
        "backup-baseline" = @{
            enabled       = $false
            dependencies  = @("management-groups", "hub-network")
            description   = "Azure Backup with Recovery Services Vault"
            cost          = 500
        }
        "defender-baseline" = @{
            enabled       = $false
            dependencies  = @("management-groups", "management-baseline")
            description   = "Microsoft Defender for Cloud"
            cost          = 2000
        }
    }

    # ============================================================================
    # NETWORK CONFIGURATION
    # ============================================================================
    static [hashtable] $NetworkAddressSpaces = @{
        "primary" = @{
            hub   = "10.0.0.0/16"
            spoke = "10.1.0.0/16"
            description = "Primary region address space"
        }
        "secondary" = @{
            hub   = "10.100.0.0/16"
            spoke = "10.101.0.0/16"
            description = "Secondary region (DR) address space"
        }
    }

    static [hashtable] $SubnetConfigurations = @{
        "hub" = @{
            "firewall"       = "10.0.0.0/26"
            "gateway"        = "10.0.1.0/27"
            "bastion"        = "10.0.2.0/27"
            "management"     = "10.0.3.0/27"
        }
        "spoke" = @{
            "app"            = "10.1.0.0/24"
            "data"           = "10.1.1.0/24"
            "private-endpoints" = "10.1.2.0/24"
        }
    }

    # ============================================================================
    # NAMING CONVENTIONS
    # ============================================================================
    static [hashtable] $NamingConventions = @{
        "resourceGroup"    = "{org_prefix}-rg-{environment}-{region_code}"
        "vnet"             = "{org_prefix}-vnet-{environment}-{region_code}"
        "subnet"           = "{org_prefix}-snet-{type}-{region_code}"
        "firewall"         = "{org_prefix}-fw-{environment}-{region_code}"
        "logAnalytics"     = "{org_prefix}-law-{environment}-{region_code}"
        "automationAccount"= "{org_prefix}-aa-{environment}-{region_code}"
        "vault"            = "{org_prefix}-rsv-{environment}-{region_code}"
        "managementGroup"  = "{org_prefix}-{level}"
    }

    # ============================================================================
    # TAGGING STRATEGY
    # ============================================================================
    static [hashtable] $DefaultTags = @{
        "environment"      = "production"
        "createdBy"        = "ALZ-Orchestration"
        "costCenter"       = "alz"
        "dataClassification" = "internal"
        "businessUnit"     = "infrastructure"
    }

    # ============================================================================
    # COST MODEL CONFIGURATION
    # ============================================================================
    static [hashtable] $CostModel = @{
        "components" = @{
            "firewall" = @{
                description = "Azure Firewall"
                baseCost    = "region-dependent"  # See FirewallCosts table
            }
            "logAnalytics" = @{
                description = "Log Analytics Workspace"
                ingestion   = 2.30  # Per GB
                retention   = 0.13  # Per GB-month
                minCost     = 50
            }
            "managementVnet" = @{
                description = "Management VNet and peering"
                monthlyCost = 50
            }
            "workloadVnet" = @{
                description = "Workload VNet and peering"
                monthlyCost = 75
            }
            "automationAccount" = @{
                description = "Automation Account"
                monthlyCost = 50
            }
            "applicationInsights" = @{
                description = "Application Insights"
                ingestion   = 0.50  # Per GB
                minCost     = 25
            }
        }
    }

    # ============================================================================
    # SECONDARY REGION OPTIMIZATION
    # ============================================================================
    static [hashtable] $SecondaryRegionConfig = @{
        enabled            = $true
        costReduction      = 0.15  # DR runs at 15% of primary cost
        firewallTier       = "Standard"  # Always use Standard for cost optimization
        deploymentType     = "skeleton"  # Read-only, minimal compute
        descriptiontation    = "Disaster recovery deployment in secondary region"
    }

    # ============================================================================
    # SERVICE METHODS
    # ============================================================================
    static [string] GetRegionCode([string]$region) {
        if ([ALZConfig]::RegionMapping.ContainsKey($region)) {
            return [ALZConfig]::RegionMapping[$region].code
        }
        throw "Unknown region: $region"
    }

    static [decimal] GetRegionCostMultiplier([string]$region) {
        if ([ALZConfig]::RegionMapping.ContainsKey($region)) {
            return [ALZConfig]::RegionMapping[$region].costMultiplier
        }
        return 1.0
    }

    static [decimal] GetFirewallCost([string]$tier, [string]$region) {
        if ([ALZConfig]::FirewallCosts.ContainsKey($tier) -and
            [ALZConfig]::FirewallCosts[$tier].ContainsKey($region)) {
            return [ALZConfig]::FirewallCosts[$tier][$region]
        }
        # Return Standard as fallback
        return [ALZConfig]::FirewallCosts["Standard"]["eastus"]
    }

    static [decimal] GetComplianceCostMultiplier([string]$variant) {
        if ([ALZConfig]::ComplianceVariants.ContainsKey($variant)) {
            return [ALZConfig]::ComplianceVariants[$variant].costMultiplier
        }
        return 1.0
    }

    static [string] GetComplianceFirewallTier([string]$variant) {
        if ([ALZConfig]::ComplianceVariants.ContainsKey($variant)) {
            return [ALZConfig]::ComplianceVariants[$variant].firewallTier
        }
        return "Standard"
    }

    static [hashtable] ValidateRegion([string]$region) {
        if ([ALZConfig]::RegionMapping.ContainsKey($region)) {
            return @{
                valid   = $true
                code    = [ALZConfig]::RegionMapping[$region].code
                name    = [ALZConfig]::RegionMapping[$region].name
            }
        }
        return @{
            valid   = $false
            message = "Region '$region' not supported"
            supportedRegions = ([ALZConfig]::RegionMapping.Keys -join ", ")
        }
    }

    static [array] GetSupportedRegions() {
        return [ALZConfig]::RegionMapping.Keys
    }

    static [array] GetSupportedComplianceVariants() {
        return [ALZConfig]::ComplianceVariants.Keys
    }

    static [hashtable] CalculateMonthlyEstimate([string]$primaryRegion, [string]$secondaryRegion, [string]$complianceVariant, [array]$enabledModules) {
        $primaryMultiplier = [ALZConfig]::GetRegionCostMultiplier($primaryRegion)
        $complianceMultiplier = [ALZConfig]::GetComplianceCostMultiplier($complianceVariant)
        $firewallTier = [ALZConfig]::GetComplianceFirewallTier($complianceVariant)

        $primaryCost = 0
        $secondaryCost = 0

        # Calculate primary region costs
        foreach ($module in $enabledModules) {
            if ([ALZConfig]::Modules.ContainsKey($module)) {
                $moduleCost = [ALZConfig]::Modules[$module].cost
                if ($moduleCost -ne "variable") {
                    $primaryCost += $moduleCost * $complianceMultiplier
                }
            }
        }

        # Add firewall cost for primary
        $firewallCost = [ALZConfig]::GetFirewallCost($firewallTier, $primaryRegion)
        $primaryCost += $firewallCost * $complianceMultiplier

        # Apply regional cost multiplier
        $primaryCost = $primaryCost * $primaryMultiplier

        # Calculate secondary region costs (if enabled)
        if ([ALZConfig]::SecondaryRegionConfig.enabled) {
            $secondaryFirewallTier = [ALZConfig]::SecondaryRegionConfig.firewallTier
            $secondaryFirewallCost = [ALZConfig]::GetFirewallCost($secondaryFirewallTier, $secondaryRegion)
            $secondaryCost = $secondaryFirewallCost * [ALZConfig]::GetRegionCostMultiplier($secondaryRegion)
        }

        $totalCost = $primaryCost + $secondaryCost

        return @{
            primaryRegionCost    = [Math]::Round($primaryCost, 2)
            secondaryRegionCost  = [Math]::Round($secondaryCost, 2)
            totalMonthlyCost     = [Math]::Round($totalCost, 2)
            complianceMultiplier = $complianceMultiplier
            primaryRegion        = $primaryRegion
            secondaryRegion      = $secondaryRegion
            variant              = $complianceVariant
        }
    }
}

# ============================================================================
# EXPORT MODULE MEMBERS
# ============================================================================
Export-ModuleMember -Variable ALZConfig
