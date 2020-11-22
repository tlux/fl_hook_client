defmodule FLHook do
  @moduledoc """
  Documentation for `FLHook`.
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
