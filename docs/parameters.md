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
| processing._service-name_.env | list | `[]` | additional environment variables for the service |
| processing._service-name_.image | string | `"<image-repository>:<image-tag>"` | image repository and tag |
| processing._service-name_.incoming | object | `{"_incoming-channel-name_":{"namespace":"inboxes","topic":"pages"}}` | map of incoming channels |
| processing._service-name_.incoming._incoming-channel-name_ | object | `{"namespace":"inboxes","topic":"pages"}` | example incomming channel with defined namespace and topic |
| processing._service-name_.nodeSelector | object | `{}` | nodeSelector settings (key -> value) |
| processing._service-name_.outgoing | object | `{"_outgoing-channel-name_":{"namespace":"outboxes","topic":"pages"}}` | map of outgoing channels |
| processing._service-name_.outgoing._outgoing-channel-name_ | object | `{"namespace":"outboxes","topic":"pages"}` | example outgoing channel with defined namespace and topic |
| processing._service-name_.podMonitor | object | `{"interval":"10s","path":"/q/metrics","scrapeTimeout":"10s"}` | overrides default podMonitor settings |
| processing._service-name_.probes.disabled | bool | `true` | disables probes, by default enabled |
| processing._service-name_.probes.livenessOverride | object | `{}` | overrides default livenessProbe settings see tests for reference |
| processing._service-name_.probes.readinessOverride | object | `{}` | overrides default readinessProbe settings see tests for reference |
| processing._service-name_.probes.startupOverride | object | `{}` | overrides default startupProbe settings see tests for reference |
| processing._service-name_.replicas | int | `2` | number of replicas, defaults to 1 |
| processing._service-name_.resources | object | `{"requests":{"cpu":"400m","memory":"256Mi"}}` | overrides resources settings (default `requests`: 256Mi memory, 400m cpu) |

## Delivery Services

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| delivery._service-name_.affinity.podAntiAffinity.enabled | bool | `true` | enables pod anti-affinity, defaults to `true` |
| delivery._service-name_.containers._container-name_.configs | list | `[{"configMapName":"generated-site-nginx-config","mountPath":"/etc/nginx/conf.d"}]` | configMap mounted as volume under mountPath, used e.g. to mount nginx configuration |
| delivery._service-name_.containers._container-name_.data.repositoryMountPath | string | `"/application/store/resources"` | repository volume mount path, when defined an emptyDir volume is created on the deployment level and it will be mounted to the container under this path |
| delivery._service-name_.containers._container-name_.env | list | `[]` | additional environment variables |
| delivery._service-name_.containers._container-name_.image | string | `"<image-repository>:<image-tag>"` | image repository and tag |
| delivery._service-name_.containers._container-name_.monitoring.interval | string | `"10s"` | optional, defaults to `10s` |
| delivery._service-name_.containers._container-name_.monitoring.path | string | `"/q/metrics"` | path for the monitoring endpoint, must be set to enable monitoring for the container |
| delivery._service-name_.containers._container-name_.monitoring.port | int | `8080` | optional, defaults to `8080` |
| delivery._service-name_.containers._container-name_.monitoring.scrapeTimeout | string | `"10s"` | optional, defaults to `10s` |
| delivery._service-name_.containers._container-name_.ports | list | `[{"containerPort":8080,"name":"http"}]` | ports exposed by the container |
| delivery._service-name_.containers._container-name_.probes.disabled | bool | `true` | disables probes, by default enabled |
| delivery._service-name_.containers._container-name_.probes.livenessOverride | object | `{}` | overrides default livenessProbe settings see tests for reference |
| delivery._service-name_.containers._container-name_.probes.readinessOverride | object | `{}` | overrides default readinessProbe settings see tests for reference |
| delivery._service-name_.containers._container-name_.probes.startupOverride | object | `{}` | overrides default startupProbe settings see tests for reference |
| delivery._service-name_.containers._container-name_.resources | string | `nil` | overrides resources for the container |
| delivery._service-name_.data.metadataSize | string | `"1Gi"` | defines size of the metadata volume |
| delivery._service-name_.data.repositorySize | string | `"1Gi"` | defines size of the repository volume |
| delivery._service-name_.incoming | object | `{"_incoming-channel-name_":{"namespace":"outboxes","topic":"pages"}}` | map of incoming channels |
| delivery._service-name_.incoming._incoming-channel-name_ | object | `{"namespace":"outboxes","topic":"pages"}` | example incomming channel with defined namespace and topic |
| delivery._service-name_.outputs | object | `{"_output-name_":{"ingress":{"annotations":{},"host":"my-domain.com","path":"/my-path","tls":{"secretName":"tls-secret"}},"service":{"containerRef":{"name":"_container-name_"},"port":80,"targetPort":"http"}}}` | map of delivery outputs |
| delivery._service-name_.outputs._output-name_.ingress.annotations | object | `{}` | additional annotations for ingress |
| delivery._service-name_.outputs._output-name_.ingress.host | string | `"my-domain.com"` | optional, set `host` to enable ingress |
| delivery._service-name_.outputs._output-name_.ingress.path | string | `"/my-path"` | optional, defaults to "/" |
| delivery._service-name_.outputs._output-name_.ingress.tls.secretName | string | `"tls-secret"` | optional, set to enable TLS, secret must be created in the same namespace |
| delivery._service-name_.outputs._output-name_.service.containerRef.name | string | `"_container-name_"` | corresponds to container name in `containers` section |
| delivery._service-name_.outputs._output-name_.service.port | int | `80` | port on which Kubernetes service is listening for traffic for this Delivery Service |
| delivery._service-name_.outputs._output-name_.service.targetPort | string | `"http"` | name of the port in the container |
| delivery._service-name_.pdb.minAvailable | int | `1` | min availabiliyty setting for the Delivery Service PodDisruptionBudget which is set to number of replicas by default |
| delivery._service-name_.replicas | int | `1` | number of replicas, defaults to 1 |