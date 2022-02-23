## Dgraph lambda

This demonstrates how to use [Lambda Resolvers](https://dgraph.io/docs/graphql/lambda/overview/) on a Kubernetes cluster.

## Instructions

### Install dgraph and dgraph-lambda

```bash
helmfile apply
```

This will install `dgraph` (Helm Release Name: `dev`, Namespace: `default`) and `dgraph-lambda` (Helm Release Name: `lambda`, Namespace: `default`).

### Add schema

Once the Dgraph cluster is deployed where Dgraph Alpha pods are in a `Running` state, you can run the following to upload the schema:

```bash
kubectl port-forward dev-dgraph-alpha-0 8080:8080
curl http://localhost:8080/admin/schema --upload-file example/schema.graphql
```

You can verify schema is uploaded with the optional [jq](https://stedolan.github.io/jq/) tool:

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
kubectl delete pvc --selector release=dev
```

## Addendum: mutation and query with curl

If you would like to quickly test the functionality from the command line with `curl`, you can do the following below to convert graphql to rest json format, and perform the query or mutation.

```bash
## Port forward Alpha pod to localhost (skip if this is already completed)
kubectl port-forward dev-dgraph-alpha-0 8080:8080

## run graphql mutation
curl http://localhost:8080/graphql --silent --request POST \
  --header "Content-Type: application/graphql" \
  --upload-file example/mutation.graphql

## perform graphql query
curl http://localhost:8080/graphql --silent --request POST \
  --header "Content-Type: application/graphql" \
  --upload-file example/query.graphql
```

## Addendum: Using vanilla helm

If you would like to forgo using `helmfile` and instead just use the vanilla `helm` tool, you can do the same process with the following:

```bash
helm install dev ../../charts/dgraph \
  --set alpha.extraEnvs[0].name=DGRAPH_ALPHA_LAMBDA \
  --set alpha.extraEnvs[0].value=url=http://lambda-dgraph-lambda.default.svc/graphql-worker

helm install lambda ../../charts/dgraph-lambda \
  --values example/script.yaml \
  --set env[0].name=DGRAPH_URL \
  --set env[0].value=http://dev-dgraph-alpha-headless.default.svc:8080
```

You can clean up with:

```bash
helm delete dev
helm delete lambda
kubectl delete pvc --selector release=dev
```

## Addendum: Troubleshooting Dgraph Lambda tips

Here are a few commands that may be useful in checking settings of Dgraph Lamba service and configuration:

```bash
LAMBDA_POD=$(kubectl get pod --selector app.kubernetes.io/name=dgraph-lambda --output jsonpath={.items[0].metadata.name})
# print env vars and verify correctness
kubectl get pod/$LAMBDA_POD --output jsonpath="{range .spec.containers[0].env[*]}{.name}={.value}{\"\n\"}{end}"
## check script from mounted path
kubectl exec -t $LAMBDA_POD -- ls -l /script/script.js
## verify script contents
kubectl exec -t $LAMBDA_POD -- cat /script/script.js

## check configmap configuration if missing script
kubectl get cm/lambda-dgraph-lambda-config --output jsonpath='{.data.script\.js}'

## verify schema on Dgraph Alpha
curl http://localhost:8080/admin --silent \
  --header "Content-Type: application/json" \
  --data '{"query": "{ getGQLSchema { schema } }"}' \
   | jq -r .data.getGQLSchema.schema
```
