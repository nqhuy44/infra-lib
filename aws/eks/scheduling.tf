# --- Node Group Scheduled Scaling ---
# This file contains resources for scheduled scaling of EKS managed node groups.
# EKS managed node groups create Auto Scaling Groups under the hood, which we can schedule.

# Data source to get ALL Auto Scaling Groups for this cluster
# We can't use wildcards in tag filters, so we get all ASGs for the cluster and filter in locals
data "aws_autoscaling_groups" "cluster" {
  filter {
    name   = "tag:eks:cluster-name"
    values = [var.cluster_name]
  }

  # Ensure we only look for ASGs after node groups are created
  depends_on = [
    aws_eks_node_group.this,
    aws_eks_node_group.this_cbd
  ]
}

# External data source to get current time at apply time
# This is needed because timestamp() is evaluated at plan time, not apply time
data "external" "current_time" {
  program = ["sh", "-c", "echo '{\"time\":\"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'\"}'"]
}

# Local to map node group names to their ASG names
locals {
  # Get all ASG names and their nodegroup tags from the cluster
  all_cluster_asgs = try(data.aws_autoscaling_groups.cluster.names, [])
  
  # Create a map of node group keys to their ASG names
  # Match by checking if the ASG name contains the cluster name and node group key
  # Use expanded schedules to get the list of node groups (excluding "defaults")
  node_group_asg_map = {
    for ng_key in keys(local.node_group_schedules_expanded) : ng_key => [
      for asg_name in local.all_cluster_asgs : asg_name
      if can(regex("${var.cluster_name}-${ng_key}", asg_name))
    ][0]
    if length([
      for asg_name in local.all_cluster_asgs : asg_name
      if can(regex("${var.cluster_name}-${ng_key}", asg_name))
    ]) > 0
  }

  # Get defaults from the config (if provided)
  schedule_defaults = try(var.node_group_schedules["defaults"], {
    scale_down = {
      min_size     = 0
      max_size     = 0
      desired_size = 0
    }
    scale_up = {
      min_size     = 2
      max_size     = 2
      desired_size = 2
    }
  })

  # Helper to parse size string "min max desired" -> {min_size, max_size, desired_size}
  parse_size_string = {
    for ng_key, ng_config in var.node_group_schedules : ng_key => {
      scale_down = {
        # Check if size is defined at scale_down level
        size_str = try(ng_config.scale_down.size, null)
        min_size = try(ng_config.scale_down.size, null) != null ? try(tonumber(split(" ", ng_config.scale_down.size)[0]), local.schedule_defaults.scale_down.min_size) : local.schedule_defaults.scale_down.min_size
        max_size = try(ng_config.scale_down.size, null) != null ? try(tonumber(split(" ", ng_config.scale_down.size)[1]), local.schedule_defaults.scale_down.max_size) : local.schedule_defaults.scale_down.max_size
        desired_size = try(ng_config.scale_down.size, null) != null ? try(tonumber(split(" ", ng_config.scale_down.size)[2]), local.schedule_defaults.scale_down.desired_size) : local.schedule_defaults.scale_down.desired_size
      }
      scale_up = {
        # Check if size is defined at scale_up level
        size_str = try(ng_config.scale_up.size, null)
        min_size = try(ng_config.scale_up.size, null) != null ? try(tonumber(split(" ", ng_config.scale_up.size)[0]), local.schedule_defaults.scale_up.min_size) : local.schedule_defaults.scale_up.min_size
        max_size = try(ng_config.scale_up.size, null) != null ? try(tonumber(split(" ", ng_config.scale_up.size)[1]), local.schedule_defaults.scale_up.max_size) : local.schedule_defaults.scale_up.max_size
        desired_size = try(ng_config.scale_up.size, null) != null ? try(tonumber(split(" ", ng_config.scale_up.size)[2]), local.schedule_defaults.scale_up.desired_size) : local.schedule_defaults.scale_up.desired_size
      }
    }
    if ng_key != "defaults"
  }

  # Parse compact schedule format: "HH:MM DAYS,HH:MM DAYS"
  # Supports both compact format (strings) and already-expanded format (objects)
  # Also supports new format with size and recurrence list
  parse_compact_schedule = {
    for ng_key, ng_config in var.node_group_schedules : ng_key => {
      timezone_offset = try(ng_config.timezone_offset, 0)
      
      # Parse scale_down - handle multiple formats:
      # 1. Object with min_size/max_size/desired_size
      # 2. String format: "HH:MM DAYS,HH:MM DAYS"
      # 3. New format: {size: "0 0 0", recurrence: ["23:30 MON-FRI", "20251225 20251226 22:00 SAT-SUN"]}
      scale_down_schedules = concat(
        # If it's an object with min_size, include it
        can(ng_config.scale_down.min_size) ? [ng_config.scale_down] : [],
        # If it's an object with size and recurrence list
        try(ng_config.scale_down.recurrence, null) != null ? [
          for rec_str in ng_config.scale_down.recurrence : {
            min_size     = local.parse_size_string[ng_key].scale_down.min_size
            max_size     = local.parse_size_string[ng_key].scale_down.max_size
            desired_size = local.parse_size_string[ng_key].scale_down.desired_size
            # Parse recurrence string - check if it starts with a date (8 digits YYYYMMDD)
            # Compute everything inline to avoid variable reference issues
            # If date range: "YYYYMMDD YYYYMMDD HH:MM DAYS"
            # Format YYYYMMDD to YYYY-MM-DD
            start_date   = length(split(" ", trimspace(rec_str))) >= 4 && can(regex("^[0-9]{8}$", split(" ", trimspace(rec_str))[0])) && can(regex("^[0-9]{8}$", split(" ", trimspace(rec_str))[1])) ? try(format("%s-%s-%s", substr(split(" ", trimspace(rec_str))[0], 0, 4), substr(split(" ", trimspace(rec_str))[0], 4, 2), substr(split(" ", trimspace(rec_str))[0], 6, 2)), null) : null
            end_date     = length(split(" ", trimspace(rec_str))) >= 4 && can(regex("^[0-9]{8}$", split(" ", trimspace(rec_str))[0])) && can(regex("^[0-9]{8}$", split(" ", trimspace(rec_str))[1])) ? try(format("%s-%s-%s", substr(split(" ", trimspace(rec_str))[1], 0, 4), substr(split(" ", trimspace(rec_str))[1], 4, 2), substr(split(" ", trimspace(rec_str))[1], 6, 2)), null) : null
            hour         = length(split(" ", trimspace(rec_str))) >= 4 && can(regex("^[0-9]{8}$", split(" ", trimspace(rec_str))[0])) && can(regex("^[0-9]{8}$", split(" ", trimspace(rec_str))[1])) ? try(tonumber(split(":", split(" ", trimspace(rec_str))[2])[0]), 0) : try(tonumber(split(":", split(" ", trimspace(rec_str))[0])[0]), 0)
            minute       = length(split(" ", trimspace(rec_str))) >= 4 && can(regex("^[0-9]{8}$", split(" ", trimspace(rec_str))[0])) && can(regex("^[0-9]{8}$", split(" ", trimspace(rec_str))[1])) ? try(tonumber(split(":", split(" ", trimspace(rec_str))[2])[1]), 0) : try(tonumber(split(":", split(" ", trimspace(rec_str))[0])[1]), 0)
            days         = length(split(" ", trimspace(rec_str))) >= 4 && can(regex("^[0-9]{8}$", split(" ", trimspace(rec_str))[0])) && can(regex("^[0-9]{8}$", split(" ", trimspace(rec_str))[1])) ? try(trimspace(join(" ", slice(split(" ", trimspace(rec_str)), 3, length(split(" ", trimspace(rec_str)))))), "") : try(trimspace(join(" ", slice(split(" ", trimspace(rec_str)), 1, length(split(" ", trimspace(rec_str)))))), "")
          }
          if trimspace(rec_str) != "" && can(regex(":", trimspace(rec_str)))
        ] : [],
        # Handle separate start/end fields
        try(ng_config.scale_down_start, null) != null ? [
          {
            min_size     = try(ng_config.scale_down_min_size, try(local.schedule_defaults.scale_down.min_size, 0))
            max_size     = try(ng_config.scale_down_max_size, try(local.schedule_defaults.scale_down.max_size, 0))
            desired_size = try(ng_config.scale_down_desired_size, try(local.schedule_defaults.scale_down.desired_size, 0))
            hour         = try(tonumber(split(":", split(" ", trimspace(ng_config.scale_down_start))[0])[0]), 0)
            minute       = try(tonumber(split(":", split(" ", trimspace(ng_config.scale_down_start))[0])[1]), 0)
            days         = try(trimspace(join(" ", slice(split(" ", trimspace(ng_config.scale_down_start)), 1, length(split(" ", trimspace(ng_config.scale_down_start)))))), "")
          }
        ] : [],
        # Handle scale_up_end - creates scale_down action (to end scale-up period)
        try(ng_config.scale_up_end, null) != null ? [
          {
            min_size     = try(ng_config.scale_down_min_size, try(local.schedule_defaults.scale_down.min_size, 0))
            max_size     = try(ng_config.scale_down_max_size, try(local.schedule_defaults.scale_down.max_size, 0))
            desired_size = try(ng_config.scale_down_desired_size, try(local.schedule_defaults.scale_down.desired_size, 0))
            hour         = try(tonumber(split(":", split(" ", trimspace(ng_config.scale_up_end))[0])[0]), 0)
            minute       = try(tonumber(split(":", split(" ", trimspace(ng_config.scale_up_end))[0])[1]), 0)
            days         = try(trimspace(join(" ", slice(split(" ", trimspace(ng_config.scale_up_end)), 1, length(split(" ", trimspace(ng_config.scale_up_end)))))), "")
          }
        ] : [],
        # Handle time range end times from scale_up (e.g., "08:00-18:00" -> scale_down at 18:00)
        can(ng_config.scale_up.min_size) || try(ng_config.scale_up_start, null) != null || try(ng_config.scale_up.recurrence, null) != null ? [] : [
          for schedule_str in split(",", ng_config.scale_up) : {
            min_size     = try(ng_config.scale_down_min_size, try(local.schedule_defaults.scale_down.min_size, 0))
            max_size     = try(ng_config.scale_down_max_size, try(local.schedule_defaults.scale_down.max_size, 0))
            desired_size = try(ng_config.scale_down_desired_size, try(local.schedule_defaults.scale_down.desired_size, 0))
            # Extract end time from range - compute inline to avoid variable reference issues
            hour         = can(regex("-", split(" ", trimspace(schedule_str))[0])) ? try(tonumber(split(":", split("-", split(" ", trimspace(schedule_str))[0])[1])[0]), 0) : 0
            minute       = can(regex("-", split(" ", trimspace(schedule_str))[0])) ? try(tonumber(split(":", split("-", split(" ", trimspace(schedule_str))[0])[1])[1]), 0) : 0
            days         = can(regex("-", split(" ", trimspace(schedule_str))[0])) ? try(trimspace(join(" ", slice(split(" ", trimspace(schedule_str)), 1, length(split(" ", trimspace(schedule_str)))))), "") : ""
          }
          if trimspace(schedule_str) != "" && can(regex(":", trimspace(schedule_str))) && can(regex("-", split(" ", trimspace(schedule_str))[0]))
        ],
        # Parse the compact string format (empty if it's an object, using start/end, or has recurrence)
        can(ng_config.scale_down.min_size) || try(ng_config.scale_down_start, null) != null || try(ng_config.scale_down.recurrence, null) != null ? [] : [
          for schedule_str in split(",", ng_config.scale_down) : {
            min_size     = try(ng_config.scale_down_min_size, try(local.schedule_defaults.scale_down.min_size, 0))
            max_size     = try(ng_config.scale_down_max_size, try(local.schedule_defaults.scale_down.max_size, 0))
            desired_size = try(ng_config.scale_down_desired_size, try(local.schedule_defaults.scale_down.desired_size, 0))
            # Check if it's a time range and extract start time - compute inline to avoid variable reference issues
            hour         = can(regex("-", split(" ", trimspace(schedule_str))[0])) ? try(tonumber(split(":", split("-", split(" ", trimspace(schedule_str))[0])[0])[0]), 0) : try(tonumber(split(":", split(" ", trimspace(schedule_str))[0])[0]), 0)
            minute       = can(regex("-", split(" ", trimspace(schedule_str))[0])) ? try(tonumber(split(":", split("-", split(" ", trimspace(schedule_str))[0])[0])[1]), 0) : try(tonumber(split(":", split(" ", trimspace(schedule_str))[0])[1]), 0)
            days         = try(trimspace(join(" ", slice(split(" ", trimspace(schedule_str)), 1, length(split(" ", trimspace(schedule_str)))))), "")
          }
          if trimspace(schedule_str) != "" && can(regex(":", trimspace(schedule_str)))
        ],
      )
      
      # Parse scale_up - handle multiple formats:
      # 1. Object with min_size/max_size/desired_size
      # 2. String format: "HH:MM DAYS,HH:MM DAYS"
      # 3. New format: {size: "2 6 2", recurrence: ["8:30 MON-FRI", "20251225 20251226 10:00 SAT-SUN"]}
      scale_up_schedules = concat(
        # If it's an object with min_size, include it
        can(ng_config.scale_up.min_size) ? [ng_config.scale_up] : [],
        # If it's an object with size and recurrence list
        try(ng_config.scale_up.recurrence, null) != null ? [
          for rec_str in ng_config.scale_up.recurrence : {
            min_size     = local.parse_size_string[ng_key].scale_up.min_size
            max_size     = local.parse_size_string[ng_key].scale_up.max_size
            desired_size = local.parse_size_string[ng_key].scale_up.desired_size
            # Parse recurrence string - check if it starts with a date (8 digits YYYYMMDD)
            # Compute everything inline to avoid variable reference issues
            # If date range: "YYYYMMDD YYYYMMDD HH:MM DAYS"
            # Format YYYYMMDD to YYYY-MM-DD
            start_date   = length(split(" ", trimspace(rec_str))) >= 4 && can(regex("^[0-9]{8}$", split(" ", trimspace(rec_str))[0])) && can(regex("^[0-9]{8}$", split(" ", trimspace(rec_str))[1])) ? try(format("%s-%s-%s", substr(split(" ", trimspace(rec_str))[0], 0, 4), substr(split(" ", trimspace(rec_str))[0], 4, 2), substr(split(" ", trimspace(rec_str))[0], 6, 2)), null) : null
            end_date     = length(split(" ", trimspace(rec_str))) >= 4 && can(regex("^[0-9]{8}$", split(" ", trimspace(rec_str))[0])) && can(regex("^[0-9]{8}$", split(" ", trimspace(rec_str))[1])) ? try(format("%s-%s-%s", substr(split(" ", trimspace(rec_str))[1], 0, 4), substr(split(" ", trimspace(rec_str))[1], 4, 2), substr(split(" ", trimspace(rec_str))[1], 6, 2)), null) : null
            hour         = length(split(" ", trimspace(rec_str))) >= 4 && can(regex("^[0-9]{8}$", split(" ", trimspace(rec_str))[0])) && can(regex("^[0-9]{8}$", split(" ", trimspace(rec_str))[1])) ? try(tonumber(split(":", split(" ", trimspace(rec_str))[2])[0]), 0) : try(tonumber(split(":", split(" ", trimspace(rec_str))[0])[0]), 0)
            minute       = length(split(" ", trimspace(rec_str))) >= 4 && can(regex("^[0-9]{8}$", split(" ", trimspace(rec_str))[0])) && can(regex("^[0-9]{8}$", split(" ", trimspace(rec_str))[1])) ? try(tonumber(split(":", split(" ", trimspace(rec_str))[2])[1]), 0) : try(tonumber(split(":", split(" ", trimspace(rec_str))[0])[1]), 0)
            days         = length(split(" ", trimspace(rec_str))) >= 4 && can(regex("^[0-9]{8}$", split(" ", trimspace(rec_str))[0])) && can(regex("^[0-9]{8}$", split(" ", trimspace(rec_str))[1])) ? try(trimspace(join(" ", slice(split(" ", trimspace(rec_str)), 3, length(split(" ", trimspace(rec_str)))))), "") : try(trimspace(join(" ", slice(split(" ", trimspace(rec_str)), 1, length(split(" ", trimspace(rec_str)))))), "")
          }
          if trimspace(rec_str) != "" && can(regex(":", trimspace(rec_str)))
        ] : [],
        # Handle separate start/end fields
        try(ng_config.scale_up_start, null) != null ? [
          {
            min_size     = try(ng_config.scale_up_min_size, try(local.schedule_defaults.scale_up.min_size, 2))
            max_size     = try(ng_config.scale_up_max_size, try(local.schedule_defaults.scale_up.max_size, 10))
            desired_size = try(ng_config.scale_up_desired_size, try(local.schedule_defaults.scale_up.desired_size, 2))
            hour         = try(tonumber(split(":", split(" ", trimspace(ng_config.scale_up_start))[0])[0]), 0)
            minute       = try(tonumber(split(":", split(" ", trimspace(ng_config.scale_up_start))[0])[1]), 0)
            days         = try(trimspace(join(" ", slice(split(" ", trimspace(ng_config.scale_up_start)), 1, length(split(" ", trimspace(ng_config.scale_up_start)))))), "")
          }
        ] : [],
        # Handle scale_down_end - creates scale_up action (to end scale-down period)
        try(ng_config.scale_down_end, null) != null ? [
          {
            min_size     = try(ng_config.scale_up_min_size, try(local.schedule_defaults.scale_up.min_size, 2))
            max_size     = try(ng_config.scale_up_max_size, try(local.schedule_defaults.scale_up.max_size, 10))
            desired_size = try(ng_config.scale_up_desired_size, try(local.schedule_defaults.scale_up.desired_size, 2))
            hour         = try(tonumber(split(":", split(" ", trimspace(ng_config.scale_down_end))[0])[0]), 0)
            minute       = try(tonumber(split(":", split(" ", trimspace(ng_config.scale_down_end))[0])[1]), 0)
            days         = try(trimspace(join(" ", slice(split(" ", trimspace(ng_config.scale_down_end)), 1, length(split(" ", trimspace(ng_config.scale_down_end)))))), "")
          }
        ] : [],
        # Handle time range end times from scale_down (e.g., "23:30-06:00" -> scale_up at 06:00)
        can(ng_config.scale_down.min_size) || try(ng_config.scale_down_start, null) != null || try(ng_config.scale_down.recurrence, null) != null ? [] : [
          for schedule_str in split(",", ng_config.scale_down) : {
            min_size     = try(ng_config.scale_up_min_size, try(local.schedule_defaults.scale_up.min_size, 2))
            max_size     = try(ng_config.scale_up_max_size, try(local.schedule_defaults.scale_up.max_size, 10))
            desired_size = try(ng_config.scale_up_desired_size, try(local.schedule_defaults.scale_up.desired_size, 2))
            # Extract end time from range - compute inline to avoid variable reference issues
            hour         = can(regex("-", split(" ", trimspace(schedule_str))[0])) ? try(tonumber(split(":", split("-", split(" ", trimspace(schedule_str))[0])[1])[0]), 0) : 0
            minute       = can(regex("-", split(" ", trimspace(schedule_str))[0])) ? try(tonumber(split(":", split("-", split(" ", trimspace(schedule_str))[0])[1])[1]), 0) : 0
            days         = can(regex("-", split(" ", trimspace(schedule_str))[0])) ? try(trimspace(join(" ", slice(split(" ", trimspace(schedule_str)), 1, length(split(" ", trimspace(schedule_str)))))), "") : ""
          }
          if trimspace(schedule_str) != "" && can(regex(":", trimspace(schedule_str))) && can(regex("-", split(" ", trimspace(schedule_str))[0]))
        ],
        # Parse the compact string format (empty if it's an object, using start/end, or has recurrence)
        can(ng_config.scale_up.min_size) || try(ng_config.scale_up_start, null) != null || try(ng_config.scale_up.recurrence, null) != null ? [] : [
          for schedule_str in split(",", ng_config.scale_up) : {
            min_size     = try(ng_config.scale_up_min_size, try(local.schedule_defaults.scale_up.min_size, 2))
            max_size     = try(ng_config.scale_up_max_size, try(local.schedule_defaults.scale_up.max_size, 10))
            desired_size = try(ng_config.scale_up_desired_size, try(local.schedule_defaults.scale_up.desired_size, 2))
            # Check if it's a time range and extract start time - compute inline to avoid variable reference issues
            hour         = can(regex("-", split(" ", trimspace(schedule_str))[0])) ? try(tonumber(split(":", split("-", split(" ", trimspace(schedule_str))[0])[0])[0]), 0) : try(tonumber(split(":", split(" ", trimspace(schedule_str))[0])[0]), 0)
            minute       = can(regex("-", split(" ", trimspace(schedule_str))[0])) ? try(tonumber(split(":", split("-", split(" ", trimspace(schedule_str))[0])[0])[1]), 0) : try(tonumber(split(":", split(" ", trimspace(schedule_str))[0])[1]), 0)
            days         = try(trimspace(join(" ", slice(split(" ", trimspace(schedule_str)), 1, length(split(" ", trimspace(schedule_str)))))), "")
          }
          if trimspace(schedule_str) != "" && can(regex(":", trimspace(schedule_str)))
        ],
      )
      
    }
    if ng_key != "defaults"
  }

  # Expand parsed schedules into individual schedule objects with unique names
  node_group_schedules_expanded = {
    for ng_key, parsed in local.parse_compact_schedule : ng_key => merge(
      { timezone_offset = parsed.timezone_offset },
      # Expand scale_down schedules with unique names
      length(parsed.scale_down_schedules) > 0 ? {
        for idx, schedule in parsed.scale_down_schedules : 
        "scale_down_${idx}" => schedule
      } : {},
      # Expand scale_up schedules with unique names (includes scale_down_end actions)
      length(parsed.scale_up_schedules) > 0 ? {
        for idx, schedule in parsed.scale_up_schedules : 
        "scale_up_${idx}" => schedule
      } : {},
      # Include any other schedules that aren't scale_down or scale_up (for backward compatibility)
      {
        for schedule_key, schedule in var.node_group_schedules[ng_key] :
        schedule_key => schedule
        if schedule_key != "timezone_offset" && 
           schedule_key != "scale_down" && 
           schedule_key != "scale_up" &&
           schedule_key != "scale_down_min_size" &&
           schedule_key != "scale_down_max_size" &&
           schedule_key != "scale_down_desired_size" &&
           schedule_key != "scale_up_min_size" &&
           schedule_key != "scale_up_max_size" &&
           schedule_key != "scale_up_desired_size" &&
           schedule_key != "defaults" &&
           try(schedule.min_size, null) != null
      }
    )
  }

  # Helper to format date + time to RFC3339 in UTC (for date range schedules)
  # AWS requires start_time and end_time to be in UTC format: "YYYY-MM-DDTHH:MM:SSZ"
  # start_time uses 00:01:00 LOCAL, converted to UTC with proper day rollover
  # Add a small offset (0-59 seconds) based on schedule_key to ensure uniqueness
  # AWS doesn't allow duplicate start_time on the same ASG
  format_rfc3339_time = {
    for ng_key, schedule_config in local.node_group_schedules_expanded : ng_key => {
      for schedule_key, schedule in schedule_config : schedule_key => (
        # Skip timezone_offset
        schedule_key == "timezone_offset" ? null : (
          # If start_date is provided, format as RFC3339 in UTC
          try(schedule.start_date, null) != null ? (
            # Local start: 00:01:XX at schedule.start_date in local TZ
            # Convert to UTC by subtracting timezone offset (hours) with day rollover
            format(
              "%04d-%02d-%02dT%02d:%02d:%02dZ",
              tonumber(split("-", schedule.start_date)[0]),
              tonumber(split("-", schedule.start_date)[1]),
              (0 - try(local.node_group_schedules_expanded[ng_key].timezone_offset, 0)) < 0 ?
                (tonumber(split("-", schedule.start_date)[2]) - 1 < 1 ? 1 : tonumber(split("-", schedule.start_date)[2]) - 1) :
                ((0 - try(local.node_group_schedules_expanded[ng_key].timezone_offset, 0)) >= 24 ?
                  tonumber(split("-", schedule.start_date)[2]) + 1 :
                  tonumber(split("-", schedule.start_date)[2])),
              (0 - try(local.node_group_schedules_expanded[ng_key].timezone_offset, 0)) < 0 ?
                (0 - try(local.node_group_schedules_expanded[ng_key].timezone_offset, 0) + 24) :
                ((0 - try(local.node_group_schedules_expanded[ng_key].timezone_offset, 0)) >= 24 ?
                  (0 - try(local.node_group_schedules_expanded[ng_key].timezone_offset, 0) - 24) :
                  (0 - try(local.node_group_schedules_expanded[ng_key].timezone_offset, 0))),
              1,
              length(schedule_key) % 60
            )
          ) : null
        )
      )
      if schedule_key != "timezone_offset"
    }
  }

  # Helper to format end date + time to RFC3339 in UTC
  # end_time uses 23:59:00 in LOCAL time, converted to UTC with day rollover
  format_rfc3339_end_time = {
    for ng_key, schedule_config in local.node_group_schedules_expanded : ng_key => {
      for schedule_key, schedule in schedule_config : schedule_key => (
        # Skip timezone_offset
        schedule_key == "timezone_offset" ? null : (
          # If end_date is provided, format as RFC3339 in UTC
          try(schedule.end_date, null) != null ? (
            # Local end: 23:59:00 at schedule.end_date in local TZ
            # Convert to UTC by subtracting timezone offset (hours) with day rollover
            format(
              "%04d-%02d-%02dT%02d:%02d:00Z",
              tonumber(split("-", schedule.end_date)[0]),
              tonumber(split("-", schedule.end_date)[1]),
              (23 - try(local.node_group_schedules_expanded[ng_key].timezone_offset, 0)) < 0 ?
                (tonumber(split("-", schedule.end_date)[2]) + 1) :
                ((23 - try(local.node_group_schedules_expanded[ng_key].timezone_offset, 0)) >= 24 ?
                  tonumber(split("-", schedule.end_date)[2]) + 1 :
                  tonumber(split("-", schedule.end_date)[2])),
              (23 - try(local.node_group_schedules_expanded[ng_key].timezone_offset, 0)) < 0 ?
                (23 - try(local.node_group_schedules_expanded[ng_key].timezone_offset, 0) + 24) :
                ((23 - try(local.node_group_schedules_expanded[ng_key].timezone_offset, 0)) >= 24 ?
                  (23 - try(local.node_group_schedules_expanded[ng_key].timezone_offset, 0) - 24) :
                  (23 - try(local.node_group_schedules_expanded[ng_key].timezone_offset, 0))),
              59
            )
          ) : null
        )
      )
      if schedule_key != "timezone_offset"
    }
  }

  # Helper to generate cron expression (in local time, not UTC)
  # AWS will handle timezone conversion when time_zone parameter is set
  # Supports any schedule name (scale_down, scale_up, scale_up_weekend, etc.)
  # Uses expanded schedules from compact format parsing
  # For date ranges: generate cron expression and use start_time/end_time to limit the date range
  # Date ranges use recurrence (cron) with start_time/end_time to limit when recurrence is active
  generate_cron_expression = {
    for ng_key, schedule_config in local.node_group_schedules_expanded : ng_key => {
      for schedule_key, schedule in schedule_config : schedule_key => (
        # Skip timezone_offset
        schedule_key == "timezone_offset" ? null : (
          # If recurrence is provided, use it directly
          try(schedule.recurrence, null) != null ? schedule.recurrence : (
            # Otherwise, generate from hour/minute/days (works for both regular and date range schedules)
            # For date ranges, we still generate cron - start_time/end_time will limit the date range
            try(schedule.hour, null) != null && try(schedule.minute, null) != null && try(schedule.days, null) != null ?
            format(
              "%d %d * * %s",
              schedule.minute,
              schedule.hour,
              schedule.days
            ) : null
          )
        )
      )
      if schedule_key != "timezone_offset"
    }
  }

  # Map timezone offsets to AWS timezone names
  # AWS uses IANA timezone database names
  timezone_map = {
    -12 = "Etc/GMT+12"
    -11 = "Pacific/Midway"
    -10 = "Pacific/Honolulu"
    -9  = "America/Anchorage"
    -8  = "America/Los_Angeles"
    -7  = "America/Denver"
    -6  = "America/Chicago"
    -5  = "America/New_York"
    -4  = "America/Santiago"
    -3  = "America/Sao_Paulo"
    -2  = "Atlantic/South_Georgia"
    -1  = "Atlantic/Azores"
    0   = "UTC"
    1   = "Europe/London"
    2   = "Europe/Berlin"
    3   = "Europe/Moscow"
    4   = "Asia/Dubai"
    5   = "Asia/Karachi"
    6   = "Asia/Dhaka"
    7   = "Asia/Bangkok"
    8   = "Asia/Singapore"
    9   = "Asia/Tokyo"
    10  = "Australia/Sydney"
    11  = "Pacific/Guadalcanal"
    12  = "Pacific/Auckland"
  }

  # Flatten schedules for easier iteration
  # Supports any number of schedules per node group (scale_down, scale_up, scale_up_weekend, etc.)
  # Uses expanded schedules from compact format parsing
  # Past schedules are handled by precondition in the resource, not filtered here
  node_group_schedules_flat = flatten([
    for ng_key, schedule_config in local.node_group_schedules_expanded : [
      for schedule_key, schedule in schedule_config : {
        ng_key       = ng_key
        action_type  = schedule_key
        min_size     = try(schedule.min_size, null)
        max_size     = try(schedule.max_size, null)
        desired_size = try(schedule.desired_size, null)
        # For date ranges: use start_time and end_time
        # AWS allows recurrence with start_time/end_time to limit when recurrence is active
        # For recurring schedules without date ranges: set start_time to null - will be calculated at apply time in resource
        # This ensures it's always in the future, even with delays between plan and apply
        start_time   = try(local.format_rfc3339_time[ng_key][schedule_key], null)
        end_time     = try(local.format_rfc3339_end_time[ng_key][schedule_key], null)
        # For recurring schedules: use recurrence (cron)
        # For date ranges: also use recurrence to specify the time pattern within the date range
        recurrence   = try(local.generate_cron_expression[ng_key][schedule_key], null)
        # Store start_date for date range schedules (used in precondition to validate future dates)
        start_date   = try(schedule.start_date, null)
        # Store schedule_key for uniqueness (used in hash)
        schedule_key_for_hash = schedule_key
      }
      if schedule_key != "timezone_offset" && try(schedule.min_size, null) != null
    ]
  ])

  # Create a map with unique keys for each schedule action
  # Include a hash of the configuration to make names unique and stable
  # Hash is based on schedule content (not index) so names stay stable when schedules are added/removed
  # The hash includes: recurrence, sizes (min/max/desired), and date ranges (start_time/end_time)
  # When recurrence or size changes in the YAML, the hash changes, triggering destroy+recreate
  # For recurring schedules: start_time is null in locals (calculated at apply time), so hash is stable
  # For date range schedules: start_time/end_time are included, so hash changes when dates change
  node_group_schedules_map = {
    for item in local.node_group_schedules_flat : 
    # Use a stable key that includes the config_hash instead of index
    # This prevents key changes when schedules are added/removed, avoiding state mismatches
    # Calculate hash once - it's used for both the key and stored as config_hash
    "${item.ng_key}-${item.action_type}-${substr(md5(join("|", [
      item.ng_key,
      item.action_type,
      item.schedule_key_for_hash,  # Include original schedule key to ensure uniqueness
      tostring(item.min_size),      # Size changes trigger recreation
      tostring(item.max_size),      # Size changes trigger recreation
      tostring(item.desired_size),  # Size changes trigger recreation
      item.start_time != null ? item.start_time : "",  # Date range changes trigger recreation
      item.end_time != null ? item.end_time : "",      # Date range changes trigger recreation
      item.recurrence != null ? item.recurrence : ""   # Recurrence changes trigger recreation
    ])), 0, 8)}" => merge(item, {
      # Store the same hash as config_hash for use in resource name
      config_hash = substr(md5(join("|", [
        item.ng_key,
        item.action_type,
        item.schedule_key_for_hash,
        tostring(item.min_size),
        tostring(item.max_size),
        tostring(item.desired_size),
        item.start_time != null ? item.start_time : "",
        item.end_time != null ? item.end_time : "",
        item.recurrence != null ? item.recurrence : ""
      ])), 0, 8)
    })
  }
}

