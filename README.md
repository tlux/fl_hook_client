# FLHook Client

[![Build](https://github.com/tlux/fl_hook_client/actions/workflows/elixir.yml/badge.svg)](https://github.com/tlux/fl_hook_client/actions/workflows/elixir.yml)
[![Coverage Status](https://coveralls.io/repos/github/tlux/fl_hook_client/badge.svg?branch=main)](https://coveralls.io/github/tlux/fl_hook_client?branch=main)
[![Module Version](https://img.shields.io/hexpm/v/fl_hook_client.svg)](https://hex.pm/packages/fl_hook_client)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/fl_hook_client/)
[![License](https://img.shields.io/hexpm/l/fl_hook_client.svg)](https://github.com/tlux/fl_hook_client/blob/main/LICENSE.md)
[![Last Updated](https://img.shields.io/github/last-commit/tlux/fl_hook_client.svg)](https://github.com/tlux/fl_hook_client/commits/main)

[FLHook](https://github.com/DiscoveryGC/FLHook) is a community-managed tool for
managing [Freelancer](<https://en.wikipedia.org/wiki/Freelancer_(video_game)>)
game servers. Freelancer is a pretty old game that has been released in 2003 by
Microsoft, but it still has a very committed community.

FLHook allows connecting via a socket to run commands on and receive events from
a Freelancer Server. This library provides an Elixir client for that matter. You
could use it to build web-based management interfaces or ingame chat bots, for
example.

## Use Cases

- Chat Bots
- Web-based Services
  - Character Management
  - Character Money Deposit
  - Character Cargo Deposit
- Player Tracking and Travel Journal
- Custom Cargo Missions

## Installation

The package is [available in Hex](https://hex.pm/packages/fl_hook_client) and
can be installed by adding `fl_hook_client` to your list of dependencies in
`mix.exs`:

```elixir
def deps do
  [
    {:fl_hook_client, "~> 2.0"}
  ]
end
```

## Usage

Initiate a connection to a server (with a list of all possible options):

```elixir
{:ok, client} =
  FLHook.Client.start_link(
    backoff_interval: 1234,
    codec: :unicode,
    connect_timeout: 2345,
    event_mode: true,
    host: "localhost",
    inet_adapter: :inet,
    name: CustomFLHookClient,
    password: "$3cret",
    port: 1920,
    recv_timeout: 3456,
    send_timeout: 4567,
    tcp_adapter: :gen_tcp
  )
```

Once connected, you can send commands to the server.

```elixir
FLHook.cmd(client, "readcharfile Player1")
# => {:ok, %FLHook.Result{lines: ["...", "..."]}}
```

Alternatively, you can use the tuple format for commands:

```elixir
FLHook.cmd(client, {"readcharfile", ["Player1"]})
```

Additionally, any value is accepted as command argument that implements the
`FLHook.Command` protocol.

By default, also events from the server will be sent to all subscribed
processes. You can add a listener for the current process as follows:

```elixir
FLHook.subscribe(client)
```

You can also register other processes as listeners:

```elixir
pid = self()

Task.async(fn ->
  FLHook.subscribe(client, pid)
end)
```

Unsubscription works the same way.

The received events have the following format:

```elixir
iex> flush()
%FLHook.Event{
  type: "launch",
  dict: %FLHook.Dict{"system" => "Li01", "char" => "Player"}
}
```

Generally, it is recommended to start the client as part of your supervision
tree. To do this, add a custom module using the `FLHook.Client` module.

```elixir
defmodule MyApp.FLClient do
  use FLHook.Client, otp_app: :my_app
end
```

Then, add some configuration in config.exs or your environment-specific configs.

```elixir
config :my_app, MyApp.FLClient,
  host: "localhost",
  port: 1920
```

After that, add your custom client to your application.ex.

```elixir
def start(_type, _args) do
  children = [
    MyApp.FLClient
  ]

  # ...
end
```

Voilà! You can now send commands to the same server without passing the client
process as first argument.

```elixir
MyApp.FLClient.cmd(client, "readcharfile Player1")
# => {:ok, %FLHook.Result{lines: ["...", "..."]}}
```

## Docs

Documentation can be generated with
[ExDoc](https://github.com/elixir-lang/ex_doc) and is published on
[HexDocs](https://hexdocs.pm/fl_hook_client).
