# Private DNS Zone — resolves *.internal.snipurl.local within all VNets
resource "azurerm_private_dns_zone" "main" {
  name                = var.dns_zone_name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Link zone to hub and all spokes so every VNet can resolve internal names
resource "azurerm_private_dns_zone_virtual_network_link" "links" {
  for_each = var.vnet_links

  name                  = "link-${each.key}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.main.name
  virtual_network_id    = each.value
  registration_enabled  = lookup(var.auto_registration_vnets, each.key, false)
  tags                  = var.tags
}

# Traffic Manager — Priority routing for geo-failover demo
# Primary endpoint (active region) gets priority 1; secondary gets priority 2.
# When primary fails its health check, Traffic Manager updates DNS to secondary.
resource "azurerm_traffic_manager_profile" "main" {
  name                   = "tm-snipurl-${var.environment}"
  resource_group_name    = var.resource_group_name
  traffic_routing_method = "Priority"

  dns_config {
    relative_name = "snipurl-${var.environment}"
    ttl           = 30   # Low TTL so failover is visible quickly during demo
  }

  monitor_config {
    protocol                     = "HTTPS"
    port                         = 443
    path                         = "/api/health"
    interval_in_seconds          = 30
    timeout_in_seconds           = 10
    tolerated_number_of_failures = 2
  }

  tags = var.tags
}

resource "azurerm_traffic_manager_azure_endpoint" "primary" {
  name               = "endpoint-primary"
  profile_id         = azurerm_traffic_manager_profile.main.id
  target_resource_id = var.primary_app_public_ip_id
  priority           = 1
  enabled            = true
}

resource "azurerm_traffic_manager_azure_endpoint" "secondary" {
  count              = var.secondary_app_public_ip_id != null ? 1 : 0
  name               = "endpoint-secondary"
  profile_id         = azurerm_traffic_manager_profile.main.id
  target_resource_id = var.secondary_app_public_ip_id
  priority           = 2
  enabled            = true
}
