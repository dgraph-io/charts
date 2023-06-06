# Ratel

## TL;DR

```bash
helm repo add dgraph https://charts.dgraph.io
helm install "my-ratel" --namespace "my-ratel" dgraph/ratel
```

## Introduction

Ratel is a [SPA](https://wikipedia.org/wiki/Single-page_application) ([single-page-application](https://wikipedia.org/wiki/Single-page_application)) [React](https://react.dev/) client that runs locally from your web browser.  The server component is a small web server that hosts the client application, which is then downloaed into your browser locally. There is no server-to-server connection. 


### Prequisites

* Kubernetes 1.20+
* Helm 3.0+
* Dgraph v21.12.0+

### Restricting Ratel

For best practices in security, it is recommended that you install Ratel separately instead of bundled together with the Dgraph.  This small web server should be installed in a namespace that is separate from Dgraph server. If your Kubernetes cluster supports the [network policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) feature, such as [Calico](https://www.tigera.io/project-calico/), you can use these to restrict traffic between the web service hosting Ratel and Dgraph servers.

Given this, use thie helm chart to install Ratel separately from Dgraph

### Accessing Ratel

In order for the Ratel client to connect to the Dgraph Alpha server, you can connect through a tunnel, such as VPN, or connect Dgraph Alpha to an endpoint, such as [service](https://kubernetes.io/docs/concepts/services-networking/service/) of type [LoadBalancer](https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer) or use an [ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) resource.  See Dgraph helm chart for further information on such configurations.

## Configuration

The following table lists the configurable parameters of the ratel chart and their default values.

|              Parameter                   |                             Description                               |                       Default                       |
| ---------------------------------------- | --------------------------------------------------------------------- | --------------------------------------------------- |
| `replicaCount`                           | number of Kubernetes replicas                                         | `1`                                                 |
| `image.repository`                       | Container repository name                                             | `dgraph/dgraph-lambda`                              |
| `image.pullPolicy`                       | Container image pull policy                                           | `IfNotPresent`                                      |
| `image.tag`                              | Container image tag                                                   | `v21.12.0`                                          |
| `imagePullSecrets`                       | Image pull secrets auth tokens used to access a private registry      | `[]`                                                |
| `nameOverride`                           | Name override of the default chart name                               | `""`                                                |
| `fullnameOverride`                       | Full Name override of the release name + chart name                   | `""`                                                |
| `script.enabled`                         | Enable adding a lambda script                                         | `false`                                             |
| `script.script`                          | Embedded lambda script stored in a config map                         | `""`                                                |
| `env`                                    | Environment variables                                                 | see `values.yaml`                                   |
| `serviceAccount.create`                  | Specifies if service account should be created                        | `true`                                              |
| `serviceAccount.annotations`             | Service Account annotations                                           | `{}`                                                |
| `serviceAccount.name`                    | Service Account name                                                  | `""`                                                |
| `podAnnotations`                         | Additional pod annotations                                            | `{}`                                                |
| `podSecurityContext`                     | Pod Security context to define privilege and access control           | `{}`                                                |
| `securityContext`                        | Container Security context to define privilege and access control     | `{}      `                                          |
| `service.type`                           | Service type (`ClusterIP`, `NodePort`, `LoadBalancer`)                | `ClusterIP`                                         |
| `service.port`                           | Service inbound port                                                  | `80`                                                |
| `service.targetPort`                     | Service targetPort of dgraph-lambda service                           | `8686`                                              |
| `ingress.enabled`                        | Ingress enabled                                                       | `false`                                             |
| `ingress.annotations`                    | Ingress annotations                                                   | `{}`                                                |
| `ingress.hosts`                          | Ingress hosts list to configure virtual hosts + routes to the service | see `values.yaml`                                   |
| `ingress.tls`                            | Ingress tls configuration                                             | `[]`                                                |
| `resources`                              | Resource limites and requests                                         | `{}`                                                |
| `nodeSelector`                           | Node selection constraints                                            | `{}`                                                |
| `tolerations`                            | Allow scheduling pods onto nodes matching specified taints            | `[]`                                                |
| `affinity`                               | Affinity configuration to allow nodes to scheduled on desired nodes   | `{}`                                                |