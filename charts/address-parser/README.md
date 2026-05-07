# address-parser application

## Purpose

This Helm chart installs address-parser application into your Kubernetes cluster.

Helm release name set during installation will be used for naming all resources created by this Helm chart.
For example, if Chart is installed with name "my-chart", deployment name will have "my-chart" prefix, as well as all
configmaps, secrets and other resources created by this chart.
It is possible to override this behavior and to set custom name for resources using attribute `nameOverride` in custom
values file.
If this attribute is set, it's value will be used to name all the resources, and release name will be ignored.

It is not possible to install application using default values only, there is a list of required attributes which should
be applied when installing address-parser.

## Required setup

Required attributes should be defined in custom values file in `yaml` format (recommended) or propagated with
`--set key=value` command during CLI installation, for example:

`helm upgrade --install address-parser holisticpay/address-parser -f my-values.yaml` or

`helm upgrade --install address-parser holisticpay/address-parser --set required-key1=value1 --set required-key2=value2 ...`

Required values are (in `yaml` format):

```yaml
secret:
  decryptionKey: "my-encryption-key" # string value

imagePullSecrets:
  - name: "image-pull-secret-name" # string value
```

Secret configuration requires only the `decryptionKey` attribute, which is used for encrypting and decrypting any
sensitive data within the application.

### Configuring image source and pull secrets

By default, address-parser image is pulled directly from Vestigo's repository hosted by Docker Hub.
If mirror registry is used for example, image source can be modified using following attributes:

```yaml
image:
  registry: custom.image.registry # will be used as default, docker.io is default (image repository and image name will be automatically appended)
  app:
    registry: custom.app.image.registry # will override image.registry for address-parser app (image repository and image name will be automatically appended)
    imageLocation: custom.app.image.registry/custom-location/custom-name # will override image registry, repository and name (only image tag will be automatically appended)
```

Default pull policy is set to `IfNotPresent` but can also be modified, for example:

```yaml
image:
  pullPolicy: Always # default is IfNotPresent
  app:
    pullPolicy: Never # will override image.pullPolicy for address-parser image
```

address-parser image tag is normally read from Chart definition, but if required, it can be overridden with attribute
`image.app.tag`, for example:

```yaml
image:
  app:
    tag: custom-tag
```

address-parser image is located on Vestigo's private Docker Hub registry, and if image registry is set to docker.io, pull
secret has to be defined.
Pull secret is not set by default, and it should be created prior to address-parser installation in target namespace.
Secret should contain credentials provided by Vestigo.

Once secret is created, it should be set with `imagePullSecrets.name` attribute, for example:

```yaml
imagePullSecrets:
  - name: vestigo-dockerhub-secret
```

### TLS setup

address-parser application is prepared to use TLS, but requires provided server certificate.
Server certificate is not provided by default (expected to be provided manually).
However, there are several different possibilities for customizing TLS setup.

#### Provide server certificate with custom `initContainer`

Key store with custom server certificate can be provided by using custom `initContainer`.
Main thing to keep in mind is that application expects that `initContainer` will output `cert.pem` and `key.pem` files
to `volumeMount` with `server-cert` name.
Application will obtain generated certificate and key files via `server-cert` mount and generate server's key store from
them.

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
**Note that this secret has to be created in target namespace prior to installation of address-parser application.**
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

### Using `existingSecret`

Instead of defining and holding encryption key in values file, `existingSecret` option can be used.
In this case, only existing secret name should be defined in `secret` block, for example:

```yaml
secret:
  existingSecret: custom-predefined-secret-name
```

Predefined secret has to be prepared and created in the target namespace prior to installation.

The content of the predefined secret has to have a single file called "password.conf" which should contain the
decryption key:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: custom-predefined-secret-name
type: Opaque
data:
  password.conf: |-
    ...
