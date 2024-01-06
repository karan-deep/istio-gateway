#!/bin/bash

minikube version > /dev/null 2>&1 || {
echo "Please install minikube https://minikube.sigs.k8s.io/docs/start/" 
exit 
};

hyperkit -v > /dev/null 2>&1 || { 
echo "Please install hyperkit https://minikube.sigs.k8s.io/docs/drivers/hyperkit/"
exit 
};

helm version > /dev/null 2>&1 || { 
echo "Please install helm https://helm.sh/docs/intro/install/"
exit 
};

istioctl version > /dev/null 2>&1 || { 
echo "Please install istioctl https://istio.io/latest/docs/setup/install/istioctl/"
exit 
};

# making hyperkit the default driver for minikube
if [[ $(minikube config get driver) != 'hyperkit' ]]
	then
		minikube config set driver hyperkit
fi

# starting cluster
minikube start --cpus=4 --memory=8192

# installing istio and changing outbound traffic policy to block unless anything is registered to passthrough
istioctl install -y --set profile=demo --set meshConfig.outboundTrafficPolicy.mode=REGISTRY_ONLY

# wait 20 secs
echo "Waiting 20 secs...";
sleep 20;

# creating namespace asset at beginning, if injected after setting resources - have to restart pods for sidecar proxy
kubectl create namespace asset

# allowing injecting side car proxy to the pods and enabling them
kubectl label namespace asset istio-injection=enabled

# installing helm-chart and creating spearate namespace 
helm install -f local-values.yaml --create-namespace --namespace asset "$(sh create-release-name.sh)" .

# opens terminal and runs command - As istio ingress gateway is a type of Loadbalancer and we are using local env. So, cloud loadbalancer doesn't exist. Using minikube tunnel which uses metalb loadbalancer to connect to loadbalancer services
echo "Opening new terminal window, enter password and keep it open"
osascript -e 'tell app "Terminal"
    do script "minikube tunnel"
end tell'

# wait 30 secs
echo "Waiting 30 secs...";
sleep 30;

# mapping hostname to minikube's IP address
echo "$(kubectl get services istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}' -n istio-system) asset-management.com" | sudo tee -a /etc/hosts

echo "Visit http://asset-management.com for the application"