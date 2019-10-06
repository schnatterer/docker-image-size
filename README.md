# docker-image-size

[![Build Status](https://travis-ci.org/schnatterer/docker-image-size.svg?branch=master)](https://travis-ci.org/schnatterer/docker-image-size)
[![](https://images.microbadger.com/badges/image/schnatterer/docker-image-size.svg)](https://hub.docker.com/r/schnatterer/docker-image-size)

Queries and compares docker image sizes.  
See also [this blog post](http://blog.schnatterer.info/2019/10/03/querying-docker-image-sizes-via-the-command-line).

<!-- Update with `doctoc --notitle README.md`. See https://github.com/thlorenz/doctoc -->
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [Installation](#installation)
  - [Docker](#docker)
  - [Local](#local)
- [Usage](#usage)
  - [Docker](#docker-1)
  - [Local](#local-1)
  - [Querying a single image](#querying-a-single-image)
  - [Examples](#examples)
  - [Implementations](#implementations)
  - [Features per implementation](#features-per-implementation)
  - [Query size with docker manifest](#query-size-with-docker-manifest)
  - [Query size with curl](#query-size-with-curl)
  - [Query size with reg](#query-size-with-reg)
- [Implementation notes](#implementation-notes)
- [Debugging](#debugging)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


## Installation

### Docker

Most convenient: don't install at all; just run docker container (see [usage](#usage)).
You can use it even more convenient by establishing an alias

```bash
alias docker-image-sizes='docker run --rm -e DIS_IMPL schnatterer/docker-image-size'
# If you want to query the size of a single image (faster)
# e.g. using curl (alternatives: docker, reg)
alias docker-image-size='docker run --rm --entrypoint docker-image-size-curl.sh schnatterer/docker-image-size'
``` 

Note that the image is cached locally, if you ever want to "update", just do a 

```bash
docker pull schnatterer/docker-image-size
```

### Local
* Install `jq`, e.g `sudo apt get install jq`  
  (the script variants have additional requirements that they will tell you on startup)
* Clone repo
* Use either
  * directly from repo or 
  * more convenient put it on the PATH, e.g. like so 
    ```bash
    sudo ln -s $(pwd)/scripts/docker-image-size-docker.sh  /usr/local/bin/docker-image-size-docker.sh
    sudo ln -s $(pwd)/scripts/docker-image-size-curl.sh  /usr/local/bin/docker-image-size-curl.sh
    sudo ln -s $(pwd)/scripts/docker-image-size-reg.sh  /usr/local/bin/docker-image-size-reg.sh
    sudo ln -s $(pwd)/scripts/docker-image-sizes.sh  /usr/local/bin/docker-image-sizes
    ```

## Usage

Note the execution might take minutes (depending on the number of tags to query), because `docker manifest` is 
infamously slow. You can use other [implementations](#implementations) that might be less compatible with some repos, 
though.

### Docker

```bash
docker run --rm schnatterer/docker-image-size <docker image name> [<extended grep regex on docker tag>]
# Or with the alias mentioned above:
docker-image-sizes <docker image name> [<extended grep regex on docker tag>]
```

### Local

```bash
docker-image-sizes <docker image name> [<extended grep regex on docker tag>]
# or from repo 
scripts/docker-image-sizes.sh <docker image name> <extended grep regex on docker tag>
```

### Querying a single image

If you care about size of one image only you can use the [implementations](#implementations) directly, which for the 
`curl` implementation responds in about a second. Note that it takes only one parameter, similar to `docker run`:

```bash
# e.g. using curl (alternatives: docker, reg)
$ docker-image-size-curl.sh <docker image name>[:<Tag> | @<RepoDigest>]
# Or using the docker image
$ docker run --rm --entrypoint docker-image-size-curl.sh schnatterer/docker-image-size <docker image name>[:<Tag> | @<RepoDigest>]
``` 

### Examples

```bash
# Match all tags containing '11' (a whole lot. Will take ages!)
docker-image-sizes adoptopenjdk 11
# More accurate (and faster) output
docker-image-sizes adoptopenjdk '^11.0.4'
# Multi arg results can be filtered using grep 
docker-image-sizes adoptopenjdk '^11.0.4' | grep 'amd64 linux'
# Query a single image (fastest!)
docker-image-size-curl.sh adoptopenjdk:11.0.4_11-jre-hotspot
```

### Implementations

`docker-images-sizes.sh` can use different implementations for querying the docker manifest from the repos. See 
Features per implementation bellow for details.  
By default `docker-images-sizes.sh` uses `docker` (the `docker manifest` command), but you could switch to `curl` or 
`reg` as follows:

```bash
docker run --rm -e DIS_IMPL=curl schnatterer/docker-image-size <docker image name> [<extended grep regex on docker tag>]
DIS_IMPL=curl docker-image-sizes <docker image name> [<extended grep regex on docker tag>]
```

### Features per implementation 

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

### Query size with docker manifest

Queries with the experimental `docker manifest` command.
A bit slower than the others but best compatibly for repos and most features (e.g. multi-arch). Requires `docker`.

```bash
# This repo only works with -docker.sh
$ scripts/docker-image-size-docker.sh mcr.microsoft.com/windows/servercore:1903
mcr.microsoft.com/windows/servercore:1903 amd64 windows 10.0.18362.356: 2217 MB
```

Tested with docker 19.03.2

### Query size with curl 

Queries with plain `curl`. Fastest, fewest requirements, but also least features (e.g. no private repos, no multi-arch).

```bash
$ scripts/docker-image-size-curl.sh gcr.io/distroless/java:11-debug
gcr.io/distroless/java:11-debug: 73 MB
# Does not work with reg v0.16.0
$ scripts/docker-image-size-curl.sh quay.io/prometheus/prometheus:v2.12.0
quay.io/prometheus/prometheus:v2.12.0: 55 MB
```

Tested with 
* curl 7.64.0 (x86_64-pc-linux-gnu)
* curl 7.66.0 (x86_64-alpine-linux-musl)

### Query size with reg

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

Tested with reg version: v0.16.0; git hash: f180c93a.

## Implementation notes

* The docker repository API (OCI distribution spec) allows for querying tags from images as well as the manifest, which 
  contains the size of each image layer.
* From these sizes, the total image size can be aggregated. See [StackOverflow answer](https://stackoverflow.com/a/54813737)  
  for basic implementation details. These are implemented in this repo as `docker-image-size-*.sh` scripts, see 
  [scripts](scripts).
* [genuinetools/reg](https://github.com/genuinetools/reg) (`tags` command) allows for querying docker image tags on the 
  command line.
* [docker-images-sizes.sh](scripts/docker-image-sizes.sh) brings both of them together:  for conveniently comparing
 docker image sizes of different tags on the command line.
* The basic logic looks like this: 
 ```bash
 $ docker run r.j3ss.co/reg tags maven | grep -e '^3.6.2'  | \
    xargs -I{}  scripts/docker-image-size-curl.sh "maven:{}"
 maven:3.6.2: 320 MB
 maven:3.6.2-amazoncorretto-11: 338 MB
 #...
 ``` 
* If multiple architectures are involved for a tag, it's better to use `docker-image-size-docker.sh` in order to avoid
 errors and get more details. Unfortunately, it's much slower:
  ```bash
  $ docker run r.j3ss.co/reg tags adoptopenjdk | grep -e '^11.0.4'  \
      | xargs -I{}  scripts/docker-image-size-docker.sh "adoptopenjdk:{}"
  openjdk:11.0.4-jdk amd64 linux : 311 MB
  openjdk:11.0.4-jdk arm64 linux : 303 MB
  openjdk:11.0.4-jdk amd64 windows 10.0.17763.737: 2353 MB
  openjdk:11.0.4-jdk amd64 windows 10.0.17134.1006: 2536 MB
  openjdk:11.0.4-jdk amd64 windows 10.0.14393.3204: 5919 MB
  # ...
  ``` 

## Debugging

```bash
export DEBUG=true # Results in set -x
scripts/docker-image-size-reg.sh docker.io/debian:stretch-20190204-slim
unset DEBUG
```