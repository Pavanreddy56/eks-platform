#!/usr/bin/env bash
# One-time install of Argo CD. After this, everything is deployed from Git.
set -euo pipefail

ARGOCD_CHART_VERSION="10.9.6"
cd "$(dirname "$0")/.."

if grep -q "YOUR_GITHUB_USERNAME" gitops/root-app.yaml; then
  echo "ERROR: run scripts/configure.sh <github-username> first." >&2
  exit 1
fi

kubectl cluster-info >/dev/null || { echo "ERROR: kubectl is not connected. Run: make kubeconfig" >&2; exit 1; }

echo ">> Installing Argo CD ${ARGOCD_CHART_VERSION}"
helm repo add argo https://argoproj.github.io/argo-helm --force-update >/dev/null
helm upgrade --install argocd argo/argo-cd \
  --version "${ARGOCD_CHART_VERSION}" \
  --namespace argocd --create-namespace \
  --values gitops/bootstrap/argocd-values.yaml \
  --wait --timeout 10m

echo ">> Creating the root app-of-apps"
kubectl apply -f gitops/root-app.yaml

cat << MSG

Argo CD is installed and syncing gitops/apps from GitHub.
  Admin password : make argocd-password
  Open the UI    : make argocd-ui   (then https://localhost:8080, user: admin)
  Watch apps     : kubectl -n argocd get applications -w
MSG
