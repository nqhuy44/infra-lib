# Local variables for processing input data
locals {
  # Process users - support both simple list and complex configurations
  processed_users = {
    for user in var.users : user.name => merge({
      path                    = "/"
      force_destroy           = false
      console_access          = false
      create_access_key       = false
      access_key_status       = "Active"
      pgp_key                 = null
      password_reset_required = true
      password_length         = 20
      groups                  = []
      policy_arns             = []
      inline_policies         = {}
      tags                    = {}
    }, user)
  }

  # Process groups - support both simple list and complex configurations  
  processed_groups = {
    for group in var.groups : group.name => merge({
      path            = "/"
      policy_arns     = []
      inline_policies = {}
      tags            = {}
    }, group)
  }

  # Process roles - support both simple list and complex configurations
  processed_roles = {
    for role in var.roles : role.name => merge({
      path                    = "/"
      description             = null
      max_session_duration    = 3600
      create_instance_profile = false
      policy_arns             = []
      inline_policies         = {}
      tags                    = {}
    }, role)
  }

  # Process policies - keep existing structure
  processed_policies = var.policies

  # Flatten relationships for easier iteration
  user_group_memberships = flatten([
    for user_name, user in local.processed_users : [
      for group_name in user.groups : {
        user_name  = user_name
        group_name = group_name
      }
    ]
  ])

  user_policy_attachments = flatten([
    for user_name, user in local.processed_users : [
      for policy_arn in user.policy_arns : {
        user_name  = user_name
        policy_arn = policy_arn
      }
    ]
  ])

  group_policy_attachments = flatten([
    for group_name, group in local.processed_groups : [
      for policy_arn in group.policy_arns : {
        group_name = group_name
        policy_arn = policy_arn
      }
    ]
  ])

  role_policy_attachments = flatten([
    for role_name, role in local.processed_roles : [
      for policy_arn in role.policy_arns : {
        role_name  = role_name
        policy_arn = policy_arn
      }
    ]
  ])

  # Flatten inline policies
  user_inline_policies = flatten([
    for user_name, user in local.processed_users : [
      for policy_name, policy_document in user.inline_policies : {
        user_name       = user_name
        policy_name     = policy_name
        policy_document = policy_document
      }
    ]
  ])

  group_inline_policies = flatten([
    for group_name, group in local.processed_groups : [
      for policy_name, policy_document in group.inline_policies : {
        group_name      = group_name
        policy_name     = policy_name
        policy_document = policy_document
      }
    ]
  ])

  role_inline_policies = flatten([
    for role_name, role in local.processed_roles : [
      for policy_name, policy_document in role.inline_policies : {
        role_name       = role_name
        policy_name     = policy_name
        policy_document = policy_document
      }
    ]
  ])
}

# --- IAM Users ---
resource "aws_iam_user" "users" {
  for_each = var.create_users ? local.processed_users : {}

  name          = each.key
  path          = each.value.path
  force_destroy = each.value.force_destroy

  tags = merge(var.tags, each.value.tags)
}

# --- IAM User Login Profiles ---
resource "aws_iam_user_login_profile" "users" {
  for_each = {
    for user_name, user in local.processed_users : user_name => user
    if var.create_users && user.console_access
  }

  user                    = aws_iam_user.users[each.key].name
  pgp_key                 = each.value.pgp_key
  password_reset_required = each.value.password_reset_required
  password_length         = each.value.password_length

  lifecycle {
    ignore_changes = [password_reset_required]
  }
}

# --- IAM User Access Keys ---
resource "aws_iam_access_key" "users" {
  for_each = {
    for user_name, user in local.processed_users : user_name => user
    if var.create_users && user.create_access_key
  }

  user    = aws_iam_user.users[each.key].name
  status  = each.value.access_key_status
  pgp_key = each.value.pgp_key
}

# --- IAM Groups ---
resource "aws_iam_group" "groups" {
  for_each = var.create_groups ? local.processed_groups : {}

  name = each.key
  path = each.value.path
}

# --- IAM Roles ---
resource "aws_iam_role" "roles" {
  for_each = var.create_roles ? local.processed_roles : {}

  name                 = each.key
  path                 = each.value.path
  assume_role_policy   = each.value.assume_role_policy
  description          = each.value.description
  max_session_duration = each.value.max_session_duration

  tags = merge(var.tags, each.value.tags)
}

# --- IAM Policies ---
resource "aws_iam_policy" "policies" {
  for_each = var.create_policies ? local.processed_policies : {}

  name        = each.key
  path        = try(each.value.path, "/")
  description = try(each.value.description, "Managed by Terraform")
  policy      = each.value.policy_document

  tags = merge(var.tags, try(each.value.tags, {}))
}

