# Person registry application

## Purpose

This Helm chart installs Person registry application into your Kubernetes cluster.

Helm release name set during installation will be used for naming all resources created by this Helm chart.
For example, if Chart is installed with name "my-chart", deployment name will have "my-chart" prefix, as well as all configmaps, secrets and other resources created by this chart.
It is possible to override this behavior and to set custom name for resources using attribute `nameOverride` in custom values file.
If this attribute is set, it's value will be used to name all the resources, and release name will be ignored.

It is not possible to install application using default values only, there is a list of required attributes which should be applied when installing Person registry.

## Required setup

Required attributes should be defined in custom values file in `yaml` format (recommended) or propagated with `--set key=value` command during CLI installation, for example:

`helm upgrade --install person-registry holisticpay/person-registry -f my-values.yaml` or

`helm upgrade --install person-registry holisticpay/person-registry --set required-key1=value1 --set required-key2=value2 ...`

Required values are (in `yaml` format):

```yaml
env:
  type: "test" # string value, possible values: dev, test, preprod, prod
  label: "t1" # string value
secret:
  decryptionKey: "my-encryption-key" # string value
  datasourcePassword: "AES-encoded-datasource-password" # string value
  kafkaPassword: "AES-encoded-kafka-password" # string value
  kafkaSchemaRegistryPassword: "AES-encoded-kafka-schema-registry-password" # string value
  liquibasePassword: "AES-encoded-liquibase-password" # string value
  searchenginePassword: "AES-encoded-searchengine-password" # string value

datasource:
  host: "datasource-host" # string value
  port: 9999 # int value
  dbName: "database-name" # string value
  user: "database-user" # string value

liquibase:
  user: "liquibase-user"  # string value
  role: "database-role"  # string value
  replicationRole: "database-replication-role" # string value
  syncOnly: false # boolean value

members:
  - businessUnit: "BU"
    applicationMember: "AM"
    memberSign: "BA"

kafka:
  user: "kafka-user" # string value
  servers: "kafka-server:port" # string value
  schemaRegistry:
    user: "kafka-schema-registry-user" # string value
    url: "kafka-schema-registry-url" # string value

imagePullSecrets:
  - name: "image-pull-secret-name" # string value
```

One set of mandatory attributes is `env` block which describes environment to which application is installed.

Attribute `env.type` defines environment type. This attribute has a list of supported values: `dev`, `test`, `preprod` and `prod`. This value instructs liquibase to apply correct database parametrization for correct purpose.

Other environment attribute is `env.label` which should hold short environment label, for instance `t1` for first test environment, or `d2` for second development environment. This attribute is used to generate database schema name.

Person registry application relies on PostgreSQL database and Kafka backends.
In order to assure connectivity to those backends, it's required to set basic info into values file.

Additionally, liquibase is enabled by default, which requires some information in order to run successfully. Either this information has to be provided, or liquibase has to be disabled with `liquibase.enabled` attribute set to `false`.

