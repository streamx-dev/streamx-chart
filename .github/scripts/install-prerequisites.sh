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
