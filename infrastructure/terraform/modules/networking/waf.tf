resource "azurerm_web_application_firewall_policy" "main" {
  name                = "${var.environment}-waf-policy"
  resource_group_name = var.resource_group_name
  location            = var.location

  policy_settings {
    enabled                     = true
    mode                       = var.environment == "prod" ? "Prevention" : "Detection"
    file_upload_limit_in_mb    = 100
    max_request_body_size_in_kb = 128
    request_body_check         = true
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
      
      rule_group_override {
        rule_group_name = "REQUEST-920-PROTOCOL-ENFORCEMENT"
        disabled_rules  = var.environment == "prod" ? [] : ["920300", "920320"]
      }

      rule_group_override {
        rule_group_name = "REQUEST-930-APPLICATION-ATTACK-LFI"
        disabled_rules  = var.environment == "prod" ? [] : ["930120"]
      }

      rule_group_override {
        rule_group_name = "REQUEST-942-APPLICATION-ATTACK-SQLI"
        disabled_rules  = []  # Always enable SQL injection protection
      }
    }
  }

  custom_rules {
    name      = "BlockMaliciousUserAgents"
    priority  = 1
    rule_type = "MatchRule"
    
    match_conditions {
      match_variables {
        variable_name = "RequestHeaders"
        selector     = "User-Agent"
      }
      operator           = "Contains"
      negation_condition = false
      match_values      = ["sqlmap", "nikto", "nessus", "nmap"]
    }
    action = "Block"
  }

  dynamic "custom_rules" {
    for_each = var.environment == "prod" ? [1] : []
    content {
      name      = "RateLimitPerIP"
      priority  = 2
      rule_type = "RateLimitRule"
      
      match_conditions {
        match_variables {
          variable_name = "RemoteAddr"
        }
      }
      rate_limit_duration = "FIVE_MINUTES"
      rate_limit_threshold = 2000
      action = "Block"
    }
  }

  tags = merge(var.default_tags, {
    Environment = var.environment
  })
}

# Associate WAF policy with Application Gateway
resource "azurerm_application_gateway_waf_policy_association" "main" {
  application_gateway_id = azurerm_application_gateway.main.id
  waf_policy_id         = azurerm_web_application_firewall_policy.main.id
}