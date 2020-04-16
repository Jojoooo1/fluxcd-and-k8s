#!/bin/bash
set -e

DIR=$PWD
cd ..
# Starts flux operator
kubectl apply -k ./staging/flux/ && kubectl -n flux-system rollout status deployment/flux

# Gets the public SSH Keys to authorize flux to commit to github
kubectl -n flux-system logs deployment/flux | grep identity.pub | cut -d '"' -f2
# fluxctl identity --k8s-fwd-ns flux
