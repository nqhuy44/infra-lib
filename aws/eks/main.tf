locals {
  # Generate resource names consistently
  cluster_name_sanitized = lower(replace(var.cluster_name, "/[^a-zA-Z0-9-]+/", "-"))

  # Karpenter node IAM role name default: KarpenterNodeRole-<cluster_name>
  karpenter_node_role_name_effective = coalesce(var.karpenter_node_role_name, "KarpenterNodeRole-${var.cluster_name}")

  # Merge common node group configuration with individual node group configurations
  # Individual node group configs take precedence over common config
  eks_managed_node_groups_merged = {
    for k, v in var.eks_managed_node_groups : k => merge(
      var.common_node_group_config,
      v,
      # Ensure critical fields have proper defaults if not set in individual config
      {
        enable_name_prefix_rollover = coalesce(
          try(v.enable_name_prefix_rollover, null),
          try(var.common_node_group_config.enable_name_prefix_rollover, false)
        )
        ami_type = coalesce(
          try(v.ami_type, null),
          try(var.common_node_group_config.ami_type, "AL2_x86_64")
        )
        version = coalesce(
          try(v.version, null),
          try(var.common_node_group_config.version, null)
        )
        subnet_ids = coalesce(
          try(v.subnet_ids, null),
          try(var.common_node_group_config.subnet_ids, null)
        )
        security_group_ids = coalesce(
          try(v.security_group_ids, null),
          try(var.common_node_group_config.security_group_ids, [])
        )
        # Use explicit logic to check if individual config has different values than defaults
        min_size = v.min_size != 1 ? v.min_size : (
          try(var.common_node_group_config.min_size, 1)
        )
        max_size = v.max_size != 3 ? v.max_size : (
          try(var.common_node_group_config.max_size, 3)
        )
        desired_size = v.desired_size != 2 ? v.desired_size : (
          try(var.common_node_group_config.desired_size, 2)
        )
        disk_size = v.disk_size != 20 ? v.disk_size : (
          try(var.common_node_group_config.disk_size, 20)
        )
      }
    )
  }


  # Known addon to service account mappings with default namespaces
  # addon_sa_mappings = {
  #   "aws-ebs-csi-driver"              = { sa_name = "ebs-csi-controller-sa", namespace = "kube-system" }
  #   "aws-efs-csi-driver"              = { sa_name = "efs-csi-controller-sa", namespace = "kube-system" }
  #   "aws-load-balancer-controller"    = { sa_name = "aws-load-balancer-controller", namespace = "kube-system" }
  #   "cluster-autoscaler"              = { sa_name = "cluster-autoscaler", namespace = "kube-system" }
  #   "external-dns"                    = { sa_name = "external-dns", namespace = "kube-system" }
  #   "amazon-cloudwatch-observability" = { sa_name = "cloudwatch-agent", namespace = "amazon-cloudwatch" }
  #   "aws-for-fluent-bit"              = { sa_name = "fluent-bit", namespace = "logging" }
  # }

  # Process addon configurations with better IRSA role lookup
  addon_base_config = {
    for k, v in var.cluster_addons : k => {
      enabled           = v.enabled
      addon_version     = v.addon_version
      resolve_conflicts = v.resolve_conflicts
      service_account_role_arn = try(
        coalesce(
          v.service_account_role_arn,
          try(aws_iam_role.irsa_roles[try(v.irsa_role_key, k)].arn, ""),
          try(aws_iam_role.irsa_roles["${k}_controller_sa"].arn, ""),
          try(aws_iam_role.irsa_roles[replace(k, "-", "_")].arn, "")
        ),
        null
      )
      configuration_values = v.configuration_values
      tags                 = v.tags
    } if v.enabled
  }

  # 1. Core addons - these don't strictly require nodes or can be deployed early
  core_addons = {
    for k, v in local.addon_base_config : k => v
    if contains(["vpc-cni", "coredns", "kube-proxy", "eks-pod-identity-agent"], k)
  }

  # 2. Node-dependent addons - these require nodes to be running
  node_dependent_addons = {
    for k, v in local.addon_base_config : k => v
    if contains([
      "aws-ebs-csi-driver",
      "aws-efs-csi-driver",
      "cluster-autoscaler",
      "aws-load-balancer-controller",
      "external-dns"
    ], k)
  }

  # 3. Observability addons - deploy these last as they monitor the cluster
  observability_addons = {
    for k, v in local.addon_base_config : k => v
    if contains([
      "amazon-cloudwatch-observability",
      "aws-for-fluent-bit",
      "metrics-server",
      "kube-state-metrics"
    ], k)
  }

  # Flatten access policy associations for easier iteration
  policy_associations_flat = flatten([
    for entry_key, entry_value in var.access_entries : [
      for policy_key, policy_value in entry_value.policy_associations : {
        entry_key  = entry_key
        policy_key = policy_key
        principal  = entry_value.principal_arn
        policy_arn = policy_value.policy_arn
        scope_type = policy_value.access_scope.type
        namespaces = try(policy_value.access_scope.namespaces, null)
      }
    ] if try(entry_value.policy_associations, null) != null
  ])
}

