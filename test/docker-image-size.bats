#!/usr/bin/env bats

COMMAND=${COMMAND:-"scripts/docker-image-size-curl.sh"}

@test "Returns filesize for docker hub library" {
   run ${COMMAND} debian
    assertSuccess
}

@test "Returns filesize for docker hub library qualified with repo" {
   run ${COMMAND} docker.io/debian
    assertSuccess
}

@test "Returns filesize for docker hub library qualified with 'library''" {
   run ${COMMAND} library/debian
    assertSuccess
}

@test "Returns filesize for docker hub repo" {
    # This returns a manifest v1 if no content type set
   run ${COMMAND} nginxinc/nginx-unprivileged
    assertSuccess
}

@test "Returns filesize for docker hub repo with tag" {
    # This returns a manifest v1 if no content type set
   run ${COMMAND} nginxinc/nginx-unprivileged:1.17.2
    assertSuccess
}

@test "Returns filesize for docker library with tag" {
    # This returns a manifest v1 if no content type set
   run ${COMMAND} nginx:1.17.2
    assertSuccess
}

@test "Returns filesize for repo digest" {
   run ${COMMAND} nginxinc/nginx-unprivileged@sha256:dc95dc03b407a7c49fb0a35c3b835b736dc621024fb14b1e8c2f568d99fffc63
    assertSuccess
}

@test "Returns filesize for platform-specific repo digest" {
   run ${COMMAND} nginxinc/nginx-unprivileged@sha256:2a10487719ac6ad15d02d832a8f43bafa9562be7ddc8f8bd710098aa54560cc2
    assertSuccess
}

@test "Returns filesize for gcr" {
   run ${COMMAND} gcr.io/distroless/java:11
    assertSuccess
}

@test "Returns non zero and error message on manifest unknown" {
   run ${COMMAND} gcr.io/distroless/java:NOTEXISTS
    assertFailure "Calcualating size failed"
}

@test "Returns non zero and error message on repo unknow" {
   run ${COMMAND} gcr.io/distroless/something/completely/different
    assertFailure "Calcualating size failed"
}

@test "Returns non zero and error message on host is not a repo" {
   run ${COMMAND} google/bla:blub
    assertFailure "Calcualating size failed"
}

@test "Returns non zero and error message on host does not exist" {
   run ${COMMAND} nooooooooooooooooootAHoooooooooooSt
    assertFailure "Calcualating size failed"
}

function assertSuccess() {
   echo $output

   [[ "${status}" -eq 0 ]]
   [[ ${output} =~ " MB" ]]
   [[ ! ${output} =~ "Calcualating size failed" ]]
}

function assertFailure() {
    echo $output

   [[ "${status}" -ne 0 ]]
   [[ ${output} =~ "Response" ]]
   [[ ${output} =~ ${1} ]]
   [[ ! ${output} =~ "jq: " ]]
}