# Protocol Buffers + Docker

include all golang tools

## What's included:
- https://github.com/protocolbuffers/protobuf
- https://github.com/protocolbuffers/protobuf-go
- https://github.com/envoyproxy/protoc-gen-validate
- https://github.com/grpc-ecosystem/grpc-gateway
- https://github.com/pseudomuto/protoc-gen-doc
- https://github.com/dart-lang/protobuf

## Supported languages
- C++ (include C++ runtime and protoc)
- Java
- Python
- Objective-C
- C#
- JavaScript
- Ruby
- Go
- PHP
- Dart
- Swift
- Web

## Usage
```
$ docker run --rm -u $(sh id -u ${USER}):$(sh id -g ${USER}) -v $(pwd)/go:/build/go -v $(pwd)/openapi:/build/openapi nanxi/protoc:latest
```

