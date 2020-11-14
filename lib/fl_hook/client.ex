defmodule FLHook.Client do
  use Connection

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

  @impl true
  def init(opts) do
    host = opts[:host] || "localhost"
    port = opts[:port] || 1920
    password = opts[:password]
    encoding = opts[:encoding] || {:utf16, :little}

    if password do
      {:connect, :init,
       %{
         host: host,
         port: port,
         password: password,
         encoding: encoding,
         socket: nil,
         queue: :queue.new()
       }}
    else
      {:stop, :password_missing}
    end
  end

  @impl true
  def connect(:init, state) do
    case :gen_tcp.connect(to_charlist(state.host), state.port, [:binary, active: false]) do
      {:ok, socket} ->
        case :gen_tcp.recv(socket, 0) do
          {:ok, welcome_msg} ->
            Coder.decode(state.encoding, welcome_msg)

            case :gen_tcp.send(
                   socket,
                   Coder.encode(state.encoding, "pass #{state.password}\r\n")
                 ) do
              :ok ->
                case :gen_tcp.recv(socket, 0) do
                  {:ok, msg} ->
                    Coder.decode(state.encoding, msg)

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

          _error ->
            {:backoff, 1000, state}
        end

      {:error, reason} ->
        IO.inspect(reason)
        {:backoff, 1000, state}
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
    :gen_tcp.close(state.socket)
  end

  @impl true
  def handle_call({:cmd, cmd, args}, from, state) do
    queue = :queue.in(state.queue, %{from: from})
    {:noreply, %{state | queue: queue}}
  end

  @impl true
  def handle_info({:tcp, socket, data}, state) do
    IO.inspect(Coder.decode(state.encoding, data))

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
