#!/usr/bin/env bash
# kien/stack Starter installer (free, Apache-2.0).
#   ./install.sh doctor  [--config stack.yaml]
#   ./install.sh install --pack starter [--config stack.yaml] [--dry-run]
#   ./install.sh --pack starter --config stack.yaml       (install implicite)
# Cible: le cluster du contexte kubectl courant (cluster existant prioritaire).
# Variables d'env optionnelles:
#   GIT_USERNAME / GIT_TOKEN          repo GitOps prive (HTTPS)
#   INFISICAL_CLIENT_ID / INFISICAL_CLIENT_SECRET   si secrets.provider=infisical
#   DNS01_API_TOKEN                   si tls.issuer=letsencrypt-dns01
#   EXTERNAL_DNS_API_TOKEN            si dns.provider != none
#   RENOVATE_TOKEN, ANTHROPIC_API_KEY, GEMINI_API_KEY, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CONFIG="$ROOT/stack.yaml"
PACK=""
CMD=install
DRY_RUN=0
ARGOCD_TIMEOUT=${ARGOCD_TIMEOUT:-600s}

log()  { printf '\033[1;34m[kube-ia]\033[0m %s\n' "$*"; }
ok()   { printf '  \033[32mOK\033[0m   %s\n' "$*"; }
warn() { printf '  \033[33mWARN\033[0m %s\n' "$*"; }
ko()   { printf '  \033[31mKO\033[0m   %s\n' "$*"; }
die()  { printf '\033[31m[kube-ia] ERREUR:\033[0m %s\n' "$*" >&2; exit 1; }

usage() { sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; }

while [ $# -gt 0 ]; do
  case "$1" in
    doctor|install) CMD=$1 ;;
    --pack) PACK=${2:?--pack requiert une valeur}; shift ;;
    --config|-c) CONFIG=${2:?--config requiert un fichier}; shift ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage; die "argument inconnu: $1" ;;
  esac
  shift
done

cfg() { yq -r "$1 // \"\"" "$CONFIG"; }

# Sans domaine: <ip>.sslip.io (DNS public gratuit qui renvoie l'IP), certificats self-signed.
# IP = ingress.ciliumLB.start, sinon ingress.nodeIP.
auto_domain() {
  local d ip; d=$(cfg .domain)
  if [ -n "$d" ] && [ "$d" != example.com ]; then echo "$d"; return; fi
  ip=$(cfg .ingress.ciliumLB.start); [ -n "$ip" ] || ip=$(cfg .ingress.nodeIP)
  [ -n "$ip" ] && echo "${ip}.sslip.io"
}

randpw() { LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c "${1:-24}" || true; }

