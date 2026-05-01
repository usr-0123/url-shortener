output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "firewall_private_ip" {
  value       = module.firewall.firewall_private_ip
  description = "Used as UDR next-hop in spoke route tables"
}

output "traffic_manager_fqdn" {
  value       = module.dns.traffic_manager_fqdn
  description = "Point your CNAME record here for custom domain"
}

output "container_app_name" {
  value = "ca-snipurl-${var.environment}"
}
