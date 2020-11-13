#!/usr/bin/env bash

main() {
  RELEASE=${1:-"my-release"}
  TLS_PATH=${2:-'./tls'}

  ALPHA_LIST=$(TYPE=alpha get_node_list)
  ZERO_LIST=$(TYPE=zero get_node_list)

  create_certificates
  create_secret_value_file

}

create_certificates() {
  ## Make Keys/Certs
  mkdir -p tls/{zero,alpha}
  dgraph cert --nodes localhost,$ALPHA_LIST --client internaluser --dir tls/alpha
  ## Copy Root CA to zero
  cp tls/alpha/ca.* tls/zero
  ## Copy Internal Client Cert/Key to zero
  cp tls/alpha/client.internaluser.* tls/zero
  ## Make Zero Keys/Cert
  dgraph cert --nodes localhost,$ZERO_LIST --dir tls/zero
}

create_secret_value_file() {
    cat <<-EOF > ./tls/secrets.yaml
alpha:
  tls:
    files:
$(for F in ./tls/alpha/*; do echo "      ${F##*/}: `cat $F | base64 | tr -d '\n'`"; done)
EOF
  cat <<-EOF >> ./tls/secrets.yaml
zero:
  tls:
    files:
$(for F in ./tls/zero/*; do echo "      ${F##*/}: `cat $F | base64 | tr -d '\n'`"; done)
EOF

}

get_node_list() {
  local LIST=()

  TYPE=${TYPE:-"alpha"}
  ## No of replicas in Alpha statefulset
  REPLICAS=${REPLICAS:-"3"}
  ## helm release name
  RELEASE=${RELEASE:-"my-release"}
  ## namespace used during deployment
  NAMESPACE=${NAMESPACE:-"default"}
  ## domain name is required
  DOMAIN=${DOMAIN:-'cluster.local'}


  ## Build List
  for (( IDX=0; IDX<REPLICAS; IDX++ )); do
    LIST+=("$RELEASE-dgraph-$TYPE-$IDX.$RELEASE-dgraph-$TYPE-headless.$NAMESPACE.svc.$DOMAIN")
  done

  ## Output Comma Separated List
  local IFS=,; echo "${LIST[*]}"
}

main $@
