# --- Local Variables ---
locals {
  cluster_name        = var.name
  cluster_name_prefix = "${var.name}-"
  create_sg           = var.create_cluster && length(var.security_groups) == 0

  # Determine bootstrap servers for connector - use external or from created cluster
  bootstrap_servers = var.create_cluster && length(aws_msk_cluster.this) > 0 ? aws_msk_cluster.this[0].bootstrap_brokers_tls : var.external_bootstrap_servers
  # Use security groups from newly created ones or provided ones
  connector_security_groups = local.create_sg ? [aws_security_group.msk[0].id] : var.security_groups
}

# --- Default Security Group (created only if no security groups are provided) ---
resource "aws_security_group" "msk" {
  count = local.create_sg ? 1 : 0

  name_prefix = "${local.cluster_name_prefix}sg-"
  description = "Default security group for MSK cluster ${var.name}"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = var.client_cidr_blocks
    description = "Kafka plaintext port"
  }

  ingress {
    from_port   = 9094
    to_port     = 9094
    protocol    = "tcp"
    cidr_blocks = var.client_cidr_blocks
    description = "Kafka TLS port"
  }

  ingress {
    from_port   = 9096
    to_port     = 9096
    protocol    = "tcp"
    cidr_blocks = var.client_cidr_blocks
    description = "Kafka SASL port"
  }

  ingress {
    from_port   = 2181
    to_port     = 2181
    protocol    = "tcp"
    cidr_blocks = var.client_cidr_blocks
    description = "ZooKeeper port"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(var.tags, { Name = "${var.name}-msk-sg" })
}

# --- MSK Cluster Configuration ---
resource "aws_msk_configuration" "this" {
  count = var.create_cluster && var.create_configuration ? 1 : 0

  name              = "${var.name}-config"
  kafka_versions    = var.configuration_kafka_versions != null && length(var.configuration_kafka_versions) > 0 ? var.configuration_kafka_versions : [var.kafka_version]
  description       = "MSK configuration for ${var.name}"
  server_properties = var.server_properties

  lifecycle {
    create_before_destroy = true
  }
}

# --- MSK Cluster ---
resource "aws_msk_cluster" "this" {
  count = var.create_cluster ? 1 : 0

  cluster_name           = var.name
  kafka_version          = var.kafka_version
  number_of_broker_nodes = var.broker_count

  broker_node_group_info {
    instance_type   = var.broker_node_type
    client_subnets  = var.subnet_ids
    security_groups = local.create_sg ? [aws_security_group.msk[0].id] : var.security_groups

    dynamic "storage_info" {
      for_each = var.broker_storage_info != {} ? [var.broker_storage_info] : []
      content {
        dynamic "ebs_storage_info" {
          for_each = try(storage_info.value.ebs_storage_info, null) != null ? [storage_info.value.ebs_storage_info] : []
          content {
            volume_size = ebs_storage_info.value.volume_size

            dynamic "provisioned_throughput" {
              for_each = try(ebs_storage_info.value.provisioned_throughput, null) != null ? [ebs_storage_info.value.provisioned_throughput] : []
              content {
                enabled           = provisioned_throughput.value.enabled
                volume_throughput = try(provisioned_throughput.value.volume_throughput, null)
              }
            }
          }
        }
      }
    }
  }

  dynamic "configuration_info" {
    for_each = var.create_configuration || var.use_existing_configuration ? [1] : []
    content {
      arn      = var.use_existing_configuration ? var.existing_configuration_arn : aws_msk_configuration.this[0].arn
      revision = var.use_existing_configuration ? var.existing_configuration_revision : aws_msk_configuration.this[0].latest_revision
    }
  }

  dynamic "client_authentication" {
    for_each = length(var.client_authentication) > 0 ? [var.client_authentication] : []
    content {
      dynamic "sasl" {
        for_each = try(client_authentication.value.sasl, null) != null ? [client_authentication.value.sasl] : []
        content {
          iam   = try(sasl.value.iam, false)
          scram = try(sasl.value.scram, false)
        }
      }

      dynamic "tls" {
        for_each = try(client_authentication.value.tls, null) != null ? [client_authentication.value.tls] : []
        content {
          certificate_authority_arns = try(tls.value.certificate_authority_arns, null)
        }
      }

      unauthenticated = try(client_authentication.value.unauthenticated, false)
    }
  }

  dynamic "encryption_info" {
    for_each = local.encryption_info
    content {
      encryption_at_rest_kms_key_arn = var.encryption_at_rest_kms_key_arn

      dynamic "encryption_in_transit" {
        for_each = length(var.encryption_in_transit) > 0 ? [var.encryption_in_transit] : []
        content {
          client_broker = try(encryption_in_transit.value.client_broker, "TLS")
          in_cluster    = try(encryption_in_transit.value.in_cluster, true)
        }
      }
    }
  }

  open_monitoring {
    prometheus {
      jmx_exporter {
        enabled_in_broker = var.prometheus_jmx_exporter
      }
      node_exporter {
        enabled_in_broker = var.prometheus_node_exporter
      }
    }
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = var.logging_cloudwatch
        log_group = var.cloudwatch_log_group
      }
      s3 {
        enabled = var.logging_s3
        bucket  = var.logging_bucket
        prefix  = var.logging_prefix
      }
      firehose {
        enabled         = var.logging_firehose
        delivery_stream = var.firehose_delivery_stream
      }
    }
  }

  enhanced_monitoring = var.enhanced_monitoring

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

