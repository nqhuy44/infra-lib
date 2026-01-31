# Control what resources to create
variable "create_users" {
  description = "Whether to create IAM users"
  type        = bool
  default     = true
}

variable "create_groups" {
  description = "Whether to create IAM groups"
  type        = bool
  default     = true
}

variable "create_roles" {
  description = "Whether to create IAM roles"
  type        = bool
  default     = true
}

variable "create_policies" {
  description = "Whether to create IAM policies"
  type        = bool
  default     = true
}

variable "create_password_policy" {
  description = "Whether to create account password policy"
  type        = bool
  default     = false
}

# Flexible data structures that different repos can populate differently
variable "users" {
  description = "List of IAM users to create with flexible configuration"
  type = list(object({
    name                    = string
    path                    = optional(string)
    force_destroy           = optional(bool)
    console_access          = optional(bool)
    create_access_key       = optional(bool)
    access_key_status       = optional(string)
    pgp_key                 = optional(string)
    password_reset_required = optional(bool)
    password_length         = optional(number)
    groups                  = optional(list(string))
    policy_arns             = optional(list(string))
    inline_policies         = optional(map(string))
    tags                    = optional(map(string))
  }))
  default = []

  validation {
    condition = alltrue([
      for user in var.users : can(regex("^[a-zA-Z0-9+=,.@_-]+$", user.name))
    ])
    error_message = "User names must contain only alphanumeric characters and +=,.@_- symbols."
  }
}

variable "groups" {
  description = "List of IAM groups to create with flexible configuration"
  type = list(object({
    name            = string
    path            = optional(string)
    policy_arns     = optional(list(string))
    inline_policies = optional(map(string))
    tags            = optional(map(string))
  }))
  default = []

  validation {
    condition = alltrue([
      for group in var.groups : can(regex("^[a-zA-Z0-9+=,.@_-]+$", group.name))
    ])
    error_message = "Group names must contain only alphanumeric characters and +=,.@_- symbols."
  }
}

variable "roles" {
  description = "List of IAM roles to create with flexible configuration"
  type = list(object({
    name                    = string
    assume_role_policy      = string
    path                    = optional(string)
    description             = optional(string)
    max_session_duration    = optional(number)
    create_instance_profile = optional(bool)
    policy_arns             = optional(list(string))
    inline_policies         = optional(map(string))
    tags                    = optional(map(string))
  }))
  default = []

  validation {
    condition = alltrue([
      for role in var.roles : can(regex("^[a-zA-Z0-9+=,.@_-]+$", role.name))
    ])
    error_message = "Role names must contain only alphanumeric characters and +=,.@_- symbols."
  }

  validation {
    condition = alltrue([
      for role in var.roles : try(role.max_session_duration >= 3600 && role.max_session_duration <= 43200, true)
    ])
    error_message = "Max session duration must be between 3600 (1 hour) and 43200 (12 hours) seconds."
  }
}

variable "policies" {
  description = "Map of IAM policies to create"
  type = map(object({
    path            = optional(string)
    description     = optional(string)
    policy_document = string
    tags            = optional(map(string))
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, policy in var.policies : can(regex("^[a-zA-Z0-9+=,.@_-]+$", name))
    ])
    error_message = "Policy names must contain only alphanumeric characters and +=,.@_- symbols."
  }
}

variable "oidc_providers" {
  description = "Map of OIDC identity providers to create"
  type = map(object({
    url             = string
    client_id_list  = list(string)
    thumbprint_list = list(string)
    tags            = optional(map(string))
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, provider in var.oidc_providers : can(regex("^https://", provider.url))
    ])
    error_message = "OIDC provider URLs must start with https://."
  }
}

variable "saml_providers" {
  description = "Map of SAML identity providers to create"
  type = map(object({
    saml_metadata_document = string
    tags                   = optional(map(string))
  }))
  default = {}
}

variable "password_policy" {
  description = "Account password policy configuration"
  type = object({
    minimum_password_length        = optional(number, 8)
    require_lowercase_characters   = optional(bool, true)
    require_numbers                = optional(bool, true)
    require_uppercase_characters   = optional(bool, true)
    require_symbols                = optional(bool, true)
    allow_users_to_change_password = optional(bool, true)
    hard_expiry                    = optional(bool, false)
    max_password_age               = optional(number, 90)
    password_reuse_prevention      = optional(number, 12)
  })
  default = {}

  validation {
    condition     = var.password_policy.minimum_password_length >= 6 && var.password_policy.minimum_password_length <= 128
    error_message = "Minimum password length must be between 6 and 128 characters."
  }

  validation {
    condition     = var.password_policy.max_password_age >= 1 && var.password_policy.max_password_age <= 1095
    error_message = "Max password age must be between 1 and 1095 days."
  }

  validation {
    condition     = var.password_policy.password_reuse_prevention >= 1 && var.password_policy.password_reuse_prevention <= 24
    error_message = "Password reuse prevention must be between 1 and 24 passwords."
  }
}

variable "tags" {
  description = "A map of tags to add to all IAM resources"
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for key, value in var.tags : can(regex("^[a-zA-Z0-9+=._:/-@]+$", key))
    ])
    error_message = "Tag keys must contain only alphanumeric characters and +=._:/-@ symbols."
  }
}