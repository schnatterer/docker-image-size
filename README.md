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

### Query with `docker manifest`

A bit slower than the others. Requires `docker`.

```bash
# This repo only works with -docker.sh
$ scripts/docker-image-size-docker.sh mcr.microsoft.com/windows/servercore:1903
1527 MB
```

### Query with `curl`

```bash
$ scripts/docker-image-size-curl.sh gcr.io/distroless/java:11-debug
73 MB 
# Does not work with reg v0.16.0
$ scripts/docker-image-size-curl.sh quay.io/prometheus/prometheus:v2.12.0
55 MB
```

## Compare sizes of docker tags

By combining`reg` and `docker-image-size` you can easily create a comparison of docker image variants sizes on the 
command line:

```bash
$ docker run r.j3ss.co/reg tags maven | grep -e '^3.6.2'  | \
    xargs -I{}  scripts/docker-image-size-curl.sh "maven:{}"
maven:3.6.2: 320 MB
maven:3.6.2-amazoncorretto-11: 338 MB
maven:3.6.2-amazoncorretto-8: 262 MB
maven:3.6.2-ibmjava: 247 MB
maven:3.6.2-ibmjava-8: 247 MB
maven:3.6.2-ibmjava-8-alpine: 185 MB
maven:3.6.2-ibmjava-alpine: 185 MB
maven:3.6.2-jdk-11: 320 MB
maven:3.6.2-jdk-11-slim: 238 MB
maven:3.6.2-jdk-12: 257 MB
maven:3.6.2-jdk-13: 263 MB
maven:3.6.2-jdk-14: 264 MB
maven:3.6.2-jdk-8: 229 MB
maven:3.6.2-jdk-8-slim: 147 MB
maven:3.6.2-slim: 238 MB
``` 
