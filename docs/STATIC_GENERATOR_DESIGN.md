# HCW Landing Zone — Static HTML CSV Generator

**Purpose**: One-shot CLI-like tool: user fills form in browser → downloads CSV → passes to Terraform/GitHub Actions

**Architecture**: Pure HTML/CSS/JavaScript (no backend needed)  
**Deployment**: Single static file (can be hosted on GitHub Pages, served via GitHub, or run locally)  
**Output**: CSV file for Terraform consumption

---

## Architecture: Static Generator vs. Backend API

### ❌ Old Design (Backend API)
```
User Form (HTML)
    ↓
Backend API Server (Node.js/Express) ← Must build & host
    ↓ /api/bootstrap
Terraform Generator
    ↓
GitHub API Call (dispatch workflow)
    ↓
GitHub Actions (runs Terraform)
```

### ✅ New Design (Static Generator)
```
User Form (HTML/JS) ← Pure static file, runs in browser
    ↓
Generate CSV in Memory (JavaScript)
    ↓
Download CSV to User's Computer
    ↓
User passes CSV to Terraform (via --var-file or GitHub Actions input)
    ↓
GitHub Actions (runs Terraform with CSV)
```

**Benefits**:
- ✅ No backend server needed
- ✅ No authentication/RBAC issues
- ✅ Can work offline
- ✅ Users have CSV locally (auditability)
- ✅ Single static HTML file (trivial to deploy)
- ✅ Can be embedded in GitHub README

**Tradeoff**:
- ⚠️ User must manually upload CSV to GitHub / trigger workflow
- ⚠️ No real-time deployment status (but they can watch GitHub Actions UI)

---

## Flow: Static Generator Model

```
┌─────────────────────────────────────────────────────────────────┐
│                    USER'S BROWSER (Offline OK)                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  1. User opens index.html (can be local file://)                │
│     └─> Form loads (no server needed)                           │
│                                                                   │
│  2. User fills form:                                             │
│     ├─ Org Prefix: "contoso"                                    │
│     ├─ Modules: [hub-network, spoke-network, policy-baseline]   │
│     ├─ Compliance: "pci-dss"                                    │
│     ├─ Regions: eastus, westus                                  │
│     └─ Cost shown in real-time ✓                                │
│                                                                   │
│  3. User clicks "Generate Configuration"                         │
│     └─> JavaScript creates CSV in memory                        │
│                                                                   │
│  4. Browser downloads CSV file                                   │
│     └─> File: contoso-alz-config.csv                            │
│                                                                   │
│  5. User saves CSV (typically ~/Downloads/)                      │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
                            ↓
        ┌───────────────────┴───────────────────┐
        │                                        │
┌───────▼──────────────┐            ┌──────────▼─────────────┐
│  OPTION A:           │            │  OPTION B:             │
│  User's Local PC     │            │  GitHub Actions        │
├──────────────────────┤            ├────────────────────────┤
│ 1. Download CSV      │            │ 1. User forks repo     │
│ 2. Run terraform:    │            │ 2. Uploads CSV via:    │
│    terraform apply   │            │    - Commit to repo    │
│    --var-file=CSV    │            │    - GitHub UI         │
│ 3. Watch status      │            │ 3. Workflow reads CSV  │
│ 4. Outputs stored    │            │ 4. Runs terraform      │
│    locally           │            │ 5. Results in GitHub   │
└──────────────────────┘            └────────────────────────┘
```

---

## CSV Format (What Gets Generated)

### Simple Format (Human-Readable)
```csv
key,value
org_prefix,contoso
primary_region,eastus
secondary_region,westus
compliance_variant,pci-dss
deploy_hub_network,true
deploy_spoke_networks,true
deploy_policy_baseline,true
deploy_backup_baseline,false
deploy_defender_baseline,false
firewall_tier,Premium
tls_minimum_version,1.2
require_encryption_in_transit,true
cost_estimate_monthly,2160
```

### Alternative: HCL Format (Terraform-Native)
```hcl
org_prefix = "contoso"
primary_region = "eastus"
secondary_region = "westus"
compliance_variant = "pci-dss"

deploy_hub_network = true
deploy_spoke_networks = true
deploy_policy_baseline = true
deploy_backup_baseline = false
deploy_defender_baseline = false

firewall_tier = "Premium"
tls_minimum_version = "1.2"
require_encryption_in_transit = true
cost_estimate_monthly = 2160
```

### Alternative: JSON Format (Flexible)
```json
{
  "orgPrefix": "contoso",
  "primaryRegion": "eastus",
  "secondaryRegion": "westus",
  "complianceVariant": "pci-dss",
  "modules": {
    "hubNetwork": true,
    "spokeNetworks": true,
    "policyBaseline": true,
    "backupBaseline": false,
    "defenderBaseline": false
  },
  "derived": {
    "firewallTier": "Premium",
    "tlsMinimumVersion": "1.2",
    "requireEncryptionInTransit": true,
    "costEstimateMonthly": 2160
  }
}
```

