defmodule FLHook.Client do
  @moduledoc """
  A client to connect to a FLHook socket.
  """

  use Connection

  require Logger

  alias __MODULE__
  alias FLHook.Client.Reply
  alias FLHook.Codec
  alias FLHook.Command
  alias FLHook.CommandError
  alias FLHook.CommandSerializer
  alias FLHook.Config
  alias FLHook.ConfigError
  alias FLHook.Event
  alias FLHook.HandshakeError
  alias FLHook.SocketError
  alias FLHook.Utils

  @welcome_msg "Welcome to FLHack"
  @client_timeout :infinity

  @typedoc """
  Type representing a FLHook client process.
  """
  @type client :: GenServer.server()

  defmacro __using__(opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)

    quote location: :keep do
      @doc false
      @spec __config__() :: Config.t()
      def __config__ do
        unquote(otp_app)
        |> Application.get_env(__MODULE__, [])
        |> Config.new()
      end

      @doc """
      Starts the FLHook client.
      """
      @spec start_link(Keyword.t()) :: GenServer.on_start()
      def start_link(opts \\ []) do
        opts = Keyword.put_new(opts, :name, __MODULE__)
        Client.start_link(__config__(), opts)
      end

      @doc """
      Default child specification for the FLHook client.
      """
      @spec child_spec(term) :: Supervisor.child_spec()
      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]}
        }
      end

      defoverridable child_spec: 1
    end
  end

  @doc """
  Starts the FLHook client using the given config or options.
  """
  @spec start_link(Config.t() | Keyword.t()) :: GenServer.on_start()
  def start_link(%Config{} = config) do
    start_link(config, [])
  end

  def start_link(opts) when is_list(opts) do
    {config_opts, start_opts} =
      Keyword.split(opts, Map.keys(Config.__struct__()))

    config = Config.new(config_opts)
    start_link(config, start_opts)
  end

  @doc """
  Starts the FLHook client using the given config and options.
  """
  @spec start_link(Config.t(), GenServer.options()) :: GenServer.on_start()
  def start_link(%Config{} = config, opts) do
    Connection.start_link(__MODULE__, config, opts)
  end

  @doc """
  Opens the connection.
  """
  @spec open(client, timeout) :: :ok | {:error, Exception.t()}
  def open(client, timeout \\ @client_timeout) do
    Connection.call(client, :open, timeout)
  end

  @doc """
  Closes the connection.
  """
  @spec close(client, timeout) :: :ok
  def close(client, timeout \\ @client_timeout) do
    Connection.call(client, :close, timeout)
  end

  @doc """
  Determines whether the socket is connected.
  """
  @spec connected?(client, timeout) :: boolean
  def connected?(client, timeout \\ @client_timeout) do
    Connection.call(client, :connected?, timeout)
  end

  @doc false
  @spec event_mode?(client, timeout) :: boolean
  def event_mode?(client, timeout \\ @client_timeout) do
    Connection.call(client, :event_mode?, timeout)
  end

  @doc false
  @spec cmd(client, Command.command(), timeout) ::
          {:ok, [binary]} | {:error, Exception.t()}
  def cmd(client, cmd, timeout \\ @client_timeout) do
    Connection.call(client, {:cmd, CommandSerializer.to_string(cmd)}, timeout)
  end

  @doc false
  @spec subscribe(client, pid, timeout) :: :ok
  def subscribe(client, listener \\ self(), timeout \\ @client_timeout) do
    Connection.call(client, {:subscribe, listener}, timeout)
  end

  @doc false
  @spec unsubscribe(client, pid, timeout) :: :ok
  def unsubscribe(client, listener \\ self(), timeout \\ @client_timeout) do
    Connection.call(client, {:unsubscribe, listener}, timeout)
  end

  # Child Spec

  @doc """
  The child specification for a FLHook client.
  """
  @spec child_spec(term) :: Supervisor.child_spec()
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  # Callbacks

  @impl true
  def init(%{password: nil}) do
    {:stop, %ConfigError{message: "No password specified"}}
  end

  def init(config) do
    state = %{
      config: config,
      queue: nil,
      recv_timeout_ref: nil,
      socket: nil,
      listeners: %{}
    }

    if config.connect_on_start do
      {:connect, :init, state}
    else
      {:ok, state}
    end
  end

  @impl true
  def connect(info, %{config: config} = state) do
    case socket_connect(config) do
      {:ok, socket} ->
        with :ok <- verify_welcome_msg(socket, config),
             :ok <- authenticate(socket, config),
             :ok <- event_mode(socket, config) do
          :ok = config.tcp_adapter.controlling_process(socket, self())

          config.inet_adapter.setopts(socket, active: :once)

          with {:open, from} <- info do
            Connection.reply(from, :ok)
          end

          {:ok, %{state | queue: :queue.new(), socket: socket}}
        else
          {:error, error} ->
            config.tcp_adapter.close(socket)
            state = %{state | socket: nil}

            case info do
              {:open, from} ->
                Connection.reply(from, {:error, error})
                {:ok, state}

              _ ->
                log_error(error, config)
                {:stop, error, state}
            end
        end

      {:error, error} ->
        case info do
          {:open, from} ->
            Connection.reply(from, {:error, error})
            {:ok, state}

          _ ->
            log_error(error, config)
            {:backoff, config.backoff_interval, state}
        end
    end
  end

  @impl true
  def disconnect(info, state) do
    maybe_cancel_timer(state.recv_timeout_ref)

    if state.socket do
      :ok = state.config.tcp_adapter.close(state.socket)
    end

    state = %{state | socket: nil}

    case info do
      {:close, from} ->
        Connection.reply(from, :ok)
        {:noconnect, state}

      error ->
        log_error(error, state.config)
        {:connect, :reconnect, state}
    end
  end

  @impl true
  def terminate(_reason, state) do
    maybe_cancel_timer(state.recv_timeout_ref)

    if state.socket do
      :ok = state.config.tcp_adapter.close(state.socket)
    end
  end

  @impl true
  def handle_call(:connected?, _from, state) do
    {:reply, !is_nil(state.socket), state}
  end

  def handle_call(:event_mode?, _from, state) do
    {:reply, state.config.event_mode, state}
  end

  def handle_call(:open, from, state) do
    {:connect, {:open, from}, state}
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

        recv_timeout_ref =
          Process.send_after(self(), :timeout, state.config.recv_timeout)

        {:noreply, %{state | queue: queue, recv_timeout_ref: recv_timeout_ref}}

      error ->
        {:reply, error, state}
    end
  end

  def handle_call({:subscribe, listener}, _from, state) do
    listeners =
      Map.put_new_lazy(state.listeners, listener, fn ->
        Process.monitor(listener)
      end)

    {:reply, :ok, %{state | listeners: listeners}}
  end

  def handle_call({:unsubscribe, listener}, _from, state) do
    listeners =
      case Map.pop(state.listeners, listener) do
        {nil, listeners} ->
          listeners

        {monitor_ref, listeners} ->
          Process.demonitor(monitor_ref)
          listeners
      end

    {:reply, :ok, %{state | listeners: listeners}}
  end

  @impl true
  def handle_info({:tcp, socket, msg}, state) do
    state.config.inet_adapter.setopts(socket, active: :once)

    case Codec.decode(state.config.codec, msg) do
      {:ok, msg} ->
        Logger.debug("[FLHook RECV] #{inspect(msg)}")

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
    maybe_cancel_timer(state.recv_timeout_ref)
    {:disconnect, %SocketError{reason: :closed}, state}
  end

  def handle_info({:tcp_error, _socket, reason}, state) do
    maybe_cancel_timer(state.recv_timeout_ref)
    {:disconnect, %SocketError{reason: reason}, state}
  end

  def handle_info(:timeout, state) do
    maybe_cancel_timer(state.recv_timeout_ref)
    error = %SocketError{reason: :timeout}

    case :queue.out(state.queue) do
      {{:value, reply}, new_queue} ->
        Connection.reply(reply.client, {:error, error})
        {:disconnect, error, %{state | queue: new_queue, recv_timeout_ref: nil}}

      {:empty, _} ->
        {:disconnect, error, state}
    end
  end

  def handle_info({:DOWN, monitor_ref, :process, listener, _info}, state) do
    {^monitor_ref, listeners} = Map.pop(state.listeners, listener)
    {:noreply, %{state | listeners: listeners}}
  end

  defp handle_event(event, state) do
    Enum.each(state.listeners, fn {listener, _monitor} ->
      send(listener, event)
    end)

    {:noreply, state}
  end

  defp handle_cmd_resp(msg, state) do
    maybe_cancel_timer(state.recv_timeout_ref)

    case :queue.out(state.queue) do
      {{:value, reply}, new_queue} ->
        case Reply.add_chunk(reply, msg) do
          %{status: :pending} = reply ->
            {:noreply, %{state | queue: :queue.in_r(reply, new_queue)}}

          %{status: :ok} = reply ->
            Connection.reply(
              reply.client,
              {:ok, Reply.rows(reply)}
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

  defp read_chunk(socket, config) do
    with {:socket, {:ok, value}} <-
           {:socket, config.tcp_adapter.recv(socket, 0, config.recv_timeout)},
         {:codec, {:ok, decoded}} <- {:codec, Codec.decode(config.codec, value)} do
      Logger.debug("[FLHook RECV] #{inspect(decoded)}")
      {:ok, decoded}
    else
      {:codec, error} -> error
      {:socket, {:error, reason}} -> {:error, %SocketError{reason: reason}}
    end
  end

  defp read_cmd_result(socket, config) do
    case do_read_cmd_result(%Reply{}, socket, config) do
      %Reply{status: :ok} = reply ->
        {:ok, Reply.rows(reply)}

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
    Logger.debug("[FLHook SEND] #{inspect(value)}")

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
    with :ok <- send_cmd(socket, config, CommandSerializer.to_string(cmd)) do
      read_cmd_result(socket, config)
    end
  end

  defp verify_welcome_msg(socket, config) do
    case read_chunk(socket, config) do
      {:ok, @welcome_msg <> _} -> :ok
      {:ok, message} -> {:error, %HandshakeError{actual_message: message}}
      error -> error
    end
  end

  defp authenticate(socket, config) do
    with {:ok, _} <- cmd_passive(socket, config, {"pass", [config.password]}) do
      :ok
    end
  end

  defp event_mode(_socket, %Config{event_mode: false}), do: :ok

  defp event_mode(socket, config) do
    with {:ok, _} <- cmd_passive(socket, config, "eventmode") do
      :ok
    end
  end

  defp maybe_cancel_timer(nil), do: :ok
  defp maybe_cancel_timer(timer_ref), do: Process.cancel_timer(timer_ref)

  defp log_error(error, config) do
    Logger.error("FLHook (#{config.host}:#{config.port}): #{Exception.message(error)}")
  end
end
