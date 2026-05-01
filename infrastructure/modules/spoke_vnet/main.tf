# Reusable spoke module. Instantiate once per tier:
#   web  → 10.1.0.0/24
#   app  → 10.2.0.0/24
#   data → 10.3.0.0/24

resource "azurerm_virtual_network" "spoke" {
  name                = "vnet-spoke-${var.spoke_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.address_space]

  tags = var.tags
}

resource "azurerm_subnet" "spoke" {
  name                 = "snet-${var.spoke_name}-${var.environment}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [var.subnet_prefix]

  # Allow Container Apps to inject into this subnet
  delegation {
    name = "container-apps-delegation"
    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# NSG — rules differ per tier (web allows 443 inbound, data denies all inbound)
resource "azurerm_network_security_group" "spoke" {
  name                = "nsg-${var.spoke_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  dynamic "security_rule" {
    for_each = var.nsg_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = "*"
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = "*"
    }
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "spoke" {
  subnet_id                 = azurerm_subnet.spoke.id
  network_security_group_id = azurerm_network_security_group.spoke.id
}

# Route Table — forces all egress through the Azure Firewall in the hub
resource "azurerm_route_table" "spoke" {
  name                          = "rt-${var.spoke_name}-${var.environment}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  disable_bgp_route_propagation = true

  route {
    name                   = "default-to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.firewall_private_ip
  }

  tags = var.tags
}

resource "azurerm_subnet_route_table_association" "spoke" {
  subnet_id      = azurerm_subnet.spoke.id
  route_table_id = azurerm_route_table.spoke.id
}

# VNet Peering: Spoke → Hub
# use_remote_gateways lets this spoke reach on-prem via the hub's VPN Gateway
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                         = "peer-${var.spoke_name}-to-hub"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = azurerm_virtual_network.spoke.name
  remote_virtual_network_id    = var.hub_vnet_id
  allow_forwarded_traffic      = true
  use_remote_gateways          = var.use_hub_gateway
  allow_virtual_network_access = true
}