```

Content of the "password.conf" file:

```properties
key.for.decryption=(plaintext encryption/decryption key)
```

## Customizing installation

Besides required attributes, installation of address-parser can be customized in different ways.

### Libpostal data directory

address-parser application uses [libpostal](https://github.com/openvenues/libpostal) library for address parsing.
Libpostal requires a pre-built data directory (~1.5 GB) to be available at runtime.

The path to the libpostal data directory is configured via the `libpostal.dataDir` attribute in values file:

```yaml
libpostal:
  dataDir: /opt/libpostal/data # default value
```

This value is passed to the container as the `LIBPOSTAL_DATA_DIR` environment variable, which the application reads
from `application.properties` (`libpostal.data-dir`).

The data directory must be available inside the container at the specified path. Common approaches to achieve this are:

- **Bake into Docker image** - include the data directory in the Docker image during build (simplest, but increases
  image size significantly).

- **Host path mount** - mount the data directory from the host VM into the container using `customVolumes` and
  `customMounts`:

```yaml
libpostal:
  dataDir: /opt/libpostal/data

customVolumes:
  - name: libpostal-data
    hostPath:
      path: /opt/libpostal/data # path on the host VM
      type: Directory

customMounts:
  - name: libpostal-data
    mountPath: /opt/libpostal/data
    readOnly: true
```

- **Persistent Volume** - provision a `PersistentVolume` with the data pre-loaded and mount it using `customVolumes`
  and `customMounts`:

```yaml
libpostal:
  dataDir: /opt/libpostal/data

customVolumes:
  - name: libpostal-data
    persistentVolumeClaim:
      claimName: libpostal-data-pvc

customMounts:
  - name: libpostal-data
    mountPath: /opt/libpostal/data
    readOnly: true
```

### oAuth2

address-parser application can use oAuth2 service for authorization. By default, this option is disabled, but can easily be
enabled by specifying following attributes in values:

```yaml
oAuth2:
  enabled: true # default is false
  resourceUri: "" # has to be specified if enabled, no default value
  authorizationPrefix: "" # defines variable prefix of the scope/role
```

To configure oAuth2, it first has to be enabled with `oAuth2.enabled` parameter.
When enabled, `oAuth2.resourceUri` should also be defined.
This URI should point to oAuth2 server with defined converter type and name, for example
`https://oauth2.server/realm/Holistic-Pay`. If scope/role has variable prefix, which should not be considered as full
role/scope name, this variable prefix should be defined. Every part of this variable part should be defined (e.g. if
scopes are defined as MY_PREFIX:scope1 MY_PREFIX:scope2 etc, then variable prefix is 'MY_PREFIX:')

### Request body sanitization and response body encoding

address-parser application provides security mechanism in order to prevent injection attacks. Mechanisms to achieve this are
Input data sanitization and Output data encoding. By default, sanitization is enabled and encoding is disabled. If any
of these needs to be changed, this can be configured via next parameters:

```yaml
request:
  sanitization:
    enabled: true

response:
  encoding:
    enabled: false
```

### Adding custom environment variables

Custom environment variables can be added to address-parser container by applying `customEnv` value, for example:

```yaml
customEnv:
  - name: MY_CUSTOM_ENV
    value: some-value
  - name: SOME_OTHER_ENV
    value: 123
```

### Adding custom mounts

Values file can be used to specify additional custom `volume` and `volumeMounts` to be added to address-parser container.

For example, custom volume mount could be added by defining this setup:

```yaml
customVolumes:
  - name: my-custom-volume
    emptyDir:
      medium: "Memory"

customMounts:
  - name: my-custom-volume
    mountPath: /some/mount/path
```

### Customizing container logs

address-parser application is predefined to redirect all logs to `stdout` expect for Web Server logs (`access.log`) and health
check logs, which are not logged by default.
However, using custom configuration, logs can be redirected to log files also (in addition to `stdout`).

When enabling logging to file, container will divide logs into four different files:

- `application.log` - contains all application-related (business logic) logs
- `messages.log` - contains application server's logs
- `health.log` - contains all incoming requests to health check endpoint (filtered out from `access.log`)
- `access.log` - contains typical Web Server logs, except for health check endpoint

