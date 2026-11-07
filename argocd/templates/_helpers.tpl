{{/* ClusterIssuer used by every Ingress */}}
{{- define "kstack.issuer" -}}
{{- if hasPrefix "letsencrypt" .Values.tls.issuer }}letsencrypt{{ else }}selfsigned-ca{{ end -}}
{{- end -}}

{{/* Values shared with every chart (helm/platform/*, helm/apps/*) as .Values.global */}}
{{- define "kstack.global" -}}
domain: {{ .Values.domain | quote }}
issuer: {{ include "kstack.issuer" . }}
ingressClass: {{ .Values.ingress.className }}
storageClass: {{ .Values.storageClass | quote }}
{{- end -}}

{{/* Source = a chart of this repo */}}
{{- define "kstack.source" -}}
repoURL: {{ .ctx.Values.gitops.repoURL }}
targetRevision: {{ .ctx.Values.gitops.targetRevision }}
path: {{ .path }}
{{- end -}}

{{- define "kstack.sync" -}}
automated: {prune: true, selfHeal: true}
retry: {limit: 10, backoff: {duration: 15s, factor: 2, maxDuration: 5m}}
syncOptions:
  - CreateNamespace=true
  - ServerSideApply=true
{{- end -}}

{{/* One ArgoCD Application for helm/platform/<name>.
     include "kstack.app" (dict "ctx" $ "name" "traefik" "ns" "traefik" "wave" 0 "values" (dict ...)) */}}
{{- define "kstack.app" -}}
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: {{ .name }}
  namespace: argocd
  annotations: {argocd.argoproj.io/sync-wave: {{ .wave | default 0 | quote }}}
  finalizers: [resources-finalizer.argocd.argoproj.io]
spec:
  project: default
  destination: {server: https://kubernetes.default.svc, namespace: {{ .ns }}}
  source:
    {{- include "kstack.source" (dict "ctx" .ctx "path" (printf "helm/platform/%s" .name)) | nindent 4 }}
    helm:
      releaseName: {{ .name }}
      valuesObject:
        global:
          {{- include "kstack.global" .ctx | nindent 10 }}
        {{- with .values }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
  syncPolicy:
    {{- include "kstack.sync" . | nindent 4 }}
{{- end -}}
