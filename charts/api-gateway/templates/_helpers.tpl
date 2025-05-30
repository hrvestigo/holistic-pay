{{/*
Expand the name of the chart.
*/}}
{{- define "api-gateway.name" -}}
{{- default .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "api-gateway.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Trust store env variables
*/}}
{{- define "api-gateway.trustStoreEnv" -}}
{{- $trustStoreLocation := "/mnt/k8s/trust-store/" }}
{{- if .Values.mountTrustStoreFromSecret.enabled -}}
{{- $trustStoreName := required "Please specify trust store file name in mountTrustStoreFromSecret.trustStoreName" .Values.mountTrustStoreFromSecret.trustStoreName }}
{{- $trustStorePath := printf "%s%s" $trustStoreLocation $trustStoreName -}}
- name: JAVAX_NET_SSL_TRUST_STORE
  value: {{ $trustStorePath }}
- name: JAVAX_NET_SSL_TRUST_STORE_TYPE
  value: {{ .Values.mountTrustStoreFromSecret.trustStoreType }}
{{- if and .Values.secret.existingSecret (eq "NONE" .Values.secret.encryptionAlgorithm) }}
- name: JAVAX_NET_SSL_TRUST_STORE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secret.existingSecret }}
      key: truststore.password
{{- end }}
{{- else if .Values.mountCaFromSecret.enabled -}}
{{- $trustStorePath := printf "%s%s" $trustStoreLocation "cacerts" -}}
- name: JAVAX_NET_SSL_TRUST_STORE
  value: {{ $trustStorePath }}
- name: JAVAX_NET_SSL_TRUST_STORE_TYPE
  value: JKS
{{- end -}}
{{- end }}

{{/*
Key store env variables
*/}}
{{- define "api-gateway.keyStoreEnv" -}}
{{- $keyStoreLocation := "/mnt/k8s/key-store/" }}
{{- if .Values.mountKeyStoreFromSecret.enabled -}}
{{- $keyStoreName := required "Please specify key store file name in mountKeyStoreFromSecret.keyStoreName" .Values.mountKeyStoreFromSecret.keyStoreName }}
{{- $keyStorePath := printf "%s%s" $keyStoreLocation $keyStoreName -}}
- name: JAVAX_NET_SSL_KEY_STORE
  value: {{ $keyStorePath }}
- name: JAVAX_NET_SSL_KEY_STORE_TYPE
  value: {{ .Values.mountKeyStoreFromSecret.keyStoreType }}
{{- if and .Values.secret.existingSecret (eq "NONE" .Values.secret.encryptionAlgorithm) }}
- name: JAVAX_NET_SSL_KEY_STORE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secret.existingSecret }}
      key: keystore.password
{{- end }}
{{- end -}}
{{- end }}

{{/*
api-gateway image repository
*/}}
{{- define "api-gateway.app.repository" -}}
{{- if .Values.image.app.imageLocation }}
{{- .Values.image.app.imageLocation }}
{{- else }}
{{- $psRepo := "hrvestigo/api-gateway-ms" }}
{{- $reg := default .Values.image.registry .Values.image.app.registry }}
{{- if $reg }}
{{- printf "%s/%s" $reg $psRepo }}
{{- else }}
{{- $psRepo }}
{{- end }}
{{- end }}
{{- end }}

