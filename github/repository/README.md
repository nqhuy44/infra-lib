# GitHub Repository Terraform Module

This module creates and manages GitHub repositories with support for standard repository settings, default and additional branches, collaborators, teams, and more.

## Features

- Create and manage GitHub repositories
- Configure visibility (public, private, internal)
- Set default branch and create additional branches
- Manage repository collaborators and teams with permissions
- Enable/disable repository features (issues, projects, wiki, discussions, downloads)
- Set repository topics
- Initialize repository with README, .gitignore, and license templates

## Usage

### Basic Repository

```hcl
module "example_repo" {
  source      = "../../modules/github/repository"
  name        = "example-service"
  description = "Example microservice repository"
  visibility  = "private"
  auto_init   = true
  topics      = ["microservice", "api", "golang"]
}
```

### Repository with Custom Default Branch and Additional Branches

```hcl
module "custom_repo" {
  source          = "../../modules/github/repository"
  name            = "custom-service"
  default_branch  = "develop"
  additional_branches = ["feature/login", "feature/payment"]
  auto_init       = true
}
```

### Repository with Collaborators and Teams

```hcl
module "team_repo" {
  source = "../../modules/github/repository"
  name   = "team-service"

  collaborators = [
    { username = "alice", permission = "admin" },
    { username = "bob" } # permission defaults to "push"
  ]

  teams = [
    { team_slug = "dev-team", permission = "push" },
    { team_slug = "ops-team" } # permission defaults to "push"
  ]
}
```

## Input Variables

| Name                   | Description                                              | Type         | Default   | Required |
| ---------------------- | -------------------------------------------------------- | ------------ | --------- | -------- |
| name                   | The name of the repository                               | string       | n/a       | yes      |
| description            | A description of the repository                          | string       | ""        | no       |
| homepage_url           | URL of a page with more information about the repository | string       | ""        | no       |
| visibility             | Repository visibility: public, private, or internal      | string       | "private" | no       |
| has_issues             | Enable issues                                            | bool         | true      | no       |
| has_projects           | Enable projects                                          | bool         | true      | no       |
| has_wiki               | Enable wiki                                              | bool         | true      | no       |
| has_downloads          | Enable downloads                                         | bool         | true      | no       |
| has_discussions        | Enable discussions                                       | bool         | false     | no       |
| allow_merge_commit     | Allow merge commits                                      | bool         | true      | no       |
| allow_squash_merge     | Allow squash merges                                      | bool         | true      | no       |
| allow_rebase_merge     | Allow rebase merges                                      | bool         | true      | no       |
| allow_auto_merge       | Allow auto-merging pull requests                         | bool         | false     | no       |
| delete_branch_on_merge | Automatically delete head branch after merge             | bool         | true      | no       |
| is_template            | Make this repository a template                          | bool         | false     | no       |
| archived               | Archive this repository                                  | bool         | false     | no       |
| archive_on_destroy     | Archive instead of delete on destroy                     | bool         | false     | no       |
| vulnerability_alerts   | Enable vulnerability alerts                              | bool         | true      | no       |
| auto_init              | Produce an initial commit in the repository              | bool         | true      | no       |
| gitignore_template     | .gitignore template                                      | string       | ""        | no       |
| license_template       | License template                                         | string       | ""        | no       |
| topics                 | List of topics                                           | list(string) | []        | no       |
| default_branch         | Name of the default branch                               | string       | null      | no       |
| additional_branches    | List of additional branches to create                    | list(string) | []        | no       |
| teams                  | List of teams to grant access (team_slug, permission)    | list(object) | []        | no       |
| collaborators          | List of users to grant access (username, permission)     | list(object) | []        | no       |

## Outputs

| Name                      | Description                         |
| ------------------------- | ----------------------------------- |
| repository_id             | The ID of the repository            |
| repository_name           | The name of the repository          |
| repository_full_name      | The full name (org/repo)            |
| repository_html_url       | The HTML URL of the repository      |
| repository_ssh_clone_url  | The SSH clone URL                   |
| repository_http_clone_url | The HTTP clone URL                  |
| default_branch            | The default branch name             |
| branches_created          | List of additional branches created |

## Requirements

- Terraform >= 1.3
- GitHub Provider >= 6.9.0

## Notes

- Collaborators and teams are optional; omit if not needed.
- If `auto_init` is false, you must manually create an initial commit before creating branches.
- Default branch is "main" if not specified.
- Additional branches are created from the default branch.
- Permissions for teams and collaborators default to "push" if omitted.
