#!/usr/bin/env bash

export DOCKER_CLI_EXPERIMENTAL=enabled

echo $(( ( $(docker manifest inspect -v ${1} \
    | jq '.[] | select(.Descriptor.platform.architecture == "amd64").SchemaV2Manifest.layers[0].size') \
           + 500000) \
         / 1000 \
         / 1000)) MB