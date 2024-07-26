# API Gateway application

## Purpose

This Helm chart installs API Gateway application into your Kubernetes cluster.

Helm release name set during installation will be used for naming all resources created by this Helm chart.
For example, if Chart is installed with name "my-chart", deployment name will have "my-chart" prefix, as well as all configmaps, secrets and other resources created by this chart.
It is possible to override this behavior and to set custom name for resources using attribute `nameOverride` in custom values file.
If this attribute is set, it's value will be used to name all the resources, and release name will be ignored.

It is possible to install application using default values only, however, there is a list of attributes which might have to be modified, depending on setup of other applications.

## Required setup

Required attributes should be defined in custom values file in `yaml` format (recommended) or propagated with `--set key=value` command during CLI installation, for example:

`helm upgrade --install api-gateway holisticpay/api-gateway -f my-values.yaml` or

`helm upgrade --install api-gateway holisticpay/api-gateway --set required-key1=value1 --set required-key2=value2 ...`

Required values are (in `yaml` format):

```yaml
routes:
  alcCollect:
    serviceName: alc-collect # name of alc-collect service, default is alc-collect
    portNumber: "8443" # port number on which alc-collect service is exposed, default is 8443
  authLimitControl:
    serviceName: auth-limit-control # name of auth-limit-control service, default is auth-limit-control
    portNumber: "8443" # port number on which auth-limit-control service is exposed, default is 8443
  personStructure:
    serviceName: person-structure # name of person-structure service, default is person-structure
    portNumber: "8443" # port number on which person-structure service is exposed, default is 8443
  personRegistry:
    serviceName: person-registry # name of person-registry service, default is person-registry
    portNumber: "8443" # port number on which person-registry service is exposed, default is 8443
  paymentOrder:
    serviceName: payment-order # name of payment-order service, default is payment-order
    portNumber: "8443" # port number on which payment-order service is exposed, default is 8443
  sepaInst:
    serviceName: sepa-inst # name of sepa-inst service, default is sepa-inst
    portNumber: "8443" # port number on which sepa-inst service is exposed, default is 8443
  crdPayInstIss:
    serviceName: crd-pay-inst-iss # name of crd-pay-inst-iss service, default is crd-pay-inst-iss
    servicePortNumber: "8443"  # port number on which crd-pay-inst-iss service is exposed, default is 8443
  personRegistryWeb:
    serviceName: person-structure-web # name of person-registry-web service, default is person-registry-web
    portNumber: "8443" # port number on which person-registry-web service is exposed, default is 8443
  balanceCheck:
    serviceName: balance-check # name of balance-check service, default is balance-check
    portNumber: "8443" # port number on which balance-check service is exposed, default is 8443
  balanceLog:
    serviceName: balance-log # name of balance-log service, default is balance-log
    portNumber: "8443" # port number on which balance-log service is exposed, default is 8443
  panManager:
    serviceName: pan-manager # name of pan-manager service, default is pan-manager
    servicePortNumber: "8443"  # port number on which pan-manager service is exposed, default is 8443
  vetoManager:
    serviceName: veto-manager # name of veto-manager service, default is veto-manager
    servicePortNumber: "8443"  # port number on which veto-manager service is exposed, default is 8443
  balanceReconciliation:
    serviceName: balance-reconciliation # name of balance-reconciliation service, default is balance-reconciliation
    servicePortNumber: "8443" # port number on which balance-reconciliation service is exposed, default is 8443
  siriusQuery:
    serviceName: sirius-query # name of sirius-query service, default is sirius-query
    servicePortNumber: "8443" # port number on which sirius-query service is exposed, default is 8443
  productEngine:
    serviceName: product-engine # name of product-engine service, default is product-engine
    servicePortNumber: "8443" # port number on which product-engine service is exposed, default is 8443

imagePullSecrets:
  - name: "image-pull-secret-name" # string value, no default value
```

### Configuring image source and pull secrets

By default, API Gateway image is pulled directly from Vestigo's repository hosted by Docker Hub.
Same applies for Liquibase image.
If mirror registry is used for example, image source can be modified for one or both images using following attributes:

```yaml
image:
  registry: custom.image.registry # will be used as default for all used images, docker.io is default
  app:
    registry: custom.app.image.registry # will override image.registry for API Gateway app
    imageLocation: custom.app.image.registry/repository/image # will override registry, repository and image name
```

