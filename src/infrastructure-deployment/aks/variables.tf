variable "resource_group_location" {
  type        = string
  default     = "eastus"
  description = "Location of the resource group."
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

variable "resource_suffix" {
  type        = string
  default     = "1603"
  description = "This block can be replaced by a random generated ID or a variable."
}

variable "var_resource_suffix" {
  type        = string
  default     = "1603"
  description = "Suffix for Azure resources to uniquely identify the deployment."
}

variable "node_count" {
  type        = number
  description = "The initial quantity of nodes for the node pool."
  default     = 1
}

variable "msi_id" {
  type        = string
  description = "The Managed Service Identity ID. Set this value if you're running this example using Managed Identity as the authentication method."
  default     = null
}

variable "username" {
  type        = string
  description = "The admin username for the new cluster."
  default     = "K8Sadmin"
}
