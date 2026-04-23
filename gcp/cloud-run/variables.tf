variable "project_id" {
  description = "The ID of the project in which the resource belongs."
  type        = string
}

variable "name" {
  description = "Name of the Cloud Run service."
  type        = string
}

variable "location" {
  description = "The location of the Cloud Run service."
  type        = string
}

variable "image" {
  description = "The image to deploy to the Cloud Run service."
  type        = string
}

variable "container_port" {
  description = "The port on which the container listens."
  type        = number
  default     = 8080
}

variable "env_vars" {
  description = "A map of environment variables to set in the container."
  type        = map(string)
  default     = {}
}

variable "cpu_limit" {
  description = "The CPU limit for the container (e.g., '1000m')."
  type        = string
  default     = "1000m"
}

variable "memory_limit" {
  description = "The memory limit for the container (e.g., '512Mi')."
  type        = string
  default     = "512Mi"
}

variable "min_instance_count" {
  description = "The minimum number of instances to maintain."
  type        = number
  default     = 0
}

variable "max_instance_count" {
  description = "The maximum number of instances to maintain."
  type        = number
  default     = 10
}

variable "vpc_connector" {
  description = "The VPC connector to use for the Cloud Run service."
  type        = string
  default     = null
}

variable "egress_settings" {
  description = "The egress settings for the VPC connector. Possible values are ALL_TRAFFIC and PRIVATE_RANGES_ONLY."
  type        = string
  default     = "ALL_TRAFFIC"
}

variable "ingress_settings" {
  description = "The ingress settings for the Cloud Run service. Possible values are INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY, INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER."
  type        = string
  default     = "INGRESS_TRAFFIC_ALL"
}

variable "allow_unauthenticated_access" {
  description = "Whether to allow unauthenticated access to the Cloud Run service."
  type        = bool
  default     = false
}

variable "service_account_email" {
  description = "The email address of the service account to use for the Cloud Run service."
  type        = string
  default     = null
}

variable "labels" {
  description = "A map of labels to apply to the Cloud Run service."
  type        = map(string)
  default     = {}
}
