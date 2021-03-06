FROM golang:1.15-alpine3.12 as builder

LABEL maintainer="MinIO Inc <dev@min.io>"

ENV GOPATH /go
ENV CGO_ENABLED 0
ENV GO111MODULE on

RUN  \
     apk add --no-cache git && \
     git clone https://github.com/minio/minio && cd minio && \
     git checkout master && go install -v -ldflags "$(go run buildscripts/gen-ldflags.go)"

FROM ubuntu:20.04

ENV MINIO_ACCESS_KEY_FILE=access_key \
    MINIO_SECRET_KEY_FILE=secret_key \
    MINIO_ROOT_USER_FILE=access_key \
    MINIO_ROOT_PASSWORD_FILE=secret_key \
    MINIO_KMS_MASTER_KEY_FILE=kms_master_key \
    MINIO_SSE_MASTER_KEY_FILE=sse_master_key \
    MINIO_UPDATE_MINISIGN_PUBKEY="RWTx5Zr1tiHQLwG9keckT0c45M3AGeHD6IvimQHpyRywVWGbP1aVSGav"

EXPOSE 9000

COPY --from=builder /go/bin/minio /usr/bin/minio
COPY --from=builder /go/minio/CREDITS /licenses/CREDITS
COPY --from=builder /go/minio/LICENSE /licenses/LICENSE
COPY --from=builder /go/minio/dockerscripts/docker-entrypoint.sh /usr/bin/

RUN  \
     apt-get update && \
     apt-get -y install curl ca-certificates util-linux

ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]

VOLUME ["/data"]

CMD ["minio"]
