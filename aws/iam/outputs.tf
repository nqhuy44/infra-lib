# --- User Outputs ---
output "users" {
  description = "Map of IAM users created"
  value = {
    for name, user in aws_iam_user.users : name => {
      arn       = user.arn
      name      = user.name
      path      = user.path
      unique_id = user.unique_id
    }
  }
}

output "user_login_profiles" {
  description = "Map of IAM user login profiles (sensitive)"
  value = {
    for name, profile in aws_iam_user_login_profile.users : name => {
      user                    = profile.user
      encrypted_password      = profile.encrypted_password
      key_fingerprint         = profile.key_fingerprint
      password_reset_required = profile.password_reset_required
    }
  }
  sensitive = true
}

output "user_access_keys" {
  description = "Map of IAM user access keys (sensitive)"
  value = {
    for name, key in aws_iam_access_key.users : name => {
      id                   = key.id
      user                 = key.user
      status               = key.status
      secret               = key.secret
      encrypted_secret     = key.encrypted_secret
      key_fingerprint      = key.key_fingerprint
      ses_smtp_password_v4 = key.ses_smtp_password_v4
    }
  }
  sensitive = true
}

output "user_names" {
  description = "List of IAM user names created"
  value       = [for user in aws_iam_user.users : user.name]
}

output "user_arns" {
  description = "List of IAM user ARNs created"
  value       = [for user in aws_iam_user.users : user.arn]
}

# --- Group Outputs ---
output "groups" {
  description = "Map of IAM groups created"
  value = {
    for name, group in aws_iam_group.groups : name => {
      arn       = group.arn
      name      = group.name
      path      = group.path
      unique_id = group.unique_id
    }
  }
}

output "group_names" {
  description = "List of IAM group names created"
  value       = [for group in aws_iam_group.groups : group.name]
}

output "group_arns" {
  description = "List of IAM group ARNs created"
  value       = [for group in aws_iam_group.groups : group.arn]
}

# --- Role Outputs ---
output "roles" {
  description = "Map of IAM roles created"
  value = {
    for name, role in aws_iam_role.roles : name => {
      arn                  = role.arn
      name                 = role.name
      path                 = role.path
      unique_id            = role.unique_id
      max_session_duration = role.max_session_duration
      description          = role.description
    }
  }
}

output "role_names" {
  description = "List of IAM role names created"
  value       = [for role in aws_iam_role.roles : role.name]
}

output "role_arns" {
  description = "List of IAM role ARNs created"
  value       = [for role in aws_iam_role.roles : role.arn]
}

# --- Policy Outputs ---
output "policies" {
  description = "Map of IAM policies created"
  value = {
    for name, policy in aws_iam_policy.policies : name => {
      arn         = policy.arn
      name        = policy.name
      path        = policy.path
      policy_id   = policy.policy_id
      description = policy.description
    }
  }
}

output "policy_names" {
  description = "List of IAM policy names created"
  value       = [for policy in aws_iam_policy.policies : policy.name]
}

output "policy_arns" {
  description = "List of IAM policy ARNs created"
  value       = [for policy in aws_iam_policy.policies : policy.arn]
}

# --- Instance Profile Outputs ---
output "instance_profiles" {
  description = "Map of IAM instance profiles created"
  value = {
    for name, profile in aws_iam_instance_profile.profiles : name => {
      arn       = profile.arn
      name      = profile.name
      path      = profile.path
      unique_id = profile.unique_id
      role      = profile.role
    }
  }
}

output "instance_profile_names" {
  description = "List of IAM instance profile names created"
  value       = [for profile in aws_iam_instance_profile.profiles : profile.name]
}

output "instance_profile_arns" {
  description = "List of IAM instance profile ARNs created"
  value       = [for profile in aws_iam_instance_profile.profiles : profile.arn]
}

# --- Identity Provider Outputs ---
output "oidc_providers" {
  description = "Map of OIDC identity providers created"
  value = {
    for name, provider in aws_iam_openid_connect_provider.oidc_providers : name => {
      arn             = provider.arn
      url             = provider.url
      client_id_list  = provider.client_id_list
      thumbprint_list = provider.thumbprint_list
    }
  }
}

output "saml_providers" {
  description = "Map of SAML identity providers created"
  value = {
    for name, provider in aws_iam_saml_provider.saml_providers : name => {
      arn  = provider.arn
      name = provider.name
    }
  }
}

# --- Password Policy Output ---
output "password_policy" {
  description = "Account password policy configuration"
  value = var.create_password_policy ? {
    minimum_password_length        = aws_iam_account_password_policy.password_policy[0].minimum_password_length
    require_lowercase_characters   = aws_iam_account_password_policy.password_policy[0].require_lowercase_characters
    require_numbers                = aws_iam_account_password_policy.password_policy[0].require_numbers
    require_uppercase_characters   = aws_iam_account_password_policy.password_policy[0].require_uppercase_characters
    require_symbols                = aws_iam_account_password_policy.password_policy[0].require_symbols
    allow_users_to_change_password = aws_iam_account_password_policy.password_policy[0].allow_users_to_change_password
    hard_expiry                    = aws_iam_account_password_policy.password_policy[0].hard_expiry
    max_password_age               = aws_iam_account_password_policy.password_policy[0].max_password_age
    password_reuse_prevention      = aws_iam_account_password_policy.password_policy[0].password_reuse_prevention
  } : null
}

# --- Summary Outputs ---
output "summary" {
  description = "Summary of created IAM resources"
  value = {
    users_count             = length(aws_iam_user.users)
    groups_count            = length(aws_iam_group.groups)
    roles_count             = length(aws_iam_role.roles)
    policies_count          = length(aws_iam_policy.policies)
    instance_profiles_count = length(aws_iam_instance_profile.profiles)
    oidc_providers_count    = length(aws_iam_openid_connect_provider.oidc_providers)
    saml_providers_count    = length(aws_iam_saml_provider.saml_providers)
    password_policy_enabled = var.create_password_policy
  }
}

# --- Relationship Outputs (for debugging) ---
output "user_group_memberships" {
  description = "User to group memberships created"
  value = {
    for membership_key, membership in aws_iam_user_group_membership.memberships : membership_key => {
      user   = membership.user
      groups = membership.groups
    }
  }
}

output "policy_attachments_summary" {
  description = "Summary of policy attachments"
  value = {
    user_policy_attachments  = length(aws_iam_user_policy_attachment.user_policies)
    group_policy_attachments = length(aws_iam_group_policy_attachment.group_policies)
    role_policy_attachments  = length(aws_iam_role_policy_attachment.role_policies)
    user_inline_policies     = length(aws_iam_user_policy.user_inline_policies)
    group_inline_policies    = length(aws_iam_group_policy.group_inline_policies)
    role_inline_policies     = length(aws_iam_role_policy.role_inline_policies)
  }
}