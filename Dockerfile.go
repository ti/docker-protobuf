# a simple protoc tool that Compatible with both arm and x86
# docker buildx build --push --platform linux/arm64,linux/amd64 --tag nanxi/protoc:go .
ARG ALPINE_VERSION=3.16
ARG GO_VERSION=1.18
ARG PROTOBUF_VERSION=3.20.1
ARG PROTOC_GEN_GO_VERSION=v1.28.0
ARG PROTOC_GEN_GO_GRPC_VERSION=v1.48.0
ARG GRPC_GATEWAY_VERSION=v2.11.0
ARG PROTOC_GEN_DOC_VERSION=v1.5.1
ARG GLIBC_VERSION=2.35-r0
ARG PROTOC_GEN_VALIDATE_VERSION=v0.6.7

FROM golang:${GO_VERSION}-alpine as builder
RUN apk add --no-cache curl unzip

ARG GLIBC_VERSION
RUN mkdir -p /out/lib/ && export ARCH=x86_64 && \
    if [[ $(arch) == *"aarch64"* ]] ;then \
    export ARCH=aarch_64 && \
    curl -sSL https://releases.linaro.org/components/toolchain/binaries/latest-7/aarch64-linux-gnu/gcc-linaro-7.5.0-2019.12-i686-mingw32_aarch64-linux-gnu.tar.xz -o /tmp/gcc-linaro.tar.xz && \
    cd /tmp/ && tar -xJvf gcc-linaro.tar.xz -C ./ --strip-components=3 gcc-linaro-7.5.0-2019.12-i686-mingw32_aarch64-linux-gnu/aarch64-linux-gnu/libc/lib &&  \
    cp lib/ld-linux-aarch64.so.1 lib/libpthread.so.0 lib/libc.so.6 /out/lib/ ; else mkdir -p /out/tmp/ /out/etc/apk/keys/ &&  \
    curl -sSL https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /out/etc/apk/keys/sgerrand.rsa.pub && \
    curl -sSL https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk -o /out/tmp/glibc.apk; fi

ARG PROTOBUF_VERSION
RUN mkdir -p /out/usr/ &&  \
    export ARCH=x86_64 && if [[ $(arch) == *"aarch64"* ]] ;then export ARCH=aarch_64; fi && \
    curl -sSL https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERSION}/protoc-${PROTOBUF_VERSION}-linux-${ARCH}.zip -o /tmp/protobuf.zip  && \
    unzip -o /tmp/protobuf.zip -d /out/usr/ && \
    rm /out/usr/readme.txt

ARG PROTOC_GEN_GO_VERSION
RUN mkdir -p ${GOPATH}/src/google.golang.org/protobuf && \
    curl -sSL https://github.com/protocolbuffers/protobuf-go/archive/refs/tags/${PROTOC_GEN_GO_VERSION}.tar.gz | tar xz --strip 1 -C ${GOPATH}/src/google.golang.org/protobuf &&\
    cd ${GOPATH}/src/google.golang.org/protobuf && \
    CGO_ENABLED=0 go build -ldflags '-w -s' -o /out/usr/bin/protoc-gen-go ./cmd/protoc-gen-go

ARG PROTOC_GEN_GO_GRPC_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/grpc/grpc-go && \
    curl -sSL https://github.com/grpc/grpc-go/archive/refs/tags/${PROTOC_GEN_GO_GRPC_VERSION}.tar.gz | tar xz --strip 1 -C ${GOPATH}/src/github.com/grpc/grpc-go &&\
    cd ${GOPATH}/src/github.com/grpc/grpc-go/cmd/protoc-gen-go-grpc && \
    CGO_ENABLED=0 go build -ldflags '-w -s' -o /out/usr/bin/protoc-gen-go-grpc

ARG PROTOC_GEN_VALIDATE_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/envoyproxy/protoc-gen-validate && \
    curl -sSL https://github.com/envoyproxy/protoc-gen-validate/archive/refs/tags/${PROTOC_GEN_VALIDATE_VERSION}.tar.gz | tar xz --strip 1 -C ${GOPATH}/src/github.com/envoyproxy/protoc-gen-validate && \
    cd ${GOPATH}/src/github.com/envoyproxy/protoc-gen-validate && \
    CGO_ENABLED=0 go build -ldflags '-w -s' -o  /out/usr/bin/protoc-gen-validate . && \
    install -D ./validate/validate.proto /out/usr/include/github.com/envoyproxy/protoc-gen-validate/validate/validate.proto

