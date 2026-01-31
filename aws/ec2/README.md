# AWS EC2 Instance Module

This Terraform module creates AWS EC2 instances with comprehensive configuration options including security groups, IAM instance profiles, EBS volumes, GPU support, and advanced networking features. It provides enterprise-grade defaults with security best practices.

## Features

- ✅ **Flexible Instance Configuration** - Support for all EC2 instance types
- ✅ **EBS Volume Management** - Root and additional EBS volumes with encryption
- ✅ **GPU Support** - Built-in validation and configuration for GPU instances
- ✅ **Security Hardening** - IMDSv2 enforcement and encryption by default
- ✅ **Network Flexibility** - Multiple network interfaces and IPv6 support
- ✅ **Monitoring Integration** - Detailed monitoring and CloudWatch support
- ✅ **User Data Support** - Both plain text and base64-encoded user data
- ✅ **Resource Tagging** - Comprehensive tagging support
- ✅ **Hibernation Support** - For supported instance types
- ✅ **Instane State Suport** - Stop or start the instance on demand

## Usage

### Basic Web Server

```hcl
module "web_server" {
  source = "github.com/your-org/terraform-modules//aws/ec2?ref=main"

  name            = "production-web-server"
  ami_id          = "ami-0abcdef1234567890"
  instance_type   = "t3.medium"
  subnet_id       = module.vpc.public_subnet_ids[0]

  # Security configuration
  vpc_security_group_ids = [
    module.web_security_group.security_group_id,
    module.ssh_security_group.security_group_id
  ]

  # SSH access
  key_name = "production-web-key"

  # Public IP for web server
  associate_public_ip_address = true

  # Enhanced root volume
  root_volume = {
    volume_size = 30
    volume_type = "gp3"
    iops        = 3000
    throughput  = 125
    encrypted   = true
  }

  # Web server initialization
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y nginx
    systemctl start nginx
    systemctl enable nginx

    # Configure basic security
    systemctl disable postfix
    systemctl stop postfix
  EOF

  # Security hardening
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # IMDSv2 only
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  tags = {
    Environment = "production"
    Service     = "web"
    Team        = "platform"
    Backup      = "daily"
  }
}
```

### Database Server with Multiple EBS Volumes

```hcl
module "database_server" {
  source = "github.com/your-org/terraform-modules//aws/ec2?ref=main"

  name          = "production-database"
  ami_id        = "ami-0abcdef1234567890"
  instance_type = "r6i.2xlarge"
  subnet_id     = module.vpc.private_subnet_ids[0]

  # Database security groups
  vpc_security_group_ids = [
    module.database_security_group.security_group_id,
    module.admin_access_security_group.security_group_id
  ]

  # IAM role for database access
  iam_instance_profile = module.database_iam_role.instance_profile_name

  # No public IP for database
  associate_public_ip_address = false

  # Enhanced root volume
  root_volume = {
    volume_size = 50
    volume_type = "gp3"
    iops        = 3000
    throughput  = 125
    encrypted   = true
    kms_key_id  = module.kms_key.key_id
  }

  # Additional EBS volumes for database storage
  ebs_volumes = [
    {
      device_name           = "/dev/xvdf"
      volume_size           = 500
      volume_type           = "io2"
      iops                  = 5000
      encrypted             = true
      kms_key_id            = module.kms_key.key_id
      delete_on_termination = false
      tags = {
        Name = "database-data-volume"
        Purpose = "database-storage"
      }
    },
    {
      device_name           = "/dev/xvdg"
      volume_size           = 200
      volume_type           = "gp3"
      iops                  = 3000
      throughput            = 125
      encrypted             = true
      kms_key_id            = module.kms_key.key_id
      delete_on_termination = false
      tags = {
        Name = "database-log-volume"
        Purpose = "database-logs"
      }
    }
  ]

  # Database initialization script
  user_data = base64encode(templatefile("${path.module}/scripts/database-init.sh", {
    db_name     = "production_db"
    environment = "production"
  }))

  # Enhanced monitoring
  enable_detailed_monitoring = true

  # Security hardening
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  tags = {
    Environment = "production"
    Service     = "database"
    Team        = "data"
    Backup      = "hourly"
    Compliance  = "required"
  }
}
```

