{{/*
Expand the name of the chart.
*/}}
{{- define "alc-collect.name" -}}
{{- default .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "alc-collect.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Liquibase image repository
*/}}
{{- define "alc-collect.liquibase.repository" -}}
{{- $liquiRepo := "liquibase/liquibase:4.9.1" }}
{{- $reg := default .Values.image.registry .Values.image.liquibase.registry }}
{{- if $reg }}
{{- printf "%s/%s" $reg $liquiRepo }}
{{- else }}
{{- $liquiRepo }}
{{- end }}
{{- end }}

{{/*
Liquibase image pull policy
*/}}
{{- define "alc-collect.liquibase.imagePullPolicy" -}}
{{- $reg := default .Values.image.pullPolicy .Values.image.liquibase.pullPolicy }}
{{- default "IfNotPresent" $reg }}
{{- end }}

{{/*
alc-collect image repository
*/}}
{{- define "alc-collect.app.repository" -}}
{{- $psRepo := "hrvestigo/alc-collect-ms" }}
{{- $reg := default .Values.image.registry .Values.image.app.registry }}
{{- if $reg }}
{{- printf "%s/%s" $reg $psRepo }}
{{- else }}
{{- $psRepo }}
{{- end }}
{{- end }}

{{/*
alc-collect image pull policy
*/}}
{{- define "alc-collect.app.imagePullPolicy" -}}
{{- $reg := default .Values.image.pullPolicy .Values.image.app.pullPolicy }}
{{- default "IfNotPresent" $reg }}
{{- end }}

{{/*
Liquibase run command
*/}}
{{- define "alc-collect.liquibase.command" -}}
{{- if .Values.enableLiquibase }}
{{- $secretFileName := required "Liquibase secret file name is required, please specify in secret.liquibase.secret.fileName" .Values.secret.liquibase.secret.fileName }}
{{- $secretFile := printf "%s%s" "/liquibase/secret/" $secretFileName }}
{{- $lsm := printf "%s%s%s" "cp /liquibase/changelog/liquibase.properties /tmp && sed -i \"s/__LIQUIBASE_PASSWORD__/$(cat " $secretFile ")/g\" /tmp/liquibase.properties && " }}
{{- $cmd := "/liquibase/docker-entrypoint.sh --changeLogFile=changelog.yaml --defaultsFile=/tmp/liquibase.properties --classpath=/liquibase/changelog:lib/postgresql-42.3.2.jar update" }}
{{- printf "%s%s" $lsm $cmd }}
{{- end }}
{{- end }}

{{/*
Trust store env variables
*/}}
{{- define "alc-collect.trustStoreEnv" -}}
{{- $trustStoreLocation := "/mnt/k8s/trust-store/" }}
{{- if .Values.mountTrustStoreFromSecret.enabled -}}
{{- $trustStoreName := required "Please specify trust store file name in mountTrustStoreFromSecret.trustStoreName" .Values.mountTrustStoreFromSecret.trustStoreName }}
{{- $trustStorePath := printf "%s%s" $trustStoreLocation $trustStoreName -}}
- name: SPRING_KAFKA_PROPERTIES_SSL_TRUSTSTORE_TYPE
  value: {{ required "Please specify trust store type in mountTrustStoreFromSecret.trustStoreType" .Values.mountTrustStoreFromSecret.trustStoreType }}
- name: SPRING_KAFKA_PROPERTIES_SSL_TRUSTSTORE_LOCATION
  value: {{ $trustStorePath }}
- name: SSL_TRUST_STORE_FILE
  value: {{ $trustStorePath }}
- name: JAVAX_NET_SSL_TRUST_STORE
  value: {{ $trustStorePath }}
{{- else if .Values.mountCaFromSecret.enabled -}}
{{- $trustStorePath := printf "%s%s" $trustStoreLocation "cacerts" -}}
- name: SPRING_KAFKA_PROPERTIES_SSL_TRUSTSTORE_LOCATION
  value: {{ $trustStorePath }}
- name: SSL_TRUST_STORE_FILE
  value: {{ $trustStorePath }}
- name: JAVAX_NET_SSL_TRUST_STORE
  value: {{ $trustStorePath }}
{{- end -}}
{{- end }}

{{/*
Common labels
*/}}
{{- define "alc-collect.labels" -}}
helm.sh/chart: {{ include "alc-collect.chart" . }}
app: {{ include "alc-collect.name" . }}
project: HolisticPay
{{ include "alc-collect.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "alc-collect.selectorLabels" -}}
app.kubernetes.io/name: {{ include "alc-collect.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Volumes
*/}}
{{- define "alc-collect.volumes" -}}
{{- with .Values.customVolumes -}}
{{- toYaml . | default "" }}
{{ "" }}
{{- end -}}
- name: {{ include "alc-collect.name" . }}-secret
  secret:
    secretName: {{ include "alc-collect.name" . }}-secret
    items:
      - path: password.conf
        key: password.conf
- name: {{ include "alc-collect.name" . }}-configmap
  configMap:
    name: {{ include "alc-collect.name" . }}-configmap
- name: liquibase-config
  configMap:
    name: {{ include "alc-collect.name" . }}-liquibase-configmap
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
{{- if .Values.enableLiquibase }}
- name: liquibase-secret
  secret:
    secretName: {{ required "Liquibase secret name is required, please specify in secret.liquibase.secret.secretName" .Values.secret.liquibase.secret.secretName }}
{{- if .Values.secret.liquibase.secret.fileName }}
    items:
      - path: {{ .Values.secret.liquibase.secret.fileName }}
        key: {{ .Values.secret.liquibase.secret.fileName }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Mounts for alc-collect application
*/}}
{{- define "alc-collect.mounts" -}}
{{- with .Values.customMounts -}}
{{- toYaml . | default "" }}
{{ "" }}
{{- end -}}
- mountPath: /mnt/k8s/secrets/
  name: {{ include "alc-collect.name" . }}-secret
- mountPath: /usr/app/config
  name: {{ include "alc-collect.name" . }}-configmap
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
{{- end}}
{{- end }}

{{/*
Application secrets
*/}}
{{- define "alc-collect.passwords" -}}
{{ tpl (.Files.Get "config/password.conf") . | b64enc }}
{{- end }}

{{/*
Application logger
*/}}
{{- define "alc-collect.logger" -}}
{{ tpl (.Files.Get "config/log4j2.xml") . }}
{{- end }}

{{/*
Liquibase changelog
*/}}
{{- define "alc-collect.changelog" -}}
{{ tpl (.Files.Get "config/liquibase/db.changelog-master.yaml") . }}
{{- end }}

{{/*
Liquibase changelog
*/}}
{{- define "alc-collect.liquibase-config" -}}
{{ tpl (.Files.Get "config/liquibase/liquibase.properties") . }}
{{- end }}
