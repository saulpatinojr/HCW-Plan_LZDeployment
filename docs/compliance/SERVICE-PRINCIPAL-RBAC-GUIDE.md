# Service Principal RBAC Configuration Guide
## Task 1.1 - GitHub Actions Least-Privilege Access

**Finding**: 1.1 - Service Principal RBAC Overprivilege (CVSS 9.1 - CRITICAL)  
**Risk**: Compromised CI/CD pipeline can escalate privileges and modify Azure RBAC  
**Remediation**: Scope service principals with Contributor role per subscription

---

## Current Security Posture

**Problem**: GitHub Actions service principal may have:
- ❌ **Owner** role (allows RBAC modification, privilege escalation)
- ❌ Tenant-level or management group-level scope (excessive access)
- ❌ Single service principal for all subscriptions (blast radius too large)

**Target State**:
- ✅ **Contributor** role only (no RBAC modification)
- ✅ Subscription-level scope (one SP per subscription)
- ✅ Separate service principals per deployment layer

---

## Recommended Architecture

### Multi-Subscription Service Principal Strategy

Create separate service principals for each deployment layer:

| Service Principal | Scope | Role | Justification |
|---|---|---|---|
| `sp-terraform-global-prod` | Root Management Group (read-only) | Management Group Contributor | Deploy management groups & policies |
| `sp-terraform-connectivity-prod` | Connectivity Subscription | Contributor | Deploy hub networks & firewalls |
| `sp-terraform-management-prod` | Management Subscription | Contributor | Deploy backup, automation, logging |
| `sp-terraform-workloads-prod` | Workload Prod Subscription | Contributor | Deploy production spokes |
| `sp-terraform-workloads-nonprod` | Workload NonProd Subscription | Contributor | Deploy non-production spokes |
| `sp-terraform-sandbox-dev` | Sandbox Subscription | Contributor | Deploy sandbox resources |

**Benefits**:
- 🔒 **Blast radius containment**: Compromise of one SP doesn't affect other subscriptions
- ✅ **Least privilege**: Each SP can only deploy to its assigned scope
- 📊 **Audit trail**: Clearer attribution of changes per subscription
- 🛡️ **Defense in depth**: Multiple layers of access control

---

## Step-by-Step Remediation

### Prerequisites
- Azure CLI 2.60+
- Owner or User Access Administrator role on target subscriptions
- Access to GitHub repository secrets

### Step 1: Audit Current Service Principal

```bash
# Set your current SP client ID
CURRENT_SP_CLIENT_ID="<YOUR_GITHUB_SP_CLIENT_ID>"

# List all role assignments for current SP
az role assignment list \
  --assignee $CURRENT_SP_CLIENT_ID \
  --all \
  --output table

# Check for Owner role (CRITICAL VIOLATION)
az role assignment list \
  --assignee $CURRENT_SP_CLIENT_ID \
  --role Owner \
  --output table
```

**Expected Output**: If any Owner assignments found, **STOP and remove them immediately**.

### Step 2: Remove Existing Owner Assignments

```bash
# Remove Owner role from ALL scopes
az role assignment list \
  --assignee $CURRENT_SP_CLIENT_ID \
  --role Owner \
  --query "[].id" \
  --output tsv | \
  xargs -I {} az role assignment delete --ids {}

# Verify removal
az role assignment list \
  --assignee $CURRENT_SP_CLIENT_ID \
  --role Owner \
  --output table

# Expected: No results
```

### Step 3: Create Separate Service Principals

