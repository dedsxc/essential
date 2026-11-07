{{/* Liste des composants actives selon pack + optional + overrides */}}
{{- define "platform.enabled" -}}
{{- $v := .Values -}}
{{- $list := list -}}
{{- $list = concat $list $v.packs.base -}}
{{- if has $v.pack (list "ia" "full") }}{{ $list = concat $list $v.packs.ia }}{{ end -}}
{{- if eq $v.pack "full" }}{{ $list = concat $list $v.packs.full }}{{ end -}}
{{- if $v.optional.cilium }}{{ $list = append $list "cilium" }}{{ end -}}
{{- if eq (($v.storage | default dict).provider | default "none") "openebs-hostpath" }}{{ $list = append $list "openebs" }}{{ end -}}
{{- if eq $v.dns.provider "none" }}{{ $list = without $list "external-dns" }}{{ end -}}
{{- $out := list -}}
{{- range uniq $list -}}
{{- $o := index ($v.components | default dict) . | default dict -}}
{{- if ne (toString (index $o "enabled")) "false" }}{{ $out = append $out . }}{{ end -}}
{{- end -}}
{{- toYaml (dict "items" $out) -}}
{{- end -}}

{{- define "platform.issuer" -}}
{{- if eq .Values.tls.issuer "selfsigned" -}}selfsigned-ca{{- else -}}letsencrypt{{- end -}}
{{- end -}}

{{/* annotations ingress standard */}}
{{- define "platform.ingressAnn" -}}
cert-manager.io/cluster-issuer: {{ include "platform.issuer" . }}
{{- end -}}
