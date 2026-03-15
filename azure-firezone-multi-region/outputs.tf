# Outputs for Multi-Region Firezone Gateway Deployment

output "load_balancer_primary" {
  description = "Primary region Firezone load balancer information"
  value = {
    id                = azurerm_lb.firezone_lb_primary.id
    name              = azurerm_lb.firezone_lb_primary.name
    public_ip_address = azurerm_public_ip.firezone_lb_pip_primary.ip_address
    fqdn              = azurerm_public_ip.firezone_lb_pip_primary.fqdn
  }
}

output "load_balancer_secondary" {
  description = "Secondary region Firezone load balancer information"
  value = {
    id                = azurerm_lb.firezone_lb_secondary.id
    name              = azurerm_lb.firezone_lb_secondary.name
    public_ip_address = azurerm_public_ip.firezone_lb_pip_secondary.ip_address
    fqdn              = azurerm_public_ip.firezone_lb_pip_secondary.fqdn
  }
}

output "traffic_manager" {
  description = "Traffic Manager profile information"
  value = {
    id   = azurerm_traffic_manager_profile.firezone_tm.id
    name = azurerm_traffic_manager_profile.firezone_tm.name
    fqdn = azurerm_traffic_manager_profile.firezone_tm.fqdn
  }
}

output "firezone_primary" {
  description = "Primary Firezone gateway information"
  value = {
    vm_id             = module.firezone_primary.firezone_gateway.id
    vm_name           = module.firezone_primary.firezone_gateway.name
    private_ip        = module.firezone_primary.firezone_gateway.private_ip_address
    region            = var.primary_region
    resource_group    = var.primary_resource_group_name
  }
}

output "firezone_secondary" {
  description = "Secondary Firezone gateway information"
  value = {
    vm_id             = module.firezone_secondary.firezone_gateway.id
    vm_name           = module.firezone_secondary.firezone_gateway.name
    private_ip        = module.firezone_secondary.firezone_gateway.private_ip_address
    region            = var.secondary_region
    resource_group    = var.secondary_resource_group_name
  }
}

output "firezone_access_info" {
  description = "Firezone access information"
  value = {
    traffic_manager_fqdn       = azurerm_traffic_manager_profile.firezone_tm.fqdn
    primary_wireguard_endpoint = "${azurerm_public_ip.firezone_lb_pip_primary.ip_address}:51820"
    secondary_wireguard_endpoint = "${azurerm_public_ip.firezone_lb_pip_secondary.ip_address}:51820"
    primary_health_check_url   = "http://${azurerm_public_ip.firezone_lb_pip_primary.ip_address}:8080"
    secondary_health_check_url = "http://${azurerm_public_ip.firezone_lb_pip_secondary.ip_address}:8080"
    primary_gateway_ip         = module.firezone_primary.firezone_gateway.private_ip_address
    secondary_gateway_ip       = module.firezone_secondary.firezone_gateway.private_ip_address
    primary_lb_ip              = azurerm_public_ip.firezone_lb_pip_primary.ip_address
    secondary_lb_ip            = azurerm_public_ip.firezone_lb_pip_secondary.ip_address
  }
}