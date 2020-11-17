defmodule FLHook.Client do
  use Connection

  require Logger

  alias FLHook.Client.Reply
  alias FLHook.Codec
  alias FLHook.CodecError
  alias FLHook.CommandError
  alias FLHook.HandshakeError
  alias FLHook.InvalidOperationError
  alias FLHook.Result
  alias FLHook.SocketError
  alias FLHook.Utils

  @backoff_timeout 1000
  @connect_timeout 5000
  @passive_recv_timeout 5000
  @send_timeout 5000
  @welcome_msg "Welcome to FLHack"

  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    {opts, init_opts} = Keyword.split(opts, [:name])
    Connection.start_link(__MODULE__, init_opts, opts)
  end

  @spec stop(GenServer.server(), term) :: :ok
  def stop(server, reason \\ :normal) do
    GenServer.stop(server, reason)
  end

  @spec cmd(GenServer.server(), String.t()) ::
          {:ok, Result.t()}
          | {:error,
             CodecError.t()
             | CommandError.t()
             | InvalidOperationError.t()
             | SocketError.t()}
  def cmd(server, cmd) do
    Connection.call(server, {:cmd, cmd})
  end

  @spec cmd!(GenServer.server(), String.t()) :: Result.t() | no_return
  def cmd!(server, cmd) do
    case cmd(server, cmd) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @spec subscribe(GenServer.server(), GenServer.server()) ::
          :ok | {:error, InvalidOperationError.t()}
  def subscribe(server, subscriber \\ self()) do
    Connection.call(server, {:subscribe, subscriber})
  end

  @spec unsubscribe(GenServer.server(), GenServer.server()) ::
          :ok | {:error, InvalidOperationError.t()}
  def unsubscribe(server, subscriber \\ self()) do
    Connection.call(server, {:unsubscribe, subscriber})
  end

  # Callbacks

  @impl true
  def init(opts) do
    host = opts[:host] || "localhost"
    port = opts[:port] || 1920
    password = opts[:password]
    socket_mode = opts[:socket_mode] || :unicode
    event_mode = opts[:event_mode] || false

    subscriptions =
      if event_mode do
        Map.new(opts[:subscribers] || [], fn subscriber ->
          {subscriber, Process.monitor(subscriber)}
        end)
      else
        %{}
      end

    if password do
      {:connect, nil,
       %{
         event_mode: event_mode,
         host: host,
         password: password,
         port: port,
         queue: :queue.new(),
         socket_mode: socket_mode,
         socket: nil,
         subscriptions: subscriptions
       }}
    else
      {:stop, :password_missing}
    end
  end

  @impl true
  def connect(_info, state) do
    with {:ok, socket} <- socket_connect(state.host, state.port),
         :ok <- verify_welcome_msg(socket, state.socket_mode),
         :ok <- authenticate(socket, state.socket_mode, state.password),
         :ok <- event_mode(socket, state.socket_mode, state.event_mode) do
      :ok = :gen_tcp.controlling_process(socket, self())
      :inet.setopts(socket, active: :once)
      {:ok, %{state | socket: socket}}
    else
      {:error, %error_struct{} = error}
      when error_struct in [CommandError, HandshakeError] ->
        log_error(error, state)
        {:stop, error, state}

      {:error, error} ->
        log_error(error, state)
        {:backoff, @backoff_timeout, state}
    end
  end

  @impl true
  def disconnect(_info, state) do
    if state.socket do
      :ok = :gen_tcp.close(state.socket)
    end

    {:connect, :reconnect, %{state | socket: nil}}
  end

  @impl true
  def terminate(_reason, state) do
    if state.socket do
      :gen_tcp.close(state.socket)
    end
  end

  @impl true
  def handle_call({:cmd, _cmd}, _from, %{socket: nil} = state) do
    {:reply, {:error, %SocketError{reason: :closed}}, state}
  end

  def handle_call({:cmd, _cmd}, _from, %{event_mode: true} = state) do
    {:reply,
     {:error,
      %InvalidOperationError{message: "Unable to run commands in event mode"}},
     state}
  end

  def handle_call({:cmd, cmd}, from, state) do
    case send_cmd(state.socket, state.socket_mode, cmd) do
      :ok ->
        queue = :queue.in(%Reply{client: from}, state.queue)
        {:noreply, %{state | queue: queue}}

      error ->
        {:reply, error, state}
    end
  end

  def handle_call({action, _subscriber}, _from, %{event_mode: false} = state)
      when action in [:subscribe, :unsubscribe] do
    {:reply,
     {:error,
      %InvalidOperationError{
        message: "Unable manage subscriptions when not in event mode"
      }}, state}
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
  def handle_info({:tcp, socket, msg}, %{event_mode: true} = state) do
    :inet.setopts(socket, active: :once)

    case Codec.decode(state.socket_mode, msg) do
      {:ok, msg} ->
        Logger.debug("[EVENT] #{msg}")

        # TODO: Introduce event struct
        Enum.each(state.subscriptions, fn subscription ->
          send(subscription.subscriber, {:event, msg})
        end)

        {:noreply, state}

      {:error, error} ->
        Logger.error("FLHook client received an unexpected message")
        {:stop, error, state}
    end
  end

  def handle_info({:tcp, socket, msg}, state) do
    :inet.setopts(socket, active: :once)

    case Codec.decode(state.socket_mode, msg) do
      {:ok, msg} ->
        {{:value, reply}, new_queue} = :queue.out(state.queue)

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
            GenServer.reply(
              reply.client,
              {:error, %CommandError{detail: detail}}
            )

            {:noreply, %{state | queue: new_queue}}
        end

      {:error, error} ->
        Logger.error("FLHook client received an unexpected message")
        {:stop, error, state}
    end
  end

  def handle_info({:tcp_closed, _socket}, state) do
    error = %SocketError{reason: :closed}
    log_error(error, state)
    {:disconnect, error, state}
  end

  def handle_info({:tcp_error, _socket, reason}, state) do
    error = %SocketError{reason: reason}
    log_error(error, state)
    {:disconnect, error, state}
  end

  def handle_info({:DOWN, monitor_ref, :process, subscriber, _info}, state) do
    subscriptions =
      case Map.pop(state.subscriptions, subscriber) do
        {^monitor_ref, subscriptions} -> subscriptions
        {_, subscriptions} -> subscriptions
      end

    {:noreply, %{state | subscriptions: subscriptions}}
  end

  # Helpers

  defp socket_connect(host, port) do
    with {:error, reason} <-
           :gen_tcp.connect(
             to_charlist(host),
             port,
             [:binary, active: false, send_timeout: @send_timeout],
             @connect_timeout
           ) do
      {:error, %SocketError{reason: reason}}
    end
  end

  defp read_chunk(socket, mode) do
    with {:socket, {:ok, value}} <-
           {:socket, :gen_tcp.recv(socket, 0, @passive_recv_timeout)},
         {:codec, {:ok, decoded}} <- {:codec, Codec.decode(mode, value)} do
      {:ok, decoded}
    else
      {:codec, error} -> error
      {:socket, {:error, reason}} -> {:error, %SocketError{reason: reason}}
    end
  end

  defp read_cmd_result(socket, mode) do
    case do_read_cmd_result(%Reply{}, socket, mode) do
      %Reply{status: :ok} = reply ->
        {:ok, Reply.to_result(reply)}

      %Reply{status: {:error, detail}} ->
        {:error, %CommandError{detail: detail}}
    end
  end

  defp do_read_cmd_result(%Reply{status: :pending} = reply, socket, mode) do
    with {:ok, chunk} <- read_chunk(socket, mode) do
      reply
      |> Reply.add_chunk(chunk)
      |> do_read_cmd_result(socket, mode)
    end
  end

  defp do_read_cmd_result(%Reply{} = reply, _socket, _mode), do: reply

  defp send_msg(socket, mode, value) do
    with {:codec, {:ok, encoded}} <-
           {:codec, Codec.encode(mode, value)},
         {:socket, :ok} <- {:socket, :gen_tcp.send(socket, encoded)} do
      :ok
    else
      {:codec, error} -> error
      {:socket, {:error, reason}} -> {:error, %SocketError{reason: reason}}
    end
  end

  defp send_cmd(socket, mode, cmd) do
    send_msg(socket, mode, cmd <> Utils.line_sep())
  end

  defp cmd_passive(socket, mode, cmd) do
    with :ok <- send_cmd(socket, mode, cmd),
         {:ok, result} <- read_cmd_result(socket, mode) do
      {:ok, result}
    end
  end

  defp verify_welcome_msg(socket, mode) do
    case read_chunk(socket, mode) do
      {:ok, @welcome_msg <> _} -> :ok
      {:ok, message} -> {:error, %HandshakeError{actual_message: message}}
      error -> error
    end
  end

  defp authenticate(socket, mode, password) do
    with {:ok, _} <- cmd_passive(socket, mode, "pass #{password}") do
      :ok
    end
  end

  defp event_mode(_socket, _mode, false), do: :ok

  defp event_mode(socket, mode, true) do
    with {:ok, _} <- cmd_passive(socket, mode, "eventmode") do
      :ok
    end
  end

  defp log_error(error, state) do
    Logger.error(
      "FLHook (#{state.host}:#{state.port}): #{Exception.message(error)}"
    )
  end
end
