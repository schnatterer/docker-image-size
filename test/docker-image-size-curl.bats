#!/usr/bin/env bats

@test "Returns filesize" {
   run scripts/docker-image-size-curl.sh https://gcr.io/v2/distroless/java/manifests/11

   echo $output

   [[ "${status}" -eq 0 ]]
   [[ ${output} =~ " MB" ]]
   [[ ! ${output} =~ "Calcualating size failed" ]]
}

@test "Returns non zero and error message on manifest unknown" {
   run scripts/docker-image-size-curl.sh https://gcr.io/v2/distroless/java/manifests/NOTEXISTS

   echo $output

   [[ "${status}" -ne 0 ]]
   [[ ${output} =~ "Response" ]]
   [[ ${output} =~ "Calcualating size failed" ]]
}

@test "Returns non zero and error message on repo unkonow" {
   run scripts/docker-image-size-curl.sh https://gcr.io/v2/distroless/something/completely/different

   echo $output

   [[ "${status}" -ne 0 ]]
   [[ ${output} =~ "Response" ]]
   [[ ${output} =~ "Calcualating size failed" ]]
}
