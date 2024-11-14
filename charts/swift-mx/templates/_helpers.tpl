{{/*
Expand the name of the chart.
*/}}
{{- define "swift-mx.name" -}}
{{- default .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "swift-mx.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Defies fixed part of swift-mx datasource schema name
*/}}
{{- define "swift-mx.dbSchema" -}}
{{- "swiftx" }}
{{- end }}

{{/*
swift-mx image repository
*/}}
{{- define "swift-mx.app.repository" -}}
{{- if .Values.image.app.imageLocation }}
{{- .Values.image.app.imageLocation }}
{{- else }}
{{- $psRepo := "hrvestigo/swift-mx-ms" }}
{{- $reg := default .Values.image.registry .Values.image.app.registry }}
{{- if $reg }}
{{- printf "%s/%s" $reg $psRepo }}
{{- else }}
{{- $psRepo }}
{{- end }}
{{- end }}
{{- end }}

{{/*
swift-mx image pull policy
*/}}
{{- define "swift-mx.app.imagePullPolicy" -}}
{{- $reg := default .Values.image.pullPolicy .Values.image.app.pullPolicy }}
{{- default "IfNotPresent" $reg }}
{{- end }}

{{/*
Liquibase image
*/}}
{{- define "swift-mx.liquibase.image" }}
{{- if .Values.image.liquibase.imageLocation }}
{{- printf "%s:%s" .Values.image.liquibase.imageLocation .Values.image.liquibase.tag }}
{{- else }}
{{- $liquiRepo := "hrvestigo/swift-mx-lb" }}
{{- $reg := default $.Values.image.registry $.Values.image.liquibase.registry }}
{{- if $reg }}
{{- printf "%s/%s" $reg $liquiRepo }}
{{- else }}
{{- $liquiRepo }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Liquibase init container definition
*/}}
{{- define "swift-mx.liquibase.initContainer" }}
{{- range $k, $member := .Values.members }}
- name: liquibase-{{ .memberSign | lower }}
  securityContext:
  {{- toYaml $.Values.securityContext | nindent 4 }}
  {{- if $.Values.image.liquibase.imageLocation }}
  image: {{ include "swift-mx.liquibase.image" $ }}
  {{- else }}
  image: {{ printf "%s%s%s%s%s" (include "swift-mx.liquibase.image" $) "-" ($member.businessUnit | lower ) ":" $.Values.image.liquibase.tag }}
  {{- end }}
  imagePullPolicy: {{ default "IfNotPresent" (default $.Values.image.pullPolicy $.Values.image.liquibase.pullPolicy) }}
  resources:
    {{- include "swift-mx.liquibase.initContainer.resources" $ | nindent 4 }}
  volumeMounts:
    - mountPath: /liquibase/secret/
      name: {{ include "swift-mx.name" $ }}-secret
  env:
    - name: SCHEMA_NAME
  {{- if $member.datasource }}
    {{- if $member.datasource.globalSchema }}
      value: {{ $member.businessUnit | lower }}{{ required "Please specify global schema prefix in datasource.globalSchemaPrefix" $.Values.datasource.globalSchemaPrefix }}{{ include "swift-mx.dbSchema" $ }}{{ required "Please specify environment label in env.label" $.Values.env.label | lower }}
    {{- else }}
      value: {{ $member.businessUnit | lower }}{{ $member.applicationMember | lower }}{{ include "swift-mx.dbSchema" $ }}{{ required "Please specify environment label in env.label" $.Values.env.label | lower }}
    {{- end }}
  {{- else }}
      value: {{ $member.businessUnit | lower }}{{ $member.applicationMember | lower }}{{ include "swift-mx.dbSchema" $ }}{{ required "Please specify environment label in env.label" $.Values.env.label | lower }}
  {{- end }}
  {{- if $member.liquibase }}
    - name: ROLE
      value: {{ default (required "Please specify database role in liquibase.role or override with member-specific members.liquibase.role" $.Values.liquibase.role) $member.liquibase.role }}
    - name: REPLICATION_ROLE
      value: {{ default (required "Please specify database replication role in liquibase.replicationRole or override with member-specific members.liquibase.replicationRole" $.Values.liquibase.replicationRole) $member.liquibase.replicationRole }}
  {{- else }}
    - name: ROLE
      value: {{ required "Please specify database role in liquibase.role or override with member-specific members.liquibase.role" $.Values.liquibase.role }}
    - name: REPLICATION_ROLE
      value: {{ required "Please specify database replication role in liquibase.replicationRole or override with member-specific members.liquibase.replicationRole" $.Values.liquibase.replicationRole }}
  {{- end }}
  command:
    - bash
    - -c
  {{- if $member.datasource }}
    {{- $url := printf "%s%s%s%d%s%s" "jdbc:postgresql://" (default $.Values.datasource.host $member.datasource.host) ":" (default ($.Values.datasource.port | int) ( $member.datasource.port | int)) "/" (default $.Values.datasource.dbName  $member.datasource.dbName) }}
    {{- $context := printf "%s%s%s%s%s" ( required "Please specify business unit in members.businessUnit" $member.businessUnit | upper ) ( required "Please specify application member in members.applicationMember" $member.applicationMember | upper ) ",test" (ternary ",event-log" "" $.Values.application.data.eventsLog.enabled) (ternary ",partitions" "" $.Values.application.data.eventsLog.partitionsEnabled) }}
    {{- $params := printf "%s%s%s%s%s%s" "cp /liquibase/changelog/liquibase.properties /tmp && java -jar /tmp/aesdecryptor.jar -d -l && /liquibase/docker-entrypoint.sh --defaultsFile=/tmp/liquibase.properties --url=" $url " --contexts=" $context " --username=" $.Values.liquibase.user }}
    {{- if $.Values.liquibase.syncOnly }}
    - {{ printf "%s%s" $params " changelog-sync" }}
    {{- else }}
    - {{ printf "%s%s" $params " update" }}
    {{- end }}
  {{- else }}
    {{- $url := printf "%s%s%s%d%s%s" "jdbc:postgresql://" $.Values.datasource.host ":" ($.Values.datasource.port | int) "/" $.Values.datasource.dbName }}
    {{- $context := printf "%s%s%s%s%s" ( required "Please specify business unit in members.businessUnit" $member.businessUnit | upper ) ( required "Please specify application member in members.applicationMember" $member.applicationMember | upper ) ",test" (ternary ",event-log" "" $.Values.application.data.eventsLog.enabled) (ternary ",partitions" "" $.Values.application.database.eventsLog.partitionsEnabled) }}
    {{- $params := printf "%s%s%s%s%s%s" "cp /liquibase/changelog/liquibase.properties /tmp && java -jar /tmp/aesdecryptor.jar -d -l && /liquibase/docker-entrypoint.sh --defaultsFile=/tmp/liquibase.properties --url=" $url " --contexts=" $context " --username=" $.Values.liquibase.user }}
    {{- if $.Values.liquibase.syncOnly }}
    - {{ printf "%s%s" $params " changelog-sync" }}
    {{- else }}
    - {{ printf "%s%s" $params " update" }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Liquibase init container resources
*/}}
{{- define "swift-mx.liquibase.initContainer.resources" -}}
{{- if .Values.liquibase.resources }}
{{- toYaml .Values.liquibase.resources }}
{{- else }}
{{- toYaml .Values.resources }}
{{- end }}
{{- end }}

