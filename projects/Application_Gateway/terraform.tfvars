appgateway_name                  = "xfin-tnp-stg-eus-appgateway-test"
vnet_rg_name                     = "xfin-tnp-stg-eus-pod1"
vnet_name                        = "SC9STG"
gatewaysubnet                    = "subNet_AppGateway"
name                             = "appgateway-cd2"
resource_group_name              = "xfin-tnp-stg-eus-cd2"
location                         = "eastus"
public_ip_address_name           = "appgateway-pod1-pip"
resource_group_public_ip_address = "xfin-tnp-stg-eus-pod1"
keyvault_name                    = "xfin-tnp-dev-eus-kv"
resource_group_keyvault          = "xfin-tnp-dev-eus-admin"
appgateway_msi_name              = "appgateway-stg-msi"
waf_policy_name                  = "DenyAll_WAF_Policy"
private_ip_address               = "10.2.4.4"
waf_policy_resource_group_name   = "xfin-tnp-stg-eus-cd2"

waf_configuration = {
  firewall_mode            = "Prevention"
  rule_set_type            = "OWASP"
  rule_set_version         = "3.2"
  enabled                  = true
  file_upload_limit_mb     = 100
  request_body_check       = true
  max_request_body_size_kb = 128
}

capacity = {
  min = 0
  max = 2
}
backend_address_pools = [
  {
    fqdns = ["xfin-tnp-stg-eus-cd.azurewebsites.net", "xfin-tnp-stg-eus-cd2.azurewebsites.net"]
    name  = "backendpool-east-cd"
  },
  {
    fqdns = ["xfin-tnp-stg-wus2-cd.azurewebsites.net", "xfin-tnp-stg-wus2-cd2.azurewebsites.net"]
    name  = "backendpool-west-cd"
  },
  {
    fqdns = ["xfin-tnp-stg-wus2-cd.azurewebsites.net", "xfin-tnp-stg-wus2-cd2.azurewebsites.net", "xfin-tnp-stg-eus-cd.azurewebsites.net", "xfin-tnp-stg-eus-cd2.azurewebsites.net"]
    name  = "backendpool-undefined"
  }
]

backend_http_settings = [
  {
    name                                = "appgateway-cd-backend-htst"
    cookie_based_affinity               = "Enabled"
    affinity_cookie_name                = "ApplicationGatewayAffinity"
    enable_https                        = false
    protocol                            = "Https"
    probe_name                          = "healthcheck_probe_cd"
    request_timeout                     = 3
    pick_host_name_from_backend_address = true
    connection_draining = {
      enable_connection_draining = true
      drain_timeout_sec          = 300
    }
  },
  {
    name                                = "appgateway-cd2-backend-htst"
    cookie_based_affinity               = "Enabled"
    affinity_cookie_name                = "ApplicationGatewayAffinity"
    enable_https                        = true
    protocol                            = "Https"
    probe_name                          = "healthcheck_probe_cd2"
    request_timeout                     = 3
    pick_host_name_from_backend_address = true
    connection_draining = {
      enable_connection_draining = true
      drain_timeout_sec          = 300
    }
  }
]

http_listener_name = "layout-listener-https"

request_routing_rules = [
  {
    name                       = "layout-pb-routingrules"
    rule_type                  = "PathBasedRouting"
    priority                   = 1
    http_listener_name         = "layout-listener-https"
    backend_address_pool_name  = "backendpool-undefined"
    backend_http_settings_name = "appgateway-cd-backend-htst"
    url_map_path_name          = "layout-pb-routingrules"
  }
]

url_path_maps = [
  {
    name                               = "layout-pb-routingrules"
    default_backend_http_settings_name = "appgateway-cd-backend-htst"
    default_backend_address_pool_name  = "backendpool-undefined"
    default_rewrite_rule_set_name      = "IncomingRewrites"
    path_rules = [{
      name                       = "westonly"
      backend_address_pool_name  = "backendpool-west-cd"
      backend_http_settings_name = "appgateway-cd-backend-htst"
      paths                      = ["/west/*"]
      rewrite_rule_set_name      = "WestPathRules"
      },
      {
        name                       = "eastonly"
        backend_address_pool_name  = "backendpool-east-cd"
        backend_http_settings_name = "appgateway-cd-backend-htst"
        paths                      = ["/east/*"]
        rewrite_rule_set_name      = "EastPathRules"
      }
    ]
  }
]


