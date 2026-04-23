# Tech Stack

This repository uses the following technologies and tools:

## Core Tools

| Tool | Version | Description |
|------|---------|-------------|
| [Terraform](https://www.terraform.io/) | ~> 1.11.0 | Infrastructure as Code orchestration |
| [Google Cloud Provider](https://registry.terraform.io/providers/hashicorp/google/latest) | ~> 7.17.0 | GCP resource management |
| [AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest) | ~> 5.0 | AWS resource management |
| [Helm](https://helm.sh/) | v3+ | Kubernetes package management |

## Reasoning

- **Terraform**: Chosen for its large provider ecosystem and state management capabilities.
- **Provider Pinning**: Versions are pinned to ensure stability and prevent breaking changes during automated deployments.
- **V2 APIs**: Where possible, modules use the latest versions of cloud APIs (e.g., Cloud Run v2) for better performance and feature support.
