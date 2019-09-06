#!/usr/bin/env bash

echo $(( ( $(docker run r.j3ss.co/reg manifest ${1} |  \
            jq '.layers[].size' \
            | paste -sd+ | bc) \
           + 500000) \
         / 1000 \
         / 1000)) MB