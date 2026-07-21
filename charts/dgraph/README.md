# Dgraph

Dgraph is a horizontally scalable and distributed graph database, providing ACID transactions,
consistent replication and linearizable reads. It's built from the ground up to perform for a rich set
of queries. Being a native graph database, it tightly controls how the data is arranged on disk to
optimize for query performance and throughput, reducing disk seeks and network calls in a cluster.

### TL;DR;

```sh
helm repo add dgraph https://charts.dgraph.io
helm install "my-release" dgraph/dgraph
```

### Introduction

This chart bootstraps [Dgraph](https://dgraph.io) cluster deployment on a
Kubernetes cluster using [Helm](https://helm.sh) package manager.

### Prerequisites

- Kubernetes 1.16+
- Helm 3.0+

### Upgrading

#### v24.x to v25.x (Breaking Changes)

Chart v25 removes the version-specific `chart` label (e.g. `chart: dgraph-24.1.4`) from StatefulSet, Deployment, and Service selectors. This is a one-time breaking change because Kubernetes does not allow modifying `selector.matchLabels` on existing StatefulSets and Deployments.

Note that keeping the `chart` label in selectors was already problematic — because it includes the chart version, **every chart upgrade would change the selector value and break**, not just the v24 to v25 transition. Removing it ensures that future chart upgrades will work seamlessly without requiring resource recreation.

**Automated migration**: The chart includes a `pre-upgrade` hook that automatically handles this. The hook:

1. Detects StatefulSets and Deployments that still have the old `chart` selector label
2. Deletes them with `--cascade=orphan`, which keeps existing pods running
3. Helm then recreates the resources with the updated selectors and rolls the pods

No manual intervention is required. Also review the [additional breaking changes](#additional-v25-breaking-changes) below.

#### Additional v25 breaking changes

**Full backup restartPolicy fix**: The full backup CronJob previously read its `restartPolicy` from `backups.incremental.restartPolicy` instead of `backups.full.restartPolicy`. This has been fixed. If you were working around this bug by setting `backups.incremental.restartPolicy` to control the full backup's restart policy, you will need to move that value to `backups.full.restartPolicy`.

**Backup admin password now required**: When `alpha.acl.enabled` is true and backups are enabled, `backups.admin.password` must be explicitly set. Previously the chart would silently render an empty secret, which would cause backup failures at runtime. The chart now fails at install/upgrade time with a clear error message if the password is missing.

**ACL and encryption flags now auto-activate**: Setting `alpha.acl.enabled: true` (or `alpha.encryption.enabled: true`) now synthesizes the matching `--acl` (or `--encryption`) superflag onto the Alpha command automatically; previously these flags had to be added by hand through `alpha.extraFlags`. If you already pass `--acl` or `--encryption` through `alpha.extraFlags`, remove it — the chart fails rendering rather than pass the flag twice. The chart points the flag at `/dgraph/acl/<alpha.acl.secretFile>` and `/dgraph/enc/<alpha.encryption.keyFile>`, which default to `hmac_secret_file` and `enc_key_file`; override those keys if your Secret stores the file under a different name.

**TLS now activates from the tls block**: Setting `alpha.tls.enabled: true` (or `zero.tls.enabled: true`) now synthesizes the `--tls` superflag onto the Alpha (or Zero) command; previously the flag had to be added by hand through `extraFlags`. If you already pass `--tls` through `alpha.extraFlags` or `zero.extraFlags`, remove it — the chart fails rendering rather than pass the flag twice. Configure TLS through the new `tls.internalPort`, `tls.clientName`, and `tls.clientAuthType` keys; the chart reads the cert files from `/dgraph/tls` (`ca.crt`, `node.crt`, `node.key`, and `client.<clientName>.crt`/`.key`).

**Health probes use HTTPS when TLS is enabled**: With `alpha.tls.enabled: true` (or `zero.tls.enabled: true`), the built-in httpGet startup, liveness, and readiness probes switch to `scheme: HTTPS`. A cert-requiring `clientAuthType` (`REQUIREANY` or `REQUIREANDVERIFY`) makes every client present a certificate, which the kubelet's probes cannot; the chart fails rendering in that case. Set `clientAuthType: VERIFYIFGIVEN`, or supply exec probes through `customStartupProbe`/`customLivenessProbe`/`customReadinessProbe`. A cert-requiring `clientAuthType` also requires `clientName` so in-cluster callers (inter-node TLS) can present a client cert.

### Installing the Chart

To install the chart with the release name `my-release`:

```bash
helm repo add dgraph https://charts.dgraph.io
helm install "my-release" dgraph/dgraph
```

These commands deploy Dgraph on the Kubernetes cluster in the default configuration.
The [Configuration](#configuration) section lists the parameters that can be configured during installation:

> **Tip**: List all releases using `helm list`

### Uninstalling the chart

To uninstall/delete the `my-release` resources:

```bash
helm delete "my-release"
```

The command above removes all the Kubernetes components associated
with the chart and deletes the release.

Deletion of the StatefulSet doesn't cascade to deleting associated PVCs. To delete them:

```bash
kubectl delete pvc --selector release=my-release
```

## Configuration

The following table lists the configurable parameters of the `dgraph` chart and their default values.

|              Parameter                   |                             Description                               |                       Default                       |
| ---------------------------------------- | --------------------------------------------------------------------- | --------------------------------------------------- |
| `commonLabels`                           | Labels to add to all resources and pod templates                      | `{}`                                                |
| `imagePullSecrets`                       | Array of imagePullSecrets applied to every Pod (plain strings or `{name: ...}` objects); takes precedence over `global.imagePullSecrets` and `image.pullSecrets` | `[]` |
| `image.registry`                         | Container registry name                                               | `docker.io`                                         |
| `image.repository`                       | Container image name                                                  | `dgraph/dgraph`                                     |
| `image.tag`                              | Container image tag                                                   | `v25.3.8`                                           |
| `image.pullPolicy`                       | Container pull policy                                                 | `IfNotPresent`                                      |
| `nameOverride`                           | Deployment name override (will append the release name)               | `nil`                                               |
| `namespaceOverride`                      | Deployment namespace override if specified.                           | `nil`                                               |
| `fullnameOverride`                       | Deployment full name override (the release name is ignored)           | `nil`                                               |
| `preUpgradeHook.enabled`                 | Run the v24-to-v25 StatefulSet selector migration Job on `helm upgrade` | `true`                                              |
| `preUpgradeHook.image.registry`          | Pre-upgrade hook image registry                                       | `docker.io`                                         |
| `preUpgradeHook.image.repository`        | Pre-upgrade hook image repository                                     | `bitnami/kubectl`                                   |
| `preUpgradeHook.image.tag`               | Pre-upgrade hook image tag                                            | `1.31`                                              |
| `preUpgradeHook.podLabels`               | Labels for pre-upgrade hook Job pods                                  | `{}`                                                |
| `preUpgradeHook.podAnnotations`          | Annotations for pre-upgrade hook Job pods                             | `{}`                                                |
| `serviceAccount.create`                  | Create ServiceAccount                                                 | `true`                                              |
| `serviceAccount.annotations`             | ServiceAccount annotations                                            | `{}`                                                |
| `serviceAccount.name`                    | ServiceAccount name                                                   | `dgraph`                                            |
| `serviceAccount.automountServiceAccountToken` | automatically mount a ServiceAccount API credentials              | `true`                                              |
| `zero.name`                              | Zero component name                                                   | `zero`                                              |
| `zero.metrics.enabled`                   | Add annotations for Prometheus metric scraping                        | `true`                                              |
| `zero.extraAnnotations`                  | Specify annotations for template metadata                             | `{}`                                                |
| `zero.podLabels`                         | Specify additional labels for template metadata                       | `{}`                                                |
| `zero.updateStrategy`                    | Strategy for upgrading zero nodes                                     | `RollingUpdate`                                     |
| `zero.schedulerName`                     | Configure an explicit scheduler                                       | `nil`                                               |
| `zero.monitorLabel`                      | "monitor" label on the zero Service (for Prometheus service discovery) | `zero-dgraph-io`                                    |
| `zero.pdb.enabled`                       | Enable a PodDisruptionBudget for the zero StatefulSet                 | `false`                                             |
| `zero.pdb.minAvailable`                  | Minimum available zero pods during voluntary disruptions              | `2`                                                 |
| `zero.pdb.maxUnavailable`                | Maximum unavailable zero pods (alternative to `minAvailable`)         | `nil`                                               |
| `zero.rollingUpdatePartition`            | Partition update strategy                                             | `nil`                                               |
| `zero.podManagementPolicy`               | Pod management policy for zero nodes                                  | `OrderedReady`                                      |
| `zero.replicaCount`                      | Number of zero nodes                                                  | `3`                                                 |
| `zero.shardReplicaCount`                 | Max number of replicas per data shard                                 | `5`                                                 |
| `zero.terminationGracePeriodSeconds`     | Zero server pod termination grace period                              | `60`                                                |
| `zero.antiAffinity`                      | Zero anti-affinity policy                                             | `soft`                                              |
| `zero.podAntiAffinitytopologyKey`        | Anti affinity topology key for zero nodes                             | `kubernetes.io/hostname`                            |
| `zero.nodeAffinity`                      | Zero node affinity policy                                             | `{}`                                                |
| `zero.envFrom`                           | Extra environment variables loaded from configmap(s) and/or secret(s) | `[]`                                                |
| `zero.extraEnvs`                         | extra env vars                                                        | `[]`                                                |
| `zero.extraFlags`                        | Zero extra flags for command line                                     | `""`                                                |
| `zero.logLevel`                          | Verbosity (glog `-v`): `normal`/`verbose`/`debug`/`trace`, or a raw integer | `normal`                                        |
| `zero.vmodule`                           | Per-module glog verbosity (`--vmodule`), e.g. `server=3,raft=2`        | `""`                                                |
| `zero.logtostderr`                       | Log to the container's stderr (glog `--logtostderr`)                  | `true`                                              |
| `zero.alsologtostderr`                   | Also write logs under `logDir` in addition to stderr                  | `false`                                             |
| `zero.logDir`                            | Directory for glog file output (`--log_dir`); used when `logtostderr=false` or `alsologtostderr=true` | `""`                        |
| `zero.configFile`                        | Zero config file                                                      | `{}`                                                |
| `zero.automountServiceAccountToken`      | automatically mount a ServiceAccount API credentials                   | `true`                                              |
| `zero.service.type`                      | Zero service type                                                     | `ClusterIP`                                         |
| `zero.service.labels`                    | Zero service labels                                                   | `{}`                                                |
| `zero.service.annotations`               | Zero service annotations                                              | `{}`                                                |
| `zero.service.publishNotReadyAddresses`  | publish address if pods not in ready state                            | `true`                                              |
| `zero.service.loadBalancerIP`            | specify static IP address for LoadBalancer type                       | `""`                                                |
| `zero.service.externalTrafficPolicy`     | route external traffic to node-local or cluster-wide endpoints        | `""`                                                |
| `zero.service.loadBalancerSourceRanges`  | restrict CIDR IP addresses for a LoadBalancer type                    | `[]`                                                |
| `zero.serviceHeadless.labels`            | Zero headless service labels                                          | `{}`                                                |
| `zero.securityContext.enabled`           | Security context for zero nodes enabled                               | `false`                                             |
| `zero.securityContext.fsGroup`           | Group id of the zero container                                        | `1001`                                              |
| `zero.securityContext.runAsUser`         | User ID for the zero container                                        | `1001`                                              |
| `zero.containerSecurityContext.enabled`  | Enable the zero container securityContext (drop ALL capabilities, forbid privilege escalation) | `false`                    |
| `zero.containerSecurityContext.allowPrivilegeEscalation` | Allow privilege escalation for the zero container     | `false`                                             |
| `zero.containerSecurityContext.readOnlyRootFilesystem` | Mount the zero container's root filesystem read-only   | `false`                                             |
| `zero.containerSecurityContext.capabilities.drop` | Linux capabilities dropped from the zero container           | `['ALL']`                                           |
| `zero.persistence.enabled`               | Enable persistence for zero using PVC                                 | `true`                                              |
| `zero.persistence.storageClass`          | PVC Storage Class for zero volume                                     | `nil`                                               |
| `zero.persistence.accessModes`           | PVC Access Mode for zero volume                                       | `['ReadWriteOnce']`                                 |
| `zero.persistence.size`                  | PVC Storage Request for zero volume                                   | `32Gi`                                              |
| `zero.persistence.persistentVolumeClaimRetentionPolicy` | PVC retention policy for the zero StatefulSet (`whenDeleted`/`whenScaled`, each `Retain` or `Delete`); requires Kubernetes >= 1.27. Unset keeps the Kubernetes default. | _unset_ |
| `zero.nodeSelector`                      | Node labels for zero pod assignment                                   | `{}`                                                |
| `zero.tolerations`                       | Zero tolerations                                                      | `[]`                                                |
| `zero.resources.requests.memory`         | Zero pod resources memory requests                                    | `100Mi`                                             |
| `zero.startupProbe`                      | Zero startup probes (**NOTE**: only supported in Kubernetes v1.16+)   | See `values.yaml` for defaults                      |
| `zero.livenessProbe`                     | Zero liveness probes                                                  | See `values.yaml` for defaults                      |
| `zero.readinessProbe`                    | Zero readiness probes                                                 | See `values.yaml` for defaults                      |
| `zero.customStartupProbe`                | Zero custom startup probes (if `zero.startupProbe` not enabled)       | `{}`                                                |
| `zero.customLivenessProbe`               | Zero custom liveness probes (if `zero.livenessProbe` not enabled)     | `{}`                                                |
| `zero.customReadinessProbe`              | Zero custom readiness probes  (if `zero.readinessProbe` not enabled)  | `{}`                                                |
| `zero.tls.internalPort`                  | Enable TLS on Zero's internal gRPC port (synthesized into `--tls`)    | `true`                                              |
| `zero.tls.clientName`                    | Client cert basename for Zero `--tls` (empty omits the client cert)   | `""`                                                |
| `zero.tls.clientAuthType`                | Zero `--tls` client-auth-type, e.g. `REQUIREANDVERIFY` (empty omits)  | `""`                                                |
| `alpha.name`                             | Alpha component name                                                  | `alpha`                                             |
| `alpha.metrics.enabled`                  | Add annotations for Prometheus metric scraping                        | `true`                                              |
| `alpha.extraAnnotations`                 | Specify annotations for template metadata                             | `{}`                                                |
| `alpha.podLabels`                        | Specify additional labels for template metadata                       | `{}`                                                |
| `alpha.monitorLabel`                     | "monitor" label on the alpha Service (for Prometheus service discovery) | `alpha-dgraph-io`                                   |
| `alpha.pdb.enabled`                      | Enable a PodDisruptionBudget for the alpha StatefulSet                | `false`                                             |
| `alpha.pdb.minAvailable`                 | Minimum available alpha pods during voluntary disruptions             | `2`                                                 |
| `alpha.pdb.maxUnavailable`               | Maximum unavailable alpha pods (alternative to `minAvailable`)        | `nil`                                               |
| `alpha.updateStrategy`                   | Strategy for upgrading alpha nodes                                    | `RollingUpdate`                                     |
| `alpha.schedulerName`                    | Configure an explicit scheduler                                       | `nil`                                               |
| `alpha.rollingUpdatePartition`           | Partition update strategy                                             | `nil`                                               |
| `alpha.podManagementPolicy`              | Pod management policy for alpha nodes                                 | `OrderedReady`                                      |
| `alpha.replicaCount`                     | Number of alpha nodes                                                 | `3`                                                 |
| `alpha.terminationGracePeriodSeconds`    | Alpha server pod termination grace period                             | `600`                                               |
| `alpha.antiAffinity`                     | Alpha anti-affinity policy                                            | `soft`                                              |
| `alpha.podAntiAffinitytopologyKey`       | Anti affinity topology key for zero nodes                             | `kubernetes.io/hostname`                            |
| `alpha.nodeAffinity`                     | Alpha node affinity policy                                            | `{}`                                                |
| `alpha.envFrom`                          | Extra environment variables loaded from configmap(s) and/or secret(s) | `[]`                                                |
| `alpha.extraEnvs`                        | extra env vars                                                        | `[]`                                                |
| `alpha.extraFlags`                       | Alpha extra flags for command                                         | `""`                                                |
| `alpha.logLevel`                         | Verbosity (glog `-v`): `normal`/`verbose`/`debug`/`trace`, or a raw integer | `normal`                                       |
| `alpha.vmodule`                          | Per-module glog verbosity (`--vmodule`), e.g. `server=3,raft=2`       | `""`                                                |
| `alpha.logtostderr`                      | Log to the container's stderr (glog `--logtostderr`)                 | `true`                                              |
| `alpha.alsologtostderr`                  | Also write logs under `logDir` in addition to stderr                 | `false`                                             |
| `alpha.logDir`                           | Directory for glog file output (`--log_dir`); used when `logtostderr=false` or `alsologtostderr=true` | `""`                       |
| `alpha.configFile`                       | Alpha config file                                                     | `{}`                                                |
| `alpha.automountServiceAccountToken`     | automatically mount a ServiceAccount API credentials                   | `true`                                              |
| `alpha.service.type`                     | Alpha node service type                                               | `ClusterIP`                                         |
| `alpha.service.labels`                   | Alpha service labels                                                  | `{}`                                                |
| `alpha.service.annotations`              | Alpha service annotations                                             | `{}`                                                |
| `alpha.service.publishNotReadyAddresses` | publish address if pods not in ready state                            | `true`                                              |
| `alpha.service.loadBalancerIP`           | specify static IP address for LoadBalancer type                       | `""`                                                |
| `alpha.service.externalTrafficPolicy`    | route external traffic to node-local or cluster-wide endpoints        | `""`                                                |
| `alpha.service.loadBalancerSourceRanges` | restrict CIDR IP addresses for a LoadBalancer type                    | `[]`                                                |
| `alpha.serviceHeadless.labels`           | Alpha headless service labels                                         | `{}`                                                |
| `alpha.ingress.enabled`                  | Alpha ingress resource enabled                                        | `false`                                             |
| `alpha.ingress.hostname`                 | Alpha ingress virtual hostname                                        | `nil`                                               |
| `alpha.ingress.annotations`              | Alpha ingress annotations                                             | `nil`                                               |
| `alpha.ingress.tls`                      | Alpha ingress TLS settings                                            | `nil`                                               |
| `alpha.ingress_grpc.enabled`             | Alpha ingress-grpc resource enabled                                   | `false`                                             |
| `alpha.ingress_grpc.hostname`            | Alpha ingress-grpc virtual hostname                                   | `nil`                                               |
| `alpha.ingress_grpc.ingressClassName`    | Alpha ingress-grpc ingress class to select ingress controller         | `nil`                                               |
| `alpha.ingress_grpc.annotations`         | Alpha ingress-gcpc annotations                                        | `nil`                                               |
| `alpha.ingress_grpc.tls`                 | Alpha ingress-grpc TLS settings                                       | `nil`                                               |
| `alpha.securityContext.enabled`          | Security context for Alpha nodes enabled                              | `false`                                             |
| `alpha.securityContext.fsGroup`          | Group id of the Alpha container                                       | `1001`                                              |
| `alpha.securityContext.runAsUser`        | User ID for the Alpha container                                       | `1001`                                              |
| `alpha.containerSecurityContext.enabled` | Enable the alpha container securityContext (drop ALL capabilities, forbid privilege escalation) | `false`                   |
| `alpha.containerSecurityContext.allowPrivilegeEscalation` | Allow privilege escalation for the alpha container   | `false`                                             |
| `alpha.containerSecurityContext.readOnlyRootFilesystem` | Mount the alpha container's root filesystem read-only | `false`                                             |
| `alpha.containerSecurityContext.capabilities.drop` | Linux capabilities dropped from the alpha container         | `['ALL']`                                           |
| `alpha.tls.enabled`                      | Alpha service TLS enabled                                             | `false`                                             |
| `alpha.tls.files`                        | Alpha service TLS key and certificate files stored as secrets         | `false`                                             |
| `alpha.tls.internalPort`                 | Enable TLS on Alpha's internal gRPC port (synthesized into `--tls`)   | `true`                                              |
| `alpha.tls.clientName`                   | Client cert basename for Alpha `--tls` (empty omits the client cert)  | `""`                                                |
| `alpha.tls.clientAuthType`               | Alpha `--tls` client-auth-type, e.g. `REQUIREANDVERIFY` (empty omits) | `""`                                                |
| `alpha.encryption.enabled`               | Alpha Encryption at Rest enabled (auto-adds `--encryption`)           | `false`                                             |
| `alpha.encryption.keyFile`               | Filename/key of the encryption key within the mounted Secret          | `enc_key_file`                                      |
| `alpha.encryption.existingSecret`        | Name of a pre-created Secret holding the encryption key (suppresses the chart's own) | `""`                                |
| `alpha.encryption.file`                  | Alpha Encryption at Rest key file                                     | `nil`                                               |
| `alpha.acl.enabled`                      | Alpha ACL enabled (auto-adds `--acl`)                                 | `false`                                             |
| `alpha.acl.secretFile`                   | Filename/key of the HMAC secret within the mounted Secret             | `hmac_secret_file`                                  |
| `alpha.acl.existingSecret`               | Name of a pre-created Secret holding the HMAC key (suppresses the chart's own) | `""`                                      |
| `alpha.acl.file`                         | Alpha ACL secret file                                                 | `nil`                                               |
| `alpha.acl.bootstrap.enabled`            | Enable the post-install/post-upgrade ACL bootstrap reconciler Job     | `false`                                             |
| `alpha.acl.bootstrap.existingSecret`     | Secret holding the credentials the bootstrap Job reads (defaults to `acl.existingSecret`, else the chart-managed ACL Secret) | `""`                |
| `alpha.acl.bootstrap.grootPasswordSecretKey` | Key in the credentials Secret holding groot's rotated password   | `groot_password`                                    |
| `alpha.acl.bootstrap.rotation`           | Opaque token rendered as a Job pod annotation; change it to force a re-run without touching Alpha | `""`                        |
| `alpha.acl.bootstrap.image`              | Image override for the bootstrap Job (empty reuses the deployed dgraph image) | `{}`                                         |
| `alpha.acl.bootstrap.groups`             | Declarative ACL groups (`name`, `rules: [{predicate, permission}]`) the reconciler converges | `[]`                                 |
| `alpha.acl.bootstrap.users`              | Declarative ACL users (`name`, `passwordSecretKey`, `groups`) the reconciler converges | `[]`                                        |
| `alpha.persistence.enabled`              | Enable persistence for alpha using PVC                                | `true`                                              |
| `alpha.persistence.storageClass`         | PVC Storage Class for alpha volume                                    | `nil`                                               |
| `alpha.persistence.accessModes`          | PVC Access Mode for alpha volume                                      | `['ReadWriteOnce']`                                 |
| `alpha.persistence.size`                 | PVC Storage Request for alpha volume                                  | `100Gi`                                             |
| `alpha.persistence.persistentVolumeClaimRetentionPolicy` | PVC retention policy for the alpha StatefulSet (`whenDeleted`/`whenScaled`, each `Retain` or `Delete`); requires Kubernetes >= 1.27. Unset keeps the Kubernetes default. | _unset_ |
| `alpha.nodeSelector`                     | Node labels for alpha pod assignment                                  | `{}`                                                |
| `alpha.tolerations`                      | Alpha tolerations                                                     | `[]`                                                |
| `alpha.resources.requests.memory`        | Zero pod resources memory request                                     | `100Mi`                                             |
| `alpha.startupProbe`                     | Alpha startup probes (**NOTE**: only supported in Kubernetes v1.16+)  | See `values.yaml` for defaults                      |
| `alpha.livenessProbe`                    | Alpha liveness probes                                                 | See `values.yaml` for defaults                      |
| `alpha.readinessProbe`                   | Alpha readiness probes                                                | See `values.yaml` for defaults                      |
| `alpha.customStartupProbe`               | Alpha custom startup probes (if `alpha.startupProbe` not enabled)     | `{}`                                                |
| `alpha.customLivenessProbe`              | Alpha custom liveness probes (if `alpha.livenessProbe` not enabled)   | `{}`                                                |
| `alpha.customReadinessProbe`             | Alpha custom readiness probes (if `alpha.readinessProbe` not enabled) | `{}`                                                |
| `alpha.extraInitContainers`             | Enables extra init containers to be added to the alpha statefulset | `[]`                                                |
| `alpha.initContainers.init.enabled`      | Alpha initContainer enabled                                           | `true`                                              |
| `alpha.initContainers.init.image.registry`   | Alpha initContainer registry name                                 | `docker.io`                                         |
| `alpha.initContainers.init.image.repository` | Alpha initContainer image name                                    | `dgraph/dgraph`                                     |
| `alpha.initContainers.init.image.tag`        | Alpha initContainer image tag                                     | `v21.03.0`                                          |
| `alpha.initContainers.init.image.pullPolicy` | Alpha initContainer pull policy                                   | `IfNotPresent`                                      |
| `alpha.initContainers.init.env` | Adds environment variables for the alpha init container                                  | `[]`                                      |
| `alpha.initContainers.init.envFrom`      | Extra environment variables loaded from configmap(s) and/or secret(s) | `[]`                                                |
| `alpha.initContainers.init.command`      | Alpha initContainer command line to execute                           | See `values.yaml` for defaults                      |
| `alpha.initContainers.init.resources`    | Alpha initContainer resource requests and/or limits                   | `{}`                                                |
| `ratel.name`                             | Ratel component name                                                  | `ratel`                                             |
| `ratel.enabled`                          | Ratel service enabled or disabled                                     | `false`                                             |
| `ratel.extraAnnotations`                 | Specify annotations for template metadata                             | `{}`                                                |
| `ratel.podLabels`                        | Specify additional labels for template metadata                       | `{}`                                                |
| `ratel.image.registry`                   | Container registry name                                               | `docker.io`                                         |
| `ratel.image.repository`                 | Container image name                                                  | `dgraph/ratel`                                      |
| `ratel.image.tag`                        | Container image tag                                                   | `v21.03.1`                                          |
| `ratel.image.pullPolicy`                 | Container pull policy                                                 | `IfNotPresent`                                      |
| `ratel.schedulerName`                    | Configure an explicit scheduler                                       | `nil`                                               |
| `ratel.replicaCount`                     | Number of ratel nodes                                                 | `1`                                                 |
| `ratel.envFrom`                          | Extra environment variables loaded from configmap(s) and/or secret(s) | `[]`                                                |
| `ratel.extraEnvs`                        | Extra env vars                                                        | `[]`                                                |
| `ratel.args`                             | Ratel command line arguments                                          | `[]`                                                |
| `ratel.automountServiceAccountToken`     | automatically mount a ServiceAccount API credentials                   | `true`                                              |
| `ratel.service.type`                     | Ratel service type                                                    | `ClusterIP`                                         |
| `ratel.service.labels`                   | Ratel Service labels                                                  | `{}`                                                |
| `ratel.service.annotations`              | Ratel Service annotations                                             | `{}`                                                |
| `ratel.service.loadBalancerIP`           | specify static IP address for LoadBalancer type                       | `""`                                                |
| `ratel.service.externalTrafficPolicy`    | route external traffic to node-local or cluster-wide endpoints        | `""`                                                |
| `ratel.service.loadBalancerSourceRanges` | restrict CIDR IP addresses for a LoadBalancer type                    | `[]`                                                |
| `ratel.ingress.enabled`                  | Ratel Ingress resource enabled                                        | `false`                                             |
| `ratel.ingress.hostname`                 | Ratel Ingress virtual hostname                                        | `nil`                                               |
| `ratel.ingress.ingressClassName`         | Ratel ingress class to select ingress controller                      | `nil`                                               |
| `ratel.ingress.annotations`              | Ratel Ingress annotations                                             | `nil`                                               |
| `ratel.ingress.tls`                      | Ratel Ingress TLS settings                                            | `nil`                                               |
| `ratel.securityContext.enabled`          | Security context for ratel nodes enabled                              | `false`                                             |
| `ratel.securityContext.fsGroup`          | Group id of the ratel container                                       | `1001`                                              |
| `ratel.securityContext.runAsUser`        | User ID for the ratel container                                       | `1001`                                              |
| `ratel.containerSecurityContext.enabled` | Enable the ratel container securityContext (drop ALL capabilities, forbid privilege escalation) | `false`                   |
| `ratel.containerSecurityContext.allowPrivilegeEscalation` | Allow privilege escalation for the ratel container   | `false`                                             |
| `ratel.containerSecurityContext.readOnlyRootFilesystem` | Mount the ratel container's root filesystem read-only | `false`                                             |
| `ratel.containerSecurityContext.capabilities.drop` | Linux capabilities dropped from the ratel container         | `['ALL']`                                           |
| `ratel.resources.requests`               | Ratel pod resources requests                                          | `nil`                                               |
| `ratel.livenessProbe`                    | Ratel liveness probes                                                 | See `values.yaml` for defaults                      |
| `ratel.readinessProbe`                   | Ratel readiness probes                                                | See `values.yaml` for defaults                      |
| `ratel.customLivenessProbe`              | Ratel custom liveness probes (if `ratel.livenessProbe` not enabled)   | `{}`                                                |
| `ratel.customReadinessProbe`             | Ratel custom readiness probes (if `ratel.readinessProbe` not enabled) | `{}`                                                |
| `backups.name`                           | Backups component name                                                | `backups`                                           |
| `backups.podLabels`                      | Specify additional labels for template metadata                       | `{}`                                                |
| `backups.podAnnotations`                 | Annotations for backup CronJob pods                                   | `{}`                                                |
| `backups.schedulerName`                  | Configure an explicit scheduler for Backups Kubernetes CronJobs       | `nil`                                               |
| `backups.admin.user`                     | Login user for backups (required if ACL enabled)                      | `groot`                                             |
| `backups.admin.password`                 | Login user password for backups (required if ACL enabled)             | `nil`                                               |
| `backups.admin.existingSecret`           | Pre-created Secret holding the backup admin password (chart mints none of its own when set); ignored unless `alpha.acl.enabled` | `""`     |
| `backups.admin.passwordSecretKey`        | Key within `existingSecret` (or the chart's own backups Secret) holding the backup admin password | `backup_admin_password`             |
| `backups.admin.tls_client`               | TLS Client Name (requried if `REQUIREANY` or `REQUIREANDVERIFY` set)  | `nil`                                               |
| `backups.admin.auth_token`               | Auth Token                                                            | `nil`                                               |
| `backups.image.registry`                 | Container registry name                                               | `docker.io`                                         |
| `backups.image.repository`               | Container image name                                                  | `dgraph/dgraph`                                     |
| `backups.image.tag`                      | Container image tag                                                   | `v21.03.0`                                          |
| `backups.image.pullPolicy`               | Container pull policy                                                 | `IfNotPresent`                                      |
| `backups.nfs.enabled`                    | Enable mounted NFS volume for backups                                 | `false`                                             |
| `backups.nfs.server`                     | NFS Server DNS or IP address                                          | `nil`                                               |
| `backups.nfs.path`                       | NFS Server file share path name                                       | `nil`                                               |
| `backups.nfs.storage`                    | Storage allocated from NFS volume and claim                           | `512Gi`                                             |
| `backups.nfs.mountPath`                  | Path to mount volume in Alpha (should match `backup.destination`)     | `/dgraph/backups`                                   |
| `backups.volume.enabled`                 | Enable mounted volume from a PVC for backups                          | `false`                                             |
| `backups.volume.claim`                   | Name of PVC previously deployed                                       | `""`                                                |
| `backups.volume.mountPath`               | Path to mount volume in Alpha (should match `backup.destination`)     | `/dgraph/backups`                                   |
| `backups.full.enabled`                   | Enable full backups cronjob                                           | `false`                                             |
| `backups.full.debug`                     | Enable `set -x` for cron shell script                                 | `false`                                             |
| `backups.full.schedule`                  | Cronjob schedule                                                      | `"0 * * * *"`                                       |
| `backups.full.restartPolicy`             | Restart policy                                                        | `Never`                                             |
| `backups.incremental.enabled`            | Enable incremental backups cronjob                                    | `false`                                             |
| `backups.incremental.debug`              | Enable `set -x` for cron shell script                                 | `false`                                             |
| `backups.incremental.schedule`           | Cronjob schedule                                                      | `"0 1-23 * * *"`                                    |
| `backups.incremental.restartPolicy`      | Restart policy                                                        | `Never`                                             |
| `backups.destination`                    | Destination - file path, s3://, minio:                                | `/dgraph/backups`                                   |
| `backups.subpath`                        | Specify subpath where full + related incremental backups are stored   | `dgraph_$(date +%Y%m%d)`                            |
| `backups.minioSecure`                    | Set to true if Minio server specified in minio:// supports TLS        | `false`                                             |
| `backups.keys.minio.access`              | Alpha env variable `MINIO_ACCESS_KEY` fetched from secrets            | ""                                                  |
| `backups.keys.minio.secret`              | Alpha env variable `MINIO_SECRET_KEY` fetched from secrets            | ""                                                  |
| `backups.keys.s3.access`                 | Alpha env variable `AWS_ACCESS_KEY_ID` fetched from secrets           | ""                                                  |
| `backups.keys.s3.secret`                 | Alpha env variable `AWS_SECRET_ACCESS_KEY` fetched from secrets       | ""                                                  |
| `serviceMonitor.enabled`                 | Create a Prometheus Operator ServiceMonitor for the alpha and zero metrics endpoints (requires the Prometheus Operator CRDs) | `false`       |
| `serviceMonitor.namespace`                | Namespace for the ServiceMonitor (defaults to the release namespace) | `nil`                                               |
| `serviceMonitor.labels`                   | Extra labels for the ServiceMonitor (for Prometheus Operator `serviceMonitorSelector`) | `{}`                                     |
| `serviceMonitor.interval`                 | Scrape interval                                                       | `30s`                                               |
| `serviceMonitor.scrapeTimeout`            | Scrape timeout                                                        | `10s`                                               |
| `serviceMonitor.path`                     | Metrics endpoint path                                                 | `/debug/prometheus_metrics`                         |
| `prometheusRule.enabled`                  | Create a Prometheus Operator PrometheusRule with default alerts (requires the Prometheus Operator CRDs) | `false`                    |
| `prometheusRule.labels`                   | Extra labels for the PrometheusRule (for Prometheus Operator `ruleSelector`) | `{}`                                             |
| `prometheusRule.defaultRules`             | Include the chart's conservative default alerting rules              | `true`                                              |
| `prometheusRule.extraRules`               | Additional Prometheus alerting rules appended to the PrometheusRule   | `[]`                                                |
| `networkPolicy.enabled`                   | Create a NetworkPolicy restricting ingress to the dgraph pods         | `false`                                              |
| `networkPolicy.clientPodLabels`           | Pod selector labels allowed as NetworkPolicy ingress clients          | `{}`                                                |
| `networkPolicy.extraIngress`              | Additional NetworkPolicy ingress rules                                | `[]`                                                |
| `validation.enabled`                      | Master switch for the post-install validation subsystem (ConfigMap, test Pod, Job, CronJob, RBAC) | `false`                        |
| `validation.image`                        | Validator image override (empty reuses the deployed dgraph image)    | `{}`                                                |
| `validation.adminUser`                    | Account the validator logs in as for auth-dependent checks            | `groot`                                             |
| `validation.adminPasswordSecretKey`       | Secret key holding `adminUser`'s password (empty derives it)         | `""`                                                |
| `validation.job.enabled`                  | Run validation as a post-install/upgrade hook Job that gates the release | `false`                                          |
| `validation.job.backoffLimit`             | Job `backoffLimit` (also used by the manual CronJob's jobTemplate)   | `1`                                                 |
| `validation.cronjob.enabled`              | Create a suspended, manually-triggered CronJob for on-demand validation | `false`                                           |
| `validation.rbac.enabled`                 | Create the validator ServiceAccount/Role/RoleBinding (required by `checkBackups`) | `false`                                 |
| `validation.checkBackups`                 | Also assert the backup CronJobs exist with their expected schedules (requires `rbac.enabled`) | `false`                     |
| `validation.backupRoundtrip`              | Trigger a live backup round-trip to S3 (side-effecting, slow; reserved for future use) | `false`                                 |
| `validation.retries`                      | Per-check retry attempts before failing                               | `10`                                                |
| `validation.retrySleep`                   | Seconds between retries                                                | `12`                                                |
| `validation.podAnnotations`               | Extra annotations for validator pods                                  | `{}`                                                |
| `validation.nodeSelector`                 | nodeSelector for validator pods (empty falls back to `alpha.nodeSelector`) | `{}`                                           |
| `validation.tolerations`                  | tolerations for validator pods (empty falls back to `alpha.tolerations`) | `[]`                                             |
| `global.ingress.enabled`                 | Enable global ingress resource (overrides Alpha/Ratel ingress)        | `false`                                             |
| `global.ingress.annotations`             | global ingress annotations                                            | `{}`                                                |
| `global.ingress.tls`                     | global ingress tls settings                                           | `{}`                                                |
| `global.ingress.ratel_hostname`          | global ingress virtual host name for Ratel service                    | `nil`                                               |
| `global.ingress.alpha_hostname`          | global ingress virtual host name for Alpha service                    | `nil`                                               |
| `global.ingress.ingressClassName`        | global ingress class to select ingress controller                     | `nil`                                               |
| `global.ingress_grpc.enabled`            | Enable global ingress-grpc resource (overrides Alpha ingress-grpc)    | `false`                                             |
| `global.ingress_grpc.annotations`        | global ingress-grpc annotations                                       | `{}`                                                |
| `global.ingress_grpc.tls`                | global ingress-grpc tls settings                                      | `{}`                                                |
| `global.ingress_grpc.alpha_grpc_hostname`| global ingress-grpc virtual host name for Alpha GRPC service          | `nil`                                               |
| `global.ingress_grpc.ingressClassName`   | global ingress-grpc ingress class to select ingress controller        | `nil`                                               |

## Ingress resource

You can define ingress resources through `alpha.ingress` for the Alpha HTTP(S) service and `ratel.ingress` for the ratel UI service, or you can use a combined single ingress with `global.ingress` for both Alpha HTTP(S) and ratel UI services.

There are some example chart values for ingress resource configuration in [example_values/ingress](https://github.com/dgraph-io/charts/tree/master/charts/dgraph/example_values/ingress).
### Ingress resource with GRPC

The Dgraph Alpha GRPC can be exposed through an ingress configured with either `alpha.ingress_grpc` or `global.ingress_grpc` values.  For this solution to work, a few requirements must be met:

* if an external load balancer is used by the ingress controller, the load balancer should be Layer 4 TCP as the ingress-controller will handle both HTTPS and GRPC traffic.
* The ingress resource must instruct the ingress controller to use GRPC, such as `nginx.ingress.kubernetes.io/backend-protocol: GRPC` with [ingress-nginx](https://kubernetes.github.io/ingress-nginx/).
* The ingress controller can support both HTTPS and GRPC traffic, but must do TLS termination, so a secret with the appropriate certificates must be configured; this can be automated with the [cert-manager](https://cert-manager.io/) addon.
* As the Dgraph Alpha service will be accessed through a FQDN name, it is recommended that DNS record updates are automated; this can be automated with the [external-dns](https://github.com/kubernetes-sigs/external-dns/) addon.

There is an example chart values for ingress resource configuration in [example_values/ingress](https://github.com/dgraph-io/charts/tree/master/charts/dgraph/example_values/ingress).
## Zero and Alpha configuration

Should you need additional configuration options you can add these either through environment variables or a configuration file, e.g. `config.yaml`. Instructions about this configuration can be found in `values.yaml`.

There are some example values files demonstrating how to add configuration with JSON and YAML file formats in [example_values](https://github.com/dgraph-io/charts/tree/master/charts/dgraph/example_values).
## Alpha TLS options

The Dgraph Alpha service can be configured to use Mutual TLS.  Instructions about this configuration can be found in `values.yaml`.  

There are some example chart values for Alpha TLS configuration in [example_values](https://github.com/dgraph-io/charts/tree/master/charts/dgraph/example_values).

### Alpha TLS example

As an example to test this feature, you can run the following steps below.


#### Step 1: Create certificates, keys, and Helm Chart secrets config

When generating the certificates and keys with `dgraph cert` command, you can use [make_tls_secrets.sh](https://github.com/dgraph-io/charts/blob/master/charts/dgraph/scripts/make_tls_secrets.sh) to generate a list of Alpha pod internal DNS names, the certificates and keys, and a Helm chart configuration `secrets.yaml`. This way other services running on the cluster, such as a backup cronjob, can access the Alpha pod.

```bash
VERS=0.0.13

## Download Script
curl --silent --remote-name --location \
  https://raw.githubusercontent.com/dgraph-io/charts/dgraph-$VERS/charts/dgraph/scripts/make_tls_secrets.sh
bash make_tls_secrets.sh \
  --release "my-release" \
  --namespace "default" \
  --replicas 3 \
  --client "dgraphuser" \
  --tls_dir ~/dgraph_tls
```

#### Step 2: Deploy

The certificates created support and Alpha internal headless Service DNS hostnames. We can deploy a Dgraph cluster using these certs.


```bash
export RELEASE="my-release"

# Download Example Dgraph Alpha config
curl --silent --remote-name --location \
 https://raw.githubusercontent.com/dgraph-io/charts/dgraph-$VERS/charts/dgraph/example_values/alpha-tls-config.yaml

# Install Chart with TLS Certificates
helm install $RELEASE \
 --values ~/dgraph_tls/secrets.yaml
 --values alpha-tls-config.yaml
 dgraph/dgraph
 ```

#### Step 3: Testing mutual TLS with Dgraph Alpha

Use port forwarding with Dgraph Alpha GRPC to make it available on localhost in another terminal tab:

```bash
export RELEASE="my-release"
kubectl port-forward $RELEASE-dgraph-alpha-0 9080:9080
```

Use port forwarding with Dgraph Alpha HTTPS to make it available on localhost in another terminal tab:

```bash
export RELEASE="my-release"
kubectl port-forward $RELEASE-dgraph-alpha-0 8080:8080
```

Now we can test GRPC with `dgraph increment`, and HTTPS with `curl`:

```bash

# Test GRPC using Mutual TLS
dgraph increment \
 --tls_cacert ~/dgraph_tls/alpha/ca.crt \
 --tls_cert ~/dgraph_tls/alpha/client.dgraphuser.crt \
 --tls_key ~/dgraph_tls/alpha/client.dgraphuser.key \
 --tls_server_name "localhost"

# Test HTTPS using Mutual TLS
curl --silent \
  --cacert ~/dgraph_tls/alpha/ca.crt \
  --cert ~/dgraph_tls/alpha/client.dgraphuser.crt \
  --key ~/dgraph_tls/alpha/client.dgraphuser.key \
  https://localhost:8080/state  
```

## Securing internal communication with mutual TLS

Starting with Dgraph `v20.11.0`, both Alpha and Zero can now use secure internal communication with Mutual TLS. As an example, see [zero-tls-config.yaml](https://github.com/dgraph-io/charts/tree/master/charts/dgraph/example_values/zero-tls-config.yaml) for an example configuration.

### Securing internal Communication mutual TLS example

#### Step 1: Create certificates, keys, and Helm chart secrets config

Similar to the above process in generating the certificate, keys, and configuration with [make_tls_secrets.sh](https://github.com/dgraph-io/charts/blob/master/charts/dgraph/scripts/make_tls_secrets.sh), you will add a `--zero` argument to generate the node certificate and key for the Dgraph Zero service in addition to the Dgraph Alpha service.

```bash
VERS=0.0.13

## Download Script
curl --silent --remote-name --location \
  https://raw.githubusercontent.com/dgraph-io/charts/dgraph-$VERS/charts/dgraph/scripts/make_tls_secrets.sh
bash make_tls_secrets.sh \
  --release "my-release" \
  --namespace "default" \
  --replicas 3 \
  --client "dgraphuser" \
  --zero \
  --tls_dir ~/dgraph_tls
```

#### Step 2: Deploy

The certificates created support and Alpha and Zero internal headless Service DNS hostnames. We can deploy a Dgraph cluster using these certs.

```bash
export RELEASE="my-release"

# Download Example Dgraph Alpha + Zero config for using mTLS on internal ports
curl --silent --remote-name --location \
 https://raw.githubusercontent.com/dgraph-io/charts/dgraph-$VERS/charts/dgraph/example_values/zero-tls-config.yaml

# Install Chart with TLS Certificates
helm install $RELEASE \
 --values ~/dgraph_tls/secrets.yaml
 --values zero-tls-config.yaml
 dgraph/dgraph
 ```

#### Step 3: Testing mutual TLS with Dgraph Zero

Now we can test Dgraph Zero HTTPS with `curl` below.  For testing Alpha, see [Step 3: Testing mutual TLS with Dgraph Alpha](#step-3-testing-mutual-tls-with-dgraph-alpha).


First, use port forwarding to forward Dgraph Zero HTTPS port to localhost in another terminal tab:

```bash
export RELEASE="my-release"
kubectl port-forward $RELEASE-dgraph-zero-0 6080:6080 &
```

Now we can test Dgraph Zero HTTPS:

```bash
# Test HTTPS using Mutual TLS
curl --silent \
  --cacert ~/dgraph_tls/zero/ca.crt \
  --cert ~/dgraph_tls/zero/client.dgraphuser.crt \
  --key ~/dgraph_tls/zero/client.dgraphuser.key \
  https://localhost:6080/state
```

## Alpha encryption at rest

You can generate a secret for the key file using `base64` tool:

```bash
printf '12345678901234567890123456789012' | base64
# MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTI=
```

Then create a Helm chart value config file with the secret:

```yaml
# alpha-enc-secret.yaml
alpha:
  encryption:
    file:
      enc_key_file: MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTI=
```

Create a corresponding configuration enables and configures Dgraph Alpha to use this file:

```yaml
# alpha-enc-config.yaml
alpha:
  encryption:
    enabled: true
  configFile:
    config.yaml: |
      encryption:
        key_file: /dgraph/enc/enc_key_file
      security:
        whitelist: 10.0.0.0/8,172.0.0.0/8,192.168.0.0/16
```

Then deploy Dgraph using the secret and config files:

```bash
RELNAME=my-release
helm install $RELNAME \
 --values alpha-enc-secret.yaml
 --values alpha-enc-config.yaml
 dgraph/dgraph
```

## Alpha access control lists

You can generate a secret for the secrets file using `base64` tool:

```bash
printf '12345678901234567890123456789012' | base64
# MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTI=
```

Then create a Helm chart value config file with the secret:

```yaml
# alpha-acl-secret.yaml
alpha:
  acl:
    file:
      hmac_secret_file: MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTI=
```

Create a corresponding configuration enables and configures Dgraph Alpha to use this file:

```yaml
# alpha-acl-config.yaml
alpha:
  acl:
    enabled: true
  configFile:
    config.yaml: |
      acl:
        secret_file: /dgraph/acl/hmac_secret_file
      security:
        whitelist: 10.0.0.0/8,172.0.0.0/8,192.168.0.0/16
```

Then deploy Dgraph using the secret and config files:

```bash
RELNAME=my-release
helm install $RELNAME \
 --values alpha-acl-secret.yaml
 --values alpha-acl-config.yaml
 dgraph/dgraph
```

## Binary backups

Dgraph [Binary Backups](https://docs.dgraph.io/admin/admin-tasks/binary-backups) are supported by Kubernetes CronJobs. There are two types of Kubernetes CronJobs supported:

* Full backup at midnight: `0 * * * *`
* Incremental backups every hour, except midnight: `0 1-23 * * *`

Binary Backups supports three types of _destinations_:

* File path (Network File System recommended)
* [Amazon Simple Storage Service](https://aws.amazon.com/s3/) (S3)
* [MinIO](https://min.io/) Object Storage

### Using Amazon S3

You can use [Amazon S3](https://aws.amazon.com/s3/) with backup cronjobs.  You will want to configure the following:

* Backups
  * `backups.destination` - should be in this format `s3://s3.<region>.amazonaws.com/<bucket>`
  * `keys.s3.access`  - set for `AWS_ACCESS_KEY_ID` used on Alpha pods, that is stored as a secret.
  * `keys.s3.secret`  - set for `AWS_SECRET_ACCESS_KEY` used on Alpha pods, that is stored as a secret.

### Using MinIO

For this option, you will need to deploy a MinIO Server or a MinIO Gateway such as [MinIO GCS Gateway](https://docs.min.io/docs/minio-gateway-for-gcs.html) or [MinIO Azure Gateway](https://docs.min.io/docs/minio-gateway-for-azure.html).  The [MinIO Helm Chart](https://helm.min.io/) can be useful for this process.

For Minio configuration, you will want to configure the following:

* Backups
  * `backups.destination` - should be in this format `minio://<server-address>:9000/<bucket>`.
  * `minioSecure` (default: `false`) - configure this to `true` if you installed TLS certs/keys for MinIO server.
  * `keys.minio.access`  - set for `MINIO_ACCESS_KEY` used on Alpha pods, that is stored as a secret.
  * `keys.minio.secret`  - set for `MINIO_SECRET_KEY` used on Alpha pods, that is stored as a secret.

### Using NFS

Backup cronjobs can take advantage of NFS if you have an NFS server available, such as [EFS](https://aws.amazon.com/efs/) or [GCFS](https://cloud.google.com/filestore).  For external NFS servers outside of the Kubernetes cluster, the NFS server will need to be accessible from Kubernetes Worker Nodes.  

When this feature is enabled, a shared NFS volume will be mounted on each of the Alpha pods to `/dgraph/backups` by default. The NFS volume will also be mounted on backup cronjob pods so that the backup script can create datestamp named directories to organize full and incremental backups.

* Backups
  * `backups.destination` (default: `/dgraph/backups`) - file-path where Dgraph Alpha will save backups
  * `backups.nfs.server` - NFS server IP address or DNS name.  If external to the Kubernetes, the NFS server should be accessible from Kubernetes worker nodes.
  * `backups.nfs.path` - NFS server path, e.g. [EFS](https://aws.amazon.com/efs/) uses `/`, while with [GCFS](https://cloud.google.com/filestore), the user specifies this during creation.
  * `backups.nfs.storage` (default: `512Gi`) - storage allocated from NFS server
  * `backups.nfs.mountPath` (default: `/dgraph/backups`) - this is mounted on Alpha pods, should be same as `backups.destination`

### Using mutual TLS

If Dgraph Alpha TLS options are used, backup cronjobs will submit the requests using HTTPS.  If Mutual TLS client certificates are configured as well, you need to specify the name of the client certificate and key so that the backup cronjob script can find them.

* Alpha
  * see [Alpha TLS Options](#alpha-tls-options) above.
* Backups
  * `backups.admin.tls_client` - this should match the client cert and key that was created with `dgraph cert --client`, e.g. `backupuser`

### Using the access control list

When ACLs are used, the backup cronjob will log in to the Alpha node using a specified user account.  Through this process, the backup cronjob script will receive an AccessJWT token that will be submitted when requesting a backup.

* Alpha
  * see [Alpha Access Control Lists](#alpha-access-control-lists) above.
* Backups
  * `backups.admin.user` (default: `groot`) - a user that is a member of `guardians` group will need to be specified.
  * `backups.admin.password` (required) - the corresponding password for that user will need to be specified.

### Using an auth token

When a simple Auth Token is used, the backup cronjob script will submit an auth token when requesting a backup.

* Alpha
  * Alpha will need to be configured with environment variable `DGRAPH_ALPHA_TOKEN` or configuration with `auth_token` set.
* Backups
  * `backups.admin.auth_token` - this will need to have the same value configured in Alpha

### Using a different backup image

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

Further information can be found in the [Monitoring in Kubernetes](https://docs.dgraph.io/admin/observability/monitoring) documentation.
