#!/bin/bash
set -e

DIR=$PWD
cd ..
# Starts flux operator
kubectl apply -k ./staging/minikube/flux/ && kubectl -n flux-system rollout status deployment/flux

# Gets the public SSH Keys to authorize flux to commit to github
kubectl -n flux-system logs deployment/flux | grep identity.pub | cut -d '"' -f2
# fluxctl identity --k8s-fwd-ns flux
# kubectl -n staging port-forward deployment/java-demo-backend-service 8080:8080
# kubectl -n staging port-forward service/java-demo-database-service 3306:3306
