variable "environment" { type = string }
variable "resource_group_name" { type = string }
variable "dns_zone_name" { type = string; default = "internal.snipurl.local" }
variable "vnet_links" { type = map(string); description = "Map of name → VNet ID to link" }
variable "auto_registration_vnets" { type = map(bool); default = {} }
variable "primary_app_public_ip_id" { type = string }
variable "secondary_app_public_ip_id" { type = string; default = null }
variable "tags" { type = map(string); default = {} }
