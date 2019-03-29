# Telnet server
A TCP server accepting *JSON* formated commands.

The signal broker accepts TCP connections after a proper start up.
The default port is `4040`.
Given that the signal broker is being run on `localhost`.
Connect with `telnet`:

```
telnet localhost 4040
```

After a successful connection, commands can be send.
A full list of available commands can be found below in [command list](#command-list).

## [Config fields](/signal_server/apps/util/README.md#json-format)
And this application uses one tag under the section `gateway`.

| Field             | description                         | Example    |
|-------------------|-------------------------------------|------------|
| `tcp_socket_port` | TCP server port number to listen on | `4040`     |

## Command list
Many commands have a optional `namespace` tag.
If this tag is not specified, the default name space will be used. Synchronous command allows optional `userdata` tag, this allows the client to track it's requests

### Signal broker commands
The first line specifies a example.
If there's a second line, that is the response.

#### Subscribe to signals
```json
{"command": "subscribe", "signals": ["a", "b"], "namespace" : "can1"}
```
Subscribe and receive events from signal `a` and `b` on name space `can1`.
Name space is optional.

#### Unsubscribe to signals
```json
{"command": "unsubscribe", "signals": ["a", "b"], "namespace" : "can1"}
```
unsubscribe and stop receiving events from signal `a`, `b` on name space `can1`.
Name space is optional.

#### Write values
```json
{"command" : "write", "signals" : {"a": 4, "b": 5}, "namespace": "can1"}
```
Write value `4` and `5` to signal `a` and `b` on name space `can1`.
Name space is optional.

#### Read values
```json
{"command" : "read", "signals" : ["a", "b"], "namespace": "can1", "userdata" : "your_data"}
{"result_read":  {"a": 42}, "userdata" : "your_data"}
```
Read values on signals `a` and `b` on name space `can1`.
Name space is optional.
In this case, the response is that `a` is `42`.

#### List signals
```json
{"command" : "list", "namespace": "can1", "userdata" : "your_data"}
{"signals": ["a", "b", "c"], "userdata" : "your_data"}
```
List all signals on name space `can1`.
Name space is optional.
Here the response is a list of signals: `a`, `b` and `c`.

#### List signals with specific tag (optional)
```json
{"command" : "list", "namespace": "can1", "userdata" : "your_data", "tag" : "frame"}
{"signals": ["a", "b", "c"], "userdata" : "your_data"}
```
List all signals on name space `can1` which are frames.
Name space is optional.
Here the response is a list of signals: `a`, `b` and `c`.
Tag can also be
```json
"tag" : "raw"
```


#### Show configuration
```json
{"command" : "get_configuration", "userdata" : "your_data"}
{"configuration": {"a":{"type":"virtual"},"b":{"type":"can"},"c":{"type":"udp"},"d":{"type":"lin"},"e":{"type":"lin"}}, "userdata" : "your_data"}
```

Show the configuration.
Here the response is a list of namespaces and their types.


### LIN commands

#### List buses
```json
{"lin": ["list_buses"]}
["Lin"]
```
List all available LIN buses.
Response is a bus `Lin`.

#### List schedules
```json
{"lin": ["list_schedules", "Lin"]}
```
List available schedules for LIN bus `Lin`.

#### Start scheduler
```json
{"lin": ["start", "Lin"]}
["ok"]
```
Start scheduling on LIN bus `Lin`.

#### Stop scheduler
```json
{"lin": ["stop", "Lin"]}
["ok"]
```
Stop scheduling on LIN bus `Lin`.

#### Load scheduler
```json
{"lin": ["load_schedule", "Lin", "CcmLin18ScheduleTable1"]}
["ok"]
```
Load and run scheduler `CcmLin18ScheduleTable1` indefinetly for LIN bus `Lin`.

```json
{"lin": ["load_schedule", "Lin", "CcmLin18ScheduleTable1", 3]}
["ok"]
```
Load and run scheduler `CcmLin18ScheduleTable1` `3` times for LIN bus `Lin`.
After 3 runs, the scheduler will go back to previously set scheduler that is set to run indefinetly.
