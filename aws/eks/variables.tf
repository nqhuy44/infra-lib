variable "cluster_name" {
  description = "Name of the EKS cluster. Will be used to prefix associated resources."
  type        = string
  validation {
    condition     = length(var.cluster_name) > 0 && length(var.cluster_name) <= 100
    error_message = "Cluster name must be between 1 and 100 characters."
  }
}

variable "cluster_version" {
  description = "Desired Kubernetes version for the EKS cluster (e.g., '1.29')."
  type        = string
}

variable "control_plane_subnet_ids" {
  description = "List of subnet IDs where the EKS control plane ENIs will be created. Typically private subnets."
  type        = list(string)
}

variable "cluster_endpoint_public_access" {
  description = "Indicates whether the Amazon EKS public API server endpoint is enabled."
  type        = bool
  default     = false # Default to private for better security
}

variable "cluster_endpoint_private_access" {
  description = "Indicates whether the Amazon EKS private API server endpoint is enabled."
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks that are allowed access to the public endpoint. Required if public access is enabled."
  type        = list(string)
  default     = ["0.0.0.0/0"] # Be cautious with this default in production
}

variable "cluster_additional_security_group_ids" {
  description = "List of additional security group IDs to attach to the EKS control plane ENIs."
  type        = list(string)
  default     = []
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Indicates whether the cluster creator IAM principal gets admin permissions by default (via bootstrap). Recommended to keep false and manage via access_entries."
  type        = bool
  default     = false
}

# --- Karpenter (optional) ---
variable "enable_karpenter" {
  description = "If true, enable Karpenter-related infrastructure managed by this module (e.g., node IAM role for Karpenter-provisioned nodes)."
  type        = bool
  default     = false
}

variable "karpenter_node_role_name" {
  description = "Name of the IAM role for Karpenter-provisioned nodes."
  type        = string
  default     = null
}

variable "karpenter_node_role_policy_arns" {
  description = "Managed policy ARNs to attach to the Karpenter node IAM role."
  type        = list(string)
  default = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ]
}

# --- Node Groups ---
variable "common_node_group_config" {
  description = <<-EOT
    Common configuration that will be applied to all node groups. Individual node group configurations will be merged with this common config.
    This allows you to define shared settings like ami_type, version, subnet_ids, security_group_ids, etc. once and apply them to all node groups.
  EOT
  type = object({
    # --- Optional: Naming & Identification ---
    name_prefix = optional(string) # If set, used instead of map key for resource naming. Useful for create_before_destroy.
    labels      = optional(map(string), {})
    tags        = optional(map(string), {}) # Additional tags specific to the node group resources (role, launch template, ASG)

    # --- Optional: Compute & Networking ---
    subnet_ids         = optional(list(string))         # Defaults to control_plane_subnet_ids if not set. Typically private subnets.
    security_group_ids = optional(list(string), [])     # IDs of security groups to attach to nodes.
    capacity_type      = optional(string, "ON_DEMAND")  # ON_DEMAND or SPOT
    ami_type           = optional(string) # e.g., AL2_x86_64, AL2_x86_64_GPU, BOTTLEROCKET_x86_64, etc.
    disk_size          = optional(number, 20)           # GiB

    # Kubernetes version for this node group. If unset, defaults to the cluster_version input.
    version = optional(string) # Kubernetes Version

    # --- Optional: Scaling & Updates ---
    min_size     = optional(number, 1)
    max_size     = optional(number, 3)
    desired_size = optional(number, 2)
    update_config = optional(object({
      # Set only one of the following. Prefer max_unavailable=1 for near zero-downtime rollouts.
      max_unavailable             = optional(number)     # Absolute number of nodes to be unavailable during update
      max_unavailable_percentage  = optional(number, 25) # Percentage of nodes to be unavailable during update
    }), {})

    taints = optional(list(object({
      key    = string
      value  = string
      effect = string # NO_SCHEDULE, NO_EXECUTE, PREFER_NO_SCHEDULE
    })), [])

    use_module_launch_template = optional(bool, true)

    extra_instance_tags = optional(map(string), {})

    enable_name_prefix_rollover = optional(bool, false)
  })
  default = {} # Default to no common configuration
}