# --- MSK Connect Custom Plugin (for connector if needed) ---
resource "aws_mskconnect_worker_configuration" "this" {
  count = var.create_connector && try(var.connector_config.worker_config, null) != null ? 1 : 0

  name = "${try(var.connector_config.name, "${var.name}-connector")}-worker-config"

  # Properties file content with worker configuration
  properties_file_content = base64encode(join("\n", [
    "# Required converter properties",
    "key.converter=${try(var.connector_config.worker_config.key_converter, "org.apache.kafka.connect.storage.StringConverter")}",
    "value.converter=${try(var.connector_config.worker_config.value_converter, "org.apache.kafka.connect.json.JsonConverter")}",
    "",
    "# Worker resource configuration",
    "connector.worker.cpu=${try(var.connector_config.worker_config.cpu, 1)}",
    "connector.worker.memory=${try(var.connector_config.worker_config.memory, 4)}",
    "connector.worker.disk=${try(var.connector_config.worker_config.volume_size, 10)}"
  ]))
}

resource "aws_mskconnect_custom_plugin" "this" {
  count = var.create_connector && length(try(var.connector_config.plugins, [])) > 0 ? length(var.connector_config.plugins) : 0

  name         = try(var.connector_config.plugins[count.index].custom_plugin.name, "plugin-${count.index}")
  content_type = try(var.connector_config.plugins[count.index].custom_plugin.content_type, "JAR")

  dynamic "location" {
    for_each = try([var.connector_config.plugins[count.index].custom_plugin.location], [])
    content {
      dynamic "s3" {
        for_each = try([location.value.s3_location], [])
        content {
          bucket_arn     = s3.value.bucket_arn
          file_key       = s3.value.file_key
          object_version = try(s3.value.object_version, null)
        }
      }
    }
  }
}

# --- MSK Connect Connector ---
resource "aws_mskconnect_connector" "this" {
  count = var.create_connector && (var.create_cluster || var.external_bootstrap_servers != "") ? 1 : 0

  name = try(var.connector_config.name, "${var.name}-connector")

  kafkaconnect_version = try(var.connector_config.kafkaconnect_version, "2.7.1")

  capacity {
    dynamic "autoscaling" {
      for_each = try([var.connector_config.capacity.autoscaling], [])
      content {
        max_worker_count = autoscaling.value.max_worker_count
        min_worker_count = try(autoscaling.value.min_worker_count, 1)

        dynamic "scale_in_policy" {
          for_each = try([autoscaling.value.scale_in_policy], [])
          content {
            cpu_utilization_percentage = scale_in_policy.value.cpu_utilization_percentage
          }
        }

        dynamic "scale_out_policy" {
          for_each = try([autoscaling.value.scale_out_policy], [])
          content {
            cpu_utilization_percentage = scale_out_policy.value.cpu_utilization_percentage
          }
        }
      }
    }

    dynamic "provisioned_capacity" {
      for_each = try(var.connector_config.capacity.autoscaling, null) == null ? [1] : []
      content {
        worker_count = try(var.connector_config.capacity.provisioned_capacity.worker_count, 1)
      }
    }
  }

  connector_configuration = merge(
    {
      "connector.class" = try(var.connector_config.connector_class, "")
      "tasks.max"       = try(var.connector_config.tasks_max, "1")
    },
    try(var.connector_config.properties, {})
  )

  dynamic "kafka_cluster" {
    for_each = [1]
    content {
      apache_kafka_cluster {
        bootstrap_servers = local.bootstrap_servers
        vpc {
          security_groups = local.connector_security_groups
          subnets         = var.connector_subnet_ids != null ? var.connector_subnet_ids : var.subnet_ids
        }
      }
    }
  }

  kafka_cluster_client_authentication {
    authentication_type = var.connector_authentication_type
  }

  kafka_cluster_encryption_in_transit {
    encryption_type = var.connector_encryption_type
  }

  dynamic "plugin" {
    for_each = try(var.connector_config.plugins, [])
    content {
      custom_plugin {
        arn      = aws_mskconnect_custom_plugin.this[index(var.connector_config.plugins, plugin.value)].arn
        revision = aws_mskconnect_custom_plugin.this[index(var.connector_config.plugins, plugin.value)].latest_revision
      }
    }
  }

  service_execution_role_arn = try(var.connector_config.service_execution_role_arn, null)

  dynamic "worker_configuration" {
    for_each = var.create_connector && try(var.connector_config.worker_config, null) != null && length(aws_mskconnect_worker_configuration.this) > 0 ? [var.connector_config.worker_config] : []
    content {
      arn      = aws_mskconnect_worker_configuration.this[0].arn
      revision = aws_mskconnect_worker_configuration.this[0].latest_revision
    }
  }

  log_delivery {
    dynamic "worker_log_delivery" {
      for_each = [1]
      content {
        dynamic "cloudwatch_logs" {
          for_each = try(var.connector_config.logging.cloudwatch_enabled, true) ? [1] : []
          content {
            enabled   = true
            log_group = try(var.connector_config.logging.cloudwatch_log_group, aws_cloudwatch_log_group.msk_connect[0].name)
          }
        }
        dynamic "s3" {
          for_each = try(var.connector_config.logging.s3_enabled, false) ? [1] : []
          content {
            enabled = true
            bucket  = var.connector_config.logging.s3_bucket
            prefix  = try(var.connector_config.logging.s3_prefix, null)
          }
        }
        dynamic "firehose" {
          for_each = try(var.connector_config.logging.firehose_enabled, false) ? [1] : []
          content {
            enabled         = true
            delivery_stream = var.connector_config.logging.firehose_delivery_stream
          }
        }
      }
    }
  }

  # Only depend on the MSK cluster if we're creating one
  #   depends_on = var.create_cluster ? [aws_msk_cluster.this[0]] : []

  lifecycle {
    # Ignore changes to bootstrap servers to prevent unnecessary replacements
    # when MSK cluster broker nodes change
    ignore_changes = [
      kafka_cluster[0].apache_kafka_cluster[0].bootstrap_servers
    ]
  }
}

