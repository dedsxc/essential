# FAQ - Prerequis

**De quoi ai-je besoin ?**

1. **Un cluster Kubernetes existant** (>= 1.29) et un kubeconfig avec droits *cluster-admin*,
   **ou un compte AWS** : le pack `full` inclut un installeur Terraform (`terraform/aws/`) qui cree le cluster EKS
   (terraform >= 1.5, aws CLI authentifiee; cout indicatif EKS 0,10 $/h + noeuds + NAT, `terraform destroy` pour tout supprimer).
   - une **StorageClass par defaut** (PVC Postgres, Ollama, Onyx, Prometheus);
   - un **LoadBalancer** pour le Service Traefik: cloud, k3s ServiceLB, ou **Cilium** (homelab: `ingress.ciliumLB.enabled: true` + une plage d IP libre du LAN, annoncee en L2, sans MetalLB). A defaut un NodePort (`ingress.serviceType: NodePort` + `ingress.nodeIP`).
2. **Ressources minimales (allouables)**:
   - pack `essential`: 2 vCPU / 6 Go RAM (8 recommandes) / 40 Go disque;
   - pack `ia` / `full`, Onyx complet (defaut, `ai.onyx.small: false`, indexation OpenSearch) + Ollama CPU
     `qwen2.5:0.5b`: **6 vCPU / 12 Go minimum (tres juste), 16 Go recommandes** / 80 Go disque;
   - Onyx leger (`ai.onyx.small: true`, chat sans indexation): ~4 Go de moins;
   - GPU NVIDIA optionnel pour Ollama; modeles plus gros => prevoir la RAM du modele en plus.

**Mesures reelles (minikube 6 vCPU / 12 Go, pack `ia`, Onyx complet, 2026-11-01)**:
noeud a 11,9 Go / 12 Go (cache inclus), sans OOMKilled ni pod Pending. Par namespace (cgroups):
onyx ~7,0 Go (20 pods; OpenSearch 1,5 Go, api-server 0,85 Go, modeles inference/indexing ~0,7 Go chacun),
ollama ~0,95 Go, monitoring ~1,0 Go, argocd ~0,65 Go, reste < 0,5 Go.

**Ce qui a ete teste de bout en bout** (meme lab): toutes les Applications ArgoCD Synced/Healthy;
Onyx via Valkey (cles presentes, aucune erreur Redis); creation admin via API, provider Ollama
`qwen2.5:0.5b`, upload d'un fichier texte (connecteur File), indexation (1 doc dans OpenSearch),
recherche admin et chat avec outil de recherche renvoyant le document; chat simple via Ollama.
Note: `qwen2.5:0.5b` declenche rarement la recherche de lui-meme; pour du RAG fiable, utiliser un
modele plus gros ou un fournisseur externe (LiteLLM).
Non teste en cluster: pack `full` complet, installeur Terraform sur un vrai compte AWS, Let's Encrypt, GPU.
3. **Poste d'installation**: `kubectl`, `helm` >= 3.14, `git`, `yq` v4 (mikefarah). `./install.sh doctor` verifie tout.
4. **Un repo Git** (GitHub, GitLab, Gitea...) joignable **depuis le cluster**, contenant ce repo + votre `stack.yaml`.
   Prive: `GIT_USERNAME` + `GIT_TOKEN` (lecture seule suffit).
5. **Un domaine** dont vous gerez le DNS: enregistrement `*.domaine` vers l'IP du LoadBalancer Traefik,
   ou external-dns avec un token API du fournisseur DNS. Pour un test: `<ip>.nip.io` / `sslip.io`.
6. **Certificats**: self-signed (tests) ou Let's Encrypt — HTTP01 (port 80 public) ou DNS01 (token API DNS, Cloudflare).
7. **Secrets**: par defaut generes aleatoirement par `install.sh` dans le cluster. En production, recommande:
   un projet **Infisical** (cloud ou auto-heberge) + une *Machine Identity* Universal Auth
   (`INFISICAL_CLIENT_ID` / `INFISICAL_CLIENT_SECRET`); les cles attendues sont listees dans
   an `ExternalSecret` in your app chart (`helm/apps/<app>/templates/`).
8. **Inference externe (optionnel)**: cle API Anthropic et/ou Gemini, ou identifiants AWS Bedrock (region activee).

**Pas besoin de**: Vault, charts Bitnami, GPU (CPU par defaut), acces Internet entrant (sauf HTTP01).

**Images**: toutes publiques (docker.io, quay.io, ghcr.io, registry.k8s.io); le cluster doit pouvoir les tirer.

## Pas de nom de domaine ?

Laisser `domain` vide : l'installeur utilise `<ip>.sslip.io` (DNS public gratuit qui renvoie l'IP du load balancer,
`ingress.ciliumLB.start` ou `ingress.nodeIP`) et des certificats **self-signed** (CA dans `cert-manager/selfsigned-ca`).
Ex. `https://argocd.192.168.1.240.sslip.io`. Le navigateur affiche un avertissement tant que la CA n'est pas importee.

## Cilium (option du Essential)

`optional.cilium: true` + `cilium.k8sServiceHost` (IP du serveur API) : Cilium est installe en premier (CNI eBPF,
remplace kube-proxy, load balancer L2 via `ingress.ciliumLB`). Le cluster doit etre cree sans CNI ni kube-proxy,
ex. k3s : `--flannel-backend=none --disable-network-policy --disable-kube-proxy --disable servicelb`.