Default pull policy is set to `IfNotPresent` but can also be modified for one or both images, for example:

```yaml
image:
  pullPolicy: Always # will be used as default for both images, default is IfNotPresent
  app:
    pullPolicy: Never # will override image.pullPolicy for API Gateway image
```

API Gateway image tag is normally read from Chart definition, but if required, it can be overridden with attribute `image.app.tag`, for example:

```yaml
image:
  app:
    tag: custom-tag
```

API Gateway image is located on Vestigo's private Docker Hub registry, and if image registry is set to docker.io, pull secret has to be defined.
Pull secret is not set by default, and it should be created prior to API Gateway installation in target namespace.
Secret should contain credentials provided by Vestigo.

Once secret is created, it should be set with `imagePullSecrets.name` attribute, for example:

```yaml
imagePullSecrets:
  - name: vestigo-dockerhub-secret
```

### TLS setup

API Gateway application is prepared to use TLS, but requires provided server certificate.
Server certificate is not provided by default (expected to be provided manually) and there are no predefined trust or key stores for TLS/mTLS.
However, there are several different possibilities for customizing TLS setup.

#### Provide server certificate with custom `initContainer`

Key store with custom server certificate can be provided by using custom `initContainer`.
Main thing to keep in mind is that application expects that `initContainer` will output `cert.pem` and `key.pem` files to `volumeMount` with `server-cert` name.
Application will obtain generated certificate and key files via `server-cert` mount and generate server's key store from them.

For example, init container could be defined like this:

```yaml
initContainers:
  - name: generate-server-cert
    image: generate-server-cert
    command:
      - bash
      - -c
      - "custom command to generate certificate"
    volumeMounts:
      - mountPath: /tmp
        name: server-cert # volumeMount name has to be "server-cert"
```

When using initContainer for server certificate, volume will be stored in memory (`emptyDir: medium: "Memory"`)

#### Provide server certificate from predefined secret

Server certificate can be provided using predefined secret.
**Note that this secret has to be created in target namespace prior to installation of API Gateway application.**
Additionally, both certificate and key files should be in one single secret.

When using secret for server certificate, following values have to be provided:

```yaml
mountServerCertFromSecret:
  enabled: true # boolean value, default is false
  secretName: "name-of-server-cert-secret" # string value
  certPath: "name-of-cert-file-from-secret" # string value
  keyPath: "name-of-key-file-from-secret" # string value
```

In this case, Helm chart will take care of mounting certificate and key files to expected location.
The only requirement is to set secret name and names of certificate and key files into values file.

#### Provide trust store with custom `initContainer`

If outbound resources (oAuth2 provider or other) require TLS connection, trust store with required certificates should also be provided.

One of the options is to provide trust store via custom `initContainer`.

There are some requirements if custom `initContainer` is used for providing trust store.
First, initContainer definition should be added to values file. Besides that, custom `volume`, `volumeMount` and environment variables should be added also.

For example, custom `initContainer` could have this definition:

```yaml
initContainers:
  - name: create-trust-store
    image: create-trust-store-image
    command:
      - bash
      - -c
      - "custom command to generate trust store"
    volumeMounts:
      - mountPath: /any
        name: trust-store-volume-name # has to match custom volume definition
```

Defined `volumeMounts.name` from `initContainer` should also be used to define custom volume, for example:

```yaml
customVolumes:
  - name: trust-store-volume-name # has to match name in initContainer and volumeMount in api-gateway container
    emptyDir: # any other volume type is OK
      medium: "Memory"
```

api-gateway container should also mount this volume, so a custom `volumeMount` is required, for example:

```yaml
customMounts:
  - name: trust-store-volume-name # has to match name in initContainer and volumeMount in api-gateway container
    mountPath: /some/mount/path # this path should be used for custom environment variables
```

Note that `mountPath` variable is used to specify a location of trust store in api-gateway container.
Suggested location is: `/mnt/k8s/trust-store`.

To make trust store is available to underlying application server, its location (absolute path - `mountPath` and file name) and type should be defined in following environment variables:

