ARG DOCKER_VERSION=19.03.6
ARG REG_VERSION=v0.16.1
ARG ALPINE_VERSION=3.11.3

FROM alpine:${ALPINE_VERSION} as main
FROM docker:${DOCKER_VERSION} as docker
FROM r.j3ss.co/reg:${REG_VERSION} as reg

FROM main as dist
RUN mkdir -p /dist/usr/bin/
COPY --from=docker /usr/local/bin/docker /dist/usr/bin/
# Otherwise cert errors occurr on "docker manifest"
COPY --from=docker /etc/ssl/certs/ca-certificates.crt /dist/etc/ssl/certs/
COPY --from=reg /usr/bin/reg /dist/usr/bin/
COPY scripts/* /dist/usr/bin/

FROM main
RUN apk update && \
  apk upgrade && \
  apk add --no-cache --update curl jq coreutils bc bash dumb-init
COPY --from=dist --chown=100000:100000 /dist /

USER 100000
ENTRYPOINT ["/usr/bin/dumb-init", "--", "docker-image-sizes.sh"]