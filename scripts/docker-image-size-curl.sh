#!/usr/bin/env bash

RESPONSE=$(curl -s ${1})
SIZES=$(echo ${RESPONSE} | jq '.layers[].size' )
RET="$?"

if [[ "${RET}" = "0" ]]; then
    echo $(( ($(echo "${SIZES}" | paste -sd+ | bc) + 500000) / 1000 / 1000)) MB
else
    echo Response: ${RESPONSE}
    echo Calcualating size failed
    exit 1
fi

