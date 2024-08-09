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
        open_on_start: true,
        backoff_interval: 1000,
        connect_timeout: 5000,
        password: "s3cret",
        recv_timeout: 5000,
        send_timeout: 5000

  ## Dispatch Command

  Send a command to the server and receive the result immediately:

      {:ok, %{"cash" => cash}} = FLHook.single(client, {"addcash", ["MyUsername", 10]})
      IO.puts("New cash: \#{cash} credits")

  ## Listen to Events

  Let the current process receive FLHook events:

      FLHook.subscribe(client)

      receive do
        %FLHook.Event{type: "kill", data: data} ->
          IO.inspect(data, label: "player killed")
      end
  """

  alias FLHook.Client
  alias FLHook.Dict
  alias FLHook.RowsCountError

  @client Application.compile_env(:fl_hook_client, :client, Client)

  @client_timeout :infinity

  @typedoc """
  Type representing a FLHook client process.
  """
  @type client :: FLHook.Client.client()

  @typedoc """
  Type representing a FLHook command.
  """
  @type command :: FLHook.Command.command()

  @doc since: "3.0.0"
  @spec connect(FLHook.Config.t() | Keyword.t()) :: GenServer.on_start()
  defdelegate connect(opts \\ []), to: @client, as: :start_link

  @doc since: "3.0.0"
  @spec disconnect(client, timeout) :: :ok
  defdelegate disconnect(
                client,
                timeout \\ @client_timeout
              ),
              to: @client,
              as: :close

  @doc since: "3.0.0"
  @spec connected?(client, timeout) :: boolean
  defdelegate connected?(client, timeout \\ @client_timeout), to: @client

  @doc since: "3.0.0"
  @spec event_mode?(client, timeout) :: boolean
  defdelegate event_mode?(client, timeout \\ @client_timeout), to: @client

  @deprecated "Use `exec/2` or `exec/3` instead"
  defdelegate cmd(
                client,
                command,
                timeout \\ @client_timeout
              ),
              to: __MODULE__,
              as: :exec

  @deprecated "Use `exec!/2` or `exec!/3` instead"
  defdelegate cmd!(
                client,
                command,
                timeout \\ @client_timeout
              ),
              to: __MODULE__,
              as: :exec!

  @doc """
  Sends a command to the socket and returns the result as rows of raw data.
  """
  @doc since: "3.0.0"
  @spec exec(client, command, timeout) ::
          {:ok, [binary]} | {:error, Exception.t()}
  defdelegate exec(
                client,
                command,
                timeout \\ @client_timeout
              ),
              to: @client,
              as: :cmd

  @doc """
  Sends a command to the socket and returns the result as rows of raw data.
  Raises on error.
  """
  @doc since: "3.0.0"
  @spec exec!(client, command, timeout) :: [binary] | no_return
  def exec!(client, command, timeout \\ @client_timeout) do
    client
    |> exec(command, timeout)
    |> bang!()
  end

  @doc """
  Sends a command to the socket without returning the result.
  """
  @spec run(client, command, timeout) :: :ok | {:error, Exception.t()}
  def run(client, command, timeout \\ @client_timeout) do
    with {:ok, _} <- exec(client, command, timeout), do: :ok
  end

  @doc """
  Sends a command to the socket without returning the result. Raises on error.
  """
  @spec run!(client, command, timeout) :: :ok | no_return
  def run!(client, command, timeout \\ @client_timeout) do
    client
    |> run(command, timeout)
    |> bang!()
  end

  @doc """
  Sends a command to the socket and returns the result as list of maps.
  """
  @doc since: "3.0.0"
  @spec all(client, command, Keyword.t(), timeout) ::
          {:ok, [map]} | {:error, Exception.t()}
  def all(client, command, opts \\ [], timeout \\ @client_timeout) do
    with {:ok, rows} <- cmd(client, command, timeout) do
      {:ok, Enum.map(rows, &Dict.parse(&1, opts))}
    end
  end

  @doc """
  Sends a command to the socket and returns the result as list of maps.
  Raises on error.
  """
  @doc since: "3.0.0"
  @spec all!(client, command, Keyword.t(), timeout) :: [map] | no_return
  def all!(client, command, opts \\ [], timeout \\ @client_timeout) do
    client
    |> all(command, opts, timeout)
    |> bang!()
  end

  @doc """
  Sends a command to the socket and returns the first row in the results as map.
  """
  @doc since: "3.0.0"
  @spec one(client, command, Keyword.t(), timeout) ::
          {:ok, map | nil} | {:error, Exception.t()}
  def one(client, command, opts \\ [], timeout \\ @client_timeout) do
    case exec(client, command, timeout) do
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
  @spec one!(client, command, Keyword.t(), timeout) :: map | nil
  def one!(client, command, opts \\ [], timeout \\ @client_timeout) do
    client
    |> one(command, opts, timeout)
    |> bang!()
  end

  @doc """
  Sends a command to the socket and returns the first row in the results as map.
  Returns an error when the command returns more than one row.
  """
  @doc since: "3.0.0"
  @spec single(client, command, Keyword.t(), timeout) ::
          {:ok, map} | {:error, Exception.t()}
  def single(client, command, opts \\ [], timeout \\ @client_timeout) do
    case exec(client, command, timeout) do
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
  @spec single!(client, command, Keyword.t(), timeout) :: map
  def single!(client, cmd, opts \\ [], timeout \\ @client_timeout) do
    client
    |> single(cmd, opts, timeout)
    |> bang!()
  end

  @doc """
  Registers the specified process as event listener.
  """
  @doc since: "1.0.1"
  @spec subscribe(client, pid, timeout) :: :ok
  defdelegate subscribe(
                client,
                listener \\ self(),
                timeout \\ @client_timeout
              ),
              to: @client

  @doc """
  Removes the event listener for the specified process.
  """
  @doc since: "1.0.1"
  @spec unsubscribe(client, pid, timeout) :: :ok
  defdelegate unsubscribe(
                client,
                listener \\ self(),
                timeout \\ @client_timeout
              ),
              to: @client

  defp bang!(:ok), do: :ok
  defp bang!({:ok, result}), do: result
  defp bang!({:error, error}), do: raise(error)
end