# --- Cluster Autoscaler IAM Policy ---
data "aws_iam_policy_document" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  # Permissions required by Cluster Autoscaler
  # See: https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md#iam-policy
  statement {
    sid    = "ClusterAutoscalerAll"
    effect = "Allow"
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:DescribeInstanceTypes", # Required for EC2 Fleet/MixedInstancesPolicy support
      "eks:DescribeNodegroup"      # Required for EKS Managed Node Groups support
    ]
    resources = ["*"] # These actions don't support resource-level permissions or require '*'
  }
  statement {
    sid    = "ClusterAutoscalerOwn"
    effect = "Allow"
    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup", # Required for ASG tagging
    ]
    resources = ["*"] # Resource level permissions require knowing ASG ARN beforehand, '*' is common practice here
    # Add condition to restrict to ASGs tagged for this cluster
    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/${var.cluster_name}"
      values   = ["owned"]
    }
    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled"
      values   = ["true"]
    }
    # Condition for EKS managed node groups (uses different tag format)
    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/eks:cluster-name"
      values   = [var.cluster_name]
    }
  }
}

resource "aws_iam_policy" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  name_prefix = "${local.cluster_name_sanitized}-ca-"
  description = "IAM policy for EKS cluster ${var.cluster_name} Cluster Autoscaler"
  policy      = data.aws_iam_policy_document.cluster_autoscaler[0].json
  tags        = merge(var.tags, { Name = "${var.cluster_name}-cluster-autoscaler-policy" })
}

# --- Cluster Autoscaler IRSA Role ---
resource "aws_iam_role" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  name_prefix = "${local.cluster_name_sanitized}-ca-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.oidc_provider.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:aud" = "sts.amazonaws.com"
        },
        StringLike = {
          "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:${var.cluster_autoscaler_service_account_namespace}:${var.cluster_autoscaler_service_account_name}"
        }
      }
    }]
  })

  tags = merge(var.tags, { Name = "${var.cluster_name}-cluster-autoscaler-role" })

  depends_on = [aws_iam_openid_connect_provider.oidc_provider]
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler && length(aws_iam_role.cluster_autoscaler) > 0 ? 1 : 0

  policy_arn = aws_iam_policy.cluster_autoscaler[0].arn
  role       = aws_iam_role.cluster_autoscaler[0].name
}

# --- Cluster IAM Role ---
resource "aws_iam_role" "cluster_role" {
  name_prefix = "${local.cluster_name_sanitized}-cluster-"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Principal = { Service = "eks.amazonaws.com" }
      Effect    = "Allow"
    }]
  })
  tags = merge(var.tags, { Name = "${var.cluster_name}-cluster-role" })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster_role.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController" # Required for SG for Pods
  role       = aws_iam_role.cluster_role.name
}

