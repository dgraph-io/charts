#!/usr/bin/env bash

[[ -d ./tls ]] || { echo "Directory './tls' does not exist! Exiting." 2>&1; exit 1; }

## Given directory ./tls creates a secrets.yaml for use with helm chart
## TLS Directory created with `dgraph cert` command, e.g.
##  `dgraph cert -n localhost -c dgraphuser`

cat <<-EOF > secrets.yaml
alpha:
  tls:
    files:
$(for F in ./tls/*; do echo "      ${F##*/}: `cat $F | base64 | tr -d '\n'`"; done)
EOF
