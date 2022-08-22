AGENTS=1

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
        --agents $AGENTS \
        -p "80:80@loadbalancer" \
        -p "443:443@loadbalancer" \
        -v $(pwd)/.machine-id:/etc/machine-id
fi

# Deploy necessary kubernetes structure
kubectl apply -f ./manifest/namespaces.yaml
kubectl apply -f ./manifest/ingress.yaml
kubectl apply -f ./manifest/fluentbit-configmap.yaml

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Deploy kube-prometheus-stack and ELK Stack
helm upgrade --install --namespace monitoring prometheus-stack prometheus-community/kube-prometheus-stack --values ./values/prometheus-stack.yaml

# Prepare own applications
prepare_own_image dotnet-weather-service

# Deploy own applications
helm install weatherapi ../dotnet-weather-service/deploy