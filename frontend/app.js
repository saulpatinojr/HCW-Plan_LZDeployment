// ═════════════════════════════════════════════════════════════════════════════
// Official Azure Landing Zones Configuration Generator
// Grounded in official ALZ Terraform modules and policy assignments
// ═════════════════════════════════════════════════════════════════════════════

// Official ALZ Policy Assignments (from https://azure.github.io/Azure-Landing-Zones/policy/policyassignments/)
const officialPolicies = {
  "Intermediate Root": [
    { id: "Deploy-MDFC", name: "Deploy Microsoft Defender for Cloud configuration", effects: ["DeployIfNotExists"], enabled: true },
    { id: "Deploy-MDEndpoints", name: "Deploy Microsoft Defender for Endpoint agent", effects: ["DeployIfNotExists"], enabled: true },
    { id: "Deploy-MDEndpointsAMA", name: "Configure Defender for Endpoint integration with MDfC", effects: ["DeployIfNotExists"], enabled: true },
    { id: "Deploy-Diag-Logs", name: "Enable allLogs category resource logging to Log Analytics", effects: ["DeployIfNotExists"], enabled: true },
    { id: "Microsoft-Cloud-Security-Benchmark", name: "Microsoft Cloud Security Benchmark", effects: ["Audit", "AuditIfNotExists", "Disabled"], enabled: true },
    { id: "Configure-ATP-OSS-DB", name: "Configure Advanced Threat Protection - OSS Databases", effects: ["DeployIfNotExists"], enabled: true },
    { id: "Configure-Defender-SQL", name: "Configure Azure Defender - SQL Servers", effects: ["DeployIfNotExists"], enabled: true },
    { id: "Deploy-ActivityLog-Diags", name: "Deploy Activity Log Diagnostics to Log Analytics", effects: ["DeployIfNotExists"], enabled: true },
    { id: "Deny-Classic-Resources", name: "Deny the deployment of classic resources", effects: ["Deny"], enabled: true },
    { id: "Enforce-ACSB", name: "Enforce Azure Compute Security Baseline compliance auditing", effects: ["AuditIfNotExists"], enabled: true },
  ],
  "Platform": [
    { id: "Enforce-KV-Guardrails", name: "Enforce recommended guardrails for Azure Key Vault", effects: ["Deny", "Audit"], enabled: true },
    { id: "Enforce-Backup", name: "Enforce enhanced recovery and backup policies", effects: ["Audit"], enabled: true },
    { id: "Subnets-Private", name: "Subnets should be private", effects: ["Audit", "Deny"], enabled: true },
    { id: "DDoS-Protection", name: "Virtual networks should be protected by Azure DDoS Protection Standard", effects: ["Modify"], enabled: true },
    { id: "AMBA-Connectivity", name: "Deploy Azure Monitor Baseline Alerts for Connectivity", effects: ["DeployIfNotExists"], enabled: true },
    { id: "AMBA-Management", name: "Deploy Azure Monitor Baseline Alerts for Management", effects: ["DeployIfNotExists"], enabled: true },
    { id: "AMBA-Identity", name: "Deploy Azure Monitor Baseline Alerts for Identity", effects: ["DeployIfNotExists"], enabled: true },
    { id: "Deny-PublicIP", name: "Deny the creation of public IP", effects: ["Deny"], enabled: true },
    { id: "Deny-MgmtPorts", name: "Management port access from the Internet should be blocked", effects: ["Deny"], enabled: true },
    { id: "Deny-SubnetNoNSG", name: "Subnets should have a Network Security Group", effects: ["Deny"], enabled: true },
    { id: "Configure-VMBackup", name: "Configure backup on virtual machines", effects: ["DeployIfNotExists"], enabled: true },
    { id: "Enable-AMAforVMs", name: "Enable Azure Monitor for VMs with Azure Monitoring Agent", effects: ["DeployIfNotExists"], enabled: true },
    { id: "Enable-AMAforVMSS", name: "Enable Azure Monitor for VMSS with Azure Monitoring Agent", effects: ["DeployIfNotExists"], enabled: true },
    { id: "Enable-AMAforHybrid", name: "Enable Azure Monitor for Hybrid VMs with AMA", effects: ["DeployIfNotExists"], enabled: true },
    { id: "Deny-Unmanaged-Disk", name: "Deny virtual machines and virtual machine scale sets not using OS Managed Disk", effects: ["Deny"], enabled: true },
  ],
  "Landing Zones": [
    { id: "Deny-Deploy-TLS", name: "Deny or Deploy and append TLS/SSL enforcement", effects: ["Audit", "AuditIfNotExists", "DeployIfNotExists", "Deny"], enabled: true },
    { id: "Deny-MgmtPorts-LZ", name: "Management port access from the Internet should be blocked", effects: ["Deny"], enabled: true },
    { id: "Deny-SubnetNoNSG-LZ", name: "Subnets should have a Network Security Group", effects: ["Deny"], enabled: true },
    { id: "Deny-IPForwarding", name: "Network interfaces should disable IP forwarding", effects: ["Deny"], enabled: true },
    { id: "Secure-Storage-HTTPS", name: "Secure transfer to storage accounts should be enabled", effects: ["Deny"], enabled: true },
    { id: "Deploy-AKS-Policy", name: "Deploy Azure Policy Add-on to Azure Kubernetes Service clusters", effects: ["DeployIfNotExists"], enabled: true },
    { id: "Configure-SQLAudit", name: "Configure SQL servers to have auditing enabled to Log Analytics", effects: ["DeployIfNotExists"], enabled: true },
    { id: "Deploy-SQLThreat", name: "Deploy Threat Detection on SQL servers", effects: ["DeployIfNotExists"], enabled: true },
    { id: "Deploy-SQLTDE", name: "Deploy TDE on SQL servers", effects: ["DeployIfNotExists"], enabled: true },
    { id: "DDoS-Protection-LZ", name: "Virtual networks should be protected by Azure DDoS Protection Standard", effects: ["Modify"], enabled: true },
    { id: "AKS-No-Privileged", name: "Kubernetes cluster should not allow privileged containers", effects: ["Deny"], enabled: true },
    { id: "AKS-No-PrivEsc", name: "Kubernetes clusters should not allow container privilege escalation", effects: ["Deny"], enabled: true },
    { id: "AKS-HTTPS-Only", name: "Kubernetes clusters should be accessible only over HTTPS", effects: ["Deny"], enabled: true },
    { id: "Enforce-KV-Guardrails-LZ", name: "Enforce recommended guardrails for Azure Key Vault", effects: ["Deny", "Audit"], enabled: true },
    { id: "AMBA-LandingZone", name: "Deploy Azure Monitor Baseline Alerts for Landing Zone", effects: ["DeployIfNotExists"], enabled: true },
  ],
  "Landing Zones/Corp": [
    { id: "Deny-PublicPaaS", name: "Public network access should be disabled for PaaS services", effects: ["Deny"], enabled: true },
    { id: "Configure-PrivateDNS", name: "Configure Azure PaaS services to use private DNS zones", effects: ["DeployIfNotExists"], enabled: true },
    { id: "Deny-PublicIP-NIC", name: "Deny network interfaces having a public IP associated", effects: ["Deny"], enabled: true },
    { id: "Audit-PrivateLinkDNS", name: "Audit the creation of Private Link Private DNS Zones", effects: ["Audit"], enabled: true },
    { id: "Deny-HybridNetworking", name: "Deny the deployment of vWAN/ER/VPN gateway resources", effects: ["Deny"], enabled: true },
  ],
  "Specialized": [
    { id: "Sandbox-Guardrails", name: "Enforce ALZ Sandbox Guardrails", effects: ["Deny"], enabled: false },
    { id: "Decommissioned-Guardrails", name: "Enforce ALZ Decommissioned Guardrails", effects: ["Deny", "DeployIfNotExists"], enabled: false },
  ]
};

