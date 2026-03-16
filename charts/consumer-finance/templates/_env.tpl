{{/*
  gRPC environment variables
*/}}
{{- define "consumer-finance.env.grpc" }}
- name: GRPC_CLIENT_GETPERSONDATA_ADDRESS
  value: {{ required "Please specify address for person structure gRPC server (mocks-ms) in grpc.getPersonData.address" .Values.grpc.getPersonData.address | quote }}
- name: GRPC_CLIENT_GETPERSONDATA_NEGOTIATIONTYPE
  value: {{ .Values.grpc.negotiation | default "TLS" | quote }}
- name: GRPC_GETPERSONDATA_TIMEOUT
  value: {{ .Values.grpc.getPersonData.timeout | default "10000" | quote }}
{{- if eq (.Values.personStructure.client | default "mockpersonstructure") "hppersonstructure" }}
- name: GRPC_CLIENT_PERSONSTRUCTUREDATA_ADDRESS
  value: {{ required "Please specify address for HP person structure gRPC server in grpc.personStructureData.address" .Values.grpc.personStructureData.address | quote }}
- name: GRPC_CLIENT_PERSONSTRUCTUREDATA_NEGOTIATIONTYPE
  value: {{ .Values.grpc.personStructureData.negotiationType | default (.Values.grpc.negotiation | default "TLS") | quote }}
- name: GRPC_PERSONSTRUCTUREDATA_TIMEOUT
  value: {{ .Values.grpc.personStructureData.timeout | default "10000" | quote }}
{{- end }}
- name: GRPC_CLIENT_GETLIMITBUCKETS_ADDRESS
  value: {{ required "Please specify address for limit buckets gRPC server in grpc.getLimitBuckets.address" .Values.grpc.getLimitBuckets.address | quote }}
- name: GRPC_CLIENT_UPDATELIMITBUCKETS_ADDRESS
  value: {{ required "Please specify address for limit buckets gRPC server in grpc.updateLimitBuckets.address" .Values.grpc.updateLimitBuckets.address | quote }}
- name: GRPC_CLIENT_GETLIMITBUCKETS_NEGOTIATIONTYPE
  value: {{ .Values.grpc.negotiation | default "TLS" | quote }}
- name: GRPC_CLIENT_UPDATELIMITBUCKETS_NEGOTIATIONTYPE
  value: {{ .Values.grpc.negotiation | default "TLS" | quote }}
- name: GRPC_GETLIMITBUCKETS_TIMEOUT
  value: {{ .Values.grpc.getLimitBuckets.timeout | default "10000" | quote }}
- name: GRPC_UPDATELIMITBUCKETS_TIMEOUT
  value: {{ .Values.grpc.updateLimitBuckets.timeout | default "10000" | quote }}
- name: GRPC_CLIENT_GETPRICINGENGINE_ADDRESS
  value: {{ required "Please specify address for pricing engine gRPC server in grpc.getPricingEngine.address" .Values.grpc.getPricingEngine.address | quote }}
- name: GRPC_CLIENT_GETPRICINGENGINE_NEGOTIATIONTYPE
  value: {{ .Values.grpc.negotiation | default "TLS" | quote }}
- name: GRPC_GETPRICINGENGINE_TIMEOUT
  value: {{ .Values.grpc.getPricingEngine.timeout | default "10000" | quote }}
- name: GRPC_WARMUP_REPEAT
  value: {{ .Values.grpc.warmup.repeat | default "10" | quote }}
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
{{- end }}

{{/*
  Kafka topics and consumer group environment variables
*/}}
{{- define "consumer-finance.env.kafka-topics" }}
- name: KAFKA_TOPIC_LIMITBUCKETCOMPENSATION_NAME
  value: {{ .Values.kafka.topics.limitbucketcompensation.name | quote }}
- name: KAFKA_TOPIC_DUEINSTALMENT_NAME
  value: {{ .Values.kafka.topics.dueinstalment.name | quote }}
- name: KAFKA_TOPIC_NOTIFICATION_NAME
  value: {{ .Values.kafka.topics.notification.name | quote }}
- name: KAFKA_TOPIC_AUTHTRANSACTION_NAME
  value: {{ .Values.kafka.topics.authtransaction.name | quote }}
- name: KAFKA_CONSUMER_GROUP_AUTHTRANSACTION_NAME
  value: {{ .Values.kafka.topics.authtransaction.consumerGroup | quote }}
- name: KAFKA_TOPIC_AUTHTRANSACTION_RETRY_MAXATTEMPTS
  value: {{ .Values.kafka.topics.authtransaction.retry.maxAttempts | quote }}
- name: KAFKA_TOPIC_AUTHTRANSACTION_RETRY_DELAY
  value: {{ .Values.kafka.topics.authtransaction.retry.delay | quote }}
- name: KAFKA_TOPIC_CRDAUTHTRXMATCH_NAME
  value: {{ .Values.kafka.topics.crdauthtrxmatch.name | quote }}
- name: KAFKA_CONSUMER_GROUP_DUEINSTALMENT_NAME
  value: {{ .Values.kafka.topics.dueinstalment.consumerGroup | quote }}
- name: KAFKA_CONSUMER_GROUP_NOTIFICATION_NAME
  value: {{ .Values.kafka.topics.notification.consumerGroup | quote }}
