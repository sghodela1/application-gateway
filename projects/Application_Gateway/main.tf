terraform {
  required_version = ">= 0.13"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.99.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "xfin-tnp-eus-prod-shared"
    storage_account_name = "xfintnpeusprodsharedtf"
    container_name       = "xfin-tnp-eus-shared-tf-state"
    key                  = "cd-appgateway/reg0-cd.tfstate"
  }
}

provider "azurerm" {
  features {}
}

module "waf_policy" {
  source = "../../modules/waf_policy"
  #default configurations
  waf_policy_name     = var.waf_policy_name
  resource_group_name = var.waf_policy_resource_group_name
  location            = var.location

  #configuration
  custom_rules     = var.custom_rules
  policy_settings  = var.policy_settings
  managed_rule_set = var.managed_rule_set

  #tags
  tags = var.tags
}

module "appgateway" {
  source = "../../modules/ApplicationGateway"

  #default configurations
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  #network configuration
  appgateway_name                  = var.appgateway_name
  vnet_rg_name                     = var.vnet_rg_name
  vnet_name                        = var.vnet_name
  gatewaysubnet                    = var.gatewaysubnet
  public_ip_address_name           = var.public_ip_address_name
  resource_group_public_ip_address = var.resource_group_public_ip_address
  keyvault_name                    = var.keyvault_name
  resource_group_keyvault          = var.resource_group_keyvault
  appgateway_msi_name              = var.appgateway_msi_name
  waf_policy_id                    = module.waf_policy.waf_policy_id #var.waf_policy_name
  private_ip_address               = var.private_ip_address
  backend_address_pools            = var.backend_address_pools
  #scaling
  capacity = var.capacity

  waf_configuration = var.waf_configuration
  #monitoring
  diagnostics = var.diagnostics

  #application gateway settings
  zones = var.zones

  rewrite_rule_set         = var.rewrite_rule_set
  ssl_certificate_name     = var.ssl_certificate_name
  trusted_certificate_name = var.trusted_certificate_name
  http_listener_name       = var.http_listener_name
  backend_http_settings    = var.backend_http_settings
  request_routing_rules    = var.request_routing_rules
  health_probes            = var.health_probes
  url_path_maps            = var.url_path_maps

  #tags
  tags = var.tags

}