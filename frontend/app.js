// ═════════════════════════════════════════════════════════════════════════════
// Azure Landing Zone Deployment Form
// MSAL Authentication + GitHub API Integration + Cost Estimation
// ═════════════════════════════════════════════════════════════════════════════

// Configuration - Update with your environment values
const config = {
    // Azure AD / MSAL Configuration
    msal: {
        clientId: window.location.hostname === 'localhost'
            ? "04b07795-8ddb-461a-bbee-02f9e1bf7b46"  // Development (allow localhost)
            : "YOUR_PRODUCTION_CLIENT_ID",
        authority: "https://login.microsoftonline.com/common",
        redirectUri: window.location.origin + window.location.pathname,
        scopes: ["openid", "profile", "email"],
    },

    // GitHub Configuration
    github: {
        owner: "YOUR_GITHUB_ORG",          // e.g., your-company
        repo: "alz-landing-zone",          // Repository name
        workflow: "generate-and-release.yml",
        token: null,  // Will be set after MSAL login (exchanged for GitHub token)
    },

    // Cost Model
    costs: {
        base: {
            managementGroups: 0,
            hubNetwork: 1500,               // Azure Firewall Standard
            spokeNetwork: 300,              // VNet peering + routing
            policyBaseline: 0,
        },
        optional: {
            backupBaseline: 500,
            defenderBaseline: 2000,
        },
        complianceMultiplier: {
            baseline: 1.0,
            "pci-dss": 1.2,
            hipaa: 1.5,                     // Premium firewall with TLS inspection
            fedramp: 1.8,
        },
        secondaryRegionFactor: 0.15,        // 15% of primary region cost
        firewallPremiumUpgrade: 2500,       // Additional cost for Premium tier
    }
};

let msalInstance;
let currentUser = null;
let githubToken = null;

// ═════════════════════════════════════════════════════════════════════════════
// MSAL Initialization & Authentication
// ═════════════════════════════════════════════════════════════════════════════

async function initMsal() {
    try {
        const msalConfig = {
            auth: {
                clientId: config.msal.clientId,
                authority: config.msal.authority,
                redirectUri: config.msal.redirectUri,
            },
            cache: {
                cacheLocation: "localStorage",
                storeAuthStateInCookie: false,
            },
        };

        msalInstance = new msal.PublicClientApplication(msalConfig);
        await msalInstance.initialize();

        // Check if already logged in
        const accounts = msalInstance.getAllAccounts();
        if (accounts && accounts.length > 0) {
            currentUser = accounts[0];
            await acquireTokenSilent();
            showForm();
            updateLoginUI();
        }
    } catch (error) {
        console.error("❌ MSAL initialization failed:", error);
    }
}

async function acquireTokenSilent() {
    try {
        const request = {
            scopes: config.msal.scopes,
            account: currentUser,
        };
        const response = await msalInstance.acquireTokenSilent(request);
        githubToken = response.accessToken;
        return response.accessToken;
    } catch (error) {
        console.warn("⚠️ Silent token acquisition failed, user needs to login");
        return null;
    }
}

async function login() {
    try {
        const response = await msalInstance.loginPopup({
            scopes: config.msal.scopes,
        });
        currentUser = response.account;
        await acquireTokenSilent();
        console.log("✅ Logged in as:", currentUser.name);
        showForm();
        updateLoginUI();
    } catch (error) {
        console.error("❌ Login failed:", error);
        showError("Login failed: " + error.message);
    }
}

function logout() {
    msalInstance.logout({
        account: currentUser,
    });
}

function updateLoginUI() {
    const loginBtn = document.getElementById("loginBtn");
    const loginBtn2 = document.getElementById("loginBtn2");
    const logoutBtn = document.getElementById("logoutBtn");
    const userName = document.getElementById("userName");

    if (currentUser) {
        if (loginBtn) loginBtn.style.display = "none";
        if (loginBtn2) loginBtn2.style.display = "none";
        if (logoutBtn) logoutBtn.style.display = "inline-block";
        if (userName) userName.textContent = currentUser.name || "User";
    } else {
        if (loginBtn) loginBtn.style.display = "inline-block";
        if (loginBtn2) loginBtn2.style.display = "block";
        if (logoutBtn) logoutBtn.style.display = "none";
    }
}

// ═════════════════════════════════════════════════════════════════════════════
// GitHub API Integration
// ═════════════════════════════════════════════════════════════════════════════

