  value: {{ .Values.grpc.personStructureData.negotiationType | default (.Values.grpc.negotiation | default "TLS") | quote }}
{{/*
  gRPC environment variables
*/}}
{{- define "consumer-finance.env.grpc" }}

- name: SPRING_GRPC_CLIENT_CHANNELS_PERSONSTRUCTUREDATA_ADDRESS
  value: {{ required "Please specify address for person structure gRPC server in spring.grpc.client.channels.personStructureData.address" .Values.spring.grpc.client.channels.personStructureData.address | quote }}
- name: SPRING_GRPC_CLIENT_CHANNELS_PERSONSTRUCTUREDATA_NEGOTIATION_TYPE
  value: {{ .Values.spring.grpc.client.channels.personStructureData.negotiationType | default (.Values.spring.grpc.client.negotiation | default "TLS") | quote }}
- name: GRPC_PERSONSTRUCTUREDATA_TIMEOUT
  value: {{ .Values.grpc.personStructureData.timeout | default "10000" | quote }}

- name: SPRING_GRPC_CLIENT_CHANNELS_GETLIMITBUCKETS_ADDRESS
  value: {{ .Values.spring.grpc.client.channels.getLimitBuckets.address | quote }}
- name: SPRING_GRPC_CLIENT_CHANNELS_GETLIMITBUCKETS_NEGOTIATION_TYPE
  value: {{ .Values.spring.grpc.client.negotiation | default "TLS" | quote }}
- name: GRPC_GETLIMITBUCKETS_TIMEOUT
  value: {{ .Values.grpc.getLimitBuckets.timeout | default "10000" | quote }}

- name: SPRING_GRPC_CLIENT_CHANNELS_UPDATELIMITBUCKETS_ADDRESS
  value: {{ .Values.spring.grpc.client.channels.updateLimitBuckets.address | quote }}
- name: SPRING_GRPC_CLIENT_CHANNELS_UPDATELIMITBUCKETS_NEGOTIATION_TYPE
  value: {{ .Values.spring.grpc.client.negotiation | default "TLS" | quote }}
- name: GRPC_UPDATELIMITBUCKETS_TIMEOUT
  value: {{ .Values.grpc.updateLimitBuckets.timeout | default "10000" | quote }}

- name: SPRING_GRPC_CLIENT_CHANNELS_GETPRICINGENGINE_ADDRESS
  value: {{ .Values.spring.grpc.client.channels.getPricingEngine.address | quote }}
- name: SPRING_GRPC_CLIENT_CHANNELS_GETPRICINGENGINE_NEGOTIATION_TYPE
  value: {{ .Values.spring.grpc.client.negotiation | default "TLS" | quote }}
- name: GRPC_GETPRICINGENGINE_TIMEOUT
  value: {{ .Values.grpc.getPricingEngine.timeout | default "10000" | quote }}

- name: SPRING_GRPC_WARMUP_REPEAT
  value: {{ .Values.spring.grpc.client.warmup.repeat | default "10" | quote }}
{{- end }}

{{/*
  REST API environment variables
*/}}
{{- define "consumer-finance.env.rest" }}
- name: REST_API_FEEPRICINGENGINE_HOST
  value: {{ required "Please specify rest.api.feePricingEngine.host" .Values.rest.api.feePricingEngine.host | quote }}
- name: REST_API_FEEPRICINGENGINE_ENDPOINT
  value: {{ required "Please specify rest.api.feePricingEngine.endpoint" .Values.rest.api.feePricingEngine.endpoint | quote }}
- name: REST_API_FEEPRICINGENGINE_TIMEOUT
  value: {{ .Values.rest.api.feePricingEngine.timeout | default "10000" | quote }}
{{- if or (eq (.Values.limitBuckets.client.default | default "mocklimitbuckets") "authlimitcontrol") (eq (.Values.limitBuckets.client.cf | default "") "authlimitcontrol") (eq (.Values.limitBuckets.client.cc | default "") "authlimitcontrol") (eq (.Values.limitBuckets.client.rb | default "") "authlimitcontrol") }}
- name: REST_API_AUTHCONTROL_GETLIMITBUCKETS_HOST
  value: {{ required "Please specify rest.api.authControl.getLimitBuckets.host" .Values.rest.api.authControl.getLimitBuckets.host | quote }}
