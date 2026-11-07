#!/usr/bin/env bash
# Renders argocd/ (root) with a stack.yaml, then every chart it points to, and validates with kubeconform.
# Usage: hack/validate.sh [stack.yaml]
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
STACK=${1:-$ROOT/stack.example.yaml}
OUT=$(mktemp -d); trap 'rm -rf "$OUT"' EXIT
KC=(kubeconform -strict -summary -ignore-missing-schemas -kubernetes-version 1.33.0 -schema-location default
  -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json')
helm template root "$ROOT/argocd" -f "$STACK" > "$OUT/root.yaml"
printf '%-18s ' root; "${KC[@]}" "$OUT/root.yaml" | tail -1
yq -r 'select(.kind == "Application") | [.metadata.name, .spec.source.path, .spec.destination.namespace] | join(" ")' "$OUT/root.yaml" > "$OUT/apps.txt"
for d in "$ROOT"/helm/apps/*/; do n=$(basename "$d"); echo "$n helm/apps/$n $n" >> "$OUT/apps.txt"; done
global=$(yq -o json 'select(.kind == "ApplicationSet") | .spec.template.spec.source.helm.valuesObject' "$OUT/root.yaml")
while read -r name path ns; do
  [ -n "$name" ] || continue
  if [[ $path == helm/apps/* ]]; then echo "$global" > "$OUT/v.json"
  else yq -o json "select(.kind == \"Application\" and .metadata.name == \"$name\") | .spec.source.helm.valuesObject" "$OUT/root.yaml" > "$OUT/v.json"; fi
  helm dependency build "$ROOT/$path" >/dev/null 2>&1 || helm dependency update "$ROOT/$path" >/dev/null
  helm template "$name" "$ROOT/$path" -n "$ns" -f "$OUT/v.json" --include-crds > "$OUT/$name.yaml"
  printf '%-18s ' "$name"; "${KC[@]}" "$OUT/$name.yaml" | tail -1
done < "$OUT/apps.txt"