# ---------------------------------------------------------------- doctor
doctor() {
  local fail=0 b
  log "Verification des prerequis (config: $CONFIG)"
  for b in kubectl helm git yq; do
    if command -v "$b" >/dev/null 2>&1; then ok "$b present"; else ko "$b absent du PATH"; fail=1; fi
  done
  [ "$fail" -eq 0 ] || { ko "outils manquants"; return 1; }
  if [ -f "$CONFIG" ]; then ok "config $CONFIG"; else ko "config $CONFIG introuvable (cp stack.example.yaml stack.yaml)"; return 1; fi

  local ctx; ctx=$(kubectl config current-context 2>/dev/null || true)
  if kubectl version --request-timeout=10s >/dev/null 2>&1; then
    ok "acces cluster (contexte: ${ctx:-?}, $(kubectl version -o json 2>/dev/null | yq -r '.serverVersion.gitVersion'))"
  else ko "cluster injoignable (contexte: ${ctx:-aucun})"; fail=1; fi
  if [ "$fail" -eq 0 ]; then
    if kubectl auth can-i '*' '*' --all-namespaces >/dev/null 2>&1; then ok "droits cluster-admin"; else ko "droits cluster-admin requis"; fail=1; fi
    if kubectl get storageclass -o name 2>/dev/null | grep -q .; then ok "StorageClass: $(kubectl get sc -o name | tr '\n' ' ')"; else warn "aucune StorageClass (PVC Postgres/Ollama/Onyx en Pending)"; fi
    local cpu mem
    cpu=$(kubectl get nodes -o jsonpath='{range .items[*]}{.status.allocatable.cpu}{"\n"}{end}' | awk '{ if ($1 ~ /m$/) s+=$1/1000; else s+=$1 } END {print int(s)}')
    mem=$(kubectl get nodes -o jsonpath='{range .items[*]}{.status.allocatable.memory}{"\n"}{end}' | awk '{ v=$1; if (v ~ /Ki$/) s+=v/1048576; else if (v ~ /Mi$/) s+=v/1024; else if (v ~ /Gi$/) s+=v; else s+=v/1073741824 } END {print int(s)}')
    ok "capacite allouable: ${cpu} CPU / ${mem} Gi"
    local p=${PACK:-$(cfg .pack)}
    case "$p" in
      starter) [ "$mem" -ge 3 ] || warn "pack starter: >= 2 CPU / 4 Go recommandes" ;;
      ia|full) [ "$mem" -ge 14 ] || warn "pack $p: >= 8 CPU / 16 Go recommandes (Onyx + OpenSearch + Ollama)" ;;
    esac
  fi

  local repo; repo=$(cfg .gitops.repoURL)
  if [ -z "$repo" ]; then ko "gitops.repoURL vide"; fail=1
  elif git_ls_remote "$repo" >/dev/null 2>&1; then ok "repo Git joignable: $repo"
  else ko "repo Git injoignable: $repo (GIT_USERNAME/GIT_TOKEN pour un repo prive)"; fail=1; fi

  local domain; domain=$(auto_domain)
  if [ -z "$domain" ]; then ko "pas de domaine: renseigner domain, ou ingress.ciliumLB.start / ingress.nodeIP (domaine <ip>.sslip.io + self-signed)"; fail=1
  elif [ "$domain" != "$(cfg .domain)" ]; then ok "pas de domaine: utilisation de $domain (certificats self-signed)"
  elif getent hosts "argocd.$domain" >/dev/null 2>&1; then ok "DNS: argocd.$domain -> $(getent hosts "argocd.$domain" | awk '{print $1; exit}')"
  else warn "argocd.$domain ne resout pas (normal si external-dns le creera; sinon creer *.$domain)"; fi

  case "$(cfg .tls.issuer)" in
    letsencrypt-dns01)
      if [ -n "${DNS01_API_TOKEN:-}" ] || kubectl -n cert-manager get secret "$(cfg .tls.dns01.secretName)" >/dev/null 2>&1; then ok "token DNS01"
      else ko "DNS01_API_TOKEN requis"; fail=1; fi ;;
    letsencrypt-http01) warn "HTTP01: *.$domain doit pointer vers le LoadBalancer Traefik, port 80 ouvert depuis Internet" ;;
    selfsigned) ok "issuer self-signed (tests)" ;;
    *) ko "tls.issuer invalide"; fail=1 ;;
  esac
  if [ "$(cfg .secrets.provider)" = infisical ]; then
    if [ -n "${INFISICAL_CLIENT_ID:-}" ] && [ -n "${INFISICAL_CLIENT_SECRET:-}" ]; then ok "identifiants Infisical"; else ko "INFISICAL_CLIENT_ID/INFISICAL_CLIENT_SECRET requis"; fail=1; fi
  fi
  if [ "$fail" -eq 0 ]; then log "doctor: OK"; else log "doctor: des prerequis manquent"; fi
  return "$fail"
}