To enable logging to file, following attribute should be set in values file:

```yaml
logger:
  logToFile: true # boolean value, default is false
```

With this basic setup, container will start to log files into a predefined "/var/log/app" location with basic file
appender.
In order to set custom log location or to enable rolling file appender, two additional attributes have to be defined:

```yaml
logger:
  logToFile: true # boolean value, default is false
  rollingFileAppender: true # boolean value, default is false
  logDir: "/custom/log/folder"
```

When defining custom log location, make sure folder either already exists in container or is mounted with `logDirMount`
variable, for example:

```yaml
logger:
  logToFile: true
  rollingFileAppender: true
  logDir: "/custom/log/folder"
  logDirMount:
    enabled: true
    spec:
      emptyDir: { }
```

Logging levels are used to categorize the entries in the log file, possible levels include
TRACE, DEBUG, INFO, WARN and ERROR.

It is possible to control which logging level will be visible in the log file for a specific category, these categories
are:

- health - health check logs
- rest - rest-related logs
- businessLogic - logs related to business logic
- general - all other logs

```yaml
logger:
  level:
    health: INFO
    rest: INFO
    businessLogic: INFO
    general: INFO
```

If you want to include in your logs, the name of the microservice which generates the logs, you can do so by setting the
value of the name of the microservice in the attribute `logger.microserviceTag`.
By default, this attribute is set to ADDPAR.

```yaml
logger:
  microserviceTag: ADDPAR # default value
```

Log format for STDOUT logger can be modified by changing attribute:

```yaml
logger:
  format: "STRING" # default value
```

Supported values for this parameter are: `STRING`,`ECS`,`LOGSTASH`,`GELF`,`GCP`.

If it is required to mask sensitive data whilst logging, it can be configured by parameter:

```yaml
logger:
  maskSensitive: true # boolean value, default is true
```

### Observing distributed tracing

In order to start exporting tracing information to Tempo (or any tool that knows how to interpret OpenTelemetry formatted data),
address-parser microservice should define next attributes:

```yaml
tracing:
  enabled: false
  samplingProbability: 0.0 # decimal value, default is 0.0
  otlpEndpoint: ''
```

First, you enable tracing using `enabled: true`.

Then, with parameter `samplingProbability` you define percentage of requests
that should be exported to processing system.
`0.0` means 0% of requests and `1.0` means 100%.

With parameter `otlpEndpoint` you define URL to which tracing information is sent.

### Modifying deployment strategy

Default deployment strategy for address-parser application is `RollingUpdate`, but it can be overridden, along with other
deployment parameters using following attributes (default values are shown):

```yaml
deployment:
  annotations: { }
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

By default, one replica of address-parser is installed on Kubernetes cluster. Number of replicas can be statically modified
with above configuration, or `HorizontalPodAutoscaler` option can be used to let Kubernetes automatically scale
application when required.

#### Customizing pod resource requests and limits

Following are the default values for address-parser requests and limits:

```yaml
resources:
  limits:
    cpu: 500m
    memory: 768Mi
  requests:
    cpu: 50m
    memory: 768Mi
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

CPU and/or memory utilization metrics can be used to autoscale address-parser pod.
It's possible to define one or both of those metrics.
If only `autoscaling.enabled` attribute is set to `true`, without setting other attributes, only CPU utilization metric
will be used with percentage set to 80.

#### Using `VerticalPodAutoscaler`

By default, VPA is disabled in configuration, but it can enabled with following setup:

```yaml
vpa:
  enabled: true # default is false, has to be set to true to enable VPA
  updateMode: Off # default mode if Off, other possible values are "Initial", "Recreate" and "Auto"
```

Please note that this feature requires VPA controller to be installed on Kubernetes cluster. Please refer
to [VPA documentation](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler) for additional
info.

### Customizing probes

address-parser application has predefined health check probes (readiness, liveness and startup).
Following are the default values:

