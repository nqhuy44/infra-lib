variable "name" {
  description = "The name of the ruleset."
  type        = string
}

variable "repositories" {
  description = "List of repository names to apply the ruleset to."
  type        = list(any)
}

variable "target" {
  description = "The target type for the ruleset (e.g., 'branch')."
  type        = string
  default     = "branch"
}

variable "enforcement" {
  description = "Enforcement level: 'active' or 'evaluate'."
  type        = string
  default     = "active"
}

variable "bypass_actors" {
  description = "List of actors allowed to bypass rules."
  type = list(object({
    actor_id    = string
    actor_type  = string
    bypass_mode = string
  }))
  default = []
}

variable "include" {
  description = "Branch pattern to include."
  type        = list(string)
  default     = []
}

variable "exclude" {
  description = "Branch pattern to exclude."
  type        = list(string)
  default     = []
}

variable "creation" {
  description = "Enable creation rule."
  type        = bool
  default     = null
}

variable "deletion" {
  description = "Enable deletion rule."
  type        = bool
  default     = null
}

variable "non_fast_forward" {
  description = "Enable non-fast-forward rule."
  type        = bool
  default     = null
}

variable "update" {
  description = "Enable update rule."
  type        = bool
  default     = null
}

variable "update_allows_fetch_and_merge" {
  description = "Allow fetch and merge on update. Only valid if update is set."
  type        = bool
  default     = null
}

variable "merge_queue" {
  description = "Merge queue rule object."
  type = object({
    check_response_timeout_minutes    = optional(number)
    grouping_strategy                 = optional(string)
    max_entries_to_build              = optional(number)
    max_entries_to_merge              = optional(number)
    merge_method                      = optional(string)
    min_entries_to_merge              = optional(number)
    min_entries_to_merge_wait_minutes = optional(number)
  })
  default = null
}

variable "branch_name_pattern" {
  description = "Branch name pattern rule object."
  type = object({
    operator = string
    pattern  = string
    name     = optional(string)
    negate   = optional(bool)
  })
  default = null
}

variable "commit_author_email_pattern" {
  description = "Commit author email pattern rule object."
  type = object({
    operator = string
    pattern  = string
    name     = optional(string)
    negate   = optional(bool)
  })
  default = null
}

variable "commit_message_pattern" {
  description = "Commit message pattern rule object."
  type = object({
    operator = string
    pattern  = string
    name     = optional(string)
    negate   = optional(bool)
  })
  default = null
}

variable "committer_email_pattern" {
  description = "Committer email pattern rule object."
  type = object({
    operator = string
    pattern  = string
    name     = optional(string)
    negate   = optional(bool)
  })
  default = null
}

variable "pull_request" {
  description = "Pull request rule object."
  type = object({
    dismiss_stale_reviews_on_push     = optional(bool)
    require_code_owner_review         = optional(bool)
    require_last_push_approval        = optional(bool)
    required_approving_review_count   = optional(number)
    required_review_thread_resolution = optional(bool)
  })
  default = null
}

variable "required_deployments" {
  description = "Required deployments rule object."
  type = object({
    required_deployment_environments = list(string)
  })
  default = null
}

variable "required_status_checks" {
  description = "Required status checks rule object."
  type = object({
    required_check = object({
      context        = string
      integration_id = string
    })
    strict_required_status_checks_policy = optional(bool)
    do_not_enforce_on_create             = optional(bool)
  })
  default = null
}

variable "tag_name_pattern" {
  description = "Tag name pattern rule object."
  type = object({
    operator = string
    pattern  = string
    name     = optional(string)
    negate   = optional(bool)
  })
  default = null
}

variable "required_code_scanning" {
  description = "Required code scanning rule object."
  type = object({
    required_code_scanning_tool = object({
      alerts_threshold          = number
      security_alerts_threshold = number
      tool                      = string
    })
  })
  default = null
}

variable "file_path_restriction" {
  description = "File path restriction rule object."
  type = object({
    restricted_file_paths = list(string)
  })
  default = null
}

variable "max_file_size" {
  description = "Max file size rule object."
  type = object({
    max_file_size = number
  })
  default = null
}

variable "max_file_path_length" {
  description = "Max file path length rule object."
  type = object({
    max_file_path_length = number
  })
  default = null
}

variable "file_extension_restriction" {
  description = "File extension restriction rule object."
  type = object({
    restricted_file_extensions = list(string)
  })
  default = null
}

variable "default_branch" {
  description = "default branch of repos"
  type        = string
  default     = "develop"
}