### GPU Instance for Machine Learning

```hcl
module "ml_training_instance" {
  source = "github.com/your-org/terraform-modules//aws/ec2?ref=main"

  name          = "ml-training-gpu"
  ami_id        = "ami-0123456789abcdef0"  # Deep Learning AMI
  instance_type = "g5.2xlarge"             # GPU instance type
  subnet_id     = module.vpc.private_subnet_ids[0]

  # Enable GPU support with validation
  gpu_enabled = true

  # Security configuration
  vpc_security_group_ids = [
    module.ml_security_group.security_group_id
  ]

  # IAM role with S3 and ECR access
  iam_instance_profile = module.ml_iam_role.instance_profile_name

  # Large root volume for ML frameworks
  root_volume = {
    volume_size = 100
    volume_type = "gp3"
    iops        = 4000
    throughput  = 250
    encrypted   = true
  }

  # High-performance storage for datasets
  ebs_volumes = [
    {
      device_name = "/dev/xvdf"
      volume_size = 1000
      volume_type = "gp3"
      iops        = 4000
      throughput  = 1000
      encrypted   = true
      tags = {
        Name = "ml-dataset-storage"
        Purpose = "training-data"
      }
    }
  ]

  # ML environment setup
  user_data = <<-EOF
    #!/bin/bash
    # Install NVIDIA Docker
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
    curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

    apt-get update
    apt-get install -y nvidia-docker2
    systemctl restart docker

    # Mount data volume
    mkfs -t xfs /dev/xvdf
    mkdir -p /data
    mount /dev/xvdf /data
    echo '/dev/xvdf /data xfs defaults,nofail 0 2' >> /etc/fstab
  EOF

  # Enhanced monitoring for GPU instances
  enable_detailed_monitoring = true

  tags = {
    Environment = "production"
    Service     = "ml-training"
    Team        = "data-science"
    GPU         = "enabled"
    CostCenter  = "research"
  }
}
```

### Auto Scaling Group Ready Instance

```hcl
module "asg_template_instance" {
  source = "github.com/your-org/terraform-modules//aws/ec2?ref=main"

  name          = "asg-web-template"
  ami_id        = "ami-0abcdef1234567890"
  instance_type = "t3.medium"
  subnet_id     = module.vpc.private_subnet_ids[0]

  # Don't create the instance directly (used for launch template)
  create_instance = false

  # Security groups for ASG instances
  vpc_security_group_ids = [
    module.web_asg_security_group.security_group_id
  ]

  # IAM role with SSM access
  iam_instance_profile = module.web_iam_role.instance_profile_name

  # Optimized root volume
  root_volume = {
    volume_size = 20
    volume_type = "gp3"
    iops        = 3000
    throughput  = 125
    encrypted   = true
  }

  # Application initialization
  user_data = base64encode(templatefile("${path.module}/templates/web-app-init.sh", {
    app_version = var.app_version
    environment = var.environment
  }))

  # T3 unlimited for burstable performance
  cpu_credits = "unlimited"

  # Security hardening
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  tags = {
    Environment = "production"
    Service     = "web-app"
    ASG         = "enabled"
    Team        = "platform"
  }
}
```

### Development Instance with Hibernation

```hcl
module "development_instance" {
  source = "github.com/your-org/terraform-modules//aws/ec2?ref=main"

  name          = "dev-workstation"
  ami_id        = "ami-0abcdef1234567890"
  instance_type = "m5.large"
  subnet_id     = module.vpc.private_subnet_ids[0]

  # Security groups
  vpc_security_group_ids = [
    module.dev_security_group.security_group_id
  ]

  # SSH access
  key_name = "dev-team-key"

  # Enable hibernation for cost savings
  hibernation = true

  # Development storage
  root_volume = {
    volume_size = 50
    volume_type = "gp3"
    encrypted   = true
  }

  # Additional development tools volume
  ebs_volumes = [
    {
      device_name = "/dev/xvdf"
      volume_size = 100
      volume_type = "gp3"
      encrypted   = true
      tags = {
        Name = "dev-tools-volume"
      }
    }
  ]

  # Development environment setup
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum groupinstall -y "Development Tools"
    yum install -y git docker

    # Start Docker
    systemctl start docker
    systemctl enable docker
    usermod -a -G docker ec2-user

    # Mount development volume
    mkfs -t xfs /dev/xvdf
    mkdir -p /opt/dev
    mount /dev/xvdf /opt/dev
    echo '/dev/xvdf /opt/dev xfs defaults,nofail 0 2' >> /etc/fstab
  EOF

  # Relaxed metadata options for development
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "optional"  # Allow IMDSv1 for development
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  tags = {
    Environment = "development"
    Service     = "development"
    Team        = "engineering"
    AutoShutdown = "enabled"
    Hibernation = "enabled"
  }
}
```

