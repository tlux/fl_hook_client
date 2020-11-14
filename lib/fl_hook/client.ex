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

  def cmd(pid, cmd, args \\ []) do
    Connection.call(pid, {:cmd, cmd, args})
  end

  # Server

  @welcome_msg "Welcome to FLHack"

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
  def connect(:init, state) do
    case :gen_tcp.connect(to_charlist(state.host), state.port, [
           :binary,
           active: false
         ]) do
      {:ok, socket} ->
        case read_msg(socket, state.socket_mode) do
          {:ok, @welcome_msg <> _} ->
            case send_msg(
                   socket,
                   state.socket_mode,
                   "pass #{state.password}\r\n"
                 ) do
              :ok ->
                case read_msg(socket, state.socket_mode) do
                  {:ok, msg} ->
                    # Set socket in active-once mode
                    :ok = :gen_tcp.controlling_process(socket, self())
                    :inet.setopts(socket, active: :once)

                    {:ok, %{state | socket: socket}}

                  _ ->
                    {:stop, :auth_failed, state}
                end

              _ ->
                {:stop, :auth_failed, state}
            end

          {:ok, _} ->
            {:stop, :invalid_socket, state}

          _error ->
            {:backoff, 1000, state}
        end

      {:error, _reason} ->
        {:backoff, 1000, state}
    end
  end

  defp read_msg(socket, mode) do
    with {:ok, value} <- :gen_tcp.recv(socket, 0),
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
  def handle_call({:cmd, cmd, args}, from, state) do
    queue = :queue.in(state.queue, %{from: from})
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
