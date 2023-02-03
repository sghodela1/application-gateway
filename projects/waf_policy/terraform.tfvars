waf_policy_name     = "DenyAll_WAF_Policy"
resource_group_name = "xfin-tnp-stg-eus-cd2"
location            = "eastus"
custom_rules = [
  {
    name      = "AkamiHeader"
    priority  = 9
    rule_type = "MatchRule"
    action    = "Block"
    match_Conditions = [
      {
        match_Variables = [
          {
            variable_Name = "RequestHeaders"
            selector      = "X_AKAMAI_HOST"
          }
        ]
        operator           = "Equal"
        negation_condition = true
        match_values       = ["true"]
        transforms         = []
      }

    ]
  },
  {
    name      = "AkamaiHostTrue"
    priority  = 10
    rule_type = "MatchRule"
    action    = "Allow"
    match_Conditions = [
      {
        match_Variables = [
          {
            variable_Name = "RequestHeaders"
            selector      = "X_AKAMAI_HOST"
          }
        ]
        operator           = "Equal"
        negation_condition = false
        match_values = [
          "true"
        ]
        transforms = []
      }

    ]
  },
  {
    name      = "BadAKHostHeader"
    priority  = 11
    rule_type = "MatchRule"
    action    = "Block"
    match_Conditions = [
      {
        match_Variables = [
          {
            variable_Name = "RequestHeaders"
            selector      = "x_akamai_host"
          }
        ]
        operator           = "Equal"
        negation_condition = true
        match_values = [
          "true"
        ]
        transforms = []
      }
    ]
  }
]

policy_settings = {
  request_body_check          = true
  max_request_body_size_in_kb = 128
  file_upload_limit_in_mb     = 100
  enabled                     = true
  mode                        = "Prevention"
}

managed_rule_set = [
  {
    rule_set_type       = "OWASP"
    rule_set_version    = "3.2"
    rule_group_override = []
  }
]


tags = {
  "Environment"              = "Stage",
  "Cost Center"              = "IT",
  "Application Name"         = "DenyAll_WAF_Policy",
  "Application Owner"        = "Kuris, Erik",
  "Criticality"              = "High",
  "Department"               = "IT",
  "Created By"               = "Krishana Kumar",
  "Disaster Recovery"        = "NA",
  "Data Classification Type" = "Tenant Isolation",
  "Tier"                     = "2-Tier"
}