# StreamX Helm Chart
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) ![Version: 0.0.4](https://img.shields.io/badge/Version-0.0.4-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.0.2](https://img.shields.io/badge/AppVersion-0.0.2-informational?style=flat-square)

This chart bootstraps StreamX on a Kubernetes cluster.

## Names and labels convention

Since the chart consists of multiple components, the `metadata.name` contains the component's name, and `app.kubernetes.io/component` label was introduced for each component.
See the `templates/_helpers.tpl` helper functions to see the implementation details.

## Parameters

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| delivery | object | `{}` | `Delivery Services` map |
| imagePullSecrets | list | `[]` | imagePullSecrets used to authenticate to registry containing StreamX and custom services |
| messaging | object | `{}` | used to configure messaging system like Apache Pulsar, see examples for reference |
| monitoring.enabled | bool | `false` | enabling this flag will enable creating `monitoring.coreos.com` Custom Resources for all services |
| processing | object | `{}` | `Processing Services` map |
| rest_ingestion.allInboxesTopicPatter | string | `"inboxes/.*"` | all-inboxes topic pattern in format: `namespace/topic-regex` |
| rest_ingestion.enabled | bool | `true` | enables REST Ingestion Service |
| rest_ingestion.env | list | `[]` | additional environment variables |
| rest_ingestion.image | string | `nil` | image repository and tag, defaults to `europe-west1-docker.pkg.dev/streamx-releases/streamx-docker-releases/dev.streamx/rest-ingestion-service:{{ .Chart.AppVersion }}` |
| rest_ingestion.ingress | object | `{}` | ingress settings, set `host` to enable ingress |
| rest_ingestion.livenessProbe | object | `{}` | liveness probe settings |
| rest_ingestion.monitoring | object | `{}` | pod monitoring configuration |
| rest_ingestion.nodeSelector | object | `{}` | node labels for pod assignment |
| rest_ingestion.readinessProbe | object | `{}` | readiness probe settings |
| rest_ingestion.replicas | int | `1` | number of replicas |
| rest_ingestion.resources | object | `{}` | resources for the container |
| rest_ingestion.startupProbe | object | `{}` | startup probe settings |
| tenant | string | `nil` | overwrites tenant for this release installation, defaults to `.Release.Name` |

### Services Mesh

Services Mesh is a set of services that process and deliver the content to the end-user. The chart comes with an empty services mesh configuration, which means that no processing and delivery services will be deployed.

#### Processing services

Configuring processing services is done via `processing` object, check the syntax in `values.yaml`. The chart comes with an empty `processing` object, which means that no processing services will be deployed.

##### Incoming channels
Processing services process data from `incoming` channels and can produce data to `outgoing` channels. Channels are defined as a map of channel objects, where key is a channel name and value is a channel configuration. See the [`values.yaml`](values.yaml) for more details.
```yaml
incoming:
  incoming-pages:
    namespace: my-namespace
    topic: my-topic
```
The namespace and topic are used for Apache Pulsar topic URL construction. The fully qualified Apache Pulsar URL is constructed as follows: `persistent://<tenant>/<namespace>/<topic>`. The tenant is configured via `pulsar.tenant` value.

Apache Pulsar topic URL is available as an environment variable in the processing service container under the following name: `MP_MESSAGING_INCOMING_<CHANNEL>_TOPIC`.

For the example above and `tenant: my-tenant`, the environment variable will be:
```conf
MP_MESSAGING_INCOMING_INCOMING-PAGES_TOPIC=persistent://my-tenant/my-namespace/my-topic
```

##### Outgoing channels
Processing services can produce data to `outgoing` channels. The following evniroment variables are available for each channel:
- `MP_MESSAGING_OUTGOING_<CHANNEL>_TOPIC` - a fully qualified Apache Pulsar URL (e.g. `persistent://my-tenant/my-namespace/my-topic`) of the topic to write to, where `<CHANNEL>` is the channel name in upper case (e.g. `MP_MESSAGING_OUTGOING_INCOMING-PAGES_TOPIC`)

##### Environment variables
Every processing service container gets the following environment variables:
- `PULSAR_SERVICE_URL` - Apache Pulsar Broker Service URL
- `PULSAR_WEB_SERVICE_URL` - Apache Pulsar REST API URL

#### Delivery services

Delivery service is a `Deployment` that is responsible for delivering the content to the end-user. It reads data from `inputs` and exposes it via `outputs`. It can store its `data` in volumes that are mounted to the `Deployment` PODs. The data lifecycle is connected with the deployment pods' lifecycle (that means if the pod is deleted, the volume is deleted as well).

Delivery services are configured via `delivery` list of objects. See the [`values.yaml`](values.yaml) for more details.

##### Incoming
Delivery services, similarly to Processing services synchronize data from `incoming` channels to their `data` volumes. The following environment variables are available for each input:
- `MP_MESSAGING_INCOMING_<CHANNEL>_TOPIC` - a fully qualified Apache Pulsar URL (e.g. `persistent://my-tenant/my-namespace/my-topic`) of the topic to read from
- `MP_MESSAGING_INCOMING_<CHANNEL>_SUBSCRIPTIONNAME` - unique subscription name for the incoming topic

##### Outputs
The important concept of each delivery service is its `output` object. A single delivery service may define multiple `outputs`. See the sketch below:

![Delivery service outputs](./assets/delivery-service-outputs.jpg)

##### Data
Delivery service defines two `emptyDir` volumes by default:
- `repository`
- `metadata`

![Delivery service data](./assets/delivery-service-data.jpg)

Each delivery service container can mount these volumes to its filesystem under configured mount paths (see container's `data.repositoryMountPath` and `data.metadataMountPath`).

The size of the volumes can be configured via `data.repositorySize` and `data.metadataSize` values on the Delivery Service level.

##### Environment variables
Every delivery service container gets the following environment variables:
- `PULSAR_SERVICE_URL` - Apache Pulsar Broker Service URL
- `PULSAR_WEB_SERVICE_URL` - Apache Pulsar REST API URL

### Local development

#### Prerequisites

1. Install [`kind`](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) and configure [`kind` cluster with `extraPortMappings`](https://kind.sigs.k8s.io/docs/user/ingress/#create-cluster) and `kubectl` context to use it.
   ```bash
   kind create cluster --config .github/cluster/kind-cluster.yaml
   ```

2. Install [`helm`](https://helm.sh/docs/intro/install/).
3. Install StreamX Chart prerequisites with `./.github/scripts/install-prerequisites.sh`. It will install:
   - NginX Ingress controller configured for Kind,
   - Apache Pulsar,
   - `[optionally]` Prometheus Operator (disabled by default).

#### Installing StreamX from Chart

> Note: to run StreamX services locally, you need access to StreamX private repository.

1. Create `docker-registry` secret to enable Kubernetes to pull images from the StreamX private repository:
   ```bash
   TOKEN=$(gcloud auth print-access-token)
   kubectl create namespace streamx || true
   kubectl create secret docker-registry streamx-gar-json-key \
     --docker-server=europe-west1-docker.pkg.dev \
     --docker-username=oauth2accesstoken \
     --docker-password="${TOKEN}" \
     --namespace streamx
   ```
   <details>
   <summary>Show how to use locally built images</summary>
   <p>
   Alternatively, you can build images on your host and use `kind load` to load them into the cluster, e.g.:
 
   ```bash
   kind load docker-image europe-west1-docker.pkg.dev/streamx-releases/streamx-docker-snapshots/dev.streamx/reference-web-delivery-service:1.0-SNAPSHOT
   kind load docker-image europe-west1-docker.pkg.dev/streamx-releases/streamx-docker-snapshots/dev.streamx/reference-relay-processing-service:1.0-SNAPSHOT
   kind load docker-image europe-west1-docker.pkg.dev/streamx-releases/streamx-docker-snapshots/dev.streamx/rest-ingestion-service:1.0-SNAPSHOT
   kind load docker-image europe-west1-docker.pkg.dev/streamx-releases/streamx-docker-snapshots/dev.streamx/pulsar-init:1.0-SNAPSHOT
   ```
   </p>
   </details>
2. Prepare Apache Pulsar for StreamX installation (run it only for the first time installation):

   > NOTE: DO NOT CHANGE THIS COMMAND TO UPGRADE AS IT WILL CLEAR ALL RUNNING STEAMX PODS!

   ```bash
    helm install streamx ./chart -n streamx \
      --set "imagePullSecrets[0].name=streamx-gar-json-key" \
      --set messaging.pulsar.initTenant.enabled=true \
      --set rest_ingestion.enabled=false \
      -f examples/reference/messaging.yaml
    ```
    This command will give you `kubectl` command to check status of initialization job. Run it and wait for the job to complete.

   <details>
   <summary>Show how to initialise StreamX chart from public release</summary>
   <p>
   > You still need to download `examples/reference/*.yaml` files from the repository.

   ```bash
   helm install streamx streamx --repo https://streamx-dev.github.io/streamx-chart -n streamx \
     --set "imagePullSecrets[0].name=streamx-gar-json-key" \
     --set messaging.pulsar.initTenant.enabled=true \
     --set rest_ingestion.enabled=false \
     -f examples/reference/messaging.yaml
   ```
   </p>
   </details>

3. Install StreamX Mesh with Helm chart:
   ```bash
   helm upgrade streamx ./chart -n streamx \
     --set "imagePullSecrets[0].name=streamx-gar-json-key" \
     -f examples/reference/messaging.yaml \
     -f examples/reference/ingestion.yaml \
     -f examples/reference/processing.yaml \
     -f examples/reference/delivery.yaml
   ```

   <details>
   <summary>Show how to install StreamX chart from public release</summary>
   <p>
   > You still need to download `examples/reference/*.yaml` files from the repository.
 
   ```bash
   helm upgrade streamx streamx --repo https://streamx-dev.github.io/streamx-chart -n streamx \
     --set "imagePullSecrets[0].name=streamx-gar-json-key" \
     -f examples/reference/messaging.yaml \
     -f examples/reference/ingestion.yaml \
     -f examples/reference/processing.yaml \
     -f examples/reference/delivery.yaml
   ```
   </p>
   </details>

#### Validation
Check that all deployments are running:

```bash
kubectl -n streamx rollout status deployment -l app.kubernetes.io/instance=streamx
```

Next, from the `examples/reference/e2e` run:
```bash
./mvnw clean verify
```

> Note: you need JDK 17 to run the tests.

<details>
<summary>See how to validate reference flow manually with cURL</summary>
<p>

Refresh the Ingestion Service schema by calling:
```bash
curl -X 'GET' \
  'http://streamx-api.127.0.0.1.nip.io/publications/v1/schema' \
  -H 'accept: */*'
```

It should return an array of available publication types.

Run the command below to publish a new page:

```bash
curl -X 'PUT' \
  'http://streamx-api.127.0.0.1.nip.io/publications/v1/pages/test.html' \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d '{
  "content": {"bytes": "<h1>Hello StreamX!</h1>"}
}'
```

Open in the browser [streamx.127.0.0.1.nip.io/test.html](http://streamx.127.0.0.1.nip.io/test.html).

### Testing

#### Helm unit tests
Run `helm unittest -f 'tests/unit/*.yaml' .` from `chart`.

### Releasing
1. Update the version in `chart/Chart.yaml`.
2. Generate README.md with `./generate-docs.sh`.
3. Commit and push changes.
4. Run [Release action](https://github.com/streamx-dev/streamx-chart/actions/workflows/release-publish-chart.yaml) to publish the chart to the GitHub Pages.