# docker-image-size

[![Build Status](https://travis-ci.org/schnatterer/docker-image-size.svg?branch=master)](https://travis-ci.org/schnatterer/docker-image-size)

Shell scripts for querying the size of a docker image from a registry.

See this [StackOverflow answer](https://stackoverflow.com/a/54813737) for details

## Install

* Install `jq`, e.g `sudo apt get install jq`
* Clone repo
* Use either
  * directly from repo or 
  *  more convenient `sudo ln -s $(pwd)/scripts/docker-image-size-reg.sh  /usr/local/bin/docker-image-size`

## Examples

There are different implementations to choose from.
Depending on the registry you query from, not all implementations might work.

I found using `reg` combining the most advantages: reliability and fast responses.

### Query with [genuinetools/reg](https://github.com/genuinetools/reg)

```bash
$ scripts/docker-image-size-reg.sh debian:stretch-20190204-slim
23 MB
```

### Query with `docker manifest`

A bit slower than the others.

```bash
$ scripts/docker-image-size-docker.sh docker.io/debian:stretch-20190204-slim
23 MB
```


### Query with `curl`

Rather inconvenient because URLs is necessary. 

```bash
$ scripts/docker-image-size-curl.sh gcr.io/distroless/java:11-debug
73 MB
```