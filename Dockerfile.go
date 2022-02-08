# a protobuf just contains goalng for arm64 and x86
ARG ALPINE_VERSION=3.15
ARG GO_VERSION=1.17
ARG ARCH=aarch_64
ARG PROTOBUF_VERSION=3.19.4
ARG PROTOC_GEN_GO_VERSION=v1.27.1
ARG PROTOC_GEN_GO_GRPC_VERSION=v1.43.0
ARG GRPC_GATEWAY_VERSION=v2.7.3
ARG GOOGLEAPIS_VERSION=master
ARG PROTOC_GEN_DOC_VERSION=v1.5.0

FROM golang:${GO_VERSION}-alpine as builder
RUN apk add --no-cache curl unzip

RUN export ARCH=x86_64 && \
    if [[ $(arch) == *"aarch64"* ]] ;then \
    export ARCH=aarch_64 && \
    curl -sSL https://releases.linaro.org/components/toolchain/binaries/latest-7/aarch64-linux-gnu/gcc-linaro-7.5.0-2019.12-i686-mingw32_aarch64-linux-gnu.tar.xz -o /tmp/gcc-linaro.tar.xz && \
    cd /tmp/ && tar -xJvf gcc-linaro.tar.xz -C ./ --strip-components=3 gcc-linaro-7.5.0-2019.12-i686-mingw32_aarch64-linux-gnu/aarch64-linux-gnu/libc/lib &&  \
    cp lib/ld-linux-aarch64.so.1 lib/libpthread.so.0 lib/libc.so.6 /out/lib/ \
    ; fi

ARG PROTOBUF_VERSION
RUN mkdir -p /out/usr/ && curl -sSL https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERSION}/protoc-${PROTOBUF_VERSION}-linux-${ARCH}.zip -o /tmp/protobuf.zip  && \
    unzip -o /tmp/protobuf.zip -d /out/usr/ && \
    rm /out/usr/readme.txt

ARG PROTOC_GEN_GO_VERSION
RUN mkdir -p ${GOPATH}/src/google.golang.org/protobuf && \
    curl -sSL https://github.com/protocolbuffers/protobuf-go/archive/refs/tags/${PROTOC_GEN_GO_VERSION}.tar.gz | tar xz --strip 1 -C ${GOPATH}/src/google.golang.org/protobuf &&\
    cd ${GOPATH}/src/google.golang.org/protobuf && \
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
    CGO_ENABLED=0 go build -ldflags '-w -s' -o /protoc-gen-validate-out/protoc-gen-validate . && \
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

FROM alpine:${ALPINE_VERSION}
COPY --from=builder /out/ /

RUN mkdir -p /build/proto/third_party /build/go/third_party /build/openapi /build/java

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

RUN echo $'if ! [ -d ./third_party ]; then return 0; fi && find ./third_party -type f -name '*.proto' -exec protoc -I ./third_party --proto_path=/usr/include \
 --go_out /build/go/third_party --go_opt paths=source_relative \
 --go-grpc_out /build/go/third_party --go-grpc_opt paths=source_relative \
 {} \;' >> /build/build_third_party.sh

RUN echo $'find ./ -not -path "./third_party/*" -type f -name '*.proto' -exec protoc -I . --proto_path=/usr/include \
 --go_out /build/go --go_opt paths=source_relative \
 --go-grpc_out /build/go --go-grpc_opt paths=source_relative \
 --java_out=/build/java --grpc-java_out=/build/java \
 --grpc-gateway_out /build/go --grpc-gateway_opt logtostderr=true \
 --grpc-gateway_opt paths=source_relative --grpc-gateway_opt generate_unbound_methods=true \
 --validate_out=lang=go,paths=source_relative:/build/go \
 --openapiv2_out /build/openapi --openapiv2_opt json_names_for_fields=false --openapiv2_opt \
logtostderr=true {} \;' >> /build/build.sh

RUN chmod +x /build/build.sh /build/build_third_party.sh
RUN chown -R nobody.nobody /build /usr/include

WORKDIR /build/proto

# the example to build the proto to test folder
# docker run --rm -v $(shell pwd)/pkg/go:/build/go -v $(shell pwd)/pkg/openapi:/build/openapi -v $(shell pwd):/build/proto nanxi/protoc:go
CMD ["/bin/sh", "-c", "/build/build.sh && /build/build_third_party.sh"]
