{{/*
Expand the name of the chart.
*/}}
{{- define "address-parser.name" -}}
{{- default .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "address-parser.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
address-parser image repository
*/}}
{{- define "address-parser.app.repository" -}}
{{- if .Values.image.app.imageLocation }}
{{- .Values.image.app.imageLocation }}
{{- else }}
{{- $psRepo := "hrvestigo/address-parser-ms" }}
{{- $reg := default .Values.image.registry .Values.image.app.registry }}
{{- if $reg }}
{{- printf "%s/%s" $reg $psRepo }}
{{- else }}
{{- $psRepo }}
{{- end }}
{{- end }}
{{- end }}

{{/*
address-parser image pull policy
*/}}
{{- define "address-parser.app.imagePullPolicy" -}}
{{- $reg := default .Values.image.pullPolicy .Values.image.app.pullPolicy }}
{{- default "IfNotPresent" $reg }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "address-parser.labels" -}}
helm.sh/chart: {{ include "address-parser.chart" . }}
app: {{ include "address-parser.name" . }}
project: HolisticPay
{{ include "address-parser.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "address-parser.selectorLabels" -}}
app.kubernetes.io/name: {{ include "address-parser.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Volumes
*/}}
{{- define "address-parser.volumes" -}}
{{- with .Values.customVolumes }}
{{- toYaml . | default "" }}
{{- end }}
- name: {{ include "address-parser.name" . }}-secret
  secret:
    secretName: {{ .Values.secret.existingSecret | default (printf "%s%s" (include "address-parser.name" .) "-secret") }}
    items:
      - path: password.conf
        key: password.conf
- name: {{ include "address-parser.name" . }}-configmap
  configMap:
    name: {{ include "address-parser.name" . }}-configmap
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
{{- if .Values.mountKeyStoreFromSecret.enabled }}
- name: keystore
  secret:
    secretName: {{ .Values.mountKeyStoreFromSecret.secretName }}
{{- if .Values.mountKeyStoreFromSecret.keyStoreName }}
    items:
      - path: {{ .Values.mountKeyStoreFromSecret.keyStoreName }}
        key: {{ .Values.mountKeyStoreFromSecret.keyStoreName }}
{{- end }}
{{- end }}
{{- if .Values.mountTrustStoreFromSecret.enabled }}
- name: truststore
  secret:
    secretName: {{ .Values.mountTrustStoreFromSecret.secretName }}
{{- if .Values.mountTrustStoreFromSecret.trustStoreName }}
    items:
      - path: {{ .Values.mountTrustStoreFromSecret.trustStoreName }}
        key: {{ .Values.mountTrustStoreFromSecret.trustStoreName }}
{{- end }}
{{- else if .Values.mountCaFromSecret.enabled }}
- name: truststore
  secret:
    secretName: {{ required "Secret name is required when mounting CA from secret, please specify in mountCaFromSecret.secretName" .Values.mountCaFromSecret.secretName }}
{{- end }}
{{- if and .Values.logger.logDirMount.enabled .Values.logger.logDirMount.spec }}
- name: logdir
{{- toYaml .Values.logger.logDirMount.spec | nindent 2 }}
{{- end }}
{{- if .Values.libpostal.dataDir }}
- name: libpostal-data
{{- if and .Values.volumeProvisioning (not .Values.volumeProvisioning.dynamic) ((((.Values.volumeProvisioning).storage).parameters).type).nfs }}
  nfs:
    server: {{ .Values.volumeProvisioning.storage.parameters.type.nfs.server }}
    path: {{ .Values.volumeProvisioning.storage.parameters.type.nfs.path }}
{{- else }}
  hostPath:
    path: {{ .Values.libpostal.dataDir }}
    type: Directory
{{- end }}
{{- end }}
{{- end }}
{{- define "address-parser.mounts" -}}
{{with .Values.customMounts -}}
{{- toYaml . | default "" }}
{{ "" }}
{{- end -}}
- mountPath: /mnt/k8s/secrets/
  name: {{ include "address-parser.name" . }}-secret
- mountPath: /usr/app/config
  name: {{ include "address-parser.name" . }}-configmap
{{- if .Values.mountServerCertFromSecret.enabled }}
- mountPath: /mnt/k8s/tls-server/key.pem
  name: server-cert
{{- if .Values.mountServerCertFromSecret.keyPath }}
  subPath: {{ .Values.mountServerCertFromSecret.keyPath }}
{{- end }}
- mountPath: /mnt/k8s/tls-server/cert.pem
  name: server-cert
{{- if .Values.mountServerCertFromSecret.certPath }}
  subPath: {{ .Values.mountServerCertFromSecret.certPath }}
{{- end }}
{{- else }}
- mountPath: /mnt/k8s/tls-server
  name: server-cert
{{- end }}
{{- if .Values.mountKeyStoreFromSecret.enabled }}
- mountPath: /mnt/k8s/key-store
  name: keystore
{{- end }}
{{- if .Values.mountTrustStoreFromSecret.enabled }}
- mountPath: /mnt/k8s/trust-store
  name: truststore
{{- else if .Values.mountCaFromSecret.enabled }}
- mountPath: /mnt/k8s/client-certs
  name: truststore
{{- end }}
{{- if and .Values.logger.logDirMount.enabled .Values.logger.logDirMount.spec }}
- mountPath: {{ .Values.logger.logDir }}
  name: logdir
{{- end }}
{{- if .Values.libpostal.dataDir }}
- mountPath: {{ .Values.libpostal.dataDir }}
  name: libpostal-data
  readOnly: true
{{- end }}
{{- end }}
{{- define "address-parser.passwords" -}}
{{ tpl (.Files.Get "config/password.conf") . | b64enc }}
{{- end }}

{{/*
Application logger
*/}}
{{- define "address-parser.logger" -}}
{{ tpl (.Files.Get "config/log4j2.xml") . }}
{{- end }}

{{/*
Create a comma separated list of endpoints that need to be exposed
*/}}
{{- define "address-parser.exposed.endpoints" -}}
{{- $endpoints := list -}}
{{- $endpoints = append $endpoints (printf "%s" "health") }}
{{- if .Values.prometheus.exposed }}
{{- $endpoints = append $endpoints (printf "%s" "prometheus") }}
{{- end }}
{{- join "," $endpoints }}
{{- end }}

{{/*
Address parser metrics configuration
*/}}
{{- define "address-parser.metrics.config" -}}
{{- range $key, $value := .Values.metrics }}
- name: MANAGEMENT_METRICS_ENABLE_{{ $key | toString | snakecase | upper }}
  value: {{ $value | toString | quote }}
{{- end }}
{{- end }}
