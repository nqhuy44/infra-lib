# EKS Terraform Module

Reusable Terraform module to provision an Amazon EKS cluster with managed node groups, IAM roles (including IRSA), and commonly used EKS add-ons. It includes several strategies and safeguards for zero/low-downtime upgrades.

## Table of Contents

- [Requirements](#requirements)
- [Features](#features)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
  - [Common Node Group Configuration](#common-node-group-configuration)
  - [Node Group Version Behavior](#node-group-version-behavior)
  - [Instance Purchase Options](#instance-purchase-options)
- [Advanced Features](#advanced-features)
  - [Zero-Downtime Strategies](#zero-downtime-strategies)
  - [Scheduled Node Group Scaling](#scheduled-node-group-scaling)
- [Reference](#reference)
  - [Inputs](#inputs)
  - [Outputs](#outputs)
  - [Terminology](#terminology)

## Requirements

- Terraform >= 1.3
- Providers:
  - `hashicorp/aws ~> 5.97`
  - `hashicorp/tls ~> 4.0`
  - `hashicorp/random ~> 3.6`

## Features

- **EKS Cluster**
  - Private/public endpoint controls
  - Configurable security groups
  - Access management via EKS Access Entries

- **Managed Node Groups**
  - Common configuration support (DRY principle)
  - Rolling update tuning (absolute or percentage-based)
  - Optional per-node-group Kubernetes version
  - Optional release version pinning for AWS-managed AMIs
  - Module-provided Launch Template (tags, disk settings)
  - Name rollover for create-before-destroy replacements
  - Automatic scaling guardrails (desired_size respects min_size)
  - Taints, labels, and custom EC2/volume tags

- **IAM & Security**
  - Cluster IAM role and policies
  - IRSA (IAM Roles for Service Accounts) with managed/inline policies
  - Optional Cluster Autoscaler IAM setup
  - EKS Access Entries and Access Policy Associations

- **Add-ons**
  - Staged deployment: core → node-dependent → observability
  - Automatic IRSA role linking
  - Version management

## Quick Start

Minimal working example:

```hcl
module "eks" {
  source = "../../../devops-terraform-modules/aws/eks"

  cluster_name    = "my-eks"
  cluster_version = "1.34"

  control_plane_subnet_ids = [
    module.vpc.subnet_ids["kubernetes-az1"],
    module.vpc.subnet_ids["kubernetes-az2"],
  ]

  eks_managed_node_groups = {
    system = {
      instance_types = ["t3.medium"]
      ami_type       = "AL2023_x86_64_STANDARD"
      min_size       = 2
      desired_size   = 2
      max_size       = 4
      update_config  = { max_unavailable_percentage = 25 }
    }
  }
}
```

## Configuration

### Common Node Group Configuration

The module supports defining common configuration that applies to all node groups, reducing repetition and ensuring consistency. Individual node group configurations merge with and can override the common configuration.

**Example:**

```hcl
module "eks" {
  source = "../../../devops-terraform-modules/aws/eks"

  cluster_name    = "my-eks"
  cluster_version = "1.34"

  control_plane_subnet_ids = [
    module.vpc.subnet_ids["kubernetes-az1"],
    module.vpc.subnet_ids["kubernetes-az2"],
  ]

  # Common configuration applied to all node groups
  common_node_group_config = {
    ami_type       = "AL2023_x86_64_STANDARD"
    version        = "1.34"
    subnet_ids = [
      module.vpc.subnet_ids["kubernetes-az1"],
      module.vpc.subnet_ids["kubernetes-az2"],
    ]
    security_group_ids = [module.eks_node_sg.security_group_id]
    capacity_type      = "ON_DEMAND"
    update_config = {
      max_unavailable_percentage = 25
    }
    enable_name_prefix_rollover = true
  }

  # Individual node groups - only need to specify what's different
  eks_managed_node_groups = {
    system = {
      instance_types = ["t3.medium"]
      min_size       = 3
      max_size       = 12
      desired_size   = 3
      disk_size      = 50
      labels         = { "node-type" = "system" }
    }
    
    workloads = {
      instance_types = ["t3a.2xlarge"]
      min_size       = 1
      max_size       = 20
      desired_size   = 1
      disk_size      = 100
      labels         = { "node-type" = "workloads" }
    }
    
    github-runners = {
      instance_types = ["t3a.xlarge"]
      min_size       = 1
      max_size       = 20
      desired_size   = 1
      disk_size      = 100
      labels         = { "node-type" = "github-runners" }
    }
  }
}
```

**Key Benefits:**
- **DRY Principle**: Define shared settings once instead of repeating them
- **Consistency**: Ensures all node groups use the same base configuration
- **Override Support**: Individual node groups can override any common setting
- **Maintainability**: Update common settings in one place to affect all node groups

### Node Group Version Behavior

- If a node group does not specify `version`, the module uses the cluster's `cluster_version`
- Specify `version` per node group only if you intentionally need divergence
- This allows gradual Kubernetes version upgrades across node groups

### Instance Purchase Options

The module supports configuring instance purchase options for cost optimization using the `capacity_type` parameter.

#### On-Demand vs Spot Instances

Use the `capacity_type` parameter to choose between on-demand and spot instances:

```hcl
eks_managed_node_groups = {
  on_demand_workers = {
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"  # Default
    min_size       = 2
    max_size       = 10
    desired_size   = 3
  }
  
  spot_workers = {
    instance_types = ["t3.medium", "t3a.medium", "t3.large"]  # Multiple types recommended
    capacity_type  = "SPOT"
    min_size       = 1
    max_size       = 20
    desired_size   = 5
  }
}
```

**Important Notes:**
- When using spot instances, specify multiple instance types to improve capacity availability
- EKS managed node groups control instance purchase options via the `capacity_type` field
- The `instance_market_options` variable exists for compatibility but is **not applied** to launch templates used by EKS managed node groups (AWS limitation)
- For advanced spot configuration (max price, interruption behavior, etc.), use self-managed node groups or configure the underlying Auto Scaling Group separately

#### Using in Common Configuration

You can set the capacity type in `common_node_group_config` to apply to all node groups:

```hcl
common_node_group_config = {
  capacity_type = "ON_DEMAND"  # or "SPOT"
  # ... other common config
}
```

Individual node groups can override the common `capacity_type`:

```hcl
common_node_group_config = {
  capacity_type = "ON_DEMAND"  # Default for all node groups
  # ... other common config
}

eks_managed_node_groups = {
  system = {
    instance_types = ["t3.medium"]
    # Uses ON_DEMAND from common config
  }
  
  spot_workers = {
    instance_types = ["t3.medium", "t3a.medium"]
    capacity_type  = "SPOT"  # Override to use spot instances
  }
}
```

## Advanced Features

### Zero-Downtime Strategies

The module provides several strategies for zero or low-downtime node group updates:

#### 1. Rolling Update Tuning (Recommended Default)

Set `update_config` per node group to control how nodes are updated. Default to `max_unavailable_percentage = 25` for a good balance of speed and safety.

```hcl
eks_managed_node_groups = {
  workers = {
    instance_types = ["m6i.large"]
    min_size       = 3
    desired_size   = 3
    max_size       = 6
    update_config  = { max_unavailable_percentage = 25 }
  }
}
```

**Options:**
- `max_unavailable`: Absolute number of nodes that can be unavailable during update
- `max_unavailable_percentage`: Percentage of nodes that can be unavailable (0-100)

#### 2. Blue/Green Deployment (Changing AMI Type)

Changing `ami_type` replaces the node group. Run two groups in parallel using different map keys, migrate workloads, then remove the old group.

```hcl
eks_managed_node_groups = {
  # Old node group
  workloads = {
    instance_types = ["m6i.large"]
    ami_type       = "AL2_x86_64"
    min_size       = 3
    desired_size   = 3
    max_size       = 6
    update_config  = { max_unavailable_percentage = 25 }
  }
  
  # New node group
  workloads_v2 = {
    instance_types = ["m6i.large"]
    ami_type       = "AL2023_x86_64_STANDARD"
    min_size       = 3
    desired_size   = 3
    max_size       = 6
    update_config  = { max_unavailable_percentage = 25 }
  }
}
```

**Best Practices:**
- Use different map keys to allow both node groups to exist concurrently
- Use labels/taints to steer workloads to the new group
- Respect Pod Disruption Budgets (PDBs) and topology spread constraints
- Advanced: Switch to a custom Launch Template with `ami_type = "CUSTOM"` for in-place AMI updates

#### 3. Create-Before-Destroy (Name Rollover)

Enable `enable_name_prefix_rollover = true` to generate a unique node group name with a short random suffix tied to `ami_type`. The module then uses create-before-destroy lifecycle.

```hcl
eks_managed_node_groups = {
  workloads = {
    instance_types = ["m6i.large"]
    ami_type       = "AL2023_x86_64_STANDARD"
    enable_name_prefix_rollover = true
    name_prefix = "workloads"  # Optional base prefix
    update_config = { max_unavailable_percentage = 25 }
  }
}
```

**How it works:**
- Name format: `${cluster_name}-${name_prefix_or_key}-${suffix}`
- New suffix is generated when `ami_type` changes
- Terraform creates the new group before destroying the old
- **Note**: Watch service quotas while two node groups coexist

#### 4. Scaling Guardrails

The module automatically ensures `desired_size >= min_size` to prevent update errors when you raise `min_size` above the current `desired_size`.

### Scheduled Node Group Scaling

The module supports automatic scheduled scaling of node groups to optimize costs by scaling down during off-hours and scaling up during business hours. This is particularly useful for non-production environments or workloads with predictable usage patterns.

#### How It Works

The module creates AWS Auto Scaling scheduled actions that automatically adjust the min, max, and desired capacity of your node groups based on cron schedules (UTC timezone).

#### Example: Timezone-Aware Scheduling

```hcl
module "eks" {
  source = "../../../devops-terraform-modules/aws/eks"

  cluster_name    = "my-eks"
  cluster_version = "1.34"

  control_plane_subnet_ids = [
    module.vpc.subnet_ids["kubernetes-az1"],
    module.vpc.subnet_ids["kubernetes-az2"],
  ]

  eks_managed_node_groups = {
    workloads = {
      instance_types = ["t3a.2xlarge"]
      min_size       = 1
      max_size       = 20
      desired_size   = 5
      disk_size      = 100
    }
    
    github-runners = {
      instance_types = ["t3a.xlarge"]
      min_size       = 1
      max_size       = 10
      desired_size   = 3
      disk_size      = 100
    }
  }

  # Schedule automatic scaling using LOCAL TIME (recommended approach)
  node_group_schedules = {
    # Scale down workloads at 8 PM, up at 6 AM (Bangkok/UTC+7 time)
    workloads = {
      timezone_offset = 7  # UTC+7 (Bangkok, Hanoi, Jakarta)
      scale_down = {
        min_size     = 0
        max_size     = 0
        desired_size = 0
        hour         = 20    # 8 PM local time
        minute       = 0
        days         = "MON-FRI"
      }
      scale_up = {
        min_size     = 1
        max_size     = 20
        desired_size = 5
        hour         = 6     # 6 AM local time
        minute       = 0
        days         = "MON-FRI"
      }
    }
    
    # Scale down github-runners at 10 PM, up at 6 AM (local time)
    github-runners = {
      timezone_offset = 7  # UTC+7
      scale_down = {
        min_size     = 0
        max_size     = 0
        desired_size = 0
        hour         = 22    # 10 PM local time
        minute       = 0
        days         = "MON-FRI"
      }
      scale_up = {
        min_size     = 1
        max_size     = 10
        desired_size = 3
        hour         = 6     # 6 AM local time
        minute       = 0
        days         = "MON-FRI"
      }
    }
  }
}
```

#### Alternative: UTC Cron Expressions

If you prefer manual conversion, you can use UTC cron expressions directly:

```hcl
node_group_schedules = {
  workloads = {
    scale_down = {
      min_size     = 0
      max_size     = 0
      desired_size = 0
      recurrence   = "0 13 * * MON-FRI"  # 8 PM UTC+7 = 13:00 UTC
    }
    scale_up = {
      min_size     = 1
      max_size     = 20
      desired_size = 5
      recurrence   = "0 23 * * SUN-THU"  # 6 AM UTC+7 = 23:00 UTC (previous day)
    }
  }
}
```

#### Cron Expression Format

Schedules use standard cron expressions in **UTC timezone**:

```
minute hour day-of-month month day-of-week
```

**Common Examples:**
- `"0 20 * * MON-FRI"` - 8 PM UTC on weekdays (Monday-Friday)
- `"0 6 * * MON-FRI"` - 6 AM UTC on weekdays
- `"0 22 * * *"` - 10 PM UTC every day
- `"0 8 * * 1-5"` - 8 AM UTC Monday through Friday
- `"0 0 * * SAT,SUN"` - Midnight UTC on weekends

**Important Notes:**
- All times are in **UTC timezone** - convert your local time to UTC
- The node group key in `node_group_schedules` must match the key in `eks_managed_node_groups`
- Both `scale_down` and `scale_up` are optional - you can define only one if needed
- Setting min/max/desired to 0 will completely scale down the node group (no nodes running)
- Make sure your workloads can tolerate the scheduled downtime when scaling to 0
- Consider using Pod Disruption Budgets (PDBs) to ensure graceful pod evictions

#### Cost Optimization Example

For development/staging environments, you might want to completely shut down outside business hours:

```hcl
node_group_schedules = {
  dev-workloads = {
    scale_down = {
      min_size     = 0
      max_size     = 0
      desired_size = 0
      recurrence   = "0 19 * * MON-FRI"  # 7 PM UTC weekdays
    }
    scale_up = {
      min_size     = 2
      max_size     = 10
      desired_size = 3
      recurrence   = "0 7 * * MON-FRI"   # 7 AM UTC weekdays
    }
  }
}
```

This configuration could save ~70% of compute costs by running nodes only during business hours (12 hours/day, 5 days/week = ~36% of the week).

#### Viewing Scheduled Actions

After applying, you can view the created scheduled actions:

```bash
# View all scheduled actions for a specific ASG
aws autoscaling describe-scheduled-actions \
  --auto-scaling-group-name $(terraform output -json node_group_asg_names | jq -r '.["your-node-group"]')

# Or view via Terraform outputs
terraform output node_group_scheduled_actions
```

## Reference

### Inputs

See `variables.tf` for the full, authoritative schema. Key inputs:

**Cluster Configuration:**
- `cluster_name` (string, required): Name of the EKS cluster
- `cluster_version` (string, required): Kubernetes version (e.g., "1.34")
- `control_plane_subnet_ids` (list(string), required): Subnet IDs for control plane ENIs
- `cluster_endpoint_public_access` (bool, default: false): Enable public API endpoint
- `cluster_endpoint_private_access` (bool, default: true): Enable private API endpoint
- `public_access_cidrs` (list(string), default: ["0.0.0.0/0"]): CIDR blocks allowed for public access
- `cluster_additional_security_group_ids` (list(string), default: []): Additional security groups for control plane

**Node Groups:**
- `common_node_group_config` (object, optional): Common configuration applied to all node groups
- `eks_managed_node_groups` (map(object), required): Map of node group definitions
  - `instance_types` (list(string), required): EC2 instance types
  - `ami_type` (string, optional): AMI type (e.g., "AL2023_x86_64_STANDARD")
  - `capacity_type` (string, optional, default: "ON_DEMAND"): "ON_DEMAND" or "SPOT"
  - `disk_size` (number, optional, default: 20): Root disk size in GiB
  - `min_size`, `max_size`, `desired_size` (number): Auto Scaling group sizes
  - `update_config` (object, optional): Update configuration
    - `max_unavailable` (number, optional): Absolute number of unavailable nodes
    - `max_unavailable_percentage` (number, optional): Percentage of unavailable nodes
  - `taints` (list(object), optional): Kubernetes taints
  - `labels` (map(string), optional): Kubernetes labels
  - `tags` (map(string), optional): AWS resource tags
  - `enable_name_prefix_rollover` (bool, optional): Enable create-before-destroy
  - See `variables.tf` for complete schema

**Add-ons:**
- `cluster_addons` (map(object), optional): EKS add-ons configuration
  - `enabled` (bool, optional, default: true)
  - `addon_version` (string, optional)
  - `resolve_conflicts` (string, optional, default: "OVERWRITE")
  - `irsa_role_key` (string, optional): Key in `iam_roles_for_service_accounts` to use

**IAM:**
- `iam_roles_for_service_accounts` (map(object), optional): IRSA role definitions
- `enable_cluster_autoscaler` (bool, optional, default: false): Enable Cluster Autoscaler IAM setup

**Access Management:**
- `access_entries` (map(object), optional): EKS Access Entries configuration

**Scheduling:**
- `node_group_schedules` (map(object), optional): Scheduled scaling actions

**Other:**
- `tags` (map(string), optional): Tags applied to all resources

### Outputs

See `outputs.tf` for details. Key outputs:

**Cluster:**
- `cluster_name`: EKS cluster name
- `cluster_arn`: EKS cluster ARN
- `cluster_endpoint`: Kubernetes API server endpoint
- `cluster_ca_certificate`: Base64 encoded CA certificate (sensitive)
- `cluster_oidc_issuer_url`: OIDC issuer URL for IRSA
- `oidc_provider_arn`: OIDC provider ARN
- `cluster_primary_security_group_id`: Cluster security group ID
- `cluster_role_arn`: Cluster IAM role ARN

**Node Groups:**
- `node_groups`: Map of node groups with details (arn, id, status, iam_role_arn, instance_types, capacity_type, ami_type, version)
- `node_group_asg_names`: Map of node group names to Auto Scaling Group names
- `node_group_scheduled_actions`: Map of scheduled scaling actions

**IAM:**
- `irsa_roles`: Map of IRSA roles (arn, name)

**Access:**
- `access_entries`: Map of access entries with principal_arn

**Add-ons:**
- `addons`: Map of deployed add-ons (arn, addon_name, addon_version)

### Terminology

- **ng**: Standard node groups created without lifecycle create-before-destroy using a stable name `${cluster_name}-${key}`
- **ng_cbd**: Node groups created with lifecycle create-before-destroy enabled via name rollover (CBD = create-before-destroy)
- **IRSA**: IAM Roles for Service Accounts - allows Kubernetes service accounts to assume IAM roles
- **Access Entries**: EKS Access Management feature for fine-grained cluster access control
