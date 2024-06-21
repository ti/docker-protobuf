# a simple protoc tool that Compatible with both arm and x86
# docker buildx create --use --name mbuild
# docker buildx build --push --platform linux/arm64,linux/amd64 --tag nanxi/protoc .
ARG ALPINE_VERSION=3.18
ARG GO_VERSION=1.21
ARG PROTOBUF_VERSION=25.1
ARG PROTOC_GEN_GO_VERSION=v1.31.0
ARG PROTOC_GEN_GO_GRPC_VERSION=v1.59.0
ARG GRPC_GATEWAY_VERSION=v2.18.1
ARG PROTOC_GEN_DOC_VERSION=v1.5.1
ARG PROTOC_GEN_VALIDATE_VERSION=v1.0.4
ARG BUF_PROTOVALIDATE_VERSION=0.6.4
ARG GRPC_WEB_VERSION=1.5.0
ARG PROTOC_GEN_JS_VERSION=3.21.2


FROM golang:${GO_VERSION}-alpine as builder
RUN apk add --no-cache curl unzip

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

ARG GRPC_GATEWAY_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway && \
    curl -sSL https://github.com/grpc-ecosystem/grpc-gateway/archive/refs/tags/${GRPC_GATEWAY_VERSION}.tar.gz | tar xz --strip 1 -C ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway && \
    cd ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway && \
    CGO_ENABLED=0 go build -ldflags '-w -s' -o /out/usr/bin/protoc-gen-grpc-gateway ./protoc-gen-grpc-gateway && \
    CGO_ENABLED=0 go build -ldflags '-w -s' -o  /out/usr/bin/protoc-gen-openapiv2 ./protoc-gen-openapiv2 && \
    mkdir -p /out/usr/include/protoc-gen-openapiv2/options && \
    install -D $(find ./protoc-gen-openapiv2/options -name '*.proto') -t /out/usr/include/protoc-gen-openapiv2/options

ARG PROTOC_GEN_DOC_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/pseudomuto/protoc-gen-doc && \
    curl -sSL https://github.com/pseudomuto/protoc-gen-doc/archive/refs/tags/${PROTOC_GEN_DOC_VERSION}.tar.gz | tar xz --strip 1 -C ${GOPATH}/src/github.com/pseudomuto/protoc-gen-doc && \
    cd ${GOPATH}/src/github.com/pseudomuto/protoc-gen-doc && \
    CGO_ENABLED=0 go build -ldflags '-w -s' -o /out/usr/bin/protoc-gen-doc ./cmd/protoc-gen-doc

ARG PROTOBUF_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/protocolbuffers/protobuf &&  \
    export ARCH=x86_64 && if [[ $(arch) == *"aarch64"* ]] ;then export ARCH=aarch_64; fi && \
    curl -sSL https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERSION}/protoc-${PROTOBUF_VERSION}-linux-${ARCH}.zip -o /tmp/protobuf.zip  && \
    unzip -o /tmp/protobuf.zip -d  ${GOPATH}/src/github.com/protocolbuffers/protobuf && \
    cd ${GOPATH}/src/github.com/protocolbuffers/protobuf && \
    cp -r ./include /out/usr/ && cp ./bin/protoc /out/usr/bin/protoc

ARG GRPC_WEB_VERSION
RUN curl -sSL https://github.com/grpc/grpc-web/releases/download/${GRPC_WEB_VERSION}/protoc-gen-grpc-web-${GRPC_WEB_VERSION}-linux-$(arch) -o /out/usr/bin/protoc-gen-grpc-web  && \
    chmod +x /out/usr/bin/protoc-gen-grpc-web

