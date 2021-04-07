

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