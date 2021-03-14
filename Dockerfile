ARG ALPINE_VERSION=3.13
ARG GLIBC_VERSION=2.33-r0
ARG GO_VERSION=1.16
ARG PROTOBUF_VERSION=3.15.6
ARG PROTOC_GEN_GO_VERSION=master
ARG PROTOC_GEN_GO_GRPC_VERSION=v1.35.1
ARG PROTOC_GEN_VALIDATE_VERSION=v0.4.1
ARG GRPC_GATEWAY_VERSION=v2.3.0
ARG PROTOC_GEN_DOC_VERSION=v1.4.1
ARG GOOGLEAPIS_VERSION=master

FROM golang:${GO_VERSION}-alpine${ALPINE_VERSION} as builder
RUN apk add --no-cache build-base curl git upx

ARG GLIBC_VERSION
RUN mkdir -p /out/tmp/ /out/etc/apk/keys/
RUN curl -sSL https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /out/etc/apk/keys/sgerrand.rsa.pub  && \
    curl -sSL https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk -o /out/tmp/glibc.apk

ARG PROTOBUF_VERSION
RUN mkdir -p /out/usr/
RUN curl -sSL https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERSION}/protoc-${PROTOBUF_VERSION}-linux-x86_64.zip -o /tmp/protobuf.zip  && \
    unzip /tmp/protobuf.zip -d /out/usr/ && \
    rm /out/usr/readme.txt

ARG PROTOC_GEN_GO_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/protocolbuffers/protobuf-go && \
    curl -sSL https://api.github.com/repos/protocolbuffers/protobuf-go/tarball/${PROTOC_GEN_GO_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/protocolbuffers/protobuf-go &&\
    cd ${GOPATH}/src/github.com/protocolbuffers/protobuf-go && \
    CGO_ENABLED=0 go build -ldflags '-w -s' -o /golang-protobuf-out/protoc-gen-go ./cmd/protoc-gen-go && \
    install -Ds /golang-protobuf-out/protoc-gen-go /out/usr/bin/protoc-gen-go

ARG PROTOC_GEN_GO_GRPC_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/grpc/grpc-go && \
    curl -sSL https://api.github.com/repos/grpc/grpc-go/tarball/${PROTOC_GEN_GO_GRPC_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/grpc/grpc-go &&\
    cd ${GOPATH}/src/github.com/grpc/grpc-go/cmd/protoc-gen-go-grpc && \
    CGO_ENABLED=0 go build -ldflags '-w -s' -o /golang-protobuf-out/protoc-gen-go-grpc && \
    install -Ds /golang-protobuf-out/protoc-gen-go-grpc /out/usr/bin/protoc-gen-go-grpc

ARG PROTOC_GEN_VALIDATE_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/envoyproxy/protoc-gen-validate && \
    curl -sSL https://api.github.com/repos/envoyproxy/protoc-gen-validate/tarball/${PROTOC_GEN_VALIDATE_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/envoyproxy/protoc-gen-validate && \
    cd ${GOPATH}/src/github.com/envoyproxy/protoc-gen-validate && \
    go build -ldflags '-w -s' -o /protoc-gen-validate-out/protoc-gen-validate . && \
    install -Ds /protoc-gen-validate-out/protoc-gen-validate /out/usr/bin/protoc-gen-validate && \
    install -D ./validate/validate.proto /out/usr/include/github.com/envoyproxy/protoc-gen-validate/validate/validate.proto

ARG GRPC_GATEWAY_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway && \
    curl -sSL https://api.github.com/repos/grpc-ecosystem/grpc-gateway/tarball/${GRPC_GATEWAY_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway && \
    cd ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway && \
    CGO_ENABLED=0 go build -ldflags '-w -s' -o /grpc-gateway-out/protoc-gen-grpc-gateway ./protoc-gen-grpc-gateway && \
    CGO_ENABLED=0 go build -ldflags '-w -s' -o /grpc-gateway-out/protoc-gen-openapiv2 ./protoc-gen-openapiv2 && \
    install -Ds /grpc-gateway-out/protoc-gen-grpc-gateway /out/usr/bin/protoc-gen-grpc-gateway && \
    install -Ds /grpc-gateway-out/protoc-gen-openapiv2 /out/usr/bin/protoc-gen-openapiv2 && \
    mkdir -p /out/usr/include/protoc-gen-openapiv2/options && \
    install -D $(find ./protoc-gen-openapiv2/options -name '*.proto') -t /out/usr/include/protoc-gen-openapiv2/options

