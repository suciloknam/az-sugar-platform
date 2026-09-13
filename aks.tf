# Replace the old snet-containerapps block in network.tf with this.
# Azure CNI Overlay means pods draw IPs from an internal overlay range, not
# the VNet, so nodes are the only thing consuming this subnet's addresses —
# a /24 comfortably supports this cluster.
resource "azurerm_subnet" "aks" {
  name                 = "snet-aks"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.3.0/24"]
}

# A dedicated identity for the cluster's control plane, created ahead of the
# cluster itself. This sidesteps a real Terraform chicken-and-egg problem:
# AKS needs "Network Contributor" on its subnet to manage load balancers and
# NICs, but a SystemAssigned identity doesn't exist to grant that role to
# until the cluster is already created. A pre-created UserAssigned identity
# breaks the cycle.
resource "azurerm_user_assigned_identity" "aks_control_plane" {
  name                = "uami-${var.project}-aks-cp"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = azurerm_subnet.aks.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_control_plane.principal_id
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${var.project}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "aks-${var.project}-${var.environment}"

  # Lets pods authenticate to Azure (Key Vault, Postgres, storage) via
  # federated tokens instead of node-level credentials — the exact same OIDC
  # trust pattern you just set up for GitHub Actions, now applied per-pod.
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    name                 = "system"
    vm_size              = "Standard_D2s_v3"
    vnet_subnet_id       = azurerm_subnet.aks.id
    auto_scaling_enabled = true
    min_count            = 2
    max_count            = 4
    zones                = ["1", "2"]
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks_control_plane.id]
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "azure"
    load_balancer_sku   = "standard"
  }

  depends_on = [azurerm_role_assignment.aks_network_contributor]
}

# The cluster's separate kubelet identity (auto-created by AKS) is what
# actually pulls images — grant it ACR access.
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

# Federated credential: a specific Kubernetes service account (apps namespace,
# social-services-sa) can now assume uami-social-services with zero secrets —
# the same identity that would have powered Container Apps, now trusted via
# the AKS OIDC issuer instead.
resource "azurerm_federated_identity_credential" "workload_identity" {
  name                = "fic-${var.project}-services"
  resource_group_name = azurerm_resource_group.main.name
  parent_id           = azurerm_user_assigned_identity.services.id
  issuer              = azurerm_kubernetes_cluster.main.oidc_issuer_url
  subject             = "system:serviceaccount:apps:social-services-sa"
  audience            = ["api://AzureADTokenExchange"]
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.main.name
}

output "aks_oidc_issuer_url" {
  value = azurerm_kubernetes_cluster.main.oidc_issuer_url
}