```bash
# Replace with your subscription IDs
export SUBSCRIPTION_ID_CONNECTIVITY="<CONNECTIVITY_SUB_ID>"
export SUBSCRIPTION_ID_MANAGEMENT="<MANAGEMENT_SUB_ID>"
export SUBSCRIPTION_ID_WORKLOAD_PROD="<WORKLOAD_PROD_SUB_ID>"
export SUBSCRIPTION_ID_WORKLOAD_NONPROD="<WORKLOAD_NONPROD_SUB_ID>"
export SUBSCRIPTION_ID_SANDBOX="<SANDBOX_SUB_ID>"

# Global (Management Group Contributor at root MG)
az ad sp create-for-rbac \
  --name "sp-terraform-global-prod" \
  --role "Management Group Contributor" \
  --scopes "/providers/Microsoft.Management/managementGroups/<ROOT_MG_ID>" \
  --sdk-auth > sp-global.json

# Connectivity
az ad sp create-for-rbac \
  --name "sp-terraform-connectivity-prod" \
  --role "Contributor" \
  --scopes "/subscriptions/$SUBSCRIPTION_ID_CONNECTIVITY" \
  --sdk-auth > sp-connectivity.json

# Management
az ad sp create-for-rbac \
  --name "sp-terraform-management-prod" \
  --role "Contributor" \
  --scopes "/subscriptions/$SUBSCRIPTION_ID_MANAGEMENT" \
  --sdk-auth > sp-management.json

# Workloads Prod
az ad sp create-for-rbac \
  --name "sp-terraform-workloads-prod" \
  --role "Contributor" \
  --scopes "/subscriptions/$SUBSCRIPTION_ID_WORKLOAD_PROD" \
  --sdk-auth > sp-workloads-prod.json

# Workloads NonProd
az ad sp create-for-rbac \
  --name "sp-terraform-workloads-nonprod" \
  --role "Contributor" \
  --scopes "/subscriptions/$SUBSCRIPTION_ID_WORKLOAD_NONPROD" \
  --sdk-auth > sp-workloads-nonprod.json

# Sandbox
az ad sp create-for-rbac \
  --name "sp-terraform-sandbox-dev" \
  --role "Contributor" \
  --scopes "/subscriptions/$SUBSCRIPTION_ID_SANDBOX" \
  --sdk-auth > sp-sandbox.json
```

**IMPORTANT**: Store these JSON files securely. They contain sensitive credentials.

### Step 4: Configure Federated Identity Credentials (OIDC)

For each service principal, configure OIDC federation with GitHub:

```bash
# Example for connectivity SP
SP_OBJECT_ID=$(az ad sp list --display-name "sp-terraform-connectivity-prod" --query "[0].id" -o tsv)

az ad app federated-credential create \
  --id $SP_OBJECT_ID \
  --parameters '{
    "name": "github-actions-connectivity-prod",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:YOUR_ORG/YOUR_REPO:environment:platform-connectivity",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

**Repeat for each service principal** with appropriate subject patterns:
- Global: `repo:YOUR_ORG/YOUR_REPO:ref:refs/heads/main`
- Connectivity: `repo:YOUR_ORG/YOUR_REPO:environment:platform-connectivity`
- Management: `repo:YOUR_ORG/YOUR_REPO:environment:platform-management`
- Workloads Prod: `repo:YOUR_ORG/YOUR_REPO:environment:workloads-prod`
- Sandbox: `repo:YOUR_ORG/YOUR_REPO:environment:sandbox`

### Step 5: Update GitHub Secrets

Update GitHub repository secrets for each deployment layer:

**Global Layer**:
- `AZURE_CLIENT_ID_GLOBAL` = Client ID from `sp-global.json`
- `AZURE_TENANT_ID` = Tenant ID (same for all)
- `AZURE_SUBSCRIPTION_ID_GLOBAL` = Root management group ID

**Connectivity Layer**:
- `AZURE_CLIENT_ID_CONNECTIVITY` = Client ID from `sp-connectivity.json`
- `AZURE_SUBSCRIPTION_ID_CONNECTIVITY` = Connectivity subscription ID

**Management Layer**:
- `AZURE_CLIENT_ID_MANAGEMENT` = Client ID from `sp-management.json`
- `AZURE_SUBSCRIPTION_ID_MANAGEMENT` = Management subscription ID

**Workloads Prod Layer**:
- `AZURE_CLIENT_ID_WORKLOADS_PROD` = Client ID from `sp-workloads-prod.json`
- `AZURE_SUBSCRIPTION_ID_WORKLOADS_PROD` = Workload prod subscription ID

**Workloads NonProd Layer**:
- `AZURE_CLIENT_ID_WORKLOADS_NONPROD` = Client ID from `sp-workloads-nonprod.json`
- `AZURE_SUBSCRIPTION_ID_WORKLOADS_NONPROD` = Workload nonprod subscription ID

**Sandbox Layer**:
- `AZURE_CLIENT_ID_SANDBOX` = Client ID from `sp-sandbox.json`
- `AZURE_SUBSCRIPTION_ID_SANDBOX` = Sandbox subscription ID

### Step 6: Update Workflow Files

Update `.github/workflows/terraform-plan.yml` and `.github/workflows/terraform-apply.yml` to use layer-specific secrets:

```yaml
# Example for connectivity layer job
- name: Azure Login (OIDC)
  uses: azure/login@6c251865b4e6290e7b78be643ea2d005bc51f69a  # v2.1.1
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID_CONNECTIVITY }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID_CONNECTIVITY }}
```

### Step 7: Verification

Test each layer deployment:

```bash
# Trigger workflow for connectivity layer
git commit --allow-empty -m "test: verify connectivity SP RBAC"
git push origin main

