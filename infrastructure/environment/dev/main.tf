terraform {
  required_version = ">= 1.7"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  # Uncomment and configure after running `az storage account create` for state:
  # backend "azurerm" {
  #   resource_group_name  = "rg-tfstate"
  #   storage_account_name = "stsnipurltfstate"
  #   container_name       = "tfstate"
  #   key                  = "dev.terraform.tfstate"
  # }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

locals {
  tags = {
    project     = "snipurl"
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "azurerm_resource_group" "main" {
  name     = "rg-snipurl-${var.environment}"
  location = var.location
  tags     = local.tags
}

# Firewall (deployed before spokes — spokes need the private IP for UDR)

module "hub_vnet" {
  source = "../../modules/hub_vnet"

  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  hub_address_space   = "10.0.0.0/16"

  # Spoke VNet IDs added after spoke modules run (use depends_on below)
  spoke_vnet_ids = {
    web  = module.spoke_web.vnet_id
    app  = module.spoke_app.vnet_id
    data = module.spoke_data.vnet_id
  }

  tags = local.tags
}

module "firewall" {
  source = "../../modules/firewall"

  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  firewall_subnet_id  = module.hub_vnet.firewall_subnet_id
  web_spoke_prefix    = "10.1.0.0/24"
  app_spoke_prefix    = "10.2.0.0/24"
  data_spoke_prefix   = "10.3.0.0/24"
  tags                = local.tags
}

# Spoke VNets

module "spoke_web" {
  source = "../../modules/spoke_vnet"

  spoke_name          = "web"
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = "10.1.0.0/24"
  subnet_prefix       = "10.1.0.0/24"
  hub_vnet_id         = module.hub_vnet.vnet_id
  firewall_private_ip = module.firewall.firewall_private_ip

  nsg_rules = [
    {
      name                   = "allow-https-inbound"
      priority               = 100
      direction              = "Inbound"
      access                 = "Allow"
      protocol               = "Tcp"
      destination_port_range = "443"
      source_address_prefix  = "AzureLoadBalancer"
    }
  ]

  tags = local.tags
}

module "spoke_app" {
  source = "../../modules/spoke_vnet"

  spoke_name          = "app"
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = "10.2.0.0/24"
  subnet_prefix       = "10.2.0.0/24"
  hub_vnet_id         = module.hub_vnet.vnet_id
  firewall_private_ip = module.firewall.firewall_private_ip

  nsg_rules = [
    {
      name                   = "allow-api-from-web-spoke"
      priority               = 100
      direction              = "Inbound"
      access                 = "Allow"
      protocol               = "Tcp"
      destination_port_range = "3001"
      source_address_prefix  = "10.1.0.0/24"
    },
    {
      name                   = "deny-all-other-inbound"
      priority               = 4000
      direction              = "Inbound"
      access                 = "Deny"
      protocol               = "*"
      destination_port_range = "*"
      source_address_prefix  = "*"
    }
  ]

  tags = local.tags
}

module "spoke_data" {
  source = "../../modules/spoke_vnet"

  spoke_name          = "data"
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = "10.3.0.0/24"
  subnet_prefix       = "10.3.0.0/24"
  hub_vnet_id         = module.hub_vnet.vnet_id
  firewall_private_ip = module.firewall.firewall_private_ip

  nsg_rules = [
    {
      name                   = "allow-sql-from-app-spoke"
      priority               = 100
      direction              = "Inbound"
      access                 = "Allow"
      protocol               = "Tcp"
      destination_port_range = "1433"
      source_address_prefix  = "10.2.0.0/24"
    },
    {
      name                   = "deny-all-other-inbound"
      priority               = 4000
      direction              = "Inbound"
      access                 = "Deny"
      protocol               = "*"
      destination_port_range = "*"
      source_address_prefix  = "*"
    }
  ]

  tags = local.tags
}

# Shared services: DNS + Traffic Manager

module "dns" {
  source = "../../modules/dns"

  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name

  vnet_links = {
    hub  = module.hub_vnet.vnet_id
    web  = module.spoke_web.vnet_id
    app  = module.spoke_app.vnet_id
    data = module.spoke_data.vnet_id
  }

  auto_registration_vnets = {
    web = true
    app = true
  }

  primary_app_public_ip_id = module.hub_vnet.vnet_id  # TODO: replace with App Gateway PIP
  tags                     = local.tags
}
