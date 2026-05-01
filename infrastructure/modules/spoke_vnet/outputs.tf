output "vnet_id" {
  value = azurerm_virtual_network.spoke.id
}

output "vnet_name" {
  value = azurerm_virtual_network.spoke.name
}

output "subnet_id" {
  value = azurerm_subnet.spoke.id
}

output "nsg_id" {
  value = azurerm_network_security_group.spoke.id
}

output "route_table_id" {
  value = azurerm_route_table.spoke.id
}
