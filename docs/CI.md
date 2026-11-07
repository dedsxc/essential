# CI and dependency updates

This repo ships with GitHub Actions and a Renovate config that also work in **your fork**.

## Charts test (`.github/workflows/charts-test.yaml`)

Runs on every pull request and on pushes to `main`:

| Job | What it does |
|---|---|
| Lint | `yamllint` (relaxed, `.yamllint.yaml`), `helm lint` of every chart with `cluster.yaml`, `ct lint` on changed charts (`ct.yaml`), `hack/validate.sh` (helm template + kubeconform) |
| Install `<chart>` | One job per changed chart under `helm/platform/*` or `helm/apps/*` (all charts if `cluster.yaml`, `ct.yaml`, `hack/` or the workflow changed). Renders the chart and validates it with kubeconform, then installs it in a [kind](https://kind.sigs.k8s.io/) cluster with `helm --wait` |
| Charts test result | Single aggregated check: use it as the required status check in branch protection |

Charts that cannot be installed alone in an empty kind cluster (`cilium` = CNI, `argocd`,
`cert-manager`, `external-secrets`, `external-dns`, `infisical`: CRDs and custom resources in the
same release or external providers) are only rendered + schema-checked. The others
(`traefik`, `metrics-server`, `cloudnative-pg`, `openebs`, apps) are really installed.

Run the same checks locally: `bash hack/validate.sh` (needs `helm`, `kubectl`, `kubeconform`).

## Renovate (`.github/renovate.json5`)

Renovate opens PRs when a new version is available for:

- upstream charts in `helm/platform/*/Chart.yaml` and `helm/apps/*/Chart.yaml` (including
  `argo-cd`, which `install.sh` bootstraps from `helm/platform/argocd`)
- container images in `values.yaml` (`repository` + `tag`)
- GitHub Actions (pinned by digest) and CI tools marked with `# renovate:` comments

Policy: weekly (Monday morning), minor + patch grouped in one PR per chart, majors in separate
PRs labelled `major`. Nothing is automerged by default. To automerge patch updates once CI is
green, set `automerge: true` in the "Patch updates" rule and make `Charts test result` a
required check. A Dependency Dashboard issue lists everything pending.

Pick **one** way to run Renovate in your fork:

1. **Mend Renovate GitHub App** (simplest): install https://github.com/apps/renovate on your
   fork. It reads `.github/renovate.json5`. Leave `RENOVATE_TOKEN` unset so the workflow below
   stays idle.
2. **Self-hosted** (`.github/workflows/renovate.yaml`): create a fine-grained token with
   read/write on *Contents*, *Pull requests*, *Issues*, *Workflows* for your fork, and save it as
   the repository secret `RENOVATE_TOKEN` (Settings > Secrets and variables > Actions). It runs
   weekly; run it on demand from the Actions tab (`dryRun` input for a test without PRs). If the
   secret is missing the job just prints a notice and succeeds.

PRs that change the Renovate config are validated by the same workflow (`Validate config`).

## Labels

`.github/workflows/labeler.yaml` labels PRs by area (`platform`, `apps`, `argocd`, `ci`, `docs`,
`installer`) from `.github/labeler.yaml`.

## Releases

Releases are automated with [release-please](https://github.com/googleapis/release-please)
(`.github/workflows/release.yaml`).

1. Write commits with [Conventional Commits](https://www.conventionalcommits.org/): `feat: ...`, `fix: ...`, `deps: ...`.
2. On every push to `main`, release-please opens or updates a **release PR** with the next version and the changelog.
3. Merge the release PR: the `vX.Y.Z` tag and the GitHub release are created.

Before 1.0.0, `feat` and `fix` bump the patch version, and breaking changes (`feat!:`) bump the minor.
Optional secret `RELEASE_TOKEN` (PAT or GitHub App token): without it the release PR is opened
with the default token and CI checks do not run on it automatically.
Repo setting required: *Settings > Actions > General > Allow GitHub Actions to create and approve pull requests*.
