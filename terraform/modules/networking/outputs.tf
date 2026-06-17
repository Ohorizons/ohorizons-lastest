output "vnet_id" {
  description = "Virtual Network ID"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Virtual Network name"
  value       = azurerm_virtual_network.main.name
}

output "subnet_ids" {
  description = "Subnet IDs"
  value = {
    aks_nodes         = azurerm_subnet.aks_nodes.id
    aks_pods          = azurerm_subnet.aks_pods.id
    private_endpoints = azurerm_subnet.private_endpoints.id
  }
}

output "aks_subnet_id" {
  description = "AKS nodes subnet ID"
  value       = azurerm_subnet.aks_nodes.id
}

output "private_dns_zone_ids" {
  description = "Private DNS zone IDs"
  value = {
    for key, zone in azurerm_private_dns_zone.zones : key => zone.id
  }
}

output "private_dns_zone_names" {
  description = "Private DNS zone names"
  value = {
    for key, zone in azurerm_private_dns_zone.zones : key => zone.name
  }
}

output "public_dns_zone_id" {
  description = "Public DNS zone ID"
  value       = var.create_dns_zone ? azurerm_dns_zone.public[0].id : null
}

output "public_dns_zone_name_servers" {
  description = "Public DNS zone name servers"
  value       = var.create_dns_zone ? azurerm_dns_zone.public[0].name_servers : null
}

output "bastion_hostname" {
  description = "Azure Bastion hostname"
  value       = var.enable_bastion ? azurerm_bastion_host.main[0].dns_name : null
}

output "nsg_ids" {
  description = "Network Security Group IDs"
  value = {
    aks_nodes         = azurerm_network_security_group.aks_nodes.id
    private_endpoints = azurerm_network_security_group.private_endpoints.id
  }
}
