# Infrastructure Architecture

This repository follows a modular architecture for managing Infrastructure as Code (IaC) using Terraform.

## Overview

The repository is organized by cloud provider and service type:

- `aws/`: Contains Terraform modules for Amazon Web Services.
- `gcp/`: Contains Terraform modules for Google Cloud Platform.
- `helm/`: Contains Helm charts for Kubernetes deployments.

## Design Principles

1. **Modularity**: Each service is encapsulated in its own module with clear inputs and outputs.
2. **Reusability**: Modules are designed to be used across different environments (dev, staging, prod).
3. **Consistency**: Naming conventions and provider constraints are standardized across modules.
4. **Security by Default**: Modules prioritize secure configurations (e.g., disabling public access by default).

## Component Interactions

Modules can be composed to build complex infrastructures. For example, a `vpc` module provides the network infrastructure for a `vm` or `cloud-run` service.