git_ls_remote() {
  local url=$1
  if [ -n "${GIT_TOKEN:-}" ]; then
    GIT_TERMINAL_PROMPT=0 timeout 30 git -c credential.helper= \
      -c "http.extraheader=Authorization: Basic $(printf '%s:%s' "${GIT_USERNAME:-git}" "$GIT_TOKEN" | base64 -w0)" \
      ls-remote "$url" HEAD
  else
    GIT_TERMINAL_PROMPT=0 timeout 30 git -c credential.helper= ls-remote "$url" HEAD
  fi
}

# ---------------------------------------------------------------- install
VALUES=""
render() { helm template platform "$ROOT/charts/platform" -f "$VALUES" "$@"; }

enabled_components() {
  render --show-only templates/applications.yaml | yq -r 'select(.kind == "Application") | .metadata.name' | grep -vx -- '---'
}

ensure_ns() { kubectl create namespace "$1" --dry-run=client -o yaml | kubectl apply -f - >/dev/null; }

# ensure_secret ns name [type] key=value...  (n'ecrase jamais un secret existant)
ensure_secret() {
  local ns=$1 name=$2; shift 2
  local type=generic
  case "${1:-}" in --type=*) type=${1#--type=}; shift ;; esac
  ensure_ns "$ns"
  if kubectl -n "$ns" get secret "$name" >/dev/null 2>&1; then ok "secret $ns/$name existe deja"; return; fi
  local args=() kv
  for kv in "$@"; do args+=("--from-literal=$kv"); done
  kubectl -n "$ns" create secret generic "$name" --type="$type" "${args[@]}" >/dev/null
  ok "secret $ns/$name cree"
}

bootstrap_secrets() {
  local comps=$1 provider issuer
  has() { grep -qx "$1" <<<"$comps"; }
  provider=$(cfg .secrets.provider); issuer=$(cfg .tls.issuer)
  log "Secrets d'amorcage"
  if [ "$issuer" = letsencrypt-dns01 ] && [ -n "${DNS01_API_TOKEN:-}" ]; then
    ensure_secret cert-manager "$(cfg .tls.dns01.secretName)" "$(cfg .tls.dns01.secretKey)=$DNS01_API_TOKEN"
  fi
  if [ "$(cfg .dns.provider)" != none ] && [ -n "${EXTERNAL_DNS_API_TOKEN:-}" ]; then
    ensure_secret external-dns "$(cfg .dns.secretName)" "api-token=$EXTERNAL_DNS_API_TOKEN"
  fi
  if has infisical; then
    local vp; vp="$(randpw 32)"
    ensure_secret infisical infisical-secrets "ENCRYPTION_KEY=$(LC_ALL=C tr -dc 'a-f0-9' </dev/urandom | head -c 32)" \
      "AUTH_SECRET=$(head -c 32 /dev/urandom | base64 | tr -d '\n')" "VALKEY_PASSWORD=$vp" \
      "REDIS_URL=redis://:$vp@infisical-valkey.infisical.svc:6379"
  fi
  if [ "$provider" = infisical ]; then
    ensure_secret external-secrets "$(cfg .secrets.infisical.credentialsSecret)" \
      "clientId=${INFISICAL_CLIENT_ID:?}" "clientSecret=${INFISICAL_CLIENT_SECRET:?}"
    ok "les secrets applicatifs viendront d'Infisical (ExternalSecrets, cf. charts/platform-config/values.yaml)"
    return
  fi
  # provider none: generation locale (valeurs aleatoires), jamais commitees
  has monitoring && ensure_secret monitoring grafana-admin admin-user=admin "admin-password=$(randpw)"
  if has onyx; then
    local s3u s3p
    s3u=$(randpw 16); s3p=$(randpw 32)
    ensure_secret onyx onyx-postgresql --type=kubernetes.io/basic-auth username=postgres "password=$(randpw)"
    ensure_secret onyx onyx-redis "redis_password=$(randpw)"
    ensure_secret onyx onyx-objectstorage "s3_aws_access_key_id=$s3u" "s3_aws_secret_access_key=$s3p" "rootUser=$s3u" "rootPassword=$s3p"
    ensure_secret onyx onyx-opensearch opensearch_admin_username=admin "opensearch_admin_password=Aa1!$(randpw 20)"
    ensure_secret onyx onyx-userauth "user_auth_secret=$(randpw 64)"
  fi
  if has litellm; then
    local mk; mk="sk-$(randpw 32)"
    ensure_secret litellm litellm-masterkey "masterkey=$mk"
    ensure_secret litellm litellm-providers "PROXY_MASTER_KEY=$mk" "ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY:-}" \
      "GEMINI_API_KEY=${GEMINI_API_KEY:-}" "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-}" "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:-}"
  fi
  if has seaweedfs; then
    local ak sk; ak="$(randpw 20)"; sk="$(randpw 40)"
    ensure_secret seaweedfs seaweedfs-s3 "seaweedfs_s3_config={\"identities\":[{\"name\":\"admin\",\"credentials\":[{\"accessKey\":\"$ak\",\"secretKey\":\"$sk\"}],\"actions\":[\"Admin\",\"Read\",\"List\",\"Tagging\",\"Write\"]}]}" "accessKey=$ak" "secretKey=$sk"
  fi
  has renovate && ensure_secret renovate renovate-env "RENOVATE_TOKEN=${RENOVATE_TOKEN:-}"
  has authentik && ensure_secret authentik authentik-env "AUTHENTIK_SECRET_KEY=$(randpw 50)"
  return 0
}