# --- CloudWatch Log Group for MSK Connect (Optional) ---
resource "aws_cloudwatch_log_group" "msk_connect" {
  count = var.create_connector ? 1 : 0
  
  name              = "/aws/msk-connect/${try(var.connector_config.name, var.name)}"
  retention_in_days = 14

  tags = merge(var.tags, {
    Name        = "${var.name}-msk-connect-logs"
  })
}

# --- IAM Resources for MSK Connect (Optional) ---

# IAM Role for MSK Connect
resource "aws_iam_role" "msk_connect_role" {
  count = var.create_connector_iam_role ? 1 : 0
  name  = "${var.name}-msk-connect-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "kafkaconnect.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "${var.name}-msk-connect-role"
  })
}

# IAM Policy for MSK Connect to access S3 (requires external S3 bucket ARNs)
resource "aws_iam_policy" "msk_connect_s3_policy" {
  count       = var.create_connector_iam_role && length(var.s3_bucket_arns) > 0 ? 1 : 0
  name        = "${var.name}-msk-connect-s3-policy"
  description = "Policy for MSK Connect to access S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = concat(
          var.s3_bucket_arns,
          [for arn in var.s3_bucket_arns : "${arn}/*"]
        )
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = concat(
          ["arn:aws:logs:*:*:*"],
          var.create_connector ? [aws_cloudwatch_log_group.msk_connect[0].arn] : []
        )
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "${var.name}-msk-connect-s3-policy"
  })
}

# Attach S3 policy to role
resource "aws_iam_role_policy_attachment" "msk_connect_s3_policy" {
  count      = var.create_connector_iam_role && length(var.s3_bucket_arns) > 0 ? 1 : 0
  role       = aws_iam_role.msk_connect_role[0].name
  policy_arn = aws_iam_policy.msk_connect_s3_policy[0].arn
}

# IAM Policy for MSK Connect to access MSK cluster
resource "aws_iam_policy" "msk_connect_kafka_policy" {
  count       = var.create_connector_iam_role ? 1 : 0
  name        = "${var.name}-msk-connect-kafka-policy"
  description = "Policy for MSK Connect to access MSK cluster"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:Connect",
          "kafka-cluster:AlterCluster",
          "kafka-cluster:DescribeCluster"
        ]
        Resource = var.create_cluster ? aws_msk_cluster.this[0].arn : "*"
      },
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:*Topic*",
          "kafka-cluster:WriteData",
          "kafka-cluster:ReadData"
        ]
        Resource = var.create_cluster ? "${aws_msk_cluster.this[0].arn}/*" : "*"
      },
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:DescribeGroup"
        ]
        Resource = var.create_cluster ? "${aws_msk_cluster.this[0].arn}/*" : "*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "${var.name}-msk-connect-kafka-policy"
  })
}

# Attach Kafka policy to role
resource "aws_iam_role_policy_attachment" "msk_connect_kafka_policy" {
  count      = var.create_connector_iam_role ? 1 : 0
  role       = aws_iam_role.msk_connect_role[0].name
  policy_arn = aws_iam_policy.msk_connect_kafka_policy[0].arn
}

locals {
  encryption_info = var.encryption_at_rest_kms_key_arn != null || length(var.encryption_in_transit) > 0 ? [1] : []
}
