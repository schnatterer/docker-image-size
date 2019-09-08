#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

echo $(( ( $(docker run r.j3ss.co/reg manifest ${1} |  \
            jq '.layers[].size' \
            | paste -sd+ | bc) \
           + 500000) \
         / 1000 \
         / 1000)) MB