### High-Performance Computing Instance

```hcl
module "hpc_instance" {
  source = "github.com/your-org/terraform-modules//aws/ec2?ref=main"

  name          = "hpc-compute-node"
  ami_id        = "ami-0abcdef1234567890"
  instance_type = "c6i.16xlarge"
  subnet_id     = module.vpc.private_subnet_ids[0]

  # Placement group for enhanced networking
  placement_group = aws_placement_group.hpc.name

  # Enhanced networking
  source_dest_check = false  # For HPC networking

  # Security groups
  vpc_security_group_ids = [
    module.hpc_security_group.security_group_id
  ]

  # IAM role for HPC workloads
  iam_instance_profile = module.hpc_iam_role.instance_profile_name

  # High-performance root volume
  root_volume = {
    volume_size = 100
    volume_type = "gp3"
    iops        = 4000
    throughput  = 250
    encrypted   = true
  }

  # NVMe local storage configuration
  ebs_volumes = [
    {
      device_name = "/dev/xvdf"
      volume_size = 2000
      volume_type = "gp3"
      iops        = 4000
      throughput  = 1000
      encrypted   = true
      tags = {
        Name = "hpc-scratch-storage"
        Purpose = "temporary-computation"
      }
    }
  ]

  # HPC environment setup
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y openmpi openmpi-devel

    # Configure huge pages
    echo 'vm.nr_hugepages = 1024' >> /etc/sysctl.conf
    sysctl -p

    # Mount scratch storage
    mkfs -t xfs /dev/xvdf
    mkdir -p /scratch
    mount /dev/xvdf /scratch
    echo '/dev/xvdf /scratch xfs defaults,nofail 0 2' >> /etc/fstab
    chmod 777 /scratch
  EOF

  # Enhanced monitoring for HPC
  enable_detailed_monitoring = true

  tags = {
    Environment = "production"
    Service     = "hpc"
    Team        = "research"
    Workload    = "compute-intensive"
  }
}

# Placement group for HPC instances
resource "aws_placement_group" "hpc" {
  name     = "hpc-cluster"
  strategy = "cluster"

  tags = {
    Name = "hpc-placement-group"
  }
}
```

### Dedicated Host Instance

```hcl
module "dedicated_host_instance" {
  source = "github.com/your-org/terraform-modules//aws/ec2?ref=main"

  name          = "dedicated-app-server"
  ami_id        = "ami-0abcdef1234567890"
  instance_type = "m5.large"
  subnet_id     = module.vpc.private_subnet_ids[0]

  # Dedicated tenancy
  tenancy = "host"
  host_id = aws_dedicated_host.app.id

  # Security groups
  vpc_security_group_ids = [
    module.app_security_group.security_group_id
  ]

  # IAM role
  iam_instance_profile = module.app_iam_role.instance_profile_name

  # CPU optimization
  cpu_core_count       = 2
  cpu_threads_per_core  = 1

  # Application initialization
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y nginx
    systemctl start nginx
    systemctl enable nginx
  EOF

  tags = {
    Environment = "production"
    Service     = "application"
    Team        = "platform"
    Tenancy     = "dedicated"
  }
}

# Dedicated host
resource "aws_dedicated_host" "app" {
  instance_type     = "m5.large"
  availability_zone = "us-west-2a"

  tags = {
    Name = "app-dedicated-host"
  }
}
```

