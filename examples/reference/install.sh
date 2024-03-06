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

# 1. Create namespace
kubectl create namespace streamx

# 2. Prepare Apache Pulsar for StreamX installation (run it only for the first time installation)
helm install reference ./chart -n streamx \
  --set messaging.pulsar.initTenant.enabled=true \
  --set rest_ingestion.enabled=false \
  -f examples/reference/messaging.yaml

# 3. Wait until the job completes
kubectl -n streamx wait --for=condition=complete job --selector app.kubernetes.io/component=pulsar-init-tenant --timeout=300s

# 4. Install reference StreamX Mesh
helm upgrade reference ./chart -n streamx \
  -f examples/reference/messaging.yaml \
  -f examples/reference/ingestion.yaml \
  -f examples/reference/processing.yaml \
  -f examples/reference/delivery.yaml

# 5. Check that all deployments are running
kubectl -n streamx rollout status deployment -l app.kubernetes.io/instance=reference
