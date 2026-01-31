# Terraform GitHub Ruleset Module

This module creates and manages advanced rulesets for branches, commits, and repository protections in GitHub repositories.  
It creates **one ruleset per repository** in the `repositories` list, each with the same configuration.

## Features

- Create GitHub rulesets for one or more repositories (one ruleset per repo)
- All rule parameters are optional and can be omitted
- Supports advanced ruleset options (branch, commit, PR, status checks, code scanning, etc.)
- Bypass actors support
- Flexible and dynamic configuration via input variables
- Can automatically add a pull request template file to each repository

## Usage

```hcl
module "ruleset" {
  source       = "../../modules/github/ruleset"
  name         = "main-branch-protection"
  repositories = [
    module.repo_a, # Pass the repository module object, not just the name
    module.repo_b
  ]
  target       = "branch"
  enforcement  = "active"
  include      = ["main"]
  exclude      = []

  creation         = true
  deletion         = true
  non_fast_forward = true

  branch_name_pattern = {
    operator = "starts_with"
    pattern  = "main"
    # name and negate are optional; name will be auto-generated if omitted
  }

  # Only one of branch_name_pattern or tag_name_pattern can be set per ruleset!
  # Do not set both at the same time.

  pull_request = {
    required_approving_review_count = 1
    require_code_owner_review       = true
  }

  # Any other rule block can be omitted if not needed
}
```

## Input Variables

| Name                          | Description                                               | Type         | Default  | Required |
| ----------------------------- | --------------------------------------------------------- | ------------ | -------- | -------- |
| name                          | The name of the ruleset                                   | string       | n/a      | yes      |
| repositories                  | List of repository module objects to apply the ruleset to | list(any)    | n/a      | yes      |
| target                        | The target type for the ruleset (e.g., "branch")          | string       | "branch" | no       |
| enforcement                   | Enforcement level: "active" or "evaluate"                 | string       | "active" | no       |
| bypass_actors                 | List of actors allowed to bypass rules                    | list(object) | []       | no       |
| include                       | Branch pattern(s) to include                              | list(string) | []       | no       |
| exclude                       | Branch pattern(s) to exclude                              | list(string) | []       | no       |
| creation                      | Enable creation rule                                      | bool         | null     | no       |
| deletion                      | Enable deletion rule                                      | bool         | null     | no       |
| non_fast_forward              | Enable non-fast-forward rule                              | bool         | null     | no       |
| update                        | Enable update rule                                        | bool         | null     | no       |
| update_allows_fetch_and_merge | Allow fetch and merge on update (requires `update`)       | bool         | null     | no       |
| branch_name_pattern           | Branch name pattern rule object                           | object       | null     | no       |
| tag_name_pattern              | Tag name pattern rule object                              | object       | null     | no       |
| ...other rules...             | See `variables.tf` for all supported rules                | object/bool  | null     | no       |

## Important Notes

- **Pass the repository module object** (not just the name) in the `repositories` variable. This allows access to outputs like `name` and `default_branch` and enables proper dependency handling.
- **Only one of `branch_name_pattern` or `tag_name_pattern` can be set per ruleset.** Setting both will cause a conflict and Terraform will fail.
- All rule parameters are optional. If you do not need a rule, omit it or set it to `null`.
- The pull request template file must exist at `templates/pull_request_template.md` in your module source directory.
- The module will automatically add the pull request template to the default branch of each repository.
- If you create repositories and rulesets at the same time, passing the module object ensures the ruleset waits for the repository to be created.

## Outputs

| Name | Description                          |
| ---- | ------------------------------------ |
| id   | Map of repository name to ruleset ID |

## Requirements

- Terraform >= 1.3
- GitHub Provider >= 6.9.0

## Example Repository Module Output

Make sure your repository module outputs at least:

```hcl
output "name" {
  value = github_repository.this.name
}
output "default_branch" {
  value = github_repository.this.default_branch
}
```
