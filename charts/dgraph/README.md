# Dgraph

Dgraph is a horizontally scalable and distributed graph database, providing ACID transactions,
consistent replication and linearizable reads. It's built from ground up to perform for a rich set
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

These command deploy Dgraph on the Kubernetes cluster in the default configuration.
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

The following table lists the configurable parameters of the dgraph chart and their default values.

|              Parameter                   |                             Description                               |                       Default                       |
| ---------------------------------------- | --------------------------------------------------------------------- | --------------------------------------------------- |
| `image.registry`                         | Container registry name                                               | `docker.io`                                         |
| `image.repository`                       | Container image name                                                  | `dgraph/dgraph`                                     |
| `image.tag`                              | Container image tag                                                   | `v20.03.3`                                          |
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
| `zero.livenessProbe`                     | Zero liveness probes                                                  | See `values.yaml` for defaults                      |
| `zero.readinessProbe`                    | Zero readiness probes                                                 | See `values.yaml` for defaults                      |
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
| `alpha.configFile`                       | Alpha config file                                                     | `{}`                                                |
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
| `alpha.persistence.enabled`              | Enable persistence for alpha using PVC                                | `true`                                              |
| `alpha.persistence.storageClass`         | PVC Storage Class for alpha volume                                    | `nil`                                               |
| `alpha.persistence.accessModes`          | PVC Access Mode for alpha volume                                      | `['ReadWriteOnce']`                                 |
| `alpha.persistence.size`                 | PVC Storage Request for alpha volume                                  | `100Gi`                                             |
| `alpha.nodeSelector`                     | Node labels for alpha pod assignment                                  | `{}`                                                |
| `alpha.tolerations`                      | Alpha tolerations                                                     | `[]`                                                |
| `alpha.resources.requests.memory`        | Zero pod resources memory request                                     | `100Mi`                                             |
| `alpha.livenessProbe`                    | Alpha liveness probes                                                 | See `values.yaml` for defaults                      |
| `alpha.readinessProbe`                   | Alpha readiness probes                                                | See `values.yaml` for defaults                      |
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
| `global.ingress.enabled`                 | Enable global ingress resource (overrides alpha/ratel ingress)        | `false`                                             |
| `global.ingress.annotations`             | global ingress annotations                                            | `{}`                                                |
| `global.ingress.tls`                     | global ingress tls settings                                           | `{}`                                                |
| `global.ingress.ratel_hostname`          | global ingress virtual host name for ratel service                    | `""`                                                |
| `global.ingress.alpha_hostname`          | global ingress virtual host name for alpha service                    | `""`                                                |


## Ingress Resource

You can define ingress resources through `alpha.ingress` for the alpha http service and `ratel.ingress` for the ratel ui service, or you can use a combined single ingress with `global.ingress` for both alpha http and ratel ui services.

