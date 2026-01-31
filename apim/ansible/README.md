# DevOps guide: validate and sync Kong configs with Ansible

This document explains how to validate and sync Kong declarative YAMLs, how variables are organized, how to run the playbooks for diff/sync, and a high‑level view of the Ansible role flow.

## Prerequisites (macOS)

- Homebrew
- Ansible, deck, Helm, AWS CLI
ansible
```bash
brew install ansible
```

deck
```bash
brew tap kong/deck && brew install deck
```

helm
```bash
brew install helm
```

awscli
```bash
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
```

- AWS credentials (if secrets are used)
  - export AWS_PROFILE=your-profile
  - or export AWS_ACCESS_KEY_ID=...; export AWS_SECRET_ACCESS_KEY=...; export AWS_REGION=...

Optional tools:
```bash
brew install yq jq
```

## Repository layout (relevant)
```
├─ ansible/
│  ├─ ansible.cfg
│  ├─ inventory/
│  │  └─ hosts.ini
│  ├─ group_vars/               # vars for multiple hosts
│  │  └─ nonprod.yml
│  ├─ host_vars/                # vars for specific hosts
│  │  └─ autosec_prod/
│  │     ├─ kong.yml
│  │     ├─ kong_chi.yml
│  ├─ playbook/
│  │  ├─ nonprod/               # playbook for nonprod
│  │  │  ├─ kong_diff.yaml
│  │  ├─ prod/                  # playbook for prod
│  │  │  ├─ kong_diff.yaml
│  ├─ roles/
│  │  ├─ kong/                  # ansible role
├─ kong-config                  # project YAMLs developers edit (input)
├─ kong-template                # Helm chart used to render files (internal detail)
```

## Variables and configuration

Set variables per environment/region under ansible/host_vars and group_vars. Example:

```yaml
# ansible/host_vars/autosec_prod/kong.yml
aws_account_id: "767397988224"
aws_region: "ap-southeast-1"
aws_secret_id: "common-infra/prod/secret/apim"

working_dir: "{{ playbook_dir | default('.') }}/../../../.."
temp_dir: "{{ working_dir }}/temp"
chart_dir: "{{ working_dir }}/kong-template"
kong_config_dir: "{{ working_dir }}/kong-config"

kong_admin_port: 8001
kong_hosts:
  - 127.0.0.1          # Ansible will probe and pick a reachable host

projects:
  - name: autosec
    enabled: true
    kong_files:
      - autosec/prod/controlplane/kong.yaml
```

Key vars:
- kong_hosts: list of candidate admin endpoints (IP/hostname). The role picks the first reachable.
- kong_admin_port: admin API port (deck will use http://<host>:<port>).
- projects[].enabled: only true entries are processed.
- projects[].kong_files: relative paths under kong-config.
- working_dir, chart_dir, kong_config_dir, temp_dir: paths used by the pipeline.
- aws_*: used when fetching secrets (if applicable).

To enable/disable files, edit projects in the corresponding host_vars or group_vars.

## High-level role flow

The main playbooks execute these role tasks in order:

1. validate_project.yml
   - Validates the projects variable structure.
   - Collect enabled projects
2. validate_file.yml
   - Builds the file list from enabled projects.
   - Verifies each file exists.
   - Copies selected kong-config files to a temp dir and collects the list.
3. validate_host.yml
   - Checks connectivity to kong_hosts and sets kong_host to the first reachable.
4. validate_aws.yml
   - Verifies AWS credentials/region when secrets are used.
5. process_secret.yml
   - Retrieves/loads secrets required for rendering or deck (e.g., tokens).
6. process_render.yml
   - Renders final config(s) from input YAMLs into the temp directory using Helm template in `kong-template`.
7. deck_validate.yml
   - Runs deck validate on the rendered files.
8. deck_diff.yml (diff playbooks)
   - Runs deck diff against the target Kong admin endpoint.
9. deck_sync.yml (sync playbooks)
   - Applies changes with deck sync.
10. cleanup.yml
   - Cleans up the temp directory.

Both diff and sync playbooks perform validation before diff/sync.

## Running the playbooks

Change directory to ansible:
```bash
cd ansible
```

### Nonprod:
- Diff (preview changes)
```bash
ansible-playbook playbook/nonprod/kong_diff.yaml
```
- Sync (apply changes)
```bash
ansible-playbook playbook/nonprod/kong_sync.yaml
```

### Prod
- Diff (preview changes)
```bash
ansible-playbook playbook/prod/kong_diff.yaml
```
- Sync (apply changes)
```bash
ansible-playbook playbook/prod/kong_sync.yaml
```

*** With project Autosec, need run additional playbooks at dataplanes ***
- Diff
```bash
ansible-playbook playbook/prod/autosec/kong_diff_sng.yaml

ansible-playbook playbook/prod/autosec/kong_diff_tyo.yaml

...
```
- Sync
```bash
ansible-playbook playbook/prod/autosec/kong_sync_sng.yaml

ansible-playbook playbook/prod/autosec/kong_sync_tyo.yaml

...
```

Tips:
- `kong_diff` playbooks will not clean rendered kong configs
- Validate and dry-run at local:
    - Run playbook `diff` to render configuration at `temp/rendered`
    - Validate rendered yaml files
    - Validate kong config by running
    ```bash
        cd temp/rendered
        deck gateway validate --kong-addr=< host >:<kong_admin_port> .
    ```
    - Check change before sync
    ```bash
        cd temp/rendered
        deck gateway diff --kong-addr=< host >:<kong_admin_port> .
    ```

## How to contribute

- Kong configs (functional change):
  - Update files under kong-config/< project >/< env >/**.yaml
  - Keep _format_version: "3.0"
  - Ensure booleans are unquoted (e.g., strip_path: false)
  - Prefer prefix paths; use regex (~) only when necessary and set regex_priority.
- Enable files for an environment/region:
  - Edit ansible/host_vars/< env_or_project >/*/kong.yml (or group_vars) and update projects:
    - Set enabled: true
    - Add/remove entries in kong_files
- Add a new project:
  - Place YAMLs under kong-config/< project >/< env >/(controlplane|dataplane)
  - Add a projects entry in the relevant host_vars/group_vars.
- Update playbook:
  - Edit kong_hosts and kong_admin_port in the relevant host_vars/group_vars.
  - Specific var files/vars using in playbook
- Secrets:
  - Credentials/tokens from AWS, set aws_account_id, aws_region, aws_secret_id and ensure your AWS auth works.

Open a PR with:
- YAML changes
- host_vars/group_vars updates
- Brief summary of intended diffs

## Troubleshooting

- No reachable Kong host:
  - Check kong_hosts and kong_admin_port
  - Ensure network access to the Admin API from your machine/runner (VPN, whitelists)
- deck not found:
  - brew tap kong/deck && brew install deck
- Validation fails on YAML:
  - yq