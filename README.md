# StreamX Helm Chart
![Version: 0.0.1](https://img.shields.io/badge/Version-0.0.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.0.1](https://img.shields.io/badge/AppVersion-0.0.1-informational?style=flat-square)

This chart bootstraps StreamX on a Kubernetes cluster.

## Names and labels convention

Since the chart consists of multiple components, the `metadata.name` contains the component's name, and `app.kubernetes.io/component` label was introduced for each component.
See the `templates/_helpers.tpl` helper functions to see the implementation details.

## Parameters

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| delivery | object | `{}` | `Delivery Services` map |
| imagePullSecrets | list | `[]` | imagePullSecrets used to authenticate to registry containing StreamX and custom services |
| processing | object | `{}` | `Processing Services` map |
| pulsar.serviceUrl | string | `"pulsar://pulsar-service:6650"` | Apache Pulsar Broker Service URL |
| pulsar.webServiceUrl | string | `"http://pulsar-web-service:8080"` | Apache Pulsar REST API URL |
| rest_ingestion.allInboxesTopicPatter | string | `"inboxes/.*"` | all-inboxes topic pattern in format: `namespace/topic-regex` |
| rest_ingestion.enabled | bool | `true` | enables REST Ingestion Service |
| rest_ingestion.env | list | `[]` | additional environment variables |
| rest_ingestion.image | string | `"europe-west1-docker.pkg.dev/streamx-releases/streamx-docker-snapshots/dev.streamx/rest-ingestion-service"` | image repository and tag |
| rest_ingestion.ingress | object | `{}` | ingress settings, set `host` to enable ingress |
| rest_ingestion.livenessProbe | object | `{}` | liveness probe settings |
| rest_ingestion.monitoring | object | `{}` | pod monitoring configuration |
| rest_ingestion.nodeSelector | object | `{}` | node labels for pod assignment |
| rest_ingestion.readinessProbe | object | `{}` | readiness probe settings |
| rest_ingestion.replicas | int | `1` | number of replicas |
| rest_ingestion.resources | object | `{}` | resources for the container |
| rest_ingestion.startupProbe | object | `{}` | startup probe settings |
| tenant | string | `"public"` | FixMe: **other tenant than `public` is not supported**; overwrites Apache Pulsar tenant for this release installation, defaults to `.Release.Name` |

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

### Development

Install required dependencies:

```bash
.github/scripts/install-prerequisites.sh
```

Clone `streamx-dev/streamx` repository and build it locally for Docker images
```bash
./mvnw clean package -Dquarkus.container-image.tag=latest
```

Run the command below to install the chart:

```bash
kubectl create namespace streamx
helm upgrade --install streamx . -n streamx \
  --set pulsar.serviceUrl="pulsar://service.pulsar:6650" \
  --set pulsar.webServiceUrl="http://web-service.pulsar:8080" \
  --set rest_ingestion.ingress.host="streamx-api.127.0.0.1.nip.io" \
  -f examples/reference/ingestion.yaml -f examples/reference/processing.yaml -f examples/reference/delivery.yaml
```

and check that all deployments are running:

```bash
kubectl get deployment -n streamx -l app.kubernetes.io/instance=streamx
```

Additionally, you may check that REST Ingestion Service is exposed by calling:

```bash
curl -X 'GET' \
  'http://streamx-api.127.0.0.1.nip.io/publications/v1/schema' \
  -H 'accept: */*'
```

It should return an array of available publication types.

Run the command below to publish a new publication:

```bash
curl -X 'PUT' \
  'http://streamx-api.127.0.0.1.nip.io/publications/v1/inbox-pages/test.html' \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d '{
  "content": {"bytes": "<h1>Hello StreamX!</h1>"}
}'
```

More coming soon...

### Testing

#### Helm unit tests
Run `helm unittest -f 'tests/unit/*.yaml' .`