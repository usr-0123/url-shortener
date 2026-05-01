variable "environment" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "firewall_subnet_id" { type = string }
variable "web_spoke_prefix" { type = string }
variable "app_spoke_prefix" { type = string }
variable "data_spoke_prefix" { type = string }
variable "tags" { type = map(string); default = {} }
