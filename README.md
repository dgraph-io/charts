# Dgraph Helm Chart

Dgraph helm chart ready to be deployed on Kubernetes using [Kubernetes Helm](https://github.com/helm/helm).

**Use [Discuss Issues](https://discuss.dgraph.io/tags/c/issues/35/charts) for reporting issues about this repository.**

## TL;DR

```bash
$ helm repo add dgraph https://charts.dgraph.io
$ helm install my-release dgraph/dgraph
```

## Before you begin

### Setup a Kubernetes Cluster

The quickest way to setup a Kubernetes cluster is with [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/),
[AWS Elastic Kubernetes Service](https://aws.amazon.com/eks/) or [Azure Kubernetes Service](https://azure.microsoft.com/en-us/services/kubernetes-service/)
using their respective quick-start guides. For setting up Kubernetes on other cloud platforms or
bare-metal servers refer to the Kubernetes [getting started guide](http://kubernetes.io/docs/getting-started-guides/).

### Install kubectl

The [Kubernetes](https://kubernetes.io/) command-line tool, `kubectl`, allows you to
run commands against Kubernetes clusters. You can use kubectl to deploy applications,
inspect and manage cluster resources, and view logs.

To install `kubectl` follow the instructions [here](https://kubernetes.io/docs/tasks/tools/install-kubectl/).

### Install Helm

[Helm](https://helm.sh/) is a tool for managing Kubernetes charts. Charts are packages
of pre-configured Kubernetes resources.

To install Helm follow the instructions [here](https://helm.sh/docs/intro/install/).

### Add Repo

To add the Dgraph helm repository:

```bash
$ helm repo add dgraph https://charts.dgraph.io
```

### Usage

See the [README of Dgraph helm chart](./charts/dgraph/README.md).

### Publishing the Chart

See the [instructions here to publish the chart](./PUBLISH.md).

# License

Copyright 2016-2020 Dgraph Labs, Inc.

Source code in this repository is variously licensed under the Apache Public License 2.0 (APL)
and the Dgraph Community License (DCL). A copy of each license can be found in the
[licenses](https://github.com/dgraph-io/dgraph/tree/main/licenses) directory.

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.