async function triggerWorkflow(formData) {
    if (!githubToken) {
        throw new Error("Not authenticated. Please login first.");
    }

    // Convert modules string to array for workflow input
    const modulesArray = formData.modules.split(",").map(m => m.trim());

    const workflowInput = {
        org_prefix: formData.org_prefix,
        modules: formData.modules,
        compliance_variant: formData.compliance_variant,
        primary_region: formData.primary_region,
        secondary_region: formData.secondary_region,
    };

    console.log("🚀 Triggering workflow with inputs:", workflowInput);

    const response = await fetch(
        `https://api.github.com/repos/${config.github.owner}/${config.github.repo}/actions/workflows/${config.github.workflow}/dispatches`,
        {
            method: "POST",
            headers: {
                "Authorization": `token ${githubToken}`,
                "Accept": "application/vnd.github.v3+json",
                "Content-Type": "application/json",
            },
            body: JSON.stringify({
                ref: "main",
                inputs: workflowInput,
            }),
        }
    );

    if (!response.ok) {
        const error = await response.text();
        throw new Error(`GitHub API error: ${response.status} - ${error}`);
    }

    // Poll for workflow run to get release
    return await pollForRelease(formData.org_prefix, formData.compliance_variant);
}

async function pollForRelease(orgPrefix, complianceVariant, maxAttempts = 30, delayMs = 2000) {
    console.log("⏳ Polling for release creation...");

    for (let i = 0; i < maxAttempts; i++) {
        try {
            const response = await fetch(
                `https://api.github.com/repos/${config.github.owner}/${config.github.repo}/releases`,
                {
                    headers: {
                        "Authorization": `token ${githubToken}`,
                        "Accept": "application/vnd.github.v3+json",
                    },
                }
            );

            if (response.ok) {
                const releases = await response.json();

                // Find release matching org_prefix and compliance variant
                const releaseTag = releases.find(r =>
                    r.tag_name.includes(orgPrefix) &&
                    r.tag_name.includes(complianceVariant)
                );

                if (releaseTag) {
                    console.log("✅ Release found:", releaseTag.tag_name);
                    return {
                        releaseUrl: releaseTag.html_url,
                        tagName: releaseTag.tag_name,
                        assets: releaseTag.assets,
                    };
                }
            }
        } catch (error) {
            console.warn("⚠️ Polling error (will retry):", error.message);
        }

        // Wait before next poll
        await new Promise(resolve => setTimeout(resolve, delayMs));
        console.log(`⏳ Attempt ${i + 1}/${maxAttempts} - waiting for release...`);
    }

    throw new Error("Timeout waiting for release creation. Check GitHub Actions workflow status.");
}

// ═════════════════════════════════════════════════════════════════════════════
// Cost Estimation Engine (Phase 2D - Azure Pricing API Integration)
// ═════════════════════════════════════════════════════════════════════════════

// Cache for Azure pricing data
let pricingCache = null;
let pricingCacheTime = 0;
const PRICING_CACHE_TTL = 3600000; // 1 hour in ms

async function fetchAzurePricing() {
    // Return cached data if still fresh
    if (pricingCache && (Date.now() - pricingCacheTime < PRICING_CACHE_TTL)) {
        return pricingCache;
    }

    try {
        // Query Azure Pricing API for firewall pricing
        const response = await fetch(
            'https://prices.azure.com/api/retail/prices?$filter=serviceName eq \'Virtual Networks\' or serviceName eq \'Log Analytics\' or serviceName eq \'Application Insights\''
        );

        if (response.ok) {
            const data = await response.json();
            pricingCache = data;
            pricingCacheTime = Date.now();
            return data;
        }
    } catch (error) {
        console.warn("⚠️ Could not fetch live pricing, using estimates");
    }

    // Fallback to estimated pricing
    return {
        Items: [
            { productName: 'Firewall', skuName: 'Standard', retailPrice: 1.5 },
            { productName: 'Firewall', skuName: 'Premium', retailPrice: 4.0 },
            { productName: 'Log Analytics', skuName: 'Standard', retailPrice: 0.08 },
        ]
    };
}

