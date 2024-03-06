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

# 1. Create namespace and create Rest Ingestion JWT keys secret
kubectl create namespace secured
kubectl apply -f examples/jwt-auth/secrets/rest-ingestion-jwt-keys.yaml

# 2. Prepare Apache Pulsar for StreamX installation
helm install secured ./chart -n secured \
  --set messaging.pulsar.initTenant.enabled=true \
  --set rest_ingestion.enabled=false \
  -f examples/jwt-auth/messaging.yaml

# 3. Wait until the job completes
kubectl -n secured wait --for=condition=complete job --selector app.kubernetes.io/component=pulsar-init-tenant --timeout=300s

# 4. Install reference StreamX Mesh with secured API
helm upgrade secured ./chart -n secured \
  -f examples/jwt-auth/messaging.yaml \
  -f examples/jwt-auth/ingestion.yaml \
  -f examples/jwt-auth/processing.yaml \
  -f examples/jwt-auth/delivery.yaml

# 5. Check that all deployments are running
kubectl -n secured rollout status deployment -l app.kubernetes.io/instance=secured
