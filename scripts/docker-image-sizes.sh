#!/usr/bin/env bash

if [[ ! -z "${DEBUG}" ]]; then set -x; fi
DIS_IMPL=${DIS_IMPL-"docker"}
IMAGE="${1}"
TAG_REGEX="${2-.*}" # By default: Process all tags
COMMAND="docker-image-size-${DIS_IMPL}.sh"

set -o nounset -o pipefail -o errexit

BASEDIR=$(dirname $0)
ABSOLUTE_BASEDIR="$( cd ${BASEDIR} && pwd )"

function main() {
  checkArgs "$@"
  checkRequiredCommand

  regCommand="reg"
  isInstalled "reg" || {
      echo "reg not installed, trying to use docker image 'r.j3ss.co/reg'"
       regCommand="docker run --rm r.j3ss.co/reg"
      isInstalled "docker" || {
          echo "Docker not installed. Out of options."
          return 1
       }
  }

  # grep -P (perl regex) would be much more versatile but not as compatible (not present in e.g. busybox)
  eval "${regCommand}" tags "${IMAGE}" | grep -E "${TAG_REGEX}"  \
    | xargs -I{} ${COMMAND} "${IMAGE}:{}"
}

function checkRequiredCommand() {
    missingCommands=""
    commands=( "${COMMAND}" )
    for currentCommand in "$commands"
    do
        # Search on the PATH and next to this script
        if [[ -z $(command -v "${currentCommand}" 2>&1) ]]; then
          if [[ ! -z $(command -v "${ABSOLUTE_BASEDIR}/${currentCommand}" 2>&1) ]]; then
             COMMAND="${ABSOLUTE_BASEDIR}/${COMMAND}"
          else
            missingCommands="${missingCommands} ${currentCommand}"
          fi
       fi
    done

    if [[ ! -z "${missingCommands}" ]]; then
        fail "Please install the following commands required by this script:${missingCommands}"
    fi
}

function isInstalled() {
    command -v "${1}" >/dev/null 2>&1 || return 1
}

function checkArgs() {

  if [[ $# < 1 ]]; then
    echo "Usage: $(basename "$0") NAME [TAG_REGEX]"
    echo "e.g.: $(basename "$0") openjdk '^11.0.4-'"
    exit 1
  fi
}

function fail() {
    error "$@"
    exit 1
}

function error() {
    echo "$@" 1>&2;
}

main "$@"