- name: REST_API_AUTHCONTROL_GETLIMITBUCKETS_ENDPOINT
  value: {{ required "Please specify rest.api.authControl.getLimitBuckets.endpoint" .Values.rest.api.authControl.getLimitBuckets.endpoint | quote }}
- name: REST_API_AUTHCONTROL_TIMEOUT
  value: {{ .Values.rest.api.authControl.timeout | default "10000" | quote }}
{{- end }}
{{- if or (eq (.Values.limitBuckets.update.client.default | default "mockupdatelimitbuckets") "authlimitcontrolupdate") (eq (.Values.limitBuckets.update.client.cf | default "") "authlimitcontrolupdate") (eq (.Values.limitBuckets.update.client.cc | default "") "authlimitcontrolupdate") (eq (.Values.limitBuckets.update.client.rb | default "") "authlimitcontrolupdate") }}
- name: REST_API_AUTHCONTROL_UPDATELIMITBUCKETS_HOST
  value: {{ required "Please specify rest.api.authControl.updateLimitBuckets.host" .Values.rest.api.authControl.updateLimitBuckets.host | quote }}
- name: REST_API_AUTHCONTROL_UPDATELIMITBUCKETS_ENDPOINT
  value: {{ required "Please specify rest.api.authControl.updateLimitBuckets.endpoint" .Values.rest.api.authControl.updateLimitBuckets.endpoint | quote }}
{{- end }}
{{- end }}

{{/*
  Kafka topics and consumer group environment variables
*/}}
{{- define "consumer-finance.env.kafka-topics" }}
- name: KAFKA_TOPIC_LIMITBUCKETCOMPENSATION_NAME
  value: {{ .Values.kafka.topics.limitbucketcompensation.name | quote }}
{{- if .Values.listener.dueinstalment.enabled }}
- name: KAFKA_TOPIC_DUEINSTALMENT_NAME
  value: {{ .Values.kafka.topics.dueinstalment.name | quote }}
- name: KAFKA_CONSUMER_GROUP_DUEINSTALMENT_NAME
  value: {{ .Values.kafka.topics.dueinstalment.consumerGroup | quote }}
{{- end }}
- name: KAFKA_TOPIC_NOTIFICATION_NAME
  value: {{ .Values.kafka.topics.notification.name | quote }}
- name: KAFKA_CONSUMER_GROUP_NOTIFICATION_NAME
  value: {{ .Values.kafka.topics.notification.consumerGroup | quote }}
{{- if .Values.listener.authtransaction.enabled }}
- name: KAFKA_TOPIC_AUTHTRANSACTION_NAME
  value: {{ .Values.kafka.topics.authtransaction.name | quote }}
- name: KAFKA_CONSUMER_GROUP_AUTHTRANSACTION_NAME
  value: {{ .Values.kafka.topics.authtransaction.consumerGroup | quote }}
- name: KAFKA_TOPIC_AUTHTRANSACTION_RETRY_MAXATTEMPTS
  value: {{ .Values.kafka.topics.authtransaction.retry.maxAttempts | quote }}
- name: KAFKA_TOPIC_AUTHTRANSACTION_RETRY_DELAY
  value: {{ .Values.kafka.topics.authtransaction.retry.delay | quote }}
{{- end }}
{{- if .Values.listener.crdauthtrxmatch.enabled }}
- name: KAFKA_TOPIC_CRDAUTHTRXMATCH_NAME
  value: {{ .Values.kafka.topics.crdauthtrxmatch.name | quote }}
- name: KAFKA_CONSUMER_GROUP_CRDAUTHTRXMATCH_NAME
  value: {{ .Values.kafka.topics.crdauthtrxmatch.consumerGroup | quote }}
- name: KAFKA_TOPIC_CRDAUTHTRXMATCH_RETRY_MAXATTEMPTS
  value: {{ .Values.kafka.topics.crdauthtrxmatch.retry.maxAttempts | quote }}
{{- end }}
{{- if .Values.listener.instalmentoffer.enabled }}
- name: KAFKA_TOPIC_INSTALMENTOFFER_NAME
  value: {{ .Values.kafka.topics.instalmentoffer.name | quote }}
- name: KAFKA_TOPIC_SYSINSTALMENTOFFER_NAME
  value: {{ .Values.kafka.topics.sysInstalmentOffer.name | quote }}
- name: KAFKA_CONSUMER_GROUP_INSTALMENTOFFER_NAME
  value: {{ .Values.kafka.topics.instalmentoffer.consumerGroup | quote }}
{{- end }}
{{- if .Values.listener.instalmentofferresponse.enabled }}
- name: KAFKA_TOPIC_INSTALMENTOFFERRESPONSE_NAME
  value: {{ .Values.kafka.topics.instalmentofferresponse.name | quote }}
