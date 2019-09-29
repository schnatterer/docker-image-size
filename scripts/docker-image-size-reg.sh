#!/usr/bin/env bash

if [[ ! -z "${DEBUG}" ]]; then set -x; fi

set -o nounset -o pipefail
#Not setting "-o errexit", because script checks errors and returns custom error messages

function main() {

    checkRequiredCommands jq paste bc

    regCommand="reg"
    isInstalled "reg" || {
        echo "reg not installed, trying to use docker image 'r.j3ss.co/reg'"
         regCommand="docker run --rm r.j3ss.co/reg"
        isInstalled "docker" || {
            echo "Docker not installed. Out of options."
            return 1
         }
    }

    sizes=$(eval "${regCommand} manifest ${1}"  | jq -e '.layers[].size' 2>/dev/null)

    if [[ "${?}" = "0" ]]; then
        echo $(( ($(echo "${sizes}" | paste -sd+ | bc) + 500000) / 1000 / 1000)) MB
    else
        fail "Calling reg failed"
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

function fail() {
    error "$@"
    error Calculating size failed
    exit 1
}

function error() {
    echo "$@" 1>&2;
}

main "$@"