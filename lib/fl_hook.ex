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

  ## Connect to Server

      {:ok, client} = FLHook.Client.start_link(
        host: "myserver.com",
        password: "s3cret",
      )

  Alternatively, create your own module that you can configure in your
  application.

      defmodule MyFLClient do
        use FLHook.Client
      end

  Add the client to your supervision tree:

      defmodule MyApp.Application do
        use Application

        def start(_type, _args) do
          Supervisor.start_link(
            [MyFLClient],
            strategy: :one_for_one,
            name: MyApp.Supervisor
          )
        end
      end

  In your config:

      import Config

      config :my_app, MyFLClient,
        host: "localhost",
        port: 1920,
        event_mode: true,
        connect_on_start: true,
        backoff_interval: 1000,
        connect_timeout: 5000,
        password: "s3cret",
        recv_timeout: 5000,
        send_timeout: 5000

  ## Dispatch Command

  Send a command to the server and receive the result immediately:

      {:ok, result} = FLHook.cmd(client, {"addcash", ["MyUsername", 10]})
      new_cash = FLHook.Result.param!(result, "cash")
      IO.puts("New cash: \#{new_cash} credits")

  ## Listen to Events

  Let the current process receive FLHook events:

      FLHook.subscribe(client)

      receive do
        %FLHook.Event{type: "kill", dict: dict} ->
          IO.inspect(dict, label: "player killed")
      end
  """

  alias FLHook.Client
  alias FLHook.Command
  alias FLHook.Dict
  alias FLHook.RowsCountError

  @typedoc """
  Type representing a FLHook client process.
  """
  @type client :: FLHook.Client.client()

  @doc """
  Sends a command to the socket and returns the result.
  """
  @doc since: "1.0.1"
  @spec cmd(client, Command.command()) ::
          {:ok, [binary]} | {:error, Exception.t()}
  defdelegate cmd(client, cmd, timeout \\ :infinity), to: Client

  @doc """
  Sends a command to the socket and returns the result. Raises on error.
  """
  @doc since: "1.0.1"
  @spec cmd!(client, Command.command(), timeout) ::
          [binary] | no_return
  def cmd!(client, cmd, timeout \\ :infinity) do
    client
    |> cmd(cmd, timeout)
    |> bang!()
  end

  @doc """
  Registers the specified process as event listener.
  """
  @doc since: "1.0.1"
  @spec subscribe(client, pid) :: :ok
  defdelegate subscribe(client, listener \\ self()), to: Client

  @doc """
  Removes the event listener for the specified process.
  """
  @doc since: "1.0.1"
  @spec unsubscribe(client, pid) :: :ok
  defdelegate unsubscribe(client, listener \\ self()), to: Client

  @doc """
  Sends a command to the socket and returns the result as list of maps.
  """
  @doc since: "3.0.0"
  @spec all(client, Command.command(), Keyword.t(), timeout) ::
          {:ok, [map]} | {:error, Exception.t()}
  def all(client, cmd, opts \\ [], timeout \\ :infinity) do
    with {:ok, rows} <- cmd(client, cmd, timeout) do
      {:ok, Enum.map(rows, &Dict.parse(&1, opts))}
    end
  end

  @doc """
  Sends a command to the socket and returns the result as list of maps.
  Raises on error.
  """
  @doc since: "3.0.0"
  def all!(client, cmd, opts \\ [], timeout \\ :infinity) do
    client
    |> all(cmd, opts, timeout)
    |> bang!()
  end

  @doc """
  Sends a command to the socket and returns the first row in the results as map.
  """
  @doc since: "3.0.0"
  @spec one(client, Command.command(), Keyword.t(), timeout) ::
          {:ok, map | nil} | {:error, Exception.t()}
  def one(client, cmd, opts \\ [], timeout \\ :infinity) do
    case cmd(client, cmd, timeout) do
      {:ok, []} -> {:ok, nil}
      {:ok, [row | _]} -> {:ok, Dict.parse(row, opts)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Sends a command to the socket and returns the first row in the results as map.
  Raises on error.
  """
  @doc since: "3.0.0"
  @spec one!(client, Command.command(), Keyword.t(), timeout) :: map | nil
  def one!(client, cmd, opts \\ [], timeout \\ :infinity) do
    client
    |> one(cmd, opts, timeout)
    |> bang!()
  end

  @doc """
  Sends a command to the socket and returns the first row in the results as map.
  Returns an error when the command returns more than one row.
  """
  @doc since: "3.0.0"
  @spec single(client, Command.command(), Keyword.t(), timeout) ::
          {:ok, map} | {:error, Exception.t()}
  def single(client, cmd, opts \\ [], timeout \\ :infinity) do
    case cmd(client, cmd, timeout) do
      {:ok, [row]} ->
        {:ok, Dict.parse(row, opts)}

      {:ok, rows} when is_list(rows) ->
        {:error, %RowsCountError{actual: length(rows), expected: 1}}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Sends a command to the socket and returns the first row in the results as map.
  Raises an error when the command returns no rows or more than one row.
  """
  @doc since: "3.0.0"
  @spec single!(client, Command.command(), Keyword.t(), timeout) :: map
  def single!(client, cmd, opts \\ [], timeout \\ :infinity) do
    client
    |> single(cmd, opts, timeout)
    |> bang!()
  end

  defp bang!({:ok, result}), do: result
  defp bang!({:error, error}), do: raise(error)
end