```yaml
customEnv:
  - name: JAVAX_NET_SSL_TRUST_STORE
    value: /some/mount/path/trust-store-file # path defined in volumeMount, has to contain full trust store file location
  - name: JAVAX_NET_SSL_TRUST_STORE_TYPE
    value: JKS # defines provided trust store type (PKCS12, JKS, or other)
```

Trust store password should be AES encrypted with key provided in `secret.decryptionKey` and set to `secret.trustStorePassword`:

```yaml
secret:
  trustStorePassword: "{aes}TrustStorePassword" # AES encoded trust store password
```

#### Provide trust store from predefined secret

Trust store can also be provided by using predefined secret.
**Note that this secret has to be created in target namespace prior to installation of API Gateway application.**

When adding trust store as secret, following values have to be provided:

```yaml
mountTrustStoreFromSecret:
  enabled: true # boolean value, default is false
  secretName: "name-of-trust-store-secret" # string value
  trustStoreName: "name-of-trust-store-file-from-secret" # string value
  trustStoreType: "type-of-trust-store" # string value, default is JKS
```

`trustStoreName` is the actual name of the trust store file itself, as defined in secret.

Default trust store type is JKS and if other type of trust store file is provided, it has to be specified in `trustStoreType` attribute, for example "PKCS12".

Trust store password has to be provided as AES encoded string in `secret.trustStorePassword` attribute, for example:

```yaml
secret:
  trustStorePassword: "{aes}TrustStorePassword" # AES encoded trust store password
```

Note that password should be AES encoded with key provided in `secret.decryptionKey` attribute.

When using secret to mount trust store, no additional custom setup is required.

#### Provide client certificates from predefined secret

Third option for providing trust store is to use predefined secret with client certificates.
Certificates provided in secret will be added to trust store by application.

To mount client certificates from secret, specify following attributes:

```yaml
mountCaFromSecret:
  enabled: true # default if false
  secretName: "secret-with-certificates"
```

When `mountCaFromSecret` is enabled, application will import all certificate files from secret to existing, Java's default, trust store.

When multiple certificates are added, they have to be added to a single secret as separate files.
Application will not load multiple certificates from one file, only first one will be imported.

Note that either `mountTrustStoreFromSecret` or `mountCaFromSecret` can be used, if both are enabled, `mountTrustStoreFromSecret` will be used.

#### Provide mTLS key store from `initContainer`

mTLS support can be added to api-gateway application in two different ways.

As for trust store, key store could also be provided via custom `initContainer`, with similar requirements.

For example, custom `initContainer` could have this definition:

```yaml
initContainers:
  - name: create-key-store
    image: create-key-store-image
    command:
      - bash
      - -c
      - "custom command to generate key store"
    volumeMounts:
      - mountPath: /any
        name: key-store-volume-name # has to match custom volume definition
```

Defined `volumeMounts.name` from `initContainer` should also be used to define custom volume, for example:

```yaml
customVolumes:
  - name: key-store-volume-name # has to match name in initContainer and volumeMount in api-gateway container
    emptyDir: # any other volume type is OK
      medium: "Memory"
```

api-gateway container should also mount this volume, so a custom `volumeMount` is required, for example:

```yaml
customMounts:
  - name: key-store-volume-name # has to match name in initContainer and volumeMount in api-gateway container
    mountPath: /some/mount/path # this path should be used for custom environment variables
```

Note that `mountPath` variable is used to specify a location of key store in api-gateway container.
Suggested location is: `/mnt/k8s/trust-store`.

To make key store available to underlying application server, its location (absolute path - `mountPath` and file name) and type should be defined in environment variable, for example:

```yaml
customEnv:
  - name: JAVAX_NET_SSL_KEY_STORE
    value: /some/mount/path/key-store-file # path defined in volumeMount, has to contain full key store file location
  - name: JAVAX_NET_SSL_KEY_STORE_TYPE
    value: PKCS12 # defines key store type (PKCS12, JKS, or other)
```

Password for key store should be AES encoded and provided in following attribute:

```yaml
secret:
  keyStorePassword: "{aes}KeyStorePassword" # AES encoded key store password
```

Password should be encoded using key defined in `secret.decryptionKey`.

#### Provide mTLS key store from predefined secret

Key store required for mTLS can also be provided via predefined secret.
**Note that this secret has to be created in target namespace prior to installation of API Gateway application.**

