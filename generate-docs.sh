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

#!/usr/bin/env bash

# workaround MacOS issue with sed
if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "MacOS detected"
  sed() {
    gsed "$@"
  }
fi

# Parameters
docker run --rm --volume "$(pwd)/chart:/helm-docs" -u $(id -u) jnorwood/helm-docs:latest -t=parameters.gotmpl -o parameters.md --values-file=values.yaml
docker run --rm --volume "$(pwd)/chart:/helm-docs" -u $(id -u) jnorwood/helm-docs:latest -t=parameters.gotmpl -o messaging.md --values-file=docs/messaging.yaml
docker run --rm --volume "$(pwd)/chart:/helm-docs" -u $(id -u) jnorwood/helm-docs:latest -t=parameters.gotmpl -o processing.md --values-file=docs/processing.yaml
docker run --rm --volume "$(pwd)/chart:/helm-docs" -u $(id -u) jnorwood/helm-docs:latest -t=parameters.gotmpl -o delivery.md --values-file=docs/delivery.yaml

echo "# StreamX Helm chart parameters\n" > docs/parameters.md
echo "## Default\n" >> docs/parameters.md
cat chart/parameters.md >> docs/parameters.md
echo "\n\n## Messaging\n" >> docs/parameters.md
cat chart/messaging.md >> docs/parameters.md
echo "\n\n## Processing Services\n" >> docs/parameters.md
cat chart/processing.md >> docs/parameters.md
echo "\n\n## Delivery Services\n" >> docs/parameters.md
cat chart/delivery.md >> docs/parameters.md
rm chart/parameters.md chart/messaging.md chart/processing.md chart/delivery.md

# Badges
docker run --rm --volume "$(pwd)/chart:/helm-docs" -u $(id -u) jnorwood/helm-docs:latest -t=badges.gotmpl -o badges.md
sed -i "1s/.*/$(cat chart/badges.md | sed 's/\//\\\//g')/" README.md
rm chart/badges.md
