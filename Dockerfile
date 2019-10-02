ARG DOCKER_VERSION=19.03.2
# newest v.0.16.0 results in "error unmarshalling content: invalid character '<' looking for beginning of value"
# latest works right now, use the corresponding repo digest in order to make it more deterministic
ARG REG_VERSION=sha256:5c4a8c1af1fb2835b5556322677df875fa63f0f410860f9203fedc330b09dc86
ARG ALPINE_VERSION=3.10.2

FROM alpine:${ALPINE_VERSION} as main
FROM docker:${DOCKER_VERSION} as docker
FROM r.j3ss.co/reg@${REG_VERSION} as reg

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
  apk add --no-cache --update curl jq coreutils bc bash
COPY --from=dist --chown=100000:100000 /dist /

USER 100000
ENTRYPOINT ["docker-image-sizes.sh"]