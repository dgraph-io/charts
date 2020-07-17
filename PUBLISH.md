## Publish Helm Charts

### Before we begin

Firstly, make sure you have [Helm](https://github.com/helm/helm/releases) and [Chart Releaser](https://github.com/helm/chart-releaser/releases) installed on the machine.

The helm chart repository is available from [here](https://charts.dgraph.io/), which is hosted using
`gh-pages` branch of the [charts repository](https://github.com/dgraph-io/charts).

### Lint the chart

It is always a good habit to lint the charts. The `helm lint` command runs a series of tests
to verify that the chart is well-formed:

```bash
$ helm lint charts/dgraph
==> Linting charts/dgraph

1 chart(s) linted, 0 chart(s) failed
```

### Create the Helm chart package

The `helm package` command packages a chart into a versioned chart archive file.

```bash
$ helm package charts/dgraph --destination .cr-release-packages/
Successfully packaged chart and saved it to: /home/prashant/dgraph-code/charts/dgraph-0.0.2.tgz
```

### Upload the package to GitHub

Set the environment variables to their appropriate values, as shown below:

```bash
$ export CR_OWNER="dgraph-io"
$ export CR_GIT_REPO="charts"
$ export CR_PACKAGE_PATH=".cr-release-packages"
$ export CR_TOKEN="<your-github-token>"
```

The `cr upload` command uploads the package as an asset to a new GitHub release.
If you have above configurations are correct, and the owner account has access to create
releases, the command below should exit without any error:

```bash
$ cr upload
```

### Create or Append the Helm chart repository index

Before we create the index file, we will check out to the `gh-pages` branch and pull the latest
changes from the remote GitHub repository to verify the creation of a new tag.

```bash
$ git checkout gh-pages
Switched to branch 'gh-pages'
Your branch is up to date with 'origin/gh-pages'.

$ git pull
From github.com:dgraph-io/charts
 * [new tag]         dgraph-0.0.2 -> dgraph-0.0.2
Already up to date.
```

Generally, we would use the `helm repo index` command which reads the current directory and generates
an index file based on the charts found and creates an `index.yaml` file for the chart repository.

Here, we use `cr index` which would the equivalent task with Chart Releaser but would use the link
of GitHub release asset instead of of the current directory.

Before using `cr index`, we will need to set the environment variables to their appropriate values as shown below:

```bash
$ export CR_OWNER="dgraph-io"
$ export CR_GIT_REPO="charts"
$ export CR_CHARTS_REPO="https://charts.dgraph.io/"
$ export CR_INDEX_PATH="index.yaml"
$ export CR_PACKAGE_PATH=".cr-release-packages"
```

```bash
$ cr index
====> Using existing index at index.yaml
====> Found dgraph-0.0.2.tgz
====> Extracting chart metadata from .cr-release-packages/dgraph-0.0.2.tgz
====> Calculating Hash for .cr-release-packages/dgraph-0.0.2.tgz
--> Updating index index.yaml
```

Verify that `index.yaml` file is created:

```bash
$ cat index.yaml
apiVersion: v1
entries:
  dgraph:
  - apiVersion: v1
    appVersion: latest
    created: "2020-01-17T22:33:37.046458+05:30"
    description: Dgraph is a horizontally scalable and distributed graph database,
      providing ACID transactions, consistent replication and linearizable reads.
    digest: cbccd3f5c92f235a7bd78305f84af847c53d85060573c28372b20ecec9b61cf8
    home: https://dgraph.io/
    icon: https://dgraph.io/assets/images/logo.png
    keywords:
    - dgraph
    - database
    - Graph
    - GraphQL
    - nosql
    maintainers:
    - email: contact@dgraph.io
      name: dgraph
    name: dgraph
    sources:
    - https://charts.dgraph.io
    - https://github.com/dgraph-io/dgraph
    urls:
    - https://github.com/dgraph-io/charts/releases/download/dgraph-0.0.2/dgraph-0.0.2.tgz
    version: 0.0.2
generated: "2020-01-17T22:33:36.573305+05:30"
```

### Publish the chart

To publish the chart, commit and push the latest changes of index file to `gh-pages` branch.

```bash
$ git add index.yaml
$ git commit -m "Update index.yaml"
$ git push origin gh-pages
```

In the end, be sure to delete the `.cr-release-packages` folder.

```bash
$ rm -rf .cr-release-packages
```
