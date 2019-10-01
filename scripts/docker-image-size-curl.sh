#!/usr/bin/env bash

if [[ ! -z "${DEBUG}" ]]; then set -x; fi
GOARCH=${GOARCH-"amd64"}
GOOS=${GOOS-"linux"}
DOCKER_HUB_HOST=index.docker.io

set -o nounset -o pipefail
#Not setting "-o errexit", because script checks errors and returns custom error messages

# TODO library only on docker.io -> example: r.j3ss.co/reg@sha256:12f48bf43adaa05f14bef571ff8da213767410c2aaf1a1af7d7711848720cf295

function main() {

    checkArgs "$@"
    checkRequiredCommands curl jq sed awk paste bc

    url="$(determineUrl "${1}")"
    header="$(checkExtraHeaderNecessary "${url}")"

    response=$(queryManifest "${url}" "${header}")

    response=$(checkManifestList "${response}" "${url}" "${header}")
    sizes=$(echo ${response} | jq -e '.layers[].size' 2>/dev/null)

    if [[ "${?}" = "0" ]]; then
        echo "${1}:" $(createAndPrintSum "${sizes}")
    else
        fail "Response: ${response}"
    fi
}

function checkArgs() {

  if [[ $# < 1 ]]; then
    echo "Usage: $(basename "$0") NAME[:TAG|@DIGEST]"
    exit 1
  fi
}

function checkRequiredCommands() {
    missingCommands=""
    for currentCommand in "$@"
    do
        isInstalled "${currentCommand}" || missingCommands="${missingCommands} ${currentCommand}"
    done

    if [[ ! -z "${missingCommands}" ]]; then
        fail "Please install the following commands required by this script:${missingCommands}"
    fi
}

function isInstalled() {
    command -v "${1}" >/dev/null 2>&1 || return 1
}

function determineUrl() {

    HOST=""

    if [[ ! "${1}" == *"/"* ]]; then
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

function queryManifest() {
    url="${1}"
    header="${2}"
    # If trying to simplify this into a variable "-H $header" you enter quoting hell
    if [[ ! -z "${header}" ]]; then
        response=$(curl -sL -H "${header}" -H "Accept:application/vnd.docker.distribution.manifest.v2+json" "${url}")
    else
        response=$(curl -sL -H "Accept:application/vnd.docker.distribution.manifest.v2+json" "${url}")
    fi

    if [[ "${?}" != "0" ]] ||  [[ -z ${response} ]]; then fail "response empty"; fi
    echo "${response}"
}

function parseHost() {
    HOST="$(echo ${1} | sed 's@^\([^/]*\)/.*@\1@')"
    failIfEmpty ${HOST} "Unable to find repo Host in parameter: ${1}"
    echo "${HOST}"
}

function parseImage() {
    HOST="${2-}" # Might be empty
    if [[ ! -z "$HOST" ]]; then HOST="${HOST}/"; fi
    IMAGE=$(echo "${1}" | sed "s|^${HOST}\([^@:]*\):*.*|\1|")
    failIfEmpty ${IMAGE} "Unable to find image name in parameter: ${1}"
    echo ${IMAGE}
}

function parseTag() {
    IMAGE="${1}"
    echo "${2}" | sed "s|.*${IMAGE}[:@]*\(.*\)|\1|"
}

function checkExtraHeaderNecessary() {
    if [[ "${1}" == *"docker.com"* ]] || [[ "${1}" == *"docker.io"* ]]; then
      repo=$(parseRepo $1)
      token="$(curl -sSL "https://auth.docker.io/token?service=registry.docker.io&scope=repository:${repo}:pull" \
                | jq -e --raw-output .token)"
     echo -n "Authorization: Bearer ${token}"
    fi
}

function parseRepo() {
    echo "${1}" | sed 's/.*v2\/\(.*\)\/manifests.*/\1/'
}

function checkManifestList() {
  response="${1}"
  url="${2}"
  header="${3}"

  mediaType=$(echo ${response} | jq -er '.mediaType' 2>/dev/null)
  if [[ "${mediaType}" == "application/vnd.docker.distribution.manifest.list.v2+json" ]]; then
    newDigest=$(echo ${response} | jq -er  ".manifests[] | select(.platform.architecture == \"${GOARCH}\" and .platform.os == \"${GOOS}\") | .digest")
    if [[ "${?}" = "0" ]]; then
        newUrl="$(echo ${url} | sed 's|\(.*\)/.*$|\1|')/${newDigest}"
        response=$(queryManifest "${newUrl}" "${header}")
    else
      fail "Response: ${response}"
    fi
  fi
  echo "${response}"
}

function createAndPrintSum() {
    echo $(( ($(echo "${1}" | paste -sd+ | bc) + 500000) / 1000 / 1000)) MB
}

function failIfEmpty() {
    if [[ -z "${1}" ]]; then
        fail "${2}"
    fi
}

function fail() {
    error "$@"
    error Calculating size failed
    exit 1
}

function error() {
    echo "$@" 1>&2;
}

main "$@"
