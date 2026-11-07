#!/usr/bin/env bash
# Offline check: kustomize argocd/applications, then helm template every chart in helm/platform and helm/apps
# (values.yaml + /cluster.yaml) and validate with kubeconform.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
KC=(kubeconform -strict -summary -ignore-missing-schemas -kubernetes-version 1.33.0 -schema-location default
  -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json')
printf '%-18s ' argocd; kubectl kustomize "$ROOT/argocd/applications" | "${KC[@]}" - | tail -1
for d in "$ROOT"/helm/platform/*/ "$ROOT"/helm/apps/*/; do
  n=$(basename "$d")
  helm dependency build "$d" >/dev/null 2>&1 || helm dependency update "$d" >/dev/null
  printf '%-18s ' "$n"
  helm template "$n" "$d" -n "$n" -f "$ROOT/cluster.yaml" --include-crds | "${KC[@]}" - | tail -1
done
