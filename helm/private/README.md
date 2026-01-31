## Changelog

# Service chart

Deploy new service or Cron job on Kubernetes

## Deploy deployment

## Validate helm template

Dry run.

```
helm template --dry-run --debug .
```

Generate chart templates locally.

```
helm template <version>.tgz --namespace <namespace> -f "values.yaml" > template-file.yaml
```

- Example:

```
cd private/
helm package .
helm template backend-0.1.1.tgz --namespace develop -f "values.yaml" > template-file.yaml

This command will gen template-file.yaml file at /private
```
