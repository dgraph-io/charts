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
export DGRAPH_PERSISTENCE="false" # default
TESTS="alpha-acl alpha-enc alpha-tls default-json default-yaml alpha-tls zero-tls"

for TEST in $TESTS; do
  helmfile --environment $TEST apply
done
```

### Run Tests with persistence

```bash
export DGRAPH_PERSISTENCE="true"
TESTS="alpha-tls alpha-acl alpha-enc alpha-tls default-json default-yaml zero-tls"

for TEST in $TESTS; do
  helmfile --environment $TEST apply
done
```

## Cleanup Kubernetes Resources

You can delete all of the pods including any persistence volumes with:

```bash
TESTS="alpha-acl alpha-enc alpha-tls default-json default-yaml alpha-tls zero-tls"

# Delete k8s resources except pvc
for TEST in $TESTS; do
  helm uninstall test --namespace dgraph-test-${TEST} 2> /dev/null
done

# Delete persistence if it exists
# NOTE: PVC resources will not get deleted if they are in use, so pods must be
# deleted first
for TEST in $TESTS; do
  if kubectl get pvc --namespace dgraph-test-${TEST} \
       --selector release=test 2> /dev/null | grep -q "test"; then
    kubectl delete pvc --namespace dgraph-test-${TEST} --selector release=test
  fi
done
```
