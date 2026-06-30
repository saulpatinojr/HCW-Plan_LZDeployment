# Terraform Cloud Backend Configuration
# Usage: terraform init -backend-config=backend.hcl

# Terraform Cloud API hostname
hostname = "app.terraform.io"

# Terraform Cloud organization
organization = "YOUR_ORG_NAME"

# Workspace configuration
workspaces {
  name = "lz-sandbox"
}
