# Social platform — Phase 0 infrastructure

Terraform for everything we built manually in the portal: resource group, VNet
with two subnets, Log Analytics, ACR, Key Vault, Postgres Flexible Server
(mixed Entra + password auth), a shared managed identity, and the Container
Apps environment.

## Where this runs

Terraform is a CLI, not a server — run it from your laptop or Azure Cloud
Shell to start, migrate to a GitHub Actions runner once the code is stable.
You need the Azure CLI logged in (`az login`) or a service principal's
credentials exported as environment variables.

## 1. Bootstrap remote state (one-time, manual)

Terraform can't create the place that stores its own state, so this one part
is plain Azure CLI, run once:

```bash
az group create --name rg-terraform-state --location centralindia
az storage account create \
  --name tfstatesocialXXXX \
  --resource-group rg-terraform-state \
  --sku Standard_LRS --encryption-services blob
az storage container create --name tfstate --account-name tfstatesocialXXXX
```

## 2. Configure variables

```bash
cp terraform.tfvars.example terraform.tfvars
# fill in entra_admin_object_id (az ad signed-in-user show --query id -o tsv)
# and entra_admin_login with your own values
```

## 3. Init, plan, apply

```bash
terraform init \
  -backend-config="resource_group_name=rg-terraform-state" \
  -backend-config="storage_account_name=tfstatesocialXXXX" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=social-platform.tfstate"

terraform plan -out=tfplan
terraform apply tfplan
```

## What you get at the end

The outputs give you everything needed to deploy the first Container App
(Auth service): the ACR login server to push an image to, the managed
identity's client ID to attach to the app, the Key Vault URI, and the
Postgres FQDN to connect to.

## Next step

This is Phase 0 only — no Container Apps (the actual microservices) are
created yet, on purpose. Each service (Auth, Profile, Post, Feed) should be
its own Terraform module or its own `azurerm_container_app` resource added
once its Docker image exists, so services deploy independently rather than
all redeploying whenever any one of them changes.