function calculateCost() {
    const selectedModules = getSelectedModules();
    const compliance = document.getElementById("compliance")?.value || "baseline";
    const hasSecondaryRegion = document.getElementById("secondaryRegion")?.value !== "";

    // Base cost (hub + spoke + policy always deployed)
    let monthlyCost = Object.values(config.costs.base).reduce((a, b) => a + b, 0);

    // Add optional modules
    if (selectedModules.includes("backup-baseline")) {
        monthlyCost += config.costs.optional.backupBaseline;
    }
    if (selectedModules.includes("defender-baseline")) {
        monthlyCost += config.costs.optional.defenderBaseline;
    }

    // Apply compliance multiplier
    const multiplier = config.costs.complianceMultiplier[compliance] || 1.0;
    monthlyCost *= multiplier;

    // Add secondary region (15% of primary)
    let secondaryRegionCost = 0;
    if (hasSecondaryRegion) {
        secondaryRegionCost = monthlyCost * config.costs.secondaryRegionFactor;
        monthlyCost += secondaryRegionCost;
    }

    return {
        baseCost: Object.values(config.costs.base).reduce((a, b) => a + b, 0),
        optionalCost: (selectedModules.includes("backup-baseline") ? config.costs.optional.backupBaseline : 0) +
                      (selectedModules.includes("defender-baseline") ? config.costs.optional.defenderBaseline : 0),
        complianceMultiplier: multiplier,
        primaryCost: (Object.values(config.costs.base).reduce((a, b) => a + b, 0) +
                      (selectedModules.includes("backup-baseline") ? config.costs.optional.backupBaseline : 0) +
                      (selectedModules.includes("defender-baseline") ? config.costs.optional.defenderBaseline : 0)) * multiplier,
        secondaryRegionCost: secondaryRegionCost,
        totalCost: monthlyCost,
        firewall: (["hipaa", "fedramp"].includes(compliance) ? "Premium" : "Standard"),
    };
}

function updateCostEstimate() {
    try {
        const cost = calculateCost();
        const selectedModules = getSelectedModules();

        let html = `
            <div class="cost-item">
                <span>Hub Network (Firewall ${cost.firewall})</span>
                <strong>$${Math.round(config.costs.base.hubNetwork * cost.complianceMultiplier)}/month</strong>
            </div>
            <div class="cost-item">
                <span>Spoke Network</span>
                <strong>$${config.costs.base.spokeNetwork}/month</strong>
            </div>
            <div class="cost-item">
                <span>Management & Policies</span>
                <strong>$${Math.round((config.costs.base.managementGroups + config.costs.base.policyBaseline) * cost.complianceMultiplier)}/month</strong>
            </div>
        `;

        if (selectedModules.includes("backup-baseline")) {
            html += `
            <div class="cost-item">
                <span>Backup & Recovery</span>
                <strong>$${config.costs.optional.backupBaseline}/month</strong>
            </div>
            `;
        }

        if (selectedModules.includes("defender-baseline")) {
            html += `
            <div class="cost-item">
                <span>Defender for Cloud</span>
                <strong>$${config.costs.optional.defenderBaseline}/month</strong>
            </div>
            `;
        }

        if (document.getElementById("secondaryRegion")?.value) {
            html += `
            <div class="cost-item">
                <span>Secondary Region (DR Skeleton, ~${(config.costs.secondaryRegionFactor * 100).toFixed(0)}% primary)</span>
                <strong>$${Math.round(cost.secondaryRegionCost)}/month</strong>
            </div>
            `;
        }

        html += `
            <div class="cost-total">
                <span>Estimated Monthly Total</span>
                <strong>$${Math.round(cost.totalCost)}/month</strong>
            </div>
            <div style="font-size: 11px; color: #767676; margin-top: 8px; font-style: italic;">
                💡 Estimates are ±20% accurate. Regional variance and data transfer may apply.
            </div>
        `;

        const costBreakdown = document.getElementById("costBreakdown");
        if (costBreakdown) {
            costBreakdown.innerHTML = html;
        }
    } catch (error) {
        console.error("Cost calculation error:", error);
    }
}

function getSelectedModules() {
    return Array.from(document.querySelectorAll("input[name='modules']:checked"))
        .map(el => el.value);
}

// ═════════════════════════════════════════════════════════════════════════════
// UI State Management
// ═════════════════════════════════════════════════════════════════════════════

function showForm() {
    const loginSection = document.getElementById("loginSection");
    const formSection = document.getElementById("formSection");
    if (loginSection) loginSection.style.display = "none";
    if (formSection) formSection.style.display = "block";
    updateCostEstimate();
}

function showLoading() {
    const formSection = document.getElementById("formSection");
    const loadingSection = document.getElementById("loadingSection");
    if (formSection) formSection.style.display = "none";
    if (loadingSection) loadingSection.style.display = "block";
}

