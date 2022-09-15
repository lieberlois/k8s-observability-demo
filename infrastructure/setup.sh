#!/bin/bash
set -e

function prepare_own_image {
    IMAGE=$1
    docker build -t $IMAGE ../$IMAGE 1>/dev/null
    k3d image import $IMAGE 1>/dev/null
}

# Check for correct cwd
if ! [[ $(pwd) =~ (.*)/infrastructure ]]; then
    echo Error: Please run the script from within the infrastructure folder!
    exit 1
fi

# Create k3d cluster
if ! k3d cluster list | grep k3s-default > /dev/null; then 
    echo foobar > .machine-id
    k3d cluster create \
        -p "8080:80@loadbalancer" \
        -v $(pwd)/.machine-id:/etc/machine-id
fi

# Deploy necessary kubernetes structure
kubectl apply -f ./manifest/namespaces.yaml
kubectl apply -f ./manifest/ingress.yaml
kubectl apply -f ./manifest/fluentbit-configmap.yaml

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add jetstack https://charts.jetstack.io
helm repo add linkerd https://helm.linkerd.io/stable
helm repo add fluent https://fluent.github.io/helm-charts
helm repo add opensearch https://opensearch-project.github.io/helm-charts/
helm repo update

# Deploy kube-prometheus-stack and ELK Stack
helm upgrade --install prometheus-stack prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --values ./values/prometheus-stack.yaml \
    --wait

# Deploy Cert-Manager and Trust
helm upgrade --install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --version v1.9.1 \
    --set installCRDs=true \
    --wait

helm upgrade --install cert-manager-trust jetstack/cert-manager-trust \
    --namespace cert-manager \
    --wait


# Deploy linkerd
kubectl apply -f ./manifest/linkerd-certs.yaml

    # CRD
helm upgrade --install linkerd-crds linkerd/linkerd-crds --version 1.4.0 --namespace linkerd  --wait
    
    # Control Plane
helm upgrade --install linkerd-control-plane linkerd/linkerd-control-plane \
    --version 1.9.0 \
    --values values/linkerd.yaml \
    --namespace linkerd \
    --wait

    # Linkerd Viz
helm upgrade --install linkerd-viz linkerd/linkerd-viz \
    --version 30.3.0 \
    --values values/linkerd-viz.yaml \
    --namespace linkerd \
    --wait

# Deploy Logging Stack
helm upgrade --install --namespace logging fluent-bit fluent/fluent-bit --values ./values/fluentbit.yaml --wait
helm upgrade --install --namespace logging opensearch opensearch/opensearch --set replicas=1 --version 1.14.0 --wait 
helm upgrade --install --namespace logging opensearch-dashboard opensearch/opensearch-dashboards --version 1.8.1 --values ./values/opensearch-dashboard.yaml --wait

# Prepare own applications
prepare_own_image dotnet-weather-service

# Deploy own applications
helm upgrade --install weatherapi ../dotnet-weather-service/deploy --wait