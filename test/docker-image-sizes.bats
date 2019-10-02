#!/usr/bin/env bats

COMMAND=${COMMAND:-"scripts/docker-image-sizes.sh"}

@test "Returns multiple multi-arch results ${COMMAND}" {
   export DIS_IMPL=docker
   run ${COMMAND} nginx '^1.17.4'

   echo ${output}

   [[ "${status}" -eq 0 ]]
   [[ ${output} =~ "nginx:1.17.4" ]]
   [[ ${output} =~ "amd64 linux" ]]
   [[ ${output} =~ "arm64 linux" ]]
}

@test "Also runs with different implementation ${COMMAND}" {
   export DIS_IMPL=curl
   run ${COMMAND} nginx '^1.17.4'

   echo ${output}

   [[ "${status}" -eq 0 ]]
   [[ ${output} =~ "nginx:1.17.4" ]]
   # curl does not support multi arch
   [[ ! ${output} =~ "amd64 linux" ]]
}