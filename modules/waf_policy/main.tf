resource "azurerm_web_application_firewall_policy" "waf_policy" {
  name                = var.waf_policy_name
  resource_group_name = var.resource_group_name
  location            = var.location

  dynamic "custom_rules" {
    for_each = var.custom_rules
    iterator = custom_rule
    content {
      name      = custom_rule.value.name
      priority  = custom_rule.value.priority
      rule_type = custom_rule.value.rule_type
      action    = custom_rule.value.action

      dynamic "match_conditions" {
        for_each = custom_rule.value.match_Conditions
        iterator = match_condition
        content {
          dynamic "match_variables" {
            for_each = match_condition.value.match_Variables
            iterator = match_variable
            content {
              variable_name = match_variable.value.variable_Name
              selector      = match_variable.value.selector
            }
          }
          operator           = match_condition.value.operator
          negation_condition = match_condition.value.negation_condition
          match_values       = match_condition.value.match_values
        }
      }
    }
  }

  policy_settings {
    request_body_check          = var.policy_settings.request_body_check
    max_request_body_size_in_kb = var.policy_settings.max_request_body_size_in_kb
    file_upload_limit_in_mb     = var.policy_settings.file_upload_limit_in_mb
    enabled                     = var.policy_settings.enabled
    mode                        = var.policy_settings.mode
  }

  managed_rules{
    dynamic "managed_rule_set" {
      for_each = var.managed_rule_set
      content {
        type       = managed_rule_set.value.rule_set_type
        version    = managed_rule_set.value.rule_set_version
        //rule_group_override = managed_rule_set.value.rule_group_override
      }
    }
  }
  tags = var.tags
}

output "waf_policy_id" {
  value = azurerm_web_application_firewall_policy.waf_policy.id
}