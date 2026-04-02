{{- define "omniroute.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "omniroute.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "omniroute.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "omniroute.labels" -}}
helm.sh/chart: {{ include "omniroute.chart" . }}
{{ include "omniroute.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "omniroute.selectorLabels" -}}
app.kubernetes.io/name: {{ include "omniroute.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "omniroute.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "omniroute.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "omniroute.imageTag" -}}
{{- if .Values.image.tag }}
{{- .Values.image.tag }}
{{- else }}
{{- .Chart.AppVersion }}
{{- end }}
{{- end }}

{{- define "omniroute.pvcName" -}}
{{- if .Values.persistence.existingClaim }}
{{- .Values.persistence.existingClaim }}
{{- else }}
{{- printf "%s-data" (include "omniroute.fullname" .) }}
{{- end }}
{{- end }}
