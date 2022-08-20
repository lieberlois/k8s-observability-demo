function prepare_image {
    IMAGE=$1
    docker pull $IMAGE
    k3d image import $IMAGE
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
        --agents 2 \
        -p "80:80@loadbalancer" \
        -p "443:443@loadbalancer" \
        -v $(pwd)/.machine-id:/etc/machine-id
fi

# Deploy necessary kubernetes structure
kubectl apply -f ./manifest/namespaces.yaml
kubectl apply -f ./manifest/ingress.yaml
kubectl apply -f ./manifest/fluentbit-configmap.yaml

# Prepare images
prepare_image opensearchproject/opensearch:2.2.0
prepare_image opensearchproject/opensearch-dashboards:2.2.0
prepare_image cr.fluentbit.io/fluent/fluent-bit:1.9.7
prepare_image grafana/grafana:9.0.5
prepare_image quay.io/prometheus-operator/prometheus-config-reloader:v0.58.0
prepare_image quay.io/prometheus-operator/prometheus-operator:v0.58.0
prepare_image quay.io/prometheus/alertmanager:v0.24.0
prepare_image quay.io/prometheus/node-exporter:v1.3.1
prepare_image quay.io/prometheus/prometheus:v2.37.0
prepare_image registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.5.0

# Add helm repositories
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add fluent https://fluent.github.io/helm-charts
helm repo add opensearch https://opensearch-project.github.io/helm-charts/
helm repo update

# Deploy kube-prometheus-stack and ELK Stack
helm upgrade --install --namespace monitoring prometheus-stack prometheus-community/kube-prometheus-stack --values ./values/grafana.yaml --wait

helm upgrade --install --namespace logging fluent-bit fluent/fluent-bit --values ./values/fluentbit.yaml --wait
helm upgrade --install --namespace logging opensearch opensearch/opensearch
helm upgrade --install --namespace logging opensearch-dashboard opensearch/opensearch-dashboards --values ./values/opensearch-dashboard.yaml --wait
