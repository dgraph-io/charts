#!/usr/bin/env bash
# dgraph post-install validator.
#
# Asserts the running dgraph cluster matches what the chart rendered, read
# from /config/expected.json. Runs in-cluster three ways: a `helm test` Pod, a
# post-install hook Job (gates the release), or the suspended manual CronJob
# (kubectl create job --from=cronjob/...).
#
# Transport is taken from env the pod template sets (mirrors the ACL bootstrap
# reconciler): plaintext by default, or HTTPS with the chart's CA and optional
# client cert under native TLS. The logical expected state comes from
# expected.json, which the chart templates from its own values, so the validator
# cannot drift from what was deployed.
#
# Checks: health, cluster membership, ACL enforcement, admin login, an
# authenticated query, per-user logins, group predicate rules, and (optionally)
# backup CronJob scheduling. When ACL is disabled, the login and auth-dependent
# checks are skipped. No `set -e`: each check aggregates into FAILURES so one
# failure still lets the rest report. Exit 0 = all pass; non-zero = a failure.
#
# check_* helpers are dispatched indirectly through retry()/run() (via "$@"),
# which shellcheck cannot trace; silence the false "never invoked" (SC2329) and
# "unreachable command" (SC2317) it infers for them.
# shellcheck disable=SC2329,SC2317
set -u

EXPECTED_JSON="${EXPECTED_JSON:-/config/expected.json}"
CREDS_DIR="${CREDS_DIR:-/creds}"
RETRIES="${RETRIES:-10}"
RETRY_SLEEP="${RETRY_SLEEP:-12}"
K8S_API="${K8S_API:-https://kubernetes.default.svc}"
SA_DIR="/var/run/secrets/kubernetes.io/serviceaccount"
: "${ALPHA_HOST:?ALPHA_HOST not set}"

# TLS: when the pod supplies a CA path (alpha.tls.enabled), talk HTTPS and present
# the client cert if one was provided. Empty CERTOPTS keeps plaintext. Mirrors the
# ACL bootstrap and backup CronJob curl handling.
SCHEME="http"
CERTOPTS=()
if [ -n "${CACERT_PATH:-}" ]; then
  SCHEME="https"
  CERTOPTS+=('--cacert' "${CACERT_PATH}")
  if [ -n "${CLIENT_CERT_PATH:-}" ] && [ -n "${CLIENT_KEY_PATH:-}" ]; then
    CERTOPTS+=('--cert' "${CLIENT_CERT_PATH}" '--key' "${CLIENT_KEY_PATH}")
  fi
fi
ALPHA="${SCHEME}://${ALPHA_HOST}:8080"

NS="$(jq -r '.namespace' "$EXPECTED_JSON")"
ACL_ENABLED="$(jq -r '.aclEnabled' "$EXPECTED_JSON")"

FAILURES=0
pass() { printf 'PASS %s\n' "$1"; }
fail() {
  printf 'FAIL %s\n' "$1"
  FAILURES=$((FAILURES + 1))
}
log() { printf '%s\n' "$1"; }

# Alpha-facing curl with the resolved TLS options applied.
curl_alpha() { /usr/bin/curl -fsS "${CERTOPTS[@]}" "$@"; }

# retry LABEL CMD... : run until exit 0 or RETRIES exhausted, logging each wait so
# a slow first deploy shows progress instead of going silent.
retry() {
  _label="$1"
  shift
  _i=1
  while true; do
    if "$@"; then return 0; fi
    [ "$_i" -ge "$RETRIES" ] && return 1
    log "$_label: not ready; retry $_i/$RETRIES in ${RETRY_SLEEP}s"
    _i=$((_i + 1))
    sleep "$RETRY_SLEEP"
  done
}

# login USER PASSWORD -> accessJWT on stdout, non-zero on failure. Credentials go
# in as GraphQL variables (jq --arg) so any generated password is injection-safe.
login() {
  _payload="$(jq -n --arg u "$1" --arg p "$2" \
    '{query:"mutation($u:String!,$p:String!){login(userId:$u,password:$p){response{accessJWT}}}",variables:{u:$u,p:$p}}')"
  _resp="$(curl_alpha -X POST "$ALPHA/admin" -H 'Content-Type: application/json' -d "$_payload")" || return 1
  _jwt="$(printf '%s' "$_resp" | jq -r '.data.login.response.accessJWT // empty')"
  [ -n "$_jwt" ] || return 1
  printf '%s' "$_jwt"
}

read_pw() {
  _f="$CREDS_DIR/$1"
  [ -f "$_f" ] || return 1
  cat "$_f"
}

# A. Health: /health is public; every instance must report "healthy".
check_health() {
  _h="$(curl_alpha "$ALPHA/health")" || return 1
  _total="$(printf '%s' "$_h" | jq 'length')"
  _ok="$(printf '%s' "$_h" | jq '[.[] | select(.status == "healthy")] | length')"
  [ "$_total" -gt 0 ] && [ "$_total" = "$_ok" ]
}

