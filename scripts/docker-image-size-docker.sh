#!/usr/bin/env bash

if [[ ! -z "${DEBUG}" ]]; then set -x; fi

set -o errexit -o nounset -o pipefail

export DOCKER_CLI_EXPERIMENTAL=enabled

function main() {

    checkRequiredCommands docker jq

    echo $(( ( $(docker manifest inspect -v ${1} \
        | jq '.[] | select(.Descriptor.platform.architecture == "amd64").SchemaV2Manifest.layers[0].size') \
               + 500000) \
             / 1000 \
             / 1000)) MB
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

main "$@"