# dgraph-lambda helm chart

## TL;DR

```bash
helm repo add dgraph https://charts.dgraph.io
helm install "my-lambda" dgraph/dgraph-lambda
```

## Introduction

### Prerequisites

- Kubernetes 1.16+
- Helm 3.0+
- Dgraph v20.11.0 or greater
  - configured with `graphql_lambda_url` and `whitelist`

### Configuration

In order to use `dgraph-lambda`, you must do the following:

1. deploy Dgraph Alpha configured to point to `dgraph-lambda`
2. configure lambda script helm override values for `dgraph-lambda`
3. deploy Dgraph Lambda service configured to point to Dgraph Alpha services
4. add GraphQL schema for the resolvers added by the lambda script

#### Environment

For these steps, set up following environment variables:

```bash
export NS=default
export LAMBDA_REL=my-lambda
export DGRAPH_REL=my-release
```

#### Deploy Dgraph Alpha

Dgraph Alpha will need to be configured with the `--graphql_lambda_url` and `--whitelist` arguments (see: [lambda server](https://dgraph.io/docs/graphql/lambda/server/)) to support `dgraph-lambda`.  You can use environment variables to configure this:

```bash
helm install $DGRAPH_REL dgraph/dgraph \
  --namespace $NS \
  --set alpha.extraEnvs[0].name=DGRAPH_ALPHA_GRAPHQL_LAMBDA_URL \
  --set alpha.extraEnvs[0].value=http://$LAMBDA_REL-dgraph-lambda.$NS.svc:80/graphql-worker \
  --set alpha.extraEnvs[1].name=DGRAPH_ALPHA_WHITELIST \
  --set alpha.extraEnvs[1].value='10.0.0.0\/8\,172.16.0.0/12\,192.168.0.0\/16'
```

The `DGRAPH_ALPHA_GRAPHQL_LAMBDA_URL` environment variable will point to Dgraph Lambda service that will be deployed in the next step.  The format Dgraph Lambda domain name is formatted as the following:

```
http://<helm-chart-release-name>-dgraph-lambda.<namesapce>.svc/graphql-worker
```

#### Configure Lambda script

First we can create a Helm override values with the lambda script embedded into it like the example below:

```yaml
# my-lambda.yaml
script:
  enabled: true
  script: |
    async function authorsByName({args, dql}) {
        const results = await dql.query(`query queryAuthor($name: string) {
            queryAuthor(func: type(Author)) @filter(eq(Author.name, $name)) {
                name: Author.name
                dob: Author.dob
                reputation: Author.reputation
            }
        }`, {"$name": args.name})
        return results.data.queryAuthor
    }

    async function newAuthor({args, graphql}) {
        // lets give every new author a reputation of 3 by default
        const results = await graphql(`mutation ($name: String!) {
            addAuthor(input: [{name: $name, reputation: 3.0 }]) {
                author {
                    id
                    reputation
                }
            }
        }`, {"name": args.name})
        return results.data.addAuthor.author[0].id
    }

    self.addGraphQLResolvers({
        "Query.authorsByName": authorsByName,
        "Mutation.newAuthor": newAuthor
    })
```

#### Deploy Dgraph Lambda

We can deploy the example above, named `my-lambda.yaml`, with the follwing:

```bash
helm install $LAMBDA_REL dgraph/dgraph-lambda \
  --namespace $NS \
  --values my-lambda.yaml \
  --set alpha.env[0].name=DGRAPH_URL \
  --set alpha.env[0].value=http://$DGRAPH_REL-dgraph-alpha-headless.$NS.svc:8080
```

The `DGRAPH_URL` environment variable will point to Dgraph Alpha service deployed in the previous step.  The format Dgraph Alpha domain name is formatted as the following:

```
http://<helm-chart-release-name>-dgraph-alpha-headless.<namespace>.svc:8080
```

#### Add GraphQL schema

After deploying both services with the lambda script, upload a schema:

```bash
## create schema file
cat <<-EOF > my-schema.graphql
type Author {
    id: ID!
    name: String! @search(by: [hash, trigram])
    dob: DateTime
    reputation: Float
}

type Query {
    authorsByName(name: String!): [Author] @lambda
}

type Mutation {
    newAuthor(name: String!): ID! @lambda
}
EOF

## port-forward Dgraph Alpha
kubectl port-forward --namespace $NS $DGRAPH_REL-dgraph-alpha-0 8080:8080

## upload schema file
curl http://localhost:8080/admin/schema --upload-file my-schema.graphql
```


## Configuration

The following table lists the configurable parameters of the `dgraph` chart and their default values.

|              Parameter                   |                             Description                               |                       Default                       |
| ---------------------------------------- | --------------------------------------------------------------------- | --------------------------------------------------- |
| `replicaCount`                           | number of Kubernetes replicas                                         | `1`                                                 |
| `image.repository`                       | Container repository name                                             | `dgraph/dgraph-lambda`                              |
| `image.pullPolicy`                       | Container image pull policy                                           | `IfNotPresent`                                      |
| `image.tag`                              | Container image tag                                                   | `v20.11.0`                                          |
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
