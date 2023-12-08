# Person registry web application

## Purpose

This Helm chart installs Save The Cloud web application into your Kubernetes cluster.

Helm release name set during installation will be used for naming all resources created by this Helm chart.
For example, if Chart is installed with name "my-chart", deployment name will have "my-chart" prefix, as well as all configmaps, secrets and other resources created by this chart.
It is possible to override this behavior and to set custom name for resources using attribute `nameOverride` in custom values file.
If this attribute is set, its value will be used to name all the resources, and release name will be ignored.

It is not possible to install application using default values only, there is a list of required attributes which should be applied when installing Person registry web.

## Required setup

Required attributes should be defined in custom values file in `yaml` format (recommended) or propagated with `--set key=value` command during CLI installation, for example:

`helm upgrade --install save-the-cloud-web dev-tools/save-the-cloud-web -f my-values.yaml` or

`helm upgrade --install save-the-cloud-web dev-tools/save-the-cloud-web --set required-key1=value1 --set required-key2=value2 ...`

Required values are (in `yaml` format):

```yaml
apiGatewayUrl: "" # string value

imagePullSecrets:
  - name: "image-pull-secret-name" # string value
```

Person registry web applications requires a location (endpoint) of API Gateway through which it will be called (defined with `apiGatewayUrl` attribute).

### TLS setup

Person registry application is prepared to use TLS, but requires provided server certificate.
Server certificate is not provided by default but is expected to be provided manually.
There are several different possibilities for customizing TLS setup.

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
**Note that this secret has to be created in target namespace prior to installation of Person registry web application.**
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

## Customizing installation

Besides required attributes, installation of Person registry web application can be customized in different ways.

### oAuth2

Person registry web application can use oAuth2 service for authorization. By default, this option is disabled, but can easily be enabled by specifying following attributes in values:

```yaml
oauth2:
  enabled: true
  realm: Holistic-Pay # default value, specify other if required
  serverUrl: "" # no default value
  resource: aux # default value, specify other if required

secret:
  keycloakClientToken: "" # no default value
```

To configure oAuth2, it first has to be enabled with `oauth2.enabled` parameter.
When enabled, other parameters should be defined.

First parameter is realm name which is defined in oAuth2. Default value for this parameter is `Holistic-Pay`, but it can be modified with `oauth2.realm` attribute.

Second parameter is oAuth2 server URL which has to be defined (has no default value). URL should contain oAuth2 server FQDN, followed by `/auth` endpoint, for example: `https://oAuth2.custom.domain/auth`.

Third parameter is used to define oAuth2 client ID, which is by default set to `aux`.
This value can be modified with `oauth2.resource` attribute.

Final parameter to set is Keycloak client token, which should be set with `secret.oauth2ClientToken` attribute. This is an AES encrypted token which is encrypted using the same encryption key as other secrets (`secret.decryptionKey`).

### Request body sanitization and response body encoding

Partner bank interface application provides security mechanism in order to prevent injection attacks. Mechanisms to achieve this are Input data sanitization and Output data encoding. By default, sanitization is enabled and encoding is disabled. If any of these needs to be changed, this can be configured via next parameters:

```yaml
request:
  sanitization:
    enabled: true
    
response:
  encoding:
    enabled: false
```

### Setting application environment

Application can display environment name on logon screen and in main screen.
This name can be easily customized by setting `environmentName` attribute to a desired value (default value is "TEST"):

```yaml
environmentName: "TEST 3"
```

### Changing application HTTP session timeout

By default, HTTP session timeout in application is set to 4 hours (14400 seconds).
This time can be modified by changing `httpSessionTimeout` attribute to a desired value:

```yaml
httpSessionTimeout: "3600"
```

Note that value is defined in seconds, which means that with this example timeout will be set to 1 hour.

### Adding custom environment variables

Custom environment variables can be added to save-the-cloud-web container by applying `customEnv` value, for example:

```yaml
customEnv:
  - name: MY_CUSTOM_ENV
    value: some-value
  - name: SOME_OTHER_ENV
    value: 123
```

### Adding custom mounts

Values file can be used to specify additional custom `volume` and `volumeMounts` to be added to save-the-cloud-web container.

For example, custom volume mount could be added by defining this setup:

```yaml
customVolumes:
  - name: my-custom-volume # has to match name in initContainer and volumeMount in save-the-cloud-web container
    emptyDir: # any other volume type is OK
      medium: "Memory"

customMounts:
  - name: my-custom-volume # has to match name in initContainer and volumeMount in save-the-cloud-web container
    mountPath: /some/mount/path # this path should be used for custom environment variables
```

### Modifying deployment strategy

Default deployment strategy for Person registry web application is `RollingUpdate`, but it can be overridden, along with other deployment parameters using following attributes (default values are shown):

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

By default, one replica of Person registry web is installed on Kubernetes cluster. Number of replicas can be statically modified with above configuration, or `HorizontalPodAutoscaler` option can be used to let Kubernetes automatically scale application when required.

#### Customizing pod resource requests and limits

Following are the default values for Person registry web requests and limits:

```yaml
resources:
  limits:
    cpu: 500m
    memory: 64Mi
  requests:
    cpu: 50m
    memory: 10Mi
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

CPU and/or memory utilization metrics can be used to autoscale Person registry web pod.
It's possible to define one or both of those metrics.
If only `autoscaling.enabled` attribute is set to `true`, without setting other attributes, only CPU utilization metric will be used with percentage set to 80.

### Customizing probes

Person registry web application has predefined health check probes (readiness and liveness).
Following are the default values:

```yaml
deployment:
  readinessProbe:
    initialDelaySeconds: 10
    periodSeconds: 60
    timeoutSeconds: 10
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

Note that Person registry web has health checks available within the `/health` endpoint (`/health/readiness` for readiness and `/health/liveness` for liveness), and this base paths should not modified, only query parameters are subject to change.
`scheme` attribute should also be set to `HTTPS` at all times, as well as `http` value for `port` attribute.

### Customizing security context

Security context for Person registry web can be set on pod and/or on container level.
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

### Customizing network setup

#### Service setup

When installing Person registry web using default setup, a `Service` object will be created of `ClusterIP` type exposed on port 8443.
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
    - host: save-the-cloud-web.custom.url
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

Person registry web deployment has some predefined affinity rules, as listed below:

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
                  - save-the-cloud-web
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

There are some other customizable attributes predefined in Person registry web application.

There's a possibility to define a custom timezone (there is no default one), by simply defining following attribute:

```yaml
timezone: Europe/London
```
