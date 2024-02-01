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
kubectl run pulsar --image=apachepulsar/pulsar:3.1.2 --command --namespace pulsar -- bin/pulsar standalone
kubectl expose pod pulsar --port=6650 --target-port=6650 --name=service --namespace pulsar
kubectl -n pulsar create service nodeport web-service --tcp=8080:8080 --node-port=30000 -o yaml --dry-run=client | kubectl set selector --local -f - 'run=pulsar' -o yaml | kubectl create -f -

# Wait for all pods to be ready
kubectl -n ingress-nginx rollout status deployment ingress-nginx-controller 
# kubectl -n monitoring rollout status deployment monitoring-kube-prometheus-operator 
kubectl -n pulsar wait  \
  --for=condition=ready pod \
  --selector=run=pulsar \
  --timeout=300s
