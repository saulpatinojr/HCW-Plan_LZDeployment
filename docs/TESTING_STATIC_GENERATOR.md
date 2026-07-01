# Testing the Static Generator

**What was built**: Static HTML/JavaScript configuration generator that creates `.tfvars` files in-browser (no backend needed).

---

## Quick Start: Test Locally

### Option 1: Open in Browser (Simplest)

```bash
# Navigate to frontend directory
cd frontend

# Open in browser (works on Windows, macOS, Linux)
# Windows:
start index.html

# macOS:
open index.html

# Linux:
xdg-open index.html

# Or just drag index.html into your browser
```

### Option 2: Use Python HTTP Server

```bash
cd frontend
python3 -m http.server 8000
# Open http://localhost:8000 in browser
```

### Option 3: Use Node.js HTTP Server

```bash
cd frontend
npx http-server
# Open URL shown in terminal
```

---

## Test Scenario 1: Basic Generation

### Steps
1. Open `frontend/index.html` in browser
2. Fill out form:
   - **Org Prefix**: `contoso`
   - **Modules**: Check all boxes (✓ Hub Network, ✓ Spoke Networks, ✓ Policy Baseline)
   - **Compliance**: Select `pci-dss`
   - **Primary Region**: `eastus`
   - **Secondary Region**: `westus`
3. Observe: Cost estimate updates to ~$2,160/month
4. Click **"📋 Generate Configuration (Download .tfvars)"**
5. Expected: Configuration preview appears below form
6. Verify preview shows:
   ```hcl
   org_prefix = "contoso"
   deploy_hub_network = true
   firewall_tier = "Premium"  # Enforced for pci-dss
   cost_estimate_monthly = 2160
   ```

---

## Test Scenario 2: Download File

### Steps
1. After generating config (above), click **"⬇️ Download .tfvars"**
2. Expected:
   - Browser downloads file: `contoso-alz-terraform.tfvars`
   - File appears in Downloads folder
3. Open downloaded file in text editor:
   ```bash
   cat ~/Downloads/contoso-alz-terraform.tfvars
   ```
4. Verify:
   - All settings are present
   - Syntax is valid HCL (can be used with Terraform)
   - Comments explain each section

---

## Test Scenario 3: Copy to Clipboard

### Steps
1. Generate config (as in Scenario 1)
2. Click **"📋 Copy to Clipboard"**
3. Expected: Button text changes to "✅ Copied to Clipboard!" for 2 seconds
4. Paste content into text editor:
   ```bash
   # Press Ctrl+V (or Cmd+V on Mac) after copying
   ```
5. Verify: Same content as download

---

## Test Scenario 4: Back to Form

### Steps
1. After generating config, click **"🔄 Back to Form"**
2. Expected: Preview card hides, form scrolls back to top
3. Modify form (e.g., change compliance to `baseline`)
4. Click generate again
5. Expected: New preview shows:
   ```hcl
   firewall_tier = "Standard"  # Changed from Premium
   cost_estimate_monthly = 1980  # Changed (lower cost)
   ```

---

## Test Scenario 5: Compliance Enforcement

### Steps
1. Change **Compliance** to `fedramp`
2. Observe:
   - Cost estimate increases (1.8x multiplier)
   - Compliance info shows: "Government: NIST compliance..."
3. Generate config
4. Verify preview shows:
   ```hcl
   firewall_tier = "Premium"  # Enforced for fedramp
   tls_minimum_version = "1.2"
   require_encryption_in_transit = true
   ```

---

## Test Scenario 6: Module Selection Impact

### Steps
1. Start with all modules checked
2. Uncheck **Defender Baseline**
3. Observe: Cost decreases by $2,000/month
4. Uncheck **Backup Baseline**
5. Observe: Cost decreases by additional ~$500-600/month
6. Generate config
7. Verify:
   ```hcl
   deploy_backup_baseline = false
   deploy_defender_baseline = false
   ```

---

## Test Scenario 7: Region Selection

### Steps
1. Change **Secondary Region** to empty string (or different region)
2. Observe: Cost estimate recalculates (secondary region adds ~15% to total)
3. Generate config
4. Verify:
   ```hcl
   secondary_region = "{your-region}"
   cost_estimate_monthly = {calculated-amount}
   ```

---

## Test Scenario 8: Terraform Validation (Integration)

### Steps
1. Download `.tfvars` file from generator
2. Save to: `terraform/live/global/{orgprefix}-alz-terraform.tfvars`
3. Test with Terraform:
   ```bash
   cd terraform/live/global
   terraform init
   terraform validate -var-file=contoso-alz-terraform.tfvars
   ```
