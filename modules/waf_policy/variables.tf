variable "waf_policy_name" {
type = string
description = "Name of WAF policy"
}
variable "resource_group_name" {
type = string
description = "Name of resource group for WAF policy"
}
variable "location" {
type = string
description = "Name of location for WAF policy"
}

variable "custom_rules" {
  description = "definition for rules in WAF"
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
  description = "WAF policy settings"
  type = object({
    request_body_check          = bool
    max_request_body_size_in_kb = number
    file_upload_limit_in_mb     = number
    enabled                     = bool
    mode                        = string
  })
}

variable "managed_rule_set" {
  description = "WAF rule set"
  type =  list(object({
      rule_set_type       = string
      rule_set_version    = string
      rule_group_override = optional(list(string))
    }))
}


variable "tags" {
  description = "Tags to apply to all resources created."
  type        = map(string)
}