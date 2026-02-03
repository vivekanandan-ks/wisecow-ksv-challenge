#!/bin/bash
set -e

echo "Installing Gateway API CRDs..."
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml

echo "Installing Caddy Gateway Controller..."
# Using the default Kustomize configuration from the official repo
kubectl apply -k github.com/caddyserver/gateway/config/default

echo "Installing cert-manager..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml
