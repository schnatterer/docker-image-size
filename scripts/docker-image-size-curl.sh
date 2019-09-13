#!/usr/bin/env bash
set -o nounset -o pipefail
#Not setting "-o errexit", because script checks errors and returns custom error messages

# TODO
#library/debian@sha256:2a10487719ac6ad15d02d832a8f43bafa9562be7ddc8f8bd710098aa54560cc2

function main() {
    url="$(determineUrl "${1}")"
    header="$(checkExtraHeaderNecessary "${url}")"

    # TODO this might be simplfied when integrated into determineUrl
    # If trying to simplify this into a variable "-H $header" you enter quoting hell
    if [[ ! -z "${header}" ]]; then
        RESPONSE=$(curl -sL -H "${header}" -H "Accept:application/vnd.docker.distribution.manifest.v2+json" "${url}")
    else
        RESPONSE=$(curl -sL -H "Accept:application/vnd.docker.distribution.manifest.v2+json" "${url}")
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

function determineUrl() {

    HOST=""
    nSlashes="$(countSlashes "${1}")"

    if [[ "${nSlashes}" == "0" ]]; then
        EFFECTIVE_HOST=${DOCKER_HUB_HOST}
    else
        HOST="$(parseHost ${1})"
        if [[ "${HOST}" == "docker.io" ]]; then
          EFFECTIVE_HOST=${DOCKER_HUB_HOST}
        else
            if [[ ! "${HOST}" == *"."* ]]; then
                EFFECTIVE_HOST=${DOCKER_HUB_HOST}
                # First part was no host
                HOST=""
            fi
        fi
    fi

    IMAGE="$(parseImage ${1} ${HOST})"
    if [[ ! "${IMAGE}" == *"/"* ]]; then
        EFFECTIVE_IMAGE="library/${IMAGE}"
    fi

    TAG="$(parseTag ${IMAGE} ${1})"
    if [[ -z "${TAG}" ]]; then
        TAG="latest"
    fi

    echo "https://${EFFECTIVE_HOST:-$HOST}/v2/${EFFECTIVE_IMAGE:-$IMAGE}/manifests/${TAG}"
}

function countSlashes() {
    echo awk -F"/" '{print NF-1}' <<< "${1}"
}

function parseHost() {
    HOST="$(echo ${1} | sed 's@^\([^/]*\)/.*@\1@')"
    failIfEmpty ${HOST} "Unable to find repo Host in parameter: ${1}"
    echo "${HOST}"
}

function parseImage() {
    HOST="${2-}" # Might be empty
    if [[ ! -z "$HOST" ]]; then HOST="${HOST}/"; fi
    IMAGE=$(echo "${1}" | sed "s@^${HOST}\([^:]*\):*.*@\1@")
    failIfEmpty ${IMAGE} "Unable to find image name in parameter: ${1}"
    echo ${IMAGE}
}

function parseTag() {
    IMAGE="${1}"
    echo "${2}" | sed "s@.*${IMAGE}:*\(.*\)@\1@"
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

function failIfEmpty() {
    if [[ -z "${1}" ]]; then
        fail "${2}"
    fi
}

function fail() {
    echo ${1}
    echo Calcualating size failed
    exit 1
}

DOCKER_HUB_HOST=registry.hub.docker.com

main "$@"