# Admin JWT underpins membership/query/groups; fetch with retry before they run.
ADMIN_JWT=""
# Admin auth header args, populated once we hold a JWT. Stays empty when ACL is
# disabled so we never send an empty X-Dgraph-AccessToken, which an auth proxy
# could treat as a failed auth attempt and reject.
AUTH_HDR=()
get_admin_jwt() {
  _u="$(jq -r '.adminUser' "$EXPECTED_JSON")"
  _k="$(jq -r '.adminPasswordKey' "$EXPECTED_JSON")"
  _pw="$(read_pw "$_k")" || return 1
  ADMIN_JWT="$(login "$_u" "$_pw")" || return 1
  [ -n "$ADMIN_JWT" ] || return 1
  AUTH_HDR=(-H "X-Dgraph-AccessToken: $ADMIN_JWT")
}

# B. Membership: counted Alphas/Zeros in /state match expected. As a
# post-install/upgrade gate this compares against the just-rendered replicaCount,
# so counts match. Note: the zeros count assumes /state lists only live members;
# if a decommissioned zero lingered in /state after a scale-down it would
# over-count and FAIL. Not a concern for the install/upgrade gate, but a manual
# CronJob run after a scale-down could surface it.
check_membership() {
  _state="$(curl_alpha "$ALPHA/state" "${AUTH_HDR[@]}")" || return 1
  _a="$(printf '%s' "$_state" | jq '[.groups[].members | length] | add // 0')"
  _z="$(printf '%s' "$_state" | jq '(.zeros // {}) | length')"
  [ "$_a" = "$(jq -r '.expectedAlphas' "$EXPECTED_JSON")" ] &&
    [ "$_z" = "$(jq -r '.expectedZeros' "$EXPECTED_JSON")" ]
}

# C. ACL enforcing: an unauthenticated admin query is rejected. Rejection can be
# a GraphQL 200 with a non-empty errors[] (current Dgraph) OR an HTTP 401/403
# (an auth proxy or a future Dgraph version). Deliberately not
# curl_alpha here: its -f turns a 4xx rejection into a non-zero exit that would
# read as "not enforcing" — exactly backwards. Assert on the status/body instead.
check_acl_enforcing() {
  _out="$(/usr/bin/curl -sS -w '\n%{http_code}' "${CERTOPTS[@]}" \
    -X POST "$ALPHA/admin" -H 'Content-Type: application/json' \
    -d '{"query":"{ queryGroup { name } }"}')" || return 1
  _code="${_out##*$'\n'}"
  _body="${_out%$'\n'*}"
  # A 401/403 is an explicit rejection => enforcing.
  case "$_code" in 401 | 403) return 0 ;; esac
  # A 200 counts only if the GraphQL response carries a non-empty errors[].
  [ "$_code" = "200" ] &&
    [ "$(printf '%s' "$_body" | jq -r '(.errors // []) | length' 2>/dev/null || echo 0)" -gt 0 ]
}

# D. Authenticated query: a DQL schema read through the auth path returns data.
check_query() {
  _resp="$(curl_alpha -X POST "$ALPHA/query" \
    -H 'Content-Type: application/dql' \
    "${AUTH_HDR[@]}" \
    --data-binary 'schema {}')" || return 1
  printf '%s' "$_resp" | jq -e '.data' >/dev/null 2>&1
}

# E. Per-user login: every declared account logs in with its stored password.
check_user_logins() {
  _rc=0
  _n="$(jq -r '.users | length' "$EXPECTED_JSON")"
  _i=0
  while [ "$_i" -lt "$_n" ]; do
    _u="$(jq -r ".users[$_i].name" "$EXPECTED_JSON")"
    _k="$(jq -r ".users[$_i].passwordKey" "$EXPECTED_JSON")"
    _i=$((_i + 1))
    _pw="$(read_pw "$_k")" || {
      fail "user-login: $_u (no password key $_k)"
      _rc=1
      continue
    }
    if login "$_u" "$_pw" >/dev/null; then
      pass "user-login: $_u"
    else
      fail "user-login: $_u"
      _rc=1
    fi
  done
  return "$_rc"
}