- name: KAFKA_TOPIC_SYSINSTALMENTOFFERRESPONSE_NAME
  value: {{ .Values.kafka.topics.sysinstalmentofferresponse.name | quote }}
- name: KAFKA_CONSUMER_GROUP_INSTALMENTOFFERRESPONSE_NAME
  value: {{ .Values.kafka.topics.instalmentofferresponse.consumerGroup | quote }}
{{- end }}
{{- if .Values.listener.extsysresponse.enabled }}
- name: KAFKA_TOPIC_EXTSYSRESPONSE_NAME
  value: {{ .Values.kafka.topics.extsysresponse.name | quote }}
- name: KAFKA_CONSUMER_GROUP_EXTSYSRESPONSE_NAME
  value: {{ .Values.kafka.topics.extsysresponse.consumerGroup | quote }}
- name: KAFKA_TOPIC_EXTSYSRESPONSE_RETRY_MAXATTEMPTS
  value: {{ .Values.kafka.topics.extsysresponse.retry.maxAttempts | quote }}
- name: KAFKA_TOPIC_EXTSYSRESPONSE_RETRY_DELAY
  value: {{ .Values.kafka.topics.extsysresponse.retry.delay | quote }}
{{- end }}
- name: KAFKA_TOPIC_CONSUMERFINANCELOANEVENT_NAME
  value: {{ .Values.kafka.topics.consumerfinanceloanevent.name | quote }}
{{- if .Values.listener.parameterization.enabled }}
- name: KAFKA_TOPIC_PARAMETERIZATION_NAME
  value: {{ .Values.kafka.topics.parameterization.name | quote }}
- name: KAFKA_CONSUMER_GROUP_CURRENCY_PARAMETERIZATION_NAME
  value: {{ .Values.kafka.topics.parameterization.currency.consumerGroup | quote }}
- name: KAFKA_CONSUMER_GROUP_COUNTRY_PARAMETERIZATION_NAME
  value: {{ .Values.kafka.topics.parameterization.country.consumerGroup | quote }}
{{- end }}
- name: LISTENER_PARAMETERIZATION_ENABLED
  value: {{ required "Please specify listener.parameterization.enabled" .Values.listener.parameterization.enabled | toString | quote }}
- name: LISTENER_DUEINSTALMENT_ENABLED
  value: {{ required "Please specify listener.dueinstalment.enabled" .Values.listener.dueinstalment.enabled | toString | quote }}
- name: LISTENER_CRDAUTHTRXMATCH_ENABLED
  value: {{ required "Please specify listener.crdauthtrxmatch.enabled" .Values.listener.crdauthtrxmatch.enabled | toString | quote }}
- name: LISTENER_INSTALMENTOFFER_ENABLED
  value: {{ required "Please specify listener.instalmentoffer.enabled" .Values.listener.instalmentoffer.enabled | toString | quote }}
- name: LISTENER_INSTALMENTOFFERRESPONSE_ENABLED
  value: {{ required "Please specify listener.instalmentofferresponse.enabled" .Values.listener.instalmentofferresponse.enabled | toString | quote }}
- name: LISTENER_EXTSYSRESPONSE_ENABLED
  value: {{ required "Please specify listener.extsysresponse.enabled" .Values.listener.extsysresponse.enabled | toString | quote }}
- name: LISTENER_AUTHTRANSACTION_ENABLED
  value: {{ required "Please specify listener.authtransaction.enabled" .Values.listener.authtransaction.enabled | toString | quote }}
{{- end }}

{{/*
  Scheduled task environment variables
*/}}
{{- define "consumer-finance.env.scheduled-task" }}
- name: SCHEDULED_TASK_CONFIN_INSTALMENTSENDING_ENABLED
  value: {{ .Values.scheduleTask.instalmentSending.enabled | quote }}
- name: SCHEDULED_TASK_CONFIN_INSTALMENTSENDING_CRON
  value: {{ if .Values.scheduleTask.instalmentSending.enabled }}{{ required "Please specify scheduleTask.instalmentSending.cron" .Values.scheduleTask.instalmentSending.cron | quote }}{{ else }}"-"{{ end }}
