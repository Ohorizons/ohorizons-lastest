# =============================================================================
# OPEN HORIZONS PLATFORM - NETWORKING TERRAFORM MODULE
# =============================================================================
#
# Creates Azure networking infrastructure for the platform.
#
# Components:
#   - Virtual Network with multiple subnets
#   - Network Security Groups
#   - Private DNS Zones
#   - Private Endpoints for Azure services
#   - Azure Bastion (optional)
#
# =============================================================================

# NOTE: Terraform block is in versions.tf

# =============================================================================
# LOCALS
# =============================================================================

locals {
  name_prefix = "${var.customer_name}-${var.environment}"

  common_tags = merge(var.tags, {
    "open-horizons/customer"    = var.customer_name
    "open-horizons/environment" = var.environment
    "open-horizons/component"   = "networking"
  })

  # Private DNS zones for Azure services
  private_dns_zones = {
    "postgres"          = "privatelink.postgres.database.azure.com"
    "redis"             = "privatelink.redis.cache.windows.net"
    "keyvault"          = "privatelink.vaultcore.azure.net"
    "acr"               = "privatelink.azurecr.io"
    "blob"              = "privatelink.blob.core.windows.net"
    "openai"            = "privatelink.openai.azure.com"
    "cognitiveservices" = "privatelink.cognitiveservices.azure.com"
    "search"            = "privatelink.search.windows.net"
  }
}

# =============================================================================
# VIRTUAL NETWORK
# =============================================================================

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${local.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.vnet_cidr]

  tags = local.common_tags
}

# =============================================================================
# SUBNETS
# =============================================================================

# AKS Nodes Subnet
resource "azurerm_subnet" "aks_nodes" {
  name                 = "snet-aks-nodes"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_config.aks_nodes_cidr]

  # Required for Azure CNI Overlay
  delegation {
    name = "aks-delegation"
    service_delegation {
      name    = "Microsoft.ContainerService/managedClusters"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# AKS Pods Subnet (for Azure CNI with dynamic IP allocation)
resource "azurerm_subnet" "aks_pods" {
  name                 = "snet-aks-pods"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_config.aks_pods_cidr]

  delegation {
    name = "aks-pods-delegation"
    service_delegation {
      name    = "Microsoft.ContainerService/managedClusters"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# Private Endpoints Subnet
resource "azurerm_subnet" "private_endpoints" {
  name                 = "snet-private-endpoints"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_config.private_endpoints_cidr]

  private_endpoint_network_policies_enabled = true
}

# Azure Bastion Subnet (if enabled)
resource "azurerm_subnet" "bastion" {
  count = var.enable_bastion ? 1 : 0

  name                 = "AzureBastionSubnet" # Must be this exact name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_config.bastion_cidr]
}

# Application Gateway Subnet (if enabled)
resource "azurerm_subnet" "app_gateway" {
  count = var.enable_app_gateway ? 1 : 0

  name                 = "snet-app-gateway"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_config.app_gateway_cidr]
}

# =============================================================================
# NETWORK SECURITY GROUPS
# =============================================================================

# AKS Nodes NSG
resource "azurerm_network_security_group" "aks_nodes" {
  name                = "nsg-aks-nodes-${local.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Allow internal VNet traffic
  security_rule {
    name                       = "AllowVNetInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  # Allow Azure Load Balancer
  security_rule {
    name                       = "AllowAzureLoadBalancerInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  # Allow HTTP/HTTPS from internet (via load balancer)
  security_rule {
    name                       = "AllowHTTPSInbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  # Deny all other inbound
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

resource "azurerm_subnet_network_security_group_association" "aks_nodes" {
  subnet_id                 = azurerm_subnet.aks_nodes.id
  network_security_group_id = azurerm_network_security_group.aks_nodes.id
}

# Private Endpoints NSG
resource "azurerm_network_security_group" "private_endpoints" {
  name                = "nsg-private-endpoints-${local.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Allow traffic from VNet only
  security_rule {
    name                       = "AllowVNetInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  # Deny all other inbound
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

resource "azurerm_subnet_network_security_group_association" "private_endpoints" {
  subnet_id                 = azurerm_subnet.private_endpoints.id
  network_security_group_id = azurerm_network_security_group.private_endpoints.id
}

# =============================================================================
# PRIVATE DNS ZONES
# =============================================================================

resource "azurerm_private_dns_zone" "zones" {
  for_each = local.private_dns_zones

  name                = each.value
  resource_group_name = var.resource_group_name

  tags = local.common_tags
}

# Link private DNS zones to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "links" {
  for_each = local.private_dns_zones

  name                  = "link-${each.key}-${local.name_prefix}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.zones[each.key].name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false

  tags = local.common_tags
}

# =============================================================================
# PUBLIC DNS ZONE
# =============================================================================

resource "azurerm_dns_zone" "public" {
  count = var.create_dns_zone ? 1 : 0

  name                = var.dns_zone_name
  resource_group_name = var.resource_group_name

  tags = local.common_tags
}

# =============================================================================
# AZURE BASTION (Optional)
# =============================================================================

resource "azurerm_public_ip" "bastion" {
  count = var.enable_bastion ? 1 : 0

  name                = "pip-bastion-${local.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.common_tags
}

resource "azurerm_bastion_host" "main" {
  count = var.enable_bastion ? 1 : 0

  name                = "bastion-${local.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion[0].id
    public_ip_address_id = azurerm_public_ip.bastion[0].id
  }

  sku = "Standard"

  tunneling_enabled      = true
  file_copy_enabled      = true
  copy_paste_enabled     = true
  shareable_link_enabled = false

  tags = local.common_tags
}

# =============================================================================
# OUTPUTS
# =============================================================================