install() {
  [ -f "$CONFIG" ] || die "config introuvable: $CONFIG"
  PACK=${PACK:-$(cfg .pack)}
  case "$PACK" in starter) ;; ia|full) die "pack $PACK: edition payante (https://shop.kien.cc). Cette edition installe le starter." ;; *) die "--pack doit valoir starter (recu: '$PACK')" ;; esac
  VALUES=$(mktemp); trap 'rm -f "$VALUES"' EXIT
  yq ".pack = \"$PACK\"" "$CONFIG" > "$VALUES"
  local dom; dom=$(auto_domain)
  if [ -n "$dom" ] && [ "$dom" != "$(cfg .domain)" ]; then
    yq -i ".domain = \"$dom\" | .tls.issuer = \"selfsigned\" | .dns.provider = \"none\"" "$VALUES"
    log "Pas de domaine: $dom (self-signed, ex. https://argocd.$dom)"
  fi

  local comps; comps=$(enabled_components)
  log "Pack $PACK -> composants: $(tr '\n' ' ' <<<"$comps")"
  if [ "$DRY_RUN" -eq 1 ]; then render --set bootstrap=true; return; fi

  doctor || die "doctor a echoue: corriger les prerequis ci-dessus"

  bootstrap_secrets "$comps"

  if grep -qx cilium <<<"$comps"; then
    log "Installation de Cilium (CNI, avant tout le reste; ensuite gere par ArgoCD)"
    local cvals cver; cvals=$(mktemp)
    render --show-only templates/applications.yaml | yq 'select(.metadata.name == "cilium") | .spec.source.helm.valuesObject' > "$cvals"
    cver=$(render --show-only templates/applications.yaml | yq -r 'select(.metadata.name == "cilium") | .spec.source.targetRevision' | grep -vx -- '---')
    helm upgrade --install cilium cilium --repo https://helm.cilium.io/ --version "$cver" -n kube-system \
      -f "$cvals" --wait --timeout 10m >/dev/null
    rm -f "$cvals"
    kubectl wait --for=condition=Ready nodes --all --timeout=5m >/dev/null
    ok "Cilium $cver pret, noeuds Ready"
  fi

  log "Installation d'ArgoCD (Helm, ensuite auto-gere par ArgoCD)"
  local avals; avals=$(mktemp)
  render --show-only templates/applications.yaml | yq 'select(.metadata.name == "argocd") | .spec.source.helm.valuesObject' > "$avals"
  local aver arepo
  aver=$(render --show-only templates/applications.yaml | yq -r 'select(.metadata.name == "argocd") | .spec.source.targetRevision' | grep -vx -- '---')
  arepo=$(render --show-only templates/applications.yaml | yq -r 'select(.metadata.name == "argocd") | .spec.source.repoURL' | grep -vx -- '---')
  helm upgrade --install argocd argo-cd --repo "$arepo" --version "$aver" -n argocd --create-namespace \
    -f "$avals" --wait --timeout 10m >/dev/null
  rm -f "$avals"
  ok "ArgoCD $aver pret"

  if [ -n "${GIT_TOKEN:-}" ]; then
    kubectl -n argocd apply -f - >/dev/null <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: gitops-repo
  namespace: argocd
  labels: {argocd.argoproj.io/secret-type: repository}
