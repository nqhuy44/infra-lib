# AWS EFS Module

This Terraform module creates and manages an AWS Elastic File System (EFS) with comprehensive configuration options including mount targets, access points, backup policies, file system policies, and replication.

---

## Features

- Full support for EFS file system configuration: encryption, performance mode, throughput mode, lifecycle policies.
- Optional mount targets across multiple subnets with security groups.
- Optional automatic backups.
- Optional access points for fine-grained access control.
- Optional file system policies for IAM-based access.
- Optional cross-region or same-region replication.
- Backward compatible and secure by default.

---

## Usage

```hcl
module "efs" {
  source = "../../modules/efs"

  name = "my-efs"

  # Basic configuration
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  # Mount targets
  subnet_ids         = ["subnet-12345", "subnet-67890"]
  security_group_ids = ["sg-12345"]

  # Enable backups
  backup_policy_enabled = true

  # Lifecycle policy
  transition_to_ia = "AFTER_30_DAYS"

  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

---

## Input Variables

| Name                                    | Description                                                                                                                                                     | Type         | Default          | Required |
| --------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------ | ---------------- | -------- |
| name                                    | Name for the EFS file system (used as creation token if creation_token is not set)                                                                              | string       | n/a              | yes      |
| creation_token                          | A unique name (token) for creating the EFS file system                                                                                                          | string       | null             | no       |
| encrypted                               | If true, the disk will be encrypted                                                                                                                             | bool         | true             | no       |
| kms_key_id                              | The ARN for the KMS encryption key                                                                                                                              | string       | null             | no       |
| performance_mode                        | The file system performance mode. Can be 'generalPurpose' or 'maxIO'                                                                                            | string       | "generalPurpose" | no       |
| throughput_mode                         | Throughput mode for the file system. Can be 'bursting', 'provisioned', or 'elastic'                                                                             | string       | "bursting"       | no       |
| provisioned_throughput_in_mibps         | The throughput, measured in MiB/s, that you want to provision for the file system. Only applicable with throughput_mode set to 'provisioned'                    | number       | null             | no       |
| tags                                    | A map of tags to assign to the resource                                                                                                                         | map(string)  | {}               | no       |
| subnet_ids                              | A list of subnet IDs for EFS mount targets                                                                                                                      | list(string) | n/a              | yes      |
| security_group_ids                      | A list of security group IDs to associate with the mount target                                                                                                 | list(string) | n/a              | yes      |
| backup_policy_enabled                   | Whether to enable EFS automatic backups                                                                                                                         | bool         | true             | no       |
| transition_to_ia                        | Indicates how long it takes to transition files to the IA storage class. Valid values: AFTER_7_DAYS, AFTER_14_DAYS, AFTER_30_DAYS, AFTER_60_DAYS, AFTER_90_DAYS | string       | null             | no       |
| transition_to_primary_storage_class     | Indicates how long it takes to transition files from IA to primary storage class. Valid values: AFTER_1_ACCESS                                                  | string       | null             | no       |
| create_access_point                     | Whether to create an EFS access point                                                                                                                           | bool         | false            | no       |
| access_point_posix_user_gid             | The POSIX group ID used for all file system operations using this access point                                                                                  | number       | 1000             | no       |
| access_point_posix_user_uid             | The POSIX user ID used for all file system operations using this access point                                                                                   | number       | 1000             | no       |
| access_point_posix_user_secondary_gids  | Secondary POSIX group IDs used for all file system operations using this access point                                                                           | list(number) | []               | no       |
| access_point_root_directory_path        | The path on the EFS file system to expose as the root directory to NFS clients using the access point                                                           | string       | "/"              | no       |
| access_point_root_directory_owner_gid   | The POSIX group ID to apply to the root directory                                                                                                               | number       | 1000             | no       |
| access_point_root_directory_owner_uid   | The POSIX user ID to apply to the root directory                                                                                                                | number       | 1000             | no       |
| access_point_root_directory_permissions | The POSIX permissions to apply to the root directory, in the format of an octal number                                                                          | string       | "755"            | no       |
| access_point_tags                       | A map of tags to assign to the access point                                                                                                                     | map(string)  | {}               | no       |
| attach_file_system_policy               | Whether to attach a file system policy to the EFS file system                                                                                                   | bool         | false            | no       |
| file_system_policy                      | The JSON policy document to attach to the EFS file system                                                                                                       | string       | null             | no       |
| enable_replica                          | Whether to enable EFS replication                                                                                                                               | bool         | false            | no       |
| replica_availability_zone_name          | The availability zone name for the replica                                                                                                                      | string       | null             | no       |
| replica_file_system_id                  | The ID of the destination file system for replication                                                                                                           | string       | null             | no       |
| replica_kms_key_id                      | The ARN of the KMS key to use for encrypting the replica                                                                                                        | string       | null             | no       |
| replica_region                          | The region for the replica                                                                                                                                      | string       | null             | no       |

---

## Outputs

| Name                         | Description                                              |
| ---------------------------- | -------------------------------------------------------- |
| efs_file_system_id           | The ID of the EFS file system                            |
| efs_file_system_arn          | The ARN of the EFS file system                           |
| mount_target_ids             | A list of EFS mount target IDs                           |
| access_point_id              | The ID of the EFS access point (if created)              |
| access_point_arn             | The ARN of the EFS access point (if created)             |
| replication_configuration_id | The ID of the EFS replication configuration (if created) |

---

## Examples

### Basic EFS with Mount Targets

```hcl
module "efs_basic" {
  source = "../../modules/efs"