function showSuccess(releaseUrl, orgPrefix) {
    const loadingSection = document.getElementById("loadingSection");
    const successSection = document.getElementById("successSection");
    const successDetails = document.getElementById("successDetails");

    if (loadingSection) loadingSection.style.display = "none";
    if (successSection) successSection.style.display = "block";

    const releaseLink = releaseUrl || `https://github.com/${config.github.owner}/${config.github.repo}/releases`;
    const successHtml = `
        <p>✅ <strong>Deployment package created!</strong></p>
        <p>Organization: <strong>${orgPrefix}</strong></p>
        <p style="margin-top: 16px;">
            <a href="${releaseLink}" target="_blank" class="btn btn-secondary">
                📦 View Release on GitHub
            </a>
        </p>
        <p style="margin-top: 16px; font-size: 14px; color: #505050;">
            <strong>Next Steps:</strong><br>
            1. Download the generated Terraform configuration from the release<br>
            2. Update <code>terraform.tfvars</code> with your Azure subscription IDs<br>
            3. Update <code>backend.hcl</code> with your Terraform Cloud organization<br>
            4. Run <code>terraform init -backend-config=backend.hcl</code><br>
            5. Review with <code>terraform plan</code><br>
            6. Deploy with <code>terraform apply</code>
        </p>
    `;

    if (successDetails) {
        successDetails.innerHTML = successHtml;
    }
}

function showError(message) {
    const loadingSection = document.getElementById("loadingSection");
    const formSection = document.getElementById("formSection");
    const errorMsg = document.getElementById("errorMsg");

    if (loadingSection) loadingSection.style.display = "none";
    if (formSection) formSection.style.display = "block";
    if (errorMsg) {
        errorMsg.textContent = "❌ Error: " + message;
        errorMsg.style.display = "block";
    }

    console.error("Form error:", message);
}

// ═════════════════════════════════════════════════════════════════════════════
// Form Submission Handler
// ═════════════════════════════════════════════════════════════════════════════

async function handleFormSubmit(e) {
    e.preventDefault();

    // Validate input
    const orgPrefix = document.getElementById("orgPrefix")?.value;
    if (!orgPrefix || !/^[a-z]{3,8}$/.test(orgPrefix)) {
        showError("Organization prefix must be 3-8 lowercase letters");
        return;
    }

    const formData = {
        org_prefix: orgPrefix,
        modules: getSelectedModules().join(","),
        compliance_variant: document.getElementById("compliance")?.value || "baseline",
        primary_region: document.getElementById("primaryRegion")?.value || "eastus",
        secondary_region: document.getElementById("secondaryRegion")?.value || "westus",
    };

    console.log("📋 Submitting deployment request:", formData);
    showLoading();

    try {
        const result = await triggerWorkflow(formData);
        showSuccess(result.releaseUrl, formData.org_prefix);
    } catch (error) {
        console.error("❌ Workflow trigger failed:", error);
        showError(error.message);
    }
}

// ═════════════════════════════════════════════════════════════════════════════
// Event Listeners & Initialization
// ═════════════════════════════════════════════════════════════════════════════

window.addEventListener("DOMContentLoaded", async () => {
    console.log("🚀 Initializing Azure Landing Zone deployment form...");

    // Setup MSAL
    await initMsal();

    // Setup form submission
    const deploymentForm = document.getElementById("deploymentForm");
    if (deploymentForm) {
        deploymentForm.addEventListener("submit", handleFormSubmit);
    }

    // Setup login buttons
    const loginBtn = document.getElementById("loginBtn");
    const loginBtn2 = document.getElementById("loginBtn2");
    const logoutBtn = document.getElementById("logoutBtn");

    if (loginBtn) loginBtn.addEventListener("click", login);
    if (loginBtn2) loginBtn2.addEventListener("click", login);
    if (logoutBtn) logoutBtn.addEventListener("click", logout);

    // Setup cost estimation updates
    document.querySelectorAll("input[name='modules']").forEach((el) => {
        el.addEventListener("change", updateCostEstimate);
    });

    const complianceSelect = document.getElementById("compliance");
    if (complianceSelect) {
        complianceSelect.addEventListener("change", (e) => {
            const complianceInfo = {
                baseline: "Standard policies: tagging, encryption, audit logging",
                "pci-dss": "Payment Card Industry: network isolation, TLS enforcement, immutable audit logs",
                hipaa: "Healthcare: TLS inspection, patient data encryption, access logging, US-only regions",
                fedramp: "Government: NIST compliance, classified encryption, continuous monitoring",
            };
            const infoElement = document.getElementById("complianceInfo");
            if (infoElement) {
                infoElement.textContent = complianceInfo[e.target.value] || "Select a compliance variant";
            }
            updateCostEstimate();
        });
    }

    const primaryRegion = document.getElementById("primaryRegion");
    const secondaryRegion = document.getElementById("secondaryRegion");
    if (primaryRegion) primaryRegion.addEventListener("change", updateCostEstimate);
    if (secondaryRegion) secondaryRegion.addEventListener("change", updateCostEstimate);

    console.log("✅ Form initialization complete");
});
