# AWS IAM Terraform Module

A flexible, production‑ready Terraform module to manage AWS IAM at scale. It supports creating:
- Users (with optional console access and access keys)
- Groups
- Roles (with optional instance profiles)
- Managed policies
- Inline policies for users, groups, and roles
- User-to-group memberships
- OIDC and SAML identity providers
- Account password policy

The module is designed to accept both simple and complex configurations, with sane defaults and validations.

## Requirements
- Terraform ~> 1.3 (as defined in `terraform.tf`)
- AWS Provider ~> 5.97.0

## Features at a glance
- Toggle creation for users, groups, roles, policies, and password policy via flags
- Strong input validations for names, session duration, password policy parameters, and tag keys
- Opinionated defaults with ability to override per item
- Sensible outputs including maps, names, ARNs, counts, and debug summaries

## Usage

Basic example showing multiple IAM constructs. Choose one of the following source styles depending on where you call the module from.

```hcl
module "iam" {
  # If calling from a repo in the same mono-repo, use a relative path
  # source = "../../devops-terraform-modules/aws/iam"

  # Or if calling via VCS, adapt to your org/repo and pin a ref
  # source = "git::ssh://git@github.com/your-org/devops-terraform-modules.git//aws/iam?ref=v1.0.0"

  # Global tags applied to taggable IAM resources
  tags = {
    Environment = "non-prod"
    ManagedBy   = "Terraform"
  }

  # Users
  users = [
    {
      name                    = "alice"
      console_access          = true
      password_length         = 20
      password_reset_required = true
      groups                  = ["developers"]
      policy_arns             = [
        "arn:aws:iam::aws:policy/ReadOnlyAccess"
      ]
      inline_policies = {
        "AllowDescribeEC2" = jsonencode({
          Version = "2012-10-17"
          Statement = [{
            Effect   = "Allow"
            Action   = ["ec2:Describe*"]
            Resource = "*"
          }]
        })
      }
      tags = { Team = "Platform" }
    },
    {
      name              = "bob"
      create_access_key = true
      access_key_status = "Active"
      # Optional PGP key for encrypting the access key secret in state/output
      # pgp_key = "keybase:your_keybase_username" 
    }
  ]

  # Groups
  groups = [
    {
      name        = "developers"
      policy_arns = ["arn:aws:iam::aws:policy/PowerUserAccess"]
    }
  ]

  # Roles
  roles = [
    {
      name                 = "app-ec2-role"
      description          = "EC2 role for application"
      max_session_duration = 3600
      path                 = "/app/"
      create_instance_profile = true
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect = "Allow"
          Principal = { Service = "ec2.amazonaws.com" }
          Action = "sts:AssumeRole"
        }]
      })
      policy_arns = [
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      ]
      inline_policies = {
        "S3ReadWriteAppBucket" = jsonencode({
          Version = "2012-10-17"
          Statement = [{
            Effect   = "Allow"
            Action   = ["s3:GetObject", "s3:PutObject"]
            Resource = [
              "arn:aws:s3:::my-app-bucket",
              "arn:aws:s3:::my-app-bucket/*"
            ]
          }]
        })
      }
      tags = { Role = "app" }
    }
  ]

  # Managed policies (created by this module)
  policies = {
    "DenyDangerousActions" = {
      description     = "Prevent deletion of critical resources"
      policy_document = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect = "Deny"
          Action = ["iam:DeleteUser", "iam:DeleteRole", "iam:DeletePolicy"]
          Resource = "*"
        }]
      })
    }
  }

  # Identity providers (optional)
  oidc_providers = {
    "github" = {
      url             = "https://token.actions.githubusercontent.com"
      client_id_list  = ["sts.amazonaws.com"]
      thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
    }
  }

  saml_providers = {
    "okta" = {
      saml_metadata_document = file("./okta-metadata.xml")
    }
  }

  # Account password policy (optional)
  create_password_policy = true
  password_policy = {
    minimum_password_length        = 12
    require_lowercase_characters   = true
    require_numbers                = true
    require_uppercase_characters   = true
    require_symbols                = true
    allow_users_to_change_password = true
    hard_expiry                    = false
    max_password_age               = 90
    password_reuse_prevention      = 12
  }
}
```