**Recommendation**: Use **HCL format** (.tfvars) — Terraform natively understands it, no parsing needed.

---

## Implementation: Static HTML Generator

### Step 1: Modify frontend/index.html

Change the submit button:
```html
<!-- OLD -->
<button type="submit" class="btn btn-primary btn-large">Deploy to Azure</button>

<!-- NEW -->
<button type="button" class="btn btn-primary btn-large" id="generateBtn">
  Generate Configuration (Download CSV)
</button>
```

Add a preview section:
```html
<!-- NEW: Configuration Preview -->
<div class="card" id="previewCard" style="display:none;">
  <h3>Generated Configuration (Preview)</h3>
  <pre id="configPreview" style="background: #f3f2f1; padding: 12px; overflow: auto; max-height: 300px;"></pre>
  <div style="margin-top: 12px;">
    <button type="button" class="btn btn-primary" id="downloadBtn">
      ⬇️ Download as terraform.tfvars
    </button>
    <button type="button" class="btn btn-secondary" id="copyBtn">
      📋 Copy to Clipboard
    </button>
  </div>
</div>
```

### Step 2: Add Generator Logic to frontend/app.js

```javascript
// ═════════════════════════════════════════════════════════════════════════════
// CONFIGURATION GENERATOR (Pure JavaScript, no backend needed)
// ═════════════════════════════════════════════════════════════════════════════

class ConfigurationGenerator {
  constructor() {
    this.form = document.getElementById('deploymentForm');
    this.generateBtn = document.getElementById('generateBtn');
    this.downloadBtn = document.getElementById('downloadBtn');
    this.copyBtn = document.getElementById('copyBtn');
    this.previewCard = document.getElementById('previewCard');
    this.configPreview = document.getElementById('configPreview');
  }

  init() {
    this.generateBtn.addEventListener('click', () => this.generateAndPreview());
    this.downloadBtn.addEventListener('click', () => this.download());
    this.copyBtn.addEventListener('click', () => this.copyToClipboard());
  }

  // Collect form data
  getFormData() {
    const data = new FormData(this.form);
    
    // Get checked modules
    const modules = [];
    document.querySelectorAll('input[name="modules"]:checked').forEach(input => {
      modules.push(input.value);
    });

    return {
      orgPrefix: data.get('orgPrefix'),
      modules: modules,
      compliance: data.get('compliance'),
      primaryRegion: data.get('primaryRegion'),
      secondaryRegion: data.get('secondaryRegion'),
    };
  }

  // Derive computed values based on compliance
  computeValues(formData) {
    const complianceRules = {
      baseline: {
        firewallTier: 'Standard',
        tlsMinimumVersion: '1.2',
        requireEncryption: false,
      },
      'pci-dss': {
        firewallTier: 'Premium',
        tlsMinimumVersion: '1.2',
        requireEncryption: true,
      },
      hipaa: {
        firewallTier: 'Premium',
        tlsMinimumVersion: '1.2',
        requireEncryption: true,
      },
      fedramp: {
        firewallTier: 'Premium',
        tlsMinimumVersion: '1.2',
        requireEncryption: true,
      },
    };

    return complianceRules[formData.compliance] || complianceRules.baseline;
  }

  // Generate terraform.tfvars format
  generateTfvars(formData, computed) {
    const lines = [
      '# HCW Landing Zone Configuration',
      `# Generated: ${new Date().toISOString()}`,
      `# Organization: ${formData.orgPrefix}`,
      '',
      '# Organization Settings',
      `org_prefix = "${formData.orgPrefix}"`,
      `primary_region = "${formData.primaryRegion}"`,
      `secondary_region = "${formData.secondaryRegion}"`,
      `compliance_variant = "${formData.compliance}"`,
      '',
      '# Module Deployment',
      `deploy_hub_network = ${formData.modules.includes('hub-network')}`,
      `deploy_spoke_networks = ${formData.modules.includes('spoke-network')}`,
      `deploy_policy_baseline = ${formData.modules.includes('policy-baseline')}`,
      `deploy_backup_baseline = ${formData.modules.includes('backup-baseline')}`,
      `deploy_defender_baseline = ${formData.modules.includes('defender-baseline')}`,
      '',
      '# Computed Values (Derived from Compliance)',
      `firewall_tier = "${computed.firewallTier}"`,
      `tls_minimum_version = "${computed.tlsMinimumVersion}"`,
      `require_encryption_in_transit = ${computed.requireEncryption}`,
      '',
      '# Cost Estimate',
      `cost_estimate_monthly = ${this.calculateCost(formData)}`,
      '',
      '# Tags',
      `environment = "prod"`,
      `managed_by = "terraform"`,
      `deployed_date = "${new Date().toISOString().split('T')[0]}"`,
    ];

    return lines.join('\n');
  }

  // Calculate cost (same logic as before)
  calculateCost(formData) {
    let cost = 0;
    
    // Base costs
    if (formData.modules.includes('hub-network')) cost += 1500;
    if (formData.modules.includes('spoke-network')) cost += 300;
    
    // Optional costs
    if (formData.modules.includes('backup-baseline')) cost += 500;
    if (formData.modules.includes('defender-baseline')) cost += 2000;
    
    // Compliance multiplier
    const multipliers = {
      baseline: 1.0,
      'pci-dss': 1.2,
      hipaa: 1.5,
      fedramp: 1.8,
    };
    cost *= multipliers[formData.compliance] || 1.0;
    
    // Secondary region (15% of primary)
    cost += cost * 0.15;
    
    return Math.round(cost);
  }

  // Generate and show preview
  generateAndPreview() {
    // Validate form
    if (!this.form.checkValidity()) {
      alert('Please fill all required fields');
      return;
    }

    const formData = this.getFormData();
    const computed = this.computeValues(formData);
    const tfvars = this.generateTfvars(formData, computed);

    // Show preview
    this.configPreview.textContent = tfvars;
    this.previewCard.style.display = 'block';

    // Scroll to preview
    this.previewCard.scrollIntoView({ behavior: 'smooth' });

    // Store for download
    this.lastConfig = tfvars;
    this.lastFilename = `${formData.orgPrefix}-alz-terraform.tfvars`;
  }

  // Download as file
  download() {
    if (!this.lastConfig) {
      alert('Generate configuration first');
      return;
    }

    const blob = new Blob([this.lastConfig], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = this.lastFilename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  }

  // Copy to clipboard
  copyToClipboard() {
    if (!this.lastConfig) {
      alert('Generate configuration first');
      return;
    }

    navigator.clipboard.writeText(this.lastConfig).then(() => {
      const btn = this.copyBtn;
      const original = btn.textContent;
      btn.textContent = '✅ Copied!';
      setTimeout(() => {
        btn.textContent = original;
      }, 2000);
    });
  }
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
  const generator = new ConfigurationGenerator();
  generator.init();
});
```

---

## How Users Would Use It

### Scenario 1: Run Terraform Locally

```bash
# 1. Open the HTML file
open frontend/index.html