When adding key store from secret, following values have to be provided:

```yaml
mountKeyStoreFromSecret:
  enabled: true # boolean value, default is false
  secretName: "name-of-key-store-secret" # string value
  keyStoreName: "name-of-key-store-file-from-secret" # string value
  keyStoreType: "type-of-key-store" # string value, default is JKS
```

`keyStoreName` is the actual name of the key store file itself, as defined in secret.

Default key store type is JKS and if other type of key store file is provided, it has to be specified in `keyStoreType` attribute, for example "PKCS12".

Key store password has to be provided as AES encoded string in `secret.keyStorePassword` attribute.
Password should be encrypted with the key defined in `secret.decryptionKey`.

```yaml
secret:
  keyStorePassword: "{aes}KeyStorePassword" # AES encoded trust store password
```

When using secret to mount key store, no additional custom setup is required.

## Customizing installation

Besides required attributes, installation of API Gateway can be customized in different ways.

### oAuth2

API Gateway application can use oAuth2 service for authentication. By default, this option is disabled, but can easily be enabled by specifying following attributes in values:

```yaml
oauth2:
  enabled: true # default is false
  resourceUri: "" # has to be specified if enabled, no default value
```

To configure oAuth2, it first has to be enabled with `oauth2.enabled` parameter.
When enabled, `oauth2.resourceUri` should also be defined.
This URI should point to oAuth2 server with defined converter type and name, for example `https://oauth2.server/auth/realms/Holistic-Pay`.

### Adding custom environment variables

Custom environment variables can be added to api-gateway container by applying `customEnv` value, for example:

```yaml
customEnv:
  - name: MY_CUSTOM_ENV
    value: some-value
  - name: SOME_OTHER_ENV
    value: 123
```

### Adding custom mounts

Values file can be used to specify additional custom `volume` and `volumeMounts` to be added to api-gateway container.

For example, custom volume mount could be added by defining this setup:

```yaml
customVolumes:
  - name: my-custom-volume # has to match name in initContainer and volumeMount in api-gateway container
    emptyDir: # any other volume type is OK
      medium: "Memory"

customMounts:
  - name: my-custom-volume # has to match name in initContainer and volumeMount in api-gateway container
    mountPath: /some/mount/path # this path should be used for custom environment variables
```

### Customizing container logs

API Gateway application is predefined to redirect all logs to `stdout` expect for Web Server logs (`access.log`) and health check logs, which are not logged by default.
However, using custom configuration, logs can be redirected to log files also (in addition to `stdout`).

When enabling logging to file, container will divide logs into three different files:

- `messages.log` - contains application server's logs

- `health.log` - contains all incoming requests to health check endpoint (filtered out from `access.log`)

- `access.log` - contains typical Web Server logs, except for health check endpoint

To enable logging to file, following attribute should be set in values file:

```yaml
logger:
  logToFile: true # boolean value, default is false
```

With this basic setup, container will start to log files into a predefined "/var/log/app" location with basic file appender.
In order to set custom log location, additional attribute has to be defined:

```yaml
logger:
  logToFile: true # boolean value, default is false
  logDir: "/custom/log/folder"
```

When defining custom log location, make sure folder either already exists in container or is mounted with `logDirMount` variable, for example:

```yaml
logger:
  logToFile: true # boolean value, default is false
  logDir: "/custom/log/folder"
  logDirMount:
    enabled: true # boolean value, default is false
    spec:
      emptyDir: {} # defines mount type, other types can be used also
```

or with other mount type:

```yaml
logger:
  logToFile: true # boolean value, default is false
  logDir: "/custom/log/folder"
  logDirMount:
    enabled: true # boolean value, default is false
    spec:
      flexVolume:
        driver: "volume-driver"
        fsType: "bind"
        options:
          basepath: "/host/path"
          basename: "nope"
          uid: 1000
          gid: 1000
```

Note that any type of mount specification can be used by following standard Kubernetes mount specification, the only requirement is that it has to be defined under `logger.logDirMount.spec` attribute in values file.

Log level can be modified by changing a single attribute:

```yaml
logger:
  globalLogLevel: "DEBUG" # default value
```

Possible values for this parameter are: `TRACE`, `DEBUG`, `INFO`, `WARN` or `ERROR`.

