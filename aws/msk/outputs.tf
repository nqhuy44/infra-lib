# --- MSK Cluster Outputs ---
output "cluster_arn" {
  description = "Amazon Resource Name (ARN) of the MSK cluster"
  value       = var.create_cluster ? aws_msk_cluster.this[0].arn : null
}

output "cluster_name" {
  description = "Name of the MSK cluster"
  value       = var.create_cluster ? aws_msk_cluster.this[0].cluster_name : null
}

output "bootstrap_brokers" {
  description = "Connection host:port pairs for plain text Kafka brokers"
  value       = var.create_cluster ? aws_msk_cluster.this[0].bootstrap_brokers : null
}

output "bootstrap_brokers_tls" {
  description = "Connection host:port pairs for TLS encrypted Kafka brokers"
  value       = var.create_cluster ? aws_msk_cluster.this[0].bootstrap_brokers_tls : null
}

output "bootstrap_brokers_sasl_scram" {
  description = "Connection host:port pairs for SASL/SCRAM authentication"
  value       = var.create_cluster ? aws_msk_cluster.this[0].bootstrap_brokers_sasl_scram : null
}

output "bootstrap_brokers_sasl_iam" {
  description = "Connection host:port pairs for SASL/IAM authentication"
  value       = var.create_cluster ? aws_msk_cluster.this[0].bootstrap_brokers_sasl_iam : null
}

output "zookeeper_connect_string" {
  description = "Connection string for ZooKeeper"
  value       = var.create_cluster ? aws_msk_cluster.this[0].zookeeper_connect_string : null
}

output "zookeeper_connect_string_tls" {
  description = "Connection string for ZooKeeper with TLS"
  value       = var.create_cluster ? aws_msk_cluster.this[0].zookeeper_connect_string_tls : null
}

output "security_group_id" {
  description = "ID of the security group created for MSK"
  value       = local.create_sg ? aws_security_group.msk[0].id : null
}

output "configuration_arn" {
  description = "ARN of the MSK configuration"
  value       = var.create_cluster && var.create_configuration ? aws_msk_configuration.this[0].arn : null
}

output "configuration_latest_revision" {
  description = "Latest revision of the MSK configuration"
  value       = var.create_cluster && var.create_configuration ? aws_msk_configuration.this[0].latest_revision : null
}

# --- MSK Connect Outputs ---
output "connector_arn" {
  description = "ARN of the MSK connector"
  value       = var.create_connector && (var.create_cluster || var.external_bootstrap_servers != "") ? aws_mskconnect_connector.this[0].arn : null
}

output "connector_name" {
  description = "Name of the MSK connector"
  value       = var.create_connector && (var.create_cluster || var.external_bootstrap_servers != "") ? aws_mskconnect_connector.this[0].name : null
}

output "connector_version" {
  description = "Current version of the MSK connector"
  value       = var.create_connector && (var.create_cluster || var.external_bootstrap_servers != "") ? aws_mskconnect_connector.this[0].version : null
}

output "custom_plugin_arns" {
  description = "ARNs of the custom plugins created for the MSK connector"
  value       = var.create_connector && length(try(var.connector_config.plugins, [])) > 0 ? [for plugin in aws_mskconnect_custom_plugin.this : plugin.arn] : []
}

# --- MSK Connect IAM Outputs ---
output "msk_connect_role_arn" {
  description = "ARN of the IAM role for MSK Connect"
  value       = var.create_connector_iam_role ? aws_iam_role.msk_connect_role[0].arn : null
}

output "msk_connect_log_group_name" {
  description = "Name of the CloudWatch log group for MSK Connect"
  value       = var.create_connector ? aws_cloudwatch_log_group.msk_connect[0].name : null
}