// ═════════════════════════════════════════════════════════════════════════════
// Official ALZ Generator Class
// ═════════════════════════════════════════════════════════════════════════════

class OfficialALZGenerator {
  constructor() {
    this.formData = null;
    this.init();
  }

  init() {
    this.setupEventListeners();
    this.populatePolicies();
    this.setupRegionPairing();
    this.updateNamingExamples();
    this.showForm();
  }

  setupEventListeners() {
    const generateBtn = document.getElementById("generateBtn");
    const downloadBtn = document.getElementById("downloadBtn");
    const copyBtn = document.getElementById("copyBtn");
    const regenerateBtn = document.getElementById("regenerateBtn");

    if (generateBtn) generateBtn.addEventListener("click", () => this.generate());
    if (downloadBtn) downloadBtn.addEventListener("click", () => this.download());
    if (copyBtn) copyBtn.addEventListener("click", () => this.copyToClipboard());
    if (regenerateBtn) regenerateBtn.addEventListener("click", () => this.backToForm());
  }

  setupRegionPairing() {
    const regionPairs = {
      "eastus2": "westus",
      "westus": "eastus2",
      "uksouth": "northeurope",
      "australiaeast": "australiasoutheast",
      "southeastasia": "eastasia",
      "centralus": "eastus",
      "canadacentral": "canadaeast",
      "northeurope": "westeurope",
      "westeurope": "northeurope",
      "eastasia": "southeastasia",
      "canadaeast": "canadacentral",
    };

    const primarySelect = document.getElementById("primaryRegion");
    if (primarySelect) {
      primarySelect.addEventListener("change", () => {
        const secondary = document.getElementById("secondaryRegion");
        if (secondary) {
          const paired = regionPairs[primarySelect.value] || primarySelect.value;
          secondary.value = paired;
          updateNamingExamples();
        }
      });
      // Set initial secondary region
      const paired = regionPairs[primarySelect.value] || "westus";
      document.getElementById("secondaryRegion").value = paired;
    }
  }

