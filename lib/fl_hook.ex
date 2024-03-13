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
  alias FLHook.Result

  @doc """
  Sends a command to the socket and returns the result.
  """
  @doc since: "1.0.1"
  @spec cmd(Client.client(), Command.command()) ::
          {:ok, Result.t()} | {:error, Exception.t()}
  defdelegate cmd(client, cmd, timeout \\ :infinity), to: Client

  @doc """
  Sends a command to the socket and returns the result. Raises on error.
  """
  @doc since: "1.0.1"
  @spec cmd!(Client.client(), Command.command(), timeout) ::
          Result.t() | no_return
  defdelegate cmd!(client, cmd, timeout \\ :infinity), to: Client

  @doc """
  Registers the specified process as event listener.
  """
  @doc since: "1.0.1"
  @spec subscribe(Client.client(), pid) :: :ok
  defdelegate subscribe(client, listener \\ self()), to: Client

  @doc """
  Removes the event listener for the specified process.
  """
  @doc since: "1.0.1"
  @spec unsubscribe(Client.client(), pid) :: :ok
  defdelegate unsubscribe(client, listener \\ self()), to: Client
end