# 2. Fill form in browser, click "Generate Configuration"
# → Browser downloads contoso-alz-terraform.tfvars

# 3. Run Terraform locally
cd terraform/live/global
terraform init
terraform plan -var-file=/path/to/contoso-alz-terraform.tfvars
terraform apply -var-file=/path/to/contoso-alz-terraform.tfvars

# 4. Watch progress in terminal
```

### Scenario 2: Use with GitHub Actions Workflow

```bash
# 1. Open HTML file, generate CSV, download contoso-alz-terraform.tfvars

# 2. Fork HCW-Plan_LZDeployment repo

# 3. Add .tfvars file to repo:
#    terraform/live/global/contoso-alz-terraform.tfvars

# 4. Commit & push (or manually trigger workflow with file)
git add terraform/live/global/contoso-alz-terraform.tfvars
git commit -m "Add contoso landing zone config"
git push origin main

# 5. GitHub Actions workflow auto-triggers
#    (or manually trigger from Actions tab)

# 6. Watch deployment in GitHub Actions UI
#    → Check logs, see Terraform output

# 7. Get artifacts from GitHub Release
```

### Scenario 3: Review Before Deployment

```bash
# 1. Generate configuration (CSV preview in browser)

# 2. Download CSV, review locally:
cat contoso-alz-terraform.tfvars
# Shows all settings, costs, derived values

# 3. Edit if needed (text editor):
nano contoso-alz-terraform.tfvars

# 4. Upload to GitHub and trigger

