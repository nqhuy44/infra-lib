
resource "github_repository_ruleset" "this" {
  for_each = { for m in var.repositories : m.name => m }

  name       = var.name
  repository = each.value.name

  target      = var.target
  enforcement = var.enforcement

  dynamic "bypass_actors" {
    for_each = var.bypass_actors
    content {
      actor_id    = bypass_actors.value.actor_id
      actor_type  = bypass_actors.value.actor_type
      bypass_mode = bypass_actors.value.bypass_mode
    }
  }

  conditions {
    ref_name {
      include = var.include
      exclude = var.exclude
    }
  }

  rules {
    # Optional boolean rules
    creation                      = var.creation
    deletion                      = var.deletion
    non_fast_forward              = var.non_fast_forward
    update                        = var.update
    update_allows_fetch_and_merge = var.update_allows_fetch_and_merge

    # Optional object rules using dynamic blocks
    dynamic "merge_queue" {
      for_each = var.merge_queue == null ? [] : [var.merge_queue]
      content {
        check_response_timeout_minutes    = try(merge_queue.value.check_response_timeout_minutes, null)
        grouping_strategy                 = try(merge_queue.value.grouping_strategy, null)
        max_entries_to_build              = try(merge_queue.value.max_entries_to_build, null)
        max_entries_to_merge              = try(merge_queue.value.max_entries_to_merge, null)
        merge_method                      = try(merge_queue.value.merge_method, null)
        min_entries_to_merge              = try(merge_queue.value.min_entries_to_merge, null)
        min_entries_to_merge_wait_minutes = try(merge_queue.value.min_entries_to_merge_wait_minutes, null)
      }
    }

    dynamic "branch_name_pattern" {
      for_each = var.branch_name_pattern == null ? [] : [var.branch_name_pattern]
      content {
        name     = try(branch_name_pattern.value.name, "branch_name_pattern_${each.key}")
        operator = branch_name_pattern.value.operator
        pattern  = branch_name_pattern.value.pattern
        negate   = try(branch_name_pattern.value.negate, false)
      }
    }

    dynamic "commit_author_email_pattern" {
      for_each = var.commit_author_email_pattern == null ? [] : [var.commit_author_email_pattern]
      content {
        name     = try(commit_author_email_pattern.value.name, "commit_author_email_pattern_${each.key}")
        operator = commit_author_email_pattern.value.operator
        pattern  = commit_author_email_pattern.value.pattern
        negate   = try(commit_author_email_pattern.value.negate, false)
      }
    }

    dynamic "commit_message_pattern" {
      for_each = var.commit_message_pattern == null ? [] : [var.commit_message_pattern]
      content {
        name     = try(commit_message_pattern.value.name, "commit_message_pattern_${each.key}")
        operator = commit_message_pattern.value.operator
        pattern  = commit_message_pattern.value.pattern
        negate   = try(commit_message_pattern.value.negate, false)
      }
    }

    dynamic "committer_email_pattern" {
      for_each = var.committer_email_pattern == null ? [] : [var.committer_email_pattern]
      content {
        name     = try(committer_email_pattern.value.name, "committer_email_pattern_${each.key}")
        operator = committer_email_pattern.value.operator
        pattern  = committer_email_pattern.value.pattern
        negate   = try(committer_email_pattern.value.negate, false)
      }
    }

    dynamic "pull_request" {
      for_each = var.pull_request == null ? [] : [var.pull_request]
      content {
        dismiss_stale_reviews_on_push     = try(pull_request.value.dismiss_stale_reviews_on_push, null)
        require_code_owner_review         = try(pull_request.value.require_code_owner_review, null)
        require_last_push_approval        = try(pull_request.value.require_last_push_approval, null)
        required_approving_review_count   = try(pull_request.value.required_approving_review_count, null)
        required_review_thread_resolution = try(pull_request.value.required_review_thread_resolution, null)
      }
    }

    dynamic "required_deployments" {
      for_each = var.required_deployments == null ? [] : [var.required_deployments]
      content {
        required_deployment_environments = required_deployments.value.required_deployment_environments
      }
    }

    dynamic "required_status_checks" {
      for_each = var.required_status_checks == null ? [] : [var.required_status_checks]
      content {
        required_check {
          context        = required_status_checks.value.required_check.context
          integration_id = required_status_checks.value.required_check.integration_id
        }
        strict_required_status_checks_policy = try(required_status_checks.value.strict_required_status_checks_policy, null)
        do_not_enforce_on_create             = try(required_status_checks.value.do_not_enforce_on_create, null)
      }
    }

    dynamic "tag_name_pattern" {
      for_each = var.tag_name_pattern == null ? [] : [var.tag_name_pattern]
      content {
        name     = try(tag_name_pattern.value.name, "tag_name_pattern_${each.key}")
        operator = tag_name_pattern.value.operator
        pattern  = tag_name_pattern.value.pattern
        negate   = try(tag_name_pattern.value.negate, false)
      }
    }

    dynamic "required_code_scanning" {
      for_each = var.required_code_scanning == null ? [] : [var.required_code_scanning]
      content {
        required_code_scanning_tool {
          alerts_threshold          = required_code_scanning.value.required_code_scanning_tool.alerts_threshold
          security_alerts_threshold = required_code_scanning.value.required_code_scanning_tool.security_alerts_threshold
          tool                      = required_code_scanning.value.required_code_scanning_tool.tool
        }
      }
    }

    dynamic "file_path_restriction" {
      for_each = var.file_path_restriction == null ? [] : [var.file_path_restriction]
      content {
        restricted_file_paths = file_path_restriction.value.restricted_file_paths
      }
    }

    dynamic "max_file_size" {
      for_each = var.max_file_size == null ? [] : [var.max_file_size]
      content {
        max_file_size = max_file_size.value.max_file_size
      }
    }

    dynamic "max_file_path_length" {
      for_each = var.max_file_path_length == null ? [] : [var.max_file_path_length]
      content {
        max_file_path_length = max_file_path_length.value.max_file_path_length
      }
    }

    dynamic "file_extension_restriction" {
      for_each = var.file_extension_restriction == null ? [] : [var.file_extension_restriction]
      content {
        restricted_file_extensions = file_extension_restriction.value.restricted_file_extensions
      }
    }
  }
}

# resource "github_repository_file" "pull_request_template" {
#   for_each = { for m in var.repositories : m.name => m }
#   repository          = each.value.name
#   file                = ".github/pull_request_template.md"
#   content             = file("${path.module}/templates/pull_request_template.md")
#   branch              = each.value.default_branch
#   commit_message      = "Add pull request template"
#   overwrite_on_create = true
# }
