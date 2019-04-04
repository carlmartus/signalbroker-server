# Signalbroker

Development tool to access can/lin and other buses using grpc which allows usage of preferred language.

## Disclaimer

Documentaion is still ongoing, Project is operational but custom dbc/ldf/human fields are required.

## Hardware

The software can execute on any linux with socketcan. On hosts without hardware can interfaces can be configured using:
```
sudo modprobe vcan
sudo ip link add dev vcan0 type vcan
sudo ifconfig vcan0 up
```

System is configured using [interfaces.json](configuration/interfaces.json)

extensive reference can be found here [link](configuration/interfaces_referense.json)

## Real deal

In order to access real can the following hardware can be used.

Suggested hardware
* Raspberry pi
* [can shield](https://copperhilltech.com/pican2-duo-can-bus-board-for-raspberry-pi-2-3/)
* [lin DYI](https://gitlab.cm.volvocars.biz/SABBASPO/volvo-linbus)

Works is ongoing for canfd support which is in experimental stage.
* [canfd shield](https://copperhilltech.com/pican-fd-can-bus-fd-duo-board-with-real-time-clock-for-raspberry-pi/)

## Accessing the server

To get aquainted to the system the easiest way to get going is by checking out the simple [telnet guide](apps/app_telnet/README.md)

However, the preferred way of accessing the system is by using grpc. Follow this [link](apps/app_telnet/README.md)

## Starting the server

* [Install elixir](https://elixir-lang.org/install.html)
* Clone this repository
* Make sure your configuration/interfaces.json makes sense (or try out of the box)
* Start the software by doing

```
mix deps.get
iex -S mix
```

## Playback for off line purposes

On your linux
```
apt-get install can-utils
```
record can from a real network
```
candump -L can0 > myfile.log
```
once you configured your interfaces.json to use virtual can interfaces by setting using vcan instead of can just play back your recorded file
```
canplayer vcan0=can0 -I myfile.log
```

## Running examples with fake data

install can-utils as described above the generate fake data using:
```
cangen vcan0  -v -g 4
```

## TODO
- [ ] Provide pre build docker image
- [x] Add default configuration
- [ ] Add grpc sample code
