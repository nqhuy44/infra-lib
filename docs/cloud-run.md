# Feature: GCP Cloud Run

The Cloud Run module allows for serverless container deployments with automatic scaling and high availability.

## API Contract

The module abstracts the `google_cloud_run_v2_service` resource.

### Key Features

- **Scaling**: Configurable `min_instance_count` and `max_instance_count`.
- **Networking**: Support for VPC Connectors and ingress controls.
- **Security**: Optional unauthenticated access via IAM binding.
- **Resources**: Precise control over CPU and Memory limits.

## Usage Instructions

Refer to the [module README](../gcp/cloud-run/README.md) for detailed variable definitions and usage examples.

### Example: Internal Service

To deploy an internal service that is only accessible within the VPC:

```hcl
module "internal_app" {
  source           = "../../gcp/cloud-run"
  name             = "internal-api"
  ingress_settings = "INGRESS_TRAFFIC_INTERNAL_ONLY"
  # ...
}
```
