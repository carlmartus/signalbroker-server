# Car5g

**This application is uded for 5g car**

## Installation

start the server and make sure it uses [configuration file:](config/intefaces.json)

### Prerequisites

Signalbroker running with a can shield, get upp and running using the prebuild binaries. Relevant network is SafetyCANexposed so one physical interface is needed.


### configuration

### running

Copy the car5g folder to the host and start the app from the car5g folder using

```elixir
iex -S mix
```
or
```elixir
mix run --no-halt
```

## Description

The application subscribes to a few signals according to the 5g car specification.
Subscription is done using grpc to the sinalbroker. Gprc host adress is "localhost:50051" which currently assumes that this app runs on them same machine as the sinalbroker.

The subscribed signals are then dispatched every 100ms to 192.168.111.1:2017 which is the host box.

The raspberry will be assigned ip address from the host box.

## Reference: generation of the ex files from the proto files:

from this folder
```bash
protoc -I ../../../../apps/grpc_service/proto_files/  --elixir_out=plugins=grpc:./lib/proto_files ../../../../apps/grpc_service/proto_files/*.proto
```