# --- EKS Cluster ---
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.cluster_role.arn

  vpc_config {
    subnet_ids              = var.control_plane_subnet_ids
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_endpoint_public_access ? var.public_access_cidrs : []
    security_group_ids      = var.cluster_additional_security_group_ids
    # EKS creates a default cluster security group automatically.
    # We attach *additional* ones via security_group_ids.
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP" # Or API
    bootstrap_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions
  }

  tags = merge(var.tags, { Name = var.cluster_name })

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceController,
  ]
}

# --- Tag Cluster Security Group for Karpenter Discovery ---
# EKS automatically creates a cluster security group that nodes need for control-plane communication
# This tag allows Karpenter to discover and use this security group
resource "aws_ec2_tag" "cluster_security_group_karpenter" {
  resource_id = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
  key         = "karpenter.sh/discovery"
  value       = var.cluster_name
}

# --- OIDC Provider for IRSA ---
data "tls_certificate" "cluster_thumbprint" {
  # Ensure cluster identity provider is available before querying
  depends_on = [aws_eks_cluster.this]
  url        = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "oidc_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster_thumbprint.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer

  tags = merge(var.tags, { Name = "${var.cluster_name}-oidc-provider" })
}

# --- IAM Roles for Service Accounts (IRSA) ---
resource "aws_iam_role" "irsa_roles" {
  for_each = var.iam_roles_for_service_accounts

  name = "${local.cluster_name_sanitized}-${each.key}-irsa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.oidc_provider.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:aud" = "sts.amazonaws.com"
        },
        StringLike = {
          "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:${each.value.namespace}:${each.value.service_account}"
        }
      }
    }]
  })

  tags       = merge(var.tags, each.value.tags, { Name = coalesce(each.value.name_prefix, "${var.cluster_name}-${each.key}-role") })
  depends_on = [aws_iam_openid_connect_provider.oidc_provider]
}

# --- Attach Inline Policies to IRSA Roles ---
resource "aws_iam_role_policy" "irsa_inline_policies" {
  for_each = {
    for k, v in var.iam_roles_for_service_accounts : k => v if try(v.inline_policy_json, null) != null && contains(keys(aws_iam_role.irsa_roles), k)
  }

  name   = "${coalesce(each.value.name_prefix, each.key)}-inline-policy" # This uses name_prefix for the policy name, which is fine.
  role   = aws_iam_role.irsa_roles[each.key].name
  policy = each.value.inline_policy_json
}


resource "aws_iam_role_policy_attachment" "irsa_policies" {
  for_each = merge([
    for sa_key, sa_config in var.iam_roles_for_service_accounts : {
      for policy_index, policy_arn_value in try(sa_config.policy_arns, []) :
      "${sa_key}-${policy_index}" => {
        role_key   = sa_key
        policy_arn = policy_arn_value
      }
    }
    if contains(keys(aws_iam_role.irsa_roles), sa_key)
  ]...)

  role       = aws_iam_role.irsa_roles[each.value.role_key].name
  policy_arn = each.value.policy_arn
}

# --- Node Group IAM Roles ---
resource "aws_iam_role" "node_group_roles" {
  for_each = local.eks_managed_node_groups_merged

  # Use 'name' instead of 'name_prefix'
  name = "${local.cluster_name_sanitized}-${each.key}-ng-role" # Construct a specific name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
      Effect    = "Allow"
    }]
  })
  # Ensure the Name tag matches the resource name
  tags = merge(var.tags, each.value.tags, { Name = "${local.cluster_name_sanitized}-${each.key}-ng-role" })
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  for_each   = local.eks_managed_node_groups_merged
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group_roles[each.key].name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  for_each   = local.eks_managed_node_groups_merged
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group_roles[each.key].name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  for_each   = local.eks_managed_node_groups_merged
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group_roles[each.key].name
}

