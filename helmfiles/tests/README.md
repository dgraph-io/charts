# Tests

These tests validate Dgraph deployments with a variety of helm config values.  

## Create Secrets Using Docker Container

```bash
## Docker environment for the `dgraph cert` command
docker run --rm --detach \
  --publish "8080:8080" \
  --publish "9080:9080" \
  --publish "8000:8000" \
  --volume $PWD/dgraph_tls:/dgraph_tls \
  --name "dgraph-certs" \
  "dgraph/standalone:v21.03.0"

## Copy script to into container
docker cp \
  ../../charts/dgraph/scripts/make_tls_secrets.sh \
  dgraph-certs:/make_tls_secrets.sh

## Generate TLS certs per each test
TLS_TESTS="alpha-tls zero-tls"
for TEST in $TLS_TESTS; do
  docker exec -it dgraph-certs /make_tls_secrets.sh --release "test" \
    --client "dgraphuser" --namespace dgraph-test-$TEST --zero --tls_dir /dgraph_tls/dgraph-test-$TEST
done

## Verify certs/keys hostnames
for TEST in $TLS_TESTS; do
  echo "Dgraph Alpha: Release[test], Namespace [dgraph-test-$TEST]:"
  echo "-------------------------------------------------------------"  
  docker exec -it dgraph-certs dgraph cert ls --dir /dgraph_tls/dgraph-test-$TEST/alpha | awk -F: '/Hosts/{gsub(/\[ ]+/, "", $2); print $2}' | tr , '\n'
  echo "Dgraph Zero: Release[test], Namespace [dgraph-test-$TEST]:"
  echo "-------------------------------------------------------------"
  docker exec -it dgraph-certs dgraph cert ls --dir /dgraph_tls/dgraph-test-$TEST/zero | awk -F: '/Hosts/{gsub(/\[ ]+/, "", $2); print $2}' | tr , '\n'
  printf "\n"
done
```

## Run Tests

This will deploy a Dgraph cluster using different types of Dgraph configuration.  Use the `--environment $TEST` flag to select the desired test.  

The focus on these tests is to deploy Dgraph on Kubernetes, and verify that dgraph is running successful.

### Run Tests without persistence

```bash
TESTS="alpha-acl alpha-enc alpha-tls default-json default-yaml alpha-tls zero-tls"
for TEST in $TESTS; do helmfile --environment $TEST apply; done
```

### Run Tests with persistence

```bash
export DGRAPH_PERSISTENCE="true"
TESTS="alpha-tls alpha-acl alpha-enc alpha-tls default-json default-yaml zero-tls"
for TEST in $TESTS; do helmfile --environment $TEST apply; done
```

## Run Tests with Health Checks

```bash
export DGRAPH_HEALTHCHECK="true"
TESTS="alpha-tls alpha-acl alpha-enc alpha-tls default-json default-yaml zero-tls"
for TEST in $TESTS; do helmfile --environment $TEST apply; done
```

## Testing with TLS

### Verify TLS (no-mutual)

```bash
# set this for all tabs
NS="dgraph-test-alpha-tls"
# run the port forward command in a separate tab
kubectl port-forward --namespace $NS test-dgraph-alpha-0 8080:8080

curl --silent \
  --cacert ./dgraph_tls/$NS/alpha/ca.crt \
  https://localhost:8080/state | jq
```

### Verify Mutual TLS

```bash
# set this for all tabs
NS="dgraph-test-zero-tls"
# run port forward commands in separate tabs
kubectl port-forward --namespace $NS test-dgraph-alpha-0 8080:8080
kubectl port-forward --namespace $NS test-dgraph-zero-0 6080:6080

curl --silent \
  --cacert ./dgraph_tls/$NS/zero/ca.crt \
  --cert ./dgraph_tls/$NS/zero/client.dgraphuser.crt \
  --key ./dgraph_tls/$NS/zero/client.dgraphuser.key \
  https://localhost:6080/state | jq

curl --silent \
  --cacert ./dgraph_tls/$NS/alpha/ca.crt \
  --cert ./dgraph_tls/$NS/alpha/client.dgraphuser.crt \
  --key ./dgraph_tls/$NS/alpha/client.dgraphuser.key \
  https://localhost:8080/state | jq
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
