defmodule FLHook.Client do
  use Connection

  require Logger

  alias FLHook.Coder

  def start_link(opts \\ []) do
    {opts, init_opts} = Keyword.split(opts, [:name])
    Connection.start_link(__MODULE__, init_opts, opts)
  end

  def stop(pid, reason \\ :normal) do
    GenServer.stop(pid, reason)
  end

  def cmd(pid, cmd) do
    Connection.call(pid, {:cmd, cmd})
  end

  # Server

  @welcome_msg "Welcome to FLHack"
  @connect_timeout 2000
  @recv_timeout 5000
  @send_timeout 5000

  @impl true
  def init(opts) do
    host = opts[:host] || "localhost"
    port = opts[:port] || 1920
    password = opts[:password]
    socket_mode = opts[:socket_mode] || :unicode
    event_mode = opts[:event_mode] || false

    if password do
      {:connect, :init,
       %{
         host: host,
         port: port,
         password: password,
         socket_mode: socket_mode,
         event_mode: event_mode,
         socket: nil,
         queue: :queue.new()
       }}
    else
      {:stop, :password_missing}
    end
  end

  @impl true
  def connect(_, state) do
    with {:connect, {:ok, socket}} <-
           {:connect,
            :gen_tcp.connect(
              to_charlist(state.host),
              state.port,
              [:binary, active: false, send_timeout: @send_timeout],
              @connect_timeout
            )},
         {:welcome, {:ok, @welcome_msg <> _}} <-
           {:welcome, read_msg(socket, state.socket_mode)},
         {:auth, :ok} <-
           {:auth,
            send_msg(
              socket,
              state.socket_mode,
              "pass #{state.password}\r\n"
            )},
         {:auth_status, {:ok, "OK\r\n"}} <-
           {:auth_status, read_msg(socket, state.socket_mode)} do
      # Set socket in active-once mode
      :ok = :gen_tcp.controlling_process(socket, self())
      :inet.setopts(socket, active: :once)
      {:ok, %{state | socket: socket}}
    else
      {:auth_status, {:ok, "ERR Wrong password\r\n"}} ->
        {:stop, :wrong_password, state}

      {_scope, {:error, reason}} ->
        Logger.error(
          "Unable to connect to #{state.host}:#{state.port} (#{inspect(reason)})"
        )

        {:backoff, 1000, state}
    end
  end

  defp read_msg(socket, mode) do
    with {:ok, value} <- :gen_tcp.recv(socket, 0, @recv_timeout),
         {:ok, decoded} <- Coder.decode(mode, value) do
      Logger.debug("[RECV] #{String.trim_trailing(decoded)}")
      {:ok, decoded}
    end
  end

  defp send_msg(socket, mode, value) do
    Logger.debug("[SEND] #{String.trim_trailing(value)}")

    with {:ok, encoded} <- Coder.encode(mode, value),
         :ok <- :gen_tcp.send(socket, encoded) do
      :ok
    end
  end

  @impl true
  def disconnect(info, state) do
    :ok = :gen_tcp.close(state.socket)

    case info do
      {:close, from} ->
        Connection.reply(from, :ok)

      {:error, :closed} ->
        :error_logger.format("Connection closed~n", [])

      {:error, reason} ->
        reason = :inet.format_error(reason)
        :error_logger.format("Connection error: ~s~n", [reason])
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
  def handle_call({:cmd, cmd}, from, state) do
    queue = :queue.in(state.queue, %{from: from})
    send_msg(state.socket, state.socket_mode, "#{cmd}\r\n")
    {:noreply, %{state | queue: queue}}
  end

  @impl true
  def handle_info({:tcp, socket, data}, state) do
    queue =
      case :queue.out(state.queue) do
        {{:value, %{from: from}}, queue} ->
          GenServer.reply(from, {:ok, data})
          queue

        {:empty, queue} ->
          queue
      end

    :inet.setopts(socket, active: :once)
    {:noreply, %{state | queue: queue}}
  end

  def handle_info({:tcp_closed, socket}, state) do
    # TODO: ...
    {:noreply, state}
  end

  def handle_info({:tcp_error, socket, reason}, state) do
    # TODO: ...
    {:noreply, state}
  end
end
