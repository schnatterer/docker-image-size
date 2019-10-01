# docker-image-size

[![Build Status](https://travis-ci.org/schnatterer/docker-image-size.svg?branch=master)](https://travis-ci.org/schnatterer/docker-image-size)

Shell scripts for querying the size of a docker image from a registry.

See this [StackOverflow answer](https://stackoverflow.com/a/54813737) for details.

<!-- Update with `doctoc --notitle README.md`. See https://github.com/thlorenz/doctoc -->
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [Install](#install)
- [Features / implementations](#features--implementations)
  - [Query with curl](#query-with-curl)
  - [Query with docker manifest](#query-with-docker-manifest)
  - [Query with reg](#query-with-reg)
- [Compare sizes of docker tags](#compare-sizes-of-docker-tags)
- [Debugging](#debugging)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


## Install

* Install `jq`, e.g `sudo apt get install jq`  
  (the script variants have additional requirements that they will tell you on startup)
* Clone repo
* Use either
  * directly from repo or 
  * more convenient `sudo ln -s $(pwd)/scripts/docker-image-size-docker.sh  /usr/local/bin/docker-image-size`
  * (optional, if you want to compare image sizes)  

## Features / implementations

There are different implementations to choose from.
Depending on the registry you query from, not all implementations might work.

See [unit tests](test/docker-image-size.bats) for more details.

|   | curl | docker | reg |
|---|---|---|---|
|with/without tag | ✔️ | ✔️ | ✔️ |
|repo digest | ✔️ | ✔️ | ✔️ |
|platform-specific digest | ✔️ | ❌ | ❌ |
|private repos | ❌ | ✔️ | ️✔️ |
|multi-arch | ❌ | ✔️ | ️❌ |
|manifest v1 | ❌ | ❌ | ❌ |
|speed | fastest | slowest️ | ️in between️ |
|docker hub| ✔️ | ✔️ | ✔️ |
|gcr.io | ✔️ | ✔️ | ✔️ |
|r.j3ss.co | ️️✔️ | ️✔️ | ✔️ |
|quay.io | ✔️ | ✔️ | ❌️ |
|mcr.microsoft.com | ❌ | ✔️ | ❌ |

### Query with curl 

Queries with plain `curl`. Fastest, fewest requirements, but also least features (e.g. no private repos, no multi-arch).

```bash
$ scripts/docker-image-size-curl.sh gcr.io/distroless/java:11-debug
gcr.io/distroless/java:11-debug: 73 MB
# Does not work with reg v0.16.0
$ scripts/docker-image-size-curl.sh quay.io/prometheus/prometheus:v2.12.0
quay.io/prometheus/prometheus:v2.12.0: 55 MB
```

Tested with curl 7.64.0 (x86_64-pc-linux-gnu)

### Query with docker manifest

Queries with the experimental `docker manifest` command.
A bit slower than the others but best compatibly for repos and most features (e.g. multi-arch). Requires `docker`.

```bash
# This repo only works with -docker.sh
$ scripts/docker-image-size-docker.sh mcr.microsoft.com/windows/servercore:1903
mcr.microsoft.com/windows/servercore:1903 amd64 windows 10.0.18362.356: 2217 MB
```

Tested with docker 19.03.2

### Query with reg

Queries with [genuinetools/reg](https://github.com/genuinetools/reg). A compromise in terms of speed and features but
supports fewest registries.

Requires either reg installed or docker.

```bash
$ scripts/docker-image-size-reg.sh docker.io/debian:stretch-20190204-slim
docker.io/debian:stretch-20190204-slim: 23 MB
```

If you're using reg via docker, you can update to the latest version with
```bash
docker pull r.j3ss.co/reg
```

Tested with reg v0.16.0.

## Compare sizes of docker tags

There is an additional `docker-image-sizes.sh` that allows for querying the size for multiple tags of an image (see
[Install](#install) section for installation).

You can just use it like so:
Note the execution might take minutes (depending on the number of tags to query), because `docker manifest` is 
infamously slow.

```bash
docker-image-sizes openjdk 11
# Also supports regex for more accurate (and faster) output
docker-image-sizes openjdk '^11.0.4-'
# Or even filter using negative lookaheads
docker-image-sizes openjdk '^(?!.*windows)11.0.4'
# Note that the regex refers to the tag of the image and will not exclude multi-arch results 
# e.g. when the image "openjdk:11.0.4-jdk" also has a variant for windows
# However, this can easily be solved using grep
docker-image-sizes openjdk '^(?!.*windows)11.0.4' | grep 'amd64 linux'

```

### How it works

It combines `reg` and `docker-image-size` you can easily create a comparison of docker image variants sizes on the 
command line:

```bash
$ docker run r.j3ss.co/reg tags maven | grep -e '^3.6.2'  | \
    xargs -I{}  scripts/docker-image-size-curl.sh "maven:{}"
maven:3.6.2: 320 MB
maven:3.6.2-amazoncorretto-11: 338 MB
#...
``` 

If multiple architectures are involved for a tag, better use `docker-image-size-docker` in order to avoid errors and get
more details:
```bash
$ docker run r.j3ss.co/reg tags openjdk | grep -e '^11.0.4-'  \
    | xargs -I{}  scripts/docker-image-size-docker.sh "openjdk:{}"
openjdk:11.0.4-jdk amd64 linux : 311 MB
openjdk:11.0.4-jdk arm64 linux : 303 MB
openjdk:11.0.4-jdk amd64 windows 10.0.17763.737: 2353 MB
openjdk:11.0.4-jdk amd64 windows 10.0.17134.1006: 2536 MB
openjdk:11.0.4-jdk amd64 windows 10.0.14393.3204: 5919 MB
# ...
``` 

## Debugging

```bash
export DEBUG=true
scripts/docker-image-size-reg.sh docker.io/debian:stretch-20190204-slim
unset DEBUG
```