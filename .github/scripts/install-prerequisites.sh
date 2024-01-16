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