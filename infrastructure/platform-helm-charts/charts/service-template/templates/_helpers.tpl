{{/*
Service account name
*/}}
{{- define "service-template.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default .Values.serviceName .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