- name: SCHEDULED_TASK_CONFIN_INSTALMENTNOTIFICATION_ENABLED
  value: {{ .Values.scheduleTask.instalmentNotification.enabled | default "false" | quote }}
- name: SCHEDULED_TASK_CONFIN_INSTALMENTNOTIFICATION_CRON
  value: {{ if .Values.scheduleTask.instalmentNotification.enabled }}{{ required "Please specify scheduleTask.instalmentNotification.cron" .Values.scheduleTask.instalmentNotification.cron | quote }}{{ else }}"-"{{ end }}
{{- end }}

{{/*
  General application environment variables
*/}}
{{- define "consumer-finance.env.general" }}
- name: TRX_MAX_NUMBER
  value: {{ .Values.trx.max.number | default "10" | quote }}
- name: CONSUMER_FINANCE_CACHE_EXPIREAFTERWRITE
  value: {{ .Values.cache.refresh.rate | default "1440" | quote }}
- name: CONSUMERFINANCE_HEADER_DELIVERYCHANNEL
  value: {{ .Values.consumerFinance.header.deliveryChannel | default "HP" | quote }}
- name: CONSUMERFINANCE_HEADER_MODULENAME
  value: {{ .Values.consumerFinance.header.moduleName | default "CONFIN" | quote }}
- name: CONSUMERFINANCE_HEADER_USERID
  value: {{ .Values.consumerFinance.header.userId | default "HPTECH001" | quote }}
- name: PERSON_STRUCTURE_CLIENT_DEFAULT
  value: {{ .Values.personStructure.client.default | default "mockpersonstructure" | quote }}
{{- if .Values.personStructure.client.cf }}
- name: PERSON_STRUCTURE_CLIENT_CF
  value: {{ .Values.personStructure.client.cf | quote }}
{{- end }}
{{- if .Values.personStructure.client.cc }}
- name: PERSON_STRUCTURE_CLIENT_CC
  value: {{ .Values.personStructure.client.cc | quote }}
{{- end }}
- name: FEE_ENGINE_CLIENT_DEFAULT
  value: {{ .Values.feeEngine.client.default | default "mockpricingengine" | quote }}
{{- if .Values.feeEngine.client.cf }}
- name: FEE_ENGINE_CLIENT_CF
  value: {{ .Values.feeEngine.client.cf | quote }}
{{- end }}
{{- if .Values.feeEngine.client.cc }}
- name: FEE_ENGINE_CLIENT_CC
  value: {{ .Values.feeEngine.client.cc | quote }}
{{- end }}
- name: LIMIT_BUCKETS_CLIENT_DEFAULT
  value: {{ .Values.limitBuckets.client.default | default "mocklimitbuckets" | quote }}
{{- if .Values.limitBuckets.client.cf }}
- name: LIMIT_BUCKETS_CLIENT_CF
  value: {{ .Values.limitBuckets.client.cf | quote }}
{{- end }}
{{- if .Values.limitBuckets.client.cc }}
- name: LIMIT_BUCKETS_CLIENT_CC
  value: {{ .Values.limitBuckets.client.cc | quote }}
{{- end }}
{{- if .Values.limitBuckets.client.rb }}
- name: LIMIT_BUCKETS_CLIENT_RB
  value: {{ .Values.limitBuckets.client.rb | quote }}
{{- end }}
- name: LIMIT_BUCKETS_UPDATE_CLIENT_DEFAULT
  value: {{ .Values.limitBuckets.update.client.default | default "mockupdatelimitbuckets" | quote }}
{{- if .Values.limitBuckets.update.client.cf }}
- name: LIMIT_BUCKETS_UPDATE_CLIENT_CF
  value: {{ .Values.limitBuckets.update.client.cf | quote }}
{{- end }}
{{- if .Values.limitBuckets.update.client.cc }}
- name: LIMIT_BUCKETS_UPDATE_CLIENT_CC
  value: {{ .Values.limitBuckets.update.client.cc | quote }}
{{- end }}
{{- if .Values.limitBuckets.update.client.rb }}
- name: LIMIT_BUCKETS_UPDATE_CLIENT_RB
  value: {{ .Values.limitBuckets.update.client.rb | quote }}
{{- end }}
- name: IDEMPOTENCY_FILTER_ENABLED
  value: {{ .Values.idempotency.filter.enabled | default "true" | quote }}
- name: SPRING_BATCH_JOB_ENABLED
  value: {{ .Values.spring.batch.job.enabled | default "false" | quote }}
