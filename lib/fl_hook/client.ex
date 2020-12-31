defmodule FLHook.Client do
  @moduledoc """
  A GenServer that connects to a FLHook socket.
  """

  use Connection

  require Logger

  alias __MODULE__
  alias FLHook.Client.Reply
  alias FLHook.Codec
  alias FLHook.CodecError
  alias FLHook.CommandError
  alias FLHook.CommandSerializer
  alias FLHook.Config
  alias FLHook.ConfigError
  alias FLHook.Event
  alias FLHook.HandshakeError
  alias FLHook.Result
  alias FLHook.SocketError
  alias FLHook.Utils

  @welcome_msg "Welcome to FLHack"

  @typedoc """
  Type representing a FLHook client process.
  """
  @type client :: GenServer.server()

  @typedoc """
  Type describing an error that occurs when a command fails.
  """
  @type cmd_error :: CodecError.t() | CommandError.t() | SocketError.t()

  @doc """
  Connects to a FLHook socket.
  """
  @callback start_link(opts :: Keyword.t()) :: GenServer.on_start()

  @doc """
  Closes the connection to the FLHook socket.
  """
  @callback close() :: :ok

  @doc """
  Determines whether the client is currently connected to a FLHook socket.
  """
  @callback connected?() :: boolean

  @doc """
  Sends a command to the server and returns the result.
  """
  @callback cmd(cmd :: FLHook.command()) ::
              {:ok, Result.t()} | {:error, cmd_error}

  @doc """
  Sends a command to the server and returns the result. Raises when the command
  fails.
  """
  @callback cmd!(cmd :: FLHook.command()) :: Result.t() | no_return

  @doc """
  Lets the current process subscribe to events emitted by the FLHook client.
  """
  @callback subscribe() :: :ok

  @doc """
  Lets the specified process subscribe to events emitted by the FLHook client.
  """
  @callback subscribe(subscriber :: GenServer.server()) :: :ok

  @doc """
  Lets the current process unsubscribe from events emitted by the FLHook client.
  """
  @callback unsubscribe() :: :ok

  @doc """
  Lets the specified process unsubscribe from events emitted by the FLHook
  client.
  """
  @callback unsubscribe(subscriber :: GenServer.server()) :: :ok

  defmacro __using__(opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)

    quote do
      @behaviour Client

      @doc false
      @spec __config__() :: Config.t()
      def __config__ do
        unquote(otp_app)
        |> Application.get_env(__MODULE__, [])
        |> Config.new()
      end

      @doc false
      @spec child_spec(term) :: Supervisor.child_spec()
      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]}
        }
      end

      @impl Client
      def start_link(opts \\ []) do
        opts = Keyword.put_new(opts, :name, __MODULE__)
        Client.start_link(__config__(), opts)
      end

      @impl Client
      def close do
        Client.close(__MODULE__)
      end

      @impl Client
      def connected? do
        Client.connected?(__MODULE__)
      end

      @impl Client
      def cmd(cmd) do
        Client.cmd(__MODULE__, cmd)
      end

      @impl Client
      def cmd!(cmd) do
        Client.cmd!(__MODULE__, cmd)
      end

      @impl Client
      def subscribe do
        Client.subscribe(__MODULE__)
      end

      @impl Client
      def subscribe(subscriber) do
        Client.subscribe(__MODULE__, subscriber)
      end

      @impl Client
      def unsubscribe do
        Client.unsubscribe(__MODULE__)
      end

      @impl Client
      def unsubscribe(subscriber) do
        Client.unsubscribe(__MODULE__, subscriber)
      end
    end
  end

  @spec start_link(Config.t() | Keyword.t()) :: GenServer.on_start()
  def start_link(%Config{} = config) do
    start_link(config, [])
  end

  def start_link(opts) when is_list(opts) do
    {opts, init_opts} = Keyword.split(opts, [:name])
    config = Config.new(init_opts)
    start_link(config, opts)
  end

  @spec start_link(Config.t(), Keyword.t()) :: GenServer.on_start()
  def start_link(%Config{} = config, opts) do
    Connection.start_link(__MODULE__, config, opts)
  end

  @spec close(client) :: :ok
  def close(client) do
    Connection.call(client, :close)
  end

  @spec connected?(client) :: boolean
  def connected?(client) do
    Connection.call(client, :connected?)
  end

  @spec cmd(client, FLHook.command()) ::
          {:ok, Result.t()} | {:error, cmd_error}
  def cmd(client, cmd) do
    Connection.call(client, {:cmd, CommandSerializer.to_string(cmd)})
  end

  @spec cmd!(client, FLHook.command()) :: Result.t() | no_return
  def cmd!(client, cmd) do
    case cmd(client, cmd) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @spec subscribe(client, GenServer.server()) :: :ok
  def subscribe(client, subscriber \\ self()) do
    Connection.call(client, {:subscribe, subscriber})
  end

  @spec unsubscribe(client, GenServer.server()) :: :ok
  def unsubscribe(client, subscriber \\ self()) do
    Connection.call(client, {:unsubscribe, subscriber})
  end

  # Child Spec

  @doc false
  @spec child_spec(term) :: Supervisor.child_spec()
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  # Callbacks

  @impl true
  def init(config) do
    if config.password do
      subscriptions =
        Map.new(config.subscribers, fn subscriber ->
          {subscriber, Process.monitor(subscriber)}
        end)

      {:connect, nil,
       %{
         config: config,
         queue: nil,
         socket: nil,
         subscriptions: subscriptions
       }}
    else
      {:stop, %ConfigError{message: "No password specified"}}
    end
  end

  @impl true
  def connect(_info, %{config: config} = state) do
    case socket_connect(config) do
      {:ok, socket} ->
        after_connect(%{state | queue: :queue.new(), socket: socket})

      {:error, error} ->
        log_error(error, config)
        {:backoff, config.backoff_interval, state}
    end
  end

  @impl true
  def disconnect(info, state) do
    if state.socket do
      :ok = state.config.tcp_adapter.close(state.socket)
    end

    state = %{state | socket: nil}

    case info do
      {:close, from} ->
        Connection.reply(from, :ok)

      error ->
        log_error(error, state.config)
    end

    {:connect, :reconnect, state}
  end

  @impl true
  def terminate(_reason, state) do
    if state.socket do
      :ok = state.config.tcp_adapter.close(state.socket)
    end
  end

  @impl true
  def handle_call(:connected?, _from, state) do
    {:reply, !is_nil(state.socket), state}
  end

  def handle_call(:close, from, state) do
    {:disconnect, {:close, from}, state}
  end

  def handle_call({:cmd, _cmd}, _from, %{socket: nil} = state) do
    {:reply, {:error, %SocketError{reason: :closed}}, state}
  end

  def handle_call({:cmd, cmd}, from, state) do
    case send_cmd(state.socket, state.config, cmd) do
      :ok ->
        queue = :queue.in(%Reply{client: from}, state.queue)
        {:noreply, %{state | queue: queue}}

      error ->
        {:reply, error, state}
    end
  end

  def handle_call({:subscribe, subscriber}, _from, state) do
    subscriptions =
      Map.put_new_lazy(state.subscriptions, subscriber, fn ->
        Process.monitor(subscriber)
      end)

    {:reply, :ok, %{state | subscriptions: subscriptions}}
  end

  def handle_call({:unsubscribe, subscriber}, _from, state) do
    subscriptions =
      case Map.pop(state.subscriptions, subscriber) do
        {nil, subscriptions} ->
          subscriptions

        {monitor_ref, subscriptions} ->
          Process.demonitor(monitor_ref, [:flush])
          subscriptions
      end

    {:reply, :ok, %{state | subscriptions: subscriptions}}
  end

  @impl true
  def handle_info({:tcp, socket, msg}, state) do
    state.config.inet_adapter.setopts(socket, active: :once)

    case Codec.decode(state.config.codec, msg) do
      {:ok, msg} ->
        case Event.parse(msg) do
          {:ok, event} ->
            handle_event(event, state)

          :error ->
            handle_cmd_resp(msg, state)
        end

      {:error, error} ->
        log_error(error, state.config)
        {:stop, error, state}
    end
  end

  def handle_info({:tcp_closed, _socket}, state) do
    {:disconnect, %SocketError{reason: :closed}, state}
  end

  def handle_info({:tcp_error, _socket, reason}, state) do
    {:disconnect, %SocketError{reason: reason}, state}
  end

  def handle_info({:DOWN, monitor_ref, :process, subscriber, _info}, state) do
    {^monitor_ref, subscriptions} = Map.pop(state.subscriptions, subscriber)
    {:noreply, %{state | subscriptions: subscriptions}}
  end

  defp handle_event(event, state) do
    Enum.each(state.subscriptions, fn {subscriber, _monitor} ->
      send(subscriber, event)
    end)

    {:noreply, state}
  end

  defp handle_cmd_resp(msg, state) do
    case :queue.out(state.queue) do
      {{:value, reply}, new_queue} ->
        case Reply.add_chunk(reply, msg) do
          %{status: :pending} = reply ->
            {:noreply, %{state | queue: :queue.in_r(reply, new_queue)}}

          %{status: :ok} = reply ->
            GenServer.reply(
              reply.client,
              {:ok, Reply.to_result(reply)}
            )

            {:noreply, %{state | queue: new_queue}}

          %{status: {:error, detail}} ->
            Connection.reply(
              reply.client,
              {:error, %CommandError{detail: detail}}
            )

            {:noreply, %{state | queue: new_queue}}
        end

      {:empty, _queue} ->
        # should never happen
        {:noreply, state}
    end
  end

  # Helpers

  defp socket_connect(config) do
    with {:error, reason} <-
           config.tcp_adapter.connect(
             to_charlist(config.host),
             config.port,
             [:binary, active: false, send_timeout: config.send_timeout],
             config.connect_timeout
           ) do
      {:error, %SocketError{reason: reason}}
    end
  end

  defp after_connect(state) do
    with :ok <- verify_welcome_msg(state),
         :ok <- authenticate(state),
         :ok <- event_mode(state) do
      :ok = state.config.tcp_adapter.controlling_process(state.socket, self())
      state.config.inet_adapter.setopts(state.socket, active: :once)
      {:ok, state}
    else
      {:error, error} ->
        state.config.tcp_adapter.close(state.socket)
        log_error(error, state.config)
        {:stop, error, %{state | socket: nil}}
    end
  end

  defp read_chunk(socket, config) do
    with {:socket, {:ok, value}} <-
           {:socket,
            config.tcp_adapter.recv(socket, 0, config.handshake_recv_timeout)},
         {:codec, {:ok, decoded}} <- {:codec, Codec.decode(config.codec, value)} do
      {:ok, decoded}
    else
      {:codec, error} -> error
      {:socket, {:error, reason}} -> {:error, %SocketError{reason: reason}}
    end
  end

  defp read_cmd_result(socket, config) do
    case do_read_cmd_result(%Reply{}, socket, config) do
      %Reply{status: :ok} = reply ->
        {:ok, Reply.to_result(reply)}

      %Reply{status: {:error, detail}} ->
        {:error, %CommandError{detail: detail}}

      error ->
        error
    end
  end

  defp do_read_cmd_result(%Reply{status: :pending} = reply, socket, config) do
    with {:ok, chunk} <- read_chunk(socket, config) do
      reply
      |> Reply.add_chunk(chunk)
      |> do_read_cmd_result(socket, config)
    end
  end

  defp do_read_cmd_result(%Reply{} = reply, _socket, _config), do: reply

  defp send_msg(socket, config, value) do
    with {:codec, {:ok, encoded}} <-
           {:codec, Codec.encode(config.codec, value)},
         {:socket, :ok} <- {:socket, config.tcp_adapter.send(socket, encoded)} do
      :ok
    else
      {:codec, error} -> error
      {:socket, {:error, reason}} -> {:error, %SocketError{reason: reason}}
    end
  end

  defp send_cmd(socket, config, cmd) do
    send_msg(socket, config, cmd <> Utils.line_sep())
  end

  defp cmd_passive(socket, config, cmd) do
    with :ok <- send_cmd(socket, config, CommandSerializer.to_string(cmd)),
         {:ok, result} <- read_cmd_result(socket, config) do
      {:ok, result}
    end
  end

  defp verify_welcome_msg(state) do
    case read_chunk(state.socket, state.config) do
      {:ok, @welcome_msg <> _} -> :ok
      {:ok, message} -> {:error, %HandshakeError{actual_message: message}}
      error -> error
    end
  end

  defp authenticate(state) do
    with {:ok, _} <-
           cmd_passive(
             state.socket,
             state.config,
             {"pass", [state.config.password]}
           ) do
      :ok
    end
  end

  defp event_mode(%{config: %{event_mode: false}}), do: :ok

  defp event_mode(state) do
    with {:ok, _} <- cmd_passive(state.socket, state.config, "eventmode") do
      :ok
    end
  end

  defp log_error(error, config) do
    Logger.error(
      "FLHook (#{config.host}:#{config.port}): #{Exception.message(error)}"
    )
  end
end
