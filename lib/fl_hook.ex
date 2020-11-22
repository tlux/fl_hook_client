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
  alias FLHook.Result

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

  @doc """
  Reads the charfile of the specified player.
  """
  @spec readcharfile(Client.client(), String.t()) ::
          {:ok, String.t()} | {:error, Client.cmd_error()}
  def readcharfile(client, player) do
    with {:ok, result} <- Client.cmd(client, {"readcharfile", [player]}) do
      {:ok, Result.file!(result)}
    end
  end

  @doc """
  Writes the charfile of the specified player using the given content string.
  """
  @spec writecharfile(Client.client(), String.t(), String.t()) ::
          :ok | {:error, Client.cmd_error()}
  def writecharfile(client, player, contents) do
    with {:ok, _result} <-
           Client.cmd(client, {"writecharfile", [player, contents]}) do
      :ok
    end
  end
end
