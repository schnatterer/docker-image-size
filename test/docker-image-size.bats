#!/usr/bin/env bats

COMMAND=${COMMAND:-"scripts/docker-image-size-curl.sh"}

@test "Returns filesize for docker hub library (latest)${COMMAND}" {
   run ${COMMAND} debian
    assertSuccess
}

@test "Returns filesize for docker hub library qualified with docker.io ${COMMAND}" {
   run ${COMMAND} docker.io/debian
    assertSuccess
}

@test "Returns filesize for docker hub library qualified with 'library'' ${COMMAND}" {
   run ${COMMAND} library/debian
    assertSuccess
}

@test "Returns filesize for docker hub library qualified with docker.io and 'library'' ${COMMAND}" {
   run ${COMMAND} docker.io/library/debian
    assertSuccess
}

@test "Returns filesize for docker hub library with tag ${COMMAND}" {
    # This returns a manifest v1 if no content type set
   run ${COMMAND} debian:buster-20190910-slim
    assertSuccess
}

@test "Returns filesize for docker hub repo (latest) ${COMMAND}" {
    # This returns a manifest v1 if no content type set
   run ${COMMAND} nginxinc/nginx-unprivileged
    assertSuccess
}

@test "Returns filesize for docker hub repo with tag ${COMMAND}" {
    # This returns a manifest v1 if no content type set
   run ${COMMAND} nginxinc/nginx-unprivileged:1.17.2
    assertSuccess
}

@test "Returns filesize for multiple architectures ${COMMAND}" {
    skipFor "reg"
    skipFor "curl"

   run ${COMMAND} debian:buster-20190910-slim
    [[ ${output} =~ "amd64 linux" ]]
    [[ ${output} =~ "arm64 linux" ]]
}

@test "Returns filesize for multiple architectures with OS version ${COMMAND}" {
    skipFor "reg"
    skipFor "curl"

   run ${COMMAND} openjdk:11.0.4-windowsservercore
    [[ ${output} =~ "amd64 windows 10.0.14393.3204" ]]
    [[ ${output} =~ "amd64 windows 10.0.17134.1006" ]]
}

@test "Returns filesize for V1 Manifest ${COMMAND}" {
    skipFor "reg"
    skipFor "docker"
    skipFor "curl"

   run ${COMMAND} quay.io/calico/node:v3.2.4-2-g41efb10-amd64
    assertSuccess
}

@test "Returns filesize for repo digest ${COMMAND}" {
   run ${COMMAND} nginxinc/nginx-unprivileged@sha256:dc95dc03b407a7c49fb0a35c3b835b736dc621024fb14b1e8c2f568d99fffc63
    assertSuccess
}

@test "Returns filesize for platform-specific repo digest ${COMMAND}" {
    skipFor "reg"
    skipFor "docker"

   run ${COMMAND} nginxinc/nginx-unprivileged@sha256:2a10487719ac6ad15d02d832a8f43bafa9562be7ddc8f8bd710098aa54560cc2
    assertSuccess
}

@test "Returns filesize for 'library' at other repo ${COMMAND}" {
   run ${COMMAND} r.j3ss.co/reg:v0.16.0
   assertSuccess
}

@test "Returns filesize for gcr ${COMMAND}" {
   run ${COMMAND} gcr.io/distroless/java:11
    assertSuccess
}

@test "Returns filesize for mcr ${COMMAND}" {
    skipFor "reg"
    skipFor "curl"

   run ${COMMAND} mcr.microsoft.com/windows/servercore:1903
    assertSuccess
}

@test "Returns filesize for quay.io ${COMMAND}" {
    skipFor "reg"
   run ${COMMAND} quay.io/prometheus/prometheus:v2.12.0
    assertSuccess
}

@test "Returns non zero and error message on manifest unknown ${COMMAND}" {
   run ${COMMAND} gcr.io/distroless/java:NOTEXISTS
    assertFailure "Calculating size failed"
}

@test "Returns non zero and error message on repo unknown ${COMMAND}" {
   run ${COMMAND} gcr.io/distroless/something/completely/different
    assertFailure "Calculating size failed"
}

@test "Returns non zero and error message on host is not a repo ${COMMAND}" {
   run ${COMMAND} google/bla:blub
    assertFailure "Calculating size failed"
}

@test "Returns non zero and error message on host does not exist ${COMMAND}" {
   run ${COMMAND} nooooooooooooooooootAHoooooooooooSt
    assertFailure "Calculating size failed"
}

function assertSuccess() {
   echo ${output}

   [[ "${status}" -eq 0 ]]
   [[ ${output} =~ " MB" ]]
   [[ ! ${output} =~ "Calculating size failed" ]]
}

function assertFailure() {
    echo ${output}

   [[ "${status}" -ne 0 ]]
   [[ ${output} =~ ${1} ]]
   [[ ! ${output} =~ "jq: " ]]
}

function skipFor() {
    if [[ "${COMMAND}" == *"-${1}.sh"* ]]; then
        skip
    fi
}