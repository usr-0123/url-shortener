# TODO: Implement container_apps module
# See docs/INFRASTRUCTURE.md for design notes and expected resources.
# Resources to add:
#   vpn_gateway    → azurerm_public_ip, azurerm_virtual_network_gateway, azurerm_local_network_gateway, azurerm_virtual_network_gateway_connection
#   load_balancer  → azurerm_lb (Standard, internal), azurerm_lb_backend_address_pool, azurerm_lb_probe, azurerm_lb_rule
#   container_apps → azurerm_container_app_environment (VNet-injected), azurerm_container_app, azurerm_container_registry