### Nitro Enclaves Instance

```hcl
module "enclave_instance" {
  source = "github.com/your-org/terraform-modules//aws/ec2?ref=main"

  name          = "enclave-secure-server"
  ami_id        = "ami-0abcdef1234567890"  # Enclave-enabled AMI
  instance_type = "m5.large"
  subnet_id     = module.vpc.private_subnet_ids[0]

  # Enable Nitro Enclaves
  enclave_options = {
    enabled = true
  }

  # Security groups
  vpc_security_group_ids = [
    module.enclave_security_group.security_group_id
  ]

  # IAM role with enclave permissions
  iam_instance_profile = module.enclave_iam_role.instance_profile_name

  # Enclave initialization
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y aws-nitro-enclaves-cli

    # Configure enclave
    systemctl enable nitro-enclaves-allocator
    systemctl start nitro-enclaves-allocator
  EOF

  tags = {
    Environment = "production"
    Service     = "secure-processing"
    Team        = "security"
    Enclave     = "enabled"
  }
}
```

## Input Variables

### Required Variables

| Name        | Description                   | Type     | Example                   |
| ----------- | ----------------------------- | -------- | ------------------------- |
| `name`      | Name of the EC2 instance      | `string` | `"web-server"`            |
| `ami_id`    | AMI ID for the instance       | `string` | `"ami-0abcdef1234567890"` |
| `subnet_id` | Subnet ID for instance launch | `string` | `"subnet-12345678"`       |

### Optional Variables

| Name                          | Description                                         | Type           | Default      |
| ----------------------------- | --------------------------------------------------- | -------------- | ------------ |
| `instance_type`               | EC2 instance type                                   | `string`       | `"t3.micro"` |
| `vpc_security_group_ids`      | List of security group IDs                          | `list(string)` | `[]`         |
| `key_name`                    | Key pair name for SSH access                        | `string`       | `null`       |
| `iam_instance_profile`        | IAM instance profile name                           | `string`       | `null`       |
| `associate_public_ip_address` | Associate public IP address                         | `bool`         | `false`      |
| `availability_zone`           | AZ to launch the instance                           | `string`       | `null`       |
| `placement_group`             | Placement group name                                | `string`       | `null`       |
| `user_data`                   | User data script (plain text)                       | `string`       | `null`       |
| `user_data_base64`            | User data script (base64-encoded)                   | `string`       | `null`       |
| `hibernation`                 | Enable hibernation support                          | `bool`         | `false`      |
| `state`                       | Change instance state running/stopped               | `string`       | `false`      |
| `enable_detailed_monitoring`  | Enable detailed CloudWatch monitoring               | `bool`         | `false`      |
| `enable_primary_ipv6`         | Enable IPv6 address                                 | `bool`         | `false`      |
| `source_dest_check`           | Enable source/destination checking                  | `bool`         | `true`       |
| `encrypt_all_volumes`         | Encrypt all EBS volumes                             | `bool`         | `true`       |
| `encrypt_root_volume`         | Encrypt root volume (overrides encrypt_all_volumes) | `bool`         | `null`       |
| `kms_key_id`                  | KMS key ID for encryption                           | `string`       | `null`       |
| `cpu_credits`                 | CPU credits option (standard/unlimited)             | `string`       | `"standard"` |
| `gpu_enabled`                 | Enable GPU support and validation                   | `bool`         | `false`      |
| `tenancy`                     | Instance tenancy (default/dedicated/host)           | `string`       | `"default"`  |
| `host_id`                     | Dedicated host ID (when tenancy=host)               | `string`       | `null`       |
| `cpu_core_count`              | Number of CPU cores                                 | `number`       | `null`       |
| `cpu_threads_per_core`        | Number of CPU threads per core                      | `number`       | `null`       |
| `enclave_options`             | Nitro Enclaves configuration                        | `object`       | `{}`         |
| `create_instance`             | Whether to create the instance                      | `bool`         | `true`       |
| `tags`                        | Tags to apply to resources                          | `map(string)`  | `{}`         |

### Complex Object Variables

#### Root Volume Configuration

