#!/usr/bin/env bash

if [[ ! -z "${DEBUG}" ]]; then set -x; fi
NAME="${1}"

set -o nounset -o pipefail
#Not setting "-o errexit", because script checks errors and returns custom error messages

export DOCKER_CLI_EXPERIMENTAL=enabled

function main() {

    checkArgs "$@"
    checkRequiredCommands docker jq paste bc

    manifest=$(docker manifest inspect -v ${1})
    if [[ "${?}" != "0" ]]; then
      fail "Calling docker manifest failed"
    fi

    if [[ "${manifest:0:1}" == "[" ]]; then

      length=$(echo "${manifest}" |  jq '. | length')
      for (( i=0; i<${length}; i ++ ))
      do
         currentObj=$(echo "${manifest}" | jq  ".[${i}]")
         optionalOsVersion=$(echo "${currentObj}" | jq -r  '" " + .Descriptor.platform."os.version"' 2>/dev/null)
         arcAndOs=$(echo "${currentObj}" | jq -r ' .Descriptor.platform.architecture + " " + .Descriptor.platform.os')
         sizes=$( echo "${currentObj}" | jq -e ".SchemaV2Manifest.layers[].size")
        if [[ "${?}" = "0" ]]; then
          echo "${1} ${arcAndOs}${optionalOsVersion}:" $(createAndPrintSum "${sizes}")
         else
           fail "Processing response from docker manifest failed. Response: ${manifest}"
         fi
      done
    else
      sizes=$( echo "${manifest}" | jq -e '.SchemaV2Manifest.layers[].size')
      if [[ "${?}" = "0" ]]; then
          echo "${1}:" $(createAndPrintSum "${sizes}")
      else
          fail "Processing response from docker manifest failed. Response: ${manifest}"
      fi
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
        command -v "${currentCommand}" >/dev/null 2>&1 || missingCommands="${missingCommands} ${currentCommand}"
    done

    if [[ ! -z "${missingCommands}" ]]; then
        fail "Please install the following commands required by this script:${missingCommands}"
    fi
}

function isInstalled() {
    command -v "${1}" >/dev/null 2>&1 || return 1
}

function createAndPrintSum() {
    echo $(( ($(echo "${1}" | paste -sd+ | bc) + 500000) / 1000 / 1000)) MB
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