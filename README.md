[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) ![Version: 0.5.1](https://img.shields.io/badge/Version-0.5.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.0.12-jvm](https://img.shields.io/badge/AppVersion-0.0.12--jvm-informational?style=flat-square) 

# StreamX Helm Chart

This chart bootstraps StreamX on a Kubernetes cluster.

## Install StreamX reference Services Mesh

### Prerequisites

Before installing StreamX, ensure to perform the following operations.
- Create and connect to [Kubernetes](https://kubernetes.io/docs/setup/) cluster version `>=1.25.0`.
- Create a [Pulsar cluster](https://pulsar.apache.org/docs/en/kubernetes-helm/) in the Kubernetes cluster.
- Install [Helm v3](https://helm.sh/docs/intro/install/).
- Optionally, install [NginX Ingress controller](https://kubernetes.github.io/ingress-nginx/deploy/) to expose StreamX services.

### Prepare Apache Pulsar for StreamX installation
> NOTE: Run this command only during the first-time installation.

```bash
helm install reference streamx --repo https://streamx-dev.github.io/streamx-chart -n streamx \
  --set messaging.pulsar.initTenant.enabled=true \
  --set rest_ingestion.enabled=false \
  -f examples/reference/messaging.yaml \
  --create-namespace
```

This command will give you `kubectl` command to check status of initialization job. Run it and wait for the job to complete.

### Install reference StreamX Mesh with Helm chart

```bash
helm upgrade reference streamx --repo https://streamx-dev.github.io/streamx-chart -n streamx \
  -f examples/reference/messaging.yaml \
  -f examples/reference/ingestion.yaml \
  -f examples/reference/processing.yaml \
  -f examples/reference/delivery.yaml
```

## Verify installation
Check that all StreamX Services deployments are running:

```bash
kubectl -n streamx rollout status deployment -l app.kubernetes.io/instance=reference
```

The output should be similar to:
```bash
deployment "reference-streamx-delivery-reference-web" successfully rolled out
deployment "reference-streamx-processing-reference-relay" successfully rolled out
deployment "reference-streamx-rest-ingestion" successfully rolled out
```

## Uninstalling StreamX

1. Uninstall StreamX Mesh with Helm chart:
   ```bash
   helm uninstall reference -n streamx
   ```
2. Delete the namespace:
   ```bash
   kubectl delete namespace streamx
   ```

## Examples
Browse the available chart installations in the [examples](./examples) directory.
Each of the examples has its `install.sh` script to install StreamX Mesh from the local Chart. 
Read more about the local setup for development in the [CONTRIBUTING.md](./CONTRIBUTING.md) documentation.

## Parameters
Read the [parameters](./docs/parameters.md) documentation to see the chart's parameters.

## Advanced concepts
Learn more about advanced StreamX chart concepts like _Services Mesh_, _multi-tenancy_, _JWT authentication_, and more in the [concepts](./docs/concepts.md) documentation.

## Development and contributing
See the [CONTRIBUTING.md](./CONTRIBUTING.md) to understand how to set up a local development environment and contribute to the project.