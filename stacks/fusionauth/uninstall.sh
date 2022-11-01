#!/bin/sh

set -e

################################################################################
# chart
################################################################################
STACK="fusionauth"
NAMESPACE="fusionauth"

helm repo remove stable
helm repo remove bitnami
helm repo remove fusionauth

helm uninstall -n "$NAMESPACE" my-es-release
helm uninstall -n "$NAMESPACE" my-postgres-release
helm uninstall "$STACK" \
  --namespace "$NAMESPACE"

