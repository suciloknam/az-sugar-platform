resource "azurerm_container_registry" "main" {
  # Must be globally unique, alphanumeric only, no hyphens — rename in tfvars if taken.
  name                = "acr${var.project}${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"

  # Admin user stays off — image pulls go through the managed identity's AcrPull
  # role assignment (see identity.tf), never a shared username/password.
  admin_enabled = false
}