Log level format for STDOUT logger can be modified by changing a single attribute:
```yaml
logger:
  format: "STRING" # default value
```

Possible values for this parameter are: `STRING`,`ECS`,`LOGSTASH`,`GELF` or `GCP`.

String format is defined as:
```
[%d] [%X{correlationId}] %p %c{1.} %replace{%m}{[a-zA-Z]{2}[0-9]{2}[a-zA-Z0-9]{4}[0-9]{7}([a-zA-Z0-9]?){0,16}}{*****}%n
```

Examples of how log entries wood look like for particular option:
* STRING
  * with stacktrace
  ```log
  2023-03-27 16:00:20,140 [6af3546625fd473bbd95482b18f2caec,620676f56f76c5b6] ERROR h.v.s.a.e.SomeClass Error
  jakarta.validation.ConstraintViolationException: must not be null
  at org.springframework.validation.beanvalidation.MethodValidationInterceptor.invoke(MethodValidationInterceptor.java:138) ~[spring-context-6.0.6.jar:6.0.6]
  at org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:184) ~[spring-aop-6.0.6.jar:6.0.6]
  at org.springframework.aop.framework.CglibAopProxy$CglibMethodInvocation.proceed(CglibAopProxy.java:750) ~[spring-aop-6.0.6.jar:6.0.6]
  ```
  * without stacktrace
  ```log
  2023-03-27 16:03:48,368 [7baee9c3042043cd3116a2bcf51b872e,ed1297a561d6ab6d] DEBUG o.s.o.j.JpaTransactionManager Exposing JPA transaction as JDBC [org.springframework.orm.jpa.vendor.HibernateJpaDialect$HibernateConnectionHandle@1d8f102d]
  ```
* ECS
  * with stacktrace
  ```log
  {"@timestamp":"2023-03-17T10:05:47.074367100Z","ecs.version":"1.2.0","log.level":"ERROR","message":"[379b4af3-1]  500 Server Error for HTTP GET","process.thread.name":"reactor-http-nio-5","log.logger":"org.springframework.boot.autoconfigure.web.reactive.error.AbstractErrorWebExceptionHandler","spanId":"0000000000000000","traceId":"00000000000000000000000000000000","error.type":"io.netty.channel.AbstractChannel.AnnotatedConnectException","error.message":"Connection refused: no further information: /127.0.0.1:3000","error.stack_trace":"io.netty.channel.AbstractChannel$AnnotatedConnectException: Connection refused: no further information: /127.0.0.1:3000\r\n\tSuppressed: The stacktrace has been enhanced by Reactor, refer to additional information below: \r\n"}
  ```
  * withoutstacktrace
  ```log
  {"mdc":{"spanId":"0000000000000000","traceId":"00000000000000000000000000000000"},"@timestamp":"2023-03-17T07:37:27.535267800Z","ecs.version":"1.2.0","log.level":"DEBUG","message":"Application availability state ReadinessState changed to ACCEPTING_TRAFFIC","process.thread.name":"main","log.logger":"org.springframework.boot.availability.ApplicationAvailabilityBean"}
  ```
* LOGSTASH
  * with stacktrace
  ```log
  {"mdc":{"spanId":"0000000000000000","traceId":"00000000000000000000000000000000"},"exception":{"exception_class":"io.netty.channel.AbstractChannel.AnnotatedConnectException","exception_message":"Connection refused: no further information: /127.0.0.1:3000","stacktrace":"io.netty.channel.AbstractChannel$AnnotatedConnectException: Connection refused: no further information: /127.0.0.1:3000\r\n\tSuppressed: The stacktrace has been enhanced by Reactor, refer to additional information below: \r\nError has been observed at the following site(s):\r\n\t*__checkpoint ⇢ org.springframework.cloud.gateway.filter.WeightCalculatorWebFilter [DefaultWebFilterChain]\r\n\t"},"@version":1,"source_host":"HOST","message":"[70e82a4a-1]  500 Server Error for HTTP GET","thread_name":"reactor-http-nio-5","@timestamp":"2023-03-17T11:26:22.416121900Z","level":"ERROR","logger_name":"org.springframework.boot.autoconfigure.web.reactive.error.AbstractErrorWebExceptionHandler"}
  ```
  * without stacktrace
  ```log
  {"@version":1,"source_host":"HOST","message":"Application availability state ReadinessState changed to ACCEPTING_TRAFFIC","thread_name":"main","@timestamp":"2023-03-17T11:24:17.730772400Z","level":"DEBUG","logger_name":"org.springframework.boot.availability.ApplicationAvailabilityBean"}
  ```