Person registry (as well as all other HolisticPay applications) is a multi-member application. For this reason, at least one application member has to be defined in `members` structure for complete setup. Please refer to [Multi-member setup](#multi-member-setup) for details.

### Datasource connection setup

All values required for PostgreSQL database connection are defined within `datasource` parent attribute.
Application will not be able to connect to database if all attributes are not filled.

Required datasource attributes:

```yaml
datasource:
  host: "db-hostname" # only PostgreSQL hostname has to be defined (for instance "localhost")
  port: 5432 # PostgreSQL port number 
  dbName: "database-name" # Name of PostgreSQL database
  user: "database-user" # User which application will use to connect to PostgreSQL
```

Datasource schema name is auto-generated. For this information, as well as advanced datasource options, please refer to [Multi-member setup](#multi-member-setup) for details.

In addition to datasource attributes, it's required to provide an AES encrypted password for database user specified in `datasource.user`, as well as for Liquibase user defined in `liquibase.user`.

Encryption key used to encrypt and decrypt datasource and liquibase passwords (as well as Kafka passwords) is defined in `secret.decryptionKey` attribute.
Use this key to encrypt datasource and liquibase password and define them in `secret.datasourcePassword` and `secret.liquibasePassword` attributes.

Datasource secret configuration:

```yaml
secret:
  decryptionKey: "my-encryption-key" # some custom encryption key
  datasourcePassword: "{AES}S0m3H4sh" # datasource password for user defined in datasource.user encrypted with custom encryption key
  liquibasePassword: "{AES}S0m3H4sh" # AES encrypted password for Liquibase user defined in liquibase.user attribute
```

Additional datasource connection properties can be set by overriding following default attributes:

```yaml
datasource:
  connTimeout: 60000 # defines time (in ms) after which active connection will timeout and be closed
  maxPoolSize: 2 # defines max size of database connection pool
  minIdle: 0 # defines min number of retained idle connections
  idleTimeout: 120000 # defines the maximum amount of time that a connection is allowed to sit idle in the pool
```

Liquibase can be disabled if necessary with `liquibase.enabled` attribute (enabled by default):

```yaml
liquibase:
  enabled: false # disable liquibase
```

Datasource connection string can be customized by adding additional parameters to connection string (URL).
To add custom parameters, they should be defined in `datasource. connectionParams` attribute as a map of values, for example:

```yaml
datasource:
  connectionParams:
    ssl: "true"
    sslmode: "enable"
```

Setup from this example would result with string "&ssl=true&sslmode=enable" appended to database connection URL.


### Kafka setup

Person registry uses Kafka as event stream backend.
Other than Kafka cluster itself, Person registry application also uses Kafka Schema Registry, which setup also has to be provided in order to establish required connection.

To connect to Kafka cluster, several attributes have to be defined in values file.
All attributes under `kafka` parent attribute are required:

```yaml
kafka:
  user: "kafka-user" # user used to connect to Kafka cluster
  servers: "kafka-server1:port,kafka-server2:port" # a comma separated list of Kafka bootstrap servers
  schemaRegistry:
    user: "kafka-schema-registry-user" # user used to connect to Kafka Schema Registry
    url: "https://kafka.schema.registry.url" # URL for Kafka Schema Registry
```

As for database, passwords for Kafka cluster and Kafka Schema Registry are also AES encrypted.
Passwords should be defined with `secret.kafkaPassword` and `secret.kafkaSchemaRegistryPassword` attributes, for example:

```yaml
secret:
  decryptionKey: "my-encryption-key" # some custom encryption key
  kafkaPassword: "{AES}S0m3H4sh" # AES encrypted password for Kafka cluster user defined in kafka.user, encrypted with custom encryption key
  kafkaSchemaRegistryPassword: "{AES}S0m30th3rH4sh" # AES encrypted password for Kafka Schema Registry user defined in kafka.schemaRegistry.user, encrypted with custom encryption key
```

Note that same `secret` attribute is used for both datasource and Kafka, so the same encryption/decryption key is used for encrypting passwords for both backends.

Default Kafka cluster and Kafka Schema registry connection type used by Person registry is Basic auth (username and password).
If different connection type should be used, it's possible to override default setup by changing following attributes:

```yaml
kafka:
  saslMechanism: PLAIN # default value, set custom mechanism if required
  securityProtocol: SASL_SSL # default value, set custom protocol if required
```
The ssl endpoint identification is set to default ([More info](https://docs.confluent.io/platform/current/kafka/authentication_ssl.html#id1)):
```yaml
kafka:
  sslEndpointIdentAlg: HTTPS # default value is HTTPS, set other ssl endpoint identification algorithm if required
```

#### Topics and consumer groups setup

Kafka topics and consumer group names used by Person registry have default names defined in `values.yaml` file, but can be overridden with following setup:

```yaml
kafka:
  topics:
    personreplicateddata:
      name: hr.vestigo.hp.personreplicateddata # default value, set custom name if required
      consumerGroup: hr.vestigo.hp.personreplicateddata # default value, set custom name if required
    personregistrylinks:
      name: hr.vestigo.hp.personregistrylinks # default value, set custom name if required
      consumerGroup: hr.vestigo.hp.personregistrylinks # default value, set custom name if required
    matchabilityflag:
      name: hr.vestigo.hp.matchabilityflag # default value, set custom name if required
      consumerGroup: hr.vestigo.hp.matchabilityflag # default value, set custom name if required
    personcrosscheck:
      name: hr.vestigo.hp.personcrosscheck # default value, set custom name if required
      consumerGroup: hr.vestigo.hp.personcrosscheck # default value, set custom name if required
    personcrosscheckdelay:
      name: hr.vestigo.hp.personcrosscheckdelay # default value, set custom name if required
      consumerGroup: hr.vestigo.hp.personcrosscheckdelay # default value, set custom name if required
      delayTime: 30 # Duration of delay in consumption of a message published on event broker topic personCrossCheck. Default value, set custom value if required
    replicateddata:
      name: hr.vestigo.hp.replicateddata # default value, set custom name if required
      consumerGroup: hr.vestigo.hp.replicateddata # default value, set custom name if required
    personlink:
      name: hr.vestigo.hp.personlink # default value, set custom name if required
      consumerGroup: hr.vestigo.hp.personlink # default value, set custom name if required
    preparedistributionpersonreplicateddata:
      name: hr.vestigo.hp.preparedistributionpersonreplicateddata # default value, set custom name if required
    distributepersonreplicateddata:
      name: hr.vestigo.hp.distributepersonreplicateddata # default value, set custom name if required
```

#### Kafka message producer setup

Kafka messages are produced with outbox pattern, see https://microservices.io/patterns/data/transactional-outbox.html. 
Service default behaviour is without CDC - Change Data Capture, where business process insert into OUTBOX_EVENT table and on commit other process reads from table delete record, publish to topic (personCrossCheck) and commit changes on DB (for each record separately).

Parameters for case when Change Data Capture is not available on target environment are defined with default values in `values.yaml` file, but can be overridden with following setup:

```yaml
kafka:
  outbox:
    deleteEntity: false # default value, set custom name if required
    scheduler:
      enabled: true # default value, set custom name if required
      fixedRate: 10000 # default value, set custom name if required      
```
In case Change Data Capture is available on target environment it should be used. 
In that case parameter deleteEntity should be set on true and scheduler enabled on false.
Topic personCrossCheck is then configured as CDC on table OUTBOX_EVENT.

#### Kafka message consumer setup

Kafka messages are consumed after service instantiation. With parameter initializationPause it is possible to pause kafka message consumption while MS initialization process is running
(e.g. while initially full load in Search engine is running).

```yaml
kafka:
  consumer:
    initializationPause: false # default value, set custom name if required
```      

### Search engine setup

Person registry can use Opensearch or Elasticsearch as search engine.

To connect to search engine cluster, several attributes have to be defined in values file.

```yaml
searchengine:
  instance: "opensearch" # default value, search engine instance, Values: opensearch, elasticsearch, none
  hostnames: "hostname1,hostname2" # a comma separated list of search engine server
  port: 9200 # default value, set custom port used to connect to search engine server
  scheme: https # defualt value, set scheme used to connect to search engine server Values: http/https
  username: "searchengine-user" # user used to connect to search engine server
  load:
    enabled: false # defualt value, enable initial full load in search engine Values: true/false
    limit: 10000 # default value, set custom value for bulk load in search engine
    reloadFixedRate: 300000 # default value (every 5 minutes), set custom value for delay between reload to search engine that will be used in case of search engine unavailability (store & forward functionality)
    reloadLimit: 1 # default value, set custom value for number of records that will be sent to search engine in one bulk request (store & forward functionality)
  index:
    perreg:
    - memberSign: '' # no default value, member sign
      prefixName: '' # no default value, index prefix name
      shards: 1 # default number, set custom number of index shards depending on requirement and number of documents
      replicas: 0 # default number, set custom number of index replicas depending on requirement and number of servers
      version: 01 # default version, set custom number of index version, starting from 01, 02, ... and increase by one while increasing index version
```

As for database, passwords for search engine is also AES encrypted.
Passwords should be defined with `secret.searchenginePassword` attribute, for example:

```yaml
secret:
  decryptionKey: "my-encryption-key" # some custom encryption key
  searchenginePassword: "{AES}S0m3H4sh" # AES encrypted password for search engine user defined in searchengine.username, encrypted with custom encryption key 
```

Note that same `secret` attribute is used for datasource, Kafka and search engine, so the same encryption/decryption key is used for encrypting passwords for backends.

Default search engine connection type used by Person registry is Basic auth (username and password).


### Service param

Person registry service parameters.

```yaml
technicalUserId: "person-registry-technical-user-id" # technical user used while producing messages in topic personcrosscheck  
deliveryChannel: "person-registry-deliverychannel" # topic header attribute for the delivery channel
appModule: "person-registry-appModule" # topic header attribute for the application module
```

### Configuring image source and pull secrets

By default, Person registry image is pulled directly from Vestigo's repository hosted by Docker Hub.
Same applies for Liquibase image.
If mirror registry is used for example, image source can be modified for one or both images using following attributes:

```yaml
image:
  registry: custom.image.registry # will be used as default for both images, docker.io is default
  app:
    registry: custom.app.image.registry # will override image.registry for Person registry app
  liquibase:
    registry: custom.liquibase.image.registry # will override image.registry for Liquibase
```

Default pull policy is set to `IfNotPresent` but can also be modified for one or both images, for example:

```yaml
image:
  pullPolicy: Always # will be used as default for both images, default is IfNotPresent
  app:
    pullPolicy: Never # will override image.pullPolicy for Person registry image
  liquibase:
    pullPolicy: IfNotPresent # will override image.pullPolicy for Liquibase image
```

Person registry image tag is normally read from Chart definition, but if required, it can be overridden with attribute `image.app.tag`, for example:

```yaml
image:
  app:
    tag: custom-tag
```

Person registry image is located on Vestigo's private Docker Hub registry, and if image registry is set to docker.io, pull secret has to be defined.
Pull secret is not set by default, and it should be created prior to Person registry installation in target namespace.
Secret should contain credentials provided by Vestigo.

Once secret is created, it should be set with `imagePullSecrets.name` attribute, for example:

```yaml
imagePullSecrets:
  - name: vestigo-dockerhub-secret
```

### TLS setup

Person registry application is prepared to use TLS, but requires provided server certificate.
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
**Note that this secret has to be created in target namespace prior to installation of Person registry application.**
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

If outbound resources (Kafka or database) require TLS connection, trust store with required certificates should also be provided.

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
  - name: trust-store-volume-name # has to match name in initContainer and volumeMount in person-registry container
    emptyDir: # any other volume type is OK
      medium: "Memory"
```

person-registry container should also mount this volume, so a custom `volumeMount` is required, for example:

```yaml
customMounts:
  - name: trust-store-volume-name # has to match name in initContainer and volumeMount in person-registry container
    mountPath: /some/mount/path # this path should be used for custom environment variables
```

Note that `mountPath` variable is used to specify a location of trust store in person-registry container.
Suggested location is: `/mnt/k8s/trust-store`.

To make trust store available to underlying application server, its location (absolute path - `mountPath` and file name) should be defined in following environment variables:

```yaml
customEnv:
  - name: SPRING_KAFKA_PROPERTIES_SSL_TRUSTSTORE_LOCATION
    value: /some/mount/path/trust-store-file # path defined in volumeMount, has to contain full trust store file location
  - name: SPRING_KAFKA_PROPERTIES_SSL_TRUSTSTORE_TYPE
    value: JKS # defines provided trust store type (PKCS12, JKS, or other)
  - name: SSL_TRUST_STORE_FILE
    value: /some/mount/path/trust-store-file # path defined in volumeMount, has to contain full trust store file location
  - name: JAVAX_NET_SSL_TRUST_STORE
    value: /some/mount/path/trust-store-file # path defined in volumeMount, has to contain full trust store file location
```

Trust store password should be AES encrypted with key provided in `secret.decryptionKey` and set to `secret.trustStorePassword`:

```yaml
secret:
  trustStorePassword: "{aes}TrustStorePassword" # AES encoded trust store password
```

#### Provide trust store from predefined secret

Trust store can also be provided by using predefined secret.
**Note that this secret has to be created in target namespace prior to installation of Person registry application.**
Additionally, both certificate and key files should be in one single secret.

When adding trust store as secret, following values have to be provided:

```yaml
mountTrustStoreFromSecret:
  enabled: true # boolean value, default is false
  secretName: "name-of-trust-store-secret" # string value
  trustStoreName: "name-of-trust-store-file-from-secret" # string value
  trustStoreType: "type-of-trust-store" # string value, default is JKS
```

`trustStoreName` is the actual name of the trust store file itself, as defined in secret.

Those two parameters are joined together to form an absolute path to trust store file.

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

When `mountCaFromSecret` is enabled, application will import all certificate files from secret to existing trust store.

Note that either `mountTrustStoreFromSecret` or `mountCaFromSecret` can be used, if both are enabled, `mountTrustStoreFromSecret` will be used.

#### Provide mTLS key store from `initContainer`

mTLS support can be added to person-registry application in two different ways.

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
  - name: key-store-volume-name # has to match name in initContainer and volumeMount in person-registry container
    emptyDir: # any other volume type is OK
      medium: "Memory"
```

person-registry container should also mount this volume, so a custom `volumeMount` is required, for example:

```yaml
customMounts:
  - name: key-store-volume-name # has to match name in initContainer and volumeMount in person-registry container
    mountPath: /some/mount/path # this path should be used for custom environment variables
```

Note that `mountPath` variable is used to specify a location of key store in person-registry container.
Suggested location is: `/mnt/k8s/trust-store`.

To make key store available to underlying application server, its location (absolute path - `mountPath` and file name) should be defined in environment variable.
Additionally, key store type should also be defined, for example:

```yaml
customEnv:
  - name: SERVER_SSL_KEY_STORE_FILE
    value: /some/mount/path/key-store-file # path defined in volumeMount, has to contain full key store file location
  - name: SSL_KEY_STORE_TYPE
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
**Note that this secret has to be created in target namespace prior to installation of Person registry application.**

When adding key store from secret, following values have to be provided:

```yaml
mountKeyStoreFromSecret:
  enabled: true # boolean value, default is false
  secretName: "name-of-key-store-secret" # string value
  keyStoreName: "name-of-key-store-file-from-secret" # string value
  keyStoreType: "type-of-key-store" # string value, default is JKS
```

`keyStoreName` is the actual name of the key store file itself, as defined in secret.

Those two parameters are joined together to form an absolute path to key store file.

Default key store type is JKS and if other type of key store file is provided, it has to be specified in `keyStoreType` attribute, for example "PKCS12".

Key store password has to be provided as AES encoded string in `secret.keyStorePassword` attribute.
Password should be encrypted with the key defined in `secret.decryptionKey`.

```yaml
secret:
  keyStorePassword: "{aes}KeyStorePassword" # AES encoded trust store password
```

When using secret to mount key store, no additional custom setup is required.

## Customizing installation

Besides required attributes, installation of Person registry can be customized in different ways.

### Multi-member setup

Person registry application (along with all other HolisticPay applications) supports multi-member setup. In order to complete application setup, at least a mandatory set of attributes has to be defined:

```yaml
members:
  - businessUnit: "BU"
    applicationMember: "AM"
    memberSign: "MS"
```

This setup is required and will define one member in application with default setup. By default, with one specified member, two database schemas will be defined - "connect" schema, which is a default schema for non-member-specific requests and one member-specific datasource schema in the same database.
Schema name for application member is auto-generated and will be in format `{members.businessUnit}{members.applicationMember}perreg{env.label}`.

`members` attribute enables customization on database level. It is possible to override specific datasource and liquibase parameters for each member separately.

List of all attributes which can be overridden:

```yaml
members:
  - businessUnit: ""
    applicationMember: ""
    memberSign: ""
    liquibase:
      user: ""
      role: ""
      replicationRole: ""
      syncOnly: false
    datasource:
      globalSchema: false
      host: ""
      port: ""
      dbName: ""
      user: ""
      password: ""
```

Each attribute within `members.datasource` and `members.liquibase` can be defined to override same values defined in `datasource` and `liquibase` blocks.

For instance, if value of `member.datasource.dbName` attribute is modified, this value will be used instead of `datasource.dbName` for this member's datasource definition.
Same logic is applied for all attributes.

#### Database setup for multi-member

Person registry provides option to setup database in several different flavors:

- all members in one database and one schema
- all members in one database with multiple member-specific schemas
- all members in member-specific databases

For first option (all-in-one), it's necessary to set `members.datasource.globalSchema` attribute to `true` (default is `false`).
When this option is enabled, generated schema name will no longer include `members.applicationMember`, but will instead hold value defined in `datasource.globalSchemaPrefix` attribute, which is set to "wo" by default.
Note that `members.businessUnit` will still be a part of schema name, as it's not possible to have a single schema in combination with multiple business units.

For instance, with setup like this one:

```yaml
environment:
  label: "t1"

members:
  - businessUnit: "AA"
    applicationMember: "BB"
    datasource:
      globalSchema: true
```

application will bind to schema with name `aawoperregt1`.
To change default `wo` prefix used in schema name, set attribute `datasource.globalSchemaPrefix` to other value.

Note that `members.datasource.globalSchema` is member-specific, so when multiple members are defined, in order to keep all data in one schema, all members have to be defined with this attribute set to `true`.
Otherwise, member with `globalSchema` attribute set to `false` will use its own schema.

For example, with following setup, one member would use global schema and one would use member-specific schema:

```yaml
members:
  - businessUnit: "AA"
    applicationMember: "BB"
    datasource:
      globalSchema: true
  - businessUnit: "AA"
    applicationMember: "CC"
    # datasource.globalSchema is not overridden, member-specific schema will be used for this member
```

Second option is to use a member-specific schemas for each member.
This is a default setup, so if `members.datasource.globalSchema` is not set to `true`, member-specific schema will be used. With this setup, each member will use its own schema in one common database.

Final option is to use a separate database (even on different host).
For this setup, `members.datasource` parameters have to be overridden for each member that required separate database.

For example, this setup would use different databases for default schema ("connect") and one additional for each member:

```yaml
datasource:
  host: "host1"
  port: "5432"
  dbName: "db1"

members:
  - businessUnit: "AA"
    applicationMember: "BB"
    memberSign: "AB"
    datasource:
      host: "host2"
      # port is not defined, datasource.port will be used
      dbName: "db2"
  - businessUnit: "AA"
    applicationMember: "CC"
    memberSign: "AC"
    datasource:
      # host and port are not defined, same datasource.host and datasource.port will be used, so this member will end up in same host as default "connect" schema
      dbName: "db3"
```

#### Searchengine setup for multi-member

Each member data are stored in different search engine index. For each application member next parameters must be defined
(in case search engine is used): index name prefix, number of shards for index, number of replicas for index and index 
version (example below).

```yaml
searchengine:  
  index:
    perreg:
    - memberSign: 'CC' 
      prefixName: 'gw.t1.spr.reg.cc.superpersona' 
      shards: 3 
      replicas: 2 
      version: 02 
    - memberSign: 'CE'
      prefixName: 'gw.t1.spr.reg.ce.superpersona'
      shards: 1
      replicas: 2
      version: 01 
```

### oAuth2

Person registry application can use oAuth2 service for authorization. By default, this option is disabled, but can easily be enabled by specifying following attributes in values:

```yaml
oAuth2:
  enabled: true # default is false
  resourceUri: "" # has to be specified if enabled, no default value
  authorizationPrefix: "" # defines variable prefix of the scope/role
```

To configure oAuth2, it first has to be enabled with `oAuth2.enabled` parameter.
When enabled, `oAuth2.resourceUri` should also be defined.
This URI should point to oAuth2 server with defined converter type and name, for example `https://oauth2.server/realm/Holistic-Pay`.
If scope/role has variable prefix, which should not be considered as full role/scope name, this variable prefix should be defined. Every part of this variable part should be defined (e.g. if scopes are defined as MY_PREFIX:scope1 MY_PREFIX:scope2 etc, then variable prefix is 'MY_PREFIX:') 

### Request body sanitization and response body encoding

Person registry application provides security mechanism in order to prevent injection attacks. Mechanisms to achieve this are Input data sanitization and Output data encoding. By default, sanitization is enabled and encoding is disabled. If any of these needs to be changed, this can be configured via next parameters:
```yaml
request:
  sanitization:
    enabled: true
    
response:
  encoding:
    enabled: false
```


### Adding custom environment variables

Custom environment variables can be added to person-registry container by applying `customEnv` value, for example:

```yaml
customEnv:
  - name: MY_CUSTOM_ENV
    value: some-value 
  - name: SOME_OTHER_ENV
    value: 123
```

### Adding custom mounts

Values file can be used to specify additional custom `volume` and `volumeMounts` to be added to person-registry container.

For example, custom volume mount could be added by defining this setup:

```yaml
customVolumes:
  - name: my-custom-volume # has to match name in initContainer and volumeMount in person-registry container
    emptyDir: # any other volume type is OK
      medium: "Memory"

customMounts:
  - name: my-custom-volume # has to match name in initContainer and volumeMount in person-registry container
    mountPath: /some/mount/path # this path should be used for custom environment variables
```

### Customizing container logs

Person registry application is predefined to redirect all logs to `stdout` expect for Web Server logs (`access.log`) and health check logs, which are not logged by default.
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

With this basic setup, container will start to log files into a predefined "/var/log/app" location with basic file appender.
In order to set custom log location or to enable rolling file appender, two additional attributes have to be defined:

```yaml
logger:
  logToFile: true # boolean value, default is false
  rollingFileAppender: true # boolean value, default is false
  logDir: "/custom/log/folder"
```

When defining custom log location, make sure folder either already exists in container or is mounted with `logDirMount` variable, for example:

```yaml
logger:
  logToFile: true # boolean value, default is false
  rollingFileAppender: true # boolean value, default is false
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
  rollingFileAppender: true # boolean value, default is false
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

Logging levels are used to categorize the entries in the log file, possible levels include 
`TRACE`, `DEBUG`, `INFO`, `WARN` and `ERROR`. 
It is possible to control which logging level will be visible in the log file for a specific category, these categories are:

- `health` - health check logs
- `kafka` - kafka-related logs
- `rest` - rest-related logs
- `database` - database access logs
- `businessLogic` - logs related to business logic
- `general` - all other logs not included in the above categories

```yaml
logger:
  level:
    health: DEBUG # logs for DEBUG level and higher (DEBUG, INFO, WARN and ERROR) will be shown, default level is DEBUG
    kafka: TRACE # logs for TRACE level and higher (TRACE, DEBUG, INFO, WARN and ERROR) will be shown, default level is DEBUG
    rest:  DEBUG # logs for DEBUG level and higher (DEBUG, INFO, WARN and ERROR) will be shown, default level is DEBUG
    database: INFO # logs for INFO level and higher (INFO, WARN and ERROR) will be shown, default level is DEBUG
    businessLogic: WARN # logs for WARN level and higher (WARN and ERROR) will be shown, default level is DEBUG
    general: ERROR # only ERROR level logs will be shown, default level is DEBUG
  ```

If you want to include in your logs, the name of the microservice which generates the logs, you can do so by setting the value of the name of the microservice in the attribute `logger.microserviceTag`.
By default, this attribute is set to empty string.
```yaml
logger:
  microserviceTag: ''
```

### Modifying deployment strategy

Default deployment strategy for Person registry application is `RollingUpdate`, but it can be overridden, along with other deployment parameters using following attributes (default values are shown):

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

By default, one replica of Person registry is installed on Kubernetes cluster. Number of replicas can be statically modified with above configuration, or `HorizontalPodAutoscaler` option can be used to let Kubernetes automatically scale application when required.

#### Customizing pod resource requests and limits

Following are the default values for Person registry requests and limits:

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

Since application uses Liquibase as init container, resources can be defined for this container also.

Resources for Liquibase can be set with `liquibase.resources` attribute. This attribute has no defaults (empty), but if it's not defined, main container's resources will be used.
For example, using following setup, resources defined within `liquibase` attribute would be used over attributes for main container (defined in root `resources` attribute):

```yaml
resources:
  limits:
    cpu: 2
    memory: 1Gi
  requests:
    cpu: 100m
    memory: 1Gi

liquibase:
  resources:
    limits:
      cpu: 1
      memory: 128Mi
    requests:
      cpu: 100m
      memory: 128Mi
```

With this setup, Liquibase init container would have limits set to 1 CPU and 128Mi of memory and requests to 100m and 128Mi.
If Liquibase resource was not defined, Liquibase init container would have limits set to 2 CPU and 1Gi and request to 100m and 1Gi.


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

CPU and/or memory utilization metrics can be used to autoscale Person registry pod.
It's possible to define one or both of those metrics.
If only `autoscaling.enabled` attribute is set to `true`, without setting other attributes, only CPU utilization metric will be used with percentage set to 80.

#### Using `VerticalPodAutoscaler`
By default, VPA is disabled in configuration, but it can enabled with following setup:
```yaml
vpa:
enabled: true # default is false, has to be set to true to enable VPA
updateMode: Off # default mode if Off, other possible values are "Initial", "Recreate" and "Auto"
```


### Customizing probes

Person registry application has predefined health check probes (readiness and liveness).
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

Note that Person registry has health checks available within the `/health` endpoint (`/health/readiness` for readiness and `/health/liveness` for liveness), and this base paths should not modified, only query parameters are subject to change.
`scheme` attribute should also be set to `HTTPS` at all times, as well as `http` value for `port` attribute.

### Customizing security context

Security context for Person registry can be set on pod and/or on container level.
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

Note that container level security context will be applied to both containers in Person registry pod (Liquibase init container and Person registry container).

### Customizing network setup

#### Service setup

When installing Person registry using default setup, a `Service` object will be created of `ClusterIP` type exposed on port 8443.
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
    - host: person-registry.custom.url
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

Person registry deployment has some predefined affinity rules, as listed below:

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
                  - person-registry
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

There are some other customizable attributes predefined in Person registry application.

One of them is related to HTTP return code which is returned by application if health check fails.
Default value for this attribute is 418 but it can be customized if necessary, for example:

```yaml
healthStatusDownReturnCode: "499" # default value is 418
```

There's a possibility to define a custom timezone (there is no default one), by simply defining following attribute:

```yaml
timezone: Europe/London
```

Finally, since Person registry is an Java application, there's a possibility to set custom JVM parameters.
There is a predefined value which specifies `Xms` and `Xmx` JVM parameters:

```yaml
javaOpts: "-Xms256M -Xmx256M" # default value
```

This value can be changed by modifying existing parameters or adding custom, for example:

```yaml
javaOpts: "-Xms256M -Xmx512M -Dcustom.jvm.param=true"
```

Note that defining custom `javaOpts` attribute will override default one, so make sure to keep `Xms` and `Xmx` parameters.
