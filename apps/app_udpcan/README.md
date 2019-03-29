# UDP CAN application
Receives CAN frames from UDP devices.
Such as a *VIU* Texas board programmed by John Fredriksson.

In order to share functionality with [app_ngcan](../app_ngcan), a library [can](../can) contains shared functionality.

## Protocol
Frames are constructed in this way:

| Name            | Size (bytes)|
|:----------------|:------------|
| Frame ID        | 4           |
| Payload size    | 1           |
| Frame payload   | 8           |
| Sum             | 13          |

With total UDP datagram content size of **13** b.
Packaging and parsing of frames is done in `CanUdp`.

## Config fields
Configuration is stored is `configuration/interfaces.json` according to [this section](/signal_server/apps/util/README.md#json-format).
And this application uses the type tag `"udp"`.

| Field            | description                          | Example          |
|------------------|--------------------------------------|------------------|
| `target_host`    | IPv4 address of VIU board            | `"192.168.1.27"` |
| `target_port`    | Server port on the VIU board         | `2000`           |
| `server_port`    | Server port of local server          | `2000`           |
