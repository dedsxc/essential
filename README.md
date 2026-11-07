# kien/stack Starter

Free, open source GitOps platform for Kubernetes, installed in one command.
ArgoCD deploys and manages everything from your Git repo.

| Component | Role |
|---|---|
| ArgoCD | GitOps: everything deployed from Git (app-of-apps, self-managed) |
| Traefik | Ingress |
| cert-manager | TLS: self-signed CA or Let's Encrypt (HTTP-01 / DNS-01) |
| external-dns | DNS records (only if `dns.provider` is set) |
| External Secrets + Infisical | Secrets out of Git (self-hosted Infisical on CloudNativePG + Valkey) |
| CloudNativePG | PostgreSQL operator |
| metrics-server | `kubectl top`, HPA |
| OpenEBS hostpath (option) | Local volumes for k3s / bare metal |
| Cilium (option) | eBPF CNI, kube-proxy replacement, L2 load balancer for homelabs |

No Bitnami charts. All charts are upstream and pinned.

## Quick start

```bash
curl -fsSL https://shop.kien.cc/try.sh | bash
```

Or by hand:

```bash
git clone https://github.com/dedsxc/kien-stack-starter && cd kien-stack-starter
cp stack.example.yaml stack.yaml      # domain, Git repo, TLS
bash install.sh doctor --config stack.yaml
bash install.sh install --pack starter --config stack.yaml
```

Requirements: `kubectl`, `helm`, `yq` (v4), a Kubernetes cluster (2 vCPU, 6 GB RAM, 8 GB recommended).

No cluster? [k3s](https://docs.k3s.io/quick-start) in one minute:

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik" sh -
```

No domain? Leave `domain` empty: the installer uses `<ip>.sslip.io` with self-signed certificates.

## GitOps

ArgoCD watches the repo set in `gitops.repoURL`. Fork or copy this repo, commit your `stack.yaml`
changes there, and ArgoCD applies them. Private repo: set `GIT_USERNAME` / `GIT_TOKEN` when installing.

Validate offline: `bash hack/validate.sh stack.yaml` (helm template + kubeconform).

Deploy your own apps with [app-template](https://github.com/dedsxc/labs/tree/main/helm/fork):
see [`examples/my-app`](examples/my-app/application.yaml).

## Paid packs

**Private AI** (Onyx, Ollama, LiteLLM, Coder) and **All-In-One** (monitoring, SSO, S3, Argo Rollouts,
Renovate, Radar, Terraform for AWS EKS) build on this Starter: https://shop.kien.cc

## License

Apache-2.0. Open source components keep their own licenses.
