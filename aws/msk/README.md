# MSK Module

This module creates AWS MSK (Managed Streaming for Kafka) clusters and MSK Connect resources with configurable options for brokers, storage, security, and connector configurations.

## Features

- Provisions fully-managed Kafka clusters
- Supports both provisioned and serverless cluster types
- Configurable broker size, count, and storage options
- Encryption options for data at rest and in transit
- MSK Connect connectors with customizable worker configurations
- **S3 Sink Connector support** with IAM role creation for external S3 buckets
- Integration with VPC, security groups, and IAM
- Enhanced monitoring with CloudWatch and Prometheus

## Usage

```hcl
module "kafka" {
  source = "../../modules/msk"

  name        = "my-kafka-cluster"
  environment = "production"
  
  # Cluster configuration
  kafka_version    = "3.4.0"
  broker_node_type = "kafka.m5.large"
  broker_count     = 3
  
  # Network configuration
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  
  # Security
  security_groups = [module.kafka_sg.security_group_id]
  encryption_in_transit = {
    client_broker = "TLS"
    in_cluster    = true
  }
  encryption_at_rest_kms_key_arn = aws_kms_key.msk.arn
  
  # Storage
  broker_storage_info = {
    ebs_storage_info = {
      volume_size = 100
      provisioned_throughput = {
        enabled           = true
        volume_throughput = 250
      }
    }
  }
  
  # Monitoring
  enhanced_monitoring = "PER_BROKER"
  prometheus_jmx_exporter = true
  prometheus_node_exporter = true
  
  # Optional MSK Connect configuration (requires external S3 buckets)
  create_connector = true
  connector_config = {
    name = "s3-sink-connector"
    connector_class = "io.confluent.connect.s3.S3SinkConnector"
    worker_count = 2
    worker_config = {
      cpu         = 1
      memory      = 4
      volume_size = 10
    }
    plugins = [{
      custom_plugin = {
        name         = "kafka-connect-s3"
        content_type = "ZIP"
        location = {
          s3_location = {
            bucket_arn = "arn:aws:s3:::your-plugins-bucket"
            file_key   = "plugins/confluentinc-kafka-connect-s3-11.0.7.zip"
          }
        }
      }
    }]
    service_execution_role_arn = aws_iam_role.connector_role.arn
    capacity = {
      autoscaling = {
        min_worker_count = 1
        max_worker_count = 4
        scale_in_policy = {
          cpu_utilization_percentage = 20
        }
        scale_out_policy = {
          cpu_utilization_percentage = 80
        }
      }
    }
  }
  
  tags = {
    Environment = "production"
    Project     = "data-platform"
  }
}
```



## Input Variables

| Name                           | Description                              | Type         | Default          | Required |
| ------------------------------ | ---------------------------------------- | ------------ | ---------------- | -------- |
| name                           | Name of the MSK cluster                  | string       | n/a              | yes      |
| environment                    | Environment tag for resources            | string       | n/a              | yes      |
| kafka_version                  | Kafka version for the cluster            | string       | "3.4.0"          | no       |
| configuration_kafka_versions   | Kafka versions supported by the MSK configuration (for upgrades) | list(string) | null             | no       |
| broker_node_type               | Instance type for MSK broker nodes       | string       | "kafka.t3.small" | no       |
| broker_count                   | Number of broker nodes                   | number       | 3                | no       |
| vpc_id                         | VPC ID where the cluster will be created | string       | n/a              | yes      |
| subnet_ids                     | List of subnet IDs for the MSK cluster   | list(string) | n/a              | yes      |
| security_groups                | List of security group IDs               | list(string) | []               | no       |
| client_authentication          | Client authentication settings           | map(any)     | {}               | no       |
| encryption_in_transit          | Encryption in transit settings           | map(any)     | {}               | no       |
| encryption_at_rest_kms_key_arn | KMS key ARN for encryption at rest       | string       | null             | no       |
| enhanced_monitoring            | Monitoring level                         | string       | "DEFAULT"        | no       |
| prometheus_jmx_exporter        | Enable Prometheus JMX exporter           | bool         | false            | no       |
| prometheus_node_exporter       | Enable Prometheus Node exporter          | bool         | false            | no       |
| broker_storage_info            | Storage configuration for broker nodes   | map(any)     | {}               | no       |
| create_connector               | Whether to create an MSK connector       | bool         | false            | no       |
| connector_config               | Configuration for MSK connector          | map(any)     | {}               | no       |
| create_connector_iam_role      | Whether to create IAM role for MSK Connect | bool         | false            | no       |
| s3_bucket_arns                 | List of S3 bucket ARNs for MSK Connect access | list(string) | []               | no       |
| environment                    | Environment name for resource tagging    | string       | "development"    | no       |
| tags                           | Tags to apply to resources               | map(string)  | {}               | no       |

