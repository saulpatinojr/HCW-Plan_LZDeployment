# Static Generator — Implementation Guide

**What to build**: Pure HTML/JavaScript configuration generator (no backend)  
**Effort**: 6-8 hours  
**Output**: `.tfvars` file that user downloads and feeds to Terraform

---

## Phase 1: Update HTML (1 hour)

### File: `frontend/index.html`

**Step 1**: Replace submit button
```html
<!-- FIND THIS: -->
<div class="form-actions">
  <button type="submit" class="btn btn-primary btn-large">Deploy to Azure</button>
</div>

<!-- REPLACE WITH: -->
<div class="form-actions">
  <button type="button" class="btn btn-primary btn-large" id="generateBtn">
    📋 Generate Configuration (Download .tfvars)
  </button>
</div>
```

**Step 2**: Add preview section (before closing `</form>`)
```html
<!-- ADD THIS before </form> tag: -->

<!-- Configuration Preview & Download -->
<div class="card" id="previewCard" style="display:none; margin-top: 24px;">
  <h3>Generated Configuration (Preview)</h3>
  <p class="small" style="color: #767676; margin-bottom: 12px;">
    Review this configuration before deploying. You can edit it locally if needed.
  </p>
  
  <div style="background: #f3f2f1; padding: 12px; border-radius: 4px; margin-bottom: 12px;">
    <pre id="configPreview" style="
      margin: 0;
      overflow-x: auto;
      max-height: 400px;
      font-family: 'Courier New', monospace;
      font-size: 12px;
      line-height: 1.4;
    "></pre>
  </div>
  
  <div style="display: flex; gap: 12px; flex-wrap: wrap;">
    <button type="button" class="btn btn-primary" id="downloadBtn">
      ⬇️ Download .tfvars
    </button>
    <button type="button" class="btn btn-secondary" id="copyBtn">
      📋 Copy to Clipboard
    </button>
    <button type="button" class="btn btn-secondary" id="regenerateBtn">
      🔄 Back to Form
    </button>
  </div>
</div>
```

---

## Phase 2: Add Generator Logic to app.js (4-5 hours)

### File: `frontend/app.js`

**Find the end of the file** (after `initMsal();` call) **and add**:

