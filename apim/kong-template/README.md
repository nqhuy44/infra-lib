# Kong template (Helm) – render Kong declarative configs

This chart renders Kong declarative configuration YAML from values files in this repo.

## Structure

- Chart.yaml – chart metadata
- values.yml – example/default values
- templates/kong.yaml – template that emits a Kong declarative config:
  - _format_version: "3.0"
  - upstreams (optional)
  - services (optional, with optional plugins)
  - routes (optional, with optional plugins)
  - plugins (optional, global)

## Input values schema (overview)

Supply your config via one or more values files. Top-level keys:

- upstreams: list of upstreams
  - name: string
  - targets: list of { target: "host:port", weight?: int }
- services: list of services
  - name: string
  - Either url: string, or protocol/host/port/path
  - tags?: [string...]
  - plugins?: list of { name: string, config?: object }
- routes: list of routes
  - name: string
  - service.name: string (must match a service name)
  - hosts?: [string...]
  - paths?: [string...] (prefix or regex if starts with ~)
  - methods?: [GET, POST, ...]
  - plugins?: list of { name: string, config?: object }
  - strip_path?: boolean (default false if not set)
  - regex_priority?: int
  - preserve_host?: boolean
  - tags?: [string...]

Note: Booleans must be real YAML booleans (true/false), not quoted strings.

## Example values (minimal)

```yaml
# values.example.yaml
upstreams:
  - name: users-upstream
    targets:
      - target: users-1.internal:8080
      - target: users-2.internal:8080

services:
  - name: users-svc
    protocol: http
    host: users-upstream
    port: 80
    plugins:
      - name: rate-limiting
        config:
          minute: 200
          policy: local

routes:
  - name: users-v1
    service:
      name: users-svc
    hosts: [dev-autosec-api.qualgo.dev]
    methods: [GET, POST]
    paths:
      - /api/v1/users
    strip_path: false
    tags: [autosec-dev, users]
```

## Render locally (macOS)

From repo root:

```bash
# Render a single values file
helm template kong-template ./kong-template \
  -f kong-config/autosec/nonprod/controlplane/kong.dev.yaml \
  > temp/rendered/autosec-dev.yaml

# Render multiple values files (later files override earlier ones)
helm template kong-template ./kong-template \
  -f kong-config/autosec/nonprod/controlplane/kong.dev.yaml \
  -f kong-template/values.yml \
  > temp/rendered/autosec-dev.yaml
```

Tips:
- Ensure the values file uses keys that this template expects (upstreams, services, routes, plugins).
- You can also test small overrides with --set/--set-string.

## Validate the rendered output

```bash
# YAML sanity
yq eval '.' temp/rendered/autosec-dev.yaml > /dev/null

# Validate with decK (Admin API must be reachable if diff)
deck gateway validate temp/rendered/autosec-dev.yaml
deck gateway diff --kong-addr http://<host>:<port> temp/rendered/autosec-dev.yaml
```

## Template logic highlights

- Only renders optional blocks if the corresponding values exist.
- Route plugins and service plugins support arbitrary config objects via toYaml | nindent 10.
- strip_path: rendered explicitly when provided; defaults to false when not set in routes.
- Regex paths: start with ~; when using overlapping regex paths, set regex_priority.
- preserve_host: emitted only when provided (true/false).

## Contributing

- Keep backward compatibility for existing values files in kong-config.
- Guard optional sections with if blocks to avoid emitting null/empty keys.
- Use toYaml | nindent for nested configs; keep indentation consistent with emitted YAML.
- If you add new supported fields:
  - Update templates/kong.yaml with conditional rendering.
  - Add an example to values.yml.
  - Test with helm template and deck validate.
- Do not quote booleans in templates; let YAML booleans render as true/false.

Coding conventions:
- Prefer explicit defaults in the template only where necessary (e.g., strip_path default false).
- Avoid emitting empty lists/objects.

## Testing changes

```bash
# Lint the chart
helm lint ./kong-template

# Render and inspect
helm template kong-template ./kong-template \
  -f kong-config/autosec/prod/controlplane/kong.yaml \
  > temp/rendered/autosec-prod.yaml

# Validate rendered manifest
yq eval '.' temp/rendered/autosec-prod.yaml > /dev/null
deck gateway validate temp/rendered/autosec-prod.yaml
```

Common pitfalls:
- Quoted booleans in values: "false" vs false (use unquoted booleans).
- Missing service referenced by a route (ensure service.name exists).
- Regex paths not escaped or missing anchors when needed.

## Compatibility

- Targets Kong declarative config _format_version: "3.0".
- Tested with Kong 3.x and decK 1.40+