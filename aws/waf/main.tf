######################
# AWS WAF WebACL
######################
resource "aws_wafv2_web_acl" "this" {
  name        = var.name
  description = var.description
  scope       = var.scope

  default_action {
    dynamic "allow" {
      for_each = var.default_action == "allow" ? [1] : []
      content {}
    }

    dynamic "block" {
      for_each = var.default_action == "block" ? [1] : []
      content {}
    }
  }

  dynamic "custom_response_body" {
    for_each = {
      for rule in var.custom_rules :
      "${rule.name}-response" => rule
      if rule.action == "block" &&
      lookup(rule, "block_custom_response", null) != null &&
      lookup(lookup(rule, "block_custom_response", {}), "response_body", null) != null
    }

    content {
      key          = custom_response_body.key
      content_type = lookup(custom_response_body.value.block_custom_response, "content_type", "TEXT_PLAIN")
      content      = custom_response_body.value.block_custom_response.response_body
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = var.cloudwatch_metrics_enabled
    metric_name                = var.metric_name != null ? var.metric_name : var.name
    sampled_requests_enabled   = var.sampled_requests_enabled
  }

  # Rule groups
  dynamic "rule" {
    for_each = var.managed_rule_groups
    content {
      name     = rule.value.name
      priority = rule.value.priority

      override_action {
        dynamic "none" {
          for_each = rule.value.override_action == "none" ? [1] : []
          content {}
        }

        dynamic "count" {
          for_each = rule.value.override_action == "count" ? [1] : []
          content {}
        }
      }

      statement {
        managed_rule_group_statement {
          name        = rule.value.rule_group_name
          vendor_name = rule.value.vendor_name

          dynamic "rule_action_override" {
            for_each = lookup(rule.value, "rule_action_overrides", {})
            content {
              action_to_use {
                dynamic "allow" {
                  for_each = rule_action_override.value == "allow" ? [1] : []
                  content {}
                }

                dynamic "block" {
                  for_each = rule_action_override.value == "block" ? [1] : []
                  content {}
                }

                dynamic "count" {
                  for_each = rule_action_override.value == "count" ? [1] : []
                  content {}
                }

                dynamic "captcha" {
                  for_each = rule_action_override.value == "captcha" ? [1] : []
                  content {}
                }

                dynamic "challenge" {
                  for_each = rule_action_override.value == "challenge" ? [1] : []
                  content {}
                }
              }
              name = rule_action_override.key
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = rule.value.cloudwatch_metrics_enabled
        metric_name                = rule.value.metric_name
        sampled_requests_enabled   = rule.value.sampled_requests_enabled
      }
    }
  }

  # Custom rules
  dynamic "rule" {
    for_each = var.custom_rules
    content {
      name     = rule.value.name
      priority = rule.value.priority

      action {
        dynamic "allow" {
          for_each = rule.value.action == "allow" ? [1] : []
          content {}
        }

        dynamic "block" {
          for_each = rule.value.action == "block" && lookup(rule.value, "block_custom_response", false) == false ? [1] : []
          content {}
        }

        dynamic "block" {
          for_each = rule.value.action == "block" && lookup(rule.value, "block_custom_response", null) != null ? [1] : []
          content {
            custom_response {
              response_code = rule.value.block_custom_response.response_code

              # Make response_headers fully optional
              dynamic "response_header" {
                for_each = lookup(rule.value.block_custom_response, "response_headers", [])
                content {
                  name  = response_header.value.name
                  value = response_header.value.value
                }
              }

              # Reference the custom response body key if response_body exists
              custom_response_body_key = lookup(rule.value.block_custom_response, "response_body", null) != null ? "${rule.value.name}-response" : null
            }
          }
        }

        dynamic "count" {
          for_each = rule.value.action == "count" ? [1] : []
          content {}
        }

        dynamic "captcha" {
          for_each = rule.value.action == "captcha" ? [1] : []
          content {}
        }

        dynamic "challenge" {
          for_each = rule.value.action == "challenge" ? [1] : []
          content {}
        }
      }

      # Token domains for CAPTCHA/Challenge
      dynamic "captcha_config" {
        for_each = rule.value.action == "captcha" ? [1] : []
        content {
          immunity_time_property {
            immunity_time = lookup(rule.value, "immunity_time", 60)
          }
        }
      }

      dynamic "challenge_config" {
        for_each = rule.value.action == "challenge" ? [1] : []
        content {
          immunity_time_property {
            immunity_time = lookup(rule.value, "immunity_time", 60)
          }
        }
      }

      statement {
        # IP Set Reference Statement
        dynamic "ip_set_reference_statement" {
          for_each = lookup(rule.value.statement, "ip_set_reference_statement", null) != null ? [rule.value.statement.ip_set_reference_statement] : []
          content {
            arn = ip_set_reference_statement.value.arn
          }
        }

        # Geo Match Statement
        dynamic "geo_match_statement" {
          for_each = lookup(rule.value.statement, "geo_match_statement", null) != null ? [rule.value.statement.geo_match_statement] : []
          content {
            country_codes = geo_match_statement.value.country_codes
          }
        }

        # Byte Match Statement
        dynamic "byte_match_statement" {
          for_each = lookup(rule.value.statement, "byte_match_statement", null) != null ? [rule.value.statement.byte_match_statement] : []
          content {
            field_to_match {
              dynamic "uri_path" {
                for_each = byte_match_statement.value.field_to_match == "uri_path" ? [1] : []
                content {}
              }
              dynamic "query_string" {
                for_each = byte_match_statement.value.field_to_match == "query_string" ? [1] : []
                content {}
              }
              dynamic "header" {
                for_each = byte_match_statement.value.field_to_match == "header" ? [1] : []
                content {
                  name = byte_match_statement.value.header_name
                }
              }
              dynamic "method" {
                for_each = byte_match_statement.value.field_to_match == "method" ? [1] : []
                content {}
              }
              dynamic "body" {
                for_each = byte_match_statement.value.field_to_match == "body" ? [1] : []
                content {}
              }
              dynamic "single_query_argument" {
                for_each = byte_match_statement.value.field_to_match == "single_query_argument" ? [1] : []
                content {
                  name = byte_match_statement.value.single_query_argument_name
                }
              }
              dynamic "all_query_arguments" {
                for_each = byte_match_statement.value.field_to_match == "all_query_arguments" ? [1] : []
                content {}
              }
              dynamic "json_body" {
                for_each = byte_match_statement.value.field_to_match == "json_body" ? [1] : []
                content {
                  match_scope = lookup(byte_match_statement.value, "json_match_scope", "ALL")
                  match_pattern {
                    included_paths = lookup(byte_match_statement.value, "json_included_paths", [])
                  }
                }
              }
            }

            positional_constraint = byte_match_statement.value.positional_constraint
            search_string         = byte_match_statement.value.search_string

            text_transformation {
              priority = byte_match_statement.value.text_transformation.priority
              type     = byte_match_statement.value.text_transformation.type
            }
          }
        }

        # Rate Based Statement
        dynamic "rate_based_statement" {
          for_each = lookup(rule.value.statement, "rate_based_statement", null) != null ? [rule.value.statement.rate_based_statement] : []
          content {
            limit                 = rate_based_statement.value.limit
            aggregate_key_type    = lookup(rate_based_statement.value, "aggregate_key_type", "IP")
            evaluation_window_sec = lookup(rate_based_statement.value, "evaluation_window_sec", null)

            # Scope Down Statement (nested statements to further refine rate limiting)
            dynamic "scope_down_statement" {
              for_each = lookup(rate_based_statement.value, "scope_down_statement", null) != null ? [rate_based_statement.value.scope_down_statement] : []
              content {
                # Byte Match Statement in scope down
                dynamic "byte_match_statement" {
                  for_each = lookup(scope_down_statement.value, "byte_match_statement", null) != null ? [scope_down_statement.value.byte_match_statement] : []
                  content {
                    field_to_match {
                      dynamic "uri_path" {
                        for_each = byte_match_statement.value.field_to_match == "uri_path" ? [1] : []
                        content {}
                      }
                      dynamic "query_string" {
                        for_each = byte_match_statement.value.field_to_match == "query_string" ? [1] : []
                        content {}
                      }
                      dynamic "header" {
                        for_each = byte_match_statement.value.field_to_match == "header" ? [1] : []
                        content {
                          name = byte_match_statement.value.header_name
                        }
                      }
                      dynamic "method" {
                        for_each = byte_match_statement.value.field_to_match == "method" ? [1] : []
                        content {}
                      }
                      dynamic "body" {
                        for_each = byte_match_statement.value.field_to_match == "body" ? [1] : []
                        content {}
                      }
                    }
                    positional_constraint = byte_match_statement.value.positional_constraint
                    search_string         = byte_match_statement.value.search_string
                    text_transformation {
                      priority = byte_match_statement.value.text_transformation.priority
                      type     = byte_match_statement.value.text_transformation.type
                    }
                  }
                }

                # Geo Match Statement in scope down
                dynamic "geo_match_statement" {
                  for_each = lookup(scope_down_statement.value, "geo_match_statement", null) != null ? [scope_down_statement.value.geo_match_statement] : []
                  content {
                    country_codes = geo_match_statement.value.country_codes
                  }
                }

                # IP Set Reference Statement in scope down
                dynamic "ip_set_reference_statement" {
                  for_each = lookup(scope_down_statement.value, "ip_set_reference_statement", null) != null ? [scope_down_statement.value.ip_set_reference_statement] : []
                  content {
                    arn = ip_set_reference_statement.value.arn
                  }
                }

                # AND logic statement in scope down
                dynamic "and_statement" {
                  for_each = lookup(scope_down_statement.value, "and_statement", null) != null ? [scope_down_statement.value.and_statement] : []
                  content {
                    dynamic "statement" {
                      for_each = and_statement.value.statements
                      content {
                        dynamic "byte_match_statement" {
                          for_each = lookup(statement.value, "byte_match_statement", null) != null ? [statement.value.byte_match_statement] : []
                          content {
                            field_to_match {
                              dynamic "uri_path" {
                                for_each = byte_match_statement.value.field_to_match == "uri_path" ? [1] : []
                                content {}
                              }
                              dynamic "query_string" {
                                for_each = byte_match_statement.value.field_to_match == "query_string" ? [1] : []
                                content {}
                              }
                              dynamic "header" {
                                for_each = byte_match_statement.value.field_to_match == "header" ? [1] : []
                                content {
                                  name = byte_match_statement.value.header_name
                                }
                              }
                              dynamic "method" {
                                for_each = byte_match_statement.value.field_to_match == "method" ? [1] : []
                                content {}
                              }
                              dynamic "body" {
                                for_each = byte_match_statement.value.field_to_match == "body" ? [1] : []
                                content {}
                              }
                            }
                            positional_constraint = byte_match_statement.value.positional_constraint
                            search_string         = byte_match_statement.value.search_string
                            text_transformation {
                              priority = byte_match_statement.value.text_transformation.priority
                              type     = byte_match_statement.value.text_transformation.type
                            }
                          }
                        }

                        dynamic "geo_match_statement" {
                          for_each = lookup(statement.value, "geo_match_statement", null) != null ? [statement.value.geo_match_statement] : []
                          content {
                            country_codes = geo_match_statement.value.country_codes
                          }
                        }

                        dynamic "ip_set_reference_statement" {
                          for_each = lookup(statement.value, "ip_set_reference_statement", null) != null ? [statement.value.ip_set_reference_statement] : []
                          content {
                            arn = ip_set_reference_statement.value.arn
                          }
                        }
                      }
                    }
                  }
                }

                # OR logic statement in scope down
                dynamic "or_statement" {
                  for_each = lookup(scope_down_statement.value, "or_statement", null) != null ? [scope_down_statement.value.or_statement] : []
                  content {
                    dynamic "statement" {
                      for_each = or_statement.value.statements
                      content {
                        dynamic "byte_match_statement" {
                          for_each = lookup(statement.value, "byte_match_statement", null) != null ? [statement.value.byte_match_statement] : []
                          content {
                            field_to_match {
                              dynamic "uri_path" {
                                for_each = byte_match_statement.value.field_to_match == "uri_path" ? [1] : []
                                content {}
                              }
                              dynamic "query_string" {
                                for_each = byte_match_statement.value.field_to_match == "query_string" ? [1] : []
                                content {}
                              }
                              dynamic "header" {
                                for_each = byte_match_statement.value.field_to_match == "header" ? [1] : []
                                content {
                                  name = byte_match_statement.value.header_name
                                }
                              }
                              dynamic "method" {
                                for_each = byte_match_statement.value.field_to_match == "method" ? [1] : []
                                content {}
                              }
                              dynamic "body" {
                                for_each = byte_match_statement.value.field_to_match == "body" ? [1] : []
                                content {}
                              }
                            }
                            positional_constraint = byte_match_statement.value.positional_constraint
                            search_string         = byte_match_statement.value.search_string
                            text_transformation {
                              priority = byte_match_statement.value.text_transformation.priority
                              type     = byte_match_statement.value.text_transformation.type
                            }
                          }
                        }

                        dynamic "geo_match_statement" {
                          for_each = lookup(statement.value, "geo_match_statement", null) != null ? [statement.value.geo_match_statement] : []
                          content {
                            country_codes = geo_match_statement.value.country_codes
                          }
                        }

                        dynamic "ip_set_reference_statement" {
                          for_each = lookup(statement.value, "ip_set_reference_statement", null) != null ? [statement.value.ip_set_reference_statement] : []
                          content {
                            arn = ip_set_reference_statement.value.arn
                          }
                        }
                      }
                    }
                  }
                }

                # NOT logic statement in scope down - FIXED: now using statement (singular)
                dynamic "not_statement" {
                  for_each = lookup(scope_down_statement.value, "not_statement", null) != null ? [scope_down_statement.value.not_statement] : []
                  content {
                    # NOT requires a single statement, not multiple statements
                    statement {
                      dynamic "byte_match_statement" {
                        for_each = lookup(not_statement.value.statement, "byte_match_statement", null) != null ? [not_statement.value.statement.byte_match_statement] : []
                        content {
                          field_to_match {
                            dynamic "uri_path" {
                              for_each = byte_match_statement.value.field_to_match == "uri_path" ? [1] : []
                              content {}
                            }
                            dynamic "query_string" {
                              for_each = byte_match_statement.value.field_to_match == "query_string" ? [1] : []
                              content {}
                            }
                            dynamic "header" {
                              for_each = byte_match_statement.value.field_to_match == "header" ? [1] : []
                              content {
                                name = byte_match_statement.value.header_name
                              }
                            }
                            dynamic "method" {
                              for_each = byte_match_statement.value.field_to_match == "method" ? [1] : []
                              content {}
                            }
                            dynamic "body" {
                              for_each = byte_match_statement.value.field_to_match == "body" ? [1] : []
                              content {}
                            }
                          }
                          positional_constraint = byte_match_statement.value.positional_constraint
                          search_string         = byte_match_statement.value.search_string
                          text_transformation {
                            priority = byte_match_statement.value.text_transformation.priority
                            type     = byte_match_statement.value.text_transformation.type
                          }
                        }
                      }

                      dynamic "geo_match_statement" {
                        for_each = lookup(not_statement.value.statement, "geo_match_statement", null) != null ? [not_statement.value.statement.geo_match_statement] : []
                        content {
                          country_codes = geo_match_statement.value.country_codes
                        }
                      }

                      dynamic "ip_set_reference_statement" {
                        for_each = lookup(not_statement.value.statement, "ip_set_reference_statement", null) != null ? [not_statement.value.statement.ip_set_reference_statement] : []
                        content {
                          arn = ip_set_reference_statement.value.arn
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }

        # SQL Injection protection
        dynamic "sqli_match_statement" {
          for_each = lookup(rule.value.statement, "sqli_match_statement", null) != null ? [rule.value.statement.sqli_match_statement] : []
          content {
            field_to_match {
              dynamic "uri_path" {
                for_each = sqli_match_statement.value.field_to_match == "uri_path" ? [1] : []
                content {}
              }
              dynamic "query_string" {
                for_each = sqli_match_statement.value.field_to_match == "query_string" ? [1] : []
                content {}
              }
              dynamic "header" {
                for_each = sqli_match_statement.value.field_to_match == "header" ? [1] : []
                content {
                  name = sqli_match_statement.value.header_name
                }
              }
              dynamic "body" {
                for_each = sqli_match_statement.value.field_to_match == "body" ? [1] : []
                content {}
              }
            }

            text_transformation {
              priority = sqli_match_statement.value.text_transformation.priority
              type     = sqli_match_statement.value.text_transformation.type
            }
          }
        }

        # XSS protection
        dynamic "xss_match_statement" {
          for_each = lookup(rule.value.statement, "xss_match_statement", null) != null ? [rule.value.statement.xss_match_statement] : []
          content {
            field_to_match {
              dynamic "uri_path" {
                for_each = xss_match_statement.value.field_to_match == "uri_path" ? [1] : []
                content {}
              }
              dynamic "query_string" {
                for_each = xss_match_statement.value.field_to_match == "query_string" ? [1] : []
                content {}
              }
              dynamic "header" {
                for_each = xss_match_statement.value.field_to_match == "header" ? [1] : []
                content {
                  name = xss_match_statement.value.header_name
                }
              }
              dynamic "body" {
                for_each = xss_match_statement.value.field_to_match == "body" ? [1] : []
                content {}
              }
            }

            text_transformation {
              priority = xss_match_statement.value.text_transformation.priority
              type     = xss_match_statement.value.text_transformation.type
            }
          }
        }

        # Regex pattern matching
        dynamic "regex_pattern_set_reference_statement" {
          for_each = lookup(rule.value.statement, "regex_pattern_set_reference_statement", null) != null ? [rule.value.statement.regex_pattern_set_reference_statement] : []
          content {
            arn = regex_pattern_set_reference_statement.value.arn
            field_to_match {
              dynamic "uri_path" {
                for_each = regex_pattern_set_reference_statement.value.field_to_match == "uri_path" ? [1] : []
                content {}
              }
              dynamic "query_string" {
                for_each = regex_pattern_set_reference_statement.value.field_to_match == "query_string" ? [1] : []
                content {}
              }
              dynamic "header" {
                for_each = regex_pattern_set_reference_statement.value.field_to_match == "header" ? [1] : []
                content {
                  name = regex_pattern_set_reference_statement.value.header_name
                }
              }
            }

            text_transformation {
              priority = regex_pattern_set_reference_statement.value.text_transformation.priority
              type     = regex_pattern_set_reference_statement.value.text_transformation.type
            }
          }
        }

        # Size constraint statement - FIXED: Implemented field_to_match properly
        dynamic "size_constraint_statement" {
          for_each = lookup(rule.value.statement, "size_constraint_statement", null) != null ? [rule.value.statement.size_constraint_statement] : []
          content {
            field_to_match {
              dynamic "uri_path" {
                for_each = size_constraint_statement.value.field_to_match == "uri_path" ? [1] : []
                content {}
              }
              dynamic "query_string" {
                for_each = size_constraint_statement.value.field_to_match == "query_string" ? [1] : []
                content {}
              }
              dynamic "single_header" {
                for_each = size_constraint_statement.value.field_to_match == "header" ? [1] : []
                content {
                  name = size_constraint_statement.value.header_name
                }
              }
              dynamic "method" {
                for_each = size_constraint_statement.value.field_to_match == "method" ? [1] : []
                content {}
              }
              dynamic "body" {
                for_each = size_constraint_statement.value.field_to_match == "body" ? [1] : []
                content {}
              }
            }

            comparison_operator = size_constraint_statement.value.comparison_operator
            size                = size_constraint_statement.value.size

            text_transformation {
              priority = size_constraint_statement.value.text_transformation.priority
              type     = size_constraint_statement.value.text_transformation.type
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = rule.value.cloudwatch_metrics_enabled
        metric_name                = rule.value.metric_name
        sampled_requests_enabled   = rule.value.sampled_requests_enabled
      }
    }
  }

  token_domains = var.token_domains

  tags = var.tags
}

######################
# WAF IP Set
######################
resource "aws_wafv2_ip_set" "this" {
  for_each = var.ip_sets

  name               = each.key
  description        = lookup(each.value, "description", null)
  scope              = var.scope
  ip_address_version = lookup(each.value, "ip_address_version", "IPV4")
  addresses          = each.value.addresses

  tags = var.tags
}

######################
# WAF Logging Configuration
######################
# In aws/modules/waf/main.tf, replace your logging configuration with:
resource "aws_wafv2_web_acl_logging_configuration" "this" {
  count = var.logging_enabled ? 1 : 0

  resource_arn            = aws_wafv2_web_acl.this.arn
  log_destination_configs = [var.log_destination_arn]

  # Method
  dynamic "redacted_fields" {
    for_each = [for f in var.redacted_fields : f if f.type == "method"]
    content {
      method {}
    }
  }

  # Query String
  dynamic "redacted_fields" {
    for_each = [for f in var.redacted_fields : f if f.type == "query_string"]
    content {
      query_string {}
    }
  }

  # URI Path
  dynamic "redacted_fields" {
    for_each = [for f in var.redacted_fields : f if f.type == "uri_path"]
    content {
      uri_path {}
    }
  }

  # Single Header
  dynamic "redacted_fields" {
    for_each = [for f in var.redacted_fields : f if f.type == "single_header"]
    content {
      single_header {
        name = redacted_fields.value.name
      }
    }
  }

  # Conditional logging filter - only add if NOT logging all requests
  dynamic "logging_filter" {
    for_each = var.logging_config.log_all_requests ? [] : [1]
    content {
      default_behavior = "DROP"

      # Log blocked requests
      dynamic "filter" {
        for_each = var.logging_config.log_blocked_only ? [1] : []
        content {
          behavior    = "KEEP"
          requirement = "MEETS_ALL"

          condition {
            action_condition {
              action = "BLOCK"
            }
          }
        }
      }

      # Log allowed requests
      dynamic "filter" {
        for_each = var.logging_config.log_allowed_only ? [1] : []
        content {
          behavior    = "KEEP"
          requirement = "MEETS_ALL"

          condition {
            action_condition {
              action = "ALLOW"
            }
          }
        }
      }

      # Log counted requests
      dynamic "filter" {
        for_each = var.logging_config.log_counted_only ? [1] : []
        content {
          behavior    = "KEEP"
          requirement = "MEETS_ALL"

          condition {
            action_condition {
              action = "COUNT"
            }
          }
        }
      }

      # Log CAPTCHA requests
      dynamic "filter" {
        for_each = var.logging_config.log_captcha_only ? [1] : []
        content {
          behavior    = "KEEP"
          requirement = "MEETS_ALL"

          condition {
            action_condition {
              action = "CAPTCHA"
            }
          }
        }
      }

      # Log Challenge requests
      dynamic "filter" {
        for_each = var.logging_config.log_challenge_only ? [1] : []
        content {
          behavior    = "KEEP"
          requirement = "MEETS_ALL"

          condition {
            action_condition {
              action = "CHALLENGE"
            }
          }
        }
      }

      # Custom filters
      dynamic "filter" {
        for_each = var.logging_config.custom_filters
        content {
          behavior    = filter.value.behavior
          requirement = filter.value.requirement

          # Action conditions
          dynamic "condition" {
            for_each = filter.value.actions
            content {
              action_condition {
                action = condition.value
              }
            }
          }

          # Label conditions (for advanced filtering)
          dynamic "condition" {
            for_each = filter.value.label_conditions
            content {
              label_name_condition {
                label_name = condition.value.label_name
              }
            }
          }
        }
      }
    }
  }
}

######################
# WAF Associations
######################
resource "aws_wafv2_web_acl_association" "this" {
  for_each = var.resource_arns

  resource_arn = each.value
  web_acl_arn  = aws_wafv2_web_acl.this.arn

  # This ensures the WAF waits for the ALB resources
  depends_on = [var.depends_on_resources]
}
######################
# WAF Regex Pattern Set
######################
resource "aws_wafv2_regex_pattern_set" "this" {
  for_each = var.regex_pattern_sets

  name        = each.key
  description = lookup(each.value, "description", null)
  scope       = var.scope

  regular_expression {
    regex_string = each.value.regex_string
  }

  tags = var.tags
}
