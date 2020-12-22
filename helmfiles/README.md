# Helmfiles

The `helmfile` is a useful tool to manage values dynamically across several helm charts.  Normally, with only with the `helm` tool by itself, you would use static values and install one chart at a time.

This can be useful to install Dgraph with Lambda function support, as well as other charts, such as monitoring with Prometheus, observability with Jaeger, logging with EKF (ElasticSearch-Fluentd-Kibana) or PLG (Promtial-Loki-Grafana), MinIO for backup storage, and so on.

This directory will have example helmfile scripts that you can adapt for your environments.

## Overview

Article:

* [Helmfile: What Is It?](https://tanzu.vmware.com/developer/guides/kubernetes/helmfile-what-is/) - succinct summary on `helmfile` tool and why is it important.

## Installation of Tools

* Prerequisite Tools
  * `kubectl` - https://kubernetes.io/docs/tasks/tools/install-kubectl/
  * `helm` - https://helm.sh/
     * helm-diff plugin - https://github.com/databus23/helm-diff
* Helmfile Tools
  * `helmfile` - https://github.com/roboll/helmfile#installation

## Usage

Helmfile uses `helmfile.yaml` in the current working directory, but can use alternative filepath with `--file` argument.

```bash
## diff releases from state file against env (helm diff)
helmfile diff --file path/to/helmfile/lambda.yaml
## apply all resources from state file only when there are changes
helmfile apply --file path/to/helmfile/lambda.yaml
## sync all resources from state file (repos, releases and chart deps)
helmfile sync --file path/to/helmfile/lambda.yaml
```
