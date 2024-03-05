# StreamX Helm chart parameters

## Default

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| delivery | object | `{}` | `Delivery Services` map, see the [Delivery Services](#delivery-services) section for reference |
| global.env | list | `[]` | global environment variables for all containers, can be overridden by component specific env |
| global.imagePullSecrets | list | `[]` | imagePullSecrets used to authenticate to registry containing StreamX and custom images |
| messaging | object | `{}` | used to configure messaging system like Apache Pulsar, see the [Messaging](#messaging) section for reference |
| monitoring.enabled | bool | `false` | enabling this flag will enable creating `monitoring.coreos.com` Custom Resources for all services |
| processing | object | `{}` | `Processing Services` map, see the [Processing Services](#processing-services) section for reference |
| rest_ingestion.allInboxesTopicPatter | string | `"inboxes/.*"` | all-inboxes topic pattern in format: `namespace/topic-regex` |
| rest_ingestion.enabled | bool | `true` | enables REST Ingestion Service |
| rest_ingestion.env | list | `[]` | additional environment variables |
| rest_ingestion.image | string | `nil` | image repository and tag, defaults to `europe-west1-docker.pkg.dev/streamx-releases/streamx-docker-releases/dev.streamx/rest-ingestion-service:{{ .Chart.AppVersion }}` |
| rest_ingestion.ingress | object | `{}` | ingress settings, set `host` to enable ingress |
| rest_ingestion.monitoring | object | `{}` | pod monitoring configuration |
| rest_ingestion.nodeSelector | object | `{}` | node labels for pod assignment |
| rest_ingestion.probes | object | `{}` | probes settings, see tests for reference |
| rest_ingestion.replicas | int | `1` | number of replicas |
| rest_ingestion.resources | object | `{}` | resources for the container |
| tenant | string | `nil` | overwrites tenant for this release installation, defaults to `.Release.Name` |

## Messaging

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| messaging.pulsar.initTenant.enabled | bool | `false` | enable Apache Pulsar tenant and namespaces initialisation for StreamX, this will create a Job that waits for Apache Pulsar to be ready |
| messaging.pulsar.initTenant.env | list | `[]` | optional: additional environment variables for tenant initialisation |
| messaging.pulsar.initTenant.image | string | `nil` | optional: custom image for tenant initialisation, by default `streamx-docker-releases/dev.streamx/pulsar-init` with the current chart's AppVersion will be used |
| messaging.pulsar.serviceUrl | string | `"pulsar://pulsar-service:6650"` | mandatory: Apache Pulsar Broker Service URL |
| messaging.pulsar.webServiceUrl | string | `"http://pulsar-web-service:8080"` | mandatory: Apache Pulsar REST API URL |

## Processing Services

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| processing.<service-name>.env | list | `[]` | additional environment variables for the service |
| processing.<service-name>.image | string | `"<image-repository>:<image-tag>"` | image repository and tag |
| processing.<service-name>.incoming | object | `{"<incoming-channel-name>":{"namespace":"inboxes","topic":"pages"}}` | map of incoming channels |
| processing.<service-name>.incoming.<incoming-channel-name> | object | `{"namespace":"inboxes","topic":"pages"}` | example incomming channel with defined namespace and topic |
| processing.<service-name>.nodeSelector | object | `{}` | nodeSelector settings (key -> value) |
| processing.<service-name>.outgoing | object | `{"<outgoing-channel-name>":{"namespace":"outboxes","topic":"pages"}}` | map of outgoing channels |
| processing.<service-name>.outgoing.<outgoing-channel-name> | object | `{"namespace":"outboxes","topic":"pages"}` | example outgoing channel with defined namespace and topic |
| processing.<service-name>.podMonitor | object | `{"interval":"10s","path":"/q/metrics","scrapeTimeout":"10s"}` | overrides default podMonitor settings |
| processing.<service-name>.probes.disabled | bool | `true` | disables probes, by default enabled |
| processing.<service-name>.probes.livenessOverride | object | `{}` | overrides default livenessProbe settings see tests for reference |
| processing.<service-name>.probes.readinessOverride | object | `{}` | overrides default readinessProbe settings see tests for reference |
| processing.<service-name>.probes.startupOverride | object | `{}` | overrides default startupProbe settings see tests for reference |
| processing.<service-name>.replicas | int | `2` | number of replicas, defaults to 1 |
| processing.<service-name>.resources | object | `{"requests":{"cpu":"400m","memory":"256Mi"}}` | overrides resources settings (default `requests`: 256Mi memory, 400m cpu) |

## Delivery Services

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| delivery.<service-name>.affinity.podAntiAffinity.enabled | bool | `true` | enables pod anti-affinity, defaults to `true` |
| delivery.<service-name>.containers.<container-name>.configs | list | `[{"configMapName":"generated-site-nginx-config","mountPath":"/etc/nginx/conf.d"}]` | configMap mounted as volume under mountPath, used e.g. to mount nginx configuration |
| delivery.<service-name>.containers.<container-name>.data.metadataMountPath | string | `"/application/store/metadata"` | metadata volume mount path |
| delivery.<service-name>.containers.<container-name>.data.repositoryMountPath | string | `"/application/store/resources"` | repository volume mount path |
| delivery.<service-name>.containers.<container-name>.env | list | `[]` | additional environment variables |
| delivery.<service-name>.containers.<container-name>.image | string | `"<image-repository>:<image-tag>"` | image repository and tag |
| delivery.<service-name>.containers.<container-name>.monitoring.interval | string | `"10s"` | optional, defaults to `10s` |
| delivery.<service-name>.containers.<container-name>.monitoring.path | string | `"/q/metrics"` | path for the monitoring endpoint, must be set to enable monitoring for the container |
| delivery.<service-name>.containers.<container-name>.monitoring.port | int | `8080` | optional, defaults to `8080` |
| delivery.<service-name>.containers.<container-name>.monitoring.scrapeTimeout | string | `"10s"` | optional, defaults to `10s` |
| delivery.<service-name>.containers.<container-name>.ports | list | `[{"containerPort":8080,"name":"http"}]` | ports exposed by the container |
| delivery.<service-name>.containers.<container-name>.probes.disabled | bool | `true` | disables probes, by default enabled |
| delivery.<service-name>.containers.<container-name>.probes.livenessOverride | object | `{}` | overrides default livenessProbe settings see tests for reference |
| delivery.<service-name>.containers.<container-name>.probes.readinessOverride | object | `{}` | overrides default readinessProbe settings see tests for reference |
| delivery.<service-name>.containers.<container-name>.probes.startupOverride | object | `{}` | overrides default startupProbe settings see tests for reference |
| delivery.<service-name>.containers.<container-name>.resources | string | `nil` | overrides resources for the container |
| delivery.<service-name>.data.metadataSize | string | `"1Gi"` | defines size of the metadata volume |
| delivery.<service-name>.data.repositorySize | string | `"1Gi"` | defines size of the repository volume |
| delivery.<service-name>.incoming | object | `{"<incoming-channel-name>":{"namespace":"outboxes","topic":"pages"}}` | map of incoming channels |
| delivery.<service-name>.incoming.<incoming-channel-name> | object | `{"namespace":"outboxes","topic":"pages"}` | example incomming channel with defined namespace and topic |
| delivery.<service-name>.outputs | object | `{"<output-name>":{"ingress":{"annotations":{},"host":"my-domain.com","path":"/my-path","tls":{"secretName":"tls-secret"}},"service":{"containerRef":{"name":"<container-name>"},"port":80,"targetPort":"http"}}}` | map of delivery outputs |
| delivery.<service-name>.outputs.<output-name>.ingress.annotations | object | `{}` | additional annotations for ingress |
| delivery.<service-name>.outputs.<output-name>.ingress.host | string | `"my-domain.com"` | optional, set `host` to enable ingress |
| delivery.<service-name>.outputs.<output-name>.ingress.path | string | `"/my-path"` | optional, defaults to "/" |
| delivery.<service-name>.outputs.<output-name>.ingress.tls.secretName | string | `"tls-secret"` | optional, set to enable TLS, secret must be created in the same namespace |
| delivery.<service-name>.outputs.<output-name>.service.containerRef.name | string | `"<container-name>"` | corresponds to container name in `containers` section |
| delivery.<service-name>.outputs.<output-name>.service.port | int | `80` | port on which Kubernetes service is listening for traffic for this Delivery Service |
| delivery.<service-name>.outputs.<output-name>.service.targetPort | string | `"http"` | name of the port in the container |
| delivery.<service-name>.pdb.minAvailable | int | `1` | min availabiliyty setting for the Delivery Service PodDisruptionBudget which is set to number of replicas by default |
| delivery.<service-name>.replicas | int | `1` | number of replicas, defaults to 1 |