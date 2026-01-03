{{/*
Common labels
*/}}
{{- define "postgres.labels" -}}
helm.sh/chart: postgres-0.1.0
app.kubernetes.io/name: postgres
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: "16"
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
