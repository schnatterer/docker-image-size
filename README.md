# docker-image-size

[![Build Status](https://travis-ci.org/schnatterer/docker-image-size.svg?branch=master)](https://travis-ci.org/schnatterer/docker-image-size)

Shell scripts for querying the size of a docker image from a registry.

See this [StackOverflow answer](https://stackoverflow.com/a/54813737) for details

## Install

* Install `jq`, e.g `sudo apt get install jq`  
  (the script variants have additional requirements that they will tell you on startup)
* Clone repo
* Use either
  * directly from repo or 
  *  more convenient `sudo ln -s $(pwd)/scripts/docker-image-size-reg.sh  /usr/local/bin/docker-image-size`

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
|speed | fastest | slowest️ | ️in between️ |
|multi-arch | ❌ | ❌ | ️❌ |
|manifest v1 | ❌ | ❌ | ❌ |
|docker hub| ✔️ | ✔️ | ✔️ |
|gcr.io | ✔️ | ✔️ | ✔️ |
|quay.io | ✔️ | ✔️ | ❌️ |
|mcr.microsoft.com | ❌ | ✔️ | ❌ |
|r.j3ss.co | ❌ | ️✔️ | ✔️ |

### Query with [genuinetools/reg](https://github.com/genuinetools/reg)

Requires either reg installed or docker.
```bash
$ scripts/docker-image-size-reg.sh docker.io/debian:stretch-20190204-slim
23 MB
```

If you're using reg via docker, you can update to the latest version with
```bash
docker pull r.j3ss.co/reg
```

Tested with reg v0.16.0.

### Query with `docker manifest`

A bit slower than the others. Requires `docker`.

```bash
# This repo only works with -docker.sh
$ scripts/docker-image-size-docker.sh mcr.microsoft.com/windows/servercore:1903
1527 MB
```

Tested with docker 19.03.2

### Query with `curl`

```bash
$ scripts/docker-image-size-curl.sh gcr.io/distroless/java:11-debug
73 MB 
# Does not work with reg v0.16.0
$ scripts/docker-image-size-curl.sh quay.io/prometheus/prometheus:v2.12.0
55 MB
```

Tested wiht curl 7.64.0 (x86_64-pc-linux-gnu)

## Compare sizes of docker tags

By combining`reg` and `docker-image-size` you can easily create a comparison of docker image variants sizes on the 
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