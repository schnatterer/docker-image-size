#!/usr/bin/env bash

echo $(( ( $(curl -s ${1} |  \
            jq '.layers[].size' \
            | paste -sd+ | bc) \
           + 500000) \
         / 1000 \
         / 1000)) MB