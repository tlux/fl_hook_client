# FLHook Client

[![Build Status](https://travis-ci.com/tlux/fl_hook_client.svg?branch=master)](https://travis-ci.org/tlux/fl_hook_client)
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
- Location Journal
- Custom Cargo Missions

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `fl_hook_client` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:fl_hook_client, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/fl_hook_client](https://hexdocs.pm/fl_hook_client).
