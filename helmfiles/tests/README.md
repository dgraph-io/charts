# Tests

These tests Dgraph delployments with a variety helm config values.  

## Create Secrets Using Docker Container

```bash
docker run --rm --detach \
  --publish "8080:8080" \
  --publish "9080:9080" \
  --publish "8000:8000" \
  --volume $PWD/dgraph_tls:/dgraph_tls \
  --name "dgraph-certs" \
  "dgraph/standalone:v21.03.0"

docker cp \
  ../../charts/dgraph/scripts/make_tls_secrets.sh \
  dgraph-certs:/make_tls_secrets.sh

docker exec -it dgraph-certs /make_tls_secrets.sh --release "test" \
  --client "dgraphuser" --zero --tls_dir /dgraph_tls

## Verify Dgraph Alpha Keys and Certificates
docker exec -it dgraph-certs dgraph cert ls --dir /dgraph_tls/alpha
## Verify Dgraph Zero Keys and Certificates
docker exec -it dgraph-certs dgraph cert ls --dir /dgraph_tls/zero
```

## Run Tests

This will deploy a dgraph cluster using different types of dgraph configuration.  Use the `--environment $TEST` flag to select the desired test.  

The focus on these tests is to deploy Dgraph on Kubernetes, and verify that dgraph is running successful.

### Run Tests without persistence

```bash
TESTS="alpha-tls alpha-enc alpha-tls default-json default-yaml zero-tls"

for TEST in $TESTS; do
  helmfile --environment $TEST apply
done
```

### Run Tests with persistence

```bash
export DGRAPH_ALPHA_PERSISTENCE=true
export DGRAPH_ZERO_PERSISTENCE=true
TESTS="alpha-tls alpha-enc alpha-tls default-json default-yaml zero-tls"

for TEST in $TESTS; do
  helmfile --environment $TEST apply
done
```

## Clean up PVCs

If you enabled peristence, you can delete the PVC with:

```bash
TESTS="alpha-tls alpha-enc alpha-tls default-json default-yaml zero-tls"

for TEST in $TESTS; do
  kubectl delete pvc --namespace dgraph-test-${TEST} --selector release=test delete
done
```