```hcl
root_volume = {
  volume_type = string           # "gp2", "gp3", "io1", "io2"
  volume_size = number           # Size in GB
  iops        = optional(number) # IOPS (for io1, io2, gp3)
  throughput  = optional(number) # Throughput in MB/s (for gp3)
  encrypted   = optional(bool)   # Encryption flag
  kms_key_id  = optional(string) # KMS key for encryption
  tags        = optional(map(string)) # Volume-specific tags
}
```

#### EBS Volumes Configuration

```hcl
ebs_volumes = [
  {
    device_name           = string           # "/dev/xvdf", "/dev/sdf", etc.
    volume_size           = number           # Size in GB
    volume_type           = string           # "gp2", "gp3", "io1", "io2"
    iops                  = optional(number) # IOPS (for io1, io2, gp3)
    throughput            = optional(number) # Throughput in MB/s (for gp3)
    encrypted             = optional(bool)   # Encryption flag
    kms_key_id            = optional(string) # KMS key for encryption
    delete_on_termination = optional(bool)   # Delete on instance termination
    tags                  = optional(map(string)) # Volume-specific tags
  }
]
```

#### Metadata Options Configuration

```hcl
metadata_options = {
  http_endpoint               = optional(string, "enabled")  # "enabled" or "disabled"
  http_tokens                 = optional(string, "optional") # "required" or "optional"
  http_put_response_hop_limit = optional(number, 1)          # 1-64
  instance_metadata_tags      = optional(string, "disabled") # "enabled" or "disabled"
}
```

#### Network Interfaces Configuration

```hcl
network_interfaces = [
  {
    device_index          = number         # 0, 1, 2, etc.
    network_interface_id  = string         # ENI ID
    delete_on_termination = optional(bool) # Delete ENI on termination
  }
]
```

### EBS Volume Types and Performance

| Volume Type | Use Case                  | Max IOPS | Max Throughput | Cost     |
| ----------- | ------------------------- | -------- | -------------- | -------- |
| `gp2`       | General purpose (legacy)  | 16,000   | 250 MB/s       | Low      |
| `gp3`       | General purpose (current) | 16,000   | 1,000 MB/s     | Low      |
| `io1`       | High IOPS (legacy)        | 64,000   | 1,000 MB/s     | High     |
| `io2`       | High IOPS (current)       | 256,000  | 4,000 MB/s     | High     |
| `st1`       | Throughput optimized      | 500      | 500 MB/s       | Very Low |
| `sc1`       | Cold storage              | 250      | 250 MB/s       | Lowest   |

## Outputs

| Name                           | Description                                  | Type     |
| ------------------------------ | -------------------------------------------- | -------- |
| `id`                           | ID of the EC2 instance                       | `string` |
| `arn`                          | ARN of the EC2 instance                      | `string` |
| `instance_id`                  | ID of the EC2 instance (alias for id)        | `string` |
| `private_ip`                   | Private IP address of the instance           | `string` |
| `public_ip`                    | Public IP address of the instance            | `string` |
| `primary_network_interface_id` | ID of the primary network interface          | `string` |
| `security_groups`              | List of associated security groups           | `list`   |
| `has_gpu`                      | Whether the instance has GPU support         | `bool`   |
| `gpu_info`                     | GPU information for the instance             | `object` |
| `tags_all`                     | Map of all tags assigned to the instance     | `map`    |
| `instance`                     | Complete instance object with all attributes | `object` |

### Output Usage Examples

```hcl
# Use instance outputs in other resources
resource "aws_route53_record" "web_server" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "web.example.com"
  type    = "A"
  ttl     = 300
  records = [module.web_server.public_ip]
}

# Create security group rule based on instance
resource "aws_security_group_rule" "database_access" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = module.web_server.security_groups[0]
  security_group_id        = module.database_security_group.security_group_id
}

# Store instance information in Parameter Store
resource "aws_ssm_parameter" "instance_ip" {
  name  = "/app/database/private-ip"
  type  = "String"
  value = module.database_server.private_ip
}
```

## Best Practices

### 1. Security Hardening