```yaml
deployment:
  readinessProbe:
    initialDelaySeconds: 0
    periodSeconds: 60
    timeoutSeconds: 10
    successThreshold: 1
    failureThreshold: 2
    httpGet:
      path: /health/readiness
      port: http
      scheme: HTTPS
  livenessProbe:
    initialDelaySeconds: 0
    periodSeconds: 60
    timeoutSeconds: 10
    failureThreshold: 3
    httpGet:
      path: /health/liveness
      port: http
      scheme: HTTPS
  startupProbe:
    initialDelaySeconds: 30
    periodSeconds: 5
    timeoutSeconds: 1
    failureThreshold: 60
    httpGet:
      path: /health/liveness
      port: http
      scheme: HTTPS
```

The startup probe is particularly important because loading libpostal data (~1.5 GB) can take significant time.
It gives the application up to 330 seconds (30s + 5s × 60) to start before the liveness probe kicks in.

Probes can be modified with different custom attributes simply by setting a different `deployment.readinessProbe`,
`deployment.livenessProbe` or `deployment.startupProbe` value structure.

### Customizing security context

Security context for address-parser can be set on pod and/or on container level.
By default, pod security context is defined with following values:

```yaml
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
```

There is no default security context on container level, but it can be defined by setting `securityContext` attribute (
opposed to `podSecurityContext`), for example:

```yaml
securityContext:
  runAsNonRoot: false
  runAsUser: 0
  runAsGroup: 0
```

### Customizing network setup

#### Service setup

When installing address-parser using default setup, a `Service` object will be created of `ClusterIP` type exposed on port
8443.
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

Service object creation can also be disabled by setting `service.enabled` attribute value to `false` (default is
`true`).

Custom annotations and labels can be added to `Service` by specifying them in `service.annotations` and `service.labels`
attributes.

#### Ingress setup

Ingress is not created by default, but can be enabled and customized by specifying following values:

```yaml
ingress:
  enabled: true # default value is false, should be set to true to enable
  className: ""
  annotations: { }
  hosts: [ ]
  tls: [ ]
```

### Adding custom init containers

Custom init container(s) can simply be added by defining their specification in `initContainers` attribute, for example:

```yaml
initContainers:
  - name: custom-init-container
    image: custom-init-container-image
    command:
      - bash
      - -c
      - "custom command"
```

Init container can have all standard Kubernetes attributes in its specification.

### Customizing affinity rules, node selector and tolerations

address-parser deployment has some predefined affinity rules, as listed below:

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
                  - address-parser
          topologyKey: kubernetes.io/hostname
```

This affinity rules can be overridden through custom values file and set to any required value if necessary.

There are no defaults for node selector or tolerations, but there is a possibility to define both by adding their
specifications, for example:

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

There are some other customizable attributes predefined in address-parser application.

One of them is related to HTTP return code which is returned by application if health check fails.
Default value for this attribute is 418 but it can be customized if necessary, for example:

```yaml
healthStatusDownReturnCode: "499" # default value is 418
```

There's a possibility to define a custom timezone (there is no default one), by simply defining following attribute:

```yaml
timezone: Europe/London
```

Finally, since address-parser is a Java application, there's a possibility to set custom JVM parameters.
There is a predefined value which specifies `Xms` and `Xmx` JVM parameters:

```yaml
javaOpts: "-Xms256M -Xmx256M" # default value
```

This value can be changed by modifying existing parameters or adding custom, for example:

```yaml
javaOpts: "-Xms256M -Xmx512M -Dcustom.jvm.param=true"
```

Note that defining custom `javaOpts` attribute will override default one, so make sure to keep `Xms` and `Xmx`
parameters.

### Metrics configuration

Application can expose metrics to Prometheus monitoring system.
By default, this is enabled and default metrics are exposed.
With `metrics` configuration additional metrics can be exposed.

```yaml
prometheus:
  exposed: true
metrics:
  jvm: true                 # JVM metrics
  executor: true            # Async task executors using thread pools metrics
```