# --- Optional: Karpenter Node IAM Role ---
# This role is intended to be used by Karpenter-provisioned nodes (EC2NodeClass.spec.role).
resource "aws_iam_role" "karpenter_node_role" {
  count = var.enable_karpenter ? 1 : 0

  name = local.karpenter_node_role_name_effective

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
      Effect    = "Allow"
    }]
  })

  tags = merge(var.tags, { Name = local.karpenter_node_role_name_effective, Service = "karpenter" })
}

resource "aws_iam_role_policy_attachment" "karpenter_node_role_policies" {
  for_each = var.enable_karpenter ? toset(var.karpenter_node_role_policy_arns) : toset([])

  role       = aws_iam_role.karpenter_node_role[0].name
  policy_arn = each.value
}

# Random suffix for node group name when rollover is enabled (per node group)
resource "random_id" "ng_suffix" {
  for_each    = { for k, v in local.eks_managed_node_groups_merged : k => v if try(v.enable_name_prefix_rollover, false) }
  byte_length = 2
  keepers = {
    # Include values that should trigger a replacement
    # ami_type changes should trigger replacement for create_before_destroy
    ami_type = each.value.ami_type

    # instance_types only included when force_replace is true
    # When false, instance_types = null (default behavior)
    instance_types = try(each.value.enable_instance_types_replacement, true) ? join(",", each.value.instance_types) : null
  }
}

# --- EKS Managed Node Groups ---
# Partition node groups based on whether name rollover (and thus CBD) is enabled
locals {
  ng_with_rollover    = { for k, v in local.eks_managed_node_groups_merged : k => v if try(v.enable_name_prefix_rollover, false) }
  ng_without_rollover = { for k, v in local.eks_managed_node_groups_merged : k => v if !try(v.enable_name_prefix_rollover, false) }
}

# Data source to list all node groups for the cluster (used to find current node groups)
data "aws_eks_node_groups" "all" {
  cluster_name = aws_eks_cluster.this.name
}

# Data source to read current node group state (for node groups without rollover)
data "aws_eks_node_group" "current_ng" {
  for_each = {
    for k in keys(local.ng_without_rollover) : k => k
    if contains(data.aws_eks_node_groups.all.names, "${var.cluster_name}-${k}")
  }

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-${each.key}"
}

# Data source to read current CBD node group state
# First, find current CBD node group names by matching prefix pattern
locals {
  # Find current CBD node group names by matching prefix pattern
  current_cbd_node_group_names = {
    for k, v in local.ng_with_rollover : k => try([
      for ng_name in data.aws_eks_node_groups.all.names : ng_name
      if startswith(ng_name, "${var.cluster_name}-${coalesce(try(v.name_prefix, null), k)}-")
    ][0], null)
  }
}

data "aws_eks_node_group" "current_cbd" {
  # IMPORTANT (OpenTofu): keep for_each keys static so plan can determine instance addresses.
  # The filtered form `if ng_name != null` makes the instance set unknown when the node group
  # list can't be read until apply (e.g., first create / cluster replacement).
  for_each = { for k, ng_name in local.current_cbd_node_group_names : k => ng_name }

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = each.value
}

# Calculate desired_size for all node groups
# Use max of AWS current (if exists) and Terraform config, clamped to max_size
# Note: desired_size is only used for initial cluster creation. After creation, Terraform ignores
# changes to desired_size (via lifecycle.ignore_changes) to allow Cluster Autoscaler to manage it
# when enabled. When autoscaler is disabled, set desired_size in config for initial creation.
locals {
  # For node groups without rollover: preserve AWS current desired_size if higher, but clamp to [min_size, max_size]
  # On new clusters, data source will be empty, so we use configured values
  desired_size_without_rollover = {
    for k, v in local.ng_without_rollover : k => (
      # Check if node group exists in AWS (key exists in data source)
      contains(keys(data.aws_eks_node_group.current_ng), k)
      # If exists: use max of AWS current and Terraform config, clamped to [min_size, max_size]
      ? min(
        max(
          data.aws_eks_node_group.current_ng[k].scaling_config[0].desired_size,
          v.desired_size,
          v.min_size
        ),
        v.max_size
      )
      # If doesn't exist (new cluster): use Terraform config, clamped to [min_size, max_size]
      : min(max(v.desired_size, v.min_size), v.max_size)
    )
  }

  # For CBD node groups: use configured desired_size, clamped to [min_size, max_size]
  # We don't preserve AWS desired_size for rollover node groups to avoid "unknown values" errors
  # during planning for new clusters. Rollover node groups use create-before-destroy anyway,
  # so preserving desired_size is less critical. For existing clusters, we'll use the configured
  # desired_size which is appropriate for rollover node groups.
  desired_size_with_rollover = {
    for k, v in local.ng_with_rollover : k => min(
      max(v.desired_size, v.min_size),
      v.max_size
    )
  }

}

