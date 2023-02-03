variable "waf_policy_name" {

}
variable "resource_group_name" {

}
variable "location" {

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


variable "tags" {
  description = "Tags to apply to all resources created."
  type        = map(string)
}