ARG GOOGLEAPIS_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/googleapis/googleapis && \
    curl -sSL https://api.github.com/repos/googleapis/googleapis/tarball/${GOOGLEAPIS_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/googleapis/googleapis && \
    cd ${GOPATH}/src/github.com/googleapis/googleapis && \
    mkdir -p /out/usr/include/google/api && \
    cp -r ./google/api/*.proto /out/usr/include/google/api/ && \
    mkdir -p /out/usr/include/google/rpc/context && \
    cp -r ./google/rpc/*.proto /out/usr/include/google/rpc/ && \
    cp -r ./google/rpc/context/*.proto /out/usr/include/google/rpc/context/

ARG PROTOC_GEN_DOC_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/pseudomuto/protoc-gen-doc && \
    curl -sSL https://api.github.com/repos/pseudomuto/protoc-gen-doc/tarball/${PROTOC_GEN_DOC_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/pseudomuto/protoc-gen-doc && \
    cd ${GOPATH}/src/github.com/pseudomuto/protoc-gen-doc && \
    CGO_ENABLED=0 go build -ldflags '-w -s' -o /protoc-gen-doc-out/protoc-gen-doc ./cmd/protoc-gen-doc && \
    install -Ds /protoc-gen-doc-out/protoc-gen-doc /out/usr/bin/protoc-gen-doc

# UPX
RUN upx --lzma $(find /out/usr/bin/ \
        -type f -name 'proto*' \
    )


FROM alpine:${ALPINE_VERSION}
COPY --from=builder /out/ /

RUN apk add --no-cache /tmp/glibc.apk && \
    rm /etc/apk/keys/sgerrand.rsa.pub /tmp/glibc.apk

RUN mkdir -p /build/proto /build/go /build/openapi
# Exmaple Proto
RUN echo $'syntax = "proto3"; \n\
package your.service.v1; \n\
option go_package = "github.com/yourorg/yourprotos/pkg/go/your/service/v1"; \n\
import "google/api/annotations.proto"; \n\
message StringMessage { \n\
    string value = 1; \n\
} \n\
service YourService { \n\
    rpc Echo(StringMessage) returns (StringMessage) { \n\
     option (google.api.http) = { \n\
       post: "/v1/example/echo" \n\
       body: "*" \n\
     }; \n\
    } \n\
}' >> /build/proto/main.proto
RUN echo $'find ./ -type f -name '*.proto' -exec protoc -I . --proto_path=/usr/include \
 --go_out /build/go --go_opt paths=source_relative \
 --go-grpc_out /build/go --go-grpc_opt paths=source_relative \
 --grpc-gateway_out /build/go --grpc-gateway_opt logtostderr=true \
 --grpc-gateway_opt paths=source_relative --grpc-gateway_opt generate_unbound_methods=true \
 --validate_out=lang=go,paths=source_relative:/build/go \
 --openapiv2_out /build/openapi --openapiv2_opt \
logtostderr=true {} \;' >> /build/build.sh
RUN chmod +x /build/build.sh
RUN chown -R nobody.nobody /build
RUN chown -R nobody.nobody /usr/include
WORKDIR /build/proto
# the example to build the proto to test folder
# docker run --rm -v $(shell pwd)/pkg/go:/build/go -v $(shell pwd)/pkg/openapi:/build/openapi -v $(shell pwd):/build/proto nanxi/protoc:go
CMD ["/bin/sh", "-c", "/build/build.sh"]