* GELF
  * with stacktrace
  ```log
  {"version":"1.1","host":"HOST","short_message":"[3440fdd5-1]  500 Server Error for HTTP GET","full_message":"io.netty.channel.AbstractChannel$AnnotatedConnectException: Connection refused: no further information: /127.0.0.1:3000\r\n\tSuppressed: The stacktrace has been enhanced by Reactor, refer to additional information below: \r\n","timestamp":1679049090.535760400,"level":3,"_logger":"org.springframework.boot.autoconfigure.web.reactive.error.AbstractErrorWebExceptionHandler","_thread":"reactor-http-nio-5","_spanId":"0000000000000000","_traceId":"00000000000000000000000000000000"}
  ```
  * without stacktrace
  ```log
  {"version":"1.1","host":"HOST","short_message":"Application availability state ReadinessState changed to ACCEPTING_TRAFFIC","timestamp":1679049030.468963200,"level":7,"_logger":"org.springframework.boot.availability.ApplicationAvailabilityBean","_thread":"main"}
  ```
* GCP
  * with stacktrace
  ```log
  {"timestamp":"2023-03-17T10:33:42.531673100Z","severity":"ERROR","message":"[3e916f02-1]  500 Server Error for HTTP GET  io.netty.channel.AbstractChannel$AnnotatedConnectException: Connection refused: no further information: /127.0.0.1:3000\r\n\tSuppressed: reactor.core.publisher.FluxOnAssembly$OnAssemblyException: \r\nError has been observed at the following site(s):\r\n\t*__checkpoint ⇢ org.springframework.cloud.gateway.filter.WeightCalculatorWebFilter [DefaultWebFilterChain]\r\n\t","logging.googleapis.com/labels":{"spanId":"0000000000000000","traceId":"00000000000000000000000000000000"},"logging.googleapis.com/sourceLocation":{"function":"org.springframework.core.log.CompositeLog.error"},"logging.googleapis.com/insertId":"1106","_exception":{"class":"io.netty.channel.AbstractChannel.AnnotatedConnectException","message":"Connection refused: no further information: /127.0.0.1:3000","stackTrace":"io.netty.channel.AbstractChannel$AnnotatedConnectException: Connection refused: no further information: /127.0.0.1:3000\r\n\tSuppressed: reactor.core.publisher.FluxOnAssembly$OnAssemblyException: \r\nError has been observed at the following site(s):\r\n\t*__checkpoint ⇢ org.springframework.cloud.gateway.filter.WeightCalculatorWebFilter [DefaultWebFilterChain]\r\n\t"},"_thread":"reactor-http-nio-5","_logger":"org.springframework.boot.autoconfigure.web.reactive.error.AbstractErrorWebExceptionHandler"}
  ```
  * without stacktrace
  ```log
  {"timestamp":"2023-03-17T10:33:14.218078900Z","severity":"DEBUG","message":"Application availability state ReadinessState changed to ACCEPTING_TRAFFIC","logging.googleapis.com/sourceLocation":{"function":"org.springframework.boot.availability.ApplicationAvailabilityBean.onApplicationEvent"},"logging.googleapis.com/insertId":"1051","_exception":{"stackTrace":""},"_thread":"main","_logger":"org.springframework.boot.availability.ApplicationAvailabilityBean"}
  ```

#### Logging request and response body

By default, api-gateway logs only basic information for every request and response that go through it - correlation_id, http_method, path and response_status_code.

If needed, it also has the ability to log body of every request and response, which is disabled by default. If needed, this can be overriden by passing next environment variable: :

```yaml
customEnv:
  - name: HTTP_LOG_BODY_ENABLED
    value: "true"
```

---
> ❗ **IMPORTANT**
>
> When body logging is enabled, potentially sensitive data will also be logged.
---