{{/*
Trust store env variables
*/}}
{{- define "swift-mx.trustStoreEnv" -}}
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
{{- define "swift-mx.labels" -}}
helm.sh/chart: {{ include "swift-mx.chart" . }}
app: {{ include "swift-mx.name" . }}
project: HolisticPay
{{ include "swift-mx.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "swift-mx.selectorLabels" -}}
app.kubernetes.io/name: {{ include "swift-mx.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Volumes
*/}}
{{- define "swift-mx.volumes" -}}
{{- if .Values.application.integration.file.readEnabled }}
- name: in
{{- with .Values.application.integration.file.readVolumeParameters -}}
{{- toYaml . | default "" | nindent 2 -}}
{{ "" }}
{{- end }}
{{- end }}
{{- if .Values.application.integration.file.writeEnabled }}
- name: out
{{- with .Values.application.integration.file.writeVolumeParameters -}}
{{- toYaml . | default "" | nindent 2 -}}
{{ "" }}
{{- end }}
{{- end }}
{{with .Values.customVolumes -}}
{{- toYaml . | default "" }}
{{ "" }}
{{- end -}}
- name: {{ include "swift-mx.name" . }}-secret
  secret:
    secretName: {{ include "swift-mx.name" . }}-secret
    items:
      - path: password.conf
        key: password.conf
- name: {{ include "swift-mx.name" . }}-configmap
  configMap:
    name: {{ include "swift-mx.name" . }}-configmap
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
{{- end }}

{{/*
Mounts for swift-mx application
*/}}
{{- define "swift-mx.mounts" -}}
{{- if .Values.application.integration.file.readEnabled }}
- name: in
  mountPath: /swiftx/in
{{- end }}
{{- if .Values.application.integration.file.writeEnabled }}
- name: out
  mountPath: /swiftx/out
{{- end }}
{{with .Values.customMounts -}}
{{- toYaml . | default "" }}
{{ "" }}
{{- end -}}
- mountPath: /mnt/k8s/secrets/
  name: {{ include "swift-mx.name" . }}-secret
- mountPath: /usr/app/config
  name: {{ include "swift-mx.name" . }}-configmap
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
{{- end }}

{{/*
Definition of application members
*/}}
{{- define "swift-mx.members" -}}
{{- $members := list -}}
{{- range $k, $member := .Values.members }}
{{- $members = append $members $member.memberSign }}
{{- end }}
{{- join "," $members }}
{{- end }}

{{/*
Application secrets
*/}}
{{- define "swift-mx.passwords" -}}
{{ tpl (.Files.Get "config/password.conf") . | b64enc }}
{{- end }}

{{/*
Application logger
*/}}
{{- define "swift-mx.logger" -}}
{{ tpl (.Files.Get "config/log4j2.xml") . }}
{{- end }}

{{/*
Defines custom datasource connection parameters appended to URL
*/}}
{{- define "swift-mx.db.connectionParams" -}}
{{- $atts := list -}}
{{- range $key, $value := .Values.datasource.connectionParams }}
{{- $atts = append $atts (printf "%s%s%s" $key "=" $value) }}
{{- end }}
{{- $string := join "&" $atts }}
{{- if $string }}
{{- printf "%s%s" "&" $string }}
{{- else }}
{{- "" }}
{{- end }}
{{- end }}

{{/*
Swift mx Kafka topics configuration
*/}}
{{- define "swift-mx.kafka.topics" }}
{{- range $key, $value := .Values.kafka.topics }}
{{- range $k, $v := $value }}
- name: SWIFT_MX_KAFKA_TOPICS_{{ $key | upper }}_{{ $k | snakecase | upper }}
  value: {{ $v | quote }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Swift mx application configuration.
Iterates over configuration per application module/components.
Each module/component has configuration per named key.
Final configuration name is SWIFT_MX_<module>_<moduleKey>_<name>=<value>,
where 'name' is configuration parameter and 'value' is configuration value
*/}}
{{- define "swift-mx.application.config" }}
{{- range $module, $configs := .Values.application }}
{{- range $moduleKey, $config := $configs }}
{{- range $name, $value := $config }}
- name: SWIFT_MX_{{ $module | upper }}_{{ $moduleKey | upper }}_{{ $name | snakecase | upper }}
  value: {{ $value | quote }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create a comma separated list of endpoints that need to be exposed
*/}}
{{- define "swift-mx.exposed.endpoints" -}}
{{- $endpoints := list -}}
{{- $endpoints = append $endpoints (printf "%s" "health") }}
{{- if .Values.prometheus.exposed }}
{{- $endpoints = append $endpoints (printf "%s" "prometheus") }}
{{- end }}
{{- join "," $endpoints }}
{{- end }}