variable "eks_managed_node_groups" {
  description = <<-EOT
    Map of EKS managed node group definitions. The map key is the logical name for the node group used in Terraform state.
    Each object requires at least 'instance_types'. Other attributes are optional with defaults.
    Common configuration from 'common_node_group_config' will be merged with individual node group configurations.
  EOT
  type = map(object({
    # --- Required ---
    instance_types = list(string) # e.g., ["t3.medium", "m5.large"]

    # --- Optional: Naming & Identification ---
    name_prefix = optional(string) # If set, used instead of map key for resource naming. Useful for create_before_destroy.
    labels      = optional(map(string), {})
    tags        = optional(map(string), {}) # Additional tags specific to the node group resources (role, launch template, ASG)

    # --- Optional: Compute & Networking ---
    subnet_ids         = optional(list(string))         # Defaults to control_plane_subnet_ids if not set. Typically private subnets.
    security_group_ids = optional(list(string), [])     # IDs of security groups to attach to nodes.
    capacity_type      = optional(string, "ON_DEMAND")  # ON_DEMAND or SPOT
    ami_type           = optional(string) # e.g., AL2_x86_64, AL2_x86_64_GPU, BOTTLEROCKET_x86_64, etc.
    disk_size          = optional(number, 20)           # GiB

    # Kubernetes version for this node group. If unset, defaults to the cluster_version input.
    version = optional(string) # Kubernetes Version

    # --- Optional: Scaling & Updates ---
    min_size     = optional(number, 1)
    max_size     = optional(number, 3)
    desired_size = optional(number, 2)
    update_config = optional(object({
      # Set only one of the following. Prefer max_unavailable=1 for near zero-downtime rollouts.
      max_unavailable             = optional(number)     # Absolute number of nodes to be unavailable during update
      max_unavailable_percentage  = optional(number, 25) # Percentage of nodes to be unavailable during update
    }), {})

    taints = optional(list(object({
      key    = string
      value  = string
      effect = string # NO_SCHEDULE, NO_EXECUTE, PREFER_NO_SCHEDULE
    })), [])

    use_module_launch_template = optional(bool, true)

    extra_instance_tags = optional(map(string), {})

    enable_name_prefix_rollover = optional(bool)
    
    enable_instance_types_replacement = optional(bool, true) # Set to true to include instance_types in keepers for replacement
  }))
  default = {} # Default to no managed node groups
}

# --- Addons ---
variable "cluster_addons" {
  description = "Map of EKS add-ons configurations"
  type = map(object({
    enabled                  = optional(bool, true)
    addon_version            = optional(string)
    resolve_conflicts        = optional(string, "OVERWRITE")
    service_account_role_arn = optional(string) # Explicit role ARN if provided
    irsa_role_key            = optional(string) # Key in iam_roles_for_service_accounts to use
    configuration_values     = optional(string)
    tags                     = optional(map(string), {})
  }))
  default = {}
}

# --- IAM Roles for Service Accounts (IRSA) ---
variable "iam_roles_for_service_accounts" {
  description = "Map defining IAM roles for specific Kubernetes service accounts (IRSA). Key is the logical name."
  type = map(object({
    name_prefix        = optional(string) # If set, used instead of map key for resource naming.
    namespace          = optional(string, "kube-system")
    service_account    = string                     # The name of the K8s ServiceAccount
    policy_arns        = optional(list(string), []) # List of managed policy ARNs to attach
    inline_policy_json = optional(string)           # JSON string for a single inline policy
    tags               = optional(map(string), {})
  }))
  default = {
    # Example for EBS CSI Driver, will be linked to addon automatically if key is 'ebs_csi_controller_sa'
    ebs_csi_controller_sa = {
      service_account = "ebs-csi-controller-sa"
      policy_arns     = ["arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"]
    }
    # Add other roles needed, e.g., external-dns, cert-manager, load-balancer-controller
  }
}

# --- Access Entries ---

