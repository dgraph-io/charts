# Dgraph Mutual TLS

This example demonstrates how to use TLS and MutualTLS for internal communications with Dgraph Alpha and starting with Dgraph `v20.11.0`, Dgraph Zero as well.

## Instructions

### Prerequisites

On the deploy workstation, that is, the system you will use to create certificates and deploy the helm charts, you will need the `dgraph` binary.  You can get this with:

```bash
## Install Dgraph
curl -sSf https://get.dgraph.io | bash
## Verify Version installed
dgraph version | awk -F: '/Dgraph version/{print $2}'
```

### Generate Certificates and Keys

First you need to generate certificates and keys for Dgraph Alpha service and Dgraph Zero service.  There's a script that can help automate creating certificates and keys, as well as a helm value `secrets.yaml` that can be use for the helm chart.  See [README.md](../../charts/dgraph/scripts/README.md).

You can run this locally with:

```bash
ln --symbolic ../../charts/dgraph/scripts/make_tls_secrets.sh make_tls_secrets.sh
## ./make_tls_secrets.sh --help for more information
./make_tls_secrets.sh \
  --release "my-release" \
  --client "dgraphuser" \
  --zero \
  --tls_dir ./examples/dgraph_tls

## Verify Dgraph Alpha Keys and Certificates
dgraph cert ls --dir ./examples/dgraph_tls/alpha
## Verify Dgraph Zero Keys and Certificates
dgraph cert ls --dir ./examples/dgraph_tls/zero
```

### Choose Client Authentication Method

With Dgraph TLS support, you can choose the type of authentication, such as whether MutualTLS is optional or explicitly required.  For more information see [Client Authentication Options](https://dgraph.io/docs/deploy/tls-configuration/#client-authentication-options).

You can set this value using the environment variable `TLS_CLIENT_AUTH` for use with helmfile.  If this enviroment variable is not set, the default configuration will be `VERIFYIFGIVEN`. As an example:

```bash
export TLS_CLIENT_AUTH=REQUIREANDVERIFY
```

### Install dgraph with TLS

For TLS support with Dgraph Alpha for external ports, the `alpha_tls` environment:

```bash
helmfile --environment "alpha_tls" apply
```

For securing internal and external ports on both Dgraph Zero and Dgraph Alpha (Dgraph `v20.11.0` or greater), the `zero_tls_internal` environment can be used:

```bash
helmfile --environment "zero_tls_internal" apply
```

## Testing

Here are some examples that can be use to test TLS and MutualTLS with client authentication.

### Testing Dgraph Alpha (TLS without client auth)

The Dgraph Alpha service will be configured with either `REQUEST` or `VERIFYIFGIVEN` (default) for the TLS client authentication method.


Use port forwarding for Dgraph Alpha HTTPS to make it available on localhost using another terminal tab:

```bash
kubectl port-forward my-release-dgraph-alpha-0 8080:8080
```

Now test against `localhost` using `curl`:

```bash
curl --silent \
  --cacert ./examples/dgraph_tls/alpha/ca.crt \
  https://localhost:8080/state | jq
```

Use port forwarding for Dgraph Alpha GRPC to make it available on localhost using another terminal tab:

```bash
kubectl port-forward my-release-dgraph-alpha-0 9080:9080
```

Now test against `localhost` using `dgraph increment`:

```bash
dgraph increment \
 --tls_cacert ./examples/dgraph_tls/alpha/ca.crt \
 --tls_server_name localhost \
 --alpha localhost:9080
```

### Testing Dgraph Alpha (mTLS with client auth)

The Dgraph Alpha service will be configured with either `REQUIREANY` or `REQUIREANDVERIFY` for the TLS client authentication method.

Use port forwarding for Dgraph Alpha HTTPS to make it available on localhost using another terminal tab:

```bash
kubectl port-forward my-release-dgraph-alpha-0 8080:8080
```

Now test against `localhost` using `curl`:

```bash
curl --silent \
  --cacert ./examples/dgraph_tls/alpha/ca.crt \
  --cert ./examples/dgraph_tls/alpha/client.dgraphuser.crt \
  --key ./examples/dgraph_tls/alpha/client.dgraphuser.key \
  https://localhost:8080/state | jq
```

Use port forwarding for Dgraph Alpha GRPC to make it available on localhost using another terminal tab:

```bash
kubectl port-forward my-release-dgraph-alpha-0 9080:9080
```

Now test against `localhost` using `dgraph increment`:

```bash
dgraph increment \
 --tls_cacert ./examples/dgraph_tls/alpha/ca.crt \
 --tls_cert ./examples/dgraph_tls/alpha/client.dgraphuser.crt \
 --tls_key ./examples/dgraph_tls/alpha/client.dgraphuser.key \
 --tls_server_name localhost \
 --alpha localhost:9080
```

### Testing Dgraph Zero (mTLS with client auth)

The Dgraph Zero service will be configured with either `REQUIREANY` or `REQUIREANDVERIFY` for the TLS client authentication method.

Use port forwarding for Dgraph Zero HTTPS to make it available on localhost using another terminal tab:

```bash
kubectl port-forward my-release-dgraph-zero-0 6080:6080
```

Now test against `localhost` using `curl`:

```bash
curl --silent \
  --cacert ./examples/dgraph_tls/zero/ca.crt \
  --cert ./examples/dgraph_tls/zero/client.dgraphuser.crt \
  --key ./examples/dgraph_tls/zero/client.dgraphuser.key \
  https://localhost:6080/state | jq
```