ARG GRPC_GATEWAY_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway && \
    curl -sSL https://github.com/grpc-ecosystem/grpc-gateway/archive/refs/tags/${GRPC_GATEWAY_VERSION}.tar.gz | tar xz --strip 1 -C ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway && \
    cd ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway && \
    CGO_ENABLED=0 go build -ldflags '-w -s' -o /out/usr/bin/protoc-gen-grpc-gateway ./protoc-gen-grpc-gateway && \
    CGO_ENABLED=0 go build -ldflags '-w -s' -o  /out/usr/bin/protoc-gen-openapiv2 ./protoc-gen-openapiv2 && \
    mkdir -p /out/usr/include/protoc-gen-openapiv2/options && \
    install -D $(find ./protoc-gen-openapiv2/options -name '*.proto') -t /out/usr/include/protoc-gen-openapiv2/options

RUN mkdir -p ${GOPATH}/src/github.com/googleapis/googleapis && \
    curl -sSL https://github.com/googleapis/googleapis/archive/refs/heads/master.tar.gz | tar xz --strip 1 -C ${GOPATH}/src/github.com/googleapis/googleapis && \
    cd ${GOPATH}/src/github.com/googleapis/googleapis && \
    mkdir -p /out/usr/include/google/api && \
    cp -r ./google/api/*.proto /out/usr/include/google/api/ && \
    mkdir -p /out/usr/include/google/rpc/context && \
    cp -r ./google/rpc/*.proto /out/usr/include/google/rpc/ && \
    cp -r ./google/rpc/context/*.proto /out/usr/include/google/rpc/context/

ARG PROTOC_GEN_DOC_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/pseudomuto/protoc-gen-doc && \
    curl -sSL https://github.com/pseudomuto/protoc-gen-doc/archive/refs/tags/${PROTOC_GEN_DOC_VERSION}.tar.gz | tar xz --strip 1 -C ${GOPATH}/src/github.com/pseudomuto/protoc-gen-doc && \
    cd ${GOPATH}/src/github.com/pseudomuto/protoc-gen-doc && \
    CGO_ENABLED=0 go build -ldflags '-w -s' -o /out/usr/bin/protoc-gen-doc ./cmd/protoc-gen-doc

FROM alpine:${ALPINE_VERSION}
COPY --from=builder /out/ /

RUN if [[ $(arch) == *"x86_64"* ]] ;then \
    apk add --no-cache /tmp/glibc.apk && \
    rm /etc/apk/keys/sgerrand.rsa.pub /tmp/glibc.apk ; fi

RUN mkdir -p /build/proto/third_party /build/go/third_party /build/openapi /build/java /build/docs

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

RUN echo $'#!/bin/sh\nif ! [ -d ./third_party ]; then return 0; fi && find ./third_party -type f -name '*.proto' -exec protoc -I ./third_party --proto_path=/usr/include \
 --go_out /build/go/third_party --go_opt paths=source_relative \
 --go-grpc_out /build/go/third_party --go-grpc_opt paths=source_relative \
 {} \;' >> /build/build_third_party.sh

RUN echo $'#!/bin/sh\nfind ./ -not -path "./third_party/*" -type f -name '*.proto' -exec protoc -I . --proto_path=/usr/include \
 --go_out /build/go --go_opt paths=source_relative \
 --go-grpc_out /build/go --go-grpc_opt paths=source_relative \
 --grpc-gateway_out /build/go --grpc-gateway_opt logtostderr=true \
 --grpc-gateway_opt paths=source_relative --grpc-gateway_opt generate_unbound_methods=true \
 --validate_out=lang=go,paths=source_relative:/build/go \
 --openapiv2_out /build/openapi --openapiv2_opt json_names_for_fields=false --openapiv2_opt logtostderr=true \
 --java_out=/build/java \
 {} \;' >> /build/build.sh

RUN echo $'#!/bin/sh\nfor f in `find ./ -not -path "./third_party/*" -type f -name '*.proto' -print`;do \
    filename=${f##*/} && dir0=${f%/*} && dir=${dir0##*./} && mkdir -p /build/docs/${dir} && \
    protoc -I . --proto_path=/usr/include \
    --doc_out=/build/docs/${dir} --doc_opt=markdown,${filename%.proto}.md ${f};\
     done;' >> /build/build_docs.sh

RUN chmod +x /build/build.sh /build/build_third_party.sh /build/build_docs.sh
RUN chown -R nobody.nobody /build /usr/include

WORKDIR /build/proto

# the example to build the proto to test folder
# docker run --rm -v $(shell pwd)/pkg/go:/build/go -v $(shell pwd)/pkg/openapi:/build/openapi -v $(shell pwd):/build/proto nanxi/protoc:go
CMD ["/bin/sh", "-c", "/build/build.sh && /build/build_third_party.sh"]
