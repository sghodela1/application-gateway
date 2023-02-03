locals {
  sku_name = "WAF_v2"
  sku_tier = "WAF_v2"

  #backend_address_pool_name      = "${var.name}-backendap"
  frontend_port_name             = "${var.name}-frontendport"
  frontend_ip_configuration_name = "${var.name}-frontendip"

  merged_tags = merge(var.tags, {
    managed-by-k8s-ingress      = "",
    last-updated-by-k8s-ingress = ""
  })

  diag_resource_list = var.diagnostics != null ? split("/", var.diagnostics.destination) : []
  parsed_diag = var.diagnostics != null ? {
    log_analytics_id   = contains(local.diag_resource_list, "Microsoft.OperationalInsights") ? var.diagnostics.destination : null
    storage_account_id = contains(local.diag_resource_list, "Microsoft.Storage") ? var.diagnostics.destination : null
    event_hub_auth_id  = contains(local.diag_resource_list, "Microsoft.EventHub") ? var.diagnostics.destination : null
    metric             = var.diagnostics.metrics
    log                = var.diagnostics.logs
    } : {
    log_analytics_id   = null
    storage_account_id = null
    event_hub_auth_id  = null
    metric             = []
    log                = []
  }
}

#
# Public IP
#

data "azurerm_public_ip" "gatewaypip" {
  name                = var.public_ip_address_name
  resource_group_name = var.resource_group_public_ip_address
}

data "azurerm_subnet" "subnet" {
  name                 = var.gatewaysubnet
  virtual_network_name = var.vnet_name
  resource_group_name  = var.vnet_rg_name
}

data "azurerm_key_vault" "key-vault" {
  name                = var.keyvault_name
  resource_group_name = var.resource_group_keyvault
}

data "azurerm_key_vault_secret" "ssl-cert" {
  name         = var.ssl_certificate_name
  key_vault_id = data.azurerm_key_vault.key-vault.id
}

data "azurerm_key_vault_secret" "trusted-cert" {
  name         = var.trusted_certificate_name
  key_vault_id = data.azurerm_key_vault.key-vault.id
}

resource "azurerm_user_assigned_identity" "managed-identity" {
  name                = var.appgateway_msi_name
  location            = var.location
  resource_group_name = var.resource_group_name
}
#grant read access to managed identity at key vault
resource "azurerm_key_vault_access_policy" "kv-acces-policy" {
  key_vault_id = data.azurerm_key_vault.key-vault.id
  tenant_id    = azurerm_user_assigned_identity.managed-identity.tenant_id
  object_id    = azurerm_user_assigned_identity.managed-identity.principal_id

  key_permissions = [
    "Get",
  ]

  secret_permissions = [
    "Get",
  ]

  certificate_permissions = [
    "Get",
  ]
}

#
# Application Gateway
#