# Create scheduled actions
# Note: We create resources for all schedules defined in var.node_group_schedules
# The ASG name is computed at apply time from the data source
#
# FIXED: AWS Eventual Consistency Issue
# To avoid "empty result" errors when replacing scheduled actions, we include a hash
# of the configuration in the scheduled action name. This ensures:
# - Different configurations get different names (no replace, just create new + destroy old)
# - Same configuration keeps the same name (no unnecessary changes)
# - Avoids the replace scenario that causes AWS eventual consistency issues
#
# Scheduled action names format: cluster-ng_key-action_type-hash
# Example: common-infra-nonprod-eks-scale_down_0-a1b2c3d4
resource "aws_autoscaling_schedule" "node_group_schedules" {
  # Create all schedules - past date ranges are rejected by precondition
  # Recurring schedules use current time + offset for start_time (calculated at apply time)
  for_each = local.node_group_schedules_map

  # Create scheduled action name with config hash to avoid replace scenarios
  # This prevents "empty result" errors by ensuring new configs get new names
  # Format: cluster-ng_key-action_type-hash
  # Example: common-infra-nonprod-eks-scale_down_0-a1b2c3d4
  scheduled_action_name  = "${var.cluster_name}-${each.value.ng_key}-${each.value.action_type}-${each.value.config_hash}"
  # Lookup ASG name from the map - will be computed at apply time
  # If ASG doesn't exist, lookup will return empty string and resource creation will fail
  # This is expected behavior - node group must exist before scheduling can be created
  # Note: When node groups are updated (e.g., max_size change), ASG names may change
  # and schedules will be recreated. The data source will refresh on the next plan/apply cycle.
  autoscaling_group_name = lookup(local.node_group_asg_map, each.value.ng_key, "")
  
  min_size         = each.value.min_size
  max_size         = each.value.max_size
  desired_capacity = each.value.desired_size
  
  start_time = try(each.value.start_time, null) != null ? try(each.value.start_time, null) : (
    each.value.recurrence != null ? (
      # Get timezone offset and calculate UTC time from local recurrence time
      # Calculate base start_time, then check if it's in the past
      # If it's in the past, add 24 hours to ensure it's always in the future
      # AWS requires start_time to be in the future, even for recurring schedules
      (
        timecmp(
          timeadd(
            format(
              "%sT%02d:%02d:00Z",
              # Get base date (today for scale_down, tomorrow for scale_up)
              startswith(each.value.action_type, "scale_up") 
                ? formatdate("YYYY-MM-DD", timeadd(data.external.current_time.result.time, "24h"))
                : formatdate("YYYY-MM-DD", data.external.current_time.result.time),
              # Convert local hour to UTC: local_hour - timezone_offset (with day rollover)
              (
                (try(tonumber(split(" ", each.value.recurrence)[1]), 0) - try(local.node_group_schedules_expanded[each.value.ng_key].timezone_offset, 0)) < 0
                ? (try(tonumber(split(" ", each.value.recurrence)[1]), 0) - try(local.node_group_schedules_expanded[each.value.ng_key].timezone_offset, 0)) + 24
                : (
                  (try(tonumber(split(" ", each.value.recurrence)[1]), 0) - try(local.node_group_schedules_expanded[each.value.ng_key].timezone_offset, 0)) >= 24
                  ? (try(tonumber(split(" ", each.value.recurrence)[1]), 0) - try(local.node_group_schedules_expanded[each.value.ng_key].timezone_offset, 0)) - 24
                  : (try(tonumber(split(" ", each.value.recurrence)[1]), 0) - try(local.node_group_schedules_expanded[each.value.ng_key].timezone_offset, 0))
                )
              ),
              # Minute stays the same (no timezone conversion needed for minutes)
              try(tonumber(split(" ", each.value.recurrence)[0]), 0)
            ),
            "${60 + ((length(each.key) * 17) % 60)}s"
          ),
          data.external.current_time.result.time
        ) < 0
        # If calculated time is in the past, add 24 hours
        ? timeadd(
            timeadd(
              format(
                "%sT%02d:%02d:00Z",
                # Get base date (today for scale_down, tomorrow for scale_up)
                startswith(each.value.action_type, "scale_up") 
                  ? formatdate("YYYY-MM-DD", timeadd(data.external.current_time.result.time, "24h"))
                  : formatdate("YYYY-MM-DD", data.external.current_time.result.time),
                # Convert local hour to UTC: local_hour - timezone_offset (with day rollover)
                (
                  (try(tonumber(split(" ", each.value.recurrence)[1]), 0) - try(local.node_group_schedules_expanded[each.value.ng_key].timezone_offset, 0)) < 0
                  ? (try(tonumber(split(" ", each.value.recurrence)[1]), 0) - try(local.node_group_schedules_expanded[each.value.ng_key].timezone_offset, 0)) + 24
                  : (
                    (try(tonumber(split(" ", each.value.recurrence)[1]), 0) - try(local.node_group_schedules_expanded[each.value.ng_key].timezone_offset, 0)) >= 24
                    ? (try(tonumber(split(" ", each.value.recurrence)[1]), 0) - try(local.node_group_schedules_expanded[each.value.ng_key].timezone_offset, 0)) - 24
                    : (try(tonumber(split(" ", each.value.recurrence)[1]), 0) - try(local.node_group_schedules_expanded[each.value.ng_key].timezone_offset, 0))
                  )
                ),
                # Minute stays the same (no timezone conversion needed for minutes)
                try(tonumber(split(" ", each.value.recurrence)[0]), 0)
              ),
              "${60 + ((length(each.key) * 17) % 60)}s"
            ),
            "24h"
          )
        # Otherwise use the calculated time as-is
        : timeadd(
            format(
              "%sT%02d:%02d:00Z",
              # Get base date (today for scale_down, tomorrow for scale_up)
              startswith(each.value.action_type, "scale_up") 
                ? formatdate("YYYY-MM-DD", timeadd(data.external.current_time.result.time, "24h"))
                : formatdate("YYYY-MM-DD", data.external.current_time.result.time),
              # Convert local hour to UTC: local_hour - timezone_offset (with day rollover)
              (
                (try(tonumber(split(" ", each.value.recurrence)[1]), 0) - try(local.node_group_schedules_expanded[each.value.ng_key].timezone_offset, 0)) < 0
                ? (try(tonumber(split(" ", each.value.recurrence)[1]), 0) - try(local.node_group_schedules_expanded[each.value.ng_key].timezone_offset, 0)) + 24
                : (
                  (try(tonumber(split(" ", each.value.recurrence)[1]), 0) - try(local.node_group_schedules_expanded[each.value.ng_key].timezone_offset, 0)) >= 24
                  ? (try(tonumber(split(" ", each.value.recurrence)[1]), 0) - try(local.node_group_schedules_expanded[each.value.ng_key].timezone_offset, 0)) - 24
                  : (try(tonumber(split(" ", each.value.recurrence)[1]), 0) - try(local.node_group_schedules_expanded[each.value.ng_key].timezone_offset, 0))
                )
              ),
              # Minute stays the same (no timezone conversion needed for minutes)
              try(tonumber(split(" ", each.value.recurrence)[0]), 0)
            ),
            "${60 + ((length(each.key) * 17) % 60)}s"
          )
      )
    ) : null
  )
  end_time   = try(each.value.end_time, null)
  recurrence = try(each.value.recurrence, null)
  
  # Set timezone - AWS will handle conversions and DST automatically
  # If timezone_offset is 0, use UTC; otherwise use mapped timezone name
  time_zone = lookup(
    local.timezone_map,
    try(local.node_group_schedules_expanded[each.value.ng_key].timezone_offset, 0),
    "UTC"
  )

  # Precondition: Skip schedules with past start_time or end_time (only for date range schedules)
  # For recurring schedules, start_time can be in the past (it's just for uniqueness, AWS uses recurrence)
  lifecycle {
    precondition {
      condition = (
        # If start_time is null, always allow
        each.value.start_time == null || 
        # If recurrence is set and end_time is null, this is a recurring schedule - allow past start_time
        (each.value.recurrence != null && each.value.end_time == null) ||
        # If start_time exists and it's a date range schedule, check if it's in the future
        (try(timecmp(each.value.start_time, timestamp()), 1) >= 0)
      ) && (
        # If end_time is null, always allow
        each.value.end_time == null || 
        # If end_time exists, check if it's in the future (date range schedules only)
        (try(timecmp(each.value.end_time, timestamp()), 1) >= 0)
      )
      error_message = "Schedule ${each.key} has a start_time or end_time in the past (for date range schedules). start_time: ${each.value.start_time != null ? each.value.start_time : "N/A"}, end_time: ${each.value.end_time != null ? each.value.end_time : "N/A"}. Please remove or update this schedule in your YAML configuration."
    }
    
    # Precondition: Validate that ASG exists before creating schedule
    # This prevents creation failures when ASG lookup returns empty string
    precondition {
      condition     = lookup(local.node_group_asg_map, each.value.ng_key, "") != ""
      error_message = "Auto Scaling Group not found for node group '${each.value.ng_key}'. The node group must exist and its ASG must be available before schedules can be created. If you just updated the node group, run 'terraform plan' again to refresh the ASG data source."
    }
    
    # AWS Eventual Consistency: When creating/replacing scheduled actions, you may see "empty result"
    # errors. This is expected - the resources are created successfully, but AWS needs time to propagate.
    # Solution: Simply retry `tofu apply` - the second attempt will succeed.
    # Using create_before_destroy to minimize disruption during replacements
    create_before_destroy = true
    
    # Ignore changes to start_time for recurring schedules (it's recalculated each apply)
    # For recurring schedules, start_time is recalculated each apply using external data source,
    # but we don't want to update the resource just because the time changed.
    # AWS uses recurrence for the actual schedule timing, not start_time.
    # This prevents unnecessary updates on every apply.
    # 
    # Ignore changes to autoscaling_group_name to allow scale config updates without schedule disruption
    # When you update min_size/max_size/desired_size, the ASG name lookup may change due to data source refresh timing,
    # but the actual ASG (and its schedules) remain valid. This prevents unnecessary schedule replacements.
    # Note: If the ASG is actually replaced (e.g., node group replacement), you may need to manually update schedules.
    ignore_changes = [
      start_time,              # Ignore start_time changes for recurring schedules (it's only for uniqueness)
      autoscaling_group_name   # Ignore ASG name changes to allow scale config updates without schedule disruption
    ]
  }

  depends_on = [
    aws_eks_node_group.this,
    aws_eks_node_group.this_cbd,
    data.external.current_time,
    data.aws_autoscaling_groups.cluster  # Ensure ASG data source is refreshed before creating schedules
  ]
}
