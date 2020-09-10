# Dgraph

Dgraph is a horizontally scalable and distributed graph database, providing ACID transactions,
consistent replication and linearizable reads. It's built from the ground up to perform for a rich set
of queries. Being a native graph database, it tightly controls how the data is arranged on disk to
optimize for query performance and throughput, reducing disk seeks and network calls in a cluster.

### TL;DR;

```sh
$ helm repo add dgraph https://charts.dgraph.io
$ helm install my-release dgraph/dgraph
```

### Introduction

This chart bootstraps [Dgraph](https://dgraph.io) cluster deployment on a
Kubernetes cluster using [Helm](https://helm.sh) package manager.

### Prerequisites

- Kubernetes 1.14+
- Helm 3.0+

### Installing the Chart

To install the chart with the release name `my-release`:

```bash
$ helm repo add dgraph https://charts.dgraph.io
$ helm install my-release dgraph/dgraph
```

These commands deploy Dgraph on the Kubernetes cluster in the default configuration.
The [Configuration](#configuration) section lists the parameters that can be configured during installation:

> **Tip**: List all releases using `helm list`

### Uninstalling the Chart

To uninstall/delete the `my-release` resources:

```bash
$ helm delete my-release
```

The command above removes all the Kubernetes components associated
with the chart and deletes the release.

Deletion of the StatefulSet doesn't cascade to deleting associated PVCs. To delete them:

```
$ kubectl delete pvc -l release=my-release,chart=dgraph
```

## Configuration

The following table lists the configurable parameters of the `dgraph` chart and their default values.

|              Parameter                   |                             Description                               |                       Default                       |
| ---------------------------------------- | --------------------------------------------------------------------- | --------------------------------------------------- |
| `image.registry`                         | Container registry name                                               | `docker.io`                                         |
| `image.repository`                       | Container image name                                                  | `dgraph/dgraph`                                     |
| `image.tag`                              | Container image tag                                                   | `v20.07.0`                                          |
| `image.pullPolicy`                       | Container pull policy                                                 | `IfNotPresent`                                      |
| `nameOverride`                           | Deployment name override (will append the release name)               | `nil`                                               |
| `fullnameOverride`                       | Deployment full name override (the release name is ignored)           | `nil`                                               |
| `zero.name`                              | Zero component name                                                   | `zero`                                              |
| `zero.updateStrategy`                    | Strategy for upgrading zero nodes                                     | `RollingUpdate`                                     |
| `zero.monitorLabel`                      | Monitor label for zero, used by prometheus.                           | `zero-dgraph-io`                                    |
| `zero.rollingUpdatePartition`            | Partition update strategy                                             | `nil`                                               |
| `zero.podManagementPolicy`               | Pod management policy for zero nodes                                  | `OrderedReady`                                      |
| `zero.replicaCount`                      | Number of zero nodes                                                  | `3`                                                 |
| `zero.shardReplicaCount`                 | Max number of replicas per data shard                                 | `5`                                                 |
| `zero.terminationGracePeriodSeconds`     | Zero server pod termination grace period                              | `60`                                                |
| `zero.antiAffinity`                      | Zero anti-affinity policy                                             | `soft`                                              |
| `zero.podAntiAffinitytopologyKey`        | Anti affinity topology key for zero nodes                             | `kubernetes.io/hostname`                            |
| `zero.nodeAffinity`                      | Zero node affinity policy                                             | `{}`                                                |
| `zero.extraEnvs`                         | extra env vars                                                        | `[]`                                                |
| `zero.configFile`                        | Zero config file                                                      | `{}`                                                |
| `zero.service.type`                      | Zero service type                                                     | `ClusterIP`                                         |
| `zero.service.annotations`               | Zero service annotations                                              | `{}`                                                |
| `zero.service.publishNotReadyAddresses`  | publish address if pods not in ready state                            | `true`                                              |
| `zero.securityContext.enabled`           | Security context for zero nodes enabled                               | `false`                                             |
| `zero.securityContext.fsGroup`           | Group id of the zero container                                        | `1001`                                              |
| `zero.securityContext.runAsUser`         | User ID for the zero container                                        | `1001`                                              |
| `zero.persistence.enabled`               | Enable persistence for zero using PVC                                 | `true`                                              |
| `zero.persistence.storageClass`          | PVC Storage Class for zero volume                                     | `nil`                                               |
| `zero.persistence.accessModes`           | PVC Access Mode for zero volume                                       | `['ReadWriteOnce']`                                 |
| `zero.persistence.size`                  | PVC Storage Request for zero volume                                   | `32Gi`                                              |
| `zero.nodeSelector`                      | Node labels for zero pod assignment                                   | `{}`                                                |
| `zero.tolerations`                       | Zero tolerations                                                      | `[]`                                                |
| `zero.resources.requests.memory`         | Zero pod resources memory requests                                    | `100Mi`                                             |
| `zero.startupProbe`                      | Zero startup probes (**NOTE**: only supported in Kubernetes v1.16+)   | See `values.yaml` for defaults                      |
| `zero.livenessProbe`                     | Zero liveness probes                                                  | See `values.yaml` for defaults                      |
| `zero.readinessProbe`                    | Zero readiness probes                                                 | See `values.yaml` for defaults                      |
| `zero.customStartupProbe`                | Zero custom startup probes (if `zero.startupProbe` not enabled)       | `{}`                                                |
| `zero.customLivenessProbe`               | Zero custom liveness probes (if `zero.livenessProbe` not enabled)     | `{}`                                                |
| `zero.customReadinessProbe`              | Zero custom readiness probes  (if `zero.readinessProbe` not enabled)  | `{}`                                                |
| `alpha.name`                             | Alpha component name                                                  | `alpha`                                             |
| `alpha.monitorLabel`                     | Monitor label for alpha, used by prometheus.                          | `alpha-dgraph-io`                                   |
| `alpha.updateStrategy`                   | Strategy for upgrading alpha nodes                                    | `RollingUpdate`                                     |
| `alpha.rollingUpdatePartition`           | Partition update strategy                                             | `nil`                                               |
| `alpha.podManagementPolicy`              | Pod management policy for alpha nodes                                 | `OrderedReady`                                      |
| `alpha.replicaCount`                     | Number of alpha nodes                                                 | `3`                                                 |
| `alpha.terminationGracePeriodSeconds`    | Alpha server pod termination grace period                             | `600`                                               |
| `alpha.antiAffinity`                     | Alpha anti-affinity policy                                            | `soft`                                              |
| `alpha.podAntiAffinitytopologyKey`       | Anti affinity topology key for zero nodes                             | `kubernetes.io/hostname`                            |
| `alpha.nodeAffinity`                     | Alpha node affinity policy                                            | `{}`                                                |
| `alpha.extraEnvs`                        | extra env vars                                                        | `[]`                                                |
| `alpha.configFile`                       | Alpha config file                                                     | `{ config.yaml: 'lru_mb: 2048' }`                   |
| `alpha.service.type`                     | Alpha node service type                                               | `ClusterIP`                                         |
| `alpha.service.annotations`              | Alpha service annotations                                             | `{}`                                                |
| `alpha.service.publishNotReadyAddresses` | publish address if pods not in ready state                            | `true`                                              |
| `alpha.ingress.enabled`                  | Alpha Ingress resource enabled                                        | `false`                                             |
| `alpha.ingress.hostname`                 | Alpha Ingress virtual hostname                                        | `nil`                                               |
| `alpha.ingress.annotations`              | Alpha Ingress annotations                                             | `nil`                                               |
| `alpha.ingress.tls`                      | Alpha Ingress TLS settings                                            | `nil`                                               |
| `alpha.securityContext.enabled`          | Security context for alpha nodes enabled                              | `false`                                             |
| `alpha.securityContext.fsGroup`          | Group id of the alpha container                                       | `1001`                                              |
| `alpha.securityContext.runAsUser`        | User ID for the alpha container                                       | `1001`                                              |
| `alpha.tls.enabled`                      | Alpha service TLS enabled                                             | `false`                                             |
| `alpha.tls.files`                        | Alpha service TLS key and certificate files stored as secrets         | `false`                                             |
| `alpha.encryption.enabled`               | Alpha Encryption at Rest enabled (Enterprise feature)                 | `false`                                             |
| `alpha.encryption.file`                  | Alpha Encryption at Rest key file (Enterprise feature)                | `nil`                                               |
| `alpha.acl.enabled`                      | Alpha ACL enabled (Enterprise feature)                                | `false`                                             |
| `alpha.acl.file`                         | Alpha ACL secret file (Enterprise feature)                            | `nil`                                               |
| `alpha.persistence.enabled`              | Enable persistence for alpha using PVC                                | `true`                                              |
| `alpha.persistence.storageClass`         | PVC Storage Class for alpha volume                                    | `nil`                                               |
| `alpha.persistence.accessModes`          | PVC Access Mode for alpha volume                                      | `['ReadWriteOnce']`                                 |
| `alpha.persistence.size`                 | PVC Storage Request for alpha volume                                  | `100Gi`                                             |
| `alpha.nodeSelector`                     | Node labels for alpha pod assignment                                  | `{}`                                                |
| `alpha.tolerations`                      | Alpha tolerations                                                     | `[]`                                                |
| `alpha.resources.requests.memory`        | Zero pod resources memory request                                     | `100Mi`                                             |
| `alpha.startupProbe`                     | Alpha startup probes (**NOTE**: only supported in Kubernetes v1.16+)  | See `values.yaml` for defaults                      |
| `alpha.livenessProbe`                    | Alpha liveness probes                                                 | See `values.yaml` for defaults                      |
| `alpha.readinessProbe`                   | Alpha readiness probes                                                | See `values.yaml` for defaults                      |
| `alpha.customStartupProbe`               | Alpha custom startup probes (if `alpha.startupProbe` not enabled)     | `{}`                                                |
| `alpha.customLivenessProbe`              | Alpha custom liveness probes (if `alpha.livenessProbe` not enabled)   | `{}`                                                |
| `alpha.customReadinessProbe`             | Alpha custom readiness probes (if `alpha.readinessProbe` not enabled) | `{}`                                                |
| `ratel.name`                             | Ratel component name                                                  | `ratel`                                             |
| `ratel.enabled`                          | Ratel service enabled or disabled                                     | `true`                                              |
| `ratel.replicaCount`                     | Number of ratel nodes                                                 | `1`                                                 |
| `ratel.extraEnvs`                        | Extra env vars                                                        | `[]`                                                |
| `ratel.service.type`                     | Ratel service type                                                    | `ClusterIP`                                         |
| `ratel.service.annotations`              | Ratel Service annotations                                             | `ClusterIP`                                         |
| `ratel.ingress.enabled`                  | Ratel Ingress resource enabled                                        | `false`                                             |
| `ratel.ingress.hostname`                 | Ratel Ingress virtual hostname                                        | `nil`                                               |
| `ratel.ingress.annotations`              | Ratel Ingress annotations                                             | `nil`                                               |
| `ratel.ingress.tls`                      | Ratel Ingress TLS settings                                            | `nil`                                               |
| `ratel.securityContext.enabled`          | Security context for ratel nodes enabled                              | `false`                                             |
| `ratel.securityContext.fsGroup`          | Group id of the ratel container                                       | `1001`                                              |
| `ratel.securityContext.runAsUser`        | User ID for the ratel container                                       | `1001`                                              |
| `ratel.resources.requests`               | Ratel pod resources requests                                          | `nil`                                               |
| `ratel.livenessProbe`                    | Ratel liveness probes                                                 | See `values.yaml` for defaults                      |
| `ratel.readinessProbe`                   | Ratel readiness probes                                                | See `values.yaml` for defaults                      |
| `ratel.customLivenessProbe`              | Ratel custom liveness probes (if `ratel.livenessProbe` not enabled)   | `{}`                                                |
| `ratel.customReadinessProbe`             | Ratel custom readiness probes (if `ratel.readinessProbe` not enabled) | `{}`                                                |
| `backups.name`                           | Backups component name                                                | `backups`                                           |
| `backups.admin.user`                     | Login user for backups (required if ACL enabled)                      | `groot`                                             |
| `backups.admin.password`                 | Login user password for backups (required if ACL enabled)             | `password`                                          |
| `backups.admin.tls_client`               | TLS Client Name (requried if `REQUIREANY` or `REQUIREANDVERIFY` set)  | `nil`                                               |
| `backups.admin.auth_token`               | Auth Token                                                            | `nil`                                               |
| `backups.image.registry`                 | Container registry name                                               | `docker.io`                                         |
| `backups.image.repository`               | Container image name                                                  | `dgraph/dgraph`                                     |
| `backups.image.tag`                      | Container image tag                                                   | `v20.07.0`                                          |
| `backups.image.pullPolicy`               | Container pull policy                                                 | `IfNotPresent`                                      |
| `backups.nfs.enabled`                    | Enable mounted NFS volume for backups                                 | `false`                                             |
| `backups.nfs.server`                     | NFS Server DNS or IP address                                           | `nil`                                               |
| `backups.nfs.path`                       | NFS Server file share path name                                        | `nil`                                               |
| `backups.nfs.storage`                    | Storage allocated from NFS volume and claim                           | `512Gi`                                             |
| `backups.nfs.mountPath`                  | Path to mount volume in Alpha (should match `backup.destination`)     | `/dgraph/backups`                                   |
| `backups.full.enabled`                   | Enable full backups cronjob                                           | `false`                                             |
| `backups.full.debug`                     | Enable `set -x` for cron shell script                                 | `false`                                             |
| `backups.full.schedule`                  | Cronjob schedule                                                      | `"0 * * * *"`                                       |
| `backups.incremental.enabled`            | Enable incremental backups cronjob                                    | `false`                                             |
| `backups.incremental.debug`              | Enable `set -x` for cron shell script                                 | `false`                                             |
| `backups.incremental.schedule`           | Cronjob schedule                                                      | `"0 1-23 * * *"`                                    |
| `backups.destination`                    | Destination - file path, s3://, minio:                                | `/dgraph/backups`                                   |
| `backups.subpath`                        | Specify subpath where full + related incremental backups are stored   | `dgraph_$(date +%Y%m%d)`                            |
| `backups.minioSecure`                    | Set to true if Minio server specified in minio:// supports TLS        | `false`                                             |
| `global.ingress.enabled`                 | Enable global ingress resource (overrides alpha/ratel ingress)        | `false`                                             |
| `global.ingress.annotations`             | global ingress annotations                                            | `{}`                                                |
| `global.ingress.tls`                     | global ingress tls settings                                           | `{}`                                                |
| `global.ingress.ratel_hostname`          | global ingress virtual host name for ratel service                    | `""`                                                |
| `global.ingress.alpha_hostname`          | global ingress virtual host name for alpha service                    | `""`                                                |


## Ingress Resource

You can define ingress resources through `alpha.ingress` for the alpha HTTP service and `ratel.ingress` for the ratel UI service, or you can use a combined single ingress with `global.ingress` for both alpha HTTP and ratel UI services.

There are some example chart values for ingress resource configuration in [example_values](https://github.com/dgraph-io/charts/tree/master/charts/dgraph/example_values).

## Zero and Alpha Configuration

Should you need additional configuration options you can add these either through environment variables or a configuration file, e.g. `config.toml`. Instructions about this configuration can be found in `values.yaml`.

There are some example values files demonstrating how to add configuration with HCL, JSON, Java Properties, TOML, and YAML file formats in [example_values](https://github.com/dgraph-io/charts/tree/master/charts/dgraph/example_values).

## Alpha TLS Options

The Dgraph alpha service can be configured to use Mutual TLS.  Instructions about this configuration can be found in `values.yaml`.  

There are some example chart values for Alpha TLS configuration in [example_values](https://github.com/dgraph-io/charts/tree/master/charts/dgraph/example_values).

### Alpha TLS Example

As an example to test this feature, you can run the following steps below.


#### Step 1: Generating Certificates and Keys

When generating the certificates and keys with `dgraph cert` command, you can use [get_alpha_list.sh](https://github.com/dgraph-io/charts/blob/master/charts/dgraph/scripts/get_alpha_list.sh) to generate a list of Alpha pod internal DNS names that can be used.  This way other services running on the cluster, such as a backup cronjob, can access the Alpha pod.

```bash
export RELEASE="my-release"
export REPLICAS=3
export NAMESPACE="default"
VERS=0.0.11

## Download Script
curl --silent --remote-name --location \
  https://raw.githubusercontent.com/dgraph-io/charts/dgraph-$VERS/charts/dgraph/scripts/get_alpha_list.sh
## create CA, Server (localhost and alpha pod hostnames), Client cert/keys in ./tls directory
dgraph cert --nodes localhost,$(bash get_alpha_list.sh) --client dgraphuser
## other clients can be created if required
dgraph cert --client backupuser
```

#### Step 3: Creating Helm Chart Secrets Config

It is recommended that you keep secrets values and config values in separate YAML files.  To assist with this practice, you can use the [make_tls_secrets.sh](https://github.com/dgraph-io/charts/blob/master/charts/dgraph/scripts/make_tls_secrets.sh) script to generate a `secrets.yaml` file from an existing `./tls` directory that was previously generated by the `dgraph cert` command.

```bash
VERS=0.0.11
## Download Script
curl --silent --remote-name --location \
  https://raw.githubusercontent.com/dgraph-io/charts/dgraph-$VERS/charts/dgraph/scripts/make_tls_secrets.sh

## create secrets.yaml from ./tls directory
bash make_tls_secrets.sh
```

#### Step 4: Deploying Helm Chart

The certificates created support and Alpha internal headless Service DNS hostnames. We can deploy a Dgraph cluster using these certs.


```bash
export RELEASE="my-release"

# Download Example Dgraph Alpha config
curl --silent --remote-name --location \
 https://raw.githubusercontent.com/dgraph-io/charts/dgraph-$VERS/charts/dgraph/example_values/alpha-tls-config.yaml

# Install Chart with TLS Certificates
helm install $RELEASE \
 --values secrets.yaml
 --values alpha-tls-config.yaml
 dgraph/dgraph
 ```

#### Step 6: Deploying Helm Chart

Now we can test GRPC with `dgraph increment`, and HTTPS with `curl`:

```bash
export RELEASE="my-release"

# Port Forward Alpha GRPC to localhost (use other terminal tab)
kubectl port-forward $RELEASE-dgraph-alpha-0 9080:9080 &
# Port Forward Alpha HTTPS to localhost (use other terminal tab)
kubectl port-forward $RELEASE-dgraph-alpha-0 8080:8080 &

# Test GRPC using Mutual TLS
dgraph increment \
 --tls_cacert ./tls/ca.crt \
 --tls_cert ./tls/client.dgraphuser.crt \
 --tls_key ./tls/client.dgraphuser.key \
 --tls_server_name "localhost"

# Test HTTPS using Mutual TLS
curl --silent \
  --cacert ./tls/ca.crt \
  --cert ./tls/client.dgraphuser.crt \
  --key ./tls/client.dgraphuser.key \
  https://localhost:8080/state  
```

## Alpha Encryption at Rest (Enterprise Feature)

You can generate a secret for the key file using `base64` tool:

```bash
base64 <<< '123456789012345'
# MTIzNDU2Nzg5MDEyMzQ1Cg==
```

Then create a Helm chart value config file with the secret:

```yaml
# alpha-enc-secret.yaml
alpha:
  encryption:
    file:
      enc_key_file: MTIzNDU2Nzg5MDEyMzQ1Cg==
```

Create a corresponding configuration enables and configures Dgraph Alpha to use this file:

```yaml
# alpha-enc-config.yaml
alpha:
  encryption:
    enabled: true
  configFile:
    config.toml: |
      encryption_key_file = '/dgraph/enc/enc_key_file'
      lru_mb = 2048
```

Then deploy Dgraph using the secret and config files:

```bash
RELNAME=my-release
helm install $RELNAME \
 --values alpha-enc-secret.yaml
 --values alpha-enc-config.yaml
 dgraph/dgraph
```

## Alpha Access Control Lists (Enterprise Feature)

You can generate a secret for the secrets file using `base64` tool:

```bash
base64 <<< '1234567890123456789012345678901'
# MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMQo=
```

Then create a Helm chart value config file with the secret:

```yaml
# alpha-acl-secret.yaml
alpha:
  acl:
    file:
      hmac_secret_file: MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMQo=
```

Create a corresponding configuration enables and configures Dgraph Alpha to use this file:

```yaml
# alpha-acl-config.yaml
alpha:
  acl:
    enabled: true
  configFile:
    config.toml: |
      acl_secret_file = '/dgraph/acl/hmac_secret_file'
      lru_mb = 2048
```

Then deploy Dgraph using the secret and config files:

```bash
RELNAME=my-release
helm install $RELNAME \
 --values alpha-acl-secret.yaml
 --values alpha-acl-config.yaml
 dgraph/dgraph
```

## Binary Backups (Enterprise feature)

Dgraph [Binary Backups](https://dgraph.io/docs/master/enterprise-features/binary-backups/) are supported by Kubernetes CronJobs. There are two types of Kubernetes CronJobs supported:

* Full backup at midnight: `0 * * * *`
* Incremental backups every hour, except midnight: `0 1-23 * * *`

Binary Backups supports three types of _destinations_:

* File path (Network File System recommended)
* [Amazon Simple Storage Service](https://aws.amazon.com/s3/) (S3)
* [MinIO](https://min.io/) Object Storage

### Using Amazon S3

You can use [Amazon S3](https://aws.amazon.com/s3/) with backup cronjobs.  You will want to configure the following:

* Alpha
  * `alpha.extraEnvs` - configure keys `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
* Backups
  * `backups.destination` - should be in this format `s3://s3.<region>.amazonaws.com/<bucket>`

### Using Minio

For this option, you will need to deploy a MinIO Server or a MinIO Gateway such as [MinIO GCS Gateway](https://docs.min.io/docs/minio-gateway-for-gcs.html) or [MinIO Azure Gateway](https://docs.min.io/docs/minio-gateway-for-azure.html).  The [MinIO Helm Chart](https://helm.min.io/) can be useful for this process.

For Minio configuration, you will want to configure the following:

* Alpha
  * `alpha.extraEnvs` - configure keys `MINIO_ACCESS_KEY` and `MINIO_SECRET_KEY`
* Backups
  * `backups.destination` - should be in this format `minio://<server-address>:9000/<bucket>`.
  * `minioSecure` (default: `false`) - configure this to `true` if you installed TLS certs/keys for MinIO server.

### Using NFS

Backup cronjobs can take advantage of NFS if you have an NFS server available, such as [EFS](https://aws.amazon.com/efs/) or [GCFS](https://cloud.google.com/filestore).  For external NFS servers outside of the Kubernetes cluster, the NFS server will need to be accessible from Kubernetes Worker Nodes.  

When this feature is enabled, a shared NFS volume will be mounted on each of the Alpha pods to `/dgraph/backups` by default. The NFS volume will also be mounted on backup cronjob pods so that the backup script can create datestamp named directories to organize full and incremental backups.

* Backups
  * `backups.destination` (default: `/dgraph/backups`) - file-path where Dgraph Alpha will save backups
  * `backups.nfs.server` - NFS server IP address or DNS name.  If external to the Kubernetes, the NFS server should be accessible from Kubernetes worker nodes.
  * `backups.nfs.path` - NFS server path, e.g. [EFS](https://aws.amazon.com/efs/) uses `/`, while with [GCFS](https://cloud.google.com/filestore), the user specifies this during creation.
  * `backups.nfs.storage` (default: `512Gi`) - storage allocated from NFS server
  * `backups.nfs.mountPath` (default: `/dgraph/backups`) - this is mounted on Alpha pods, should be same as `backups.destination`

### Using Mutual TLS

If Dgraph Alpha TLS options are used, backup cronjobs will submit the requests using HTTPS.  If Mutual TLS client certificates are configured as well, you need to specify the name of the client certificate and key so that the backup cronjob script can find them.

* Alpha
  * see [Alpha TLS Options](#alpha-tls-options) above.
* Backups
  * `backups.admin.tls_client` - this should match the client cert and key that was created with `dgraph cert --client`, e.g. `backupuser`

### Using the Access Control List

When ACLs are used, the backup cronjob will log in to the Alpha node using a specified user account.  Through this process, the backup cronjob script will receive an AccessJWT token that will be submitted when requesting a backup.

* Alpha
  * see [Alpha Access Control Lists](#alpha-access-control-lists-enterprise-feature) above.
* Backups
  * `backups.admin.user` (default: `groot`) - a user that is a member of `guardians` group will need to be specified.
  * `backups.admin.password` (default: `password`) - the corresponding password for that user will need to be specified.

### Using Auth Token

When a simple Auth Token is used, the backup cronjob script will submit an auth token when requesting a backup.

* Alpha
  * Alpha will need to be configured with environment variable `DGRAPH_ALPHA_AUTH_TOKEN` or configuration with `auth_token` set.
* Backups
  * `backups.admin.auth_token` - this will need to have the same value configured in Alpha

### Using a Different Backup Image

The default backup image uses the same Dgraph image specified under `image`.  This can be changed to an alternative image of your choosing under `backup.image`.
The backup image will need `bash`, `grep`, and `curl` installed.

### Troubleshooting Kubernetes CronJobs

The Kubernetes CronJob will create jobs based on the schedule. To see the results of these scheduled jobs, you would do the following:

1. Run `kubectl get jobs` to list the jobs
2. Using a name from one of the jobs, run `kubectl get pods --selector job-name=<job-name>`

As an example, you could get the logs of the jobs with the following:

```bash
JOBS=( $(kubectl get jobs --no-headers --output custom-columns=":metadata.name") )
for JOB in "${JOBS[@]}"; do
   POD=$(kubectl get pods --selector job-name=$JOB --no-headers --output custom-columns=":metadata.name")
   kubectl logs $POD
done
```

## Monitoring

Dgraph exposes Prometheus metrics to monitor the state of various components involved in
the cluster, this includes Dgraph Alpha and Dgraph Zero.

Further information can be found in the [Monitoring in Kubernetes](https://dgraph.io/docs/deploy/kubernetes/#monitoring-in-kubernetes) documentation.
