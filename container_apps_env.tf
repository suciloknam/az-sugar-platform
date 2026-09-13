# The shared environment every microservice (Auth, Profile, Post, Feed) deploys
# into as an individual Container App — shared network and logging, independent
# scaling and deploys per service.
resource "azurerm_container_app_environment" "main" {
  name                = "cae-${var.project}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  infrastructure_subnet_id   = azurerm_subnet.container_apps.id

  # Set true once you add API Management/Front Door in front and want the
  # environment fully private with no public ingress at all.
  internal_load_balancer_enabled = false
}
