output "cluster_name" {
  description = "The name of the EKS cluster."
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "The ARN of the EKS cluster."
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "The endpoint for the EKS cluster's Kubernetes API server."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_ca_certificate" {
  description = "Base64 encoded certificate data required to communicate with the cluster."
  value       = aws_eks_cluster.this.certificate_authority[0].data
  sensitive   = true
}

output "cluster_oidc_issuer_url" {
  description = "The OIDC issuer URL for the cluster."
  value       = try(aws_eks_cluster.this.identity[0].oidc[0].issuer, "")
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider. Empty if cluster identity is not available."
  value       = try(aws_iam_openid_connect_provider.oidc_provider.arn, "")
}

output "cluster_primary_security_group_id" {
  description = "The security group ID created by EKS for the cluster control plane."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "cluster_role_arn" {
  description = "The ARN of the IAM role associated with the EKS cluster."
  value       = aws_iam_role.cluster_role.arn
}

output "node_groups" {
  description = "Map of EKS managed node groups created, keyed by the input map key."
  value = merge(
    {
      for k, ng in aws_eks_node_group.this : k => {
        arn            = ng.arn
        id             = ng.id
        status         = ng.status
        iam_role_arn   = aws_iam_role.node_group_roles[k].arn
        instance_types = ng.instance_types
        capacity_type  = ng.capacity_type
        ami_type       = ng.ami_type
        version        = ng.version
      }
    },
    {
      for k, ng in aws_eks_node_group.this_cbd : k => {
        arn            = ng.arn
        id             = ng.id
        status         = ng.status
        iam_role_arn   = aws_iam_role.node_group_roles[k].arn
        instance_types = ng.instance_types
        capacity_type  = ng.capacity_type
        ami_type       = ng.ami_type
        version        = ng.version
      }
    }
  )
}

output "irsa_roles" {
  description = "Map of IAM roles created for service accounts, keyed by the input map key."
  value = {
    for k, role in aws_iam_role.irsa_roles : k => {
      arn  = role.arn
      name = role.name
    }
  }
}

output "karpenter_node_role" {
  description = "Karpenter node IAM role info (null if disabled)."
  value = var.enable_karpenter ? {
    name = aws_iam_role.karpenter_node_role[0].name
    arn  = aws_iam_role.karpenter_node_role[0].arn
  } : null
}

output "access_entries" {
  description = "Map of access entries created, keyed by the input map key."
  value = {
    for k, entry in aws_eks_access_entry.this : k => {
      principal_arn = entry.principal_arn
    }
  }
}

output "addons" {
  description = "Map of EKS addons deployed, keyed by addon name."
  value = merge(
    {
      for k, a in aws_eks_addon.core : k => {
        arn          = a.arn
        addon_name   = a.addon_name
        addon_version = a.addon_version
        # status       = a.status
      }
    },
    {
      for k, a in aws_eks_addon.node_dependent : k => {
        arn          = a.arn
        addon_name   = a.addon_name
        addon_version = a.addon_version
        # status       = a.status
      }
    },
    {
      for k, a in aws_eks_addon.observability : k => {
        arn          = a.arn
        addon_name   = a.addon_name
        addon_version = a.addon_version
        # status       = a.status
      }
    }
  )
}

# Debug outputs
output "common_node_group_config" {
  description = "The common node group configuration passed to the module."
  value       = var.common_node_group_config
}

output "eks_managed_node_groups_merged" {
  description = "The merged node group configurations."
  value       = local.eks_managed_node_groups_merged
}

output "node_group_scheduled_actions" {
  description = "Map of scheduled scaling actions created for node groups."
  value = {
    for k, schedule in aws_autoscaling_schedule.node_group_schedules : k => {
      scheduled_action_name  = schedule.scheduled_action_name
      autoscaling_group_name = schedule.autoscaling_group_name
      min_size               = schedule.min_size
      max_size               = schedule.max_size
      desired_size           = schedule.desired_capacity
      recurrence             = schedule.recurrence
    }
  }
}

output "node_group_asg_names" {
  description = "Map of node group names to their Auto Scaling Group names."
  value       = local.node_group_asg_map
}