# Check workflow run:
# - RBAC validation should PASS
# - No Owner role assignments detected
# - Service principal properly scoped to subscription
```

### Step 8: Cleanup Old Service Principal

After verifying all layers work with new SPs:

```bash
# List old SP assignments
az role assignment list --assignee $CURRENT_SP_CLIENT_ID --output table

# Delete old SP role assignments
az role assignment list \
  --assignee $CURRENT_SP_CLIENT_ID \
  --query "[].id" \
  --output tsv | \
  xargs -I {} az role assignment delete --ids {}

# Delete old SP
az ad sp delete --id $CURRENT_SP_CLIENT_ID

# Remove old secrets from GitHub
# (delete AZURE_CLIENT_ID, AZURE_SUBSCRIPTION_ID if single SP was used)
```

---

## Validation Checklist

After remediation, verify:

- [ ] No service principal has Owner role
- [ ] All service principals scoped to specific subscriptions (no tenant/MG scope except global)
- [ ] Each service principal has Contributor role only
- [ ] OIDC federation configured for each service principal
- [ ] GitHub secrets updated per layer
- [ ] Workflow files reference layer-specific secrets
- [ ] RBAC validation job passes in CI/CD
- [ ] Test deployment succeeds for each layer
- [ ] Old service principal removed

---

## Troubleshooting

### Issue: "Insufficient privileges to complete the operation"

**Cause**: Service principal lacks required permissions

**Solution**:
```bash
# Verify SP has Contributor on target subscription
az role assignment list \
  --assignee <SP_CLIENT_ID> \
  --scope /subscriptions/<SUBSCRIPTION_ID> \
  --output table

# Add Contributor if missing
az role assignment create \
  --assignee <SP_CLIENT_ID> \
  --role Contributor \
  --scope /subscriptions/<SUBSCRIPTION_ID>
```

### Issue: "RBAC validation fails with Owner role detected"

**Cause**: Service principal still has Owner assignments

**Solution**: Follow Step 2 to remove all Owner assignments

### Issue: "Cannot modify management groups"

**Cause**: Global SP lacks Management Group Contributor role

**Solution**:
```bash
az role assignment create \
  --assignee <GLOBAL_SP_CLIENT_ID> \
  --role "Management Group Contributor" \
  --scope "/providers/Microsoft.Management/managementGroups/<ROOT_MG_ID>"
```

---

## Security Best Practices

### Regular Audits

Run monthly RBAC audits:

```bash
# List all service principals
az ad sp list --filter "startswith(displayName, 'sp-terraform')" \
  --query "[].{Name:displayName, AppId:appId}" \
  --output table

# For each SP, verify roles
az role assignment list --assignee <SP_APP_ID> --all --output table
```

### Rotation Policy

Rotate federated identity credentials quarterly:
1. Create new federated credential
2. Update GitHub secrets
3. Test deployments
4. Delete old credential

### Monitoring

Enable Azure Activity Log alerts for:
- Role assignment changes on service principals
- Service principal credential modifications
- Owner role assignments

---

## Additional Resources

- [Azure RBAC Best Practices](https://learn.microsoft.com/azure/role-based-access-control/best-practices)
- [Workload Identity Federation](https://learn.microsoft.com/azure/active-directory/workload-identities/workload-identity-federation)
- [GitHub OIDC with Azure](https://docs.github.com/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure)
- [Management Group Contributor Role](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#management-group-contributor)

---

**Document Version**: 1.0  
**Last Updated**: May 28, 2026  
**Phase 1 Task**: 1.1 - Service Principal RBAC Validation & Scoping  
**Effort**: 8 hours  
**Cost**: $0