### Distributed tracing
Api gateway also supports distributed tracing via OTLP protocol. It uses Micrometer and OpenTelemetry to instrument and export traces to designated backend. By default, instrumentation is disabled, but that can be overridden by providing values in following structure (listed below are default values):
```yaml
tracing:
  enabled: false # true or false
  endpoint: ""
  samplingProbability: 0.1 # allowed values are [0.0, 1.0]
```

Parameter `tracing.endpoint` must point to the tracing backend into which traces will be uploaded. Tracing backend must be compatible with OTLP protocol.

Parameter `tracing.samplingProbability` must be a decimal number with values in range `[0.0, 1.0]` and it dictates which percentage of recorded traces will be uploaded to tracing backend. 0.0 means 0% of traces will be uploaded and 1.0 means 100% of traces will be uploaded.


### Modifying deployment strategy

Default deployment strategy for API Gateway application is `RollingUpdate`, but it can be overridden, along with other deployment parameters using following attributes (default values are shown):

```yaml
deployment:
  annotations: {}
  replicaCount: 1
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  minReadySeconds: 60
  terminationGracePeriodSeconds: 60
  restartPolicy: Always
```

By default, one replica of API Gateway is installed on Kubernetes cluster. Number of replicas can be statically modified with above configuration, or `HorizontalPodAutoscaler` option can be used to let Kubernetes automatically scale application when required.

#### Customizing pod resource requests and limits

Following are the default values for API Gateway requests and limits:

```yaml
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 50m
    memory: 256Mi
```

Any value (or all of them) can be modified by specifying same attribute in custom values file to any other value.

#### Using `HorizontalPodAutoscaler`

By default, autoscaler is disabled in configuration, but it can enabled by using following setup:

```yaml
autoscaling:
  enabled: true # default is false, has to be set to true to enable HPA
  minReplicas: 1 # default value
  maxReplicas: 10 # default value
  targetCPUUtilizationPercentage: 80 # default value
  targetMemoryUtilizationPercentage: 80 # not used by default
```

CPU and/or memory utilization metrics can be used to autoscale API Gateway pod.
It's possible to define one or both of those metrics.
If only `autoscaling.enabled` attribute is set to `true`, without setting other attributes, only CPU utilization metric will be used with percentage set to 80.

### Customizing probes

API Gateway application has predefined health check probes (readiness and liveness).
Following are the default values:

```yaml
deployment:
  readinessProbe:
    initialDelaySeconds: 10
    periodSeconds: 60
    timeoutSeconds: 181
    successThreshold: 1
    failureThreshold: 2
    httpGet:
      path: /health/readiness
      port: http
      scheme: HTTPS
  livenessProbe:
    initialDelaySeconds: 60
    periodSeconds: 60
    timeoutSeconds: 10
    failureThreshold: 3
    httpGet:
      path: /health/liveness
      port: http
      scheme: HTTPS
```

Probes can be modified with different custom attributes simply by setting a different `deployment.readinessProbe` or `deployment.livenessProbe` value structure.

For example, this setup would increase `periodSeconds`, add `httpHeaders` attributes and apply query parameters to `path` of `livenessProbe`:

```yaml
deployment:
  livenessProbe:
    periodSeconds: 180
    httpGet:
      path: /health/liveness?__cbhck=Health/k8s # do not modify base path
      httpHeaders:
        - name: Content-Type
          value: application/json
        - name: User-Agent
          value: Health/k8s
        - name: Host
          value: localhost
```

Note that API Gateway has health checks available within the `/health` endpoint (`/health/readiness` for readiness and `/health/liveness` for liveness), and this base paths should not modified, only query parameters are subject to change.
`scheme` attribute should also be set to `HTTPS` at all times, as well as `http` value for `port` attribute.

### Customizing security context

Security context for API Gateway can be set on pod and/or on container level.
By default, pod security context is defined with following values:

```yaml
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
```

There is no default security context on container level, but it can be defined by setting `securityContext` attribute (opposed to `podSecurityContext`), for example:

```yaml
securityContext:
  runAsNonRoot: false
  runAsUser: 0
  runAsGroup: 0
```

Note that container level security context will be applied to both containers in API Gateway pod (Liquibase init container and API Gateway container).

### Customizing network setup

#### Service setup

