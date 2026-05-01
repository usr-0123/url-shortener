output "vnet_id" {
  description = "Resource ID of the Hub VNet"
  value       = azurerm_virtual_network.hub.id
}

output "vnet_name" {
  description = "Name of the Hub VNet"
  value       = azurerm_virtual_network.hub.name
}

output "firewall_subnet_id" {
  description = "Resource ID of AzureFirewallSubnet"
  value       = azurerm_subnet.firewall.id
}

output "gateway_subnet_id" {
  description = "Resource ID of GatewaySubnet"
  value       = azurerm_subnet.gateway.id
}

output "shared_services_subnet_id" {
  description = "Resource ID of the shared services subnet"
  value       = azurerm_subnet.shared_services.id
}
