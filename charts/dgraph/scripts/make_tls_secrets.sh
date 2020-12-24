#!/usr/bin/env bash



######
# main - runs the script
##########################
main() {
  parse_command $@
  create_certs
}

######
# usage - print friendly usage statement
##########################
usage() {
  cat <<-USAGE 1>&2
Make TLS Secrets

Usage:
  $0 [FLAGS] --release [CHART_RELEASE_NAME]

Flags:
 -c, --client              Client certificate username, e.g. dgraphuser, backupuser
     --domain              Kubernetes internal domain name (default "cluster.local")
 -d, --debug               Enable debug in output
 -e, --extra               Additional domain names to support, e.g. external DNS name for an ingress
 -h, --help                Help for $0
 -n, --namespace           Kubernetes namespace (default "default")
 -r, --release             Helm Chart Release Name (required)
     --replicas            Number of Kubernetes replicas (default "3")
     --tls_dir             Path to top level TLS directory (default "./dgraph_tls")
 -z, --zero                Create certificates for zero as well
USAGE
}

######
# get_getopt - find GNU getopt or print error message
##########################
get_getopt() {
 unset GETOPT_CMD

 ## Check for GNU getopt compatibility
 if [[ "$(getopt --version)" =~ "--" ]]; then
   local SYSTEM="$(uname -s)"
   if [[ "${SYSTEM,,}" == "freebsd" ]]; then
     ## Check FreeBSD install location
     if [[ -f "/usr/local/bin/getopt" ]]; then
        GETOPT_CMD="/usr/local/bin/getopt"
     else
       ## Save FreeBSD Instructions
       local MESSAGE="On FreeBSD, compatible getopt can be installed with 'sudo pkg install getopt'"
     fi
   elif [[ "${SYSTEM,,}" == "darwin" ]]; then
     ## Check HomeBrew install location
     if [[ -f "/usr/local/opt/gnu-getopt/bin/getopt" ]]; then
        GETOPT_CMD="/usr/local/opt/gnu-getopt/bin/getopt"
     ## Check MacPorts install location
     elif [[ -f "/opt/local/bin/getopt" ]]; then
        GETOPT_CMD="/opt/local/bin/getopt"
     else
        ## Save MacPorts or HomeBrew Instructions
        if command -v brew > /dev/null; then
          local MESSAGE="On macOS, gnu-getopt can be installed with 'brew install gnu-getopt'\n"
        elif command -v port > /dev/null; then
          local MESSAGE="On macOS, getopt can be installed with 'sudo port install getopt'\n"
        fi
     fi
   fi
 else
   GETOPT_CMD="$(command -v getopt)"
 fi

 ## Error if no suitable getopt command found
 if [[ -z $GETOPT_CMD ]]; then
   printf "ERROR: GNU getopt not found.  Please install GNU compatible 'getopt'\n\n%s" "$MESSAGE" 1>&2
   exit 1
 fi
}


######
# parse_command - parse command line options using GNU getopt
##########################
parse_command() {
  get_getopt

  ## Parse Arguments with GNU getopt
  PARSED_ARGUMENTS=$(
    $GETOPT_CMD -o c:de:hn:r:z \
    --long client:,domain:,debug,extra:,help,namespace:,release:,replicas:,tls_dir:,zero \
    -n 'make_tls_secrets.sh' -- "$@"
  )
  if [ $? != 0 ] ; then usage; exit 1 ; fi
  eval set -- "$PARSED_ARGUMENTS"

  ## Defaults
  DEBUG="false"
  ZERO_ENABLED="false"
  NAMESPACE="default"
  REPLICAS=3
  TLS_DIR=dgraph_tls
  LOCAL_DOMAIN="cluster.local"

  ## Process Arguments
  while true; do
    case "$1" in
      -c | --client) CLIENT_NAME="$2"; shift 2 ;;
      --domain) LOCAL_DOMAIN="$2"; shift 2 ;;
      -d | --debug) DEBUG=true; shift ;;
      -e | --extra) EXTRA_ADDRESSES="$2"; shift 2 ;;
      -h | --help) usage; exit;;
      -n | --namespace) NAMESPACE="$2"; shift 2 ;;
      -r | --release) RELEASE="$2"; shift 2 ;;
      --replicas) REPLICAS="$2"; shift 2;;
      --tls_dir) TLS_DIR="$2"; shift 2 ;;
      -z | --zero) ZERO_ENABLED=true; shift ;;
      --) shift; break ;;
      *) break ;;
    esac
  done

  ## Check required variable was set
  if [[ -z "$RELEASE" ]]; then
    printf "ERROR: Helm chart release name was not specified!!\n\n"
    usage
    exit 1
  fi
}

######
# create_certs - create TLS certs/keys for Alpha and optionally Zero for K8S system
##########################
create_certs() {
  if [[ $DEBUG == "true" ]]; then
    set -ex
  else
    set -e
  fi

  echo "ZERO_ENABLED=$ZERO_ENABLED"
  echo "NAMESPACE=$NAMESPACE"
  echo "REPLICAS=$REPLICAS"
  echo "RELEASE=$RELEASE"
  echo "TLS_DIR=$TLS_DIR"
  echo "ZERO_ENABLED=$ZERO_ENABLED"
  echo "LOCAL_DOMAIN=$LOCAL_DOMAIN"
  echo "EXTRA_ADDRESSES=$EXTRA_ADDRESSES"

}


main $@
