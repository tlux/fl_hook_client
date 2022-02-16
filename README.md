# FLHook Client

[![Build Status](https://app.travis-ci.com/tlux/fl_hook_client.svg?branch=master)](https://app.travis-ci.com/tlux/fl_hook_client)
[![Coverage Status](https://coveralls.io/repos/github/tlux/fl_hook_client/badge.svg?branch=master)](https://coveralls.io/github/tlux/fl_hook_client?branch=master)
[![Hex.pm](https://img.shields.io/hexpm/v/fl_hook_client.svg)](https://hex.pm/packages/fl_hook_client)

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
    {:fl_hook_client, "~> 0.2"}
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
    subscribers: [self()],
    tcp_adapter: :gen_tcp
  )
```

Once connected, you can send commands to the server.

```elixir
FLHook.Client.cmd(client, "readcharfile Player1")
# => {:ok, %FLHook.Result{lines: ["...", "..."]}}
```

Alternatively, you can use the tuple format for commands:

```elixir
FLHook.Client.cmd(client, {"readcharfile", ["Player1"]})
```

Additionally, any value is accepted as command argument that implements the
`FLHook.Command` protocol.

By default, also events from the server will be sent to all subscribed
processes. You can add a subscription for the current process as follows:

```elixir
FLHook.Client.subscribe(client)
```

You can also subscribe other processes:

```elixir
pid = self()

Task.async(fn ->
  FLHook.Client.subscribe(client, pid)
end)
```

Unsubscription works the same way.

The received events have the following format:

```elixir
iex> flush()
%FLHook.Event{type: "launch", params: %{"system" => "Li01", "char" => "Player"}}
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
[ExDoc](https://github.com/elixir-lang/ex_doc) and published on
[HexDocs](https://hexdocs.pm). Once published, the docs can be found at
[https://hexdocs.pm/fl_hook_client](https://hexdocs.pm/fl_hook_client).
