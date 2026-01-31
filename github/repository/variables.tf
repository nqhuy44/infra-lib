variable "name" {
  description = "The name of the repository."
  type        = string
}

variable "description" {
  description = "A description of the repository."
  type        = string
  default     = ""
}

variable "homepage_url" {
  description = "URL of a page with more information about the repository."
  type        = string
  default     = ""
}

variable "visibility" {
  description = "Visibility of the repository. Must be one of 'public', 'private', or 'internal'."
  type        = string
  default     = "private"
}

variable "has_issues" {
  description = "Enable issues for this repository."
  type        = bool
  default     = true
}

variable "has_projects" {
  description = "Enable projects for this repository."
  type        = bool
  default     = true
}

variable "has_wiki" {
  description = "Enable wiki for this repository."
  type        = bool
  default     = true
}

variable "has_downloads" {
  description = "Enable downloads for this repository."
  type        = bool
  default     = true
}

variable "has_discussions" {
  description = "Enable discussions for this repository."
  type        = bool
  default     = false
}

variable "allow_merge_commit" {
  description = "Allow merge commits."
  type        = bool
  default     = true
}

variable "allow_squash_merge" {
  description = "Allow squash merges."
  type        = bool
  default     = true
}

variable "allow_rebase_merge" {
  description = "Allow rebase merges."
  type        = bool
  default     = true
}

variable "allow_auto_merge" {
  description = "Allow auto-merging pull requests."
  type        = bool
  default     = false
}

variable "delete_branch_on_merge" {
  description = "Automatically delete head branches after pull requests are merged."
  type        = bool
  default     = true
}

variable "is_template" {
  description = "Is this repository a template repository?"
  type        = bool
  default     = false
}

variable "archived" {
  description = "Archive this repository."
  type        = bool
  default     = false
}

variable "archive_on_destroy" {
  description = "Archive the repository instead of deleting on destroy."
  type        = bool
  default     = false
}

variable "vulnerability_alerts" {
  description = "Enable vulnerability alerts for this repository."
  type        = bool
  default     = true
}

variable "auto_init" {
  description = "Produce an initial commit in the repository."
  type        = bool
  default     = true
}

variable "gitignore_template" {
  description = "Choose an available .gitignore template."
  type        = string
  default     = ""
}

variable "license_template" {
  description = "Choose an available license template."
  type        = string
  default     = ""
}

variable "topics" {
  description = "List of topics for the repository."
  type        = list(string)
  default     = []
}

variable "default_branch" {
  description = "The name of the default branch. If not set, defaults to 'main'."
  type        = string
  default     = null
}

variable "additional_branches" {
  description = "List of additional branches to create from the default branch."
  type        = list(string)
  default     = []
}

variable "teams" {
  description = "List of teams to grant access. Each object: { team_slug = string, permission = optional(string) }"
  type = list(object({
    team_slug  = string
    permission = optional(string, "push")
  }))
  default = []
}

variable "collaborators" {
  description = "List of users to grant access. Each object: { username = string, permission = optional(string) }"
  type = list(object({
    username   = string
    permission = optional(string, "push")
  }))
  default = []
}

variable "merge_commit_title" {
  description = "The default title for merge commits. Can be one of 'PR_TITLE', 'MERGE_MESSAGE', or 'BLANK'."
  type        = string
  default     = "PR_TITLE"
}

variable "merge_commit_message" {
  description = "The default message for merge commits. Can be one of 'PR_BODY', 'MERGE_MESSAGE', or 'BLANK'."
  type        = string
  default     = "BLANK"
}

variable "squash_merge_commit_title" {
  description = "The default title for squash merge commits. Can be one of 'PR_TITLE', 'MERGE_MESSAGE', or 'BLANK'."
  type        = string
  default     = "PR_TITLE"
}

variable "squash_merge_commit_message" {
  description = "The default message for squash merge commits. Can be one of 'PR_BODY', 'MERGE_MESSAGE', or 'BLANK'."
  type        = string
  default     = "BLANK"
}