## Inputs
- create_users (bool, default: true): Whether to create IAM users
- create_groups (bool, default: true): Whether to create IAM groups
- create_roles (bool, default: true): Whether to create IAM roles
- create_policies (bool, default: true): Whether to create IAM policies
- create_password_policy (bool, default: false): Whether to set the account password policy
- users (list(object)): List of users to create. Fields (all optional unless noted):
  - name (string, required)
  - path (string, default "/")
  - force_destroy (bool, default false)
  - console_access (bool, default false)
  - create_access_key (bool, default false)
  - access_key_status (string, default "Active")
  - pgp_key (string, default null)
  - password_reset_required (bool, default true)
  - password_length (number, default 20)
  - groups (list(string), default [])
  - policy_arns (list(string), default [])
  - inline_policies (map(string JSON), default {})
  - tags (map(string), default {})
  - Validation: user.name must match ^[a-zA-Z0-9+=,.@_-]+$
- groups (list(object)):
  - name (string, required)
  - path (string, default "/")
  - policy_arns (list(string), default [])
  - inline_policies (map(string JSON), default {})
  - tags (map(string), default {})
  - Validation: group.name must match ^[a-zA-Z0-9+=,.@_-]+$
- roles (list(object)):
  - name (string, required)
  - assume_role_policy (string JSON, required)
  - path (string, default "/")
  - description (string, default null)
  - max_session_duration (number, default 3600; must be between 3600 and 43200)
  - create_instance_profile (bool, default false)
  - policy_arns (list(string), default [])
  - inline_policies (map(string JSON), default {})
  - tags (map(string), default {})
  - Validations: name pattern ^[a-zA-Z0-9+=,.@_-]+$, session duration range 3600..43200
- policies (map(object)):
  - key = policy name (validated against ^[a-zA-Z0-9+=,.@_-]+$)
  - value fields:
    - policy_document (string JSON, required)
    - path (string, default "/")
    - description (string, default "Managed by Terraform")
    - tags (map(string), default {})
