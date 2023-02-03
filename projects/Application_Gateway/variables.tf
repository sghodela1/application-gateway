variable "appgateway_name" {
  type        = string
  description = "Name of the spoke virtual network."
  default     = "xfin-tnp-stg-eus2-appgateway-pod1"
}

variable "vnet_rg_name" {
  type        = string
  description = "Name of the resource group for virtual network."
  default     = ""
}
variable "vnet_name" {
  type        = string
  description = "Name of the virtual network."
  default     = ""
}

variable "gatewaysubnet" {
  type        = string
  description = "Name of gateway subnet to deploy application gateway in."
  default     = ""
}

variable "name" {
  type        = string
  description = "Name of the spoke virtual network."
  default     = "appgateway-pod1"
}

variable "resource_group_name" {
  type        = string
  description = "Name of resource group to deploy resources in."
  default     = "xfin-tnp-stg-eus-pod1"
}

variable "location" {
  type        = string
  description = "The Azure Region in which to create resource."
  default     = "eastus"
}

variable "public_ip_address_name" {
  type        = string
  description = "Name of public ip address for application gateway"
  default     = ""
}

variable "resource_group_public_ip_address" {
  type        = string
  description = "Name of the resource group of public ip address for application gateway"
  default     = ""
}

variable "keyvault_name" {
  type        = string
  description = "Name of key vault for ssl certificate"
  default     = ""
}

variable "resource_group_keyvault" {
  type        = string
  description = "Name of resource group of key vault for ssl certificate"
  default     = ""
}

variable "appgateway_msi_name" {
  type        = string
  description = "Name of managed identiy"
  default     = ""
}

variable "waf_policy_name" {
  type        = string
  description = "Name of WAF policy to be attached to application gateway"
  default     = ""
}

variable "private_ip_address" {
  type        = string
  description = "Private ip address to be assigned to application gateway"
  default     = ""
}

variable "capacity" {
  description = "Min and max capacity for auto scaling"
  type = object({
    min = number
    max = number
  })
  default = null
}

variable "waf_configuration" {
  description = "waf policy configuration"
  type = object({
    firewall_mode            = string
    rule_set_type            = string
    rule_set_version         = string
    enabled                  = bool
    file_upload_limit_mb     = number
    request_body_check       = bool
    max_request_body_size_kb = number
  })
  default = null
}

variable "diagnostics" {
  description = "Diagnostic settings for those resources that support it. See README.md for details on configuration."
  type = object({
    destination   = string
    eventhub_name = string
    logs          = list(string)
    metrics       = list(string)
  })
  default = null
}

variable "zones" {
  description = "A collection of availability zones to spread the Application Gateway over."
  type        = list(string)
  default     = null
}

variable "http_listener_name" {
  description = "Name of listener"
  type        = string
}

variable "backend_address_pools" {
  description = "list of backend address pools"
  type = list(object({
    name  = string
    fqdns = optional(list(string))
  }))
}

variable "backend_http_settings" {
  description = "List of backend http settings"
  type = list(object({
    name                                = string
    cookie_based_affinity               = string
    affinity_cookie_name                = optional(string)
    path                                = optional(string)
    enable_https                        = bool
    protocol                            = string
    probe_name                          = optional(string)
    request_timeout                     = number
    host_name                           = optional(string)
    pick_host_name_from_backend_address = optional(string)
    trusted_root_certificate_names = list(string)
    connection_draining = optional(object({
      enable_connection_draining = bool
      drain_timeout_sec          = number
    }))
  }))
}

variable "request_routing_rules" {
  description = "List of request routing rules used by listeners"
  type = list(object({
    name                       = string
    rule_type                  = string
    priority                   = number
    http_listener_name         = string
    backend_address_pool_name  = optional(string)
    backend_http_settings_name = optional(string)
    url_map_path_name          = optional(string)
  }))
}

variable "health_probes" {
  description = "List of health probes used to test backend pools health"
  type = list(object({
    name                                      = string
    pick_host_name_from_backend_http_settings = optional(bool)
    protocol                                  = string
    interval                                  = number
    path                                      = string
    timeout                                   = number
    unhealthy_threshold                       = number
    port                                      = optional(number)
  }))
}

variable "url_path_maps" {
  description = "list of URL path maps associated to path-based rules"
  type = list(object({
    name                               = string
    default_backend_http_settings_name = optional(string)
    default_backend_address_pool_name  = optional(string)
    default_rewrite_rule_set_name      = optional(string)
    path_rules = optional(list(object({
      name                       = string
      backend_address_pool_name  = optional(string)
      backend_http_settings_name = optional(string)
      paths                      = list(string)
      rewrite_rule_set_name      = optional(string)
    })))
  }))
}

variable "rewrite_rule_set" {
  description = "List of rewrite rule sets"
  type = list(object({
    name = string
    rewrite_rule = list(object({
      name          = string
      rule_sequence = number
      condition = list(object({
        variable    = string
        pattern     = string
        ignore_case = bool
        negate      = bool
      }))
      url = list(object({
        path = string
        //query_string = optional(string)
        //components = optional(string)
        reroute = bool
      }))
    }))
  }))
}

variable "trusted_certificate_name" {
  type        = string
  description = "Name of certificate upload in key value for trust"
}

variable "ssl_certificate_name" {
  type        = string
  description = "Name of certificate upload in key value for ssl"
}

variable "tags" {
  description = "Tags to apply to all resources created."
  type        = map(string)
  default = {
    "Environment"              = "Stage",
    "Cost Center"              = "IT",
    "Application Name"         = "xfin-tnp-stg-eus-jss",
    "Application Owner"        = "Capple, Ryan",
    "Criticality"              = "High",
    "Department"               = "IT",
    "Created By"               = "Krishana Kumar",
    "Disaster Recovery"        = "NA",
    "Data Classification Type" = "Tenant Isolation",
    "Tier"                     = "2-Tier"
  }
}

variable "waf_policy_resource_group_name" {
  type        = string
  description = "Name of resource group of waf policy"
}

variable "custom_rules" {
  description = ""
  type = list(object({
    name      = string
    priority  = number
    rule_type = string
    action    = string
    match_Conditions = list(object({
      match_Variables = list(object({
        variable_Name = string
        selector      = string
      }))
      operator           = string
      negation_condition = optional(bool)
      match_values       = optional(list(string))
      transforms         = optional(list(string))
    }))
  }))
}
variable "policy_settings" {
  description = ""
  type = object({
    request_body_check          = bool
    max_request_body_size_in_kb = number
    file_upload_limit_in_mb     = number
    enabled                     = bool
    mode                        = string
  })
}

variable "managed_rule_set" {
  description = ""
  type = list(object({
    rule_set_type       = string
    rule_set_version    = string
    rule_group_override = optional(list(string))
  }))
}
