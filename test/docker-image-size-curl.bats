#!/usr/bin/env bats

@test "Returns filesize for docker hub library" {
   run scripts/docker-image-size-curl.sh debian
    assertSuccess
}

@test "Returns filesize for docker hub library qualified with repo" {
   run scripts/docker-image-size-curl.sh docker.io/debian
    assertSuccess
}

@test "Returns filesize for docker hub library qualified with 'library''" {
   run scripts/docker-image-size-curl.sh library/debian
    assertSuccess
}

@test "Returns filesize for docker hub repo" {
    # This returns a manifest v1 if no content type set
   run scripts/docker-image-size-curl.sh nginxinc/nginx-unprivileged
    assertSuccess
}

@test "Returns filesize for docker repo with tag" {
    # This returns a manifest v1 if no content type set
   run scripts/docker-image-size-curl.sh nginxinc/nginx-unprivileged:1.17.2
    assertSuccess
}

@test "Returns filesize for gcr" {
   run scripts/docker-image-size-curl.sh gcr.io/distroless/java:11
    assertSuccess
}

@test "Returns non zero and error message on manifest unknown" {
   run scripts/docker-image-size-curl.sh gcr.io/distroless/java:NOTEXISTS
    assertFailure "Calcualating size failed"
}

@test "Returns non zero and error message on repo unknow" {
   run scripts/docker-image-size-curl.sh gcr.io/distroless/something/completely/different
    assertFailure "Calcualating size failed"
}

@test "Returns non zero and error message on host is not a repo" {
   run scripts/docker-image-size-curl.sh google/bla:blub
    assertFailure "Calcualating size failed"
}

@test "Returns non zero and error message on host does not exist" {
   run scripts/docker-image-size-curl.sh nooooooooooooooooootAHoooooooooooSt
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