  populatePolicies() {
    const container = document.getElementById("policyAssignments");
    if (!container) return;

    container.innerHTML = "";

    for (const [scope, policies] of Object.entries(officialPolicies)) {
      const scopeDiv = document.createElement("div");
      scopeDiv.className = "policy-scope";

      const scopeTitle = document.createElement("div");
      scopeTitle.className = "policy-scope-title";
      scopeTitle.textContent = scope;
      scopeDiv.appendChild(scopeTitle);

      policies.forEach((policy) => {
        const item = document.createElement("div");
        item.className = "policy-item";

        const info = document.createElement("div");
        info.className = "policy-info";

        const checkbox = document.createElement("input");
        checkbox.type = "checkbox";
        checkbox.className = "policy-checkbox";
        checkbox.name = `policy_${policy.id}`;
        checkbox.value = policy.id;
        checkbox.checked = policy.enabled;

        const details = document.createElement("div");
        details.className = "policy-details";

        const name = document.createElement("span");
        name.className = "policy-name";
        name.textContent = policy.name;

        const description = document.createElement("span");
        description.className = "policy-description";
        description.textContent = `Policy: ${policy.id}`;

        details.appendChild(name);
        details.appendChild(description);

        info.appendChild(checkbox);
        info.appendChild(details);
        item.appendChild(info);

        // Effect selector
        if (policy.effects.length > 1) {
          const effectDiv = document.createElement("div");
          effectDiv.className = "policy-effect";

          const label = document.createElement("label");
          label.textContent = "Effect:";

          const select = document.createElement("select");
          select.name = `policy_effect_${policy.id}`;
          policy.effects.forEach((effect) => {
            const option = document.createElement("option");
            option.value = effect;
            option.textContent = effect;
            select.appendChild(option);
          });

          effectDiv.appendChild(label);
          effectDiv.appendChild(select);
          item.appendChild(effectDiv);
        }

        scopeDiv.appendChild(item);
      });

      container.appendChild(scopeDiv);
    }
  }

