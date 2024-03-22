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

# Prepares the template file by extracting the include sections from README.md
prepare_template() {
  awk '
      /<!-- start: .*/ {
          split($0, arr, " ")
          print "{include (" arr[3] ")}"
          f=1
          next
      }
      /<!-- end: .*-->/ {
          f=0
          next
      }
      f==0
  ' README.md > "$1"
}

# Replace include sections with file content
replace_includes() {
  partials_dir=$1
  template_file=$2
  while IFS= read -r line
  do
      if [[ $line == "{include ("*")}" ]]; then
          # Extract the file path
          filename=$(echo $line | sed -n -e 's/^.*(\(.*\)).*$/\1/p')
          # Include the file content
          filepath="$partials_dir/$filename"
          if [[ -f $filepath ]]; then
              echo "<!-- start: $filename -->"
              cat "$filepath"
              printf "\n<!-- end: $filename -->\n"
          else
              echo "File $filepath not found"
          fi
      else
          # Print the line as is
          echo "$line"
      fi
  done < "$template_file"
}

GEN_DOCS_DIR="gen-docs"
TEMP_DOCS_ROOT="chart/$GEN_DOCS_DIR"
mkdir -p $TEMP_DOCS_ROOT

# Parameters
docker run --rm --volume "$(pwd)/chart:/helm-docs" -u $(id -u) jnorwood/helm-docs:latest -t=parameters.gotmpl -o $GEN_DOCS_DIR/global.md --values-file=values.yaml
docker run --rm --volume "$(pwd)/chart:/helm-docs" -u $(id -u) jnorwood/helm-docs:latest -t=parameters.gotmpl -o $GEN_DOCS_DIR/messaging.md --values-file=docs/messaging.yaml
docker run --rm --volume "$(pwd)/chart:/helm-docs" -u $(id -u) jnorwood/helm-docs:latest -t=parameters.gotmpl -o $GEN_DOCS_DIR/processing.md --values-file=docs/processing.yaml
docker run --rm --volume "$(pwd)/chart:/helm-docs" -u $(id -u) jnorwood/helm-docs:latest -t=parameters.gotmpl -o $GEN_DOCS_DIR/delivery.md --values-file=docs/delivery.yaml

echo "### Default\n" > $TEMP_DOCS_ROOT/parameters.md
cat $TEMP_DOCS_ROOT/global.md >> $TEMP_DOCS_ROOT/parameters.md
echo "\n\n### Messaging\n" >> $TEMP_DOCS_ROOT/parameters.md
cat $TEMP_DOCS_ROOT/messaging.md >> $TEMP_DOCS_ROOT/parameters.md
echo "\n\n### Processing Services\n" >> $TEMP_DOCS_ROOT/parameters.md
cat $TEMP_DOCS_ROOT/processing.md >> $TEMP_DOCS_ROOT/parameters.md
echo "\n\n### Delivery Services\n" >> $TEMP_DOCS_ROOT/parameters.md
cat $TEMP_DOCS_ROOT/delivery.md >> $TEMP_DOCS_ROOT/parameters.md

# Badges
docker run --rm --volume "$(pwd)/chart:/helm-docs" -u $(id -u) jnorwood/helm-docs:latest -t=badges.gotmpl -o $GEN_DOCS_DIR/badges.md

# Create README.md from template
prepare_template "$TEMP_DOCS_ROOT/template.md"
replace_includes "$TEMP_DOCS_ROOT" "$TEMP_DOCS_ROOT/template.md" > README.md

# Cleanup
rm -rf $TEMP_DOCS_ROOT