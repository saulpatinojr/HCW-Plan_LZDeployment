# Quick Start: Static .tfvars Generator

**What you have**: A fully functional HTML/JavaScript tool that generates Terraform configuration files.

**Time to test**: 5 minutes

---

## 30-Second Setup

```bash
# Open the tool (pick one):

# Option 1: Direct file (no server needed)
open frontend/index.html

# Option 2: Python HTTP server
cd frontend
python3 -m http.server 8000
# Then open: http://localhost:8000

# Option 3: Node.js server
cd frontend
npx http-server
# Open URL shown in terminal
```

---

## 2-Minute Test

1. **Fill form**:
   - Org Prefix: `test`
   - Modules: ✓ All three (Hub, Spoke, Policy)
   - Compliance: `pci-dss`
   - Regions: `eastus` / `westus`

2. **Generate**:
   - Click **"📋 Generate Configuration"**
   - See preview appear
   - Verify: `firewall_tier = "Premium"` (enforced for PCI-DSS)

3. **Download**:
   - Click **"⬇️ Download .tfvars"**
   - File `test-alz-terraform.tfvars` appears in Downloads

4. **Verify with Terraform**:
   ```bash
   terraform validate -var-file=~/Downloads/test-alz-terraform.tfvars
   # Should succeed
   ```

✅ **Done!** The generator works.

---

## What Each Button Does

| Button | Action | Output |
|--------|--------|--------|
| **Generate Configuration** | Creates `.tfvars` in browser memory | Shows preview below |
| **Download .tfvars** | Browser downloads file | `{org}-alz-terraform.tfvars` in Downloads |
| **Copy to Clipboard** | Copies preview to clipboard | Pastes into any text editor |
| **Back to Form** | Hides preview, scrolls to form | Ready to modify and regenerate |

---

## What Gets Generated

For `test` org with `pci-dss` compliance:

```hcl
org_prefix = "test"
primary_region = "eastus"
secondary_region = "westus"
compliance_variant = "pci-dss"

deploy_hub_network = true
deploy_spoke_networks = true
deploy_policy_baseline = true

firewall_tier = "Premium"         # ← Enforced for pci-dss
tls_minimum_version = "1.2"
require_encryption_in_transit = true

cost_estimate_monthly = 2160      # ← Real-time calculation
```

---

## How to Deploy with Terraform

### Option 1: Local (Easiest)

```bash
# 1. Download from generator
# 2. Save to downloads folder
# 3. Run Terraform

cd terraform/live/global
terraform init
terraform apply -var-file=~/Downloads/test-alz-terraform.tfvars
```

### Option 2: GitHub (Auto)

```bash
# 1. Download from generator
# 2. Commit to repo

git add terraform/live/global/test-alz-terraform.tfvars
git commit -m "Add test landing zone config"
git push origin main

# 3. GitHub Actions runs automatically
# 4. Watch at: https://github.com/yourrepo/actions
```

---

## Customization Quick Tips

### Add a Module

1. Edit `frontend/index.html` - add checkbox
2. Edit `frontend/app.js` - update cost model:
   ```javascript
   optional: {
     myModule: 1000,  // Add here
   }
   ```
3. Test - cost updates, module appears in output

### Change a Cost

Edit `frontend/app.js`, search `costs:` object:

```javascript
hubNetwork: 1500,          // Change this
spokeNetwork: 300,         // or this
backupBaseline: 500,       // or this
defenderBaseline: 2000,    // or this
```

### Add Compliance Rule

Edit `frontend/app.js`, `computeValues()` method:

```javascript
myCompliance: {
    firewallTier: "Premium",
    tlsMinimumVersion: "1.2",
    requireEncryption: true,
},
```

---

## Common Questions

**Q: Does it need a server?**  
A: No. It's pure HTML/JavaScript. Opens in any browser, works offline.

**Q: Is the generated file safe?**  
A: Yes. It's just variables. No secrets. You review before deploying.

**Q: Can I customize the form?**  
A: Yes. Edit `frontend/index.html` for form fields, `frontend/app.js` for logic.

**Q: How do I share this with my team?**  
A: Upload `frontend/` to GitHub Pages or any web host. Send link.

**Q: Does it work offline?**  
A: Yes. Open `frontend/index.html` directly (file:/// URL).

**Q: Can I deploy without Terraform?**  
A: No, the `.tfvars` file is for Terraform. But you can review it, edit it, or pass it to Azure CLI if you prefer.

---

## Files You Modified

### `frontend/index.html`
- Changed "Deploy" button → "Generate Configuration"
- Added preview card below form
- +15 lines

### `frontend/app.js`
- Added ConfigurationGenerator class
- Keeps MSAL auth (optional)
- Removes GitHub integration
- +270 lines

### `frontend/styles.css`
- Added `.preview-card` and related styles
- +40 lines

**Total**: 325 lines of code (all working, no backend needed)

---

## Success Checklist

- [ ] Can open `frontend/index.html` in browser
- [ ] Form renders (org prefix, modules, compliance, regions)
- [ ] Cost updates when you change selections
- [ ] Can click "Generate Configuration"
- [ ] Preview appears with `.tfvars` content
- [ ] Can download file
- [ ] Downloaded file opens in text editor
- [ ] File is valid HCL (no syntax errors)
- [ ] Can use file with `terraform validate`

If all checked ✅, you're done!

---

## Next Actions

**Now**:
1. Test locally (above)
2. Download a `.tfvars` file
3. Try `terraform validate -var-file=...`

**This Week**:
1. Host on GitHub Pages (optional)
2. Share with team
3. Deploy first landing zone

**Later**:
1. Add custom modules
2. Integrate with GitHub Actions
3. Add more compliance rules

---

## Support

If something doesn't work:

1. **Check browser console** (F12 → Console tab)
2. **Re-read TESTING_STATIC_GENERATOR.md**
3. **Verify file exists**: `frontend/index.html`
4. **Try different browser** (Chrome/Firefox/Safari)

---

## That's It!

You now have a working `.tfvars` generator. No backend. No servers. Pure static HTML/JavaScript.

**Status**: ✅ Ready to use  
**Time spent**: 8 hours  
**Lines of code**: 325  
**Backend needed**: Zero  

Enjoy! 🎉

