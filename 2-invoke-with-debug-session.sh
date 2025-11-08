#!/bin/bash
# -*- mode:shell-script; coding:utf-8; sh-shell:bash -*-

apigee=https://apigee.googleapis.com

source ./lib/utils.sh

check_proxy_existence() {
  local org api env
  org="$1"
  api="$2"

  CURL -X GET $apigee/v1/organizations/$org/apis/$api

  [[ $CURL_RC -eq 200 ]]
}

inquire_latest_rev() {
  local org api env
  org="$1"
  env="$2"
  api="$3"

  CURL -X GET \
    $apigee/v1/organizations/$org/environments/$env/apis/$api/deployments

  REV=$(jq -r '[.deployments[].revision | tonumber] | max' "$CURL_OUT")
}

create_debug_session() {
  local org env api rev
  org="$1"
  env="$2"
  api="$3"
  rev="$4"
  # https://cloud.google.com/apigee/docs/reference/apis/apigee/rest/v1/organizations.environments.apis.revisions.debugsessions/create
  CURL -X POST $apigee/v1/organizations/$org/environments/$env/apis/$api/revisions/$rev/debugsessions \
    -H "content-type: application/json" \
    -d '{  "timeout": "600" }' ## no filter
  #  "filter": "response.status.code = 502",

  # here, set the session ID into a variable, so later the caller can use it.
  SESSION=$(jq -r '.name' "$CURL_OUT")
}

# # get debug sessions for an {api,revision,environment} tuple
# :api = jsonthreattest
# :rev = 2
# :env = default-dev
#
# GET :apigee/v1/organizations/:org/environments/:env/apis/:api/revisions/:rev/debugsessions
# Authorization: Bearer :token

get_debug_session_transaction() {
  local org api env rev sessionid i
  org="$1"
  env="$2"
  api="$3"
  rev="$4"
  sessionid="$5"

  TRANSACTION=""
  for i in {1..6}; do
    printf "\nWaiting a bit for the debug session collection....\n"
    sleep 5

    CURL -X GET $apigee/v1/organizations/$org/environments/$env/apis/$api/revisions/$rev/debugsessions/$sessionid/data

    if [[ $(jq 'length' "$CURL_OUT") -gt 0 ]]; then
      TRANSACTION=$(jq -r '.[0]' "$CURL_OUT")
      break
    fi
  done
}

get_one_transaction() {
  local org api env rev sessionid transactionid
  org="$1"
  env="$2"
  api="$3"
  rev="$4"
  sessionid="$5"
  transactionid="$6"

  CURL -X GET $apigee/v1/organizations/$org/environments/$env/apis/$api/revisions/$rev/debugsessions/$sessionid/data/$transactionid

  cat $CURL_OUT
}

# ========================================================

check_shell_variables APIGEE_ORG APIGEE_ENV PROXY APIGEE_ENDPOINT
check_required_commands jq mktemp gcloud curl

# The TOKEN is implicitly used by subsequent calls to the CURL function.
TOKEN=$(gcloud auth print-access-token)

printf "\nChecking for existence of API %s ...\n" "$PROXY"
if ! check_proxy_existence $APIGEE_ORG $PROXY; then
  printf "The proxy %s does not exist in org=%s ...\n" "$PROXY" "$APIGEE_ORG"
  printf "Cannot continue.\n\n"
  exit 1
fi

# Sets REV by side effect

printf "\nGetting deployments of API %s ...\n" "$PROXY"
inquire_latest_rev $APIGEE_ORG $APIGEE_ENV $PROXY
# Sets REV by side effect

printf "\nCreating a Debug session for that proxy....\n"
create_debug_session $APIGEE_ORG $APIGEE_ENV $PROXY $REV
# Sets SESSION by side effect

printf "\nThe debug session id is %s ...\n" "$SESSION"


# I do not know a "closed loop" way of determining if the
# DebugSession is "ready" and listening.
printf "\nWaiting a bit for the debug session creation....\n"
sleep 12

# Invoke a request:
printf "\nInvoking the proxy wth no authentication... This will result in a 401...\n"
basepath=$PROXY
NO_TOKEN=1
CURL -X GET $APIGEE_ENDPOINT/$basepath/urlpath
cat $CURL_OUT
NO_TOKEN=0

printf "\nGetting Debug session info...\n"
get_debug_session_transaction $APIGEE_ORG $APIGEE_ENV $PROXY $REV $SESSION
# Sets TRANSACTION by side effect

if [[ -z "$TRANSACTION" ]]; then
  printf "\nDid not receive a transaction from the debug session. Exiting.\n"
  exit 1
fi
printf "\nThe transaction id is %s ...\n" "$TRANSACTION"

printf "\nGetting info for that transaction...\n"
get_one_transaction $APIGEE_ORG $APIGEE_ENV $PROXY $REV $SESSION $TRANSACTION

printf "\nAt this point, we could examine the debug session and evaluate assertions......\n\n"