```hcl
# Always use IMDSv2 for production
metadata_options = {
  http_tokens = "required"  # Force IMDSv2
  http_put_response_hop_limit = 1
}

# Enable encryption by default
encrypt_all_volumes = true
kms_key_id = module.kms_key.key_id

# Use least privilege IAM roles
iam_instance_profile = module.restricted_iam_role.instance_profile_name
```

### 2. Performance Optimization

```hcl
# Use gp3 for better price/performance
root_volume = {
  volume_type = "gp3"
  iops        = 3000
  throughput  = 125
}

# Enable detailed monitoring for production
enable_detailed_monitoring = true

# Use placement groups for HPC workloads
placement_group = aws_placement_group.cluster.name
```

### 3. Cost Optimization

```hcl
# Use T3 unlimited for variable workloads
cpu_credits = "unlimited"

# Enable hibernation for development instances
hibernation = true

# Right-size your instances based on workload
instance_type = "t3.medium"  # Start small, scale up as needed
```

### 4. Monitoring and Alerting

```hcl
# CloudWatch alarms for instance monitoring
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${module.web_server.id}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"

  dimensions = {
    InstanceId = module.web_server.id
  }
}
```

## GPU Instance Support

### Supported GPU Instance Types

- **G4dn**: NVIDIA T4 GPUs (machine learning inference)
- **G5**: NVIDIA A10G GPUs (machine learning training/inference)
- **P3**: NVIDIA V100 GPUs (high-performance computing)
- **P4**: NVIDIA A100 GPUs (machine learning training)
- **P5**: NVIDIA H100 GPUs (latest generation ML training)

### GPU Instance Example

```hcl
module "gpu_training" {
  source = "github.com/your-org/terraform-modules//aws/ec2?ref=main"

  name          = "gpu-ml-training"
  ami_id        = "ami-0123456789abcdef0"  # Deep Learning AMI
  instance_type = "g5.xlarge"              # 1x NVIDIA A10G

  # Enable GPU validation
  gpu_enabled = true

  # GPU-optimized storage
  root_volume = {
    volume_size = 100
    volume_type = "gp3"
    iops        = 4000
  }

  ebs_volumes = [
    {
      device_name = "/dev/xvdf"
      volume_size = 1000
      volume_type = "gp3"
      throughput  = 1000
    }
  ]
}
```

## Multi-NIC Support at Instance Initialization

This module allows you to create EC2 instances with multiple network interfaces (NICs) **at launch time**.  
You do **not** need to manually create `aws_network_interface` resources—just declare your desired NICs in the `network_interfaces` variable and the module will create and attach them automatically.

**Example:**

```hcl
network_interfaces = [
  {
    device_index    = 1
    subnet_id       = "subnet-bbbbbbb"
    security_groups = ["sg-bbbbbbb"]
    delete_on_termination = true
  },
  {
    device_index    = 2
    subnet_id       = "subnet-ccccccc"
    security_groups = ["sg-ccccccc"]
    private_ip      = "10.0.3.10"
    tags            = { Name = "multi-nic-instance-nic3" }
    delete_on_termination = true
  }
]
```

- The module will automatically create and attach all specified NICs.
- Each NIC must specify a subnet and at least one security group.
- Adding/removing NICs will cause the instance to be replaced (AWS limitation).

---

## Troubleshooting

### Common Issues

#### 1. Instance Won't Start

```bash
# Check instance status
aws ec2 describe-instance-status --instance-ids i-1234567890abcdef0

# Check system logs
aws ec2 get-console-output --instance-id i-1234567890abcdef0
```

#### 2. User Data Not Executing

```bash
# Check cloud-init logs on the instance
sudo tail -f /var/log/cloud-init-output.log
sudo journalctl -u cloud-init
```

#### 3. EBS Volume Not Mounting

```bash
# Check if volume is attached
lsblk

# Check volume file system
sudo file -s /dev/xvdf

# Manual mount
sudo mkdir /data
sudo mount /dev/xvdf /data
```

#### 4. IMDSv2 Connectivity Issues

```bash
# Test IMDSv2 access
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/
```

## Requirements

| Name      | Version   |
| --------- | --------- |
| terraform | ~> 1.3    |
| aws       | ~> 5.97.0 |

## License

This module is released under the MIT License.
