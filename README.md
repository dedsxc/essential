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

Demo (zero questions, public repo, self-signed certs):

```bash
curl -fsSL https://shop.kien.cc/try.sh | bash
curl -fsSL https://shop.kien.cc/try.sh | bash -s uninstall
```

Real install: [fork this repo](https://github.com/dedsxc/kien-stack-starter/fork), then

```bash
curl -fsSL https://shop.kien.cc/install.sh | bash    # asks for your fork, domain, email
```

Requirements: `kubectl`, `helm`, `git`, a Kubernetes cluster (2 vCPU, 6 GB RAM, 8 GB recommended).
No cluster? [k3s](https://docs.k3s.io/quick-start) in one minute:

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik" sh -
```

## How the repo is organised

```
argocd/                         app-of-apps (a Helm chart rendered by ArgoCD)
  templates/platform/traefik.yaml    -> Application -> helm/platform/traefik
  templates/platform/argocd.yaml     -> Application -> helm/platform/argocd (ArgoCD manages itself)
  templates/platform/...             one file per platform brick
  templates/applications.yaml        ApplicationSet: one Application per helm/apps/* folder
helm/
  platform/<brick>/             Helm chart: Chart.yaml (upstream chart as dependency), values.yaml, templates/
  apps/<your-app>/              your apps (see helm/apps/hello, based on app-template)
stack.example.yaml              your settings (domain, TLS, Git repo...), passed to argocd/
```

1. `install.sh` installs ArgoCD with Helm (from `helm/platform/argocd`), then applies **one** Application,
   `root`, pointing to `argocd/` with your `stack.yaml` as values.
2. `root` renders one Application per file in `argocd/templates/platform/`. Each one deploys a chart from
   `helm/platform/`. ArgoCD then takes over its own install.
3. The `apps` ApplicationSet creates an Application per folder in `helm/apps/`.

Every chart receives `global.domain`, `global.issuer`, `global.ingressClass`, `global.storageClass`.

### Deploy your app

```bash
cp -r helm/apps/hello helm/apps/my-site     # rename in Chart.yaml, edit values.yaml (image, port, host)
git add helm/apps/my-site && git commit -m "my-site" && git push
```

ArgoCD creates the `my-site` Application in the `my-site` namespace. Delete the folder to remove it.

### Change the platform

- Tune a brick: edit `helm/platform/<brick>/values.yaml` (upstream values go under the dependency name).
- Upgrade a brick: bump the version in `helm/platform/<brick>/Chart.yaml`.
- Add a brick: create `helm/platform/<brick>/` and `argocd/templates/platform/<brick>.yaml`.

Private repo: set `GIT_USERNAME` / `GIT_TOKEN` when installing.
Validate offline: `bash hack/validate.sh stack.yaml` (helm template + kubeconform on every chart).

## Paid packs

**Private AI** (Onyx, Ollama, LiteLLM, Coder) and **All-In-One** (monitoring, SSO, S3, Argo Rollouts,
Renovate, Radar, Terraform for AWS EKS) build on this Starter: https://shop.kien.cc

## License

Apache-2.0. Open source components keep their own licenses.
