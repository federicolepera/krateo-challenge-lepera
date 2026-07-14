{{- define "neon-postgres-chart.name" -}}
{{- .Chart.Name -}}
{{- end -}}

{{- define "neon-postgres-chart.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "neon-postgres-chart.secretName" -}}
{{- if .Values.secretName -}}
{{- .Values.secretName -}}
{{- else -}}
{{- printf "%s-connection" (include "neon-postgres-chart.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "neon-postgres-chart.serviceAccountName" -}}
{{- if .Values.serviceAccountName -}}
{{- .Values.serviceAccountName -}}
{{- else -}}
{{- printf "%s-provisioner" (include "neon-postgres-chart.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
