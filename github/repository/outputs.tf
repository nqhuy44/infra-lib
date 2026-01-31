output "id" {
  description = "The ID of the repository."
  value       = github_repository.this.id
}

output "name" {
  description = "The name of the repository."
  value       = github_repository.this.name
}

output "full_name" {
  description = "The full name of the repository."
  value       = github_repository.this.full_name
}

output "html_url" {
  description = "The HTML URL of the repository."
  value       = github_repository.this.html_url
}

output "ssh_clone_url" {
  description = "The SSH clone URL of the repository."
  value       = github_repository.this.ssh_clone_url
}

output "http_clone_url" {
  description = "The HTTP clone URL of the repository."
  value       = github_repository.this.http_clone_url
}

output "default_branch" {
  description = "The default branch name."
  value       = local.actual_default_branch
}

output "branches_created" {
  description = "List of additional branches created."
  value       = local.additional_branches
}