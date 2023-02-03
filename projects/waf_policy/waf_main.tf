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
    key                  = "waf-policy/waf_policy_DenyAll.tfstate"
    access_key           = "8IgLu/vQduvTwvaozXN2Tv6mrpH/cX4zpuwIeHQRC/O38XLtIN8X+ZOoQIT2qIAAo1rPoCybbiv/9gDutKZG3g=="
  }
}

provider "azurerm" {
  features {}
}

module "waf_policy" {
  source = "../../modules/waf_policy"

  #default configurations
  waf_policy_name     = var.waf_policy_name
  resource_group_name = var.resource_group_name
  location            = var.location

  #configuration
  custom_rules     = var.custom_rules
  policy_settings  = var.policy_settings
  managed_rule_set = var.managed_rule_set

  #tags
  tags = var.tags

}