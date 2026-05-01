variable "spoke_name" {
  description = "Short name for this spoke tier: web, app, or data"
  type        = string
  validation {
    condition     = contains(["web", "app", "data"], var.spoke_name)
    error_message = "spoke_name must be one of: web, app, data."
  }
}

variable "environment" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "address_space" {
  description = "CIDR for the spoke VNet (e.g. 10.1.0.0/24)"
  type        = string
}

variable "subnet_prefix" {
  description = "CIDR for the spoke subnet — should match address_space for simple spokes"
  type        = string
}

variable "hub_vnet_id" {
  description = "Resource ID of the Hub VNet to peer with"
  type        = string
}

variable "firewall_private_ip" {
  description = "Private IP of the Azure Firewall — used as UDR next-hop"
  type        = string
}

variable "use_hub_gateway" {
  description = "Whether to route through hub VPN Gateway (requires gateway deployed)"
  type        = bool
  default     = false
}

variable "nsg_rules" {
  description = "List of NSG rules specific to this spoke tier"
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    destination_port_range     = string
    source_address_prefix      = string
  }))
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
