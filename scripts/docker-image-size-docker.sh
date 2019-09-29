#!/usr/bin/env bash

if [[ ! -z "${DEBUG}" ]]; then set -x; fi

set -o nounset -o pipefail
#Not setting "-o errexit", because script checks errors and returns custom error messages

export DOCKER_CLI_EXPERIMENTAL=enabled

function main() {

    checkRequiredCommands docker jq

    sizes=$(docker manifest inspect -v ${1} \
        | jq -e '.[] | select(.Descriptor.platform.architecture == "amd64").SchemaV2Manifest.layers[0].size' 2>/dev/null)

    if [[ "${?}" = "0" ]]; then
        echo $(( ($(echo "${sizes}") + 500000) / 1000 / 1000)) MB
    else
        fail "Calling docker manifest failed"
    fi
}

function checkRequiredCommands() {
    missingCommands=""
    for currentCommand in "$@"
    do
        command -v "${currentCommand}" >/dev/null 2>&1 || missingCommands="${missingCommands} ${currentCommand}"
    done

    if [[ ! -z "${missingCommands}" ]]; then
        fail "Please install the following commands required by this script:${missingCommands}"
    fi
}

function isInstalled() {
    command -v "${1}" >/dev/null 2>&1 || return 1
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