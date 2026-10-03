#!/usr/bin/env bash
# Tear everything down in the right order. Kubernetes-created AWS resources
# (the ALB from the Ingress) must be deleted BEFORE terraform destroy,
# otherwise the VPC cannot be deleted.
set -euo pipefail
cd "$(dirname "$0")/.."
TF_DIR="terraform/envs/${ENV:-dev}"

if kubectl cluster-info >/dev/null 2>&1; then
  echo ">> Stopping the root app from re-creating children"
  kubectl -n argocd patch application root --type merge -p '{"spec":{"syncPolicy":null}}' 2>/dev/null || true

  echo ">> Deleting demo-app (the load balancer controller removes the ALB)"
  kubectl -n argocd delete application demo-app --wait=true --timeout=10m 2>/dev/null || true
  kubectl delete ingress --all -A --timeout=5m 2>/dev/null || true

  echo ">> Waiting for load balancer cleanup"
  for _ in $(seq 1 30); do
    [[ -z "$(kubectl get ingress -A -o name 2>/dev/null)" ]] && break
    sleep 10
  done
  sleep 30

  echo ">> Deleting remaining Argo CD applications and Argo CD itself"
  kubectl -n argocd delete application --all --wait=true --timeout=10m 2>/dev/null || true
  helm uninstall argocd -n argocd 2>/dev/null || true
else
  echo ">> kubectl not connected; skipping in-cluster cleanup"
fi

echo ">> terraform destroy"
terraform -chdir="$TF_DIR" destroy

cat << MSG

Done. Double-check in the AWS console that no load balancers named k8s-*
remain in EC2 > Load Balancers. The Terraform state bucket from
terraform/bootstrap is kept on purpose (delete it manually if you are finished).
MSG
