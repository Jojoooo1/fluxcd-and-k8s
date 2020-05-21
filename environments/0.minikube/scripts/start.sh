#!/bin/bash
set -e

[[ ! -x "$(command -v kubectl)" ]] && echo "kubectl not found" && exit 1
[[ ! -x "$(command -v kustomize)" ]] && echo "kustomize not found" && exit 1
[[ ! -x "$(command -v fluxctl)" ]] && echo "fluxctl not found" && exit 1
[[ ! -x "$(command -v kubeseal)" ]] && echo "kubeseal not found" && exit 1
# Make sure before starting that all secret are sealed # kubeseal --format=yaml --cert="../sealed-secrets/cert.pem" <"../flux/secret.yaml" >"../flux/secret-sealed.yaml"
[[ ! -f "../sealed-secrets/master.key" ]] && echo "You need a sealed secret backup to start the project" && exit 1

echo
echo ">>> Deployind Sealed Secrets Operator"
kustomize build "../sealed-secrets" | kubectl apply -f -
[ -f "../sealed-secrets/master.key" ] && kubectl apply -f "../sealed-secrets/master.key"
echo
echo ">>> Waiting for sealed-secrets-controller to start"
until kubectl -n kube-system get deploy sealed-secrets-controller | grep "1/1"; do
  sleep 10
done
echo ">>> Saving locally private and public keys"
kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml >"../sealed-secrets/master.key" # fetch private key
kubeseal --fetch-cert >"../sealed-secrets/cert.pem"                                                                       # fetch public key

# Starts istio first for proxy injection purpose
echo
echo ">>> Deploying Istio Operator"
kubectl apply -f ../../../bases/istio/crds # creates CRDS first
kustomize build ../istio | kubectl apply -f -

echo
echo ">>> Waiting for istio to start (for proxy injection purposes)"
until kubectl -n istio-system get deploy istiod | grep "1/1"; do # INFO: CRD are created by istio operator
  sleep 10
done
echo ">>> Istio control plane is ready"

echo
echo ">>> Deploying Flux & Helm Operator"
kustomize build ../flux | kubectl apply -f -

echo
echo ">>> Waiting for flux to start"
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

#  kubectl -n staging port-forward deployment/java-demo-backend-service 8080:8080
#  kubectl -n staging port-forward service/java-demo-database-service 3306:3306
