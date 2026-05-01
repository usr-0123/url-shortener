variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group to deploy into"
  type        = string
}

variable "hub_address_space" {
  description = "CIDR block for the Hub VNet"
  type        = string
  default     = "10.0.0.0/16"
}

variable "firewall_subnet_prefix" {
  description = "CIDR for AzureFirewallSubnet (must be /26 or larger)"
  type        = string
  default     = "10.0.0.0/26"
}

variable "gateway_subnet_prefix" {
  description = "CIDR for GatewaySubnet"
  type        = string
  default     = "10.0.1.0/27"
}

variable "shared_services_subnet_prefix" {
  description = "CIDR for shared services subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "spoke_vnet_ids" {
  description = "Map of spoke name → VNet resource ID for peering"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