variable "access_entries" {
  description = "Map defining access entries for the cluster using EKS Access Management. Key is the logical name."
  type = map(object({
    principal_arn     = string                       # ARN of the IAM user or role
    kubernetes_groups = optional(list(string), [])   # Optional: Assign K8s groups (less common with policy associations)
    type              = optional(string, "STANDARD") # STANDARD, FARGATE_LINUX, EC2_LINUX, EC2_WINDOWS
    policy_associations = optional(map(object({      # Map of policy associations, key is logical name
      policy_arn = string                            # ARN of an EKS Access Policy (e.g., AmazonEKSAdminPolicy) or custom IAM policy
      access_scope = object({
        type       = string                 # 'namespace' or 'cluster'
        namespaces = optional(list(string)) # Required if type is 'namespace'
      })
    })), {})
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "enable_cluster_autoscaler" {
  description = "Set to true to create the necessary IAM role, policy, and node group tags for the Kubernetes Cluster Autoscaler."
  type        = bool
  default     = false
}

variable "cluster_autoscaler_service_account_namespace" {
  description = "The Kubernetes namespace where the Cluster Autoscaler service account resides."
  type        = string
  default     = "kube-system"
}

variable "cluster_autoscaler_service_account_name" {
  description = "The Kubernetes service account name used by the Cluster Autoscaler."
  type        = string
  default     = "cluster-autoscaler" # Common default name
}

variable "tags" {
  description = "A map of tags to assign to all resources created by the module."
  type        = map(string)
  default     = {}
}

# --- Node Group Scheduled Scaling ---
variable "node_group_schedules" {
  description = "Map of scheduled scaling actions for node groups. Each key should match a node group name from eks_managed_node_groups."
  # Use 'any' type to allow flexible structure per node group
  # Each node group can have: timezone_offset (number) + any number of schedule objects
  # Validation will ensure proper structure
  type = any
  default = {}
  
  validation {
    condition = alltrue([
      for ng_key, schedule_config in var.node_group_schedules : alltrue([
        for schedule_key, schedule in schedule_config : 
        # Skip timezone_offset and defaults
        schedule_key == "timezone_offset" || schedule_key == "defaults" ? true : (
          # Skip scale_down, scale_up, and start/end fields - they can be strings (compact format) or objects
          # The module will handle parsing and validation
          # Also skip size and recurrence fields (new format)
          schedule_key == "scale_down" || schedule_key == "scale_up" ||
          schedule_key == "scale_down_start" || schedule_key == "scale_down_end" ||
          schedule_key == "scale_up_start" || schedule_key == "scale_up_end" ||
          schedule_key == "scale_down_min_size" || schedule_key == "scale_down_max_size" ||
          schedule_key == "scale_down_desired_size" || schedule_key == "scale_up_min_size" ||
          schedule_key == "scale_up_max_size" || schedule_key == "scale_up_desired_size" ||
          schedule_key == "size" || schedule_key == "recurrence" ? true : (
            # Only validate other schedule keys that are clearly objects
            # Check if it has min_size using can() to safely check property access
            can(schedule.min_size) && can(schedule.max_size) && can(schedule.desired_size) ? (
              # For full objects, validate they have proper structure
              (can(schedule.recurrence) && schedule.recurrence != null) || 
              (can(schedule.hour) && can(schedule.minute) && can(schedule.days) && 
               schedule.hour != null && schedule.minute != null && schedule.days != null)
            ) : true
          )
        )
      ])
    ])
    error_message = "Each schedule action must have either 'recurrence' (cron) OR 'hour', 'minute', and 'days' all set. Compact format strings (e.g., '23:30 MON-FRI') are also supported and will be parsed by the module."
  }
  
  validation {
    condition = alltrue([
      for ng_key, schedule_config in var.node_group_schedules : alltrue([
        for schedule_key, schedule in schedule_config : 
        schedule_key == "timezone_offset" || schedule_key == "defaults" || 
        schedule_key == "scale_down" || schedule_key == "scale_up" ||
        schedule_key == "scale_down_start" || schedule_key == "scale_down_end" ||
        schedule_key == "scale_up_start" || schedule_key == "scale_up_end" ? true : (
          # Only validate hour if it's clearly an object (has min_size property)
          can(schedule.hour) && can(schedule.min_size) ? 
          (schedule.hour >= 0 && schedule.hour <= 23) : true
        )
      ])
    ])
    error_message = "Hour must be between 0 and 23."
  }
  
  validation {
    condition = alltrue([
      for ng_key, schedule_config in var.node_group_schedules : alltrue([
        for schedule_key, schedule in schedule_config : 
        schedule_key == "timezone_offset" || schedule_key == "defaults" || 
        schedule_key == "scale_down" || schedule_key == "scale_up" ||
        schedule_key == "scale_down_start" || schedule_key == "scale_down_end" ||
        schedule_key == "scale_up_start" || schedule_key == "scale_up_end" ? true : (
          # Only validate minute if it's clearly an object (has min_size property)
          can(schedule.minute) && can(schedule.min_size) ? 
          (schedule.minute >= 0 && schedule.minute <= 59) : true
        )
      ])
    ])
    error_message = "Minute must be between 0 and 59."
  }
}
