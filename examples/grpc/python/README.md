# tiny grpc python example

## Installation, configuration

start the server and make sure it uses [configuration file:](config/interfaces.json)

inspiration from
https://grpc.io/docs/tutorials/basic/python.html


proto files are available in: [signal_server/apps/grpc_service/proto_files/](/signal_server/apps/grpc_service/proto_files/)

## Setup
pip install grpcio-tools

to re-generate files (already generated in the [generated](generated/) folder)

```bash
python -m grpc_tools.protoc -I../../../apps/grpc_service/proto_files --python_out=./generated --grpc_python_out=./generated ../../../apps/grpc_service/proto_files/*
```

## Run
modify localhost in the sample code to the ip where your server is running.
run the simple_example.sh from your terminal.
```bash
python simple_example.sh
```

make sure you have can traffic running eg "cangen vcan0  -v -g 4" check root readme. Have patience.
