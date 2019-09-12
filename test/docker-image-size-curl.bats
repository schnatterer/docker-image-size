#!/usr/bin/env bats

@test "Returns filesize for docker hub library" {
   run scripts/docker-image-size-curl.sh https://registry.hub.docker.com/v2/library/debian/manifests/latest

    assertSuccess
}

@test "Returns filesize for docker hub repo" {
    # This returns a manifest v1 if no content type set
   run scripts/docker-image-size-curl.sh https://registry.hub.docker.com/v2/nginxinc/nginx-unprivileged/manifests/1.17.2

    assertSuccess
}

@test "Follows redirects" {
   run scripts/docker-image-size-curl.sh https://registry-1.docker.io//v2/nginxinc/nginx-unprivileged/manifests/1.17.2

    assertSuccess
}

@test "Returns filesize for docker io repo" {
    # This returns a manifest v1 if no content type set
   run scripts/docker-image-size-curl.sh https://index.docker.io/v2/nginxinc/nginx-unprivileged/manifests/1.17.2

    assertSuccess
}

@test "Fail when no valid url" {
   run scripts/docker-image-size-curl.sh https://registry.hub.docker.com/v2/nginxinc/nginx-unprivileged

    assertFailure
}

@test "Returns filesize for gcr" {
   run scripts/docker-image-size-curl.sh https://gcr.io/v2/distroless/java/manifests/11

    assertSuccess
}

@test "Returns non zero and error message on manifest unknown" {
   run scripts/docker-image-size-curl.sh https://gcr.io/v2/distroless/java/manifests/NOTEXISTS


    assertFailure "Calcualating size failed"
}

@test "Returns non zero and error message on repo unknow" {
   run scripts/docker-image-size-curl.sh https://gcr.io/v2/distroless/something/completely/different

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
}