- name: KAFKA_CONSUMER_GROUP_CRDAUTHTRXMATCH_NAME
  value: {{ .Values.kafka.topics.crdauthtrxmatch.consumerGroup | quote }}
- name: KAFKA_TOPIC_CRDAUTHTRXMATCH_RETRY_MAXATTEMPTS
  value: {{ .Values.kafka.topics.crdauthtrxmatch.retry.maxAttempts | quote }}
- name: KAFKA_TOPIC_INSTALMENTOFFER_NAME
  value: {{ .Values.kafka.topics.instalmentoffer.name | quote }}
- name: KAFKA_TOPIC_SYSINSTALMENTOFFER_NAME
  value: {{ .Values.kafka.topics.sysInstalmentOffer.name | quote }}
- name: KAFKA_CONSUMER_GROUP_INSTALMENTOFFER_NAME
  value: {{ .Values.kafka.topics.instalmentoffer.consumerGroup | quote }}
- name: KAFKA_TOPIC_INSTALMENTOFFERRESPONSE_NAME
  value: {{ .Values.kafka.topics.instalmentofferresponse.name | quote }}
- name: KAFKA_TOPIC_SYSINSTALMENTOFFERRESPONSE_NAME
  value: {{ .Values.kafka.topics.sysinstalmentofferresponse.name | quote }}
- name: KAFKA_CONSUMER_GROUP_INSTALMENTOFFERRESPONSE_NAME
  value: {{ .Values.kafka.topics.instalmentofferresponse.consumerGroup | quote }}
- name: KAFKA_TOPIC_EXTSYSRESPONSE_NAME
  value: {{ .Values.kafka.topics.extsysresponse.name | quote }}
- name: KAFKA_CONSUMER_GROUP_EXTSYSRESPONSE_NAME
  value: {{ .Values.kafka.topics.extsysresponse.consumerGroup | quote }}
- name: KAFKA_TOPIC_EXTSYSRESPONSE_RETRY_MAXATTEMPTS
  value: {{ .Values.kafka.topics.extsysresponse.retry.maxAttempts | quote }}
- name: KAFKA_TOPIC_EXTSYSRESPONSE_RETRY_DELAY
  value: {{ .Values.kafka.topics.extsysresponse.retry.delay | quote }}
- name: KAFKA_TOPIC_CONSUMERFINANCELOANEVENT_NAME
  value: {{ .Values.kafka.topics.consumerfinanceloanevent.name | quote }}
- name: KAFKA_TOPIC_PARAMETERIZATION_NAME
  value: {{ .Values.kafka.topics.parameterization.name | quote }}
- name: KAFKA_CONSUMER_GROUP_CURRENCY_PARAMETERIZATION_NAME
  value: {{ .Values.kafka.topics.parameterization.currency.consumerGroup | quote }}
- name: KAFKA_CONSUMER_GROUP_COUNTRY_PARAMETERIZATION_NAME
  value: {{ .Values.kafka.topics.parameterization.country.consumerGroup | quote }}
{{- end }}

{{/*
  Scheduled task environment variables
*/}}
{{- define "consumer-finance.env.scheduled-task" }}
- name: SCHEDULED_TASK_CONFIN_INSTALMENTSENDING_ENABLED
  value: {{ .Values.scheduleTask.instalmentSending.enabled | quote }}
- name: SCHEDULED_TASK_CONFIN_INSTALMENTSENDING_CRON
  value: {{- if .Values.scheduleTask.instalmentSending.enabled }}{{ required "Please specify scheduleTask.instalmentSending.cron" .Values.scheduleTask.instalmentSending.cron | quote }}{{- else }}"-"{{- end }}
- name: SCHEDULED_TASK_CONFIN_INSTALMENTNOTIFICATION_ENABLED
  value: {{ .Values.scheduleTask.instalmentNotification.enabled | default "false" | quote }}
- name: SCHEDULED_TASK_CONFIN_INSTALMENTNOTIFICATION_CRON
  value: {{- if .Values.scheduleTask.instalmentNotification.enabled }}{{ required "Please specify scheduleTask.instalmentNotification.cron" .Values.scheduleTask.instalmentNotification.cron | quote }}{{- else }}"-"{{- end }}
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
- name: PERSON_STRUCTURE_CLIENT
  value: {{ .Values.personStructure.client | default "mockpersonstructure" | quote }}
- name: FEE_ENGINE_CLIENT
  value: {{ .Values.feeEngine.client | default "hppricingengine" | quote }}
- name: IDEMPOTENCY_FILTER_ENABLED
  value: {{ .Values.idempotency.filter.enabled | default "true" | quote }}
- name: TRANSACTION_TIMEOUT_IN_SECONDS
  value: {{ .Values.transaction.timeout.inSeconds | default "200" | quote }}
- name: HR_VESTIGO_HP_OUTBOX_DELETEENTITY
  value: {{ .Values.hr.vestigo.hp.outbox.deleteEntity | default false | quote }}
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
{{- if and .Values.secret.existingSecret (eq "NONE" .Values.secret.encryptionAlgorithm) }}
- name: SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_KEYCLOAK_CLIENTSECRET
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secret.existingSecret }}
      key: oauth2.password
{{- end }}
{{- end -}}