  getFormData() {
    const primaryRegion = document.getElementById("primaryRegion")?.value || "westus";
    const secondaryRegion = document.getElementById("secondaryRegion")?.value || "eastus2";
    const allRegions = [primaryRegion, secondaryRegion];

    // Add any additional regions
    document.querySelectorAll('select[name="additionalRegion"]').forEach(select => {
      if (select.value && !allRegions.includes(select.value)) {
        allRegions.push(select.value);
      }
    });

    // Get all environment suffixes
    const envSuffixes = Array.from(document.querySelectorAll(".suffix-input"))
      .map(input => input.value)
      .filter(val => val.trim());

    if (envSuffixes.length === 0) {
      envSuffixes.push("prod");
    }

    return {
      orgName: document.getElementById("orgName")?.value || "Contoso",
      orgId: document.getElementById("orgId")?.value || "contoso",
      defenderEmail: document.getElementById("defenderEmail")?.value || "",
      primaryRegion: primaryRegion,
      secondaryRegion: secondaryRegion,
      allRegions: allRegions,
      networkTopology: document.querySelector('input[name="networkTopology"]:checked')?.value || "hub-spoke",
      firewallSku: document.querySelector('input[name="firewallSku"]:checked')?.value || "Standard",
      ddosProtection: document.getElementById("ddosProtection")?.checked ?? true,
      bastionHost: document.getElementById("bastionHost")?.checked ?? true,
      privateDnsZones: document.getElementById("privateDnsZones")?.checked ?? true,
      vnetGateway: document.getElementById("vnetGateway")?.checked ?? true,
      ama: document.getElementById("ama")?.checked ?? true,
      amba: document.getElementById("amba")?.checked ?? true,
      defenderPlans: document.getElementById("defenderPlans")?.checked ?? true,
      policies: this.getSelectedPolicies(),
      mgNames: {
        intRoot: document.getElementById("mgIntRoot")?.value || "",
        platform: document.getElementById("mgPlatform")?.value || "",
        connectivity: document.getElementById("mgConnectivity")?.value || "",
        identity: document.getElementById("mgIdentity")?.value || "",
        management: document.getElementById("mgManagement")?.value || "",
        landingZones: document.getElementById("mgLandingZones")?.value || "",
      },
      resourceNaming: {
        prefix: document.getElementById("resourcePrefix")?.value || "",
        envSuffixes: envSuffixes,
        instanceStart: parseInt(document.getElementById("instanceStart")?.value || "1"),
      },
      network: {
        hubCidr: document.getElementById("hubCidr")?.value || "10.0.0.0/16",
        spokeCidrs: (document.getElementById("spokeCidrs")?.value || "10.1.0.0/16").split("\n").filter(c => c.trim()),
      },
      tagging: {
        enabled: document.getElementById("tagEnforcement")?.checked ?? false,
        environment: document.getElementById("tagEnvironment")?.value || envSuffixes[0],
        owner: document.getElementById("tagOwner")?.value || "",
        costCenter: document.getElementById("tagCostCenter")?.value || "",
        application: document.getElementById("tagApplication")?.value || "",
      }
    };
  }

  getSelectedPolicies() {
    const policies = {};
    document.querySelectorAll('input.policy-checkbox:checked').forEach((checkbox) => {
      const policyId = checkbox.value;
      const effectSelect = document.querySelector(`select[name="policy_effect_${policyId}"]`);
      policies[policyId] = {
        enabled: true,
        effect: effectSelect?.value || this.getDefaultEffect(policyId)
      };
    });
    return policies;
  }

  getDefaultEffect(policyId) {
    for (const policies of Object.values(officialPolicies)) {
      const policy = policies.find(p => p.id === policyId);
      if (policy) return policy.effects[0];
    }
    return "Audit";
  }

