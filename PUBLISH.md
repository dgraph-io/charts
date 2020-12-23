## Publish Helm Charts

### Before we begin

Firstly, make sure you have [Helm](https://github.com/helm/helm/releases) and [Chart Releaser](https://github.com/helm/chart-releaser/releases) installed on the machine.

The helm chart repository is available from [here](https://charts.dgraph.io/), which is hosted using
`gh-pages` branch of the [charts repository](https://github.com/dgraph-io/charts).

### Lint the chart

It is always a good habit to lint the charts. The `helm lint` command runs a series of tests
to verify that the chart is well-formed:

```bash
helm lint charts/dgraph
helm ling charts/dgraph-lambda
```

### Create the Helm chart package

The `helm package` command packages a chart into a versioned chart archive file.

```bash
## remove existing packages
rm -rf .cr-release-packages/*
## for publishing dgraph
helm package charts/dgraph --destination .cr-release-packages/
## for publishing dgraph-lambda chart
helm package charts/dgraph-lambda --destination .cr-release-packages/
```

### Upload the package to GitHub

Set the environment variables to their appropriate values, as shown below:

```bash
export CR_OWNER="dgraph-io"
export CR_GIT_REPO="charts"
export CR_PACKAGE_PATH="/path/to/.cr-release-packages"
export CR_TOKEN="<your-github-token>"
```

The `cr upload` command uploads the package as an asset to a new GitHub release.
If you have above configurations are correct, and the owner account has access to create
releases, the command below should exit without any error:

```bash
cr upload
```

### Configuration

An optional `--config` can used instead of environment variables.

```yaml
## File: ~/.config/chart-releaser/config.yaml
owner: dgraph-io
git-repo: charts
package-path: /path/to/.cr-release-packages
token: <your-github-token>
## index config specific
index-path: index.yaml
charts-repo: https://charts.dgraph.io/
```

### Create or Append the Helm chart repository index

Before we create the index file, we will check out to the `gh-pages` branch and pull the latest
changes from the remote GitHub repository to verify the creation of a new tag.

```bash
git checkout gh-pages
git pull
```

Generally, we would use the `helm repo index` command which reads the current directory and generates
an index file based on the charts found and creates an `index.yaml` file for the chart repository.

Here, we use `cr index` which would the equivalent task with Chart Releaser but would use the link
of GitHub release asset instead of of the current directory.

Before using `cr index`, we will need to set the environment variables to their appropriate values as shown below.  This can be skipped if configuration with `--config` is used instead.

```bash
export CR_OWNER="dgraph-io"
export CR_GIT_REPO="charts"
export CR_CHARTS_REPO="https://charts.dgraph.io/"
export CR_INDEX_PATH="index.yaml"
export CR_PACKAGE_PATH=".cr-release-packages"
```

```bash
cr index
```

Verify that `index.yaml` file is created:

```bash
$ cat index.yaml
```

### Publish the chart

To publish the chart, commit and push the latest changes of index file to `gh-pages` branch.

```bash
git add index.yaml
## cample commit strings:
##   dgraph-lambda-0.0.1 index.yaml update
##   dgraph-0.0.13 index.yaml update
git commit -m "chart-version index.yaml update"
git push origin gh-pages
```

## Cleanup

In the end, be sure to delete the `.cr-release-packages` folder.

```bash
rm -rf .cr-release-packages
```
