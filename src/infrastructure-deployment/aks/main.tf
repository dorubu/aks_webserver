resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = "eusqrgr-k8sassign-${var.resource_suffix}"
}

# Get the ACR ID
data "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.common_resource_group_name
}

resource "azurerm_kubernetes_cluster" "k8s" {
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  name                = "eusqaks-k8sassign-${var.resource_suffix}"
  dns_prefix          = "eusqdns-k8sassign-${var.resource_suffix}"

  identity {
    type = "SystemAssigned"
  }
  default_node_pool {
    name                = "agentpool"
    vm_size             = "Standard_B2s"
    node_count          = var.node_count
    enable_auto_scaling = false
  }
  linux_profile {
    admin_username = var.username

    ssh_key {
      key_data = jsondecode(azapi_resource_action.ssh_public_key_gen.output).publicKey
    }
  }
  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
  }
}

# Assign the ACR pull role to AKS
resource "azurerm_role_assignment" "acr_role_assignment" {
  scope                            = data.azurerm_container_registry.acr.id
  principal_id                     = azurerm_kubernetes_cluster.k8s.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  skip_service_principal_aad_check = true
}
