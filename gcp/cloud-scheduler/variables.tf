variable "project_id" {
  description = "The ID of the project in which the resource belongs."
  type        = string
}

variable "region" {
  description = "The region of the Cloud Scheduler."
  type        = string
}

variable "name" {
  description = "Name of the Cloud Scheduler job."
  type        = string
}

variable "description" {
  description = "Description of the Cloud Scheduler job."
  type        = string
  default     = ""
}

variable "schedule" {
  description = "The cron schedule expression (e.g., '0 2 * * *')."
  type        = string
}

variable "time_zone" {
  description = "The timezone for the schedule."
  type        = string
  default     = "Asia/Ho_Chi_Minh"
}

variable "target_job_name" {
  description = "The name of the Cloud Run Job to trigger."
  type        = string
}

variable "service_account_email" {
  description = "Service account email to use for authentication. If not provided, a new service account will be created automatically and granted roles/run.invoker."
  type        = string
  default     = null
}