There are some example chart values for ingress resource configuration in [example_values](https://github.com/dgraph-io/charts/tree/master/charts/dgraph/example_values).

## Alpha TLS Options

The Dgraph alpha service can be configured to use Mutual TLS.  Instructions about this configuration can be found in `values.yaml`.  

It is recommend that you keep secrets values and config values in separate yaml files.  To assist with this practice, you can use the [make_tls_secrets.sh](https://github.com/dgraph-io/charts/blob/master/charts/dgraph/scripts/make_tls_secrets.sh) script to generate a `secrets.yaml` file from an existing `./tls` directory that was previously generated by the `dgraph cert` command.

There are some example chart values for Alpha TLS configuration in [example_values](https://github.com/dgraph-io/charts/tree/master/charts/dgraph/example_values).

### Alpha TLS Example

As an example to test this feature, you can run the following:

```bash
VERS="0.0.8"
RELNAME="my-release"

# Prepare Certificates/Keys
dgraph cert -n localhost -c dgraphuser
# Create Dgraph alpha secrets
curl --silent --remote-name --location \
  https://raw.githubusercontent.com/dgraph-io/charts/dgraph-$VERS/charts/dgraph/scripts/make_tls_secrets.sh
bash make_tls_secrets.sh
# Download Example Dgraph alpha config
curl --silent --remote-name --location \
 https://raw.githubusercontent.com/dgraph-io/charts/dgraph-$VERS/charts/dgraph/example_values/alpha-tls-config.yaml

# Install Chart with TLS Certificates
helm install $RELNAME \
 --values secrets.yaml
 --values alpha-tls-config.yaml
 --version $VERS
 dgraph/dgraph

# Port Forward Alpha GRPC to localhost (use other terminal tab)
kubectl port-forward $RELNAME-dgraph-alpha-0 9080:9080 &
# Port Forward Alpha HTTPS to localhost (use other terminal tab)
kubectl port-forward $RELNAME-dgraph-alpha-0 8080:8080 &

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


## Monitoring

Dgraph exposes prometheus metrics to monitor the state of various components involved in
the cluster, this includes dgraph alpha and zero.

Follow the below mentioned steps to setup prometheus monitoring for your cluster:

* Install Prometheus operator:

```bash
$ kubectl apply --filename https://raw.githubusercontent.com/coreos/prometheus-operator/release-0.34/bundle.yaml
```

* Ensure that the instance of `prometheus-operator` has started before continuing.

```bash
$ kubectl get deployments prometheus-operator
NAME                  DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
prometheus-operator   1         1         1            1           3m
```

* Apply prometheus manifest present [here](https://github.com/dgraph-io/dgraph/blob/master/contrib/config/monitoring/prometheus/prometheus.yaml).

```bash
$ kubectl apply --filename prometheus.yaml

serviceaccount/prometheus-dgraph-io created
clusterrole.rbac.authorization.k8s.io/prometheus-dgraph-io created
clusterrolebinding.rbac.authorization.k8s.io/prometheus-dgraph-io created
servicemonitor.monitoring.coreos.com/alpha.dgraph-io created
servicemonitor.monitoring.coreos.com/zero-dgraph-io created
prometheus.monitoring.coreos.com/dgraph-io created
```

To view prometheus UI locally run:

```bash
$ kubectl port-forward prometheus-dgraph-io-0 9090:9090
```

The UI is accessible at port 9090. Open http://localhost:9090 in your browser to play around.

To register alerts from dgraph cluster with your prometheus deployment follow the steps below:

* Create a kubernetes secret containing alertmanager configuration. Edit the configuration file
present [here](https://github.com/dgraph-io/dgraph/blob/master/contrib/config/monitoring/prometheus/alertmanager-config.yaml)
with the required reciever configuration including the slack webhook credential and create the secret.

You can find more information about alertmanager configuration [here](https://prometheus.io/docs/alerting/configuration/).

```bash
$ kubectl create secret generic alertmanager-alertmanager-dgraph-io --from-file=alertmanager.yaml=alertmanager-config.yaml

$ kubectl get secrets
NAME                                            TYPE                 DATA   AGE
alertmanager-alertmanager-dgraph-io             Opaque               1      87m
```

* Apply the [alertmanager](https://github.com/dgraph-io/dgraph/blob/master/contrib/config/monitoring/prometheus/alertmanager.yaml)
along with [alert-rules](https://github.com/dgraph-io/dgraph/blob/master/contrib/config/monitoring/prometheus/alert-rules.yaml)
manifest to use the default configured alert configuration. You can also add custom rules based on
the metrics exposed by dgraph cluster similar to [alert-rules](https://github.com/dgraph-io/dgraph/blob/master/contrib/config/monitoring/prometheus/alert-rules.yaml)
manifest.

```bash
$ kubectl apply --filename alertmanager.yaml
alertmanager.monitoring.coreos.com/alertmanager-dgraph-io created
service/alertmanager-dgraph-io created

$ kubectl apply --filename alert-rules.yaml
prometheusrule.monitoring.coreos.com/prometheus-rules-dgraph-io created
```