stringData:
  type: git
  url: $(cfg .gitops.repoURL)
  username: ${GIT_USERNAME:-git}
  password: ${GIT_TOKEN}
YAML
    ok "credential du repo GitOps enregistre dans ArgoCD"
  fi

  log "Application racine 'platform' (app-of-apps)"
  render --set bootstrap=true | yq 'select(.kind == "Application" and .metadata.name == "platform")' | kubectl apply -f - >/dev/null
  ok "applique: ArgoCD synchronise maintenant depuis $(cfg .gitops.repoURL)"

  wait_apps "$comps"
  summary
}

wait_apps() {
  local comps=$1 deadline=$(( $(date +%s) + ${ARGOCD_TIMEOUT%s} )) pending
  log "Attente Synced/Healthy (timeout $ARGOCD_TIMEOUT)"
  while :; do
    pending=""
    for a in platform $comps; do
      local st
      st=$(kubectl -n argocd get application "$a" -o jsonpath='{.status.sync.status}/{.status.health.status}' 2>/dev/null || true)
      [ "$st" = Synced/Healthy ] || pending="$pending $a(${st:-absent})"
    done
    [ -z "$pending" ] && { ok "toutes les applications sont Synced/Healthy"; return 0; }
    if [ "$(date +%s)" -ge "$deadline" ]; then
      warn "pas encore pretes:$pending"
      if [ -z "$(kubectl -n traefik get svc traefik -o jsonpath='{.status.loadBalancer.ingress}' 2>/dev/null)" ] \
         && [ "$(kubectl -n traefik get svc traefik -o jsonpath='{.spec.type}' 2>/dev/null)" = LoadBalancer ]; then
        warn "Traefik attend une IP de load balancer: le cluster n'en fournit pas."
        warn "  -> homelab: ingress.ciliumLB.enabled=true (Cilium L2), ou ingress.serviceType: NodePort; minikube: 'minikube tunnel'"
      fi
      return 1
    fi
    sleep 15
  done
}

summary() {
  local d; d=$(cfg .domain)
  log "Termine. Acces:"
  echo "  ArgoCD : https://argocd.$d  (admin / kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)"
  grep -qx monitoring <<<"$(enabled_components)" && echo "  Grafana: https://grafana.$d (admin / kubectl -n monitoring get secret grafana-admin -o jsonpath='{.data.admin-password}' | base64 -d)"
  grep -qx infisical <<<"$(enabled_components)" && echo "  Infisical: https://infisical.$d (create the admin account on first visit)"
  grep -qx onyx <<<"$(enabled_components)" && echo "  Onyx   : https://onyx.$d"
  [ "$(cfg .tls.issuer)" = selfsigned ] && echo "  (certificats self-signed: CA dans cert-manager/selfsigned-ca)"
  return 0
}

command -v yq >/dev/null 2>&1 || die "yq (mikefarah, v4) est requis"
case "$CMD" in
  doctor) doctor ;;
  install) install ;;
esac
