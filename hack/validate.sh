#!/usr/bin/env bash
# Rend le chart platform puis chaque Application enfant (helm template) et valide avec kubeconform.
# Usage: hack/validate.sh [stack.yaml] [pack...]
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
STACK=${1:-$ROOT/stack.example.yaml}; shift || true
PACKS=("$@"); [ ${#PACKS[@]} -eq 0 ] && PACKS=(starter)
OUT=$(mktemp -d); trap 'rm -rf "$OUT"' EXIT
KC=(kubeconform -strict -summary -ignore-missing-schemas -kubernetes-version 1.33.0
  -schema-location default
  -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json')
for pack in "${PACKS[@]}"; do
  echo "== pack $pack"
  helm template platform "$ROOT/charts/platform" -f "$STACK" --set pack="$pack" --set bootstrap=true > "$OUT/platform.yaml"
  "${KC[@]}" "$OUT/platform.yaml"
  yq -r 'select(.kind == "Application" and .metadata.name != "platform") | [.metadata.name, .spec.source.repoURL, (.spec.source.chart // "-"), .spec.source.targetRevision, (.spec.source.path // "-"), .spec.destination.namespace] | join(" ")' "$OUT/platform.yaml" > "$OUT/apps.txt"
  while read -r n _; do
    [ -n "$n" ] || continue
    yq -o json "select(.kind == \"Application\" and .metadata.name == \"$n\") | .spec.source.helm.valuesObject // {}" "$OUT/platform.yaml" > "$OUT/$n.values.json"
  done < "$OUT/apps.txt"
  while read -r name repo chart ver path ns; do
    [ -n "$name" ] || continue
    if [ "$path" != "-" ]; then src=("$ROOT/$path")
    elif [[ "$repo" == http* ]]; then src=("$chart" --repo "$repo" --version "$ver")
    else src=("oci://$repo/$chart" --version "$ver"); fi
    if helm template "$name" "${src[@]}" -n "$ns" -f "$OUT/$name.values.json" --include-crds > "$OUT/$name.yaml" 2> "$OUT/$name.err"; then
      printf '%-18s ' "$name"; "${KC[@]}" "$OUT/$name.yaml" | tail -1
    else echo "ECHEC $name"; cat "$OUT/$name.err"; exit 1; fi
  done < "$OUT/apps.txt"
done
