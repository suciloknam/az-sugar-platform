# This one identity is attached to every Container App you deploy later
# (Auth, Profile, Post, Feed). It's how they pull images and read secrets
# with zero passwords or connection strings stored anywhere in code.
resource "azurerm_user_assigned_identity" "services" {
  name                = "uami-${var.project}-services"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

resource "azurerm_role_assignment" "services_acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.services.principal_id
}

resource "azurerm_role_assignment" "services_kv_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.services.principal_id
}

# Lets Terraform's own identity (you, locally, or the CI service principal later)
# write secrets into the vault — e.g. the Postgres admin password below.
resource "azurerm_role_assignment" "terraform_runner_kv_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}