# 5. No surprises — you've already reviewed it
```

---

## What You'd Need to Change

### 1. frontend/index.html
- ✅ Already 95% correct
- Change: "Deploy to Azure" button → "Generate Configuration (Download CSV)"
- Add: Configuration preview section + download/copy buttons

### 2. frontend/app.js
- ✅ Keep MSAL auth (users can still identify themselves)
- ✅ Keep cost model
- Add: ConfigurationGenerator class (300 lines)
- Remove: Form submission handler, GitHub API calls, job tracking

### 3. No Backend Needed
- ❌ Delete plans for Express server
- ❌ No `/api/bootstrap` endpoint
- ❌ No `/api/jobs/:id` endpoint
- ❌ No GitHub API integration

### 4. GitHub Actions Workflow
- ✅ Keep `generate-and-release.yml`
- Modify: Input method (accept file upload or manual trigger with CSV)
- Option A: User commits CSV to repo, workflow reads it
- Option B: User uploads CSV via GitHub Actions artifacts UI

---

## Effort Comparison

### Old Design (Backend API)
- Express server: 3h
- Bootstrap endpoint: 4h
- Terraform generator: 5h
- GitHub integration: 4h
- Job tracking: 2h
- **Total: 18h** (plus infrastructure, hosting, monitoring)

### New Design (Static Generator)
- Modify HTML form: 1h
- Add ConfigurationGenerator class: 4h
- Add download/copy UI: 1h
- Test locally: 2h
- **Total: 8h** (no hosting needed, works offline)

---

## Files Needed

### Minimal (Static Only)
```
frontend/
├── index.html          (modified — add preview section)
├── styles.css          (no changes)
└── app.js              (add ConfigurationGenerator class)
```

### With GitHub Actions Integration
```
.github/workflows/
└── deploy-with-tfvars.yml  (new — reads .tfvars from repo)
```

---

## Template: Updated GitHub Actions Workflow

This workflow reads a `.tfvars` file from the repo:

```yaml
name: Deploy Landing Zone with Configuration

on:
  push:
    paths:
      - 'terraform/live/**/*.tfvars'
      - '.github/workflows/deploy-with-tfvars.yml'
  workflow_dispatch:
    inputs:
      var_file:
        description: 'Path to .tfvars file (e.g., terraform/live/global/contoso-alz-terraform.tfvars)'
        required: true
        type: string

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.6.x

      - name: Azure Login
        uses: azure/login@v1
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Terraform Init
        working-directory: terraform/live/global
        run: terraform init

      - name: Terraform Plan
        working-directory: terraform/live/global
        run: |
          VAR_FILE="${{ github.event.inputs.var_file || 'terraform.tfvars' }}"
          terraform plan -var-file="../../${VAR_FILE}" -out=tfplan

      - name: Terraform Apply
        working-directory: terraform/live/global
        if: github.ref == 'refs/heads/main'
        run: |
          VAR_FILE="${{ github.event.inputs.var_file || 'terraform.tfvars' }}"
          terraform apply tfplan

      - name: Create Release with Artifacts
        uses: actions/create-release@v1
        if: success()
        with:
          tag_name: deployment-${{ github.run_id }}
          release_name: Landing Zone Deployment ${{ github.run_id }}
          body: |
            Configuration: ${{ github.event.inputs.var_file }}
            Commit: ${{ github.sha }}
          files: |
            terraform/live/global/tfplan
```

---

## Deployment Options

### Option 1: Static File Locally
```bash
# User runs directly from file system
open frontend/index.html  # Works as file:/// URL

# Generate config, download .tfvars, run Terraform locally
```

### Option 2: GitHub Pages
```bash
# Serve from GitHub Pages
# Users access via: https://yourorg.github.io/HCW-Plan_LZDeployment/frontend/

# Or embed link in README:
# [Landing Zone Configurator](https://yourorg.github.io/HCW-Plan_LZDeployment/frontend/)
```

### Option 3: Simple HTTP Server
```bash
# For demos/shared access
cd frontend
python3 -m http.server 8000
# Access: http://localhost:8000/index.html
```

---

## Summary: Static vs. Backend

| Feature | Static Generator | Backend API |
|---------|-----------------|-------------|
| **Setup Time** | 8 hours | 18 hours |
| **Hosting Needed** | No (static file) | Yes (server) |
| **Offline Support** | ✅ Yes | ❌ No |
| **Real-time Status** | ⚠️ Manual (GitHub UI) | ✅ Auto-updates |
| **Authentication** | Optional (MSAL for identify) | Required |
| **Scalability** | Unlimited (no backend) | Limited (server cost) |
| **Complexity** | Low (pure JS) | High (backend, DB, etc.) |
| **User Flow** | Download → Manual upload | Form → Auto trigger |
| **Audit Trail** | CSV file (user keeps it) | Database (backend) |

---

## Recommendation

**Build the Static Generator:**
- ✅ 10x simpler to implement (8h vs 18h)
- ✅ Works offline (users can run locally)
- ✅ Auditability (users have CSV locally)
- ✅ No backend to maintain
- ✅ Users control when to deploy (not auto-triggered)
- ⚠️ Manual workflow trigger (but GitHub Actions UI is fine for power users)

**This is perfect for:**
- Internal tool (not public-facing)
- Enterprise (users want to review before deploying)
- One-off deployments (not self-service SaaS)
- Cost-conscious teams (no server hosting)

---

**Owner**: Platform Engineering  
**Next Step**: Decide — static generator or backend API?  
**Recommendation**: Static. It's 10x faster and better for this use case.

