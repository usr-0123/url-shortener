resource "azurerm_public_ip" "firewall" {
  name                = "pip-firewall-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_firewall_policy" "main" {
  name                = "afwp-snipurl-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_firewall" "main" {
  name                = "afw-snipurl-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  firewall_policy_id  = azurerm_firewall_policy.main.id

  ip_configuration {
    name                 = "configuration"
    subnet_id            = var.firewall_subnet_id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }

  tags = var.tags
}

# Application rule: allow outbound HTTPS to specific FQDNs only
resource "azurerm_firewall_policy_rule_collection_group" "app_rules" {
  name               = "rcg-app-rules"
  firewall_policy_id = azurerm_firewall_policy.main.id
  priority           = 200

  application_rule_collection {
    name     = "allow-outbound-https"
    priority = 200
    action   = "Allow"

    rule {
      name = "allow-azure-services"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["10.0.0.0/8"]
      destination_fqdns = [
        "*.azure.com",
        "*.microsoft.com",
        "*.azurewebsites.net",
        "*.azurecr.io",
        "mcr.microsoft.com",
      ]
    }
  }

  # Network rule: allow spoke-to-spoke traffic on specific ports only
  network_rule_collection {
    name     = "allow-spoke-to-spoke"
    priority = 100
    action   = "Allow"

    rule {
      name                  = "web-to-app-api"
      protocols             = ["TCP"]
      source_addresses      = [var.web_spoke_prefix]
      destination_addresses = [var.app_spoke_prefix]
      destination_ports     = ["3001"]   # Node.js API port
    }

    rule {
      name                  = "app-to-data-sql"
      protocols             = ["TCP"]
      source_addresses      = [var.app_spoke_prefix]
      destination_addresses = [var.data_spoke_prefix]
      destination_ports     = ["1433"]   # Azure SQL
    }
  }
}
