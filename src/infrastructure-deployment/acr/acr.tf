provider "azurerm" {
  features {}
}

variable "common_resource_group_name" {
  type        = string
  default     = "eusqrgr8sassign-common"
  description = "Name of the resource group that holds shared resources."
}

variable "acr_name" {
  type        = string
  default     = "eusqacrk8sassign"
  description = "The name of the ACR holding the images for the AKS Cluster."
}

resource "azurerm_resource_group" "rgr_common" {
  name     = var.common_resource_group_name
  location = "East US"
}

resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rgr_common.name
  location            = azurerm_resource_group.rgr_common.location
  sku                 = "Basic"
  admin_enabled       = false
}
