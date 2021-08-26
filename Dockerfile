ARG ALPINE_VERSION=3.14
ARG GLIBC_VERSION=2.33-r0
ARG GO_VERSION=1.16
ARG PROTOBUF_VERSION=3.17.3
ARG PROTOC_GEN_GO_VERSION=v1.27.1
ARG PROTOC_GEN_GO_GRPC_VERSION=v1.38.1
ARG PROTOC_GEN_VALIDATE_VERSION=main
ARG GRPC_GATEWAY_VERSION=v2.5.0
ARG PROTOC_GEN_DOC_VERSION=v1.4.1
ARG GOOGLEAPIS_VERSION=master
ARG DART_VERSION=2
ARG DART_PROTOBUF_VERSION=master
ARG SWIFT_VERSION=5.4.1
ARG GRPC_SWIFT_VERSION=1.2.0
ARG GRPC_WEB_VERSION=1.2.1

FROM golang:${GO_VERSION}-alpine${ALPINE_VERSION} as builder
RUN apk add --no-cache build-base curl git upx

ARG PROTOBUF_VERSION
RUN mkdir -p /out/usr/ && curl -sSL https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERSION}/protoc-${PROTOBUF_VERSION}-linux-x86_64.zip -o /tmp/protobuf.zip  && \
    unzip -o /tmp/protobuf.zip -d /out/usr/ && \
    rm /out/usr/readme.txt

ARG GRPC_WEB_VERSION
RUN curl -sSL https://github.com/grpc/grpc-web/releases/download/${GRPC_WEB_VERSION}/protoc-gen-grpc-web-${GRPC_WEB_VERSION}-linux-x86_64 -o /out/usr/bin/protoc-gen-grpc-web && \
    chmod +x /out/usr/bin/protoc-gen-grpc-web

ARG PROTOC_GEN_GO_VERSION
RUN mkdir -p ${GOPATH}/src/google.golang.org/protobuf && \
    curl -sSL https://api.github.com/repos/protocolbuffers/protobuf-go/tarball/${PROTOC_GEN_GO_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/google.golang.org/protobuf &&\
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
RUN find /out -name "*.a" -delete -or -name "*.la" -delete

ARG GLIBC_VERSION
RUN mkdir -p /out/tmp/ /out/etc/apk/keys/
RUN curl -sSL https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /out/etc/apk/keys/sgerrand.rsa.pub  && \
    curl -sSL https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk -o /out/tmp/glibc.apk

ARG DART_VERSION
FROM google/dart:${DART_VERSION} as dart_builder
RUN apt-get update && apt-get install -y musl-tools curl

ARG DART_PROTOBUF_VERSION
RUN mkdir -p /dart-protobuf && \
    curl -sSL https://api.github.com/repos/dart-lang/protobuf/tarball/${DART_PROTOBUF_VERSION} | tar xz --strip 1 -C /dart-protobuf && \
    cd /dart-protobuf/protoc_plugin && pub install && dart2native --verbose bin/protoc_plugin.dart -o protoc_plugin && \
    install -D /dart-protobuf/protoc_plugin/protoc_plugin /out/usr/bin/protoc-gen-dart

ARG SWIFT_VERSION
FROM swift:${SWIFT_VERSION} as swift_builder
RUN apt-get update && \
    apt-get install -y unzip patchelf libnghttp2-dev curl libssl-dev zlib1g-dev

ARG GRPC_SWIFT_VERSION
RUN mkdir -p /grpc-swift && \
    curl -sSL https://api.github.com/repos/grpc/grpc-swift/tarball/${GRPC_SWIFT_VERSION} | tar xz --strip 1 -C /grpc-swift && \
    cd /grpc-swift && make && make plugins && \
    install -Ds /grpc-swift/protoc-gen-swift /protoc-gen-swift/protoc-gen-swift && \
    install -Ds /grpc-swift/protoc-gen-grpc-swift /protoc-gen-swift/protoc-gen-grpc-swift && \
    cp /lib64/ld-linux-x86-64.so.2 \
        $(ldd /protoc-gen-swift/protoc-gen-swift /protoc-gen-swift/protoc-gen-grpc-swift | awk '{print $3}' | grep /lib | sort | uniq) \
        /protoc-gen-swift/ && \
    find /protoc-gen-swift/ -name 'lib*.so*' -exec patchelf --set-rpath /protoc-gen-swift {} \; && \
    for p in protoc-gen-swift protoc-gen-grpc-swift; do \
        patchelf --set-interpreter /protoc-gen-swift/ld-linux-x86-64.so.2 /protoc-gen-swift/${p}; \
    done
RUN mkdir /out
RUN mv /protoc-gen-swift /out/protoc-gen-swift

FROM alpine:${ALPINE_VERSION}
COPY --from=builder /out/ /
COPY --from=dart_builder /out/ /
COPY --from=swift_builder /out/ /

RUN apk add --no-cache /tmp/glibc.apk && \
    rm /etc/apk/keys/sgerrand.rsa.pub /tmp/glibc.apk

RUN mkdir -p /build/proto/third_party /build/go/third_party /build/openapi /build/js /build/web

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
 --grpc-gateway_out /build/go --grpc-gateway_opt logtostderr=true \
 --grpc-gateway_opt paths=source_relative --grpc-gateway_opt generate_unbound_methods=true \
 --validate_out=lang=go,paths=source_relative:/build/go \
 --openapiv2_out /build/openapi --openapiv2_opt json_names_for_fields=false --openapiv2_opt \
logtostderr=true {} \;' >> /build/build.sh

RUN echo $'find ./ -not -path "./third_party/*" -type f -name '*.proto' -exec protoc -I . --proto_path=/usr/include \
 --js_out=import_style=commonjs:/build/web \
 --grpc-web_out=import_style=commonjs,mode=grpcwebtext:/build/web \
 {} \;' >> /build/build_web.sh
 
RUN chmod +x /build/build.sh /build/build_third_party.sh /build/build_web.sh
RUN chown -R nobody.nobody /build /usr/include

WORKDIR /build/proto

# the example to build the proto to test folder
# docker run --rm -v $(shell pwd)/pkg/go:/build/go -v $(shell pwd)/pkg/openapi:/build/openapi -v $(shell pwd):/build/proto nanxi/protoc:go
CMD ["/bin/sh", "-c", "/build/build.sh && /build/build_third_party.sh"]

