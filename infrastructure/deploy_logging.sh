#!/bin/bash
set -e

docker pull opensearchproject/opensearch:2.2.0
docker pull opensearchproject/opensearch-dashboards:2.2.0
k3d image import opensearchproject/opensearch:2.2.0
k3d image import opensearchproject/opensearch-dashboards:2.2.0

helm repo add fluent https://fluent.github.io/helm-charts
helm repo add opensearch https://opensearch-project.github.io/helm-charts/
helm repo update

helm upgrade --install --namespace logging opensearch opensearch/opensearch --set replicas=1
helm upgrade --install --namespace logging fluent-bit fluent/fluent-bit --values ./values/fluentbit.yaml
helm upgrade --install --namespace logging opensearch-dashboard opensearch/opensearch-dashboards --values ./values/opensearch-dashboard.yaml 