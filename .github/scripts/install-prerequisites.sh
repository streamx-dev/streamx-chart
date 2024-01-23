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

helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace

helm upgrade --install monitoring kube-prometheus-stack \
  --repo https://prometheus-community.github.io/helm-charts \
  --set prometheus.prometheusSpec.podMonitorSelector=null \
  --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
  --namespace monitoring --create-namespace

kubectl create namespace pulsar || true
kubectl run pulsar --image=apachepulsar/pulsar:3.1.2 --command --namespace pulsar -- bin/pulsar standalone
kubectl expose pod pulsar --port=6650 --target-port=6650 --name=service --namespace pulsar
kubectl expose pod pulsar --port=8080 --target-port=8080 --name=web-service --namespace pulsar
