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

# Starts istio first for proxy injection purpose
echo
echo ">>> Deploying istiod"
kustomize build ../../../bases/istio | kubectl apply -f -
kustomize build ../istio | kubectl apply -f -

echo
echo ">>> Waiting for istiod to start for proxy injection purposes"
until kubectl -n istio-system get deploy istiod | grep "1/1"; do # INFO: CRD are created by istio operator
  sleep 10
done
echo ">>> Istio control plane is ready"

echo
echo ">>> Deploying fluxd"
kustomize build ../flux | kubectl apply -f -

echo
echo ">>> Waiting for fluxd to start"
kubectl -n flux-system rollout status deployment/flux
echo ">>> fluxs deployment is done"

sleep 40 # time to sync with github

echo
echo ">>> Waiting for fluxd to sync"
fluxctl sync --k8s-fwd-ns flux-system
echo ">>> fluxd sync is done"

# Gets the public SSH Keys to authorize flux to commit to github
# kubectl -n flux-system logs deployment/flux | grep identity.pub | cut -d '"' -f2 # Replaced by a personal key in order to keep a single ssh key in github
# fluxctl identity --k8s-fwd-ns flux

# Exposes the external IP directly to any program running on the host in order to set a LoadBalancer
# minikube tunnel

# kubectl -n staging port-forward deployment/java-demo-backend-service 8080:8080
# kubectl -n staging port-forward service/java-demo-database-service 3306:3306
