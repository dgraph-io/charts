## Dgraph lambda

This demonstrates how to use [Lambda Resolvers](https://dgraph.io/docs/graphql/lambda/overview/) on a Kubernetes cluster.

## Instructions

### Install dgraph and dgraph-lambda

```bash
helmfile apply
```

### Add schema

Once the Dgraph cluster is deployed where Dgraph Alpha pods are in Running state, you can run the following to upload the schema:

```bash
kubectl port-forward dev-dgraph-alpha-0 8080:8080
curl http://localhost:8080/admin/schema --upload-file schema.graphql
```
