{{/*
Labels
*/}}
{{- define "elasticsearch.labels" -}}
helm.sh/chart: elasticsearch-0.1.0
app.kubernetes.io/name: elasticsearch
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: "8.15.0"
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
