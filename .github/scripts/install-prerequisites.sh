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

#!/bin/bash

set -x -e

PULSAR_VERSION=${1:-"3.1.2"}

# Install Kind-dedicated NgInx Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Install Kube-Prometheus Stack
# helm upgrade --install monitoring kube-prometheus-stack \
#   --repo https://prometheus-community.github.io/helm-charts \
#   --set prometheus.prometheusSpec.podMonitorSelector=null \
#   --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
#   --namespace monitoring --create-namespace

# Install Apache Pulsar in Standalone Mode
kubectl create namespace pulsar || true
# FixMe - wait until default service account is created in pulsar namespace
for i in {1..5}; do
  kubectl -n pulsar wait --for=jsonpath='{.metadata}' serviceaccount/default --timeout=30s && break
  sleep 10
done

kubectl -n pulsar run pulsar --image=apachepulsar/pulsar:${PULSAR_VERSION} --command -- bin/pulsar standalone
kubectl -n pulsar expose pod pulsar --port=6650 --target-port=6650 --name=service
kubectl -n pulsar expose pod pulsar --port=8080 --target-port=8080 --name=web-service

# Wait for all pods to be ready
kubectl -n ingress-nginx rollout status deployment ingress-nginx-controller 
# kubectl -n monitoring rollout status deployment monitoring-kube-prometheus-operator 
kubectl -n pulsar wait  \
  --for=condition=ready pod \
  --selector=run=pulsar \
  --timeout=300s