When installing API Gateway using default setup, a `Service` object will be created of `ClusterIP` type exposed on port 8443.
Those values can be modified by setting following attributes in custom values file, for example for `NodePort`:

```yaml
service:
  type: NodePort
  port: 10000
  nodePort: 32000
```

or for `LoadBalancer`:

```yaml
service:
  type: LoadBalancer
  loadBalancerIP: 192.168.0.1
```

Service object creation can also be disabled by setting `service.enabled` attribute value to `false` (default is `true`).

Custom annotations and labels can be added to `Service` by specifying them in `service.annotations` and `service.labels` attributes, for example:

```yaml
service:
  annotations:
    custom.annotation: "custom value"
    other.annotation: "true"
  labels:
    customLabel: "custom value"
```

Complete list of `Service` attributes:

```yaml
service:
  enabled: true
  type: ClusterIP
  port: 8443
  nodePort: ""
  clusterIP: ""
  loadBalancerIP: ""
  loadBalancerSourceRanges: []
  annotations: {}
  labels: {}
```

#### Ingress setup

Ingress is not created by default, but can be enabled and customized by specifying following values:

```yaml
ingress:
  enabled: true # default value is false, should be set to true to enable
  className: ""
  annotations: {}
  hosts: []
  tls: []
```

For example, a working setup could be defined like this:

```yaml
ingress:
  enabled: true
  annotations:
    nginx.ingress.kubernetes.io/ssl-passthrough: "true"
  hosts:
    - host: api-gateway.custom.url
      paths:
        - path: /
          pathType: Prefix
```

### Adding custom init containers

As already explained as one of the options when providing TLS certificates, there's a possibility to define a custom `initContainer`.
This option is not limited to TLS setup only, but custom `initContainer` can be used for any purpose.

Custom init container(s) can simply be added by defining their specification in `initContainers` attribute, for example:

```yaml
initContainers:
  - name: custom-init-container
    image: custom-init-container-image
    command:
      - bash
      - -c
      - "custom command"
  - name: other-custom-init-container
    image: other-custom-init-container-image
    env:
      - name: CUSTOM_ENV_VAR
        value: custom value
```

Init container can have all standard Kubernetes attributes in its specification.

### Customizing affinity rules, node selector and tolerations

API Gateway deployment has some predefined affinity rules, as listed below:

```yaml
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/arch
              operator: In
              values:
                - amd64
            - key: kubernetes.io/os
              operator: In
              values:
                - linux
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
              - key: app
                operator: In
                values:
                  - api-gateway
          topologyKey: kubernetes.io/hostname
```

This affinity rules can be overridden through custom values file and set to any required value if necessary.

There are no defaults for node selector or tolerations, but there is a possibility to define both by adding their specifications, for example:

```yaml
nodeSelector:
  disktype: ssd

tolerations:
  - key: "custom-key"
    operator: "Equal"
    value: "custom-value"
    effect: "NoExecute"
    tolerationSeconds: 3600
```

### Adding custom annotations

Custom annotations can be added to pod by listing them under `podAnnotations` attribute structure, for example:

```yaml
podAnnotations:
  custom.annotation: custom-value
  other.annotation: other-value
```

Annotations can also be added to deployment by specifying them under `deployment.annotations`, for example:

```yaml
deployment:
  annotations:
    custom.annotation: custom-value
    other.annotation: other-value
```

### Additional custom configuration

There are some other customizable attributes predefined in API Gateway application.

One of them is related to HTTP return code which is returned by application if health check fails.
Default value for this attribute is 418 but it can be customized if necessary, for example:

```yaml
healthStatusDownReturnCode: "499" # default value is 418
```

There's a possibility to define a custom timezone (there is no default one), by simply defining following attribute:

```yaml
timezone: Europe/London
```

Finally, since API Gateway is an Java application, there's a possibility to set custom JVM parameters.
There is a predefined value which specifies `Xms` and `Xmx` JVM parameters:

```yaml
javaOpts: "-Xms256M -Xmx256M" # default value
```

This value can be changed by modifying existing parameters or adding custom, for example:

```yaml
javaOpts: "-Xms256M -Xmx512M -Dcustom.jvm.param=true"
```

Note that defining custom `javaOpts` attribute will override default one, so make sure to keep `Xms` and `Xmx` parameters.