## Outputs

| Name                     | Description                                       |
| ------------------------ | ------------------------------------------------- |
| cluster_arn              | ARN of the MSK cluster                            |
| cluster_name             | Name of the MSK cluster                           |
| bootstrap_brokers        | Connection string for plaintext Kafka brokers     |
| bootstrap_brokers_tls    | Connection string for TLS encrypted Kafka brokers |
| bootstrap_brokers_sasl   | Connection string for SASL authenticated brokers  |
| zookeeper_connect_string | Connection string for ZooKeeper nodes             |
| connector_arn            | ARN of the MSK connector if created               |
| connector_name           | Name of the MSK connector if created              |
| connector_version        | Version of the MSK connector if created           |
| security_group_id        | ID of the security group created for MSK          |
| msk_connect_role_arn     | ARN of the IAM role for MSK Connect (if created)  |

## Prerequisites

### Security Groups

This module requires security groups to be provided externally. You should use the security-group module to create appropriate security groups before using this MSK module.

### S3 Buckets (for S3 Connectors)

When using S3 sink connectors, you need to create S3 buckets separately using your S3 module. The MSK module will create the necessary IAM roles and policies for MSK Connect to access these buckets.

**Required S3 Buckets:**
- **Plugins Bucket**: Stores the Kafka Connect S3 connector plugin
- **Data Bucket**: Stores the actual Kafka data streamed from topics

**S3 Connector Plugin Setup:**
1. Download the Confluent S3 Sink Connector plugin:
   ```bash
   wget https://hub-downloads.confluent.io/api/plugins/confluentinc/kafka-connect-s3/versions/11.0.7/confluentinc-kafka-connect-s3-11.0.7.zip
   ```

2. Upload the plugin to your plugins S3 bucket:
   ```bash
   aws s3 cp confluentinc-kafka-connect-s3-11.0.7.zip s3://your-plugins-bucket/plugins/
   ```

### Example: Creating Security Groups

Example creating security groups with your existing module:

```hcl
module "msk_sg" {
  source = "../../modules/security-group"
  
  name        = "msk-sg"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for MSK cluster"
  
  ingress_rules = [
    {
      from_port   = 9092
      to_port     = 9092
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
      description = "Kafka plaintext"
    },
    {
      from_port   = 9094
      to_port     = 9094
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
      description = "Kafka TLS"
    },
    {
      from_port   = 2181
      to_port     = 2181
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
      description = "ZooKeeper"
    }
  ]
  
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound"
    }
  ]
}

module "msk_cluster" {
  source = "../../modules/msk"
  
  name            = "my-kafka-cluster"
  environment     = "production"
  security_groups = [module.msk_sg.security_group_id]  # Pass the security group ID here
  
  # Other MSK configuration...
}

## Examples
Standard MSK Cluster with TLS Encryption
```hcl
module "kafka_standard" {
  source = "../../modules/msk"

  name        = "standard-kafka-cluster"
  environment = "production"
  
  kafka_version    = "3.4.0"
  broker_node_type = "kafka.m5.large"
  broker_count     = 3
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  
  encryption_in_transit = {
    client_broker = "TLS"
    in_cluster    = true
  }
  
  broker_storage_info = {
    ebs_storage_info = {
      volume_size = 100
    }
  }
  
  enhanced_monitoring = "PER_BROKER"
  
  tags = {
    Environment = "production"
  }
}
```

MSK Cluster with SASL/SCRAM Authentication
```hcl
module "kafka_auth" {
  source = "../../modules/msk"

  name        = "auth-kafka-cluster"
  environment = "staging"
  
  kafka_version    = "3.4.0"
  broker_node_type = "kafka.m5.large"
  broker_count     = 3
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  
  client_authentication = {
    sasl = {
      scram = true
    }
  }
  
  encryption_in_transit = {
    client_broker = "TLS"
    in_cluster    = true
  }
  
  tags = {
    Environment = "staging"
  }
}
```

MSK Connect S3 Sink Configuration with External S3 Buckets
```hcl
# Create S3 buckets using your S3 module
module "s3_plugins" {
  source = "your-s3-module"
  bucket_name = "my-kafka-plugins"
  # ... your S3 module configuration
}

module "s3_data" {
  source = "your-s3-module"
  bucket_name = "my-kafka-data"
  # ... your S3 module configuration
}

module "kafka_with_s3_connector" {
  source = "../../modules/msk"

  name        = "s3-connector-cluster"
  environment = "development"
  
  kafka_version    = "3.8.1"
  broker_node_type = "kafka.t3.small"
  broker_count     = 2
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  
  # Enable IAM role creation for MSK Connect
  create_connector_iam_role = true
  s3_bucket_arns = [
    module.s3_plugins.bucket_arn,
    module.s3_data.bucket_arn
  ]
  