resource "azurerm_application_gateway" "main" {
  name                = var.appgateway_name
  resource_group_name = var.resource_group_name
  location            = var.location
  enable_http2        = false
  zones               = var.zones
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.managed-identity.id
    ]
  }
  ssl_certificate {
    name                = var.ssl_certificate_name
    key_vault_secret_id = trimsuffix(data.azurerm_key_vault_secret.ssl-cert.id, "${data.azurerm_key_vault_secret.ssl-cert.version}")
  }

  #trusted_root_certificate  {
  #  name = var.trusted_certificate_name
  #  key_vault_secret_id = trimsuffix(data.azurerm_key_vault_secret.trusted-cert.id, "${data.azurerm_key_vault_secret.trusted-cert.version}")
  #}

  tags = local.merged_tags

  sku {
    name = local.sku_name
    tier = local.sku_tier
  }

  waf_configuration {
    firewall_mode            = var.waf_configuration.firewall_mode // "Detection"
    rule_set_type            = var.waf_configuration.rule_set_type
    rule_set_version         = var.waf_configuration.rule_set_version // "2.2.9"
    enabled                  = var.waf_configuration.enabled
    file_upload_limit_mb     = var.waf_configuration.file_upload_limit_mb
    request_body_check       = var.waf_configuration.request_body_check
    max_request_body_size_kb = var.waf_configuration.max_request_body_size_kb
  }
  force_firewall_policy_association = true
  firewall_policy_id                = var.waf_policy_id

  autoscale_configuration {
    min_capacity = var.capacity.min
    max_capacity = var.capacity.max
  }

  gateway_ip_configuration {
    name      = "${var.name}-ip-configuration"
    subnet_id = data.azurerm_subnet.subnet.id
  }

  frontend_ip_configuration {
    name                 = "${local.frontend_ip_configuration_name}-pip"
    public_ip_address_id = data.azurerm_public_ip.gatewaypip.id
  }

  #frontend_ip_configuration {
  #  name                          = "${local.frontend_ip_configuration_name}-private"
  #  subnet_id                     = data.azurerm_subnet.subnet.id
  #  private_ip_address_allocation = "Static"
  #  private_ip_address            = var.private_ip_address
  #}
  frontend_port {
    name = "${local.frontend_port_name}-443"
    port = 443
  }

  dynamic "backend_address_pool" {
    for_each = var.backend_address_pools
    content {
      name  = backend_address_pool.value.name
      fqdns = backend_address_pool.value.fqdns
    }
  }

  dynamic "backend_http_settings" {
    for_each = var.backend_http_settings
    content {
      name                                = backend_http_settings.value.name
      cookie_based_affinity               = lookup(backend_http_settings.value, "cookie_based_affinity", "Disabled")
      affinity_cookie_name                = lookup(backend_http_settings.value, "affinity_cookie_name", null)
      path                                = lookup(backend_http_settings.value, "path", "/")
      port                                = backend_http_settings.value.enable_https ? 443 : 80
      protocol                            = backend_http_settings.value.protocol
      probe_name                          = lookup(backend_http_settings.value, "probe_name", null)
      request_timeout                     = lookup(backend_http_settings.value, "requset_timeout", 30)
      pick_host_name_from_backend_address = lookup(backend_http_settings.value, "pick_host_name_from_backend_address", false)
      host_name                           = lookup(backend_http_settings.value, "host_name", null)
      #trusted_root_certificate_names = backend_http_settings.value.trusted_root_certificate_names
      dynamic "connection_draining" {
        for_each = backend_http_settings.value.connection_draining[*]
        content {
          enabled           = connection_draining.value.enable_connection_draining
          drain_timeout_sec = connection_draining.value.drain_timeout_sec
        }
      }
    }

  }

  http_listener {
    name                           = var.http_listener_name
    frontend_ip_configuration_name = "${local.frontend_ip_configuration_name}-pip"
    frontend_port_name             = "${local.frontend_port_name}-443"
    protocol                       = "https"
    ssl_certificate_name           = var.ssl_certificate_name
  }

  dynamic "request_routing_rule" {
    for_each = var.request_routing_rules
    content {
      name                        = request_routing_rule.value.name
      rule_type                   = request_routing_rule.value.rule_type
      priority                    = request_routing_rule.value.priority
      http_listener_name          = request_routing_rule.value.http_listener_name
      redirect_configuration_name = null
      backend_address_pool_name   = request_routing_rule.value.backend_address_pool_name
      backend_http_settings_name  = request_routing_rule.value.backend_http_settings_name
      url_path_map_name           = lookup(request_routing_rule.value, "url_map_path_name", null)
    }
  }

  dynamic "probe" {
    for_each = var.health_probes
    content {
      name                                      = probe.value.name
      interval                                  = lookup(probe.value, "interval", 30)
      protocol                                  = probe.value.protocol
      path                                      = lookup(probe.value, "path", "/")
      timeout                                   = lookup(probe.value, "timeout", 30)
      unhealthy_threshold                       = lookup(probe.value, "unhealth_threshold", 2)
      pick_host_name_from_backend_http_settings = lookup(probe.value, "pick_host_name_from_backend_http_settings", false)
    }
  }

  dynamic "url_path_map" {
    for_each = var.url_path_maps
    content {
      name                                = url_path_map.value.name
      default_redirect_configuration_name = null
      default_backend_http_settings_name  = url_path_map.value.default_backend_http_settings_name
      default_backend_address_pool_name   = url_path_map.value.default_backend_address_pool_name
      default_rewrite_rule_set_name       = lookup(url_path_map.value, "default_rewrite_rule_set_name", null)

      dynamic "path_rule" {
        for_each = lookup(url_path_map.value, "path_rules")
        content {
          name                        = path_rule.value.name
          backend_address_pool_name   = path_rule.value.backend_address_pool_name
          backend_http_settings_name  = path_rule.value.backend_http_settings_name
          paths                       = flatten(path_rule.value.paths)
          redirect_configuration_name = null
          rewrite_rule_set_name       = lookup(path_rule.value, "rewrite_rule_set_name", null)
        }
      }
    }
  } #url_path_map block ends here

  dynamic "rewrite_rule_set" {
    for_each = var.rewrite_rule_set
    iterator = rset
    content {
      name = rset.value.name

      dynamic "rewrite_rule" {
        for_each = lookup(rset.value, "rewrite_rule", [])
        iterator = rule
        content {
          name          = rule.value.name
          rule_sequence = rule.value.rule_sequence

          dynamic "condition" {
            for_each = lookup(rule.value, "condition", [])
            content {
              variable    = condition.value.variable
              pattern     = condition.value.pattern
              ignore_case = condition.value.ignore_case
              negate      = condition.value.negate
            }
          } #condition block ends here

          dynamic "url" {
            for_each = lookup(rule.value, "url", [])
            content {
              path = url.value.path
              //query_string = url.value.query_string
              //components = url.value.components
              reroute = url.value.reroute #set to null, checks only the URL path, not both URL Path and query string
            }
          } #url block ends here
        }
      } #rewrite_rule block ends here

    }
  } #rewrite_rule_set block ends here


} #gateway block ends here

data "azurerm_monitor_diagnostic_categories" "default" {
  resource_id = azurerm_application_gateway.main.id
}

#diagnostics
resource "azurerm_monitor_diagnostic_setting" "main" {
  count                          = var.diagnostics != null ? 1 : 0
  name                           = "${var.name}-diag"
  target_resource_id             = azurerm_application_gateway.main.id
  log_analytics_workspace_id     = local.parsed_diag.log_analytics_id
  eventhub_authorization_rule_id = local.parsed_diag.event_hub_auth_id
  eventhub_name                  = local.parsed_diag.event_hub_auth_id != null ? var.diagnostics.eventhub_name : null
  storage_account_id             = local.parsed_diag.storage_account_id

  dynamic "log" {
    for_each = data.azurerm_monitor_diagnostic_categories.default.logs
    content {
      category = log.value
      enabled  = contains(local.parsed_diag.log, "all") || contains(local.parsed_diag.log, log.value)

      retention_policy {
        enabled = false
        days    = 0
      }
    }
  }

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.default.metrics
    content {
      category = metric.value
      enabled  = contains(local.parsed_diag.metric, "all") || contains(local.parsed_diag.metric, metric.value)

      retention_policy {
        enabled = false
        days    = 0
      }
    }
  }
}