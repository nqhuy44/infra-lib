variable "project_id" {
  description = "The ID of the project in which the resource belongs."
  type        = string
}

variable "account_id" {
  description = "The account id that is used to generate the service account email address."
  type        = string
}

variable "display_name" {
  description = "The display name for the service account."
  type        = string
  default     = ""
}

variable "description" {
  description = "A text description of the service account."
  type        = string
  default     = ""
}

variable "project_roles" {
  description = "A list of roles to be added to the created service account (e.g. 'roles/viewer')."
  type        = list(string)
  default     = []
}

variable "sa_users" {
  description = "A list of IAM members (e.g., 'user:foo@example.com') who are allowed to impersonate/use this service account (roles/iam.serviceAccountUser)."
  type        = list(string)
  default     = []
}