RUN mkdir -p ${GOPATH}/src/github.com/googleapis/googleapis && \
    curl -sSL https://github.com/googleapis/googleapis/archive/refs/heads/master.tar.gz | tar xz --strip 1 -C ${GOPATH}/src/github.com/googleapis/googleapis && \
    cd ${GOPATH}/src/github.com/googleapis/googleapis && \
    mkdir -p /out/usr/include/google/api && \
    cp -r ./google/api/*.proto /out/usr/include/google/api/ && \
    mkdir -p /out/usr/include/google/rpc/context && \
    cp -r ./google/rpc/*.proto /out/usr/include/google/rpc/ && \
    cp -r ./google/rpc/context/*.proto /out/usr/include/google/rpc/context/

ARG PROTOC_GEN_JS_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/protocolbuffers/protobuf-javascript &&  \
    export ARCH=x86_64 && if [[ $(arch) == *"aarch64"* ]] ;then export ARCH=aarch_64; fi && \
    curl -sSL https://github.com/protocolbuffers/protobuf-javascript/releases/download/v${PROTOC_GEN_JS_VERSION}/protobuf-javascript-${PROTOC_GEN_JS_VERSION}-linux-${ARCH}.zip -o /tmp/protobuf-javascript.zip  && \
    unzip -o /tmp/protobuf-javascript.zip -d  ${GOPATH}/src/github.com/protocolbuffers/protobuf-javascript && \
    cd ${GOPATH}/src/github.com/protocolbuffers/protobuf-javascript && \
    cp -r ./google  /out/usr/include/ && cp ./bin/protoc-gen-js /out/usr/bin/protoc-gen-js

RUN apk add --no-cache nodejs npm

RUN <<EOF
    apk add --no-cache nodejs npm
    npm install -g pkg
    npm install -g @protobuf-ts/plugin
    pkg --compress Brotli --targets node18-alpine --output /out/usr/bin/protoc-gen-ts /usr/local/bin/protoc-gen-ts
    npm uninstall -g @protobuf-ts/plugin
EOF

ARG PROTOC_GEN_JS_VERSION
RUN <<EOF
    # Skip arm64 build due to https://github.com/bazelbuild/bazel/issues/17220
    # TODO: Remove this conditional once fixed
    if [ $(arch) == *"x86"* ]; then
        echo "Start build protobuf-javascript in " $(arch)
        apk add --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/ bazel6
        apk add --no-cache build-base linux-headers
        # Build protoc-gen-js
        mkdir -p ${GOPATH}/src/github.com/protocolbuffers/protobuf-javascript
        cd ${GOPATH}/src/github.com/protocolbuffers/protobuf-javascript
        curl -sSL https://api.github.com/repos/protocolbuffers/protobuf-javascript/tarball/main | tar xz --strip 1 -C  ${GOPATH}/src/github.com/protocolbuffers/protobuf-javascript
        bazel build plugin_files
        install -D ./bazel-bin/generator/protoc-gen-js /out/usr/bin/protoc-gen-js
    fi
EOF

ARG PROTOC_GEN_VALIDATE_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/bufbuild/protoc-gen-validate && \
    curl -sSL https://github.com/bufbuild/protoc-gen-validate/archive/refs/heads/main.tar.gz | tar xz --strip 1 -C ${GOPATH}/src/github.com/bufbuild/protoc-gen-validate && \
    cd ${GOPATH}/src/github.com/bufbuild/protoc-gen-validate && \
    CGO_ENABLED=0 go build -ldflags '-w -s' -o  /out/usr/bin/protoc-gen-validate . && \
    install -D ./validate/validate.proto /out/usr/include/validate/validate.proto

ARG BUF_PROTOVALIDATE_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/bufbuild/protovalidate && \
    curl -sSL https://github.com/bufbuild/protovalidate/archive/refs/heads/main.tar.gz | tar xz --strip 1 -C ${GOPATH}/src/github.com/bufbuild/protoc-gen-validate && \
    cd ${GOPATH}/src/github.com/bufbuild/protovalidate && \
    cp -rf  ./proto/protovalidate/buf out/usr/include/buf


ARG ALPINE_VERSION
FROM alpine:${ALPINE_VERSION} as grpc_java
RUN apk add --no-cache grpc-java

ARG ALPINE_VERSION
FROM alpine:${ALPINE_VERSION}
RUN apk add --no-cache grpc-plugins
COPY --from=builder /out/ /
COPY --from=grpc_java /usr/bin/protoc-gen-grpc-java /usr/bin/protoc-gen-grpc-java

RUN ln -s /usr/bin/grpc_cpp_plugin /usr/bin/protoc-gen-grpc-cpp
RUN ln -s /usr/bin/grpc_csharp_plugin /usr/bin/protoc-gen-grpc-csharp
RUN ln -s /usr/bin/grpc_node_plugin /usr/bin/protoc-gen-grpc-js
RUN ln -s /usr/bin/grpc_objective_c_plugin /usr/bin/protoc-gen-grpc-objc
RUN ln -s /usr/bin/grpc_php_plugin /usr/bin/protoc-gen-grpc-php
RUN ln -s /usr/bin/grpc_python_plugin /usr/bin/protoc-gen-grpc-python
RUN ln -s /usr/bin/grpc_ruby_plugin /usr/bin/protoc-gen-grpc-ruby

RUN mkdir -p /build/proto/third_party /build/go/third_party /build/openapi /build/java /build/python /build/web /build/docs /build/descriptor

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

RUN echo $'#!/bin/sh\nfind ./ -not -path "./third_party/*" -type f -name '*.proto' -exec protoc -I . --proto_path=/usr/include \
 --go_out /build/go --go_opt paths=source_relative --go-grpc_out /build/go --go-grpc_opt paths=source_relative --validate_out=lang=go,paths=source_relative:/build/go \
 --openapiv2_out /build/openapi --openapiv2_opt json_names_for_fields=false --openapiv2_opt logtostderr=true \
 --python_out=/build/python --pyi_out=/build/python --python-grpc_out=/build/python --plugin=protoc-gen-python-grpc=/usr/bin/grpc_python_plugin \
 --java_out=/build/java --java-grpc_out=/build/java --plugin=protoc-gen-java-grpc=/usr/bin/protoc-gen-grpc-java \
 --grpc-gateway_out /build/go --grpc-gateway_opt logtostderr=true --grpc-gateway_opt paths=source_relative --grpc-gateway_opt generate_unbound_methods=true \
 --ts_out=/build/web --ts_opt force_server_none \
 {} \;' >> /build/build.sh

RUN apk add --no-cache gcompat
RUN echo $'#!/bin/sh\nfind ./ -not -path "./third_party/*" -type f -name '*.proto' -exec protoc -I . --proto_path=/usr/include \
   --js_out=import_style=es6:/build/web --grpc-web_out=import_style=typescript,mode=grpcweb:/build/web  \
 {} \;' >> /build/build_web.sh

RUN echo $'#!/bin/sh\nif ! [ -d ./third_party ]; then return 0; fi && find ./third_party -type f -name '*.proto' -exec protoc -I ./third_party --proto_path=/usr/include \
 --go_out /build/go/third_party --go_opt paths=source_relative --go-grpc_out /build/go/third_party --go-grpc_opt paths=source_relative \
 {} \;' >> /build/build_third_party.sh

RUN echo $'#!/bin/sh\nfor f in `find ./ -not -path "./third_party/*" -type f -name '*.proto' -print`;do \
    filename=${f##*/} && dir0=${f%/*} && dir=${dir0##*./} && mkdir -p /build/docs/${dir} && \
    protoc -I . --proto_path=/usr/include \
    --doc_out=/build/docs/${dir} --doc_opt=markdown,${filename%.proto}.md ${f};\
     done;' >> /build/build_docs.sh

RUN echo $'#!/bin/sh\nfind ./ -not -path "./third_party/*" -type f -name '*.proto' -exec protoc -I . --proto_path=/usr/include \
   --python_out=/build/python --pyi_out=/build/python --python-grpc_out=/build/python --plugin=protoc-gen-python-grpc=/usr/bin/grpc_python_plugin \
 {} \;' >> /build/build_python.sh

RUN echo $'#!/bin/sh\nprotoc -I . --include_imports --include_source_info --proto_path=/usr/include \
   --descriptor_set_out=/build/descriptor/descriptor.pb \
 $(find . -type f -name "*.proto"  ! -path "./third_party/*"  | tr '\n' ' ');' >> /build/build_descriptor.sh

RUN chmod +x /build/build.sh /build/build_third_party.sh /build/build_docs.sh /build/build_web.sh /build/build_python.sh /build/build_descriptor.sh
RUN chown -R nobody.nobody /build /usr/include

WORKDIR /build/proto

# the example to build the proto to test folder
# docker run --rm -v $(shell pwd)/pkg/go:/build/go -v $(shell pwd)/pkg/openapi:/build/openapi -v $(shell pwd):/build/proto nanxi/protoc:go
CMD ["/bin/sh", "-c", "/build/build.sh && /build/build_third_party.sh"]
