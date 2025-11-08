#!/bin/bash
# -*- mode:shell-script; coding:utf-8; sh-shell:bash -*-

# Copyright © 2025 Google LLC.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

source ./lib/utils.sh
# ========================================================

check_shell_variables APIGEE_ORG APIGEE_ENV PROXY APIGEE_ENDPOINT
check_required_commands jq mktemp gcloud curl

if [[ ! -f "$HOME/.apigeecli/bin/apigeecli" ]]; then
    printf "\nInstalling apigeecli...\n"
    curl -s https://raw.githubusercontent.com/apigee/apigeecli/main/downloadLatest.sh | bash
fi


export PATH=$PATH:$HOME/.apigeecli/bin

# The TOKEN is needed for subsequent calls
TOKEN=$(gcloud auth print-access-token)

printf "Importing and Deploying the proxy...\n"
REV=$(apigeecli apis create bundle -f ./apis/apiproxy -n "$PROXY" --org "$APIGEE_ORG" --token "$TOKEN" --disable-check | jq ."revision" -r)
apigeecli apis deploy --wait --name "$PROXY" --ovr --rev "$REV" --org "$APIGEE_ORG" --env "$APIGEE_ENV" --token "$TOKEN"

printf "\nOK.\n\n"

