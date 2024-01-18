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
| pulsar.tenant | string | `nil` | overwrites Apache Pulsar tenant for this release installation, defaults to `.Release.Name` |
| pulsar.webServiceUrl | string | `"http://pulsar-web-service:8080"` | Apache Pulsar REST API URL |

### Services Mesh

Services Mesh is a set of services that process and deliver the content to the end-user. The chart comes with an empty services mesh configuration, which means that no processing and delivery services will be deployed.

#### Processing services

Configuring processing services is done via `processing` object, check the syntax in `values.yaml`. The chart comes with an empty `processing` object, which means that no processing services will be deployed.

##### Inputs
Processing services process data from `inputs` and based on their logic, they can produce data to `outputs`. The following evniroment variables are available for each input:
- `PLUGIN_FUNCTIONS_<INPUT_INDEX>__INPUT` - a fully qualified Apache Pulsar URL (e.g. `persistent://my-tenant/my-namespace/my-topic`) of the topic to read from, where `<INPUT_INDEX>` is the index of the input in the `inputs` list e.g. `PLUGIN_FUNCTIONS_0__INPUT`, `PLUGIN_FUNCTIONS_1__INPUT`, etc.

##### Outputs
Processing services can produce data to `outputs`. The following evniroment variables are available for each output:
- `PLUGIN_FUNCTIONS_<OUTPUT_INDEX>__OUTPUT` - a fully qualified Apache Pulsar URL (e.g. `persistent://my-tenant/my-namespace/my-topic`) of the topic to write to, where `<OUTPUT_INDEX>` is the index of the output in the `outputs` list e.g. `PLUGIN_FUNCTIONS_0__OUTPUT`, `PLUGIN_FUNCTIONS_1__OUTPUT`, etc.

##### Environment variables
Every processing service container gets the following environment variables:
- `PULSAR_SERVICE_URL` - Apache Pulsar Broker Service URL
- `PULSAR_WEB_SERVICE_URL` - Apache Pulsar REST API URL

#### Delivery services

Delivery service is a `Deployment` that is responsible for delivering the content to the end-user. It reads data from `inputs` and exposes it via `outputs`. It can store its `data` in volumes that are mounted to the `Deployment` PODs. The data lifecycle is connected with the deployment pods' lifecycle (that means if the pod is deleted, the volume is deleted as well).

Delivery services are configured via `delivery` list of objects. See the [`values.yaml`](values.yaml) for more details.

##### Inputs
Delivery services synchronize data from `inputs` to their `data` volumes. The following evniroment variables are available for each input:
- `PULSAR_OUTBOX_TOPIC` - a fully qualified Apache Pulsar URL (e.g. `persistent://my-tenant/my-namespace/my-topic`) of the topic to read from
- `PULSAR_OUTBOX_SUBSCRIPTION_NAME` - unique subscription name for the input topic

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

Run the command below to install the chart:

```bash
kubectl create namespace streamx
kubectl create configmap streamx-site-nginx-config -n streamx --from-file=examples/dummy/nginx/streamx.conf
helm upgrade --install streamx . -n streamx -f examples/dummy/processing.yaml -f examples/dummy/delivery.yaml
```

and check that all the dummy processing and delivery services pods are running:

```bash
kubectl get pods -n streamx -l app.kubernetes.io/instance=streamx
```

### Testing

#### Helm unit tests
Run `helm unittest -f 'tests/unit/*.yaml' .`