{{/*
api-gateway image pull policy
*/}}
{{- define "api-gateway.app.imagePullPolicy" -}}
{{- $reg := default .Values.image.pullPolicy .Values.image.app.pullPolicy }}
{{- default "IfNotPresent" $reg }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "api-gateway.labels" -}}
helm.sh/chart: {{ include "api-gateway.chart" . }}
app: {{ include "api-gateway.name" . }}
project: HolisticPay
{{ include "api-gateway.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "api-gateway.selectorLabels" -}}
app.kubernetes.io/name: {{ include "api-gateway.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}


{{/*
Volumes
*/}}
{{- define "api-gateway.volumes" -}}
{{- with .Values.customVolumes -}}
{{- toYaml . | default "" }}
{{ "" }}
{{- end -}}
{{- if ne "NONE" .Values.secret.encryptionAlgorithm }}
- name: {{ include "api-gateway.name" . }}-secret
  secret:
    secretName: {{ .Values.secret.existingSecret | default (printf "%s%s" (include "api-gateway.name" .) "-secret") }}
    items:
      - path: password.conf
        key: password.conf
{{- end }}
- name: {{ include "api-gateway.name" . }}-configmap
  configMap:
    name: {{ include "api-gateway.name" . }}-configmap
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
- name: truststore
{{- if .Values.mountTrustStoreFromSecret.enabled }}
  secret:
    secretName: {{ .Values.mountTrustStoreFromSecret.secretName }}
  {{- if .Values.mountTrustStoreFromSecret.trustStoreName }}
    items:
      - path: {{ .Values.mountTrustStoreFromSecret.trustStoreName }}
        key: {{ .Values.mountTrustStoreFromSecret.trustStoreName }}
  {{- end }}
{{- else }}
  emptyDir: {}
  {{- if .Values.mountCaFromSecret.enabled }}
- name: certs
  secret:
    secretName: {{ required "Secret name is required when mounting CA from secret, please specify in mountCaFromSecret.secretName" .Values.mountCaFromSecret.secretName }}
  {{- end }}
{{- end }}
- name: logdir
{{- if and .Values.logger.logDirMount.enabled .Values.logger.logDirMount.spec }}
{{- toYaml .Values.logger.logDirMount.spec | nindent 2 }}
{{- else }}
  emptyDir: {}
{{- end }}
- name: tmp
  emptyDir: {}
{{- end }}

{{/*
Mounts for api-gateway application
*/}}
{{- define "api-gateway.mounts" -}}
{{- with .Values.customMounts -}}
{{- toYaml . | default "" }}
{{ "" }}
{{- end -}}
{{- if ne "NONE" .Values.secret.encryptionAlgorithm }}
- mountPath: /mnt/k8s/secrets/
  name: {{ include "api-gateway.name" . }}-secret
{{- end }}
- mountPath: /opt/app/application.yaml
  name: {{ include "api-gateway.name" . }}-configmap
  subPath: application.yaml
- mountPath: /opt/app/log4j2.xml
  name: {{ include "api-gateway.name" . }}-configmap
  subPath: log4j2.xml
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
{{- if .Values.mountCaFromSecret.enabled }}
- mountPath: /mnt/k8s/client-certs
  name: certs
{{- end }}
- mountPath: /mnt/k8s/trust-store
  name: truststore
- mountPath: {{ .Values.logger.logDir }}
  name: logdir
- mountPath: /tmp
  name: tmp
{{- end }}

{{/*
Tracing configuration
*/}}
{{- define "api-gateway.tracing" -}}
{{- if .Values.tracing.enabled -}}
- name: MANAGEMENT_TRACING_ENABLED
  value: "true"
- name: MANAGEMENT_TRACING_SAMPLING_PROBABILITY
  value: {{ .Values.tracing.samplingProbability | quote }}
- name: MANAGEMENT_OTLP_TRACING_ENDPOINT
  value: {{ required "Please specify tracing endpoint in tracing.endpoint" .Values.tracing.endpoint  }}
{{- else }}
- name: MANAGEMENT_TRACING_ENABLED
  value: "false"
{{- end }}
{{- end }}

{{/*
Application secrets
*/}}
{{- define "api-gateway.passwords" -}}
{{ tpl (.Files.Get "config/password.conf") . | b64enc }}
{{- end }}

{{/*
Application logger
*/}}
{{- define "api-gateway.logger" -}}
{{ tpl (.Files.Get "config/log4j2.xml") . }}
{{- end }}

{{/*
Application configuration
*/}}
{{- define "api-gateway.appConfig" -}}
{{ tpl (.Files.Get "config/application.yaml") . }}
{{- end }}

{{/*
Create a comma separated list of endpoints that need to be exposed
*/}}
{{- define "api-gateway.exposed.endpoints" -}}
{{- $endpoints := list -}}
{{- $endpoints = append $endpoints (printf "%s" "health") }}
{{- if .Values.prometheus.exposed }}
{{- $endpoints = append $endpoints (printf "%s" "prometheus") }}
{{- end }}
{{- join "," $endpoints }}
{{- end }}