  generateTfvars() {
    const data = this.getFormData();

    let tfvars = `# ═════════════════════════════════════════════════════════════════════════════
# Azure Landing Zones Platform Configuration (.tfvars)
# Generated: ${new Date().toISOString().split('T')[0]}
# Organization: ${data.orgName}
# Primary Region: ${data.primaryRegion}
# Secondary Region: ${data.secondaryRegion}
# ═════════════════════════════════════════════════════════════════════════════

# Organization Configuration
root_id   = "${data.orgId}"
root_name = "${data.orgName}"

# Starter Locations (Primary + Secondary + Additional)
starter_locations = [${data.allRegions.map(l => `"${l}"`).join(", ")}]

# Security Configuration
defender_email_security_contact = "${data.defenderEmail}"

# Network Configuration
enable_virtual_wan = ${data.networkTopology === "virtual-wan" ? "true" : "false"}
firewall_sku = "${data.firewallSku}"

# Feature Toggles
enable_ddos_protection          = ${data.ddosProtection}
enable_bastion_deployment       = ${data.bastionHost}
enable_private_dns_zones        = ${data.privateDnsZones}
enable_virtual_network_gateway  = ${data.vnetGateway}

# Monitoring & Security
enable_azure_monitoring_agent = ${data.ama}
enable_amba_deployment         = ${data.amba}
enable_defender_plans          = ${data.defenderPlans}

# Management Group Customization
custom_management_groups = {
`;

    if (data.mgNames.intRoot) tfvars += `  intermediate_root = "${data.mgNames.intRoot}"\n`;
    if (data.mgNames.platform) tfvars += `  platform = "${data.mgNames.platform}"\n`;
    if (data.mgNames.connectivity) tfvars += `  connectivity = "${data.mgNames.connectivity}"\n`;
    if (data.mgNames.identity) tfvars += `  identity = "${data.mgNames.identity}"\n`;
    if (data.mgNames.management) tfvars += `  management = "${data.mgNames.management}"\n`;
    if (data.mgNames.landingZones) tfvars += `  landing_zones = "${data.mgNames.landingZones}"\n`;

    tfvars += `}

# Resource Naming Configuration
custom_resource_names = {
  prefix                = "${data.resourceNaming.prefix || data.orgId}"
  environment_naming    = [${data.resourceNaming.envSuffixes.map(e => `"${e}"`).join(", ")}]
  instance_start_number = ${data.resourceNaming.instanceStart}
}

# Network Address Space
hub_vnet_cidr = "${data.network.hubCidr}"
spoke_vnet_cidr = [${data.network.spokeCidrs.map(c => `"${c.trim()}"`).join(", ")}]

# Policy Assignments
policy_assignments = {
`;

    for (const [policyId, config] of Object.entries(data.policies)) {
      tfvars += `  "${policyId}" = {\n`;
      tfvars += `    enabled = ${config.enabled}\n`;
      tfvars += `    effect  = "${config.effect}"\n`;
      tfvars += `  }\n`;
    }

    tfvars += `}

# Tags
tags = {
`;
    if (data.tagging.environment) tfvars += `  Environment = "${data.tagging.environment}"\n`;
    if (data.tagging.owner) tfvars += `  Owner = "${data.tagging.owner}"\n`;
    if (data.tagging.costCenter) tfvars += `  CostCenter = "${data.tagging.costCenter}"\n`;
    if (data.tagging.application) tfvars += `  Application = "${data.tagging.application}"\n`;

    tfvars += `}
`;

    return tfvars;
  }

  validate() {
    const data = this.getFormData();
    const errors = [];

    if (!data.orgId || !/^[a-z0-9]{3,20}$/.test(data.orgId)) {
      errors.push("Organization ID must be 3-20 lowercase alphanumeric characters");
    }
    if (!data.defenderEmail || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(data.defenderEmail)) {
      errors.push("Valid Defender email is required");
    }
    if (data.locations.length === 0) {
      errors.push("Select at least one location");
    }
    if (!data.network.hubCidr || !this.isValidCIDR(data.network.hubCidr)) {
      errors.push("Hub VNet CIDR must be a valid CIDR block (e.g., 10.0.0.0/16)");
    }
    if (data.network.spokeCidrs.length === 0 || !data.network.spokeCidrs.every(c => this.isValidCIDR(c))) {
      errors.push("Spoke VNet CIDRs must be valid CIDR blocks");
    }

    return errors;
  }