  name = "basic-efs"

  subnet_ids         = ["subnet-12345", "subnet-67890"]
  security_group_ids = ["sg-12345"]

  tags = {
    Environment = "dev"
  }
}
```

### EFS with Access Point

```hcl
module "efs_with_access_point" {
  source = "../../modules/efs"

  name = "efs-with-ap"

  subnet_ids         = ["subnet-12345"]
  security_group_ids = ["sg-12345"]

  create_access_point = true
  access_point_posix_user_uid = 1001
  access_point_posix_user_gid = 1001
  access_point_root_directory_path = "/app"
  access_point_root_directory_permissions = "755"

  tags = {
    Environment = "production"
  }
}
```

### EFS with File System Policy

```hcl
module "efs_with_policy" {
  source = "../../modules/efs"

  name = "efs-with-policy"

  subnet_ids         = ["subnet-12345"]
  security_group_ids = ["sg-12345"]

  attach_file_system_policy = true
  file_system_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Principal = {
          AWS = "arn:aws:iam::123456789012:root"
        }
        Action   = "elasticfilesystem:ClientMount"
        Resource = "*"
      }
    ]
  })

  tags = {
    Environment = "production"
  }
}
```

### EFS with Replication

```hcl
module "efs_with_replica" {
  source = "../../modules/efs"

  name = "efs-with-replica"

  subnet_ids         = ["subnet-12345"]
  security_group_ids = ["sg-12345"]

  enable_replica = true
  replica_region = "us-west-2"
  replica_availability_zone_name = "us-west-2a"
  replica_kms_key_id = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"

  tags = {
    Environment = "production"
  }
}
```

### Full-Featured EFS

```hcl
module "efs_full" {
  source = "../../modules/efs"

  name = "full-efs"

  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "provisioned"
  provisioned_throughput_in_mibps = 100

  subnet_ids         = ["subnet-12345", "subnet-67890"]
  security_group_ids = ["sg-12345"]

  backup_policy_enabled = true
  transition_to_ia = "AFTER_30_DAYS"

  create_access_point = true
  access_point_posix_user_uid = 1000
  access_point_posix_user_gid = 1000

  attach_file_system_policy = true
  file_system_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Principal = "*"
        Action   = "elasticfilesystem:ClientMount"
        Resource = "*"
        Condition = {
          Bool = {
            "aws:SecureTransport" = "true"
          }
        }
      }
    ]
  })

  enable_replica = true
  replica_region = "us-east-1"
  replica_availability_zone_name = "us-east-1b"

  tags = {
    Environment = "production"
    Project     = "data-storage"
  }
}
```

---

## Notes

- Ensure that the subnets provided for mount targets are in different availability zones for high availability.
- For cross-region replication, the destination file system must already exist in the target region.
- Access points allow you to enforce user identity and root directory permissions for NFS clients.
- File system policies can restrict access based on IAM principals and conditions like requiring secure transport.

---

## Changelog

- **[v1.0.0]**: Initial release with support for EFS file system, mount targets, access points, policies, and replication.
