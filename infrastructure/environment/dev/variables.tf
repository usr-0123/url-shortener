variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "sql_admin_password" {
  type        = string
  sensitive   = true
  description = "Azure SQL administrator password — never hardcode, use tfvars or env var"
}