  isValidCIDR(cidr) {
    return /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}\/[0-9]{1,2}$/.test(cidr);
  }

  generate() {
    const errors = this.validate();
    if (errors.length > 0) {
      alert("Form validation errors:\n\n" + errors.join("\n"));
      return;
    }

    const tfvars = this.generateTfvars();
    const preview = document.getElementById("configPreview");
    if (preview) {
      preview.textContent = tfvars;
    }

    const form = document.getElementById("deploymentForm");
    const previewCard = document.getElementById("previewCard");
    if (form) form.classList.add("hidden");
    if (previewCard) previewCard.classList.remove("hidden");

    window.scrollTo(0, 0);
  }

  download() {
    const tfvars = this.generateTfvars();
    const orgId = document.getElementById("orgId")?.value || "alz";
    const filename = `${orgId}-alz-terraform.tfvars`;
    const element = document.createElement("a");
    element.setAttribute("href", "data:text/plain;charset=utf-8," + encodeURIComponent(tfvars));
    element.setAttribute("download", filename);
    element.style.display = "none";
    document.body.appendChild(element);
    element.click();
    document.body.removeChild(element);
  }

  copyToClipboard() {
    const tfvars = this.generateTfvars();
    navigator.clipboard.writeText(tfvars).then(() => {
      const copyBtn = document.getElementById("copyBtn");
      const originalText = copyBtn?.textContent;
      if (copyBtn) {
        copyBtn.textContent = "✓ Copied!";
        setTimeout(() => {
          copyBtn.textContent = originalText;
        }, 2000);
      }
    }).catch(err => {
      console.error("Failed to copy:", err);
      alert("Failed to copy to clipboard. Please try again.");
    });
  }

  backToForm() {
    const form = document.getElementById("deploymentForm");
    const previewCard = document.getElementById("previewCard");
    if (form) form.classList.remove("hidden");
    if (previewCard) previewCard.classList.add("hidden");
    window.scrollTo(0, 0);
  }

  showForm() {
    const formSection = document.getElementById("formSection");
    if (formSection) formSection.classList.remove("hidden");
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Global Helper Functions (called from HTML)
// ═════════════════════════════════════════════════════════════════════════════

function addEnvironmentSuffix() {
  const container = document.getElementById("environmentSuffixes");
  if (!container) return;

  const div = document.createElement("div");
  div.className = "suffix-input-group";

  const input = document.createElement("input");
  input.type = "text";
  input.className = "suffix-input";
  input.placeholder = "e.g., dev, test, staging";
  input.addEventListener("input", updateNamingExamples);

  const btn = document.createElement("button");
  btn.type = "button";
  btn.className = "btn btn-small";
  btn.textContent = "✕";
  btn.onclick = () => removeEnvironmentSuffix(btn);

  div.appendChild(input);
  div.appendChild(btn);
  container.appendChild(div);
}

function removeEnvironmentSuffix(btn) {
  const group = btn.parentElement;
  if (group) {
    group.remove();
    updateNamingExamples();
  }
}

function updateNamingExamples() {
  const prefix = document.getElementById("resourcePrefix")?.value || "org";
  const suffix = document.querySelector(".suffix-input")?.value || "prod";
  const instance = document.getElementById("instanceStart")?.value || "1";

  document.getElementById("exampleStorageAccount").textContent = `st${prefix}${suffix}${instance.padStart(3, "0")}`;
  document.getElementById("exampleVM").textContent = `vm-${prefix}-${suffix}-${instance.padStart(3, "0")}`;
  document.getElementById("exampleVNet").textContent = `vnet-${prefix}-${suffix}`;
  document.getElementById("exampleRG").textContent = `rg-${prefix}-${suffix}-eastus2`;

  // Auto-populate environment tag
  const tagEnv = document.getElementById("tagEnvironment");
  if (tagEnv) {
    tagEnv.value = suffix;
  }
}

function updateSecondaryRegionOptions() {
  // Already handled in setupRegionPairing
}

function toggleTaggingFields() {
  const enforcement = document.getElementById("tagEnforcement");
  const fields = document.getElementById("taggingFields");
  const additional = document.getElementById("additionalTags");

  if (fields) fields.classList.toggle("hidden-section", !enforcement.checked);
  if (additional) additional.classList.toggle("hidden-section", !enforcement.checked);
}

function addRegion() {
  const container = document.getElementById("additionalRegionsList");
  if (!container) return;

  const div = document.createElement("div");
  div.className = "region-item";

  const select = document.createElement("select");
  select.name = "additionalRegion";
  const regions = ["eastus2", "westus", "uksouth", "australiaeast", "southeastasia", "centralus", "canadacentral"];
  regions.forEach(region => {
    const option = document.createElement("option");
    option.value = region;
    option.textContent = region;
    select.appendChild(option);
  });

  const btn = document.createElement("button");
  btn.type = "button";
  btn.className = "btn btn-small";
  btn.textContent = "✕";
  btn.onclick = () => div.remove();

  div.appendChild(select);
  div.appendChild(btn);
  container.appendChild(div);
}

// ═════════════════════════════════════════════════════════════════════════════
// Initialize on page load
// ═════════════════════════════════════════════════════════════════════════════

document.addEventListener("DOMContentLoaded", () => {
  new OfficialALZGenerator();
});
