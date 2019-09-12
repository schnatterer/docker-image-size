#!/usr/bin/env bash

function main() {
    header="$(checkExtraHeaderNecessary "${1}")"

    # If trying to simplify this into a variable "-H $header" you enter quoting hell
    if [[ ! -z "${header}" ]]; then
        RESPONSE=$(curl -sL -H "${header}" -H "Accept:application/vnd.docker.distribution.manifest.v2+json"  "${1}")
   else
        RESPONSE=$(curl -sL -H "Accept:application/vnd.docker.distribution.manifest.v2+json" "${1}")
    fi

    if [[ "${?}" != "0" ]] ||  [[ -z ${RESPONSE} ]]; then fail "response empty"; fi

    SIZES=$(echo ${RESPONSE} | jq '.layers[].size' )
    RET="$?"

    if [[ "${RET}" = "0" ]]; then
        echo $(( ($(echo "${SIZES}" | paste -sd+ | bc) + 500000) / 1000 / 1000)) MB
    else
        fail "Response: ${RESPONSE}"
    fi
}

function checkExtraHeaderNecessary() {
    if [[ "${1}" == *"docker.com"* ]] || [[ "${1}" == *"docker.io"* ]]; then
      repo=$(parseRepo $1)
      token="$(curl -sSL "https://auth.docker.io/token?service=registry.docker.io&scope=repository:${repo}:pull" \
                | jq --raw-output .token)"
     echo -n "Authorization: Bearer ${token}"
    fi
}

function parseRepo() {
    echo "${1}" | sed 's/.*v2\/\(.*\)\/manifests.*/\1/'
}

function fail() {
    echo ${1}
    echo Calcualating size failed
    exit 1
}

main "$@"