resource "aws_eks_node_group" "this" {
  for_each = local.ng_without_rollover

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-${each.key}"
  node_role_arn   = aws_iam_role.node_group_roles[each.key].arn
  subnet_ids      = coalesce(each.value.subnet_ids, var.control_plane_subnet_ids) # Use specific or default subnets

  ami_type       = each.value.ami_type
  capacity_type  = each.value.capacity_type
  instance_types = each.value.instance_types
  # When using a launch template, disk size must be specified in the LT, not here.
  disk_size = try(each.value.use_module_launch_template, true) ? null : each.value.disk_size

  version         = coalesce(each.value.version, var.cluster_version)
  release_version = try(each.value.release_version, null)

  scaling_config {
    # Set initial desired_size (used for cluster creation only). Terraform ignores changes to
    # desired_size after creation (via lifecycle.ignore_changes) to allow Cluster Autoscaler
    # to manage it when enabled. Use preserved AWS desired_size if higher, but clamp to max_size
    # to allow max_size reductions.
    desired_size = local.desired_size_without_rollover[each.key]
    max_size     = max(each.value.max_size, each.value.min_size)
    min_size     = each.value.min_size
  }

  dynamic "launch_template" {
    for_each = try(each.value.use_module_launch_template, true) && contains(keys(aws_launch_template.ng), each.key) ? [1] : []
    content {
      id      = aws_launch_template.ng[each.key].id
      version = tostring(aws_launch_template.ng[each.key].latest_version)
    }
  }

  update_config {
    max_unavailable = try(each.value.update_config.max_unavailable, null)
    max_unavailable_percentage = (
      try(each.value.update_config.max_unavailable, null) == null
      ? try(each.value.update_config.max_unavailable_percentage, 25)
      : null
    )
  }

  dynamic "taint" {
    for_each = each.value.taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  labels = merge(
    { "nodegroup-name" = each.key }, # Use this instead of eks.amazonaws.com/nodegroup
    each.value.labels                # Keep user-provided labels
  )

  # Conditionally add Cluster Autoscaler tags
  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name = "${var.cluster_name}-${each.key}"
      # Tags for Cluster Autoscaler discovery
      "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
      "k8s.io/cluster-autoscaler/enabled"             = "true"
    }
  )

  # Ensure cluster and roles are created first
  depends_on = [
    aws_eks_cluster.this,
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
  ]

  # Use lifecycle block for smoother node group updates/replacements
  # desired_size is always ignored to allow Cluster Autoscaler to manage it when enabled.
  # When autoscaler is disabled, set desired_size in config for initial creation.
  # This allows max_size reductions to work even when current AWS desired_size > new max_size
  lifecycle {
    ignore_changes = [
      labels,
      tags,
      scaling_config[0].desired_size
    ]
  }
}

