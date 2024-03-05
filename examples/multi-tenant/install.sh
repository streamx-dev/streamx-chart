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

# 1. Create namespaces
kubectl create namespace tenant-1
kubectl create namespace tenant-2

# 2. Prepare Apache puslar for StreamX installation
helm install tenant-1 ./chart -n tenant-1 \
  --set messaging.pulsar.initTenant.enabled=true \
  --set rest_ingestion.enabled=false \
  -f examples/multi-tenant/tenant-1/messaging.yaml
helm install tenant-2 ./chart -n tenant-2 \
  --set messaging.pulsar.initTenant.enabled=true \
  --set rest_ingestion.enabled=false \
  -f examples/multi-tenant/tenant-2/messaging.yaml

# 3. Wait until the jobs complete
kubectl -n tenant-1 wait --for=condition=complete job --selector app.kubernetes.io/component=pulsar-init-tenant --timeout=300s
kubectl -n tenant-2 wait --for=condition=complete job --selector app.kubernetes.io/component=pulsar-init-tenant --timeout=300s

# 4. Install StreamX Mesh
helm upgrade tenant-1 ./chart -n tenant-1 \
  -f examples/multi-tenant/tenant-1/messaging.yaml \
  -f examples/multi-tenant/tenant-1/ingestion.yaml \
  -f examples/multi-tenant/tenant-1/processing.yaml \
  -f examples/multi-tenant/tenant-1/delivery.yaml
helm upgrade tenant-2 ./chart -n tenant-2 \
  -f examples/multi-tenant/tenant-2/messaging.yaml \
  -f examples/multi-tenant/tenant-2/ingestion.yaml \
  -f examples/multi-tenant/tenant-2/processing.yaml \
  -f examples/multi-tenant/tenant-2/delivery.yaml


# 5. Check that all deployments are running
kubectl -n tenant-1 rollout status deployment -l app.kubernetes.io/instance=tenant-1
kubectl -n tenant-2 rollout status deployment -l app.kubernetes.io/instance=tenant-2