- oidc_providers (map(object)):
  - url (string, must start with https://)
  - client_id_list (list(string))
  - thumbprint_list (list(string))
  - tags (map(string), default {})
- saml_providers (map(object)):
  - saml_metadata_document (string)
  - tags (map(string), default {})
- password_policy (object):
  - minimum_password_length (number, default 8; must be 6..128)
  - require_lowercase_characters (bool, default true)
  - require_numbers (bool, default true)
  - require_uppercase_characters (bool, default true)
  - require_symbols (bool, default true)
  - allow_users_to_change_password (bool, default true)
  - hard_expiry (bool, default false)
  - max_password_age (number, default 90; must be 1..1095)
  - password_reuse_prevention (number, default 12; must be 1..24)
- tags (map(string), default {}): Global tags applied to supported IAM resources. Validation: tag keys must match ^[a-zA-Z0-9+=._:/-@]+$

Note: Inline policy values are expected to be valid JSON policy documents (use `jsonencode` as shown in examples).

## Outputs
- users: Map of users with arn, name, path, unique_id
- user_login_profiles (sensitive): Map with user, encrypted_password, key_fingerprint, password_reset_required
- user_access_keys (sensitive): Map with id, user, status, secret, encrypted_secret, key_fingerprint, ses_smtp_password_v4
- user_names: List of user names
- user_arns: List of user ARNs
- groups: Map of groups with arn, name, path, unique_id
- group_names: List of group names
- group_arns: List of group ARNs
- roles: Map of roles with arn, name, path, unique_id, max_session_duration, description
- role_names: List of role names
- role_arns: List of role ARNs
- policies: Map of managed policies with arn, name, path, policy_id, description
- policy_names: List of policy names
- policy_arns: List of policy ARNs
- instance_profiles: Map with arn, name, path, unique_id, role
- instance_profile_names: List of instance profile names
- instance_profile_arns: List of instance profile ARNs
- oidc_providers: Map with arn, url, client_id_list, thumbprint_list
- saml_providers: Map with arn, name
- password_policy: Object with the effective account password policy (null if not created)
- summary: Object with counts and flags
- user_group_memberships: Map of user-to-group memberships (for debugging)
- policy_attachments_summary: Counts of policy attachments and inline policies

## Notes and best practices
- Sensitive outputs are marked sensitive; rely on your CI/runner’s secrets handling and avoid printing them to logs.
- Consider providing a `pgp_key` (e.g., `keybase:<username>` or an armored public key string) when creating access keys or login profiles to encrypt secrets in state and outputs.
- Use `create_*` flags to gradually adopt the module without impacting existing resources you manage elsewhere.
- When enabling `create_instance_profile` for a role, the module creates an instance profile with the same name.

## Example: IRSA for AWS Load Balancer Controller
This module can be used to create an IAM Role for Service Accounts (IRSA) for the AWS Load Balancer Controller running as ServiceAccount `aws-load-balancer-controller` in the `kube-system` namespace.

If your EKS cluster OIDC issuer is, for example:
- https://oidc.eks.ap-southeast-1.amazonaws.com/id/0674E964B710108E91ECEC170B22BB57

You can create (or reuse) the OIDC provider and a role trusted for that ServiceAccount.

Terraform example that safely computes the OIDC thumbprint and creates the IRSA role via this module:

```hcl
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.97" }
    tls = { source = "hashicorp/tls", version = "~> 4.0" }
  }
}

# EKS OIDC issuer URL without trailing slash
variable "eks_oidc_issuer_url" {
  type    = string
  default = "https://oidc.eks.ap-southeast-1.amazonaws.com/id/0674E964B710108E91ECEC170B22BB57"
}

# Fetch the certificate chain and compute the CA thumbprint
data "tls_certificate" "eks_oidc" {
  url = var.eks_oidc_issuer_url
}

locals {
  eks_oidc_hostpath   = replace(var.eks_oidc_issuer_url, "https://", "")
  eks_oidc_thumbprint = one([
    for c in data.tls_certificate.eks_oidc.certificates : c.sha1_fingerprint
    if c.is_ca
  ])
}

data "aws_caller_identity" "current" {}

# Trust policy restricted to the controller SA in kube-system
data "aws_iam_policy_document" "alb_irsa_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.eks_oidc_hostpath}"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.eks_oidc_hostpath}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.eks_oidc_hostpath}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
  }
}

module "iam_irsa_alb_controller" {
  # Adjust the source to your repo layout
  source = "../../devops-terraform-modules/aws/iam"

  # Only roles and the OIDC provider are needed here
  create_users           = false
  create_groups          = false
  create_policies        = false
  create_password_policy = false

  oidc_providers = {
    eks = {
      url             = var.eks_oidc_issuer_url
      client_id_list  = ["sts.amazonaws.com"]
      thumbprint_list = [local.eks_oidc_thumbprint]
    }
  }

  roles = [
    {
      name                 = "eks-aws-load-balancer-controller-irsa"
      description          = "IRSA role for AWS Load Balancer Controller in kube-system"
      max_session_duration = 3600
      assume_role_policy   = data.aws_iam_policy_document.alb_irsa_trust.json

      # Attach the controller policy inline (or use a managed policy ARN via policy_arns)
      inline_policies = {
        AWSLoadBalancerController = jsonencode({
          Version = "2012-10-17"
          Statement = [
            {
              Sid    = "ELBV2"
              Effect = "Allow"
              Action = [
                "elasticloadbalancing:AddListenerCertificates",
                "elasticloadbalancing:AddTags",
                "elasticloadbalancing:CreateListener",
                "elasticloadbalancing:CreateLoadBalancer",
                "elasticloadbalancing:CreateRule",
                "elasticloadbalancing:CreateTargetGroup",
                "elasticloadbalancing:DeleteListener",
                "elasticloadbalancing:DeleteLoadBalancer",
                "elasticloadbalancing:DeleteRule",
                "elasticloadbalancing:DeleteTargetGroup",
                "elasticloadbalancing:DeregisterTargets",
                "elasticloadbalancing:Describe*",
                "elasticloadbalancing:ModifyListener",
                "elasticloadbalancing:ModifyLoadBalancerAttributes",
                "elasticloadbalancing:ModifyRule",
                "elasticloadbalancing:ModifyTargetGroup",
                "elasticloadbalancing:ModifyTargetGroupAttributes",
                "elasticloadbalancing:RegisterTargets",
                "elasticloadbalancing:RemoveListenerCertificates",
                "elasticloadbalancing:RemoveTags",
                "elasticloadbalancing:SetIpAddressType",
                "elasticloadbalancing:SetSecurityGroups",
                "elasticloadbalancing:SetSubnets",
                "elasticloadbalancing:SetWebAcl"
              ]
              Resource = "*"
            },
            {
              Sid    = "EC2"
              Effect = "Allow"
              Action = [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:CreateSecurityGroup",
                "ec2:CreateTags",
                "ec2:DeleteSecurityGroup",
                "ec2:Describe*",
                "ec2:RevokeSecurityGroupIngress"
              ]
              Resource = "*"
            },
            {
              Sid      = "IAMServiceLinkedRoleForELB"
              Effect   = "Allow"
              Action   = ["iam:CreateServiceLinkedRole"]
              Resource = "*"
              Condition = {
                StringEquals = {
                  "iam:AWSServiceName" = "elasticloadbalancing.amazonaws.com"
                }
              }
            },
            {
              Sid    = "WAFShield"
              Effect = "Allow"
              Action = [
                "waf-regional:GetWebACLForResource",
                "waf-regional:GetWebACL",
                "waf-regional:AssociateWebACL",
                "waf-regional:DisassociateWebACL",
                "wafv2:GetWebACLForResource",
                "wafv2:GetWebACL",
                "wafv2:AssociateWebACL",
                "wafv2:DisassociateWebACL",
                "shield:DescribeProtection",
                "shield:GetSubscriptionState",
                "shield:DeleteProtection",
                "shield:CreateProtection",
                "shield:DescribeSubscription",
                "shield:ListProtections"
              ]
              Resource = "*"
            },
            {
              Sid      = "ACM"
              Effect   = "Allow"
              Action   = ["acm:ListCertificates", "acm:DescribeCertificate"]
              Resource = "*"
            },
            {
              Sid      = "Tagging"
              Effect   = "Allow"
              Action   = ["tag:GetResources", "tag:TagResources"]
              Resource = "*"
            },
            {
              Sid    = "CognitoAndIAMServerCert"
              Effect = "Allow"
              Action = [
                "cognito-idp:DescribeUserPoolClient",
                "iam:ListServerCertificates",
                "iam:GetServerCertificate"
              ]
              Resource = "*"
            }
          ]
        })
      }
    }
  ]
}
```

If the OIDC provider already exists, reference it via a data source, omit `oidc_providers` from the module call, and use the provider ARN in the trust policy’s principal.

Helm values: annotate the ServiceAccount with the role ARN created above:

```yaml
serviceAccount:
  create: true
  name: aws-load-balancer-controller
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::<YOUR_AWS_ACCOUNT_ID>:role/eks-aws-load-balancer-controller-irsa
```

Checklist
- The OIDC issuer URL has no trailing slash and matches the cluster issuer exactly.
- Trust policy conditions use the correct hostpath keys: `<hostpath>:aud` is `sts.amazonaws.com` and `<hostpath>:sub` matches `system:serviceaccount:kube-system:aws-load-balancer-controller`.
- You don’t create a duplicate OIDC provider if one already exists.
- Keep the IAM policy in sync with your controller version.

## Versioning
Pin the module to a specific tag or commit when sourcing it from VCS to ensure reproducible deployments.

## License
Apache-2.0 (or your repository’s chosen license).