  # Create the S3 sink connector
  create_connector = true
  connector_config = {
    name = "s3-sink-connector"
    connector_class = "io.confluent.connect.s3.S3SinkConnector"
    kafkaconnect_version = "2.7.1"
    worker_count = 1
    
    worker_config = {
      cpu         = 1
      memory      = 4
      volume_size = 10
    }
    
    # Connector properties
    properties = {
      "s3.bucket.name" = module.s3_data.bucket_name
      "s3.region" = "us-west-2"
      "flush.size" = "1000"
      "rotate.interval.ms" = "3600000"
      "format.class" = "io.confluent.connect.s3.format.avro.AvroFormat"
      "partitioner.class" = "io.confluent.connect.storage.partitioner.TimeBasedPartitioner"
      "path.format" = "'year'=YYYY/'month'=MM/'day'=dd/'hour'=HH"
      "topics" = "test-topic"
      "topics.dir" = "topics"
    }
    
    plugins = [{
      custom_plugin = {
        name         = "kafka-connect-s3"
        content_type = "ZIP"
        location = {
          s3_location = {
            bucket_arn = module.s3_plugins.bucket_arn
            file_key   = "plugins/confluentinc-kafka-connect-s3-11.0.7.zip"
          }
        }
      }
    }]
    
    # Use the automatically created IAM role
    service_execution_role_arn = module.kafka_with_s3_connector.msk_connect_role_arn
  }
  
  tags = {
    Environment = "development"
  }
}
```

## S3 Sink Connector Setup

The module supports S3 sink connectors with IAM role creation for MSK Connect. S3 buckets should be created separately using your S3 module.

### Prerequisites

1. **Create S3 buckets** using your S3 module:
   ```hcl
   module "s3_plugins" {
     source = "your-s3-module"
     bucket_name = "my-kafka-plugins"
     # ... your S3 module configuration
   }
   
   module "s3_data" {
     source = "your-s3-module"
     bucket_name = "my-kafka-data"
     # ... your S3 module configuration
   }
   ```

2. **Download the Confluent S3 Sink Connector plugin**:
   ```bash
   wget https://hub-downloads.confluent.io/api/plugins/confluentinc/kafka-connect-s3/versions/11.0.7/confluentinc-kafka-connect-s3-11.0.7.zip
   ```

3. **Upload the plugin to S3** (after creating the infrastructure):
   ```bash
   aws s3 cp confluentinc-kafka-connect-s3-11.0.7.zip s3://<plugins-bucket-name>/plugins/
   ```

### Quick Setup

```hcl
module "msk_s3" {
  source = "../../modules/msk"

  name        = "my-kafka-cluster"
  environment = "production"
  
  # Basic MSK configuration
  kafka_version    = "3.8.1"
  broker_node_type = "kafka.t3.small"
  broker_count     = 2
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  
  # Enable IAM role creation for MSK Connect
  create_connector_iam_role = true
  s3_bucket_arns = [
    module.s3_plugins.bucket_arn,
    module.s3_data.bucket_arn
  ]
  
  # Create S3 sink connector
  create_connector = true
  connector_config = {
    name = "s3-sink-connector"
    connector_class = "io.confluent.connect.s3.S3SinkConnector"
    properties = {
      "s3.bucket.name" = module.s3_data.bucket_name
      "topics" = "my-topic"
      "flush.size" = "1000"
    }
    plugins = [{
      custom_plugin = {
        name = "kafka-connect-s3"
        content_type = "ZIP"
        location = {
          s3_location = {
            bucket_arn = module.s3_plugins.bucket_arn
            file_key   = "plugins/confluentinc-kafka-connect-s3-11.0.7.zip"
          }
        }
      }
    }]
    service_execution_role_arn = module.msk_s3.msk_connect_role_arn
  }
}
```

### S3 Connector Configuration Options

| Property | Description | Default |
|----------|-------------|---------|
| `create_connector_iam_role` | Create IAM role and policies for MSK Connect | `false` |
| `s3_bucket_arns` | List of S3 bucket ARNs for MSK Connect access | `[]` |

### Outputs

When `create_connector_iam_role = true`, the module provides:

- `msk_connect_role_arn` - IAM role for MSK Connect

## Quick Start

### Basic MSK Cluster

Most users will consume this module as follows:

```hcl
module "msk" {
  source = "../../modules/msk"

  name            = "my-kafka-cluster"
  environment     = "production"
  kafka_version   = "3.8.1"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  security_groups = [module.msk_sg.security_group_id]

  # Optional: create a module-managed MSK configuration
  create_configuration          = true
  # Tip: list both current and next Kafka versions to enable non-destructive upgrades
  configuration_kafka_versions  = ["3.8.x", "3.9.x"]

