output "id" {
  description = "The ID of the repository ruleset."
  value       = { for k, v in github_repository_ruleset.this : k => v.id }
}