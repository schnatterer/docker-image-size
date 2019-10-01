#!/usr/bin/env bash


function main() {
  checkArgs "$@"
  checkRequiredCommands docker-image-size

  IMAGE="${1}"
  TAG_REGEX="${2}"

  regCommand="reg"
  isInstalled "reg" || {
      echo "reg not installed, trying to use docker image 'r.j3ss.co/reg'"
       regCommand="docker run --rm r.j3ss.co/reg"
      isInstalled "docker" || {
          echo "Docker not installed. Out of options."
          return 1
       }
  }

  eval "${regCommand}" tags "${IMAGE}" | grep -P "${TAG_REGEX}"  \
    | xargs -I{} docker-image-size "${IMAGE}:{}"
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

function checkArgs() {

  if [[ $# != 2 ]]; then
    echo "Usage: $(basename "$0") NAME TAG_REGEX"
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