  # Example encryption and monitoring
  encryption_in_transit = {
    client_broker = "TLS"
    in_cluster    = true
  }
  enhanced_monitoring      = "PER_BROKER"
  prometheus_jmx_exporter  = true
  prometheus_node_exporter = true

  tags = {
    Environment = "production"
    Project     = "data-platform"
  }
}
```

### MSK Cluster with S3 Connector

For S3 sink connectors, create S3 buckets first, then configure the connector:

```hcl
# Create S3 buckets using your S3 module
module "s3_plugins" {
  source = "your-s3-module"
  bucket_name = "my-kafka-plugins"
  # ... your S3 module configuration
}

module "s3_data" {
  source = "your-s3-module"
  bucket_name = "my-kafka-data"
  # ... your S3 module configuration
}

module "msk" {
  source = "../../modules/msk"

  name            = "my-kafka-cluster"
  environment     = "production"
  kafka_version   = "3.8.1"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  security_groups = [module.msk_sg.security_group_id]

  # Enable IAM role creation for MSK Connect
  create_connector_iam_role = true
  s3_bucket_arns = [
    module.s3_plugins.bucket_arn,
    module.s3_data.bucket_arn
  ]

  # Create S3 sink connector
  create_connector = true
  connector_config = {
    name = "s3-sink-connector"
    connector_class = "io.confluent.connect.s3.S3SinkConnector"
    properties = {
      "s3.bucket.name" = module.s3_data.bucket_name
      "topics" = "my-topic"
      "flush.size" = "1000"
    }
    plugins = [{
      custom_plugin = {
        name = "kafka-connect-s3"
        content_type = "ZIP"
        location = {
          s3_location = {
            bucket_arn = module.s3_plugins.bucket_arn
            file_key   = "plugins/confluentinc-kafka-connect-s3-11.0.7.zip"
          }
        }
      }
    }]
    service_execution_role_arn = module.msk.msk_connect_role_arn
  }

  tags = {
    Environment = "production"
    Project     = "data-platform"
  }
}
```

## Upgrading Kafka safely (non-destructive)

There are two common patterns, depending on whether your MSK configuration is managed by this module or outside of it.

- Module-managed configuration
  1. Ensure the MSK configuration supports both current and target versions, e.g.:
     - configuration_kafka_versions = ["3.8.x", "3.9.x"]
  2. Apply so the configuration revision is created/updated.
  3. Bump kafka_version on the cluster to the target version (e.g., "3.9.0") and apply again.

- Using an existing configuration (external resource)
  If you manage aws_msk_configuration outside of the module, set its kafka_versions to include all needed versions, then reference it from the module:

```hcl
resource "aws_msk_configuration" "example" {
  name           = "example-config"
  kafka_versions = ["3.8.x", "3.9.x"]
  server_properties = <<-EOT
    auto.create.topics.enable=true
    delete.topic.enable=true
  EOT
}

module "msk" {
  source = "../../modules/msk"

  name                         = "my-kafka-cluster"
  kafka_version                = "3.8.1"             # bump later to 3.9.x
  vpc_id                       = module.vpc.vpc_id
  subnet_ids                   = module.vpc.private_subnet_ids
  security_groups              = [module.msk_sg.security_group_id]

  # Use the existing configuration
  create_configuration         = false
  use_existing_configuration   = true
  existing_configuration_arn   = aws_msk_configuration.example.arn
  existing_configuration_revision = aws_msk_configuration.example.latest_revision
}
```

Notes
- The cluster's kafka_version still controls the actual broker version. The configuration's kafka_versions only ensures compatibility and avoids recreation during upgrades.
- When upgrading across major versions, review release notes for removed/changed broker properties in your server_properties.

## Troubleshooting

### S3 Connector Issues

**Connector Not Starting:**
1. Check MSK Connect logs in CloudWatch
2. Verify the S3 connector plugin is uploaded to the plugins bucket
3. Ensure IAM permissions are correct for the MSK Connect role
4. Verify the plugin file path in the connector configuration

**No Data in S3:**
1. Verify the topic name matches the connector configuration
2. Check that messages are being produced to the topic
3. Review connector logs for errors
4. Ensure the S3 data bucket has proper permissions

**Permission Errors:**
1. Verify the `s3_bucket_arns` variable includes all required buckets
2. Check that the MSK Connect role has access to both plugins and data buckets
3. Ensure bucket policies allow the MSK Connect service to access the buckets

### Common Configuration Issues

**Invalid Plugin Path:**
- Ensure the `file_key` in the plugin configuration matches the uploaded file path
- Use the correct plugin version (e.g., `confluentinc-kafka-connect-s3-11.0.7.zip`)

**Topic Configuration:**
- Use comma-separated topic names for multiple topics: `"topics" = "topic1,topic2,topic3"`
- Ensure topics exist before starting the connector

## Requirements
- Terraform >= 1.0.0
- AWS Provider >= 4.0.0