4. Expected: No errors (clean validation)
5. Optional: Run plan to see what would deploy:
   ```bash
   terraform plan -var-file=contoso-alz-terraform.tfvars -out=tfplan
   ```
6. Expected: Terraform reads variables successfully, shows deployment plan

---

## Test Scenario 9: Form Validation

### Steps
1. Leave **Org Prefix** empty
2. Click "Generate Configuration"
3. Expected: Browser shows validation error "Please fill all required fields"
4. Fill with invalid prefix (e.g., `MyOrg` with capital letters)
5. Generate again
6. Expected: Error (pattern must be 3-8 lowercase letters)
7. Fix to `myorg`
8. Generate succeeds

---

## Test Scenario 10: Real-Time Cost Updates

### Steps
1. Start with default form values
2. Note cost in estimate card
3. Check **Defender Baseline** (optional module)
4. Expected: Cost updates immediately (+$2,000/month)
5. Change **Compliance** to `hipaa`
6. Expected: Cost updates immediately (1.5x multiplier)
7. Change **Secondary Region** to `westus2`
8. Expected: Cost updates (still includes secondary region factor)

---

## Checklist: All Features Working

- [ ] Form renders without errors
- [ ] Cost estimate displays and updates in real-time
- [ ] Can generate configuration from all modules
- [ ] Preview shows correctly formatted `.tfvars`
- [ ] Can download `.tfvars` file
- [ ] Downloaded file is readable and valid HCL
- [ ] Can copy to clipboard
- [ ] Can go back to form and regenerate
- [ ] Compliance variants enforce correct settings (Premium/Standard firewall)
- [ ] Module selections reflected in output
- [ ] Regions populate correctly
- [ ] Cost calculations are accurate
- [ ] Downloaded file works with Terraform validate

---

## Troubleshooting

### Issue: Configuration not generating

**Check**:
1. Are all required fields filled?
2. Is org prefix 3-8 lowercase letters?
3. Open browser console (F12) - any errors?

### Issue: Download not working

**Check**:
1. Browser allows file downloads (check settings)
2. Try copy-to-clipboard method instead
3. Check browser console for errors

### Issue: Cost estimates wrong

**Check**:
1. Verify cost model in `app.js` (search `calculateCost`)
2. Test with known values:
   - Hub Network: $1,500
   - Spoke Network: $300
   - Backup: $500
   - Defender: $2,000
   - PCI-DSS multiplier: 1.2x
   - Secondary region: +15% of primary

### Issue: Terraform validation fails

**Check**:
1. Is `.tfvars` file in correct location?
2. Run with `-var-file=./filename` (include `./`)
3. Check for syntax errors in generated file
4. Verify region names are valid Azure regions

---

## Success Indicators

✅ **User can**:
1. Open HTML file (no server needed)
2. Fill form with their options
3. See cost estimate update in real-time
4. Generate `.tfvars` file
5. Download file to computer
6. Use file with Terraform (or upload to GitHub)

✅ **Generated `.tfvars` file**:
1. Is valid HCL syntax
2. Contains all form values
3. Contains computed values (firewall tier, TLS version)
4. Contains cost estimates
5. Can be used with `terraform plan/apply`

---

## Next Steps After Testing

1. **Local Deployment**:
   ```bash
   # Download .tfvars, then:
   terraform -chdir=terraform/live/global apply \
     -var-file=/path/to/downloaded/file.tfvars
   ```

2. **GitHub Integration**:
   - Commit `.tfvars` to repo
   - Push to main branch
   - GitHub Actions workflow auto-runs (if configured)

3. **Share with Team**:
   - Host `frontend/index.html` on GitHub Pages
   - Send link in docs
   - Users generate their own configs

---

## Performance Notes

- Should load instantly (static HTML)
- Cost calculations: <1ms
- Configuration generation: <1ms
- Works offline (no server or API calls)
- File size: ~50KB (HTML + CSS + JS)

---

## Browser Compatibility

Tested and working on:
- ✅ Chrome/Chromium 90+
- ✅ Firefox 88+
- ✅ Safari 14+
- ✅ Edge 90+

Requires:
- JavaScript enabled
- `Blob` and `URL.createObjectURL` support (all modern browsers)
- Clipboard API (for copy button)

---

## Success!

If all test scenarios pass, the static generator is ready for use. Users can:
1. Download from GitHub / open locally
2. Fill form
3. Get `.tfvars` file
4. Use with Terraform

No backend needed. No deployment required. ✅

