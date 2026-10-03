#!/usr/bin/env bash
# Replace the GitHub username placeholder (and optionally the AWS region)
# in the GitOps manifests and Helm values.
# Usage: scripts/configure.sh <github-username> [aws-region]
set -euo pipefail

GH_USER="${1:?Usage: scripts/configure.sh <github-username> [aws-region]}"
REGION="${2:-ap-south-1}"
cd "$(dirname "$0")/.."

replace() { # portable in-place sed (GNU and BSD/macOS)
  local from="$1" to="$2"; shift 2
  for f in "$@"; do sed -i.bak "s|${from}|${to}|g" "$f" && rm -f "$f.bak"; done
}

replace "YOUR_GITHUB_USERNAME" "$GH_USER" gitops/root-app.yaml gitops/apps/demo-app.yaml README.md

if [[ "$REGION" != "ap-south-1" ]]; then
  replace "ap-south-1" "$REGION" \
    gitops/apps/aws-load-balancer-controller.yaml \
    helm/demo-app/values.yaml helm/demo-app/values-dev.yaml
  echo "Region set to $REGION. Also set region = \"$REGION\" in terraform/envs/dev/terraform.tfvars"
fi

echo "Configured for github.com/${GH_USER}/eks-platform. Review with: git diff"
