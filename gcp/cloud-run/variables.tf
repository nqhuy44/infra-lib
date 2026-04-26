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

variable "command" {
  description = "Entrypoint array. Leaves empty to use the default entrypoint in the container image."
  type        = list(string)
  default     = []
}

variable "args" {
  description = "Arguments to the entrypoint command."
  type        = list(string)
  default     = []
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

variable "secret_vars" {
  description = "A map of environment variables to set from Google Secret Manager. The key is the environment variable name, and the value is the secret ID. The 'latest' version of the secret will be used."
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

variable "cpu_idle" {
  description = "Determines whether CPU is allocated only during requests (true) or always allocated (false)."
  type        = bool
  default     = true
}

variable "startup_cpu_boost" {
  description = "Enable CPU boost on startup."
  type        = bool
  default     = false
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

variable "max_instance_request_concurrency" {
  description = "Sets the maximum number of requests that each serving instance can receive."
  type        = number
  default     = null
}

variable "request_timeout" {
  description = "Max duration the instance is allowed for responding to a request (e.g. '300s')."
  type        = string
  default     = null
}

variable "liveness_probe" {
  description = "Liveness probe configuration. Supports http_get or tcp_socket."
  type = object({
    http_get = optional(object({
      path = string
      port = optional(number)
    }))
    tcp_socket = optional(object({
      port = optional(number)
    }))
    initial_delay_seconds = optional(number)
    timeout_seconds       = optional(number)
    period_seconds        = optional(number)
    failure_threshold     = optional(number)
  })
  default = null
}

variable "startup_probe" {
  description = "Startup probe configuration. Supports http_get or tcp_socket."
  type = object({
    http_get = optional(object({
      path = string
      port = optional(number)
    }))
    tcp_socket = optional(object({
      port = optional(number)
    }))
    initial_delay_seconds = optional(number)
    timeout_seconds       = optional(number)
    period_seconds        = optional(number)
    failure_threshold     = optional(number)
  })
  default = null
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

variable "execution_environment" {
  description = "The execution environment for the Cloud Run service. Possible values are EXECUTION_ENVIRONMENT_GEN1, EXECUTION_ENVIRONMENT_GEN2."
  type        = string
  default     = null
}

variable "traffic_percent" {
  description = "Percent of traffic to allocate to the latest revision."
  type        = number
  default     = 100
}