# --- User Group Memberships ---
resource "aws_iam_user_group_membership" "memberships" {
  for_each = {
    for membership in local.user_group_memberships : "${membership.user_name}-${membership.group_name}" => membership
    if var.create_users && var.create_groups
  }

  user   = aws_iam_user.users[each.value.user_name].name
  groups = [aws_iam_group.groups[each.value.group_name].name]
}

# --- IAM User Policy Attachments ---
resource "aws_iam_user_policy_attachment" "user_policies" {
  for_each = {
    for attachment in local.user_policy_attachments : "${attachment.user_name}-${basename(attachment.policy_arn)}" => attachment
    if var.create_users
  }

  user       = aws_iam_user.users[each.value.user_name].name
  policy_arn = each.value.policy_arn
}

# --- IAM Group Policy Attachments ---
resource "aws_iam_group_policy_attachment" "group_policies" {
  for_each = {
    for attachment in local.group_policy_attachments : "${attachment.group_name}-${basename(attachment.policy_arn)}" => attachment
    if var.create_groups
  }

  group      = aws_iam_group.groups[each.value.group_name].name
  policy_arn = each.value.policy_arn
}

# --- IAM Role Policy Attachments ---
resource "aws_iam_role_policy_attachment" "role_policies" {
  for_each = {
    for attachment in local.role_policy_attachments : "${attachment.role_name}-${basename(attachment.policy_arn)}" => attachment
    if var.create_roles
  }

  role       = aws_iam_role.roles[each.value.role_name].name
  policy_arn = each.value.policy_arn
}

# --- IAM User Inline Policies ---
resource "aws_iam_user_policy" "user_inline_policies" {
  for_each = {
    for policy in local.user_inline_policies : "${policy.user_name}-${policy.policy_name}" => policy
    if var.create_users
  }

  user   = aws_iam_user.users[each.value.user_name].name
  name   = each.value.policy_name
  policy = each.value.policy_document
}

# --- IAM Group Inline Policies ---
resource "aws_iam_group_policy" "group_inline_policies" {
  for_each = {
    for policy in local.group_inline_policies : "${policy.group_name}-${policy.policy_name}" => policy
    if var.create_groups
  }

  group  = aws_iam_group.groups[each.value.group_name].name
  name   = each.value.policy_name
  policy = each.value.policy_document
}

# --- IAM Role Inline Policies ---
resource "aws_iam_role_policy" "role_inline_policies" {
  for_each = {
    for policy in local.role_inline_policies : "${policy.role_name}-${policy.policy_name}" => policy
    if var.create_roles
  }

  role   = aws_iam_role.roles[each.value.role_name].name
  name   = each.value.policy_name
  policy = each.value.policy_document
}

# --- Instance Profiles ---
resource "aws_iam_instance_profile" "profiles" {
  for_each = {
    for role_name, role in local.processed_roles : role_name => role
    if var.create_roles && role.create_instance_profile
  }

  name = each.key
  role = aws_iam_role.roles[each.key].name
  path = each.value.path

  tags = merge(var.tags, each.value.tags)
}

# --- OIDC Identity Providers ---
resource "aws_iam_openid_connect_provider" "oidc_providers" {
  for_each = var.oidc_providers

  url             = each.value.url
  client_id_list  = each.value.client_id_list
  thumbprint_list = each.value.thumbprint_list

  tags = merge(var.tags, try(each.value.tags, {}))
}

# --- SAML Identity Providers ---
resource "aws_iam_saml_provider" "saml_providers" {
  for_each = var.saml_providers

  name                   = each.key
  saml_metadata_document = each.value.saml_metadata_document

  tags = merge(var.tags, try(each.value.tags, {}))
}

# --- Account Password Policy ---
resource "aws_iam_account_password_policy" "password_policy" {
  count = var.create_password_policy ? 1 : 0

  minimum_password_length        = var.password_policy.minimum_password_length
  require_lowercase_characters   = var.password_policy.require_lowercase_characters
  require_numbers                = var.password_policy.require_numbers
  require_uppercase_characters   = var.password_policy.require_uppercase_characters
  require_symbols                = var.password_policy.require_symbols
  allow_users_to_change_password = var.password_policy.allow_users_to_change_password
  hard_expiry                    = var.password_policy.hard_expiry
  max_password_age               = var.password_policy.max_password_age
  password_reuse_prevention      = var.password_policy.password_reuse_prevention
}