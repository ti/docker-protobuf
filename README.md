# Protocol Buffers + Docker

include all golang tools

## What's included:
- https://github.com/protocolbuffers/protobuf
- https://github.com/protocolbuffers/protobuf-go
- https://github.com/envoyproxy/protoc-gen-validate
- https://github.com/grpc-ecosystem/grpc-gateway
- https://github.com/pseudomuto/protoc-gen-doc
- https://github.com/mwitkow/go-proto-validators

## Supported languages
- C
- Go

## Usage
```
$ docker run --rm -u $(sh id -u ${USER}):$(sh id -g ${USER}) -v $(pwd)/go:/build/go -v $(pwd)/openapi:/build/openapi nanxi/protoc:latest
```

