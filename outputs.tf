output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "container_registry_login_server" {
  value = azurerm_container_registry.main.login_server
}

output "key_vault_uri" {
  value = azurerm_key_vault.main.vault_uri
}

output "postgres_fqdn" {
  value = azurerm_postgresql_flexible_server.main.fqdn
}

output "user_assigned_identity_id" {
  value = azurerm_user_assigned_identity.services.id
}

output "user_assigned_identity_client_id" {
  value = azurerm_user_assigned_identity.services.client_id
}

output "container_app_environment_id" {
  value = azurerm_container_app_environment.main.id
}