resource "aws_eks_node_group" "this_cbd" {
  for_each = local.ng_with_rollover

  cluster_name = aws_eks_cluster.this.name
  node_group_name = format(
    "%s-%s-%s",
    var.cluster_name,
    coalesce(try(each.value.name_prefix, null), each.key),
    random_id.ng_suffix[each.key].hex
  )
  node_role_arn = aws_iam_role.node_group_roles[each.key].arn
  subnet_ids    = coalesce(each.value.subnet_ids, var.control_plane_subnet_ids)

  ami_type       = each.value.ami_type
  capacity_type  = each.value.capacity_type
  instance_types = each.value.instance_types
  disk_size      = try(each.value.use_module_launch_template, true) ? null : each.value.disk_size

  version         = coalesce(each.value.version, var.cluster_version)
  release_version = try(each.value.release_version, null)

  scaling_config {
    # Set initial desired_size (used for cluster creation only). Terraform ignores changes to
    # desired_size after creation (via lifecycle.ignore_changes) to allow Cluster Autoscaler
    # to manage it when enabled. Use preserved AWS desired_size if higher, but clamp to max_size
    # to allow max_size reductions.
    desired_size = local.desired_size_with_rollover[each.key]
    max_size     = max(each.value.max_size, each.value.min_size)
    min_size     = each.value.min_size
  }

  dynamic "launch_template" {
    for_each = try(each.value.use_module_launch_template, true) && contains(keys(aws_launch_template.ng), each.key) ? [1] : []
    content {
      id      = aws_launch_template.ng[each.key].id
      version = tostring(aws_launch_template.ng[each.key].latest_version)
    }
  }

  update_config {
    max_unavailable = try(each.value.update_config.max_unavailable, null)
    max_unavailable_percentage = (
      try(each.value.update_config.max_unavailable, null) == null
      ? try(each.value.update_config.max_unavailable_percentage, 25)
      : null
    )
  }

  dynamic "taint" {
    for_each = each.value.taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  labels = merge(
    { "nodegroup-name" = each.key },
    each.value.labels
  )

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name                                            = "${var.cluster_name}-${each.key}"
      "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
      "k8s.io/cluster-autoscaler/enabled"             = "true"
    }
  )

  depends_on = [
    aws_eks_cluster.this,
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
  ]

  lifecycle {
    # desired_size is always ignored to allow Cluster Autoscaler to manage it when enabled.
    # When autoscaler is disabled, set desired_size in config for initial creation.
    # This allows max_size reductions to work even when current AWS desired_size > new max_size
    ignore_changes = [
      labels,
      tags,
      scaling_config[0].desired_size
    ]
    create_before_destroy = true
  }
}

# Launch Template
resource "aws_launch_template" "ng" {
  for_each = {
    for k, v in local.eks_managed_node_groups_merged : k => v
    if try(v.use_module_launch_template, true)
  }

  name_prefix            = "${local.cluster_name_sanitized}-${each.key}-"
  update_default_version = true

  # Intentionally let EKS MNGr manage AMI and user data; we’re only here for tag_specifications.

  # Root volume settings so EKS doesn’t require disk_size on the node group
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = try(each.value.disk_size, 20) # GiB
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
      # Optionally, for gp3:
      # iops       = 3000
      # throughput = 125
    }
  }

  # Tag instances at launch
  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      try(each.value.tags, {}),
      try(each.value.extra_instance_tags, {}),
      {
        Name               = "${var.cluster_name}-${each.key}-node",
        "eks:cluster-name" = var.cluster_name,
        "eks:nodegroup" = (
          try(each.value.enable_name_prefix_rollover, false)
          ? format(
            "%s-%s-%s",
            var.cluster_name,
            coalesce(try(each.value.name_prefix, null), each.key),
            random_id.ng_suffix[each.key].hex
          )
          : "${var.cluster_name}-${each.key}"
        )
      }
    )
  }

  # Optional: tag EBS volumes
  tag_specifications {
    resource_type = "volume"
    tags = merge(
      var.tags,
      try(each.value.tags, {}),
      try(each.value.extra_instance_tags, {}),
      {
        "eks:cluster-name" = var.cluster_name,
        "eks:nodegroup" = (
          try(each.value.enable_name_prefix_rollover, false)
          ? format(
            "%s-%s-%s",
            var.cluster_name,
            coalesce(try(each.value.name_prefix, null), each.key),
            random_id.ng_suffix[each.key].hex
          )
          : "${var.cluster_name}-${each.key}"
        )
      }
    )
  }

  tags = merge(
    var.tags,
    try(each.value.tags, {}),
    { Name = "${local.cluster_name_sanitized}-${each.key}-lt" }
  )
}

