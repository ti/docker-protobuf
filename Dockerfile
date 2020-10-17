ARG ALPINE_VERSION=3.12
ARG GO_VERSION=1.15
ARG GRPC_GATEWAY_VERSION=2.0.0
ARG PROTOC_GEN_VALIDATE_VERSION=0.4.1
ARG GO_PROTO_VALIDATORS_VERSION=0.3.2
ARG PROTOBUF_VERSION=3.13.0
ARG GRPC_VERSION=1.32.0
ARG PROTOC_GEN_DOC_VERSION=1.3.2
ARG PROTOC_GEN_GO_VERSION=1.25.0
ARG PROTOC_GEN_GO_GRPC_VERSION=1.0.0

FROM golang:${GO_VERSION}-alpine${ALPINE_VERSION} as go_builder
RUN apk add --no-cache build-base curl unzip git

ARG PROTOBUF_VERSION
RUN mkdir -p /out/usr/
RUN curl -sSL https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERSION}/protoc-${PROTOBUF_VERSION}-linux-x86_64.zip -o /tmp/protobuf.zip  && \
    unzip /tmp/protobuf.zip -d /out/usr/ && \
    rm -rf /out/usr/bin \
    rm /out/usr/readme.txt

ARG PROTOC_GEN_GO_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/protocolbuffers/protobuf-go && \
    curl -sSL https://codeload.github.com/protocolbuffers/protobuf-go/tar.gz/v${PROTOC_GEN_GO_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/protocolbuffers/protobuf-go &&\
    cd ${GOPATH}/src/github.com/protocolbuffers/protobuf-go && \
    go build -ldflags '-w -s' -o /golang-protobuf-out/protoc-gen-go ./cmd/protoc-gen-go && \
    install -Ds /golang-protobuf-out/protoc-gen-go /out/usr/bin/protoc-gen-go

ARG PROTOC_GEN_GO_GRPC_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/grpc/grpc-go && \
    curl -sSL https://codeload.github.com/grpc/grpc-go/tar.gz/cmd/protoc-gen-go-grpc/v${PROTOC_GEN_GO_GRPC_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/grpc/grpc-go &&\
    cd ${GOPATH}/src/github.com/grpc/grpc-go/cmd/protoc-gen-go-grpc && \
    go build -ldflags '-w -s' -o /golang-protobuf-out/protoc-gen-go-grpc && \
    install -Ds /golang-protobuf-out/protoc-gen-go-grpc /out/usr/bin/protoc-gen-go-grpc

ARG PROTOC_GEN_VALIDATE_VERSION
RUN echo v${PROTOC_GEN_VALIDATE_VERSION}
RUN mkdir -p ${GOPATH}/src/github.com/envoyproxy/protoc-gen-validate && \
    curl -sSL https://api.github.com/repos/envoyproxy/protoc-gen-validate/tarball/v${PROTOC_GEN_VALIDATE_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/envoyproxy/protoc-gen-validate && \
    cd ${GOPATH}/src/github.com/envoyproxy/protoc-gen-validate && \
    go build -ldflags '-w -s' -o /protoc-gen-validate-out/protoc-gen-validate . && \
    install -Ds /protoc-gen-validate-out/protoc-gen-validate /out/usr/bin/protoc-gen-validate && \
    install -D ./validate/validate.proto /out/usr/include/github.com/envoyproxy/protoc-gen-validate/validate/validate.proto

ARG GRPC_GATEWAY_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway && \
    curl -sSL https://api.github.com/repos/grpc-ecosystem/grpc-gateway/tarball/v${GRPC_GATEWAY_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway && \
    cd ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway && \
    go build -ldflags '-w -s' -o /grpc-gateway-out/protoc-gen-grpc-gateway ./protoc-gen-grpc-gateway && \
    go build -ldflags '-w -s' -o /grpc-gateway-out/protoc-gen-openapiv2 ./protoc-gen-openapiv2 && \
    install -Ds /grpc-gateway-out/protoc-gen-grpc-gateway /out/usr/bin/protoc-gen-grpc-gateway && \
    install -Ds /grpc-gateway-out/protoc-gen-openapiv2 /out/usr/bin/protoc-gen-openapiv2 && \
    mkdir -p /out/usr/include/protoc-gen-openapiv2/options && \
    install -D $(find ./protoc-gen-openapiv2/options -name '*.proto') -t /out/usr/include/protoc-gen-openapiv2/options && \
    mkdir -p /out/usr/include/google/api && \
    install -D $(find ./third_party/googleapis/google/api -name '*.proto') -t /out/usr/include/google/api && \
    mkdir -p /out/usr/include/google/rpc && \
    install -D $(find ./third_party/googleapis/google/rpc -name '*.proto') -t /out/usr/include/google/rpc

ARG PROTOC_GEN_DOC_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/pseudomuto/protoc-gen-doc && \
    curl -sSL https://api.github.com/repos/pseudomuto/protoc-gen-doc/tarball/v${PROTOC_GEN_DOC_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/pseudomuto/protoc-gen-doc && \
    cd ${GOPATH}/src/github.com/pseudomuto/protoc-gen-doc && \
    go build -ldflags '-w -s' -o /protoc-gen-doc-out/protoc-gen-doc ./cmd/protoc-gen-doc && \
    install -Ds /protoc-gen-doc-out/protoc-gen-doc /out/usr/bin/protoc-gen-doc

ARG GO_PROTO_VALIDATORS_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/mwitkow/go-proto-validators && \
    curl -sSL https://github.com/mwitkow/go-proto-validators/archive/v${GO_PROTO_VALIDATORS_VERSION}.tar.gz | tar xz --strip 1 -C ${GOPATH}/src/github.com/mwitkow/go-proto-validators && \
    cd ${GOPATH}/src/github.com/mwitkow/go-proto-validators && \
    install -D validator.proto /out/usr/include/github.com/mwitkow/go-proto-validators/validator.proto && \
    go build -ldflags '-w -s' -o /protoc-gen-govalidators-out/protoc-gen-govalidators ./protoc-gen-govalidators && \
    install -Ds /protoc-gen-govalidators-out/protoc-gen-govalidators /out/usr/bin/protoc-gen-govalidators

FROM alpine:${ALPINE_VERSION}
COPY --from=go_builder /out/ /
ARG PROTOBUF_VERSION
RUN apk add --no-cache protoc=${PROTOBUF_VERSION}-r0 --repository=http://dl-cdn.alpinelinux.org/alpine/edge/main
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
