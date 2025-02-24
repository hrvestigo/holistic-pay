{{/*
Expand the name of the chart.
*/}}
{{- define "payment-dashboard-web.name" -}}
{{- default .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "payment-dashboard-web.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
payment-dashboard-web image repository
*/}}
{{- define "payment-dashboard-web.app.repository" -}}
{{- $psRepo := "hrvestigo/payment-dashboard-web-ms" }}
{{- $reg := default .Values.image.registry .Values.image.app.registry }}
{{- if $reg }}
{{- printf "%s/%s" $reg $psRepo }}
{{- else }}
{{- $psRepo }}
{{- end }}
{{- end }}

{{/*
payment-dashboard-web image pull policy
*/}}
{{- define "payment-dashboard-web.app.imagePullPolicy" -}}
{{- $reg := default .Values.image.pullPolicy .Values.image.app.pullPolicy }}
{{- default "IfNotPresent" $reg }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "payment-dashboard-web.labels" -}}
helm.sh/chart: {{ include "payment-dashboard-web.chart" . }}
app: {{ include "payment-dashboard-web.name" . }}
project: HolisticPay
{{ include "payment-dashboard-web.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "payment-dashboard-web.selectorLabels" -}}
app.kubernetes.io/name: {{ include "payment-dashboard-web.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Volumes
*/}}
{{- define "payment-dashboard-web.volumes" -}}
{{- with .Values.customVolumes -}}
{{- toYaml . | default "" }}
{{ "" }}
{{- end -}}
- name: server-cert
{{- if .Values.mountServerCertFromSecret.enabled }}
  secret:
    secretName: {{ .Values.mountServerCertFromSecret.secretName }}
{{- if and .Values.mountServerCertFromSecret.certPath .Values.mountServerCertFromSecret.keyPath }}
    items:
      - path: {{ .Values.mountServerCertFromSecret.certPath }}
        key: {{ .Values.mountServerCertFromSecret.certPath }}
      - path: {{ .Values.mountServerCertFromSecret.keyPath }}
        key: {{ .Values.mountServerCertFromSecret.keyPath }}
{{- end }}
{{- else }}
  emptyDir:
    medium: "Memory"
{{- end }}
{{- end }}

{{/*
Mounts for payment-dashboard-web application
*/}}
{{- define "payment-dashboard-web.mounts" -}}
{{- with .Values.customMounts -}}
{{- toYaml . | default "" }}
{{ "" }}
{{- end -}}
{{- if .Values.mountServerCertFromSecret.enabled }}
- mountPath: /etc/nginx/host.key
  name: server-cert
{{- if .Values.mountServerCertFromSecret.keyPath }}
  subPath: {{ .Values.mountServerCertFromSecret.keyPath }}
{{- end }}
- mountPath: /etc/nginx/host.cert
  name: server-cert
{{- if .Values.mountServerCertFromSecret.certPath }}
  subPath: {{ .Values.mountServerCertFromSecret.certPath }}
{{- end }}
{{- else -}}
- mountPath: /etc/nginx/host.key
  name: server-cert
  subPath: key.pem
- mountPath: /etc/nginx/host.cert
  name: server-cert
  subPath: cert.pem
{{- end }}
{{- end }}
