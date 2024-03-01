# Copyright 2024 Dynamic Solutions Sp. z o.o. sp.k.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
Common Quasar Reactive Messaging environment variables
Usage:
{{ include "streamx.component.quasarEnvs" (dict "componentName" "component-name" "context" $) }}
*/}}
{{- define "streamx.component.quasarEnvs" -}}
- name: QUASAR_APPLICATION_INSTANCE-ID
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
{{- end }}

{{/*
Tenant name
Usage:
{{ include "streamx.tenant" . }}
*/}}
{{- define "streamx.tenant" -}}
{{- default .Release.Name .Values.tenant }}
{{- end }}

{{/*
Checks if namespace is one of: inboxes, outboxes, relays
Usage:
{{ include "streamx.services.checkNamespace" .namespace }}
*/}}
{{- define "streamx.services.checkNamespace" -}}
{{- $allowedNamespaces := list "inboxes" "outboxes" "relays"}}
{{- if not (has . $allowedNamespaces) }}
{{- fail (printf "Invalid namespace: '%s'. Topic namespace must be one of: 'inboxes', 'outboxes', 'relays'" .) }}
{{- end }}
{{- end }}

{{/*
Pulsar topic
Usage:
{{ include "streamx.pulsarTopic" (dict "namespaceAndTopic" .Values.<component-name>.topic "context" $) }}
*/}}
{{- define "streamx.pulsarTopic" -}}
{{- $channelParts := split "/" .namespaceAndTopic }}
{{- $channel := dict "namespace" $channelParts._0 "topic" $channelParts._1 }}
{{- include "streamx.services.checkNamespace" $channelParts._0 }}
{{- printf "persistent://%s/%s/%s" (include "streamx.tenant" .context) $channelParts._0 $channelParts._1 }}
{{- end }}

{{/*
Channel topic
Usage:
{{ include "streamx.channelTopic" (dict "channel" .channel "context" $) }}
*/}}
{{- define "streamx.channelTopic" -}}
{{ include "streamx.services.checkNamespace" .channel.namespace }}
{{- printf "persistent://%s/%s/%s" (include "streamx.tenant" .context) .channel.namespace .channel.topic }}
{{- end }}

{{/*
Common Pulsar environment variables
Usage:
{{ include "streamx.pulsarEnvs" . }}
*/}}
{{- define "streamx.pulsarEnvs" -}}
{{- with (.Values.messaging).pulsar -}}
- name: PULSAR_ADMIN_SERVICEURL
  value: {{ .webServiceUrl }}
- name: PULSAR_CLIENT_SERVICEURL
  value: {{ .serviceUrl }}
{{- end }}
{{- end }}

{{/*
Common Container Probes environment variables for Quarkus applications
Usage:
{{ include "streamx.quarkusProbesConfig" (dict "probes" <probes-object> "context" $) }}
*/}}
{{- define "streamx.quarkusProbesConfig" -}}
{{- $probes := .probes | default dict }}
{{- if not $probes.disabled }}
livenessProbe:
{{- if $probes.livenessOverride }}
{{- toYaml $probes.livenessOverride | nindent 2 }}
{{- else }}
  httpGet:
    path: /q/health/live
    port: 8080
    scheme: HTTP
{{- end }}
readinessProbe:
{{- if $probes.readinessOverride }}
{{ toYaml $probes.readinessOverride | nindent 2 }}
{{- else }}
  httpGet:
    path: /q/health/ready
    port: 8080
    scheme: HTTP
{{- end }}
startupProbe:
{{- if $probes.startupOverride }}
{{ toYaml $probes.startupOverride | nindent 2 }}
{{- else }}
  httpGet:
    path: /q/health/started
    port: 8080
    scheme: HTTP
{{- end }}
{{- end }}
{{- end }}

{{/*
Returns YAML list of environment variables. It merges two lists of envs (name->value) giving precedence from overwrite to base, 
effectively overwriting values in the base (distinguished by the 'name').
Usage:
{{ include "streamx.mergeEnvs" (dict "baseEnvs" <envs-list> "overwriteEnvs" <envs-list>) }}
*/}}
{{- define "streamx.mergeEnvs" -}}
{{- $overwriteEnvs := .overwriteEnvs | default list }}
{{- $baseEnvs := .baseEnvs | default list }}
{{- $overwriteDict := dict }}
{{- range $overwriteEnvs }}
{{- $_ := set $overwriteDict .name .value }}
{{- end }}
{{- $baseDict := dict }}
{{- range $baseEnvs }}
{{- $_ := set $baseDict .name .value }}
{{- end }}
{{- $merged := mergeOverwrite $baseDict $overwriteDict -}}
{{- range $key, $value := $merged }}
- name: {{ $key | quote}}
  value: {{ $value | quote }}
{{- end }}
{{- end }}