defmodule FLHook do
  @moduledoc """
  [FLHook](https://github.com/DiscoveryGC/FLHook) is a community-managed tool
  for managing
  [Freelancer](https://en.wikipedia.org/wiki/Freelancer_(video_game)) game
  servers. Freelancer is a pretty old game that has been released in 2003 by
  Microsoft, but it still has a very committed community.

  FLHook allows connecting via a socket to run commands on and receive events
  from a Freelancer Server. This library provides an Elixir client for that
  matter. You could use it to build web-based management interfaces or ingame
  chat bots, for example.
  """

  alias FLHook.Client

  @doc """
  Prints out the help document from the server.
  """
  @spec help(Client.client()) :: :ok | no_return
  def help(client) do
    client
    |> Client.cmd!("help")
    |> to_string()
    |> IO.puts()
  end
end
