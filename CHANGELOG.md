# Changelog

## [0.4.0](https://github.com/dedsxc/essential/compare/v0.3.6...v0.4.0) (2026-11-12)


### ⚠ BREAKING CHANGES

* expose apps with Gateway API (HTTPRoute) instead of Ingress ([#15](https://github.com/dedsxc/essential/issues/15))

### Features

* app Postgres via cnpg-cluster chart, password ClusterGenerator, Reloader brick ([#4](https://github.com/dedsxc/essential/issues/4)) ([a0af69f](https://github.com/dedsxc/essential/commit/a0af69f0ffc5ccba4bd1f889f99904181dd23b87))
* **doctor:** refuse optional.cilium when the cluster already has a CNI ([a29f272](https://github.com/dedsxc/essential/commit/a29f272fb3fdf9185a1dd444ab7aefd904ce8e11))
* expose apps with Gateway API (HTTPRoute) instead of Ingress ([#15](https://github.com/dedsxc/essential/issues/15)) ([db040f7](https://github.com/dedsxc/essential/commit/db040f7309994c47ea6e763bcb5ae75f46108004))
* generate passwords with the External Secrets ClusterGenerator ([#27](https://github.com/dedsxc/essential/issues/27)) ([5c48b9c](https://github.com/dedsxc/essential/commit/5c48b9c32bfcfffcba6fd134cd805fdf72f1992a))
* host try.sh and install.sh in the repo (raw.githubusercontent.com) ([#30](https://github.com/dedsxc/essential/issues/30)) ([4337946](https://github.com/dedsxc/essential/commit/43379467dcbdf503cbd747618ecdda79bbccf747))
* installer and config in English; macOS support (no GNU timeout/base64 -w0) ([d469ab7](https://github.com/dedsxc/essential/commit/d469ab74c54683188061cca01fe11fdd07d2bf0a))
* **install:** wait until every app is ready, show progress ([#40](https://github.com/dedsxc/essential/issues/40)) ([7b34f52](https://github.com/dedsxc/essential/commit/7b34f521c60011537e4bab84d34b00257a8caf8b))
* kien/stack Starter (free edition of kube-ia-platform) ([ee343e1](https://github.com/dedsxc/essential/commit/ee343e1dc75f26e8f26d7819de7c96cfe38cf8e6))
* print ArgoCD admin password and port-forward right after ArgoCD is ready ([19259ba](https://github.com/dedsxc/essential/commit/19259bacc47f94e7af54f54e8cdf14c5b82fb038))


### Bug fixes

* --dry-run prints pure YAML on stdout (logs to stderr, values as comments) ([1286abd](https://github.com/dedsxc/essential/commit/1286abd86c01998714974775b002dc07b8770c55))
* AppProjects sync before ApplicationSets; skip metrics-server when the distro ships one (k3s); fix yq precedence in optional-brick patches ([fa75482](https://github.com/dedsxc/essential/commit/fa75482ceda0b4942a6cdfe8789a79debac4d92c))
* **cilium:** bootstrap without LB CRs (CRDs not there yet); socketLB.hostNamespaceOnly for container nodes ([3dac3b1](https://github.com/dedsxc/essential/commit/3dac3b1477814bdb328b714b3b64d1418ff6ed40))
* **infisical:** memory limit 2Gi (OOMKilled at first start with 1000Mi) ([0551fdf](https://github.com/dedsxc/essential/commit/0551fdf2cbbcafd3da03497f7118cc462963553e))
* **install:** bootstrap ArgoCD without HTTPRoute ([#19](https://github.com/dedsxc/essential/issues/19)) ([60ee916](https://github.com/dedsxc/essential/commit/60ee9161a728fa0d255b94d61c893e0ee182be0a))
* **install:** make install.sh executable ([#17](https://github.com/dedsxc/essential/issues/17)) ([f643792](https://github.com/dedsxc/essential/commit/f643792bedaa0909c598c6268fb7afdc92bfca55))
* **install:** refuse to install when cluster.yaml / argocd / helm changes are not pushed ([#35](https://github.com/dedsxc/essential/issues/35)) ([3a14b16](https://github.com/dedsxc/essential/commit/3a14b163c8813291e7d2391837bfebb8aa47cb94))
* **install:** retry chart downloads, silence tr broken pipe ([#10](https://github.com/dedsxc/essential/issues/10)) ([ee4b9c5](https://github.com/dedsxc/essential/commit/ee4b9c508b254df5e472f10cbb5800940657aa77))
* **traefik:** externalTrafficPolicy Local to keep client IP ([#20](https://github.com/dedsxc/essential/issues/20)) ([c15ecae](https://github.com/dedsxc/essential/commit/c15ecae4095c2f159bfcd4c3cda419ae00c94b7d))
* values carry no global defaults, cluster.yaml provides them ([#13](https://github.com/dedsxc/essential/issues/13)) ([32817b7](https://github.com/dedsxc/essential/commit/32817b74df56d10d081f81a6e969de8782bfe157))


### Documentation

* FAQ in English, Essential only ([d71d5a3](https://github.com/dedsxc/essential/commit/d71d5a3bf109d293a4d8afae5f937e8e7b29f802))
* README for argocd/applications layout ([47b99fb](https://github.com/dedsxc/essential/commit/47b99fb8608d094c32a39644ca8bcd3765726958))
* README for the argocd/ + helm/ layout ([ef15c8b](https://github.com/dedsxc/essential/commit/ef15c8bb1f1d2429ec4985e83881711b7fa2bb9d))

## [0.3.6](https://github.com/kien-stack/essential/compare/v0.3.5...v0.3.6) (2026-11-12)


### Features

* **install:** wait until every app is ready, show progress ([#40](https://github.com/kien-stack/essential/issues/40)) ([7b34f52](https://github.com/kien-stack/essential/commit/7b34f521c60011537e4bab84d34b00257a8caf8b))

## [0.3.5](https://github.com/kien-stack/essential/compare/v0.3.4...v0.3.5) (2026-11-11)


### Bug fixes

* **install:** refuse to install when cluster.yaml / argocd / helm changes are not pushed ([#35](https://github.com/kien-stack/essential/issues/35)) ([3a14b16](https://github.com/kien-stack/essential/commit/3a14b163c8813291e7d2391837bfebb8aa47cb94))

## [0.3.4](https://github.com/kien-stack/essential/compare/v0.3.3...v0.3.4) (2026-11-10)


### Features

* host try.sh and install.sh in the repo (raw.githubusercontent.com) ([#30](https://github.com/kien-stack/essential/issues/30)) ([4337946](https://github.com/kien-stack/essential/commit/43379467dcbdf503cbd747618ecdda79bbccf747))

## [0.3.3](https://github.com/kien-stack/essential/compare/v0.3.2...v0.3.3) (2026-11-09)


### Features

* generate passwords with the External Secrets ClusterGenerator ([#27](https://github.com/kien-stack/essential/issues/27)) ([5c48b9c](https://github.com/kien-stack/essential/commit/5c48b9c32bfcfffcba6fd134cd805fdf72f1992a))

## [0.3.2](https://github.com/dedsxc/kien-stack-essential/compare/v0.3.1...v0.3.2) (2026-11-09)


### Bug fixes

* **traefik:** externalTrafficPolicy Local to keep client IP ([#20](https://github.com/dedsxc/kien-stack-essential/issues/20)) ([c15ecae](https://github.com/dedsxc/kien-stack-essential/commit/c15ecae4095c2f159bfcd4c3cda419ae00c94b7d))

## [0.3.1](https://github.com/dedsxc/kien-stack-essential/compare/v0.3.0...v0.3.1) (2026-11-09)


### Bug fixes

* **install:** bootstrap ArgoCD without HTTPRoute ([#19](https://github.com/dedsxc/kien-stack-essential/issues/19)) ([60ee916](https://github.com/dedsxc/kien-stack-essential/commit/60ee9161a728fa0d255b94d61c893e0ee182be0a))
* **install:** make install.sh executable ([#17](https://github.com/dedsxc/kien-stack-essential/issues/17)) ([f643792](https://github.com/dedsxc/kien-stack-essential/commit/f643792bedaa0909c598c6268fb7afdc92bfca55))

## [0.3.0](https://github.com/dedsxc/kien-stack-essential/compare/v0.2.4...v0.3.0) (2026-11-09)


### ⚠ BREAKING CHANGES

* expose apps with Gateway API (HTTPRoute) instead of Ingress ([#15](https://github.com/dedsxc/kien-stack-essential/issues/15))

### Features

* expose apps with Gateway API (HTTPRoute) instead of Ingress ([#15](https://github.com/dedsxc/kien-stack-essential/issues/15)) ([db040f7](https://github.com/dedsxc/kien-stack-essential/commit/db040f7309994c47ea6e763bcb5ae75f46108004))

## [0.2.4](https://github.com/dedsxc/kien-stack-essential/compare/v0.2.3...v0.2.4) (2026-11-08)


### Bug fixes

* values carry no global defaults, cluster.yaml provides them ([#13](https://github.com/dedsxc/kien-stack-essential/issues/13)) ([32817b7](https://github.com/dedsxc/kien-stack-essential/commit/32817b74df56d10d081f81a6e969de8782bfe157))

## [0.2.3](https://github.com/dedsxc/kien-stack-essential/compare/v0.2.2...v0.2.3) (2026-11-08)


### Bug fixes

* **install:** retry chart downloads, silence tr broken pipe ([#10](https://github.com/dedsxc/kien-stack-essential/issues/10)) ([ee4b9c5](https://github.com/dedsxc/kien-stack-essential/commit/ee4b9c508b254df5e472f10cbb5800940657aa77))

## [0.2.2](https://github.com/dedsxc/kien-stack-essential/compare/v0.2.1...v0.2.2) (2026-11-08)


### Features

* app Postgres via cnpg-cluster chart, password ClusterGenerator, Reloader brick ([#4](https://github.com/dedsxc/kien-stack-essential/issues/4)) ([a0af69f](https://github.com/dedsxc/kien-stack-essential/commit/a0af69f0ffc5ccba4bd1f889f99904181dd23b87))