# --- Core EKS Addons (VPC-CNI, CoreDNS, Kube-Proxy) ---
resource "aws_eks_addon" "core" {
  for_each = local.core_addons

  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = each.key
  addon_version               = each.value.addon_version
  resolve_conflicts_on_create = each.value.resolve_conflicts
  resolve_conflicts_on_update = each.value.resolve_conflicts
  service_account_role_arn    = each.value.service_account_role_arn
  configuration_values        = each.value.configuration_values

  tags = merge(var.tags, each.value.tags, {
    Name      = "${var.cluster_name}-${each.key}-addon"
    eks_addon = each.key
  })

  depends_on = [
    aws_eks_cluster.this,
    aws_iam_role.irsa_roles
  ]
}

# --- Node-Dependent EKS Addons (EBS CSI, EFS CSI, etc.) ---
resource "aws_eks_addon" "node_dependent" {
  for_each = local.node_dependent_addons

  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = each.key
  addon_version               = each.value.addon_version
  resolve_conflicts_on_create = each.value.resolve_conflicts
  resolve_conflicts_on_update = each.value.resolve_conflicts
  service_account_role_arn    = each.value.service_account_role_arn
  configuration_values        = each.value.configuration_values

  tags = merge(var.tags, each.value.tags, {
    Name      = "${var.cluster_name}-${each.key}-addon"
    eks_addon = each.key
  })

  # Critically, these addons depend on node groups being ready
  depends_on = [
    aws_eks_cluster.this,
    aws_iam_role.irsa_roles,
    aws_eks_node_group.this,
    aws_eks_node_group.this_cbd,
    aws_eks_addon.core
  ]
}

# --- Observability EKS Addons (CloudWatch, Fluent Bit, etc.) ---
resource "aws_eks_addon" "observability" {
  for_each = local.observability_addons

  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = each.key
  addon_version               = each.value.addon_version
  resolve_conflicts_on_create = each.value.resolve_conflicts
  resolve_conflicts_on_update = each.value.resolve_conflicts
  service_account_role_arn    = each.value.service_account_role_arn
  configuration_values        = each.value.configuration_values

  tags = merge(var.tags, each.value.tags, {
    Name      = "${var.cluster_name}-${each.key}-addon"
    eks_addon = each.key
  })

  # These addons depend on node groups and other addons being ready
  depends_on = [
    aws_eks_cluster.this,
    aws_iam_role.irsa_roles,
    aws_eks_node_group.this,
    aws_eks_node_group.this_cbd,
    aws_eks_addon.core,
    aws_eks_addon.node_dependent
  ]
}

# --- Access Entries ---
resource "aws_eks_access_entry" "this" {
  for_each = var.access_entries

  cluster_name      = aws_eks_cluster.this.name
  principal_arn     = each.value.principal_arn
  kubernetes_groups = each.value.kubernetes_groups
  type              = each.value.type

  tags = merge(var.tags, each.value.tags, {
    Name = "${var.cluster_name}-${each.key}-access-entry"
  })
}

# --- Access Policy Associations ---
resource "aws_eks_access_policy_association" "this" {
  # Create a unique key for each association: "entry_key-policy_key"
  for_each = { for item in local.policy_associations_flat : "${item.entry_key}-${item.policy_key}" => item }

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value.principal
  policy_arn    = each.value.policy_arn

  access_scope {
    type       = each.value.scope_type
    namespaces = each.value.scope_type == "namespace" ? each.value.namespaces : null
  }

  depends_on = [aws_eks_access_entry.this]
}
