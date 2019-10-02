#!/usr/bin/env bash

if [[ ! -z "${DEBUG}" ]]; then set -x; fi
GOARCH=${GOARCH-"amd64"}
GOOS=${GOOS-"linux"}
DOCKER_HUB_HOST=index.docker.io
NAME="${1}"
set -o nounset -o pipefail
#Not setting "-o errexit", because script checks errors and returns custom error messages

function main() {

    checkArgs "$@"
    checkRequiredCommands curl jq sed awk paste bc

    url="$(determineUrl "${1}")"
    response=$(queryManifest "${url}")
    if [[ "${?}" != "0" ]]; then exit 1; fi

    response=$(checkManifestList "${response}" "${url}")
    sizes=$(echo ${response} | jq -e '.layers[].size' 2>/dev/null)

    if [[ "${?}" = "0" ]]; then
        echo "${1}:" $(createAndPrintSum "${sizes}")
    else
        fail "Response: ${response}"
    fi
}

function checkArgs() {

  if [[ $# != 1 ]]; then
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
    EFFECTIVE_HOST=${HOST}

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
    if [[ ! "${IMAGE}" == *"/"* ]] && [[ ${EFFECTIVE_HOST} == ${DOCKER_HUB_HOST} ]]; then
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
    response=$(curl -sLi -H "Accept:application/vnd.docker.distribution.manifest.v2+json" "${url}")
    httpResponseCode=$(echo "${response}" | head -n 1 | cut -d$' ' -f2)
    header=""

    if [[ "${httpResponseCode}" == "401" ]]; then
      # e.g. Www-Authenticate: Bearer realm="https://auth.docker.io/token",service="registry.docker.io",scope="repository:library/debian:pull"
      # to: https://auth.docker.io/token?service=registry.docker.io&scope=repository:library/debian:pull
      # e.g. www-authenticate: Bearer realm="https://r.j3ss.co/auth",service="Docker registry",scope="repository:reg:pull"
      # to https://r.j3ss.co/auth?service=Docker%20registry&scope=repository:reg:pull'
      # URL encode any blanks such as service="Docker registry"
      # Remove all remaining spaces at the end to avoid quoting issues
      authUrl=$(echo "${response}" | grep -i www-Authenticate \
                | sed 's|.*Bearer realm="\(.*\)"|\1|' | sed 's|",service|?service|' | sed 's|",scope|\&scope|' | tr -d '"' \
                | sed 's| |%20|' |  tr -d '[:space:]' )
      token="$(curl -sSL "${authUrl}" | jq -e --raw-output .token)"
      header="Authorization: Bearer ${token}"
    elif [[ "${httpResponseCode}" == "200" ]]; then
      response=$(echo ${response} | awk 'END{print}')
    else
      fail "Request failed. Response: ${response}"
      echo "after fail"
    fi

    # If trying to simplify this into a variable "-H $header" you enter quoting hell
    if [[ -z "${header}" ]]; then
        response=$(curl -sL -H "Accept:application/vnd.docker.distribution.manifest.v2+json" "${url}")
    else
        response=$(curl -sL -H "${header}" -H "Accept:application/vnd.docker.distribution.manifest.v2+json" "${url}")
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

function checkManifestList() {
  response="${1}"
  url="${2}"

  mediaType=$(echo ${response} | jq -er '.mediaType' 2>/dev/null)
  if [[ "${mediaType}" == "application/vnd.docker.distribution.manifest.list.v2+json" ]]; then
    newDigest=$(echo ${response} | jq -er  ".manifests[] | select(.platform.architecture == \"${GOARCH}\" and .platform.os == \"${GOOS}\") | .digest")
    if [[ "${?}" = "0" ]]; then
        newUrl="$(echo ${url} | sed 's|\(.*\)/.*$|\1|')/${newDigest}"
        response=$(queryManifest "${newUrl}")
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
    error Calculating size failed for ${NAME}
    exit 1
}

function error() {
    echo "$@" 1>&2;
}

main "$@"
