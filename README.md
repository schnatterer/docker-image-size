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

## Examples

There are different implementations to choose from.
Depending on the registry you query from, not all implementations might work.

Advantages:

* combining `reg` fast responses
* `docker` can handle most repos
* `curl` bash-only implementation, should run in all environments, even when they don't support docker.

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

Rather inconvenient because URLs is necessary. 

```bash
$ scripts/docker-image-size-curl.sh gcr.io/distroless/java:11-debug
73 MB 
# Does not work with reg v0.16.0
$ scripts/docker-image-size-curl.sh quay.io/prometheus/prometheus:v2.12.0
55 MB
```