- name: SPRING_JPA_PROPERTIES_HIBERNATE_JDBC_FETCH_SIZE
  value: {{ .Values.spring.jpa.properties.hibernate.jdbc.fetch_size | default "1000" | quote }}
- name: RECONCILIATION_REPORT_DELIMITER
  value: {{ .Values.reconciliation.report.delimiter | default ";" | quote }}
- name: RECONCILIATION_REPORT_DIRECTORY
  value: {{ default .Values.reconciliation.report.directory .Values.batch.logs.location | quote }}
- name: RECONCILIATION_REPORT_FILENAMEPREFIX
  value: {{ .Values.reconciliation.report.filenamePrefix | default "CFM_RR" | quote }}
- name: RECONCILIATION_REPORT_BATCHNAME
  value: {{ .Values.reconciliation.report.batchName | default "reconciliationReport" | quote }}
- name: RECONCILIATION_REPORT_ENABLED
  value: {{ .Values.reconciliation.report.enabled | default "false" | quote }}
- name: RECONCILIATION_REPORT_CRON
  value: {{ if .Values.reconciliation.report.enabled }}{{ required "Please specify reconciliation.report.cron" .Values.reconciliation.report.cron | quote }}{{ else }}"-"{{ end }}
- name: TRANSACTION_TIMEOUT_IN_SECONDS
  value: {{ .Values.transaction.timeout.inSeconds | default "200" | quote }}
- name: HR_VESTIGO_HP_OUTBOX_DELETEENTITY
  value: {{ .Values.hr.vestigo.hp.outbox.deleteEntity | default false | quote }}
- name: PARAMETERIZATION_SERVICE_PATH
  value: {{ .Values.parameterization.service.path | default "api/v1/consumer-finance" | quote }}
- name: KAFKA_AUTHEXCEPTION_FAILPROBEENABLED
  value: {{ .Values.kafka.authException.failProbeEnabled | default "false" | toString | quote }}
- name: KAFKA_AUTHEXCEPTION_RETRYINTERVAL
  value: {{ .Values.kafka.authException.retryInterval | default "" | quote }}
- name: STATUS_AUDIT_LOG_ENABLED
  value: {{ .Values.status.audit.log.enabled | default true | toString | quote }}
{{- end }}


{{/*
  Inbound authentication environment variables
*/}}
{{- define "consumer-finance.env.inbound-oauth2" }}
{{- if .Values.oauth2.enabled }}
- name: SECURITY_AUTHENTICATION
  value: oauth2
- name: SECURITY_AUTHENTICATION_JWT_CONVERTER
  value: realm
- name: SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_ISSUERURI
  value: {{ required "Please specify oAuth2 resource URI in oauth2.resourceUri" .Values.oauth2.resourceUri | quote }}
{{- else }}
- name: SECURITY_AUTHENTICATION
  value: none
- name: SECURITY_AUTHENTICATION_JWT_CONVERTER
  value: ""
- name: SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_ISSUERURI
  value: ""
{{- end }}
{{- end }}

{{/*
OAuth2 configuration properties
*/}}
{{- define "consumer-finance.env.outbound-oauth2" -}}
- name: SECURITY_OUTBOUND_OAUTH2_TOKEN
  value: {{ .Values.oauth2.outbound.enabled | quote}}
{{- if .Values.oauth2.outbound.enabled }}
- name: SECURITY_OAUTH2_PROVIDER
  value: keycloak
- name: SPRING_SECURITY_OAUTH2_CLIENT_PROVIDER_KEYCLOAK_ISSUERURI
  value: >-
    {{ required "Please specify Keycloak server URL in oauth2.serverUrl" .Values.oauth2.serverUrl }}/realms/{{ required "Please specify Keycloak realm name in oauth2.realm" .Values.oauth2.realm }}
- name: SPRING_SECURITY_OAUTH2_CLIENT_PROVIDER_KEYCLOAK_TOKENURI
  value: >-
    {{ required "Please specify Keycloak server URL in oauth2.serverUrl" .Values.oauth2.serverUrl }}/realms/{{ required "Please specify Keycloak realm name in oauth2.realm" .Values.oauth2.realm }}/protocol/openid-connect/token
- name: SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_KEYCLOAK_CLIENTID
  value: {{ required "Please specify Keycloak resource name in oauth2.resource" .Values.oauth2.resource | quote }}
- name: SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_KEYCLOAK_SCOPE
  value: openid
{{- end }}
{{- end -}}