health_probes = [
  {
    name                                      = "healthcheck_probe_cd"
    protocol                                  = "Https"
    pick_host_name_from_backend_http_settings = true
    path                                      = "/healthcheck"
    interval                                  = 30
    timeout                                   = 25
    unhealthy_threshold                       = 3
  },
  {
    name                                      = "healthcheck_probe_cd2"
    protocol                                  = "Https"
    pick_host_name_from_backend_http_settings = true
    path                                      = "/healthcheck"
    interval                                  = 30
    timeout                                   = 25
    unhealthy_threshold                       = 3
  }
]

rewrite_rule_set = [
  {
    name = "IncomingRewrites"

    rewrite_rule = [
      {
        name          = "DCTarget=East"
        rule_sequence = 100
        condition = [
          {
            variable    = "var_request_query"
            pattern     = "DCTarget=East"
            ignore_case = true
            negate      = false
          }
        ] #condition block ends here
        url = [
          {
            path = "/east{var_request_uri}"
            //components = "path_only"
            reroute = true
          }
        ]
      },
      {
        name          = "DCTarget=West"
        rule_sequence = 100
        condition = [
          {
            variable    = "var_request_query"
            pattern     = "DCTarget=West"
            ignore_case = true
            negate      = false
          }
        ] #condition block ends here
        url = [
          {
            path = "/west{var_request_uri}"
            //components = "path_only"
            reroute = true
          }
        ]
      },
      {
        name          = "AZ_East=1"
        rule_sequence = 100
        condition = [
          {
            variable    = "http_req_Cookie"
            pattern     = "AZ_East=1"
            ignore_case = true
            negate      = false
          }
        ] #condition block ends here
        url = [
          {
            path = "/east{var_request_uri}"
            //components = "path_only"
            reroute = true
          }
        ]
      },
      {
        name          = "AZ_West=1"
        rule_sequence = 100
        condition = [
          {
            variable    = "http_req_Cookie"
            pattern     = "AZ_West=1"
            ignore_case = true
            negate      = false
          }
        ] #condition block ends here
        url = [
          {
            path = "/west{var_request_uri}"
            //components = "path_only"
            reroute = true
          }
        ]
      }
    ]
  },
  {
    name = "EastPathRules"
    rewrite_rule = [
      {
        name          = "StripPathRouting"
        rule_sequence = 100
        condition = [
          {
            variable    = "var_uri_path"
            pattern     = "/east(.*)"
            ignore_case = true
            negate      = false
          }
        ] #condition block ends here
        url = [
          {
            path = "{var_uri_path_1}"
            //components = "path_only"
            reroute = false
          }
        ]
      }
    ]
  },
  {
    name = "WestPathRules"
    rewrite_rule = [
      {
        name          = "StripPathRouting"
        rule_sequence = 100
        condition = [
          {
            variable    = "var_uri_path"
            pattern     = "/west(.*)"
            ignore_case = true
            negate      = false
          }
        ] #condition block ends here
        url = [
          {
            path = "{var_uri_path_1}"
            //components = "path_only"
            reroute = false
          }
        ]
      }
    ]
  }
]

ssl_certificate = {
  name                = "CMS9-AIO"
  key_vault_secret_id = "https://xfin-tnp-dev-eus-kv.vault.azure.net/secrets/CMS9-AIO-July-11-2022"
}

tags = {
  "Environment"              = "Stage",
  "Cost Center"              = "IT",
  "Application Name"         = "sitecore 9 CD",
  "Application Owner"        = "Kuris, Erik",
  "Criticality"              = "High",
  "Department"               = "IT",
  "Created By"               = "Krishana Kumar",
  "Disaster Recovery"        = "NA",
  "Data Classification Type" = "Tenant Isolation",
  "Tier"                     = "2-Tier"
}

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
