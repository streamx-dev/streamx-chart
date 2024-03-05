# Contributing

## Local setup for development
For local development, we will prepare a `kind` cluster with `extraPortMappings` and install reference StreamX Service Mesh from the chart.

Start with cloning the repository and navigating to the `streamx-chart` directory.

### Prerequisites
1. Install [`kind`](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) and configure [`kind` cluster with `extraPortMappings`](https://kind.sigs.k8s.io/docs/user/ingress/#create-cluster) and `kubectl` context to use it.
   ```bash
   kind create cluster --config .github/cluster/kind-cluster.yaml
   ```
2. Install StreamX Chart prerequisites with
   ```bash
   ./.github/scripts/install-prerequisites.sh
   ```
   It will install:
   - NginX Ingress controller configured for Kind,
   - Apache Pulsar,
   - `[optionally]` Prometheus Operator (disabled by default).

### Install examples StreamX Mesh from local Chart

To install the reference StreamX Mesh, run the `install.sh` script from the example directory of your choice, e.g.:

```bash
./examples/reference/install.sh
```

To run the reference instance.

### Validation

#### E2E tests

From the `tests/e2e` run:
```bash
./mvnw verify
```
to verify StreamX e2e tests for a reference installation. See the corresponding GitHub Actions workflows for the details on how to run particular scenarios.

> Note: you need JDK 17 to run the tests.

<details>
<summary>See how to validate reference flow manually with cURL</summary>
<p>

Refresh the Ingestion Service schema by calling:
```bash
curl -X 'GET' \
  'http://reference-api.127.0.0.1.nip.io/publications/v1/schema' \
  -H 'accept: */*'
```

It should return an array of available publication types.

Run the command below to publish a new page:

```bash
curl -X 'PUT' \
  'http://reference-api.127.0.0.1.nip.io/publications/v1/pages/test.html' \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d '{
  "content": {"bytes": "<h1>Hello StreamX!</h1>"}
}'
```

Open in the browser [reference.127.0.0.1.nip.io/test.html](http://reference.127.0.0.1.nip.io/test.html).
</p>
</details>

#### Unit tests

Run `helm unittest -f 'tests/unit/*.yaml' .` from `chart` to validate the chart structure and parameters.

### Releasing

1. Update the version in `chart/Chart.yaml`.
2. Generate README.md with `./generate-docs.sh`.
3. Commit and push changes.
4. Run [Release action](https://github.com/streamx-dev/streamx-chart/actions/workflows/release-publish-chart.yaml) to publish the chart to the GitHub Pages.

### Generating secrets for Rest Ingestion Auth

```bash
openssl genrsa -out rsaPrivateKey.pem 2048
openssl rsa -pubout -in rsaPrivateKey.pem -out key.pub
openssl pkcs8 -topk8 -nocrypt -inform pem -in rsaPrivateKey.pem -outform pem -out key.pem
kubectl create namespace tenant-1 || true
kubectl -n tenant-1 create secret generic streamx-api-keys --from-file=./key.pem --from-file=./key.pub
```
