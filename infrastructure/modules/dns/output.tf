output "private_dns_zone_id" {
  value = azurerm_private_dns_zone.main.id
}

output "traffic_manager_fqdn" {
  description = "Public DNS name for Traffic Manager — point your domain CNAME here"
  value       = azurerm_traffic_manager_profile.main.fqdn
}
