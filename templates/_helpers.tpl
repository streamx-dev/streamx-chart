{{/*
Expand the name of the chart.
*/}}
{{- define "streamx.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "streamx.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create a default fully qualified component name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
Usage:
{{ include "streamx.component.fullname" (dict "componentName" "component-name" "context" $) }}
*/}}
{{- define "streamx.component.fullname" -}}
{{- if .context.Values.fullnameOverride }}
{{- printf "%s-%s" .context.Values.fullnameOverride .componentName | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .context.Chart.Name .context.Values.nameOverride }}
{{- if contains $name .context.Release.Name }}
{{- printf "%s-%s" .context.Release.Name .componentName | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s-%s" .context.Release.Name $name .componentName | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "streamx.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Metadata labels for StreamX component
Usage:
{{ include "streamx.component.labels" (dict "componentName" "component-name" "context" $) }}
*/}}
{{- define "streamx.component.labels" -}}
helm.sh/chart: {{ include "streamx.chart" .context }}
{{ include "streamx.component.selectorLabels" (dict "componentName" .componentName "context" .context) }}
app.kubernetes.io/managed-by: {{ .context.Release.Service }}
{{- end }}

{{/*
Selector labels for StreamX component
Usage:
{{ include "streamx.component.selectorLabels" (dict "componentName" "component-name" "context" $) }}
*/}}
{{- define "streamx.component.selectorLabels" -}}
app.kubernetes.io/name: {{ include "streamx.name" .context }}
app.kubernetes.io/instance: {{ .context.Release.Name }}
app.kubernetes.io/component: {{ .componentName }}
{{- end }}

{{/*
Tenant name
Usage:
{{ include "streamx.tenant" . }}
*/}}
{{- define "streamx.tenant" -}}
{{- default .Release.Name .Values.pulsar.tenant }}
{{- end }}

{{/*
Pulsar topic
Usage:
{{ include "streamx.pulsarTopic" (dict "namespaceAndTopic" .Values.<component-name>.topic "context" $) }}
*/}}
{{- define "streamx.pulsarTopic" -}}
{{- printf "persistent://%s/%s" (include "streamx.tenant" .context) .namespaceAndTopic }}
{{- end }}

{{/*
Pulsar topic
Usage:
{{ include "streamx.channelTopic" (dict "channel" .channel "context" $) }}
*/}}
{{- define "streamx.channelTopic" -}}
{{- printf "persistent://%s/%s/%s" (include "streamx.tenant" .context) .channel.namespace .channel.topic }}
{{- end }}