```javascript
// ═════════════════════════════════════════════════════════════════════════════
// PART A: Configuration Generator Class
// ═════════════════════════════════════════════════════════════════════════════

class ConfigurationGenerator {
  constructor() {
    this.form = document.getElementById('deploymentForm');
    this.generateBtn = document.getElementById('generateBtn');
    this.downloadBtn = document.getElementById('downloadBtn');
    this.copyBtn = document.getElementById('copyBtn');
    this.regenerateBtn = document.getElementById('regenerateBtn');
    this.previewCard = document.getElementById('previewCard');
    this.configPreview = document.getElementById('configPreview');
    
    this.lastConfig = null;
    this.lastFilename = null;
  }

  // Initialize event listeners
  init() {
    this.generateBtn.addEventListener('click', () => this.generateAndPreview());
    this.downloadBtn.addEventListener('click', () => this.download());
    this.copyBtn.addEventListener('click', () => this.copyToClipboard());
    this.regenerateBtn.addEventListener('click', () => this.backToForm());
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Collect form data
  // ─────────────────────────────────────────────────────────────────────────
  getFormData() {
    const formData = new FormData(this.form);
    
    // Get checked modules
    const modules = [];
    document.querySelectorAll('input[name="modules"]:checked').forEach(input => {
      modules.push(input.value);
    });

    return {
      orgPrefix: formData.get('orgPrefix').trim(),
      modules: modules,
      compliance: formData.get('compliance'),
      primaryRegion: formData.get('primaryRegion').trim(),
      secondaryRegion: formData.get('secondaryRegion').trim(),
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Derive computed values based on compliance & modules
  // ─────────────────────────────────────────────────────────────────────────
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

    const rules = complianceRules[formData.compliance] || complianceRules.baseline;
    
    // Add compute-time values
    return {
      ...rules,
      generatedDate: new Date().toISOString().split('T')[0],
      generatedTime: new Date().toISOString(),
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Calculate cost (same as before)
  // ─────────────────────────────────────────────────────────────────────────
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
    
    // Secondary region adds 15% of primary cost
    cost += cost * 0.15;
    
    return Math.round(cost);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Generate terraform.tfvars format
  // ─────────────────────────────────────────────────────────────────────────
  generateTfvars(formData, computed) {
    const lines = [
      '# ═════════════════════════════════════════════════════════════════════',
      '# HCW Landing Zone Terraform Configuration',
      `# Generated: ${computed.generatedTime}`,
      `# Organization: ${formData.orgPrefix}`,
      '# ═════════════════════════════════════════════════════════════════════',
      '',
      '# ORGANIZATION SETTINGS',
      '# ─────────────────────────────────────────────────────────────────────',
      `org_prefix           = "${formData.orgPrefix}"`,
      `primary_region       = "${formData.primaryRegion}"`,
      `secondary_region     = "${formData.secondaryRegion}"`,
      `compliance_variant   = "${formData.compliance}"`,
      `environment          = "prod"`,
      '',
      '# MODULE SELECTION (true = deploy, false = skip)',
      '# ─────────────────────────────────────────────────────────────────────',
      `deploy_hub_network           = ${formData.modules.includes('hub-network')}`,
      `deploy_spoke_networks        = ${formData.modules.includes('spoke-network')}`,
      `deploy_policy_baseline       = ${formData.modules.includes('policy-baseline')}`,
      `deploy_backup_baseline       = ${formData.modules.includes('backup-baseline')}`,
      `deploy_defender_baseline     = ${formData.modules.includes('defender-baseline')}`,
      '',
      '# COMPUTED VALUES (Automatically set based on compliance)',
      '# ─────────────────────────────────────────────────────────────────────',
      `firewall_tier                = "${computed.firewallTier}"`,
      `tls_minimum_version          = "${computed.tlsMinimumVersion}"`,
      `require_encryption_in_transit = ${computed.requireEncryption}`,
      '',
      '# COST ESTIMATES',
      '# ─────────────────────────────────────────────────────────────────────',
      `cost_estimate_monthly = ${this.calculateCost(formData)}`,
      `cost_estimate_annual  = ${this.calculateCost(formData) * 12}`,
      '',
      '# TAGS (Applied to all resources)',
      '# ─────────────────────────────────────────────────────────────────────',
      `managed_by      = "terraform"`,
      `deployed_date   = "${computed.generatedDate}"`,
      `compliance_type = "${formData.compliance}"`,
      '',
      '# ═════════════════════════════════════════════════════════════════════',
      '# DEPLOYMENT INSTRUCTIONS',
      '# ═════════════════════════════════════════════════════════════════════',
      '# Option 1: Deploy Locally',
      '#   terraform -chdir=terraform/live/global init',
      '#   terraform -chdir=terraform/live/global apply \\',
      `#     -var-file=${formData.orgPrefix}-alz-terraform.tfvars`,
      '',
      '# Option 2: Deploy via GitHub Actions',
      '#   1. Commit this file to repo:',
      `#      terraform/live/global/${formData.orgPrefix}-alz-terraform.tfvars`,
      '#   2. Push to main branch',
      '#   3. Watch GitHub Actions > Workflows',
      '# ═════════════════════════════════════════════════════════════════════',
    ];

    return lines.join('\n');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Generate and show preview
  // ─────────────────────────────────────────────────────────────────────────
  generateAndPreview() {
    // Validate form
    if (!this.form.checkValidity()) {
      alert('❌ Please fill all required fields');
      this.form.reportValidity();
      return;
    }

    try {
      const formData = this.getFormData();
      const computed = this.computeValues(formData);
      const tfvars = this.generateTfvars(formData, computed);

      // Show preview
      this.configPreview.textContent = tfvars;
      this.previewCard.style.display = 'block';

      // Scroll to preview
      this.previewCard.scrollIntoView({ behavior: 'smooth', block: 'start' });

      // Store for download
      this.lastConfig = tfvars;
      this.lastFilename = `${formData.orgPrefix}-alz-terraform.tfvars`;
      
      console.log('✅ Configuration generated:', this.lastFilename);
    } catch (error) {
      alert(`❌ Error generating configuration: ${error.message}`);
      console.error(error);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Download config as .tfvars file
  // ─────────────────────────────────────────────────────────────────────────
  download() {
    if (!this.lastConfig) {
      alert('❌ Generate configuration first');
      return;
    }

    try {
      const blob = new Blob([this.lastConfig], { type: 'text/plain' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = this.lastFilename;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
      
      console.log(`✅ Downloaded: ${this.lastFilename}`);
    } catch (error) {
      alert(`❌ Download failed: ${error.message}`);
      console.error(error);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Copy to clipboard
  // ─────────────────────────────────────────────────────────────────────────
  copyToClipboard() {
    if (!this.lastConfig) {
      alert('❌ Generate configuration first');
      return;
    }

    navigator.clipboard.writeText(this.lastConfig).then(() => {
      const btn = this.copyBtn;
      const original = btn.textContent;
      btn.textContent = '✅ Copied to Clipboard!';
      setTimeout(() => {
        btn.textContent = original;
      }, 2000);
      console.log('✅ Configuration copied to clipboard');
    }).catch((error) => {
      alert(`❌ Copy failed: ${error.message}`);
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Back to form
  // ─────────────────────────────────────────────────────────────────────────
  backToForm() {
    this.previewCard.style.display = 'none';
    this.form.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PART B: Initialize Generator on Page Load
// ═════════════════════════════════════════════════════════════════════════════

document.addEventListener('DOMContentLoaded', () => {
  const generator = new ConfigurationGenerator();
  generator.init();
  console.log('✅ Configuration Generator initialized');
});
```

---

## Phase 3: Update Cost Display (Optional - 1 hour)

**Make cost update in real-time as user changes selections**

Add this to `app.js` (inside the `DOMContentLoaded` handler):

```javascript
// Real-time cost updates
const updateCostDisplay = () => {
  const generator = new ConfigurationGenerator();
  const formData = generator.getFormData();
  const cost = generator.calculateCost(formData);
  
  const costBreakdown = document.getElementById('costBreakdown');
  if (costBreakdown) {
    costBreakdown.innerHTML = `
      <p style="font-size: 24px; color: #0078d4; font-weight: bold;">
        $${cost.toLocaleString()}/month
      </p>
      <p style="color: #767676; font-size: 14px;">
        Estimated annual: $${(cost * 12).toLocaleString()}
      </p>
      <small style="color: #999;">Based on selected modules and compliance variant</small>
    `;
  }
};

// Listen for form changes
document.querySelectorAll('input, select').forEach(input => {
  input.addEventListener('change', updateCostDisplay);
});

// Initial cost display
updateCostDisplay();
```

---

## Phase 4: Testing (1-2 hours)

### Test Locally

```bash
# 1. Open in browser
open frontend/index.html

# 2. Fill form
- Org Prefix: "testorg" (or "contoso")
- Select all modules
- Compliance: pci-dss
- Regions: eastus, westus

# 3. Click "Generate Configuration (Download .tfvars)"

# 4. Verify preview shows:
- All values from form
- Computed values (Premium firewall for pci-dss)
- Cost calculation
- Deployment instructions

# 5. Click "Download .tfvars"

# 6. Check Downloads folder
# File should be: testorg-alz-terraform.tfvars

# 7. Open file in editor, verify content:
cat ~/Downloads/testorg-alz-terraform.tfvars

# Should see:
# org_prefix = "testorg"
# deploy_hub_network = true
# firewall_tier = "Premium"
# cost_estimate_monthly = 3960  (or similar)
```

### Test with Terraform

```bash
# 1. Use downloaded .tfvars file
cp ~/Downloads/testorg-alz-terraform.tfvars terraform/live/global/

# 2. Plan deployment
cd terraform/live/global
terraform init
terraform plan -var-file=testorg-alz-terraform.tfvars

# 3. Verify it reads the file correctly
# Should see: Refreshing state...
# Should see plan for all selected modules
```

---

## Phase 5: Optional - GitHub Actions Integration (1 hour)

**Create workflow that reads .tfvars from repo**

### File: `.github/workflows/deploy-with-tfvars.yml`

```yaml
name: Deploy Landing Zone with Config

on:
  push:
    paths:
      - 'terraform/live/**/*.tfvars'
      - '.github/workflows/deploy-with-tfvars.yml'
    branches: [main]
  workflow_dispatch:
    inputs:
      var_file_path:
        description: 'Path to .tfvars file'
        required: false
        default: 'terraform/live/global/terraform.tfvars'

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: List .tfvars files
        run: find terraform/ -name "*.tfvars" -type f

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
          # Detect the .tfvars file (use first one found, or input)
          VAR_FILE="${{ github.event.inputs.var_file_path }}"
          if [ -z "$VAR_FILE" ]; then
            VAR_FILE=$(find ../../ -name "*.tfvars" -type f | head -1)
          fi
          echo "Using: $VAR_FILE"
          terraform plan -var-file="$VAR_FILE" -out=tfplan

      - name: Terraform Apply
        working-directory: terraform/live/global
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
        run: |
          VAR_FILE=$(find ../../ -name "*.tfvars" -type f | head -1)
          terraform apply tfplan

      - name: Upload Logs
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: terraform-logs
          path: terraform/live/global/
```

---

## Final Checklist

- [ ] **frontend/index.html** — Button changed, preview section added
- [ ] **frontend/app.js** — ConfigurationGenerator class added + initialized
- [ ] **frontend/styles.css** — No changes needed (already correct)
- [ ] **Test locally** — Can fill form, generate, download, view .tfvars
- [ ] **Test with Terraform** — Can use .tfvars file with `terraform plan`
- [ ] (**Optional**) **GitHub Actions** — Workflow reads .tfvars from repo

---

## What Users See

```
┌─────────────────────────────────────────────────────────────┐
│  Azure Landing Zone Configuration                           │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Organization Prefix:     [contoso]                         │
│  Modules: [✓] Hub Network [✓] Spoke [✓] Policy             │
│  Compliance: [PCI-DSS  ▼]                                   │
│  Regions: [eastus] [westus]                                │
│                                                              │
│  Estimated Cost: $2,160/month  ($25,920/year)              │
│                                                              │
│  [📋 Generate Configuration (Download .tfvars)]             │
│                                                              │
└─────────────────────────────────────────────────────────────┘

                    [User clicks button]
                            ↓

┌─────────────────────────────────────────────────────────────┐
│  Generated Configuration (Preview)                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  # HCW Landing Zone Terraform Configuration                │
│  # Generated: 2026-06-30T14:23:45.000Z                     │
│                                                              │
│  org_prefix = "contoso"                                    │
│  primary_region = "eastus"                                 │
│  compliance_variant = "pci-dss"                            │
│                                                              │
│  deploy_hub_network = true                                 │
│  firewall_tier = "Premium"                                 │
│  cost_estimate_monthly = 2160                              │
│  ...                                                         │
│                                                              │
│  [⬇️ Download .tfvars] [📋 Copy to Clipboard]             │
│                                                              │
└─────────────────────────────────────────────────────────────┘

                [User clicks Download]
                        ↓
         Browser downloads: contoso-alz-terraform.tfvars
                        ↓
            User now has .tfvars file locally
                        ↓
         Can use with Terraform or upload to GitHub
```

---

## Summary

**You now have:**
- ✅ Static HTML generator (no backend needed)
- ✅ Real-time cost calculation
- ✅ Compliance-based enforcement (Premium firewall for PCI-DSS, etc.)
- ✅ Download/copy functionality
- ✅ Deployment instructions in generated file
- ✅ Optional GitHub Actions integration

**Total effort: 6-8 hours**  
**Result: Works offline, no server needed, audit trail (user keeps CSV)**

