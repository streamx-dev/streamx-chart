# E2e tests
Goal: run end-to-end tests against a "real" kubernetes cluster. We use [Test Containers](https://www.testcontainers.org/) to run a local kubernetes cluster - [kind](https://kind.sigs.k8s.io/). 

## Prerequisites
- [Docker](https://docs.docker.com/get-docker/)
- [gcloud](https://cloud.google.com/sdk/docs/install)
- no `kubectl` installed on your machine (provided as a container)
- no `helm` installed on your machine (provided as a container)
- no `kind` installed on your machine (wrapped with `KindContainer`)

## Running the tests
```bash
export STREAMX_GAR_TOKEN=$(gcloud auth print-access-token)
./mvnw clean test
```