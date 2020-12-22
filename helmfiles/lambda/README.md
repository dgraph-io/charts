## Dgraph lambda

This demonstrates how to use [Lambda Resolvers](https://dgraph.io/docs/graphql/lambda/overview/) on a Kubernetes cluster.

## Instructions

### Install dgraph and dgraph-lambda

```bash
helmfile apply
```

This will install `dgraph` (Helm Release Name: `dev`, Namespace: `default`) and `dgraph-lambda` (Helm Release Name: `lambda`, Namespace: `default`).

### Add schema

Once the Dgraph cluster is deployed where Dgraph Alpha pods are in `Running` state, you can run the following to upload the schema:

```bash
kubectl port-forward dev-dgraph-alpha-0 8080:8080
curl http://localhost:8080/admin/schema --upload-file schema.graphql
```

You can verify schema is uploaded with [jq](https://stedolan.github.io/jq/) tool:

```bash
curl http://localhost:8080/admin --silent \
  --header "Content-Type: application/json" \
  --data '{"query": "{ getGQLSchema { schema } }"}' \
   | jq -r .data.getGQLSchema.schema
```

## Mutation and Queries

With your favorite GraphQL editor, you can try mutations and queries.  Using the `kubectl port-forward dev-dgraph-alpha-0 8080:8080`, you can use this url: http://localhost:8080/graphql to access Dgraph Alpha.

### Mutation

```graphql
mutation {
  newAuthor(name: "Ken Addams")
}
```

### Query

```graphql
query {
  authorsByName(name: "Ken Addams") {
    name
    dob
    reputation
  }
}
```

## Clean Up

To delete the Dgraph cluster and the dgraph-lambda, you can do the following:

```bash
helmfile delete
kubectl delete pvc -l release=dev
```

## Addendum: mutation and query with curl

If you would like to quickly test the functionality from the command line with `curl`, you can do the following below to convert graphql to rest json format, and perform the query or mutation.

```bash
## gql2json() to convert graphql query file to escaped REST(JSON) formatted string
function gql2json {
  GQL=$(cat $1 | tr '\r\n\t' ' ' | tr -s ' ' | sed 's/"/\\"/g')
  echo "{\"query\":\"${GQL}\"}"
}

## Port forward Alpha pod to localhost (skip if this is already completed)
kubectl port-forward dev-dgraph-alpha-0 8080:8080

## run graphql mutation
curl http://localhost:8080/graphql -sH "Content-Type: application/json" -d"$(gql2json mutation.graphql)"

## perform graphql query
curl http://localhost:8080/graphql -sH "Content-Type: application/json" -d"$(gql2json query.graphql)"
```

## Addendum: Using vanilla helm

If you would like to forgo using `helmfile` and instead just use the vanilla `helm` tool, you can do the same process with the following:

```bash
helm install dev ../../charts/dgraph \
  --set alpha.extraEnvs[0].name=DGRAPH_ALPHA_GRAPHQL_LAMBDA_URL \
  --set alpha.extraEnvs[0].value=http://lambda-dgraph-lambda.default.svc:80/graphql-worker \
  --set alpha.extraEnvs[1].name=DGRAPH_ALPHA_WHITELIST \
  --set alpha.extraEnvs[1].value='10.0.0.0\/8\,172.16.0.0/12\,192.168.0.0\/16'

helm install lambda ../../charts/dgraph-lambda \
  --values script.yaml \
  --set alpha.extraEnvs[0].name=DGRAPH_URL \
  --set alpha.extraEnvs[0].value=http://dev-dgraph-alpha-headless.default.svc:8080
```

You can clean up with:

```bash
helm delete dev
helm delete lambda
kubectl delete pvc -l release=dev
```
