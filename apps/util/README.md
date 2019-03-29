# Util

A module for common project wide utilities.

## Configuration `Util.Config`
During the start of the umbrella project `signal_server`, this module should start before any other.
For the simple reason that the configuration should be read before other modules have access to it.

Ensure correct start order in terms of the `util` application by adding this line to `mix.exs`:
```elixir
{:util, in_umbrella: true},
```
Add the line to `deps` array.

### JSON format
The local configuration file `configuration/interfaces.json` has to have the correct structure in order to work.
Have a look at the [default configuration file](/signal_server/configuration/interfaces.json) to get a understanding of the structure.

I/O communicating with the signal broker have their configuration under the tag `chains`.
Where each section has their type of I/O defined by the tag `type`.

Each type of I/O have their own set of fields in their section.
Look at the documentation for each application to see what fields they have.

Shared parameters:

| Field                | Description                          | Example       |
|----------------------|--------------------------------------|---------------|
| `type`               | Type of I/O                          | `"udp"`       |
| `device_name`        | Internal programmatic name of I/O    | `"can2"`      |
| `namespace`          | Namespace for this I/O               | `"bodycan"`   |
| `dbc_file`           | Path of vector `.dbc` file           | `"body.dbc"`  |
| `human_file`       | Path of human `.json` file         | `"body.json"` |
| `fixed_payload_size` | Set fixed payload size in bytes      | `8`           |

For `app_ngcan` `device_name` is the name of the CAN interface.

> Hint:
> [Fields for `app_ngcan`](/signal_server/apps/app_ngcan/README.md#config-fields)
> and
> [fields for `app_updcan`](/signal_server/apps/app_udpcan/README.md#config-fields).

## Forwarder `Util.Forwarder`
Synchronous testing in a asynchronous world.
As described here: <http://openmymind.net/Testing-Asynchronous-Code-In-Elixir/>.
As a result of using this pattern, there should not be any need for putting `:timer.sleep` calls in the unit tests.
Thus removing race conditions that *sometimes* make the CI pipeline fail.
