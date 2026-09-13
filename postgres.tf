resource "random_password" "postgres_admin" {
  length      = 24
  special     = true
  min_upper   = 2
  min_lower   = 2
  min_numeric = 2
  min_special = 2
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                = "psql-${var.project}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  delegated_subnet_id = azurerm_subnet.postgres.id
  private_dns_zone_id = azurerm_private_dns_zone.postgres.id

  sku_name   = var.postgres_sku_name
  storage_mb = 32768
  version    = "16"

  administrator_login    = var.postgres_admin_username
  administrator_password = random_password.postgres_admin.result

  # Both auth methods — services authenticate via Entra tokens through the
  # managed identity (no stored password); the admin login above is the
  # break-glass path for migrations and emergency access. Mirrors the
  # "PostgreSQL and Microsoft Entra authentication" choice from the portal.
  authentication {
    active_directory_auth_enabled = true
    password_auth_enabled         = true
  }

  zone = "1"

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
}

resource "azurerm_postgresql_flexible_server_active_directory_administrator" "main" {
  server_name         = azurerm_postgresql_flexible_server.main.name
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = var.entra_admin_object_id
  principal_name      = var.entra_admin_login
  principal_type      = var.entra_admin_principal_type
}

# One database per microservice, same server — cheaper for phase 1, and each
# service's connection string still only ever points at its own database.
resource "azurerm_postgresql_flexible_server_database" "auth" {
  name      = "auth_db"
  server_id = azurerm_postgresql_flexible_server.main.id
}

resource "azurerm_postgresql_flexible_server_database" "profile" {
  name      = "profile_db"
  server_id = azurerm_postgresql_flexible_server.main.id
}

resource "azurerm_postgresql_flexible_server_database" "post" {
  name      = "post_db"
  server_id = azurerm_postgresql_flexible_server.main.id
}

# The break-glass password lives only in Key Vault — never in a plain output,
# never in app config.
resource "azurerm_key_vault_secret" "postgres_admin_password" {
  name         = "postgres-admin-password"
  value        = random_password.postgres_admin.result
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_role_assignment.terraform_runner_kv_officer]
}
