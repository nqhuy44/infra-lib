locals {
  actual_default_branch = var.default_branch != null ? var.default_branch : "main"
  create_default_branch = var.default_branch != null && var.default_branch != "main"
  additional_branches   = var.additional_branches != null ? var.additional_branches : []
}

resource "github_repository" "this" {
  name         = var.name
  description  = var.description
  homepage_url = var.homepage_url
  visibility   = var.visibility

  has_issues      = var.has_issues
  has_projects    = var.has_projects
  has_wiki        = var.has_wiki
  has_downloads   = var.has_downloads
  has_discussions = var.has_discussions

  allow_merge_commit = var.allow_merge_commit
  # if allow_merge_commit is true, then values can be set
  merge_commit_title   = var.merge_commit_title
  merge_commit_message = var.merge_commit_message

  allow_squash_merge = var.allow_squash_merge
  # if allow_squash_merge is true, then values can be set
  squash_merge_commit_title   = var.squash_merge_commit_title
  squash_merge_commit_message = var.squash_merge_commit_message

  allow_rebase_merge     = var.allow_rebase_merge
  allow_auto_merge       = var.allow_auto_merge
  delete_branch_on_merge = var.delete_branch_on_merge

  is_template          = var.is_template
  archived             = var.archived
  archive_on_destroy   = var.archive_on_destroy
  vulnerability_alerts = var.vulnerability_alerts

  auto_init          = var.auto_init
  gitignore_template = var.gitignore_template
  license_template   = var.license_template

  topics = var.topics

  lifecycle {
    ignore_changes = [
      auto_init,
      gitignore_template,
      license_template,
    ]
  }
}

# Create the custom default branch from empty (if needed)
resource "github_branch" "default_branch" {
  count = local.create_default_branch ? 1 : 0

  repository = github_repository.this.name
  branch     = var.default_branch

  depends_on = [github_repository.this]
}

# Create additional branches from the default branch (or main)
resource "github_branch" "additional" {
  count = length(local.additional_branches)

  repository    = github_repository.this.name
  branch        = local.additional_branches[count.index]
  source_branch = local.actual_default_branch

  depends_on = [
    github_repository.this,
    github_branch.default_branch
  ]
}

# Set the default branch properly
resource "github_branch_default" "default" {
  count = local.create_default_branch ? 1 : 0

  repository = github_repository.this.name
  branch     = var.default_branch

  depends_on = [
    github_repository.this,
    github_branch.default_branch,
    github_branch.additional
  ]
}

# Grant team access to the repository
resource "github_team_repository" "team_access" {
  for_each = { for t in var.teams : t.team_slug => t if length(var.teams) > 0 }

  team_id    = each.value.team_slug
  repository = github_repository.this.name
  permission = each.value.permission
}

# Grant user (collaborator) access to the repository
resource "github_repository_collaborator" "user_access" {
  for_each = { for u in var.collaborators : u.username => u if length(var.collaborators) > 0 }

  repository = github_repository.this.name
  username   = each.value.username
  permission = each.value.permission
}