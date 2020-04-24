#!/bin/bash
set -e

if [[ ! -x "$(command -v kubectl)" ]]; then
  echo "kubectl not found"
  exit 1
fi

if [[ ! -x "$(command -v kustomize)" ]]; then
  echo "kustomize not found"
  exit 1
fi

if [[ ! -x "$(command -v fluxctl)" ]]; then
  echo "fluxctl not found"
  exit 1
fi

# Starts flux operator (did not used kubectl because it uses Kustomize v2.0.3)
kustomize build ../flux | kubectl apply -f -

echo ">>> Waiting for flux to start"
kubectl -n flux-system rollout status deployment/flux
echo ">>> flux is ready"

echo ">>> Waiting for flux to sync"
fluxctl sync --k8s-fwd-ns flux-system
echo ">>> flux sync is done"

echo ">>> Waiting for istiod to start"
until kubectl -n istio-system get deploy istiod | grep "1/1"; do
  sleep 5
done
echo ">>> Istio control plane is ready"

# Gets the public SSH Keys to authorize flux to commit to github
# kubectl -n flux-system logs deployment/flux | grep identity.pub | cut -d '"' -f2 # Replaced by a personal key in order to keep a single ssh key in github
# fluxctl identity --k8s-fwd-ns flux

# Exposes the external IP directly to any program running on the host in order to set a LoadBalancer
# minikube tunnel

# kubectl -n staging port-forward deployment/java-demo-backend-service 8080:8080
# kubectl -n staging port-forward service/java-demo-database-service 3306:3306
