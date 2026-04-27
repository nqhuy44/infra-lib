variable "project_id" {
  description = "The ID of the project in which the resource belongs."
  type        = string
}

variable "name" {
  description = "Name of the Cloud Run Job."
  type        = string
}

variable "location" {
  description = "The location of the Cloud Run Job."
  type        = string
}

variable "image" {
  description = "The image to deploy to the Cloud Run Job."
  type        = string
}

variable "command" {
  description = "Entrypoint command. Leaves empty to use the default."
  type        = list(string)
  default     = []
}

variable "args" {
  description = "Arguments to the entrypoint command."
  type        = list(string)
  default     = []
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
  description = "The CPU limit for the container (e.g., '1000m' or '1')."
  type        = string
  default     = "1000m"
}

variable "memory_limit" {
  description = "The memory limit for the container (e.g., '512Mi')."
  type        = string
  default     = "512Mi"
}

variable "task_count" {
  description = "Number of tasks to run per execution."
  type        = number
  default     = 1
}

variable "parallelism" {
  description = "Max number of tasks to run in parallel."
  type        = number
  default     = 1
}

variable "max_retries" {
  description = "Number of retries per task, between 0 and 10."
  type        = number
  default     = 0
}

variable "timeout" {
  description = "Max duration a task is allowed to run (e.g. '600s')."
  type        = string
  default     = "600s"
}

variable "vpc_connector" {
  description = "The VPC connector to use for the Cloud Run Job."
  type        = string
  default     = null
}

variable "egress_settings" {
  description = "The egress settings for the VPC connector. Possible values are ALL_TRAFFIC and PRIVATE_RANGES_ONLY."
  type        = string
  default     = "ALL_TRAFFIC"
}

variable "service_account_email" {
  description = "The email address of the service account to use for the Cloud Run Job."
  type        = string
  default     = null
}

variable "labels" {
  description = "A map of labels to apply to the Cloud Run Job."
  type        = map(string)
  default     = {}
}

variable "execution_environment" {
  description = "The execution environment for the Cloud Run Job. Possible values are EXECUTION_ENVIRONMENT_GEN1, EXECUTION_ENVIRONMENT_GEN2."
  type        = string
  default     = "EXECUTION_ENVIRONMENT_GEN2"
}

variable "volumes" {
  description = "A list of volumes to make available to the containers."
  type = list(object({
    name = string
    empty_dir = optional(object({
      medium     = optional(string)
      size_limit = optional(string)
    }))
    secret = optional(object({
      secret       = string
      default_mode = optional(number)
      items = optional(list(object({
        path    = string
        version = optional(string)
        mode    = optional(number)
      })))
    }))
    cloud_sql_instance = optional(object({
      instances = optional(list(string))
    }))
    gcs = optional(object({
      bucket    = string
      read_only = optional(bool)
    }))
    nfs = optional(object({
      server    = string
      path      = string
      read_only = optional(bool)
    }))
  }))
  default = []
}

variable "volume_mounts" {
  description = "A list of volume mounts to mount in the container."
  type = list(object({
    name       = string
    mount_path = string
  }))
  default = []
}