# F. Groups + rules: each expected group exists AND carries every expected
# predicate rule (matching predicate and permission).
check_groups() {
  _ng="$(jq -r '.groups | length' "$EXPECTED_JSON")"
  [ "$_ng" -eq 0 ] && return 0
  _resp="$(curl_alpha -X POST "$ALPHA/admin" -H 'Content-Type: application/json' \
    "${AUTH_HDR[@]}" \
    -d '{"query":"{ queryGroup { name rules { predicate permission } } }"}')" || return 1
  _rc=0
  _i=0
  while [ "$_i" -lt "$_ng" ]; do
    _g="$(jq -r ".groups[$_i].name" "$EXPECTED_JSON")"
    _exp_rules="$(jq -c ".groups[$_i].rules // []" "$EXPECTED_JSON")"
    _i=$((_i + 1))
    _present="$(printf '%s' "$_resp" | jq --arg g "$_g" '[.data.queryGroup[] | select(.name == $g)] | length')"
    if [ "${_present:-0}" -lt 1 ]; then
      fail "group: $_g (absent)"
      _rc=1
      continue
    fi
    _act_rules="$(printf '%s' "$_resp" | jq -c --arg g "$_g" '([.data.queryGroup[] | select(.name == $g)][0].rules) // []')"
    _missing="$(jq -n --argjson e "$_exp_rules" --argjson a "$_act_rules" \
      '[$e[] | . as $r | select(($a | any(.predicate == $r.predicate and .permission == $r.permission)) | not)] | length')"
    if [ "${_missing:-0}" -eq 0 ]; then
      pass "group: $_g (rules ok)"
    else
      fail "group: $_g ($_missing expected rule(s) missing)"
      _rc=1
    fi
  done
  return "$_rc"
}

# G. Backups: each expected backup CronJob exists with the expected schedule.
# Reads the Kubernetes API with the pod's ServiceAccount token (requires the
# validation RBAC). Only runs when expected.json marks backups.check true.
check_backups() {
  _token="$(cat "$SA_DIR/token")"
  _n="$(jq -r '.backups.cronjobs | length' "$EXPECTED_JSON")"
  _rc=0
  _i=0
  while [ "$_i" -lt "$_n" ]; do
    _name="$(jq -r ".backups.cronjobs[$_i].name" "$EXPECTED_JSON")"
    _sched="$(jq -r ".backups.cronjobs[$_i].schedule" "$EXPECTED_JSON")"
    _i=$((_i + 1))
    _cj="$(/usr/bin/curl -fsS --cacert "$SA_DIR/ca.crt" -H "Authorization: Bearer $_token" \
      "$K8S_API/apis/batch/v1/namespaces/$NS/cronjobs/$_name")" || {
      fail "backup-cronjob: $_name (absent)"
      _rc=1
      continue
    }
    _got="$(printf '%s' "$_cj" | jq -r '.spec.schedule')"
    if [ "$_got" = "$_sched" ]; then
      pass "backup-cronjob: $_name ($_got)"
    else
      fail "backup-cronjob: $_name ($_got != $_sched)"
      _rc=1
    fi
  done
  return "$_rc"
}

run() {
  _name="$1"
  shift
  if retry "$_name" "$@"; then pass "$_name"; else fail "$_name"; fi
}

# run_reported LABEL FN...: retry wrapper for checks that emit their own per-item
# PASS/FAIL and increment FAILURES (check_user_logins, check_groups,
# check_backups). Bare, these get one shot and can FAIL on a still-propagating
# ACL rule or a not-yet-visible CronJob while the run()-wrapped checks above them
# would retry past the same window. Probe quietly in a subshell (its FAILURES
# increments and output are discarded) until it passes or attempts run out, then
# run once authoritatively so per-item detail and the failure count land exactly
# once.
run_reported() {
  _name="$1"
  shift
  _i=1
  while [ "$_i" -lt "$RETRIES" ]; do
    if ("$@") >/dev/null 2>&1; then break; fi
    log "$_name: not ready; retry $_i/$RETRIES in ${RETRY_SLEEP}s"
    _i=$((_i + 1))
    sleep "$RETRY_SLEEP"
  done
  "$@"
}

log "dgraph validator -> $ALPHA (ns=$NS, aclEnabled=$ACL_ENABLED); up to $RETRIES x ${RETRY_SLEEP}s per check"
run "health" check_health

if [ "$ACL_ENABLED" = "true" ]; then
  if retry "admin-login" get_admin_jwt; then pass "admin-login"; else fail "admin-login"; fi
  run "acl-enforcing" check_acl_enforcing
  run "membership" check_membership
  run "query" check_query
  run_reported "user-logins" check_user_logins
  run_reported "groups" check_groups
else
  log "ACL disabled (expected.json aclEnabled != true); skipping login, ACL-enforcement, user-login, and group checks"
  run "membership" check_membership
  run "query" check_query
fi

if [ "$(jq -r '.backups.check' "$EXPECTED_JSON")" = "true" ]; then
  run_reported "backups" check_backups
fi

echo "----"
if [ "$FAILURES" -eq 0 ]; then
  echo "dgraph validation: PASS"
  exit 0
fi
echo "dgraph validation: FAIL ($FAILURES check(s))"
exit 1
