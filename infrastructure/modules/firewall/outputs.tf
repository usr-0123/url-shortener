output "firewall_private_ip" {
  description = "Private IP used as next-hop in spoke route tables"
  value       = azurerm_firewall.main.ip_configuration[0].private_ip_address
}

output "firewall_public_ip" {
  value = azurerm_public_ip.firewall.ip_address
}

output "firewall_id" {
  value = azurerm_firewall.main.id
}
