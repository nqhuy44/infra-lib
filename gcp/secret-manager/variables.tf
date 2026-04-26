variable "project_id" {
  description = "The ID of the project in which the resource belongs."
  type        = string
}

variable "secrets" {
  description = "A map of secret names to their initial placeholder values. The actual values will be ignored by Terraform lifecycle."
  type        = map(string)
}

variable "accessors" {
  description = "A list of IAM members (e.g., 'serviceAccount:my-sa@project.iam.gserviceaccount.com', 'user:foo@example.com') to grant roles/secretmanager.secretAccessor to all secrets."
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "A map of labels (tags) to apply to all secrets."
  type        = map(string)
  default     = {}
}
